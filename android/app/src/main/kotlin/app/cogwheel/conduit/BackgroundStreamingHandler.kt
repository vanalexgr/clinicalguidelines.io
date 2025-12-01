package app.cogwheel.conduit

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*
import org.json.JSONArray
import org.json.JSONObject

class BackgroundStreamingService : Service() {
    private var wakeLock: PowerManager.WakeLock? = null
    private val activeStreams = mutableSetOf<String>()
    private var activeStreamCount = 0
    private var isForeground = false
    private var currentForegroundType: Int = 0
    private var foregroundStartTime: Long = 0

    companion object {
        const val CHANNEL_ID = "conduit_streaming_channel"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START = "START_STREAMING"
        const val ACTION_STOP = "STOP_STREAMING"
        const val EXTRA_REQUIRES_MICROPHONE = "requiresMicrophone"
        const val EXTRA_STREAM_COUNT = "streamCount"
    }

    override fun onCreate() {
        super.onCreate()
        println("BackgroundStreamingService: Service created")

        // CRITICAL: Enter foreground IMMEDIATELY to satisfy Android's 5s timeout.
        // Do this before ANY other initialization to minimize the risk of
        // ForegroundServiceDidNotStartInTimeException.
        try {
            val initialType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
            } else {
                0
            }
            if (!isForeground) {
                // Channel should already exist (created in ConduitApplication)
                // but ensure it exists as a fallback
                ensureNotificationChannel()
                val notification = createMinimalNotification()
                val success = startForegroundInternal(notification, initialType)
                if (!success) {
                    // startForegroundInternal returned false (caught internal exception)
                    // Throw to trigger the fallback handler
                    throw IllegalStateException("startForegroundInternal returned false")
                }
            }
        } catch (e: Exception) {
            // Last resort: try to enter foreground with absolute minimal setup
            println("BackgroundStreamingService: Error in onCreate, attempting fallback: ${e.message}")
            try {
                // Must ensure channel exists before creating notification on Android O+
                // Otherwise startForeground throws "Bad notification" error
                ensureNotificationChannel()
                val fallbackNotification = NotificationCompat.Builder(this, CHANNEL_ID)
                    .setContentTitle("Conduit")
                    .setSmallIcon(android.R.drawable.ic_dialog_info)
                    .setSilent(true)
                    .setOngoing(true)  // Prevent user from dismissing foreground service notification
                    .build()
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    startForeground(
                        NOTIFICATION_ID,
                        fallbackNotification,
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
                    )
                    currentForegroundType = ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
                } else {
                    @Suppress("DEPRECATION")
                    startForeground(NOTIFICATION_ID, fallbackNotification)
                }
                isForeground = true
                foregroundStartTime = System.currentTimeMillis()
            } catch (fallbackError: Exception) {
                println("BackgroundStreamingService: Fallback also failed: ${fallbackError.message}")
                // All attempts exhausted - now notify Flutter of the failure
                // This ensures we don't prematurely notify before trying fallback
                sendFailureNotification(fallbackError)
                // Service will be killed by system, but at least we tried
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        val incomingStreamCount =
            intent?.getIntExtra(EXTRA_STREAM_COUNT, 0) ?: 0
        activeStreamCount = incomingStreamCount

        val desiredType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            resolveForegroundServiceType(intent)
        } else {
            0
        }

        // Always enter foreground as early as possible to avoid the 5s timeout
        // even when stop/keep-alive races deliver a STOP intent first.
        val needsTypeUpdate = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
            currentForegroundType != desiredType

        if (!isForeground || needsTypeUpdate) {
            val notification = createMinimalNotification()
            val enteredForeground = if (!isForeground) {
                startForegroundInternal(notification, desiredType)
            } else {
                updateForegroundType(notification, desiredType)
                true
            }

            if (!enteredForeground) {
                stopSelf()
                return START_NOT_STICKY
            }

            // If no streams are active after entering foreground, shut down to
            // avoid lingering foreground instances that could trigger
            // DidNotStopInTime exceptions.
            if (activeStreamCount <= 0) {
                stopStreaming()
                return START_NOT_STICKY
            }
        }

