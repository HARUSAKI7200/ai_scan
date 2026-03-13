// kotlin/com/example/ai_scan/CameraActivity.kt

package com.example.ai_scan

import android.Manifest
import android.content.Context
import android.content.DialogInterface
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.ColorStateList
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.Matrix
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.media.ExifInterface
import android.os.Bundle
import android.util.Log
import android.util.Size
import android.view.OrientationEventListener
import android.view.Surface
import android.view.View
import android.widget.*
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.camera.camera2.interop.Camera2CameraInfo
import androidx.camera.core.*
import androidx.camera.core.resolutionselector.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.example.ai_scan.utils.DocumentCornerDetector
import com.example.ai_scan.utils.DocumentCropper
import org.opencv.android.OpenCVLoader
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicInteger
import kotlin.math.sqrt

class CameraActivity : AppCompatActivity(), SensorEventListener {

    private lateinit var viewFinder: PreviewView
    private lateinit var shutterButton: ImageButton
    private lateinit var torchButton: Button    // ★UI変更: Buttonクラスに
    private lateinit var settingsButton: Button // ★UI追加: 解像度ボタン
    private lateinit var doneButton: Button
    private lateinit var statusTextView: TextView
    private lateinit var orientationTextView: TextView 
    private lateinit var resTextView: TextView  // ★UI追加: 解像度表示
    private lateinit var stabilityBar: ProgressBar
    private lateinit var shutterEffectView: View
    private lateinit var processingOverlay: View

    private var imageCapture: ImageCapture? = null
    private var camera: Camera? = null 
    private var cameraExecutor = Executors.newSingleThreadExecutor()
    private var isTorchOn = false 

    private var selectedResolution: Size? = null // ★追加: 選択された解像度
    private var docDetector: DocumentCornerDetector? = null

    private lateinit var sensorManager: SensorManager
    private var accelerometer: Sensor? = null
    private var isDeviceStable = false
    private var isCapturingInProgress = false
    private var isWaitingForProcessing = false 
    
    private var orientationEventListener: OrientationEventListener? = null
    private var currentRotation: Int = -1
    
    private val processingCount = AtomicInteger(0)

    private val alpha = 0.8f 
    private val gravity = FloatArray(3) 
    private var gravityInitialized = false 

    private val STABILITY_THRESHOLD = 0.8f 
    private var stableFrameCount = 0 
    private val REQUIRED_STABLE_FRAMES = 5 

