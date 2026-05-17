package com.example.gemma_care

import android.content.Context
import android.util.Log
import com.google.ai.edge.litertlm.Backend
import com.google.ai.edge.litertlm.Content
import com.google.ai.edge.litertlm.Contents
import com.google.ai.edge.litertlm.Conversation
import com.google.ai.edge.litertlm.ConversationConfig
import com.google.ai.edge.litertlm.Engine
import com.google.ai.edge.litertlm.EngineConfig
import com.google.ai.edge.litertlm.SamplerConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.withContext
import java.io.File

class LiteRTService(
    private val context: Context,
    private val modelPath: String
) {
    companion object {
        private const val TAG = "LiteRTService"
    }

    private var engine: Engine? = null
    private var activeConversation: Conversation? = null
    private var activeSystemPrompt: String? = null

    var isLoaded: Boolean = false
        private set

    suspend fun loadModel() = withContext(Dispatchers.IO) {
        Log.d(TAG, "==============================")
        Log.d(TAG, "Loading LiteRT-LM model (CPU + Vision)")
        Log.d(TAG, "Model path: $modelPath")

        val modelFile = File(modelPath)
        if (!modelFile.exists()) {
            throw IllegalStateException("Model file not found: $modelPath")
        }

        val config = EngineConfig(
            modelPath = modelPath,
            backend = Backend.CPU(),
            visionBackend = Backend.CPU(),
            cacheDir = modelFile.parentFile?.absolutePath
        )

        engine = Engine(config)
        engine?.initialize()
        Log.d(TAG, "Engine initialized with vision support")
        isLoaded = true
    }

    private fun closeActiveConversation() {
        try { activeConversation?.close() } catch (_: Exception) {}
        activeConversation = null
        activeSystemPrompt = null
    }

    suspend fun chatStreaming(
        systemPrompt: String,
        messages: List<Map<String, String>>,
        onToken: (String) -> Unit,
    ) = withContext(Dispatchers.IO) {
        val loadedEngine = engine ?: throw IllegalStateException("Model not loaded")

        if (activeSystemPrompt != systemPrompt) {
            Log.d(TAG, "System prompt changed — creating new conversation")
            closeActiveConversation()
            activeConversation = loadedEngine.createConversation(
                ConversationConfig(
                    systemInstruction = Contents.of(systemPrompt),
                    samplerConfig = SamplerConfig(topK = 40, topP = 0.95, temperature = 0.8),
                )
            )
            activeSystemPrompt = systemPrompt
        } else {
            Log.d(TAG, "Reusing existing conversation — no re-prefill")
        }

        val lastUserMessage = messages.lastOrNull { it["role"] == "user" }?.get("content")
            ?: throw IllegalStateException("No user message found")

        Log.d(TAG, "==============================")
        Log.d(TAG, "Streaming chat inference")
        Log.d(TAG, "Message: ${lastUserMessage.take(80)}")

        activeConversation!!.sendMessageAsync(lastUserMessage).collect { chunk ->
            onToken(chunk.toString())
        }
    }

    // Single image streaming
    suspend fun imageStreaming(
        prompt: String,
        imagePath: String,
        onToken: (String) -> Unit,
    ) = withContext(Dispatchers.IO) {
        val loadedEngine = engine ?: throw IllegalStateException("Model not loaded")

        val imageFile = File(imagePath)
        if (!imageFile.exists()) {
            throw IllegalStateException("Image file not found: $imagePath")
        }

        closeActiveConversation()

        Log.d(TAG, "==============================")
        Log.d(TAG, "Streaming single image inference: $imagePath")

        val conversation = loadedEngine.createConversation(
            ConversationConfig(
                samplerConfig = SamplerConfig(topK = 40, topP = 0.95, temperature = 0.8),
            )
        )

        try {
            val contents = Contents.of(
                Content.ImageFile(imagePath),
                Content.Text(prompt)
            )
            conversation.sendMessageAsync(contents).collect { chunk ->
                onToken(chunk.toString())
            }
            activeConversation = conversation
            activeSystemPrompt = null
        } catch (e: Exception) {
            try { conversation.close() } catch (_: Exception) {}
            throw e
        }
    }

    // Multi-image streaming — all PDF pages at once, one response
    suspend fun imageListStreaming(
        prompt: String,
        imagePaths: List<String>,
        onToken: (String) -> Unit,
    ) = withContext(Dispatchers.IO) {
        val loadedEngine = engine ?: throw IllegalStateException("Model not loaded")

        for (path in imagePaths) {
            if (!File(path).exists()) {
                throw IllegalStateException("Image file not found: $path")
            }
        }

        closeActiveConversation()

        Log.d(TAG, "==============================")
        Log.d(TAG, "Streaming multi-image inference: ${imagePaths.size} pages")

        val conversation = loadedEngine.createConversation(
            ConversationConfig(
                samplerConfig = SamplerConfig(topK = 40, topP = 0.95, temperature = 0.8),
            )
        )

        try {
            val contentList = mutableListOf<Content>()
            for (path in imagePaths) {
                contentList.add(Content.ImageFile(path))
            }
            contentList.add(Content.Text(prompt))

            val contents = Contents.of(contentList)
            conversation.sendMessageAsync(contents).collect { chunk ->
                onToken(chunk.toString())
            }
            activeConversation = conversation
            activeSystemPrompt = null
        } catch (e: Exception) {
            try { conversation.close() } catch (_: Exception) {}
            throw e
        }
    }

    fun clearConversationCache() {
        closeActiveConversation()
        Log.d(TAG, "Conversation cleared")
    }

    fun unload() {
        closeActiveConversation()
        try { engine?.close() } catch (_: Exception) {}
        engine = null
        isLoaded = false
        Log.d(TAG, "Engine unloaded")
    }
}