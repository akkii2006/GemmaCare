package com.example.gemma_care

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterActivity() {

    private val methodChannelName = "com.example.gemma_care/litert"
    private val eventChannelName = "com.example.gemma_care/litert_stream"

    private var liteRTService: LiteRTService? = null
    private var streamingJob: Job? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            eventChannelName
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                eventSink = sink
            }
            override fun onCancel(arguments: Any?) {
                eventSink = null
                streamingJob?.cancel()
                streamingJob = null
            }
        })

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            methodChannelName
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "loadModel" -> {
                    val modelPath = call.argument<String>("modelPath") ?: run {
                        result.error("INVALID_ARGS", "modelPath is required", null)
                        return@setMethodCallHandler
                    }
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            liteRTService = LiteRTService(applicationContext, modelPath)
                            liteRTService?.loadModel()
                            withContext(Dispatchers.Main) { result.success(true) }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("LOAD_ERROR", e.stackTraceToString(), null)
                            }
                        }
                    }
                }

                "startChatStream" -> {
                    val systemPrompt = call.argument<String>("systemPrompt") ?: run {
                        result.error("INVALID_ARGS", "systemPrompt is required", null)
                        return@setMethodCallHandler
                    }
                    val rawMessages = call.argument<List<*>>("messages") ?: run {
                        result.error("INVALID_ARGS", "messages is required", null)
                        return@setMethodCallHandler
                    }

                    val service = liteRTService
                    if (service == null || !service.isLoaded) {
                        result.error("NOT_LOADED", "Model not loaded", null)
                        return@setMethodCallHandler
                    }

                    @Suppress("UNCHECKED_CAST")
                    val messages = rawMessages.mapNotNull { item ->
                        (item as? Map<*, *>)?.let { map ->
                            mapOf(
                                "role" to (map["role"] as? String ?: "user"),
                                "content" to (map["content"] as? String ?: "")
                            )
                        }
                    }

                    streamingJob?.cancel()
                    streamingJob = CoroutineScope(Dispatchers.IO).launch {
                        try {
                            service.chatStreaming(
                                systemPrompt = systemPrompt,
                                messages = messages,
                                onToken = { token ->
                                    CoroutineScope(Dispatchers.Main).launch {
                                        eventSink?.success(token)
                                    }
                                }
                            )
                            withContext(Dispatchers.Main) {
                                eventSink?.success("__DONE__")
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                eventSink?.error("STREAM_ERROR", e.message, null)
                            }
                        }
                    }
                    result.success(true)
                }

                "startImageStream" -> {
                    val prompt = call.argument<String>("prompt") ?: run {
                        result.error("INVALID_ARGS", "prompt is required", null)
                        return@setMethodCallHandler
                    }
                    val imagePath = call.argument<String>("imagePath") ?: run {
                        result.error("INVALID_ARGS", "imagePath is required", null)
                        return@setMethodCallHandler
                    }

                    val service = liteRTService
                    if (service == null || !service.isLoaded) {
                        result.error("NOT_LOADED", "Model not loaded", null)
                        return@setMethodCallHandler
                    }

                    streamingJob?.cancel()
                    streamingJob = CoroutineScope(Dispatchers.IO).launch {
                        try {
                            service.imageStreaming(
                                prompt = prompt,
                                imagePath = imagePath,
                                onToken = { token ->
                                    CoroutineScope(Dispatchers.Main).launch {
                                        eventSink?.success(token)
                                    }
                                }
                            )
                            withContext(Dispatchers.Main) {
                                eventSink?.success("__DONE__")
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                eventSink?.error("IMAGE_STREAM_ERROR", e.message, null)
                            }
                        }
                    }
                    result.success(true)
                }

                "startImageListStream" -> {
                    val prompt = call.argument<String>("prompt") ?: run {
                        result.error("INVALID_ARGS", "prompt is required", null)
                        return@setMethodCallHandler
                    }
                    val rawPaths = call.argument<List<*>>("imagePaths") ?: run {
                        result.error("INVALID_ARGS", "imagePaths is required", null)
                        return@setMethodCallHandler
                    }

                    val service = liteRTService
                    if (service == null || !service.isLoaded) {
                        result.error("NOT_LOADED", "Model not loaded", null)
                        return@setMethodCallHandler
                    }

                    val imagePaths = rawPaths.mapNotNull { it as? String }

                    streamingJob?.cancel()
                    streamingJob = CoroutineScope(Dispatchers.IO).launch {
                        try {
                            service.imageListStreaming(
                                prompt = prompt,
                                imagePaths = imagePaths,
                                onToken = { token ->
                                    CoroutineScope(Dispatchers.Main).launch {
                                        eventSink?.success(token)
                                    }
                                }
                            )
                            withContext(Dispatchers.Main) {
                                eventSink?.success("__DONE__")
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                eventSink?.error("IMAGE_LIST_STREAM_ERROR", e.message, null)
                            }
                        }
                    }
                    result.success(true)
                }

                "runImageInference" -> {
                    val prompt = call.argument<String>("prompt") ?: run {
                        result.error("INVALID_ARGS", "prompt and imagePath required", null)
                        return@setMethodCallHandler
                    }
                    val imagePath = call.argument<String>("imagePath") ?: run {
                        result.error("INVALID_ARGS", "prompt and imagePath required", null)
                        return@setMethodCallHandler
                    }

                    val service = liteRTService
                    if (service == null || !service.isLoaded) {
                        result.error("NOT_LOADED", "Model not loaded", null)
                        return@setMethodCallHandler
                    }

                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val responseBuilder = StringBuilder()
                            service.imageStreaming(
                                prompt = prompt,
                                imagePath = imagePath,
                                onToken = { token -> responseBuilder.append(token) }
                            )
                            withContext(Dispatchers.Main) {
                                result.success(responseBuilder.toString())
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("IMAGE_INFERENCE_ERROR", e.stackTraceToString(), null)
                            }
                        }
                    }
                }

                "isModelLoaded" -> {
                    result.success(liteRTService?.isLoaded ?: false)
                }

                "clearConversationCache" -> {
                    liteRTService?.clearConversationCache()
                    result.success(true)
                }

                "unloadModel" -> {
                    try {
                        streamingJob?.cancel()
                        liteRTService?.unload()
                        liteRTService = null
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UNLOAD_ERROR", e.stackTraceToString(), null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        streamingJob?.cancel()
        try { liteRTService?.unload() } catch (_: Exception) {}
        super.onDestroy()
    }
}