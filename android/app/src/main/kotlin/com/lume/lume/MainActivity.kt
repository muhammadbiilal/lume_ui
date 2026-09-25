package com.lume.lume

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val camera = LumeCameraPermission(this)
    private val images = LumeImageSaver(this)
    private val notifications = LumeNotificationPermission(this)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, LumeCameraPermission.CHANNEL).setMethodCallHandler(camera)
        MethodChannel(messenger, LumeAppSettings.CHANNEL).setMethodCallHandler(LumeAppSettings(this))
        MethodChannel(messenger, LumeImageSaver.CHANNEL).setMethodCallHandler(images)
        MethodChannel(messenger, LumeNotificationPermission.CHANNEL).setMethodCallHandler(notifications)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        camera.onResult(requestCode, grantResults)
        images.onResult(requestCode, grantResults)
        notifications.onResult(requestCode, grantResults)
    }
}
