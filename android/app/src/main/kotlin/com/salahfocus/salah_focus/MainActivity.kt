package com.salahfocus.salah_focus

import android.content.Intent
import android.content.ActivityNotFoundException
import android.app.LocaleManager
import android.app.NotificationManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.LocaleList
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private val settingsChannel = "salah_focus/system_settings"
    private val prayerAlarmChannel = "salah_focus/prayer_alarm"
    private val prayerIdPattern = Regex("^[a-zA-Z0-9][a-zA-Z0-9:_-]{0,199}$")
    private var alarmActive = false

    override fun onCreate(savedInstanceState: Bundle?) {
        // Apply before Flutter draws so a scheduled alarm can wake a locked device.
        // Ordinary app launches must never display the Home screen over the keyguard.
        setAlarmActive(savedInstanceState?.getBoolean("prayerAlarmActive")
            ?: isPrayerAlarmIntent(intent))
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        setIntent(intent)
        if (isPrayerAlarmIntent(intent)) {
            setAlarmActive(true)
        }
        // Flutter forwards this to flutter_local_notifications for warm-start routing.
        super.onNewIntent(intent)
    }

    override fun onSaveInstanceState(outState: Bundle) {
        outState.putBoolean("prayerAlarmActive", alarmActive)
        super.onSaveInstanceState(outState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, prayerAlarmChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "setAlarmActive") {
                    result.notImplemented()
                } else {
                    val active = call.argument<Boolean>("active")
                    if (active == null) {
                        result.error("invalid_alarm_state", "An active boolean is required.", null)
                    } else {
                        setAlarmActive(active)
                        result.success(null)
                    }
                }
            }
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
                    "canUseFullScreenIntent" -> {
                        result.success(Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE ||
                            getSystemService(NotificationManager::class.java).canUseFullScreenIntent())
                    }
                    "openFullScreenIntentSettings" -> {
                        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                            Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT).apply {
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

    private fun isPrayerAlarmIntent(intent: Intent?): Boolean {
        if (intent == null ||
            intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0 ||
            intent.action !in setOf("SELECT_NOTIFICATION", "SELECT_FOREGROUND_NOTIFICATION")) {
            return false
        }
        val payload = intent.getStringExtra("payload") ?: return false
        if (payload.length > 2048) return false
        if (payload.startsWith("prayer:") || payload.startsWith("reminder:")) {
            return prayerIdPattern.matches(payload.substringAfter(':'))
        }
        return try {
            val data = JSONObject(payload)
            val prayerId = data.opt("prayerId") as? String ?: return false
            val action = if (data.isNull("action")) "open" else data.opt("action")
            val eventId = if (data.isNull("eventId")) null else data.opt("eventId")
            (data.opt("v") as? Number)?.toDouble() == 1.0 &&
                data.optString("kind") in setOf("prayer", "reminder", "snooze") &&
                prayerIdPattern.matches(prayerId) &&
                action in setOf("open", "mark_prayed", "snooze") &&
                (eventId == null || (eventId is String && eventId.isNotEmpty() &&
                    eventId.length <= 256 && eventId.none { it.code < 32 || it.code == 127 }))
        } catch (_: org.json.JSONException) {
            false
        }
    }

    @Suppress("DEPRECATION")
    private fun setAlarmActive(active: Boolean) {
        alarmActive = active
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(active)
            setTurnScreenOn(active)
        } else {
            val flags = WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            if (active) window.addFlags(flags) else window.clearFlags(flags)
        }
        if (active) {
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
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
