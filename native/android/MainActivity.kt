package com.salahfocus.salah_focus

import android.content.Intent
import android.content.ActivityNotFoundException
import android.app.LocaleManager
import android.net.Uri
import android.os.Build
import android.os.LocaleList
import android.provider.Settings
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
                        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                            }
                        } else {
                            appDetailsIntent()
                        }
                        openSettings(intent, result)
                    }
                    "openExactAlarmSettings" -> {
                        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                                data = Uri.parse("package:$packageName")
                            }
                        } else {
                            appDetailsIntent()
                        }
                        openSettings(intent, result)
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

    private fun appDetailsIntent() = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
        data = Uri.parse("package:$packageName")
    }

    private fun openSettings(preferred: Intent, result: MethodChannel.Result) {
        // Some Android variants do not provide every settings activity.
        // Attempt the launch directly: package visibility can hide resolvable activities.
        for (intent in listOf(preferred, appDetailsIntent(), Intent(Settings.ACTION_SETTINGS))) {
            try {
                startActivity(intent)
                result.success(null)
                return
            } catch (_: ActivityNotFoundException) {
                // Try the next settings screen.
            } catch (_: SecurityException) {
                // The vendor may restrict access to this particular screen.
            }
        }
        result.error("settings_unavailable", "Unable to open system settings.", null)
    }
}
