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

    // ★統一ログタグ
    private val TAG = "[AI_SCAN]_Native"

    private var cameraResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d(TAG, "🔵 INFO: configureFlutterEngine() - Flutterエンジン初期化")

        // OpenCVの初期化（書類の輪郭検知用）
        if (OpenCVLoader.initDebug()) {
            Log.d(TAG, "🟢 SUCCESS: OpenCV loaded successfully")
        } else {
            Log.e(TAG, "🔴 ERROR: OpenCV initialization failed!")
        }

        // Flutterからのカメラ起動メソッドを受け取るチャンネル
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_CAMERA).setMethodCallHandler { call, result ->
            if (call.method == "startNativeCamera") {
                Log.d(TAG, "🔵 INFO: Flutterから startNativeCamera が呼ばれました。")
                cameraResult = result
                val isProductList = call.argument<Boolean>("is_product_list") ?: false
                val isBatchAllowed = call.argument<Boolean>("is_batch_allowed") ?: true
                
                Log.d(TAG, "🔵 INFO: パラメータ -> isProductList: $isProductList, isBatchAllowed: $isBatchAllowed")
                
                val intent = Intent(this, CameraActivity::class.java)
                intent.putExtra("mode", if (isProductList) "product_list" else "tag")
                intent.putExtra("is_batch_allowed", isBatchAllowed) 
                
                startActivityForResult(intent, CAMERA_REQUEST_CODE)
            } else {
                Log.w(TAG, "🟡 WARN: 未知のメソッド呼び出し: ${call.method}")
                result.notImplemented()
            }
        }
    }

    // カメラアクティビティからの戻り値（撮影された画像のパスリスト）をFlutterへ返す
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == CAMERA_REQUEST_CODE) {
            Log.d(TAG, "🔵 INFO: onActivityResult() - CameraActivityから戻りました (resultCode: $resultCode)")
            val res = if (resultCode == RESULT_OK) {
                val paths = data?.getStringArrayListExtra("captured_paths")
                Log.d(TAG, "🟢 SUCCESS: 取得したパス数: ${paths?.size ?: 0}")
                paths
            } else {
                Log.d(TAG, "🟡 WARN: カメラ撮影がキャンセルされました。")
                null
            }
            cameraResult?.success(res)
            cameraResult = null
        }
    }
}