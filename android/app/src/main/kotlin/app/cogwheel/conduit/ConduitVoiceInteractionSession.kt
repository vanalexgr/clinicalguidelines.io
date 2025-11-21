package app.cogwheel.conduit

import android.content.Context
import android.content.Intent
import android.service.voice.VoiceInteractionSession
import android.os.Bundle
import android.app.assist.AssistStructure
import android.app.assist.AssistContent

class ConduitVoiceInteractionSession(context: Context) : VoiceInteractionSession(context) {

    override fun onHandleAssist(
        data: Bundle?,
        structure: AssistStructure?,
        content: AssistContent?
    ) {
        super.onHandleAssist(data, structure, content)
        
        android.util.Log.d("ConduitVoiceSession", "onHandleAssist called")

        // Launch the main activity when the assistant is triggered
        val intent = Intent(context, MainActivity::class.java)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }
}
