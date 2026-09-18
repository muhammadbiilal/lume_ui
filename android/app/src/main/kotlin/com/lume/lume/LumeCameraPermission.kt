package com.lume.lume

import android.Manifest
import android.app.Activity
import android.app.admin.DevicePolicyManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * The camera permission as Android reports it — facts, never a guess (C80).
 *
 * `lume_camera_gate.dart` classifies what this returns. Android says two
 * things about a refused permission: whether it is granted, and
 * `shouldShowRequestPermissionRationale` — true once the reader has refused
 * and Android will still ask. Neither alone tells a first request from "don't
 * ask again", so this also keeps, per install, whether Lume has asked and
 * whether Android has ever said it would ask again since the last grant. It
 * keeps no time: nothing here is inferred from how long anything took.
 *
 * Methods: `check` (no dialog) and `request` (Android's dialog, when Android
 * shows one). Settings is `LumeAppSettings`.
 */
class LumeCameraPermission(private val activity: Activity) :
    MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "lume/camera_permission"
        private const val REQUEST = 0x4C55
        private const val STORE = "lume.camera_permission"
        private const val ASKED = "asked"
        private const val SAW_RATIONALE = "sawRationale"
    }

    private var pending: MethodChannel.Result? = null
    private var rationaleBefore = false
    private var sawRationaleBefore = false

    private val store
        get() = activity.getSharedPreferences(STORE, Context.MODE_PRIVATE)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "check" -> result.success(facts())
            "request" -> request(result)
            else -> result.notImplemented()
        }
    }

    private fun hasCamera() =
        activity.packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY)

    private fun policyDisabled(): Boolean {
        val dpm = activity.getSystemService(Context.DEVICE_POLICY_SERVICE)
            as DevicePolicyManager?
        return dpm?.getCameraDisabled(null) ?: false
    }

    private fun granted() =
        activity.checkSelfPermission(Manifest.permission.CAMERA) ==
            PackageManager.PERMISSION_GRANTED

    private fun rationale() =
        activity.shouldShowRequestPermissionRationale(Manifest.permission.CAMERA)

    /** What Android says now, recorded as it is observed. */
    private fun facts(): HashMap<String, Any> {
        val isGranted = granted()
        val isRationale = !isGranted && rationale()
        val edit = store.edit()
        // A grant starts the history again; a rationale is remembered until one.
        if (isGranted) edit.putBoolean(SAW_RATIONALE, false)
        if (isRationale) edit.putBoolean(SAW_RATIONALE, true)
        edit.apply()
        return hashMapOf(
            "sdk" to Build.VERSION.SDK_INT,
            "hasCamera" to hasCamera(),
            "policyDisabled" to policyDisabled(),
            "granted" to isGranted,
            "rationale" to isRationale,
            "asked" to store.getBoolean(ASKED, false),
            "sawRationale" to store.getBoolean(SAW_RATIONALE, false),
            "requested" to false,
        )
    }

    private fun request(result: MethodChannel.Result) {
        if (pending != null) {
            result.error("busy", "A camera request is already open", null)
            return
        }
        val now = facts()
        // Nothing to ask: granted, no camera, or a policy Settings cannot undo.
        if (now["granted"] == true || now["hasCamera"] == false ||
            now["policyDisabled"] == true
        ) {
            result.success(now)
            return
        }
        rationaleBefore = now["rationale"] == true
        sawRationaleBefore = now["sawRationale"] == true
        store.edit().putBoolean(ASKED, true).apply()
        pending = result
        activity.requestPermissions(arrayOf(Manifest.permission.CAMERA), REQUEST)
    }

    /** From [MainActivity.onRequestPermissionsResult]. */
    fun onResult(requestCode: Int, grantResults: IntArray) {
        if (requestCode != REQUEST) return
        val result = pending ?: return
        pending = null
        val after = facts()
        after["requested"] = true
        after["rationaleBefore"] = rationaleBefore
        after["sawRationaleBefore"] = sawRationaleBefore
        // "If the request is cancelled, the result arrays are empty."
        after["interrupted"] = grantResults.isEmpty()
        result.success(after)
    }
}
