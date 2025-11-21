package app.cogwheel.conduit

import android.content.Context
import android.content.Intent
import android.service.voice.VoiceInteractionSession
import android.os.Bundle
import android.app.assist.AssistStructure
import android.app.assist.AssistContent
import android.graphics.Bitmap

class ConduitVoiceInteractionSession(context: Context) : VoiceInteractionSession(context) {

    private var capturedContext: String? = null
    private var capturedScreenshot: Bitmap? = null

    override fun onCreateContentView(): android.view.View {
        val view = layoutInflater.inflate(app.cogwheel.conduit.R.layout.assistant_overlay, null)

        // Summarize page button - sends screen context
        val summarizeButton = view.findViewById<android.view.View>(app.cogwheel.conduit.R.id.btn_summarize)
        summarizeButton?.setOnClickListener {
            launchAppWithContext(includeScreenshot = false)
        }

        // Ask about page button - sends screenshot
        val askAboutButton = view.findViewById<android.view.View>(app.cogwheel.conduit.R.id.btn_ask_about)
        askAboutButton?.setOnClickListener {
            launchAppWithScreenshot()
        }

        // Input area (opens text input)
        val inputArea = view.findViewById<android.view.View>(app.cogwheel.conduit.R.id.input_area)
        inputArea?.setOnClickListener {
            launchApp()
        }

        // Voice button
        val voiceButton = view.findViewById<android.view.View>(app.cogwheel.conduit.R.id.btn_voice)
        voiceButton?.setOnClickListener {
            // TODO: Implement voice input functionality
            launchAppWithContext(includeScreenshot = false)
        }

        return view
    }

    override fun onHandleAssist(
        data: Bundle?,
        structure: AssistStructure?,
        content: AssistContent?
    ) {
        super.onHandleAssist(data, structure, content)

        android.util.Log.d("ConduitVoiceSession", "onHandleAssist called")

        // Capture screen context
        val screenContext = StringBuilder()
        structure?.let {
            val nodes = it.windowNodeCount
            for (i in 0 until nodes) {
                val windowNode = it.getWindowNodeAt(i)
                traverseNode(windowNode.rootViewNode, screenContext)
            }
        }
        capturedContext = screenContext.toString()

        // Capture screenshot from assist data
        data?.let {
            try {
                capturedScreenshot = it.getParcelable("screenshot")
                if (capturedScreenshot == null) {
                    // Try alternative key
                    capturedScreenshot = it.getParcelable("android.intent.extra.ASSIST_SCREENSHOT")
                }
                android.util.Log.d("ConduitVoiceSession", "Screenshot captured: ${capturedScreenshot != null}")
            } catch (e: Exception) {
                android.util.Log.e("ConduitVoiceSession", "Failed to get screenshot from bundle", e)
            }
        }
    }

    override fun onHandleScreenshot(screenshot: Bitmap?) {
        super.onHandleScreenshot(screenshot)
        capturedScreenshot = screenshot
        android.util.Log.d("ConduitVoiceSession", "Screenshot received via onHandleScreenshot: ${screenshot != null}")
    }

    private fun launchApp() {
        try {
            android.util.Log.d("ConduitVoiceSession", "Attempting to launch app")
            val intent = Intent(context, MainActivity::class.java)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)

            context.startActivity(intent)
            android.util.Log.d("ConduitVoiceSession", "App launch requested")
            finish() // Close the overlay
        } catch (e: Exception) {
            android.util.Log.e("ConduitVoiceSession", "Failed to launch app", e)
        }
    }

    private fun launchAppWithContext(includeScreenshot: Boolean) {
        try {
            android.util.Log.d("ConduitVoiceSession", "Attempting to launch app with context")
            val intent = Intent(context, MainActivity::class.java)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)

            if (capturedContext != null) {
                intent.putExtra("screen_context", capturedContext)
                android.util.Log.d("ConduitVoiceSession", "Context attached: ${capturedContext?.take(50)}...")
            } else {
                android.util.Log.d("ConduitVoiceSession", "No context captured")
            }

            context.startActivity(intent)
            android.util.Log.d("ConduitVoiceSession", "App launch requested")
            finish() // Close the overlay
        } catch (e: Exception) {
            android.util.Log.e("ConduitVoiceSession", "Failed to launch app", e)
        }
    }

    private fun launchAppWithScreenshot() {
        try {
            android.util.Log.d("ConduitVoiceSession", "Attempting to launch app with screenshot")
            val intent = Intent(context, MainActivity::class.java)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)

            // Save screenshot to cache and pass URI
            capturedScreenshot?.let { bitmap ->
                try {
                    val file = java.io.File(context.cacheDir, "assistant_screenshot_${System.currentTimeMillis()}.png")
                    val outputStream = java.io.FileOutputStream(file)
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
                    outputStream.flush()
                    outputStream.close()

                    intent.putExtra("screenshot_path", file.absolutePath)
                    android.util.Log.d("ConduitVoiceSession", "Screenshot saved to: ${file.absolutePath}")
                } catch (e: Exception) {
                    android.util.Log.e("ConduitVoiceSession", "Failed to save screenshot", e)
                }
            } ?: run {
                android.util.Log.d("ConduitVoiceSession", "No screenshot captured")
            }

            context.startActivity(intent)
            android.util.Log.d("ConduitVoiceSession", "App launch requested with screenshot")
            finish() // Close the overlay
        } catch (e: Exception) {
            android.util.Log.e("ConduitVoiceSession", "Failed to launch app with screenshot", e)
        }
    }

    private fun traverseNode(node: AssistStructure.ViewNode?, builder: StringBuilder) {
        if (node == null) return

        if (node.text != null) {
            builder.append(node.text).append("\n")
        }
        
        // Also check content description for accessibility text
        if (node.contentDescription != null) {
             builder.append(node.contentDescription).append("\n")
        }

        for (i in 0 until node.childCount) {
            traverseNode(node.getChildAt(i), builder)
        }
    }
}
