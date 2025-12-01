package com.vsai

import android.Manifest
import android.content.pm.PackageManager
import android.media.MediaPlayer
import android.media.MediaRecorder
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.WritableMap
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.modules.core.DeviceEventManagerModule
import java.io.File
import java.io.IOException

@ReactModule(name = AudioRecorderModule.NAME)
class AudioRecorderModule(reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

    companion object {
        const val NAME = "AudioRecorder"
    }

    private var mediaRecorder: MediaRecorder? = null
    private var mediaPlayer: MediaPlayer? = null
    private var currentRecordingPath: String? = null
    private var isRecording = false
    private var isPlaying = false
    private var isPaused = false
    private var recordingStartTime: Long = 0
    private var pausedDuration: Long = 0

    private val handler = Handler(Looper.getMainLooper())
    private var recordingProgressRunnable: Runnable? = null
    private var playbackProgressRunnable: Runnable? = null

    override fun getName(): String = NAME

    // MARK: - Event Emitting
    private fun sendEvent(eventName: String, params: WritableMap?) {
        reactApplicationContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
            .emit(eventName, params)
    }

    @ReactMethod
    fun addListener(eventName: String) {
        // Required for RN event emitter
    }

    @ReactMethod
    fun removeListeners(count: Int) {
        // Required for RN event emitter
    }

    // MARK: - Recording Methods
    @ReactMethod
    fun startRecording(promise: Promise) {
        if (isRecording) {
            promise.reject("ALREADY_RECORDING", "Recording is already in progress")
            return
        }

        val fileName = "recording_${System.currentTimeMillis()}.m4a"
        val recordingsDir = getRecordingsDirectoryPath()
        val filePath = "$recordingsDir/$fileName"

        try {
            mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(reactApplicationContext)
            } else {
                @Suppress("DEPRECATION")
                (MediaRecorder())
            }

            mediaRecorder?.apply {
                setAudioSource(MediaRecorder.AudioSource.MIC)
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                setAudioSamplingRate(44100)
                setAudioEncodingBitRate(128000)
                setOutputFile(filePath)
                prepare()
                start()
            }

            currentRecordingPath = filePath
            isRecording = true
            isPaused = false
            recordingStartTime = System.currentTimeMillis()
            pausedDuration = 0

            startRecordingProgressUpdates()

            val params = Arguments.createMap().apply {
                putString("filePath", filePath)
            }
            sendEvent("onRecordingStarted", params)

            promise.resolve(filePath)
        } catch (e: IOException) {
            promise.reject("RECORDING_ERROR", "Failed to start recording: ${e.message}", e)
        } catch (e: Exception) {
            promise.reject("RECORDING_ERROR", "Failed to start recording: ${e.message}", e)
        }
    }

    @ReactMethod
    fun stopRecording(promise: Promise) {
        if (!isRecording) {
            promise.reject("NOT_RECORDING", "No recording in progress")
            return
        }

        try {
            stopRecordingProgressUpdates()
            mediaRecorder?.apply {
                stop()
                release()
            }
            mediaRecorder = null

            val filePath = currentRecordingPath ?: ""
            val duration = (System.currentTimeMillis() - recordingStartTime - pausedDuration) / 1000.0

            isRecording = false
            isPaused = false

            val params = Arguments.createMap().apply {
                putString("filePath", filePath)
                putDouble("duration", duration)
            }
            sendEvent("onRecordingStopped", params)

            promise.resolve(filePath)
        } catch (e: Exception) {
            promise.reject("STOP_ERROR", "Failed to stop recording: ${e.message}", e)
        }
    }

    @ReactMethod
    fun pauseRecording(promise: Promise) {
        if (!isRecording) {
            promise.reject("NOT_RECORDING", "No recording in progress")
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                mediaRecorder?.pause()
                isPaused = true
                stopRecordingProgressUpdates()

                val duration = (System.currentTimeMillis() - recordingStartTime - pausedDuration) / 1000.0
                val params = Arguments.createMap().apply {
                    putDouble("duration", duration)
                }
                sendEvent("onRecordingPaused", params)

                promise.resolve(null)
            } catch (e: Exception) {
                promise.reject("PAUSE_ERROR", "Failed to pause recording: ${e.message}", e)
            }
        } else {
            promise.reject("NOT_SUPPORTED", "Pause recording is not supported on this Android version")
        }
    }

    @ReactMethod
    fun resumeRecording(promise: Promise) {
        if (!isRecording || !isPaused) {
            promise.reject("NOT_PAUSED", "Recording is not paused")
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                mediaRecorder?.resume()
                isPaused = false
                startRecordingProgressUpdates()

                sendEvent("onRecordingResumed", null)
                promise.resolve(null)
            } catch (e: Exception) {
                promise.reject("RESUME_ERROR", "Failed to resume recording: ${e.message}", e)
            }
        } else {
            promise.reject("NOT_SUPPORTED", "Resume recording is not supported on this Android version")
        }
    }

    @ReactMethod
    fun cancelRecording(promise: Promise) {
        try {
            stopRecordingProgressUpdates()
            mediaRecorder?.apply {
                stop()
                release()
            }
            mediaRecorder = null

            currentRecordingPath?.let { path ->
                File(path).delete()
            }

            isRecording = false
            isPaused = false
            currentRecordingPath = null

            promise.resolve(null)
        } catch (e: Exception) {
            // Even if there's an error, clean up
            mediaRecorder = null
            isRecording = false
            isPaused = false
            currentRecordingPath = null
            promise.resolve(null)
        }
    }

    // MARK: - Playback Methods
    @ReactMethod
    fun playRecording(filePath: String, promise: Promise) {
        val file = File(filePath)
        if (!file.exists()) {
            promise.reject("FILE_NOT_FOUND", "Audio file not found at path: $filePath")
            return
        }

        try {
            mediaPlayer?.release()
            mediaPlayer = MediaPlayer().apply {
                setDataSource(filePath)
                prepare()

                setOnCompletionListener {
                    stopPlaybackProgressUpdates()
                    isPlaying = false

                    val params = Arguments.createMap().apply {
                        putString("filePath", filePath)
                        putBoolean("success", true)
                    }
                    sendEvent("onPlaybackCompleted", params)
                }

                setOnErrorListener { _, what, extra ->
                    stopPlaybackProgressUpdates()
                    isPlaying = false

                    val params = Arguments.createMap().apply {
                        putString("message", "Playback error: what=$what, extra=$extra")
                        putString("code", "PLAYBACK_ERROR")
                    }
                    sendEvent("onPlaybackError", params)
                    true
                }

                start()
            }

            isPlaying = true
            startPlaybackProgressUpdates()

            val params = Arguments.createMap().apply {
                putString("filePath", filePath)
                putDouble("duration", (mediaPlayer?.duration ?: 0) / 1000.0)
            }
            sendEvent("onPlaybackStarted", params)

            promise.resolve(null)
        } catch (e: Exception) {
            promise.reject("PLAYBACK_ERROR", "Failed to play recording: ${e.message}", e)
        }
    }

    @ReactMethod
    fun stopPlayback(promise: Promise) {
        try {
            stopPlaybackProgressUpdates()
            mediaPlayer?.apply {
                if (isPlaying) {
                    stop()
                }
                seekTo(0)
            }
            isPlaying = false

            sendEvent("onPlaybackStopped", null)
            promise.resolve(null)
        } catch (e: Exception) {
            promise.reject("STOP_ERROR", "Failed to stop playback: ${e.message}", e)
        }
    }

    @ReactMethod
    fun pausePlayback(promise: Promise) {
        if (!isPlaying) {
            promise.reject("NOT_PLAYING", "No playback in progress")
            return
        }

        try {
            mediaPlayer?.pause()
            stopPlaybackProgressUpdates()

            val params = Arguments.createMap().apply {
                putDouble("currentTime", (mediaPlayer?.currentPosition ?: 0) / 1000.0)
            }
            sendEvent("onPlaybackPaused", params)

            promise.resolve(null)
        } catch (e: Exception) {
            promise.reject("PAUSE_ERROR", "Failed to pause playback: ${e.message}", e)
        }
    }

    @ReactMethod
    fun resumePlayback(promise: Promise) {
        if (mediaPlayer == null) {
            promise.reject("NOT_PAUSED", "No playback to resume")
            return
        }

        try {
            mediaPlayer?.start()
            isPlaying = true
            startPlaybackProgressUpdates()

            sendEvent("onPlaybackResumed", null)
            promise.resolve(null)
        } catch (e: Exception) {
            promise.reject("RESUME_ERROR", "Failed to resume playback: ${e.message}", e)
        }
    }

    // MARK: - Status Methods
    @ReactMethod
    fun isRecording(promise: Promise) {
        promise.resolve(isRecording)
    }

    @ReactMethod
    fun isPlaying(promise: Promise) {
        promise.resolve(isPlaying)
    }

    @ReactMethod
    fun getRecordingDuration(promise: Promise) {
        if (isRecording) {
            val duration = (System.currentTimeMillis() - recordingStartTime - pausedDuration) / 1000.0
            promise.resolve(duration)
        } else {
            promise.resolve(0.0)
        }
    }

    @ReactMethod
    fun getPlaybackDuration(promise: Promise) {
        promise.resolve((mediaPlayer?.duration ?: 0) / 1000.0)
    }

    @ReactMethod
    fun getPlaybackCurrentTime(promise: Promise) {
        promise.resolve((mediaPlayer?.currentPosition ?: 0) / 1000.0)
    }

    // MARK: - Permission Methods
    @ReactMethod
    fun requestPermissions(promise: Promise) {
        val activity = currentActivity
        if (activity == null) {
            promise.reject("NO_ACTIVITY", "No activity available")
            return
        }

        val hasPermission = ContextCompat.checkSelfPermission(
            reactApplicationContext,
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED

        if (hasPermission) {
            promise.resolve(true)
        } else {
            // Note: Actual permission request should be handled through PermissionsAndroid in JS
            promise.resolve(false)
        }
    }

    @ReactMethod
    fun hasPermissions(promise: Promise) {
        val hasPermission = ContextCompat.checkSelfPermission(
            reactApplicationContext,
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED

        promise.resolve(hasPermission)
    }

    // MARK: - File Management
    @ReactMethod
    fun getRecordingsDirectory(promise: Promise) {
        promise.resolve(getRecordingsDirectoryPath())
    }

    @ReactMethod
    fun deleteRecording(filePath: String, promise: Promise) {
        try {
            val file = File(filePath)
            val deleted = file.delete()
            promise.resolve(deleted)
        } catch (e: Exception) {
            promise.reject("DELETE_ERROR", "Failed to delete recording: ${e.message}", e)
        }
    }

    // MARK: - Helper Methods
    private fun getRecordingsDirectoryPath(): String {
        val recordingsDir = File(reactApplicationContext.filesDir, "recordings")
        if (!recordingsDir.exists()) {
            recordingsDir.mkdirs()
        }
        return recordingsDir.absolutePath
    }

    private fun startRecordingProgressUpdates() {
        stopRecordingProgressUpdates()
        recordingProgressRunnable = object : Runnable {
            override fun run() {
                if (isRecording && !isPaused) {
                    val duration = (System.currentTimeMillis() - recordingStartTime - pausedDuration) / 1000.0
                    val params = Arguments.createMap().apply {
                        putDouble("duration", duration)
                        putString("filePath", currentRecordingPath ?: "")
                    }
                    sendEvent("onRecordingProgress", params)
                    handler.postDelayed(this, 100)
                }
            }
        }
        handler.post(recordingProgressRunnable!!)
    }

    private fun stopRecordingProgressUpdates() {
        recordingProgressRunnable?.let { handler.removeCallbacks(it) }
        recordingProgressRunnable = null
    }

    private fun startPlaybackProgressUpdates() {
        stopPlaybackProgressUpdates()
        playbackProgressRunnable = object : Runnable {
            override fun run() {
                if (isPlaying && mediaPlayer != null) {
                    val params = Arguments.createMap().apply {
                        putDouble("currentTime", (mediaPlayer?.currentPosition ?: 0) / 1000.0)
                        putDouble("duration", (mediaPlayer?.duration ?: 0) / 1000.0)
                        putString("filePath", "")
                    }
                    sendEvent("onPlaybackProgress", params)
                    handler.postDelayed(this, 100)
                }
            }
        }
        handler.post(playbackProgressRunnable!!)
    }

    private fun stopPlaybackProgressUpdates() {
        playbackProgressRunnable?.let { handler.removeCallbacks(it) }
        playbackProgressRunnable = null
    }

    override fun onCatalystInstanceDestroy() {
        super.onCatalystInstanceDestroy()
        stopRecordingProgressUpdates()
        stopPlaybackProgressUpdates()
        mediaRecorder?.release()
        mediaPlayer?.release()
    }
}