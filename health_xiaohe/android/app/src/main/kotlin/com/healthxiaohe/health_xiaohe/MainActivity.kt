package com.healthxiaohe.health_xiaohe

import android.media.*
import android.media.audiofx.AcousticEchoCanceler
import android.os.Process
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.io.*

class MainActivity : FlutterActivity() {
    // --- AudioEngine: 统一管理录音和播放，解决回声和延迟 ---
    private var audioRecord: AudioRecord? = null
    private var audioTrack: AudioTrack? = null
    private var echoCanceler: AcousticEchoCanceler? = null
    private var recording = false
    private var outputBufferSize = 0
    private var recChannel: MethodChannel? = null

    private fun safeCleanup() {
        try { echoCanceler?.enabled = false; echoCanceler?.release() } catch (_: Exception) {}
        echoCanceler = null
        try { audioRecord?.stop(); audioRecord?.release() } catch (_: Exception) {}
        audioRecord = null
        recording = false
    }

    private fun safeStopTrack() {
        try { audioTrack?.pause(); audioTrack?.flush() } catch (_: Exception) {}
    }

    private fun safeDisposeTrack() {
        try { audioTrack?.stop(); audioTrack?.release() } catch (_: Exception) {}
        audioTrack = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // --- Recorder Channel ---
        recChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.healthxiaohe/audio_recorder")
        recChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val sampleRate = call.argument<Int>("sampleRate") ?: 16000
                    val bufferSize = AudioRecord.getMinBufferSize(sampleRate,
                        AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT)
                    audioRecord = AudioRecord.Builder()
                        .setAudioSource(MediaRecorder.AudioSource.VOICE_COMMUNICATION)
                        .setAudioFormat(AudioFormat.Builder()
                            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                            .setSampleRate(sampleRate)
                            .setChannelMask(AudioFormat.CHANNEL_IN_MONO)
                            .build())
                        .setBufferSizeInBytes(bufferSize * 2)
                        .build()
                    // 尝试开启硬件回声消除
                    try {
                        if (AcousticEchoCanceler.isAvailable()) {
                            echoCanceler = AcousticEchoCanceler.create(audioRecord!!.audioSessionId)
                            echoCanceler?.enabled = true
                        }
                    } catch (_: Exception) {}
                    audioRecord?.startRecording()
                    recording = true
                    // 在后台线程持续读取PCM并发送到Flutter
                    Thread {
                        Process.setThreadPriority(Process.THREAD_PRIORITY_URGENT_AUDIO)
                        val buf = ByteArray(bufferSize)
                        while (recording) {
                            val len = audioRecord?.read(buf, 0, buf.size) ?: break
                            if (len > 0) {
                                val chunk = buf.copyOf(len)
                                runOnUiThread { recChannel?.invokeMethod("onAudio", chunk) }
                            }
                        }
                    }.start()
                    result.success(true)
                }
                "stop" -> { safeCleanup(); result.success(true) }
                else -> result.notImplemented()
            }
        }

        // --- Player Channel ---
        val playerChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.healthxiaohe/audio_player")
        playerChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "init" -> {
                    val sampleRate = call.argument<Int>("sampleRate") ?: 24000
                    outputBufferSize = AudioTrack.getMinBufferSize(sampleRate,
                        AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_16BIT)
                    audioTrack = AudioTrack.Builder()
                        .setAudioAttributes(AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                            .build())
                        .setAudioFormat(AudioFormat.Builder()
                            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                            .setSampleRate(sampleRate)
                            .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                            .build())
                        .setBufferSizeInBytes(outputBufferSize * 2)
                        .setTransferMode(AudioTrack.MODE_STREAM)
                        .build()
                    audioTrack?.play()
                    result.success(true)
                }
                "play" -> {
                    try {
                        audioTrack?.play() // resume after pause
                        val data = call.arguments as ByteArray
                        audioTrack?.write(data, 0, data.size)
                        result.success(true)
                    } catch (e: Exception) { result.success(false) }
                }
                "stop" -> { safeStopTrack(); result.success(true) }
                "dispose" -> { safeDisposeTrack(); result.success(true) }
                else -> result.notImplemented()
            }
        }
    }
}