        when (action) {
            ACTION_STOP -> {
                stopStreaming()
                return START_NOT_STICKY
            }
            "KEEP_ALIVE" -> {
                keepAlive()
                return START_STICKY
            }
            ACTION_START -> {
                if (activeStreamCount > 0) {
                    acquireWakeLock()
                    println("BackgroundStreamingService: Started foreground service")
                } else {
                    println("BackgroundStreamingService: No active streams; skipping wake lock")
                }
            }
        }

        return START_STICKY
    }

    private fun startForegroundInternal(notification: Notification, type: Int): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(NOTIFICATION_ID, notification, type)
                currentForegroundType = type
            } else {
                @Suppress("DEPRECATION")
                startForeground(NOTIFICATION_ID, notification)
            }
            isForeground = true
            foregroundStartTime = System.currentTimeMillis()
            println("BackgroundStreamingService: Foreground service started at $foregroundStartTime")
            true
        } catch (e: Exception) {
            // Catch all exceptions including ForegroundServiceStartNotAllowedException
            println("BackgroundStreamingService: Failed to enter foreground: ${e.javaClass.simpleName}: ${e.message}")
            // Don't notify Flutter here - let caller handle fallback attempts first.
            // Only notify after all attempts (primary + fallback) have been exhausted.
            false
        }
    }
    
    private fun sendFailureNotification(e: Exception) {
        // Send broadcast intent to notify MainActivity
        val intent = Intent("app.cogwheel.conduit.FOREGROUND_SERVICE_FAILED")
        intent.putExtra("error", e.message ?: "Unknown error")
        intent.putExtra("errorType", e.javaClass.simpleName)
        sendBroadcast(intent)
    }

    private fun updateForegroundType(notification: Notification, type: Int) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return
        try {
            startForeground(NOTIFICATION_ID, notification, type)
            currentForegroundType = type
        } catch (e: SecurityException) {
            println("BackgroundStreamingService: Unable to update foreground type: ${e.message}")
        }
    }

    private fun resolveForegroundServiceType(intent: Intent?): Int {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return 0

        val requiresMicrophone = intent?.getBooleanExtra(EXTRA_REQUIRES_MICROPHONE, false) ?: false
        if (requiresMicrophone) {
            if (hasRecordAudioPermission()) {
                return ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE or
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
            }
            println("BackgroundStreamingService: Microphone permission missing; falling back to data sync type")
        }

        return ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
    }

    private fun hasRecordAudioPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            android.Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun createMinimalNotification(): Notification {
        ensureNotificationChannel()

        // Create a minimal, silent notification (required for foreground service)
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Conduit")
            .setContentText("Background service active")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_SECRET)
            .setOngoing(true)
            .setShowWhen(false)
            .setSilent(true)
            .build()
    }

    private fun ensureNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            "Background Service",
            NotificationManager.IMPORTANCE_MIN,
        ).apply {
            description = "Background service for Conduit"
            setShowBadge(false)
            enableLights(false)
            enableVibration(false)
            setSound(null, null)
            lockscreenVisibility = Notification.VISIBILITY_SECRET
        }

        manager.createNotificationChannel(channel)
    }
    
    /**
     * Acquires a wake lock to prevent CPU sleep during active streaming.
     * 
     * Timeout is set to 6 minutes (360 seconds) to cover the 5-minute keepAlive
     * interval with a 1-minute buffer. This ensures continuous wake lock coverage
     * without gaps between refreshes.
     * 
     * Note: Android Play Console may flag wake locks > 1 minute as "excessive",
     * but continuous CPU availability is required for reliable streaming.
     * The alternative (60-second timeout with 5-minute refresh) creates 4-minute
     * gaps where the CPU can sleep, causing streams to stall.
     */
    private fun acquireWakeLock() {
        if (wakeLock?.isHeld == true) return

        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "Conduit::StreamingWakeLock"
        ).apply {
            // 6-minute timeout covers the 5-minute keepAlive interval + 1-minute buffer
            // This ensures no gaps in wake lock coverage during active streaming
            // Note: Use default reference-counted mode with timeout-based acquire
            // (setReferenceCounted(false) interferes with timeout auto-release)
            acquire(6 * 60 * 1000L) // 6 minutes - refreshed every 5 minutes by keepAlive()
        }
        println("BackgroundStreamingService: Wake lock acquired (6min timeout)")
    }
    
    private fun releaseWakeLock() {
        try {
            wakeLock?.let {
                if (it.isHeld) {
                    it.release()
                    println("BackgroundStreamingService: Wake lock released")
                }
            }
        } catch (e: Exception) {
            // Wake lock may already be released due to timeout
            println("BackgroundStreamingService: Wake lock release exception: ${e.message}")
        }
        wakeLock = null
    }
    
    private fun keepAlive() {
        if (activeStreamCount <= 0) {
            stopStreaming()
            return
        }

        // Check if we're approaching Android 14's 6-hour dataSync limit
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE && isForeground) {
            val uptime = System.currentTimeMillis() - foregroundStartTime
            val fiveHours = 5 * 60 * 60 * 1000L // 5 hours in milliseconds
            
            if (uptime > fiveHours) {
                println("BackgroundStreamingService: Approaching time limit (${uptime / 3600000}h), stopping service")
                stopStreaming()
                return
            }
        }
        
        // Refresh wake lock to maintain CPU availability for streaming.
        // Wake lock has 6-minute timeout, keepAlive is called every 5 minutes,
        // ensuring continuous coverage with 1-minute overlap buffer.
        // Note: Foreground services prevent process termination but NOT CPU sleep.
        releaseWakeLock()
        acquireWakeLock()
        println("BackgroundStreamingService: Keep alive - wake lock refreshed, ${activeStreamCount} active streams")
    }
    
    private fun stopStreaming() {
        println("BackgroundStreamingService: Stopping service...")
        activeStreams.clear()
        activeStreamCount = 0
        releaseWakeLock()
        
        if (isForeground) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                } else {
                    @Suppress("DEPRECATION")
                    stopForeground(true)
                }
            } catch (e: Exception) {
                println("BackgroundStreamingService: Error stopping foreground: ${e.message}")
            }
            isForeground = false
        }
        
        stopSelf()
        println("BackgroundStreamingService: Service stopped")
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        println("BackgroundStreamingService: Task removed, stopping service")
        stopStreaming()
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        println("BackgroundStreamingService: onDestroy called")
        if (isForeground) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                } else {
                    @Suppress("DEPRECATION")
                    stopForeground(true)
                }
            } catch (e: Exception) {
                println("BackgroundStreamingService: Error stopping foreground in onDestroy: ${e.message}")
            }
        }
        releaseWakeLock()
        activeStreams.clear()
        activeStreamCount = 0
        isForeground = false
        foregroundStartTime = 0
        super.onDestroy()
        println("BackgroundStreamingService: Service destroyed")
    }

    override fun onBind(intent: Intent?): IBinder? = null
}

