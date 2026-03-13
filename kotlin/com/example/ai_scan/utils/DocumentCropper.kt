// app/src/main/kotlin/com/example/ai_scan/utils/DocumentCropper.kt

package com.example.ai_scan.utils

import android.graphics.Bitmap
import org.opencv.android.Utils
import org.opencv.core.*
import org.opencv.imgproc.Imgproc
import kotlin.math.*

object DocumentCropper {

    private fun safeMatToBitmap(src: Mat): Bitmap {
        if (src.empty() || src.width() <= 0 || src.height() <= 0) {
            return Bitmap.createBitmap(1, 1, Bitmap.Config.ARGB_8888)
        }
        val validSrc = if (src.channels() == 1) {
            val rgba = Mat()
            Imgproc.cvtColor(src, rgba, Imgproc.COLOR_GRAY2RGBA)
            rgba
        } else {
            src
        }
        val bmp = Bitmap.createBitmap(validSrc.width(), validSrc.height(), Bitmap.Config.ARGB_8888)
        Utils.matToBitmap(validSrc, bmp)
        if (validSrc != src) validSrc.release()
        return bmp
    }

    /**
     * Gemini専用フィルタ (統合版)
     * ・グレースケール化：しない（カラー情報を維持して認識精度向上）
     * ・コントラスト強調：しない（自然な画質を維持）
     * ・リサイズ：長辺3500px制限
     */
    fun applyGeminiFilter(bitmap: Bitmap): Bitmap {
        if (bitmap.isRecycled) return bitmap
        val srcMat = Mat()
        Utils.bitmapToMat(bitmap, srcMat)
        
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
        
        val outBitmap = safeMatToBitmap(resizedMat)
        resizedMat.release()
        return outBitmap
    }

    /**
     * 黒塗りマスク・凸包エッジ交差法 (Masked Hull Intersection Warp)
     * デバッグコードを完全削除した最適化版
     */
    fun processFullPipeline(srcBitmap: Bitmap, maskMat: Mat): Bitmap? {
        if (srcBitmap.isRecycled || maskMat.empty()) return null

        val srcMat = Mat()
        Utils.bitmapToMat(srcBitmap, srcMat)

        if (srcMat.channels() != 4) {
            Imgproc.cvtColor(srcMat, srcMat, Imgproc.COLOR_RGB2RGBA)
        }

        val processedMask = Mat()
        val kernel = Imgproc.getStructuringElement(Imgproc.MORPH_RECT, Size(5.0, 5.0))
        Imgproc.morphologyEx(maskMat, processedMask, Imgproc.MORPH_OPEN, kernel)

        val maskedSrc = Mat(srcMat.size(), srcMat.type(), Scalar(0.0, 0.0, 0.0, 255.0))
        srcMat.copyTo(maskedSrc, processedMask)

        val contours = mutableListOf<MatOfPoint>()
        Imgproc.findContours(processedMask, contours, Mat(), Imgproc.RETR_EXTERNAL, Imgproc.CHAIN_APPROX_SIMPLE)
        
        var bestContour: MatOfPoint? = null
        var maxScore = 0.0

        for (contour in contours) {
            val area = Imgproc.contourArea(contour)
            if (area < 1000) continue 

            val mat2f = MatOfPoint2f(*contour.toArray())
            val peri = Imgproc.arcLength(mat2f, true)
            val approx = MatOfPoint2f()
            Imgproc.approxPolyDP(mat2f, approx, 0.02 * peri, true)

            val vertexCount = approx.total().toInt()
            val points = MatOfPoint(*approx.toArray())
            val isConvex = Imgproc.isContourConvex(points)

            var score = area
            if (vertexCount == 4) score *= 1.2
            if (isConvex) score *= 1.1

            if (score > maxScore) {
                maxScore = score
                bestContour = contour
            }
            
            mat2f.release()
            approx.release()
            points.release()
        }

        var resultBitmap: Bitmap? = null

        if (bestContour != null) {
            val hullIndices = MatOfInt()
            Imgproc.convexHull(bestContour, hullIndices)
            val contourPoints = bestContour.toArray()
            val hullPoints = hullIndices.toArray().map { contourPoints[it] }
            val hullContour = MatOfPoint2f(*hullPoints.toTypedArray())

            val minRect = Imgproc.minAreaRect(hullContour)
            val baseAngle = minRect.angle

            val bestLines = findBestHullLines(hullPoints, baseAngle, srcMat.width(), srcMat.height())

            if (bestLines != null) {
                val tl = computeIntersection(bestLines[0], bestLines[2])
                val tr = computeIntersection(bestLines[0], bestLines[3])
                val br = computeIntersection(bestLines[1], bestLines[3])
                val bl = computeIntersection(bestLines[1], bestLines[2])

                if (tl != null && tr != null && br != null && bl != null) {
                    val corners = arrayOf(tl, tr, br, bl)
                    val sortedCorners = sortCorners(corners)
                    resultBitmap = warpPerspective(srcMat, sortedCorners)
                } else {
                    resultBitmap = fallbackWarp(srcMat, minRect)
                }
            } else {
                resultBitmap = fallbackWarp(srcMat, minRect)
            }
            
            hullIndices.release()
            hullContour.release()
        } else {
            resultBitmap = srcBitmap
        }

        srcMat.release()
        maskedSrc.release()
        processedMask.release()
        kernel.release()
        contours.forEach { it.release() }
        
        return resultBitmap
    }