    private var mode: String = "tag"
    private val capturedPaths = ArrayList<String>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_camera)

        if (OpenCVLoader.initDebug()) {
            try {
                docDetector = DocumentCornerDetector(this)
            } catch (e: Exception) {
                Log.e(TAG, "Detector init fail: ${e.message}")
            }
        }

        mode = intent.getStringExtra("mode") ?: "tag"

        viewFinder = findViewById(R.id.viewFinder)
        shutterButton = findViewById(R.id.btnCapture)
        torchButton = findViewById(R.id.btnTorch)       
        settingsButton = findViewById(R.id.btnSettings) // ★追加
        doneButton = findViewById(R.id.btnDone)
        statusTextView = findViewById(R.id.txtStability)
        orientationTextView = findViewById(R.id.txtOrientation)
        resTextView = findViewById(R.id.txtResolution)  // ★追加
        stabilityBar = findViewById(R.id.stabilityBar)
        shutterEffectView = findViewById(R.id.shutterEffectView)
        processingOverlay = findViewById(R.id.processingOverlay)

        findViewById<ImageButton>(R.id.btnClose)?.setOnClickListener { 
            setResult(RESULT_CANCELED)
            finish() 
        }

        torchButton.setOnClickListener { toggleTorch() }
        settingsButton.setOnClickListener { showResolutionDialog() } // ★追加
        
        doneButton.setOnClickListener {
            if (capturedPaths.isEmpty()) {
                Toast.makeText(this, "画像を撮影してください", Toast.LENGTH_SHORT).show()
            } else if (processingCount.get() > 0) {
                isWaitingForProcessing = true
                processingOverlay.visibility = View.VISIBLE
                shutterButton.isEnabled = false
                doneButton.isEnabled = false
                torchButton.isEnabled = false
                settingsButton.isEnabled = false
            } else {
                finishWithResult()
            }
        }
        updateDoneButtonText()

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

        if (accelerometer == null) {
            isDeviceStable = true
            updateStabilityUI(100)
        }

        initOrientationListener()

        if (allPermissionsGranted()) {
            viewFinder.post { startCamera() }
        } else {
            ActivityCompat.requestPermissions(this, getRequiredPermissions(), REQUEST_CODE_PERMISSIONS)
        }

        shutterButton.setOnClickListener {
            if (!isCapturingInProgress && isDeviceStable) {
                takePhoto()
            } else if (!isDeviceStable) {
                Toast.makeText(this, "端末を固定してください", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun initOrientationListener() {
        orientationEventListener = object : OrientationEventListener(this) {
            override fun onOrientationChanged(orientation: Int) {
                if (orientation == OrientationEventListener.ORIENTATION_UNKNOWN) return
                
                val newRotation = when (orientation) {
                    in 340..360, in 0 until 20 -> Surface.ROTATION_0
                    in 70 until 110 -> Surface.ROTATION_270
                    in 160 until 200 -> Surface.ROTATION_180
                    in 250 until 290 -> Surface.ROTATION_90
                    else -> currentRotation 
                }
                
                if (newRotation != currentRotation && newRotation != -1) {
                    currentRotation = newRotation
                    
                    val orientationText = when (currentRotation) {
                        Surface.ROTATION_0 -> "縦 (Portrait)"
                        Surface.ROTATION_180 -> "縦 (逆Portrait)"
                        Surface.ROTATION_90 -> "横 (Landscape)"
                        Surface.ROTATION_270 -> "横 (逆Landscape)"
                        else -> "不明"
                    }
                    
                    runOnUiThread {
                        orientationTextView.text = "向き: $orientationText"
                        if (currentRotation == Surface.ROTATION_0 || currentRotation == Surface.ROTATION_180) {
                            orientationTextView.setTextColor(Color.WHITE)
                        } else {
                            orientationTextView.setTextColor(Color.YELLOW)
                        }
                    }

                    try {
                        imageCapture?.targetRotation = currentRotation
                    } catch (e: Exception) {}
                }
            }
        }
    }

    // ★追加: 解像度選択ダイアログの表示
    private fun showResolutionDialog() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(this)
        cameraProviderFuture.addListener({
            val cameraProvider = cameraProviderFuture.get()
            val cameraInfo = cameraProvider.availableCameraInfos.firstOrNull {
                val facing = Camera2CameraInfo.from(it).getCameraCharacteristic<Int>(android.hardware.camera2.CameraCharacteristics.LENS_FACING)
                facing == android.hardware.camera2.CameraMetadata.LENS_FACING_BACK
            } ?: return@addListener

            val map = Camera2CameraInfo.from(cameraInfo)
                .getCameraCharacteristic(android.hardware.camera2.CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP)
            
            val sizes: Array<Size> = map?.getOutputSizes(android.graphics.ImageFormat.JPEG)
                ?.sortedByDescending { it.width * it.height }?.toTypedArray() ?: emptyArray()

            val sizeLabels = sizes.map { size -> 
                "${size.width} x ${size.height} (${getAspectRatioString(size)})" 
            }.toTypedArray()

            AlertDialog.Builder(this)
                .setTitle("解像度を選択")
                .setItems(sizeLabels) { _: DialogInterface, which: Int ->
                    selectedResolution = sizes[which]
                    startCamera() 
                }
                .setNegativeButton("キャンセル", null)
                .show()
        }, ContextCompat.getMainExecutor(this))
    }

    // ★追加: アスペクト比の計算
    private fun getAspectRatioString(size: Size): String {
        fun calculateGcd(a: Int, b: Int): Int {
            var x = a; var y = b
            while (y != 0) { val t = x % y; x = y; y = t }; return x
        }
        val gcdValue = calculateGcd(size.width, size.height)
        return "${size.width / gcdValue}:${size.height / gcdValue}"
    }

    private fun toggleTorch() {
        val cameraControl = camera?.cameraControl ?: return
        isTorchOn = !isTorchOn
        cameraControl.enableTorch(isTorchOn)
        // ★修正: テキストカラーの変更
        torchButton.setTextColor(if (isTorchOn) Color.YELLOW else Color.WHITE)
    }

    override fun onResume() {
        super.onResume()
        orientationEventListener?.enable()
        accelerometer?.let {
            sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_GAME)
        }
    }

    override fun onPause() {
        super.onPause()
        orientationEventListener?.disable()
        sensorManager.unregisterListener(this)
    }

    override fun onSensorChanged(event: SensorEvent?) {
        event ?: return
        if (isWaitingForProcessing) return 
        
        var x = event.values[0]
        var y = event.values[1]
        var z = event.values[2]

        if (event.sensor.type == Sensor.TYPE_ACCELEROMETER) {
            if (!gravityInitialized) {
                gravity[0] = x; gravity[1] = y; gravity[2] = z
                gravityInitialized = true
            }
            gravity[0] = alpha * gravity[0] + (1 - alpha) * x
            gravity[1] = alpha * gravity[1] + (1 - alpha) * y
            gravity[2] = alpha * gravity[2] + (1 - alpha) * z
            x -= gravity[0]; y -= gravity[1]; z -= gravity[2]
        }

        val norm = sqrt(x * x + y * y + z * z)
        if (norm < STABILITY_THRESHOLD) stableFrameCount++ else stableFrameCount = 0
        isDeviceStable = stableFrameCount >= REQUIRED_STABLE_FRAMES

        val score = ((1.0f - (norm / (STABILITY_THRESHOLD * 1.5f))) * 100).toInt().coerceIn(0, 100)
        updateStabilityUI(score)
    }

    private fun updateStabilityUI(score: Int) {
        if (isWaitingForProcessing) return
        runOnUiThread {
            stabilityBar.progress = score
            if (isDeviceStable) {
                stabilityBar.progressTintList = ColorStateList.valueOf(Color.GREEN)
                if (!isCapturingInProgress) {
                    shutterButton.isEnabled = true
                    shutterButton.alpha = 1.0f
                }
                statusTextView.text = "書類撮影 (OK)"
                statusTextView.setTextColor(Color.GREEN)
            } else {
                stabilityBar.progressTintList = ColorStateList.valueOf(Color.RED)
                shutterButton.isEnabled = false
                shutterButton.alpha = 0.5f
                statusTextView.text = "端末を固定してください..."
                statusTextView.setTextColor(Color.RED)
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    private fun startCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(this)
        cameraProviderFuture.addListener({
            val cameraProvider = cameraProviderFuture.get()

            // ★修正: 解像度が選択されている場合はそれを適用する
            val resStrategy = if (selectedResolution != null) {
                ResolutionStrategy(selectedResolution!!, ResolutionStrategy.FALLBACK_RULE_CLOSEST_HIGHER)
            } else {
                ResolutionStrategy.HIGHEST_AVAILABLE_STRATEGY
            }

            val resolutionSelector = ResolutionSelector.Builder()
                .setAspectRatioStrategy(AspectRatioStrategy.RATIO_4_3_FALLBACK_AUTO_STRATEGY)
                .setResolutionStrategy(resStrategy)
                .build()

            val preview = Preview.Builder()
                .setResolutionSelector(resolutionSelector)
                .build()
                .also { it.setSurfaceProvider(viewFinder.surfaceProvider) }

            imageCapture = ImageCapture.Builder()
                .setCaptureMode(ImageCapture.CAPTURE_MODE_MAXIMIZE_QUALITY)
                .setResolutionSelector(resolutionSelector)
                .setTargetRotation(if (currentRotation != -1) currentRotation else viewFinder.display.rotation) 
                .build()

            try {
                cameraProvider.unbindAll()
                camera = cameraProvider.bindToLifecycle(this, CameraSelector.DEFAULT_BACK_CAMERA, preview, imageCapture)
                updateResolutionText() // ★追加: 解像度テキストの更新
            } catch (e: Exception) { 
                Log.e(TAG, "Bind fail", e)
                Toast.makeText(this, "カメラの起動に失敗しました", Toast.LENGTH_SHORT).show()
            }
        }, ContextCompat.getMainExecutor(this))
    }

    // ★追加: 解像度表示の更新
    private fun updateResolutionText() {
        val resolution = imageCapture?.resolutionInfo?.resolution
        runOnUiThread {
            if (resolution != null) {
                resTextView.text = "解像度: ${resolution.width}x${resolution.height}"
            }
        }
    }

    private fun takePhoto() {
        val ic = imageCapture ?: return
        
        isCapturingInProgress = true
        shutterButton.isEnabled = false
        shutterButton.alpha = 0.5f

        triggerShutterEffect()
        
        processingCount.incrementAndGet()
        updateDoneButtonText()

        val photoFile = File(getOutputDirectory(), SimpleDateFormat(FILENAME_FORMAT, Locale.US).format(System.currentTimeMillis()) + ".jpg")
        
        if (currentRotation != -1) {
            ic.targetRotation = currentRotation
        }

        val metadata = ImageCapture.Metadata().apply {
            isReversedHorizontal = false
        }

        val outputOptions = ImageCapture.OutputFileOptions.Builder(photoFile)
            .setMetadata(metadata)
            .build()

        ic.takePicture(outputOptions, ContextCompat.getMainExecutor(this),
            object : ImageCapture.OnImageSavedCallback {
                override fun onError(e: ImageCaptureException) { 
                    Log.e(TAG, "Capture fail: ${e.message}")
                    runOnUiThread {
                        Toast.makeText(baseContext, "撮影エラー", Toast.LENGTH_SHORT).show()
                        checkAndCompleteProcessing(success = false)
                        isCapturingInProgress = false
                        updateStabilityUI(stabilityBar.progress)
                    }
                }
                override fun onImageSaved(res: ImageCapture.OutputFileResults) {
                    runOnUiThread {
                        isCapturingInProgress = false
                        shutterButton.postDelayed({
                            updateStabilityUI(stabilityBar.progress)
                        }, 500)
                    }
                    cameraExecutor.execute {
                        processCapturedImage(photoFile)
                    }
                }
            })
    }

    private fun processCapturedImage(file: File) {
        var originalBitmap: Bitmap? = null
        var rotatedBitmap: Bitmap? = null
        var croppedBitmap: Bitmap? = null
        var enhancedBitmap: Bitmap? = null
        var maskMat: org.opencv.core.Mat? = null

        try {
            val path = file.absolutePath
            val options = BitmapFactory.Options().apply { inMutable = true }
            originalBitmap = BitmapFactory.decodeFile(path, options) ?: return

            rotatedBitmap = fixRotation(originalBitmap, path)
            if (rotatedBitmap != originalBitmap) {
                originalBitmap.recycle()
                originalBitmap = null
            }
            
            if (docDetector != null) {
                maskMat = docDetector!!.detectMask(rotatedBitmap!!)
            }

            if (maskMat != null) {
                croppedBitmap = DocumentCropper.processFullPipeline(rotatedBitmap!!, maskMat!!)
            }
            
            val sourceForEnhancement = croppedBitmap ?: rotatedBitmap
            
            enhancedBitmap = DocumentCropper.applyGeminiFilter(sourceForEnhancement!!)
            
            if (enhancedBitmap != sourceForEnhancement) {
                if (sourceForEnhancement == croppedBitmap) croppedBitmap?.recycle()
                if (sourceForEnhancement == rotatedBitmap) rotatedBitmap?.recycle()
                croppedBitmap = null
                rotatedBitmap = null
            }

            saveBitmap(enhancedBitmap, file)

            synchronized(capturedPaths) {
                capturedPaths.add(file.absolutePath)
            }

        } catch (e: Exception) {
            Log.e(TAG, "Process failed", e)
            runOnUiThread { 
                Toast.makeText(this, "保存失敗", Toast.LENGTH_SHORT).show() 
            }
        } finally {
            originalBitmap?.recycle()
            rotatedBitmap?.recycle()
            croppedBitmap?.recycle()
            enhancedBitmap?.recycle()
            maskMat?.release()
            
            checkAndCompleteProcessing(success = true)
        }
    }

    private fun checkAndCompleteProcessing(success: Boolean) {
        val remaining = processingCount.decrementAndGet()
        runOnUiThread { 
            updateDoneButtonText()
            if (isWaitingForProcessing && remaining == 0) {
                finishWithResult()
            }
        }
    }
    
    private fun fixRotation(bitmap: Bitmap, path: String): Bitmap {
        try {
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
        } catch (e: Exception) { return bitmap }
    }

    private fun saveBitmap(bitmap: Bitmap, file: File) {
        FileOutputStream(file).use { out ->
            bitmap.compress(Bitmap.CompressFormat.JPEG, 95, out)
        }
    }

    private fun updateDoneButtonText() {
        runOnUiThread { 
            val count = capturedPaths.size
            doneButton.text = "完了 ($count)"
        }
    }

    private fun finishWithResult() {
        val intent = Intent()
        intent.putStringArrayListExtra("captured_paths", capturedPaths)
        setResult(RESULT_OK, intent)
        finish()
    }

    private fun getOutputDirectory(): File {
        val outputDir = File(filesDir, "AiScanApp").apply { mkdirs() }
        return outputDir
    }

    private fun triggerShutterEffect() {
        runOnUiThread {
            shutterEffectView.visibility = View.VISIBLE
            shutterEffectView.alpha = 0.7f
            shutterEffectView.animate().alpha(0f).setDuration(100).withEndAction { shutterEffectView.visibility = View.GONE }.start()
        }
    }

    private fun allPermissionsGranted() = getRequiredPermissions().all {
        ContextCompat.checkSelfPermission(baseContext, it) == PackageManager.PERMISSION_GRANTED
    }

    private fun getRequiredPermissions(): Array<String> {
        return arrayOf(Manifest.permission.CAMERA)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_CODE_PERMISSIONS) {
            if (allPermissionsGranted()) {
                viewFinder.post { startCamera() }
            } else {
                Toast.makeText(this, "カメラへのアクセスを許可してください", Toast.LENGTH_LONG).show()
                finish()
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        orientationEventListener?.disable()
        docDetector?.close()
        cameraExecutor.shutdown()
    }
    
    companion object { 
        private const val TAG = "CameraXApp"
        private const val FILENAME_FORMAT = "yyyy-MM-dd-HH-mm-ss-SSS"
        private const val REQUEST_CODE_PERMISSIONS = 10
    }
}