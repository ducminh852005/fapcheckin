package com.example.fapcheckin

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.Activity
import android.content.Intent
import android.graphics.BitmapFactory
import androidx.exifinterface.media.ExifInterface
import java.io.ByteArrayInputStream
import java.util.concurrent.Executors
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions

class MainActivity : FlutterActivity() {
    private val worker = Executors.newSingleThreadExecutor()
    private var exportResult: MethodChannel.Result? = null
    private var exportBytes: ByteArray? = null
    private val exportRequestCode = 8042

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fapcheckin/export")
            .setMethodCallHandler { call, result ->
                if (call.method != "saveXlsx") {
                    result.notImplemented()
                } else if (exportResult != null) {
                    result.error("EXPORT_BUSY", "Một file đang được lưu.", null)
                } else {
                    val bytes = call.argument<ByteArray>("bytes")
                    if (bytes == null || bytes.isEmpty()) {
                        result.error("INVALID_FILE", "File xuất rỗng.", null)
                        return@setMethodCallHandler
                    }
                    exportResult = result
                    exportBytes = bytes
                    try {
                        startActivityForResult(Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                            putExtra(Intent.EXTRA_TITLE, call.argument<String>("filename") ?: "attendance.xlsx")
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                        }, exportRequestCode)
                    } catch (e: Exception) {
                        exportResult = null
                        exportBytes = null
                        result.error("EXPORT_FAILED", e.message, null)
                    }
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fapcheckin/ocr")
            .setMethodCallHandler { call, result ->
                if (call.method != "recognize") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val bytes = call.argument<ByteArray>("bytes")
                if (bytes == null || bytes.isEmpty() || bytes.size > 5 * 1024 * 1024) {
                    result.error("INVALID_IMAGE", "Chọn ảnh JPG/PNG không quá 5 MB.", null)
                    return@setMethodCallHandler
                }
                worker.execute {
                    try {
                        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
                        require(bounds.outWidth > 0 && bounds.outHeight > 0)
                        var sample = 1
                        while (maxOf(bounds.outWidth, bounds.outHeight) / sample > 2500) sample *= 2
                        val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size,
                            BitmapFactory.Options().apply { inSampleSize = sample })
                            ?: throw IllegalArgumentException("Invalid image")
                        val rotation = ByteArrayInputStream(bytes).use {
                            ExifInterface(it).rotationDegrees
                        }
                        val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
                        recognizer.process(InputImage.fromBitmap(bitmap, rotation))
                            .addOnSuccessListener { text -> result.success(text.text) }
                            .addOnFailureListener { result.error("OCR_FAILED", "Không đọc được ảnh. Hãy chọn ảnh rõ hơn.", null) }
                            .addOnCompleteListener { recognizer.close(); bitmap.recycle() }
                    } catch (e: Exception) {
                        runOnUiThread { result.error("INVALID_IMAGE", "Không đọc được ảnh JPG/PNG.", null) }
                    }
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != exportRequestCode) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }
        val result = exportResult ?: return
        val bytes = exportBytes
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null || bytes == null) {
            exportResult = null
            exportBytes = null
            result.success(null)
            return
        }
        worker.execute {
            try {
                val output = contentResolver.openOutputStream(uri, "wt")
                    ?: throw IllegalStateException("Không mở được vị trí lưu.")
                output.use { it.write(bytes); it.flush() }
                runOnUiThread {
                    exportResult = null
                    exportBytes = null
                    result.success(uri.toString())
                }
            } catch (e: Exception) {
                runOnUiThread {
                    exportResult = null
                    exportBytes = null
                    result.error("EXPORT_FAILED", e.message, null)
                }
            }
        }
    }

    override fun onDestroy() {
        exportResult?.error("EXPORT_CANCELLED", "Màn hình đã đóng; vui lòng kiểm tra file trước khi thử lại.", null)
        exportResult = null
        exportBytes = null
        worker.shutdown()
        super.onDestroy()
    }
}
