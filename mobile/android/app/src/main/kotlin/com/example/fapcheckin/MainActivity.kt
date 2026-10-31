package com.example.fapcheckin

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.graphics.BitmapFactory
import androidx.exifinterface.media.ExifInterface
import java.io.ByteArrayInputStream
import java.util.concurrent.Executors
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions

class MainActivity : FlutterActivity() {
    private val worker = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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

    override fun onDestroy() {
        worker.shutdown()
        super.onDestroy()
    }
}
