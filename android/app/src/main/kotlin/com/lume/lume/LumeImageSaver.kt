package com.lume.lume

import android.Manifest
import android.app.Activity
import android.content.ContentValues
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

/**
 * Puts one PNG in Pictures, and says it did only once it is there (C81).
 *
 * Replaces `gal` on Android: `gal` 2.3.3 inserts with a `.png` name and no
 * MIME type, and Android 10 then types the row `image/jpeg` and renames it
 * `….png.jpg` (reproduced on API 29 in the F6B closure).
 *
 * * **Android 10 and later** — a MediaStore row with `DISPLAY_NAME` ending
 *   `.png`, `MIME_TYPE` `image/png`, `RELATIVE_PATH` Pictures and
 *   `IS_PENDING` while the bytes are written. A taken name is renamed by
 *   MediaStore, never overwritten. A row whose write fails is deleted. No
 *   permission.
 * * **Android 7–9** — `WRITE_EXTERNAL_STORAGE`, declared only up to API 28 and
 *   asked on the press; a file in Pictures under a name not yet taken, then
 *   the media scanner, and "saved" only once the scanner has indexed it.
 *
 * Returns `{outcome, name, mime, uri}`; outcome is `saved`, `denied`,
 * `noSpace` or `failed`. `simulateFailure` fails the write after the row is
 * made, in a debuggable build only, so cleanup can be seen on a device.
 */
class LumeImageSaver(private val activity: Activity) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "lume/image_saver"
        private const val REQUEST = 0x4C56
        private const val MIME = "image/png"
    }

    private var pending: (() -> Unit)? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "savePng") {
            result.notImplemented()
            return
        }
        val bytes = call.argument<ByteArray>("bytes")
        val name = call.argument<String>("name")
        if (bytes == null || name.isNullOrBlank()) {
            result.success(outcome("failed"))
            return
        }
        val fail = call.argument<Boolean>("simulateFailure") == true &&
            (activity.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            Thread { post(result, saveMediaStore(bytes, name, fail)) }.start()
        } else {
            legacy(result, bytes, name, fail)
        }
    }

    private fun post(result: MethodChannel.Result, value: Map<String, Any?>) =
        activity.runOnUiThread { result.success(value) }

    private fun outcome(o: String, name: String? = null, mime: String? = null, uri: Uri? = null) =
        mapOf("outcome" to o, "name" to name, "mime" to mime, "uri" to uri?.toString())

    private fun noSpace(e: Throwable) =
        (e.message ?: "").contains("ENOSPC") || (e.message ?: "").contains("No space")

    // ------------------------------------------------------------ API 29+

    private fun saveMediaStore(bytes: ByteArray, name: String, fail: Boolean): Map<String, Any?> {
        val resolver = activity.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, "$name.png")
            put(MediaStore.MediaColumns.MIME_TYPE, MIME)
            put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_PICTURES)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val collection = MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val uri = try {
            resolver.insert(collection, values)
        } catch (e: Exception) {
            null
        } ?: return outcome("failed")
        return try {
            resolver.openOutputStream(uri)?.use { out ->
                if (fail) throw IOException("simulated failure")
                out.write(bytes)
                out.flush()
            } ?: throw IOException("no stream")
            val done = ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) }
            if (resolver.update(uri, done, null, null) != 1) throw IOException("not published")
            // What MediaStore holds now, not what was asked for.
            resolver.query(
                uri,
                arrayOf(MediaStore.MediaColumns.DISPLAY_NAME, MediaStore.MediaColumns.MIME_TYPE),
                null, null, null,
            )?.use { c ->
                if (!c.moveToFirst()) throw IOException("row gone")
                val shown = c.getString(0)
                val mime = c.getString(1)
                if (mime != MIME || !shown.endsWith(".png")) {
                    resolver.delete(uri, null, null)
                    return outcome("failed", shown, mime)
                }
                outcome("saved", shown, mime, uri)
            } ?: throw IOException("no row")
        } catch (e: Exception) {
            try {
                resolver.delete(uri, null, null)
            } catch (_: Exception) {
            }
            outcome(if (noSpace(e)) "noSpace" else "failed")
        }
    }

    // ------------------------------------------------------------ API 24–28

    private fun legacy(result: MethodChannel.Result, bytes: ByteArray, name: String, fail: Boolean) {
        val permission = Manifest.permission.WRITE_EXTERNAL_STORAGE
        val write = { Thread { writeLegacy(result, bytes, name, fail) }.start() }
        if (activity.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED) {
            write()
            return
        }
        if (pendingResult != null) {
            result.success(outcome("failed"))
            return
        }
        pendingResult = result
        pending = write
        activity.requestPermissions(arrayOf(permission), REQUEST)
    }

    /** From [MainActivity.onRequestPermissionsResult]. */
    fun onResult(requestCode: Int, grantResults: IntArray) {
        if (requestCode != REQUEST) return
        val result = pendingResult ?: return
        val write = pending
        pendingResult = null
        pending = null
        if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            write?.invoke()
        } else {
            result.success(outcome("denied"))
        }
    }

    @Suppress("DEPRECATION")
    private fun writeLegacy(result: MethodChannel.Result, bytes: ByteArray, name: String, fail: Boolean) {
        val dir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
        var file: File? = null
        try {
            if (!dir.exists() && !dir.mkdirs()) throw IOException("no Pictures")
            var n = 0
            var f: File
            do {
                f = File(dir, if (n == 0) "$name.png" else "$name ($n).png")
                n++
            } while (!f.createNewFile())
            file = f
            FileOutputStream(f).use { out ->
                if (fail) throw IOException("simulated failure")
                out.write(bytes)
                out.fd.sync()
            }
        } catch (e: Exception) {
            file?.delete()
            post(result, outcome(if (noSpace(e)) "noSpace" else "failed"))
            return
        }
        val saved = file!!
        MediaScannerConnection.scanFile(activity, arrayOf(saved.absolutePath), arrayOf(MIME)) { _, uri ->
            if (uri == null) {
                saved.delete()
                post(result, outcome("failed"))
            } else {
                post(result, outcome("saved", saved.name, MIME, uri))
            }
        }
    }
}
