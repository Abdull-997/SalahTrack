package com.salahfocus.salah_focus

import android.content.Intent
import android.app.LocaleManager
import android.net.Uri
import android.os.Build
import android.os.LocaleList
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val settingsChannel = "salah_focus/system_settings"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, settingsChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openNotificationSettings" -> {
                        startActivity(Intent("android.settings.APP_NOTIFICATION_SETTINGS").apply {
                            putExtra("android.provider.extra.APP_PACKAGE", packageName)
                        })
                        result.success(null)
                    }
                    "openExactAlarmSettings" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            startActivity(Intent("android.settings.REQUEST_SCHEDULE_EXACT_ALARM").apply {
                                data = Uri.parse("package:$packageName")
                            })
                        }
                        result.success(null)
                    }
                    "setApplicationLocale" -> {
                        val languageCode = call.arguments as? String
                        if (languageCode == null) {
                            result.error("invalid_locale", "A language code is required.", null)
                        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            getSystemService(LocaleManager::class.java).applicationLocales =
                                LocaleList.forLanguageTags(languageCode)
                            result.success(null)
                        } else {
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
