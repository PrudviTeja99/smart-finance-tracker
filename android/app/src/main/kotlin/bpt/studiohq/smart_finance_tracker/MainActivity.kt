package bpt.studiohq.smart_finance_tracker

import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "bpt.studiohq.smart_finance_tracker/app_info"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getAppInfo") {
                val packageName = call.argument<String>("packageName")
                if (packageName == null) {
                    result.error("INVALID_ARGUMENT", "Package name is null", null)
                    return@setMethodCallHandler
                }
                try {
                    val pm = packageManager
                    val appInfo = pm.getApplicationInfo(packageName, 0)
                    val label = pm.getApplicationLabel(appInfo).toString()
                    val iconDrawable = pm.getApplicationIcon(appInfo)
                    
                    val bitmap = drawableToBitmap(iconDrawable)
                    val stream = ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                    val iconBytes = stream.toByteArray()

                    val response = mapOf(
                        "appName" to label,
                        "iconBytes" to iconBytes
                    )
                    result.success(response)
                } catch (e: PackageManager.NameNotFoundException) {
                    result.error("NOT_FOUND", "Package not found: $packageName", null)
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            } else if (call.method == "openAppSettings") {
                try {
                    val intent = android.content.Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                    val uri = android.net.Uri.fromParts("package", packageName, null)
                    intent.data = uri
                    intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            } else if (call.method == "isIgnoringBatteryOptimizations") {
                try {
                    val pm = getSystemService(android.content.Context.POWER_SERVICE) as android.os.PowerManager
                    val isIgnoring = pm.isIgnoringBatteryOptimizations(packageName)
                    result.success(isIgnoring)
                } catch (e: Exception) {
                    result.success(false)
                }
            } else if (call.method == "requestIgnoreBatteryOptimizations") {
                try {
                    val intent = android.content.Intent(android.provider.Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                        data = android.net.Uri.parse("package:$packageName")
                        addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(intent)
                    result.success(true)
                } catch (e1: Exception) {
                    try {
                        val fallbackIntent = android.content.Intent(android.provider.Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                            addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(fallbackIntent)
                        result.success(true)
                    } catch (e2: Exception) {
                        try {
                            val detailsIntent = android.content.Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = android.net.Uri.fromParts("package", packageName, null)
                                addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(detailsIntent)
                            result.success(true)
                        } catch (e3: Exception) {
                            result.error("ERROR", e3.message, null)
                        }
                    }
                }
            } else if (call.method == "openAutoStartSettings") {
                try {
                    val packageName = this.packageName
                    var intent: android.content.Intent? = null

                    // Manufacturer-specific Auto Start settings
                    when (android.os.Build.MANUFACTURER.lowercase()) {
                        "xiaomi", "redmi", "mi", "poco" -> {
                            intent = android.content.Intent().apply {
                                setClassName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity")
                            }
                        }
                        "oppo", "realme", "oneplus" -> {
                            intent = android.content.Intent().apply {
                                setComponent(android.content.ComponentName("com.android.settings", "com.android.settings.Settings\$AppAndNotificationSettingsActivity"))
                            }
                        }
                        "vivo", "iqoo" -> {
                            intent = android.content.Intent().apply {
                                setComponent(android.content.ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"))
                            }
                        }
                        "huawei", "honor" -> {
                            intent = android.content.Intent().apply {
                                setComponent(android.content.ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"))
                            }
                        }
                        "samsung" -> {
                            intent = android.content.Intent().apply {
                                setComponent(android.content.ComponentName("com.samsung.android.sm", "com.samsung.android.sm.battery.BatteryActivity"))
                            }
                        }
                        "google", "asus", "motorola", "" -> {
                            // fall through to general fallback
                        }
                        else -> {
                            // Unknown manufacturer → use general fallback
                        }
                    }

                    // Try manufacturer-specific intent first
                    if (intent != null) {
                    try {
                            intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                            return@setMethodCallHandler
                        } catch (e: Exception) {
                            // Intent failed (activity not found) → fallback
                        }
                    }

                    // === BEST GENERAL FALLBACK ===
                    val fallbackIntent = android.content.Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = android.net.Uri.fromParts("package", packageName, null)
                        addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(fallbackIntent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        if (drawable is BitmapDrawable) {
            return drawable.bitmap
        }
        val bitmap = Bitmap.createBitmap(
            if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 1,
            if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 1,
            Bitmap.Config.ARGB_8888
        )
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }
}
