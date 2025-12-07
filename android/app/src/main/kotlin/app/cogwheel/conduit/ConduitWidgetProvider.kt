package app.cogwheel.conduit

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent

/**
 * Home screen widget provider for Conduit.
 * 
 * Provides quick actions:
 * - New Chat: Start a fresh conversation
 * - Mic: Start voice input
 * - Camera: Take a photo and attach to chat
 * - Photos: Pick from gallery and attach to chat
 * - Clipboard: Paste clipboard content as prompt
 */
class ConduitWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // Called when the first widget is created
    }

    override fun onDisabled(context: Context) {
        // Called when the last widget is removed
    }

    companion object {
        private const val ACTION_NEW_CHAT = "new_chat"
        private const val ACTION_MIC = "mic"
        private const val ACTION_CAMERA = "camera"
        private const val ACTION_PHOTOS = "photos"
        private const val ACTION_CLIPBOARD = "clipboard"

        private fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.conduit_widget)

            // Set up click handlers using home_widget's launch intent
            views.setOnClickPendingIntent(
                R.id.widget_container,
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("homewidget://$ACTION_NEW_CHAT")
                )
            )
            views.setOnClickPendingIntent(
                R.id.btn_new_chat,
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("homewidget://$ACTION_NEW_CHAT")
                )
            )
            views.setOnClickPendingIntent(
                R.id.btn_mic,
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("homewidget://$ACTION_MIC")
                )
            )
            views.setOnClickPendingIntent(
                R.id.btn_camera,
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("homewidget://$ACTION_CAMERA")
                )
            )
            views.setOnClickPendingIntent(
                R.id.btn_photos,
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("homewidget://$ACTION_PHOTOS")
                )
            )
            views.setOnClickPendingIntent(
                R.id.btn_clipboard,
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("homewidget://$ACTION_CLIPBOARD")
                )
            )

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
