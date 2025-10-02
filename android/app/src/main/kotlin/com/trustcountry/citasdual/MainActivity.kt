package com.trustcountry.citasduales

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "keep_alive_service"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startKeepAliveService" -> {
                    try {
                        NotificationKeepAliveService.startService(this)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to start service", e.message)
                    }
                }
                "stopKeepAliveService" -> {
                    try {
                        NotificationKeepAliveService.stopService(this)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to stop service", e.message)
                    }
                }
                "isKeepAliveServiceRunning" -> {
                    // Implementar verificación si es necesario
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        // Iniciar servicio cuando la actividad se destruye
        NotificationKeepAliveService.startService(this)
    }
}