class BackgroundStreamingHandler(private val activity: MainActivity) : MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var sharedPrefs: SharedPreferences

    private val activeStreams = mutableSetOf<String>()
    private val streamsRequiringMic = mutableSetOf<String>()
    private var backgroundJob: Job? = null
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var serviceFailureReceiver: android.content.BroadcastReceiver? = null
    
    companion object {
        private const val CHANNEL_NAME = "conduit/background_streaming"
        private const val PREFS_NAME = "conduit_stream_states"
        private const val STREAM_STATES_KEY = "active_streams"
    }

    fun setup(flutterEngine: FlutterEngine) {
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        context = activity.applicationContext
        sharedPrefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        
        createNotificationChannel()
        setupServiceFailureReceiver()
    }
    
    private fun setupServiceFailureReceiver() {
        serviceFailureReceiver = object : android.content.BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == "app.cogwheel.conduit.FOREGROUND_SERVICE_FAILED") {
                    val error = intent.getStringExtra("error") ?: "Unknown error"
                    val errorType = intent.getStringExtra("errorType") ?: "Exception"
                    
                    println("BackgroundStreamingHandler: Service failure received: $errorType - $error")
                    
                    // Notify Flutter about the service failure
                    channel.invokeMethod("serviceFailed", mapOf(
                        "error" to error,
                        "errorType" to errorType,
                        "streamIds" to activeStreams.toList()
                    ))
                    
                    // Clear active streams since service failed
                    activeStreams.clear()
                    streamsRequiringMic.clear()
                }
            }
        }
        
        val filter = android.content.IntentFilter("app.cogwheel.conduit.FOREGROUND_SERVICE_FAILED")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(serviceFailureReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(serviceFailureReceiver, filter)
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startBackgroundExecution" -> {
                val streamIds = call.argument<List<String>>("streamIds")
                val requiresMic = call.argument<Boolean>("requiresMicrophone") ?: false
                if (streamIds != null) {
                    startBackgroundExecution(streamIds, requiresMic)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGS", "Stream IDs required", null)
                }
            }
            
            "stopBackgroundExecution" -> {
                val streamIds = call.argument<List<String>>("streamIds")
                if (streamIds != null) {
                    stopBackgroundExecution(streamIds)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGS", "Stream IDs required", null)
                }
            }
            
            "keepAlive" -> {
                keepAlive()
                result.success(null)
            }
            
            "saveStreamStates" -> {
                val states = call.argument<List<Map<String, Any>>>("states")
                val reason = call.argument<String>("reason")
                if (states != null) {
                    saveStreamStates(states, reason ?: "unknown")
                    result.success(null)
                } else {
                    result.error("INVALID_ARGS", "States required", null)
                }
            }
            
            "recoverStreamStates" -> {
                result.success(recoverStreamStates())
            }
            
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun startBackgroundExecution(streamIds: List<String>, requiresMic: Boolean) {
        activeStreams.addAll(streamIds)
        streamsRequiringMic.retainAll(activeStreams)
        if (requiresMic) {
            streamsRequiringMic.addAll(streamIds)
        }

        if (activeStreams.isNotEmpty()) {
            startForegroundService()
            startBackgroundMonitoring()
        }
    }

    private fun stopBackgroundExecution(streamIds: List<String>) {
        activeStreams.removeAll(streamIds.toSet())
        streamsRequiringMic.removeAll(streamIds.toSet())

        if (activeStreams.isEmpty()) {
            stopForegroundService()
            stopBackgroundMonitoring()
        }
    }

    private fun startForegroundService() {
        try {
            val serviceIntent = Intent(context, BackgroundStreamingService::class.java)
            serviceIntent.putExtra(
                BackgroundStreamingService.EXTRA_STREAM_COUNT,
                activeStreams.size,
            )
            serviceIntent.putExtra(
                BackgroundStreamingService.EXTRA_REQUIRES_MICROPHONE,
                streamsRequiringMic.isNotEmpty(),
            )
            serviceIntent.action = BackgroundStreamingService.ACTION_START

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        } catch (e: Exception) {
            println("BackgroundStreamingHandler: Failed to start foreground service: ${e.message}")
            // Clear active streams as we couldn't start the service
            activeStreams.clear()
            streamsRequiringMic.clear()
        }
    }

    private fun stopForegroundService() {
        try {
            val serviceIntent = Intent(context, BackgroundStreamingService::class.java)
            serviceIntent.action = BackgroundStreamingService.ACTION_STOP
            context.stopService(serviceIntent)
        } catch (e: Exception) {
            println("BackgroundStreamingHandler: Failed to stop foreground service: ${e.message}")
        }
    }

    private fun startBackgroundMonitoring() {
        backgroundJob?.cancel()
        backgroundJob = scope.launch {
            while (activeStreams.isNotEmpty()) {
                delay(30000) // Check every 30 seconds
                
                // Notify Dart side to check stream health
                channel.invokeMethod("checkStreams", null, object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        when (result) {
                            is Int -> {
                                if (result == 0) {
                                    activeStreams.clear()
                                    stopForegroundService()
                                }
                            }
                        }
                    }
                    
                    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                        println("BackgroundStreamingHandler: Error checking streams: $errorMessage")
                    }
                    
                    override fun notImplemented() {
                        println("BackgroundStreamingHandler: checkStreams method not implemented")
                    }
                })
            }
        }
    }

    private fun stopBackgroundMonitoring() {
        backgroundJob?.cancel()
        backgroundJob = null
    }

    private fun keepAlive() {
        if (activeStreams.isEmpty()) return
        
        try {
            val serviceIntent = Intent(context, BackgroundStreamingService::class.java)
            serviceIntent.action = "KEEP_ALIVE"
            serviceIntent.putExtra(
                BackgroundStreamingService.EXTRA_STREAM_COUNT,
                activeStreams.size,
            )
            serviceIntent.putExtra(
                BackgroundStreamingService.EXTRA_REQUIRES_MICROPHONE,
                streamsRequiringMic.isNotEmpty(),
            )
            
            // Use startService (not startForegroundService) for keep-alive pings
            // to avoid ForegroundServiceStartNotAllowedException on Android 14+
            context.startService(serviceIntent)
        } catch (e: Exception) {
            println("BackgroundStreamingHandler: Failed to keep alive service: ${e.message}")
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Background Service"
            val descriptionText = "Background service for Conduit"
            val importance = NotificationManager.IMPORTANCE_MIN
            val channel = NotificationChannel(BackgroundStreamingService.CHANNEL_ID, name, importance).apply {
                description = descriptionText
                setShowBadge(false)
                enableLights(false)
                enableVibration(false)
                setSound(null, null)
                lockscreenVisibility = Notification.VISIBILITY_SECRET
            }

            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun saveStreamStates(states: List<Map<String, Any>>, reason: String) {
        try {
            val jsonArray = JSONArray()
            for (state in states) {
                val jsonObject = JSONObject()
                for ((key, value) in state) {
                    jsonObject.put(key, value)
                }
                jsonArray.put(jsonObject)
            }
            
            sharedPrefs.edit()
                .putString(STREAM_STATES_KEY, jsonArray.toString())
                .putLong("saved_timestamp", System.currentTimeMillis())
                .putString("saved_reason", reason)
                .apply()
                
            println("BackgroundStreamingHandler: Saved ${states.size} stream states (reason: $reason)")
        } catch (e: Exception) {
            println("BackgroundStreamingHandler: Failed to save stream states: ${e.message}")
        }
    }

    private fun recoverStreamStates(): List<Map<String, Any>> {
        return try {
            val savedStates = sharedPrefs.getString(STREAM_STATES_KEY, null) ?: return emptyList()
            val timestamp = sharedPrefs.getLong("saved_timestamp", 0)
            val reason = sharedPrefs.getString("saved_reason", "unknown")
            
            // Check if states are not too old (max 1 hour)
            val age = System.currentTimeMillis() - timestamp
            if (age > 3600000) { // 1 hour in milliseconds
                println("BackgroundStreamingHandler: Stream states too old (${age / 1000}s), discarding")
                sharedPrefs.edit().remove(STREAM_STATES_KEY).apply()
                return emptyList()
            }
            
            val jsonArray = JSONArray(savedStates)
            val result = mutableListOf<Map<String, Any>>()
            
            for (i in 0 until jsonArray.length()) {
                val jsonObject = jsonArray.getJSONObject(i)
                val map = mutableMapOf<String, Any>()
                
                val keys = jsonObject.keys()
                while (keys.hasNext()) {
                    val key = keys.next()
                    val value = jsonObject.get(key)
                    map[key] = value
                }
                
                result.add(map)
            }
            
            println("BackgroundStreamingHandler: Recovered ${result.size} stream states (reason: $reason, age: ${age / 1000}s)")
            
            // Clear saved states after recovery
            sharedPrefs.edit().remove(STREAM_STATES_KEY).apply()
            
            result
        } catch (e: Exception) {
            println("BackgroundStreamingHandler: Failed to recover stream states: ${e.message}")
            emptyList()
        }
    }

    fun cleanup() {
        scope.cancel()
        stopBackgroundMonitoring()
        stopForegroundService()
        
        // Unregister broadcast receiver
        try {
            serviceFailureReceiver?.let {
                context.unregisterReceiver(it)
            }
        } catch (e: Exception) {
            println("BackgroundStreamingHandler: Error unregistering receiver: ${e.message}")
        }
        serviceFailureReceiver = null
    }
}
