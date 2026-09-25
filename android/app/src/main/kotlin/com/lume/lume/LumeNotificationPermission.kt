package com.lume.lume

import android.Manifest
import android.app.Activity
import android.app.AlarmManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * The notification permission as Android reports it — facts, never a guess.
 *
 * `lume_notification_gate.dart` classifies what this returns; nothing here
 * decides anything for Reminders.
 *
 * POST_NOTIFICATIONS (API 33/Tiramisu+) behaves like camera:
 * `checkSelfPermission` says whether it is granted, and
 * `shouldShowRequestPermissionRationale` says whether Android will still show
 * its own dialog after a refusal. Neither alone tells a first request from
 * "don't ask again", so the same per-install bookkeeping as
 * `LumeCameraPermission` (`asked`, `sawRationale`) is kept here, for the same
 * reason. Below API 33 the permission does not exist — a posted notification
 * just shows — so `granted` is reported `true` unconditionally and `request`
 * resolves immediately with no dialog.
 *
 * Exact alarms (API 31/S+, `AlarmManager.canScheduleExactAlarms`) have no
 * equivalent machinery at all: Android gives no rationale flag for it and
 * shows no dialog Lume can trigger. The only way to grant it is the system's
 * own Settings screen, reached via `ACTION_REQUEST_SCHEDULE_EXACT_ALARM`. So
 * `requestExactAlarm` does not behave like `request` — it has no result to
 * wait for. It fires that Settings intent and returns the current facts
 * immediately; the caller is expected to poll again with `check` or
 * `checkExactAlarm` later (e.g. when the app resumes) to see whether the
 * reader actually flipped it in Settings. Because there is nothing to
 * remember about it — no rationale, no "asked" — `canScheduleExactAlarms` is
 * read fresh every time and returned on every response, outside the
 * asked/rationale bookkeeping that only applies to POST_NOTIFICATIONS.
 *
 * Methods: `check`/`request` for POST_NOTIFICATIONS (Android's dialog, when
 * Android shows one), `checkExactAlarm`/`requestExactAlarm` for exact alarms
 * (Settings, never a dialog). Settings is `LumeAppSettings`.
 */
class LumeNotificationPermission(private val activity: Activity) :
    MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "lume/notification_permission"
        private const val REQUEST = 0x4C56
        private const val STORE = "lume.notification_permission"
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
            "checkExactAlarm" -> result.success(facts())
            "requestExactAlarm" -> requestExactAlarm(result)
            else -> result.notImplemented()
        }
    }

    private fun granted(): Boolean {
        // Below API 33 there is no POST_NOTIFICATIONS permission to hold.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun rationale(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return false
        return activity.shouldShowRequestPermissionRationale(
            Manifest.permission.POST_NOTIFICATIONS,
        )
    }

    /** Read fresh every time: nothing about this is worth caching. */
    private fun canScheduleExactAlarms(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        val alarmManager =
            activity.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        return alarmManager.canScheduleExactAlarms()
    }

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
            "granted" to isGranted,
            "rationale" to isRationale,
            "asked" to store.getBoolean(ASKED, false),
            "sawRationale" to store.getBoolean(SAW_RATIONALE, false),
            "requested" to false,
            "canScheduleExactAlarms" to canScheduleExactAlarms(),
        )
    }

    private fun request(result: MethodChannel.Result) {
        if (pending != null) {
            result.error("busy", "A notification request is already open", null)
            return
        }
        val now = facts()
        // Nothing to ask: already granted, or the permission doesn't exist here.
        if (now["granted"] == true || Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(now)
            return
        }
        rationaleBefore = now["rationale"] == true
        sawRationaleBefore = now["sawRationale"] == true
        store.edit().putBoolean(ASKED, true).apply()
        pending = result
        activity.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST)
    }

    /**
     * No dialog exists for exact alarms. This opens Android's own Settings
     * screen and returns immediately with the current facts — there is no
     * request result to wait for, so the caller must check again later.
     */
    private fun requestExactAlarm(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                data = Uri.parse("package:${activity.packageName}")
            }
            activity.startActivity(intent)
        }
        result.success(facts())
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
