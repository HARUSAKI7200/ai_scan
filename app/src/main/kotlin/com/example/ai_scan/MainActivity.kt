// app/src/main/kotlin/com/example/ai_scan/MainActivity.kt

package com.example.ai_scan

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.*
import android.media.ExifInterface
import android.media.MediaScannerConnection
import android.os.Bundle
import android.util.Log
import androidx.core.content.ContextCompat // ★ 追加: ContextCompatを使用
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import com.example.ai_scan.utils.DocumentCornerDetector
import com.example.ai_scan.utils.DocumentCropper
import com.example.ai_scan.utils.GeminiDocumentCropper
import org.opencv.android.OpenCVLoader

class MainActivity: FlutterActivity() {
    private val CHANNEL_IMAGE = "com.example.app/image_processing"
    private val CHANNEL_CAMERA = "com.example.app/camera"
    private val CHANNEL_NIFUDA_EVENT = "com.example.app/nifuda_events"
    
    private val CAMERA_REQUEST_CODE = 1001
    private val NIFUDA_CAMERA_REQUEST_CODE = 1002 
    private var cameraResult: MethodChannel.Result? = null

    private var eventSink: EventChannel.EventSink? = null

    private val captureReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val path = intent?.getStringExtra("saved_path")
            if (path != null && eventSink != null) {
                runOnUiThread {
                    eventSink?.success(path)
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        if (OpenCVLoader.initDebug()) {
            Log.i("OpenCV", "OpenCV loaded successfully")
        } else {
            Log.e("OpenCV", "OpenCV initialization failed!")
        }
        
        // ★ 修正: LocalBroadcastManager を廃止し、標準の registerReceiver を使用
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NIFUDA_EVENT).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    val filter = IntentFilter("com.example.app.NIFUDA_CAPTURED")
                    // Android 13以降に対応するため ContextCompat を使用し、RECEIVER_NOT_EXPORTED を指定
                    ContextCompat.registerReceiver(
                        this@MainActivity,
                        captureReceiver,
                        filter,
                        ContextCompat.RECEIVER_NOT_EXPORTED
                    )
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    try {
                        unregisterReceiver(captureReceiver)
                    } catch (e: Exception) {
                        // 登録されていない場合の解除エラーを無視
                    }
                }
            }
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_IMAGE).setMethodCallHandler { call, result ->
            when (call.method) {
                "autoCropImage" -> {
                    val path = call.argument<String>("imagePath")
                    if (path != null) {
                        Thread {
                            val res = performAutoCrop(path) ?: path
                            runOnUiThread { result.success(res) }
                        }.start()
                    } else { result.error("ERROR", "Path is null", null) }
                }
                "maskAndResizeImage" -> {
                    val path = call.argument<String>("imagePath")
                    val masks = call.argument<List<Map<String, Double>>>("masks")
                    if (path != null && masks != null) {
                        Thread {
                            val res = performMaskProcessing(path, masks, useGemini = false)
                            runOnUiThread { result.success(res) }
                        }.start()
                    } else { result.error("ERROR", "Invalid args", null) }
                }
                "maskAndResizeImageGemini" -> {
                    val path = call.argument<String>("imagePath")
                    val masks = call.argument<List<Map<String, Double>>>("masks")
                    if (path != null && masks != null) {
                        Thread {
                            val res = performMaskProcessing(path, masks, useGemini = true)
                            runOnUiThread { result.success(res) }
                        }.start()
                    } else { result.error("ERROR", "Invalid args", null) }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_CAMERA).setMethodCallHandler { call, result ->
            if (call.method == "startNativeCamera") {
                cameraResult = result
                val isProductList = call.argument<Boolean>("is_product_list") ?: false
                val intent = Intent(this, CameraActivity::class.java)
                intent.putExtra("mode", if (isProductList) "product_list" else "tag")
                startActivityForResult(intent, CAMERA_REQUEST_CODE)
            } 
            else if (call.method == "startNifudaCamera") {
                cameraResult = result
                val keywords = call.argument<List<String>>("keywords") ?: emptyList()
                val intent = Intent(this, NifudaCameraActivity::class.java)
                intent.putStringArrayListExtra("keywords", ArrayList(keywords))
                startActivityForResult(intent, NIFUDA_CAMERA_REQUEST_CODE)
            }
            else { result.notImplemented() }
        }
    }

    private fun performMaskProcessing(path: String, masks: List<Map<String, Double>>, useGemini: Boolean): String? {
        var bitmap: Bitmap? = null
        var enhanced: Bitmap? = null
        return try {
            val options = BitmapFactory.Options().apply { inMutable = true }
            bitmap = BitmapFactory.decodeFile(path, options) ?: return null
            
            enhanced = if (useGemini) {
                GeminiDocumentCropper.applyGeminiFilter(bitmap!!)
            } else {
                DocumentCropper.applyEnhancedFilter(bitmap!!)
            }

            if (enhanced != bitmap) { bitmap?.recycle(); bitmap = null }
            
            val canvas = Canvas(enhanced!!)
            val paint = Paint().apply { color = Color.BLACK; style = Paint.Style.FILL }
            for (m in masks) {
                val l = (m["l"] ?: 0.0).toFloat() * enhanced!!.width
                val t = (m["t"] ?: 0.0).toFloat() * enhanced!!.height
                val r = (m["r"] ?: 0.0).toFloat() * enhanced!!.width
                val b = (m["b"] ?: 0.0).toFloat() * enhanced!!.height
                canvas.drawRect(l, t, r, b, paint)
            }
            FileOutputStream(File(path)).use { out -> enhanced!!.compress(Bitmap.CompressFormat.JPEG, 95, out) }
            path
        } catch (e: Exception) { path } finally { bitmap?.recycle(); enhanced?.recycle() }
    }

    private fun performAutoCrop(inputPath: String): String? {
        val detector = DocumentCornerDetector(this)
        var bitmap: Bitmap? = null
        var rotated: Bitmap? = null
        var mask: org.opencv.core.Mat? = null
        var cropped: Bitmap? = null
        return try {
            val options = BitmapFactory.Options().apply { inMutable = true }
            bitmap = BitmapFactory.decodeFile(inputPath, options) ?: return null
            rotated = fixRotation(bitmap!!, inputPath)
            if (rotated != bitmap) { bitmap?.recycle(); bitmap = null }
            mask = detector.detectMask(rotated!!) ?: return null
            
            val dcimDir = android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_DCIM)
            val debugDir = File(dcimDir, "debug_crop").apply { mkdirs() }
            val debugSavePath = File(debugDir, "debug_${File(inputPath).name}").absolutePath

            cropped = DocumentCropper.processFullPipeline(rotated!!, mask!!, debugSavePath)
            
            android.media.MediaScannerConnection.scanFile(this, arrayOf(debugSavePath), null, null)

            if (cropped != null) {
                FileOutputStream(File(inputPath)).use { out -> cropped!!.compress(Bitmap.CompressFormat.JPEG, 95, out) }
                inputPath
            } else { inputPath }
        } catch (e: Exception) { null } finally {
            detector.close(); mask?.release(); bitmap?.recycle(); rotated?.recycle(); cropped?.recycle()
        }
    }

    private fun fixRotation(bitmap: Bitmap, path: String): Bitmap {
        val ei = ExifInterface(path)
        val orientation = ei.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)
        val matrix = Matrix()
        when (orientation) {
            ExifInterface.ORIENTATION_ROTATE_90 -> matrix.postRotate(90f)
            ExifInterface.ORIENTATION_ROTATE_180 -> matrix.postRotate(180f)
            ExifInterface.ORIENTATION_ROTATE_270 -> matrix.postRotate(270f)
            else -> return bitmap
        }
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == CAMERA_REQUEST_CODE || requestCode == NIFUDA_CAMERA_REQUEST_CODE) {
            val res = if (resultCode == RESULT_OK) data?.getStringArrayListExtra("captured_paths") else null
            cameraResult?.success(res); cameraResult = null
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(captureReceiver)
        } catch (e: Exception) {}
    }
}