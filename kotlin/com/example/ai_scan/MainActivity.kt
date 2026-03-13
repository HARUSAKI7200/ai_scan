package com.example.ai_scan

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.opencv.android.OpenCVLoader

class MainActivity: FlutterActivity() {
    private val CHANNEL_CAMERA = "com.example.app/camera"
    private val CAMERA_REQUEST_CODE = 1001

    private var cameraResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // OpenCVの初期化（書類の輪郭検知用）
        if (OpenCVLoader.initDebug()) {
            Log.i("OpenCV", "OpenCV loaded successfully")
        } else {
            Log.e("OpenCV", "OpenCV initialization failed!")
        }

        // Flutterからのカメラ起動メソッドを受け取るチャンネル
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_CAMERA).setMethodCallHandler { call, result ->
            if (call.method == "startNativeCamera") {
                cameraResult = result
                val isProductList = call.argument<Boolean>("is_product_list") ?: false
                
                val intent = Intent(this, CameraActivity::class.java)
                intent.putExtra("mode", if (isProductList) "product_list" else "tag")
                startActivityForResult(intent, CAMERA_REQUEST_CODE)
            } else {
                result.notImplemented()
            }
        }
    }

    // カメラアクティビティからの戻り値（撮影された画像のパスリスト）をFlutterへ返す
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == CAMERA_REQUEST_CODE) {
            val res = if (resultCode == RESULT_OK) {
                data?.getStringArrayListExtra("captured_paths")
            } else {
                null
            }
            cameraResult?.success(res)
            cameraResult = null
        }
    }
}