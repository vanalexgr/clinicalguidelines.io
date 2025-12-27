package io.clinicalguidelines.chat

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent

/**
 * Home screen widget provider for Clinical Guidelines.
 * 
 * Provides quick access to start a new chat conversation.
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

        private fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.conduit_widget)

            // Set up click handlers using home_widget's launch intent
            // The homeWidget=true query param is required for the home_widget package to
            // recognize these URLs and forward them to the Flutter widgetClicked stream
            views.setOnClickPendingIntent(
                R.id.widget_container,
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("conduit://$ACTION_NEW_CHAT?homeWidget=true")
                )
            )
            views.setOnClickPendingIntent(
                R.id.btn_new_chat,
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("conduit://$ACTION_NEW_CHAT?homeWidget=true")
                )
            )

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

