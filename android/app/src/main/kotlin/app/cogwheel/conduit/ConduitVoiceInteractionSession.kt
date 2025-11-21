package app.cogwheel.conduit

import android.content.Context
import android.content.Intent
import android.service.voice.VoiceInteractionSession
import android.os.Bundle
import android.app.assist.AssistStructure
import android.app.assist.AssistContent

class ConduitVoiceInteractionSession(context: Context) : VoiceInteractionSession(context) {

    private var capturedContext: String? = null

    override fun onCreateContentView(): android.view.View {
        val view = layoutInflater.inflate(app.cogwheel.conduit.R.layout.assistant_overlay, null)

        // Share screen button
        val shareScreenButton = view.findViewById<android.view.View>(app.cogwheel.conduit.R.id.btn_share_screen)
        shareScreenButton?.setOnClickListener {
            // TODO: Implement share screen functionality
            launchAppWithContext()
        }

        // Summarize page button
        val summarizeButton = view.findViewById<android.view.View>(app.cogwheel.conduit.R.id.btn_summarize)
        summarizeButton?.setOnClickListener {
            launchAppWithContext()
        }

        // Ask about page button
        val askAboutButton = view.findViewById<android.view.View>(app.cogwheel.conduit.R.id.btn_ask_about)
        askAboutButton?.setOnClickListener {
            launchAppWithContext()
        }

        // Input area (opens text input)
        val inputArea = view.findViewById<android.view.View>(app.cogwheel.conduit.R.id.input_area)
        inputArea?.setOnClickListener {
            launchAppWithContext()
        }

        // Voice button
        val voiceButton = view.findViewById<android.view.View>(app.cogwheel.conduit.R.id.btn_voice)
        voiceButton?.setOnClickListener {
            // TODO: Implement voice input functionality
            launchAppWithContext()
        }

        // Sparkle button (AI actions)
        val sparkleButton = view.findViewById<android.view.View>(app.cogwheel.conduit.R.id.btn_sparkle)
        sparkleButton?.setOnClickListener {
            launchAppWithContext()
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

        val screenContext = StringBuilder()
        structure?.let {
            val nodes = it.windowNodeCount
            for (i in 0 until nodes) {
                val windowNode = it.getWindowNodeAt(i)
                traverseNode(windowNode.rootViewNode, screenContext)
            }
        }
        
        capturedContext = screenContext.toString()
        // Ideally, we could update the UI here to say "Context Ready"
    }

    private fun launchAppWithContext() {
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
