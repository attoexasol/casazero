package com.example.casazero

import android.app.AlertDialog
import android.content.DialogInterface
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.casazero/file_opener"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "showOpenCancelConfirmation" -> {
                    val title = call.argument<String>("title") ?: "Open"
                    val message = call.argument<String>("message") ?: "Open this file?"
                    showNativeOpenCancelConfirmation(title, message, result)
                }
                "openWithChooser" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        openFileWithChooser(filePath, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "File path is null", null)
                    }
                }
                "indexFileInMediaStore" -> {
                    val filePath = call.argument<String>("filePath")
                    val fileName = call.argument<String>("fileName")
                    if (filePath != null && fileName != null) {
                        indexFileInMediaStore(filePath, fileName, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "File path or name is null", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun showNativeOpenCancelConfirmation(
        title: String,
        message: String,
        result: MethodChannel.Result
    ) {
        runOnUiThread {
            AlertDialog.Builder(this)
                .setTitle(title)
                .setMessage(message)
                .setPositiveButton("Open") { _: DialogInterface?, _: Int ->
                    result.success(true)
                }
                .setNegativeButton("Cancel") { _: DialogInterface?, _: Int ->
                    result.success(false)
                }
                .setOnCancelListener {
                    result.success(false)
                }
                .create()
                .show()
        }
    }

    private fun openFileWithChooser(filePath: String, result: MethodChannel.Result) {
        try {
            val file = File(filePath)
            if (!file.exists()) {
                result.success(mapOf("type" to "fileNotFound", "message" to "File not found"))
                return
            }

            val uri: Uri = try {
                // Try FileProvider first (for app-private files and external files)
                FileProvider.getUriForFile(
                    this,
                    "${applicationContext.packageName}.fileprovider",
                    file
                )
            } catch (e: Exception) {
                // Fallback to file:// URI if FileProvider fails
                // This works for files in public directories like Downloads
                Uri.fromFile(file)
            }

            // Create intent with ACTION_VIEW and generic MIME type (*/*) to force chooser
            // Using */* ensures ALL apps that can handle the file are shown
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "*/*")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            // CRITICAL: Use Intent.createChooser to ALWAYS show the chooser
            // This prevents auto-opening even if a default app is set for images
            // The chooser will appear for ALL file types including images
            val chooser = Intent.createChooser(intent, "Open with...")
            chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            
            startActivity(chooser)
            result.success(mapOf("type" to "done", "message" to "Chooser shown successfully"))
        } catch (e: Exception) {
            result.success(mapOf("type" to "error", "message" to (e.message ?: "Unknown error")))
        }
    }

    private fun indexFileInMediaStore(filePath: String, fileName: String, result: MethodChannel.Result) {
        try {
            val file = File(filePath)
            if (!file.exists()) {
                result.success(false)
                return
            }

            val mimeType = getMimeType(fileName)

            // Scan the existing file on disk so it appears in Downloads / file managers
            // without creating an empty MediaStore entry.
            MediaScannerConnection.scanFile(
                applicationContext,
                arrayOf(filePath),
                arrayOf(mimeType)
            ) { _, _ ->
                result.success(true)
            }
        } catch (e: Exception) {
            // Don't fail - file is still saved even if MediaStore indexing fails
            result.success(false)
        }
    }

    private fun getMimeType(fileName: String): String {
        val extension = fileName.substringAfterLast('.', "").lowercase()
        return when (extension) {
            "pdf" -> "application/pdf"
            "jpg", "jpeg" -> "image/jpeg"
            "png" -> "image/png"
            "doc" -> "application/msword"
            "docx" -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            "xls" -> "application/vnd.ms-excel"
            "xlsx" -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            "txt" -> "text/plain"
            else -> "application/octet-stream"
        }
    }
}