    private fun findBestHullLines(hullPoints: List<Point>, baseAngle: Double, w: Int, h: Int): Array<DoubleArray>? {
        if (hullPoints.size < 3) return null

        var bestTop: DoubleArray? = null; var maxLenTop = -1.0
        var bestBottom: DoubleArray? = null; var maxLenBottom = -1.0
        var bestLeft: DoubleArray? = null; var maxLenLeft = -1.0
        var bestRight: DoubleArray? = null; var maxLenRight = -1.0

        val center = Point(w / 2.0, h / 2.0)
        val rad = Math.toRadians(-baseAngle)
        val cosA = cos(rad)
        val sinA = sin(rad)

        for (i in hullPoints.indices) {
            val p1 = hullPoints[i]
            val p2 = hullPoints[(i + 1) % hullPoints.size]

            val x1 = p1.x; val y1 = p1.y
            val x2 = p2.x; val y2 = p2.y

            val dx = x2 - x1
            val dy = y2 - y1
            val lenSq = dx*dx + dy*dy
            if (lenSq < 100) continue 

            val a = y1 - y2
            val b = x2 - x1
            val c = x1 * y2 - x2 * y1
            val norm = sqrt(a*a + b*b)
            val lineData = doubleArrayOf(a/norm, b/norm, c/norm) 

            val midX = (x1 + x2) / 2.0
            val midY = (y1 + y2) / 2.0
            
            val rDx = midX - center.x
            val rDy = midY - center.y
            val rotX = rDx * cosA - rDy * sinA
            val rotY = rDx * sinA + rDy * cosA

            var angle = atan2(dy, dx) * 180.0 / Math.PI
            var relAngle = abs((angle - baseAngle) % 180.0)
            if (relAngle > 90) relAngle = 180 - relAngle

            if (relAngle < 20) {
                if (rotY < 0) { 
                    if (lenSq > maxLenTop) { maxLenTop = lenSq; bestTop = lineData }
                } else { 
                    if (lenSq > maxLenBottom) { maxLenBottom = lenSq; bestBottom = lineData }
                }
            }
            else if (relAngle > 70) {
                if (rotX < 0) { 
                    if (lenSq > maxLenLeft) { maxLenLeft = lenSq; bestLeft = lineData }
                } else { 
                    if (lenSq > maxLenRight) { maxLenRight = lenSq; bestRight = lineData }
                }
            }
        }

        if (bestTop == null || bestBottom == null || bestLeft == null || bestRight == null) return null
        return arrayOf(bestTop, bestBottom, bestLeft, bestRight)
    }

    private fun computeIntersection(l1: DoubleArray, l2: DoubleArray): Point? {
        val a1 = l1[0]; val b1 = l1[1]; val c1 = l1[2]
        val a2 = l2[0]; val b2 = l2[1]; val c2 = l2[2]
        val det = a1 * b2 - a2 * b1
        if (abs(det) < 1e-6) return null
        val x = (b1 * c2 - b2 * c1) / det
        val y = (c1 * a2 - c2 * a1) / det
        return Point(x, y)
    }

    private fun sortCorners(corners: Array<Point>): Array<Point> {
        var cx = 0.0; var cy = 0.0
        for (p in corners) { cx += p.x; cy += p.y }
        cx /= 4.0; cy /= 4.0
        val center = Point(cx, cy)
        
        val sorted = corners.sortedBy { atan2(it.y - center.y, it.x - center.x) }
        
        val tl = sorted.firstOrNull { it.x < center.x && it.y < center.y } ?: sorted[0]
        val tr = sorted.firstOrNull { it.x > center.x && it.y < center.y } ?: sorted[1]
        val br = sorted.firstOrNull { it.x > center.x && it.y > center.y } ?: sorted[2]
        val bl = sorted.firstOrNull { it.x < center.x && it.y > center.y } ?: sorted[3]
        return arrayOf(tl, tr, br, bl)
    }

    private fun fallbackWarp(src: Mat, minRect: RotatedRect): Bitmap? {
        val points = Array(4) { Point() }
        minRect.points(points)
        val sorted = sortCorners(points)
        return warpPerspective(src, sorted)
    }

    private fun warpPerspective(src: Mat, corners: Array<Point>): Bitmap? {
        val widthA = hypot(corners[0].x - corners[1].x, corners[0].y - corners[1].y)
        val widthB = hypot(corners[3].x - corners[2].x, corners[3].y - corners[2].y)
        val maxWidth = maxOf(widthA, widthB).toInt()

        val heightA = hypot(corners[0].x - corners[3].x, corners[0].y - corners[3].y)
        val heightB = hypot(corners[1].x - corners[2].x, corners[1].y - corners[2].y)
        val maxHeight = maxOf(heightA, heightB).toInt()

        if (maxWidth <= 0 || maxHeight <= 0) return null

        val dstPoints = arrayOf(
            Point(0.0, 0.0),
            Point(maxWidth.toDouble() - 1, 0.0),
            Point(maxWidth.toDouble() - 1, maxHeight.toDouble() - 1),
            Point(0.0, maxHeight.toDouble() - 1)
        )

        val srcMat = MatOfPoint2f(*corners)
        val dstMat = MatOfPoint2f(*dstPoints)
        val transform = Imgproc.getPerspectiveTransform(srcMat, dstMat)
        val dst = Mat()
        Imgproc.warpPerspective(src, dst, transform, Size(maxWidth.toDouble(), maxHeight.toDouble()))

        val bmp = safeMatToBitmap(dst)
        dst.release(); transform.release(); srcMat.release(); dstMat.release()
        return bmp
    }
}