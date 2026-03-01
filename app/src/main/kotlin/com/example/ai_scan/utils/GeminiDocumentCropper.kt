// app/src/main/kotlin/com/example/nifuda_gpt_app_fixed/utils/GeminiDocumentCropper.kt

package com.example.nifuda_gpt_app_fixed.utils

import android.graphics.Bitmap
import org.opencv.android.Utils
import org.opencv.core.*
import org.opencv.imgproc.Imgproc
import kotlin.math.max

object GeminiDocumentCropper {

    private fun safeMatToBitmap(src: Mat): Bitmap {
        if (src.empty() || src.width() <= 0 || src.height() <= 0) {
            return Bitmap.createBitmap(1, 1, Bitmap.Config.ARGB_8888)
        }
        // OpenCVのMat(BGR/RGB)をAndroidのBitmap(ARGB)に変換
        // Config.ARGB_8888を使用することでカラー情報を保持します
        val bmp = Bitmap.createBitmap(src.width(), src.height(), Bitmap.Config.ARGB_8888)
        Utils.matToBitmap(src, bmp)
        return bmp
    }

    /**
     * Gemini専用フィルタ
     * ・グレースケール化：しない（カラー情報を維持して認識精度向上）
     * ・コントラスト強調：しない（自然な画質を維持）
     * ・リサイズ：長辺3500px制限（Geminiの得意なサイズ感に合わせる）
     */
    fun applyGeminiFilter(bitmap: Bitmap): Bitmap {
        if (bitmap.isRecycled) return bitmap
        val srcMat = Mat()
        Utils.bitmapToMat(bitmap, srcMat)
        
        // 1. リサイズ (長辺3500px制限)
        // Geminiは3072px程度でタイル処理されるため、大きすぎると縮小コストがかかるだけ。
        // 3500px程度に抑えるのがベストプラクティス。
        val targetMax = 3500.0
        val currentMax = maxOf(srcMat.width(), srcMat.height()).toDouble()
        val scaleFactor = if (currentMax > targetMax) targetMax / currentMax else 1.0
        
        val resizedMat = Mat()
        if (scaleFactor < 1.0) {
            Imgproc.resize(srcMat, resizedMat, Size(), scaleFactor, scaleFactor, Imgproc.INTER_LINEAR)
            srcMat.release()
        } else {
            srcMat.copyTo(resizedMat)
            srcMat.release()
        }

        // ★ここがGPT用との違い：
        // グレースケール変換 (cvtColor) を行わず、カラーのまま出力する。
        
        val outBitmap = safeMatToBitmap(resizedMat)
        
        resizedMat.release()
        return outBitmap
    }
}