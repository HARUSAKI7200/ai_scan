// app/src/main/kotlin/com/example/ai_scan/utils/DocumentCornerDetector.kt

package com.example.ai_scan.utils

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import org.opencv.core.Core
import org.opencv.core.CvType
import org.opencv.core.Mat
import org.opencv.core.Point
import org.opencv.core.Scalar
import org.opencv.imgproc.Imgproc
import org.tensorflow.lite.Interpreter 
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.channels.FileChannel
import kotlin.math.exp
import kotlin.math.max
import kotlin.math.min

class DocumentCornerDetector(private val context: Context) {
    private var interpreter: Interpreter? = null
    
    private val INPUT_SIZE = 640 
    private val MODEL_FILENAME = "models/yolo_nano_v1_32.tflite"
    private val CLASS_INDEX_DOCUMENT = 0 
    private val IDX_CLASS_START = 4

    private val MASK_THRESHOLD = 0.85f

    init {
        try {
            val assetFileDescriptor = context.assets.openFd(MODEL_FILENAME)
            val fileChannel = FileInputStream(assetFileDescriptor.fileDescriptor).channel
            val modelBuffer = fileChannel.map(FileChannel.MapMode.READ_ONLY, assetFileDescriptor.startOffset, assetFileDescriptor.declaredLength)
            
            val options = Interpreter.Options()
            options.setNumThreads(4)
            interpreter = Interpreter(modelBuffer, options)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun detectMask(bitmap: Bitmap): Mat? {
        val interpreter = interpreter ?: return null

        val info = preprocessLetterbox(bitmap)

        val outputDetect = Array(1) { Array(37) { FloatArray(8400) } } 
        val outputProtoBuffer = ByteBuffer.allocateDirect(1 * 160 * 160 * 32 * 4).order(ByteOrder.nativeOrder())
        val outputs = mapOf(0 to outputDetect, 1 to outputProtoBuffer)

        interpreter.runForMultipleInputsOutputs(arrayOf(info.buffer), outputs)

        val bestAnchorIndex = findBestAnchor(outputDetect[0])
        if (bestAnchorIndex == -1) return null

        val cx = outputDetect[0][0][bestAnchorIndex] * INPUT_SIZE
        val cy = outputDetect[0][1][bestAnchorIndex] * INPUT_SIZE
        val w = outputDetect[0][2][bestAnchorIndex] * INPUT_SIZE
        val h = outputDetect[0][3][bestAnchorIndex] * INPUT_SIZE
        
        val originalWidth = bitmap.width.toDouble()
        val originalHeight = bitmap.height.toDouble()
        
        val x1 = (((cx - w / 2) - info.padX) / info.ratio).toDouble()
        val y1 = (((cy - h / 2) - info.padY) / info.ratio).toDouble()
        val x2 = (((cx + w / 2) - info.padX) / info.ratio).toDouble()
        val y2 = (((cy + h / 2) - info.padY) / info.ratio).toDouble()
        
        val safeX1 = max(0.0, min(x1, originalWidth - 2.0)).toInt()
        val safeY1 = max(0.0, min(y1, originalHeight - 2.0)).toInt()
        val safeX2 = max(1.0, min(x2, originalWidth - 1.0)).toInt()
        val safeY2 = max(1.0, min(y2, originalHeight - 1.0)).toInt()

        val coeffs = FloatArray(32)
        for (i in 0 until 32) {
            coeffs[i] = outputDetect[0][5 + i][bestAnchorIndex]
        }

        outputProtoBuffer.rewind()
        val protoFloatBuffer = outputProtoBuffer.asFloatBuffer()

        val mask160 = Mat(160, 160, CvType.CV_32F)
        val maskData = FloatArray(160 * 160)
        for (y in 0 until 160) {
            for (x in 0 until 160) {
                var sum = 0f
                for (c in 0 until 32) {
                    sum += protoFloatBuffer.get(y * 160 * 32 + x * 32 + c) * coeffs[c]
                }
                maskData[y * 160 + x] = 1.0f / (1.0f + exp(-sum))
            }
        }
        mask160.put(0, 0, maskData)

        val mask640 = Mat()
        Imgproc.resize(mask160, mask640, org.opencv.core.Size(INPUT_SIZE.toDouble(), INPUT_SIZE.toDouble()))

        val binaryMask640 = Mat()
        Imgproc.threshold(mask640, binaryMask640, MASK_THRESHOLD.toDouble(), 255.0, Imgproc.THRESH_BINARY)
        binaryMask640.convertTo(binaryMask640, CvType.CV_8U)

        val roiX = max(0, min(info.padX.toInt(), INPUT_SIZE - 1))
        val roiY = max(0, min(info.padY.toInt(), INPUT_SIZE - 1))
        val roiW = max(1, min((INPUT_SIZE - 2 * info.padX).toInt(), INPUT_SIZE - roiX))
        val roiH = max(1, min((INPUT_SIZE - 2 * info.padY).toInt(), INPUT_SIZE - roiY))

        val croppedMask640 = Mat(binaryMask640, org.opencv.core.Rect(roiX, roiY, roiW, roiH))
        val finalMask = Mat()
        Imgproc.resize(croppedMask640, finalMask, org.opencv.core.Size(originalWidth, originalHeight))

        val bboxMask = Mat.zeros(finalMask.size(), CvType.CV_8U)
        if (safeX1 < safeX2 && safeY1 < safeY2) {
            Imgproc.rectangle(bboxMask, Point(safeX1.toDouble(), safeY1.toDouble()), Point(safeX2.toDouble(), safeY2.toDouble()), Scalar(255.0), -1)
        }
        Core.bitwise_and(finalMask, bboxMask, finalMask)

        mask160.release(); mask640.release(); binaryMask640.release()
        croppedMask640.release(); bboxMask.release()

        return finalMask
    }

    private fun findBestAnchor(detectionData: Array<FloatArray>): Int {
        val documentScoreRow = detectionData[IDX_CLASS_START + CLASS_INDEX_DOCUMENT]
        var maxScore = 0f
        var bestIdx = -1
        val threshold = 0.50f 

        for (i in documentScoreRow.indices) {
            val score = documentScoreRow[i]
            if (score > maxScore && score > threshold) {
                maxScore = score
                bestIdx = i
            }
        }
        return bestIdx
    }

    private data class LetterboxInfo(val buffer: ByteBuffer, val ratio: Float, val padX: Float, val padY: Float)

    private fun preprocessLetterbox(bitmap: Bitmap): LetterboxInfo {
        val width = bitmap.width
        val height = bitmap.height
        val ratio = INPUT_SIZE.toFloat() / maxOf(width, height)
        val newWidth = (width * ratio).toInt()
        val newHeight = (height * ratio).toInt()

        val resized = Bitmap.createScaledBitmap(bitmap, newWidth, newHeight, true)
        val padX = (INPUT_SIZE - newWidth) / 2f
        val padY = (INPUT_SIZE - newHeight) / 2f

        val canvasBitmap = Bitmap.createBitmap(INPUT_SIZE, INPUT_SIZE, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(canvasBitmap)
        canvas.drawBitmap(resized, padX, padY, null)

        val byteBuffer = ByteBuffer.allocateDirect(4 * INPUT_SIZE * INPUT_SIZE * 3).apply { order(ByteOrder.nativeOrder()) }
        val intValues = IntArray(INPUT_SIZE * INPUT_SIZE)
        canvasBitmap.getPixels(intValues, 0, INPUT_SIZE, 0, 0, INPUT_SIZE, INPUT_SIZE)

        for (pixel in intValues) {
            byteBuffer.putFloat(((pixel shr 16) and 0xFF) / 255.0f) 
            byteBuffer.putFloat(((pixel shr 8) and 0xFF) / 255.0f)  
            byteBuffer.putFloat((pixel and 0xFF) / 255.0f)         
        }
        
        if (!canvasBitmap.isRecycled) canvasBitmap.recycle()
        if (!resized.isRecycled) resized.recycle()
        
        return LetterboxInfo(byteBuffer, ratio, padX, padY)
    }

    fun close() {
        interpreter?.close()
    }
}