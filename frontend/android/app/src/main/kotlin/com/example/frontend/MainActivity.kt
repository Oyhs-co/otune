package com.example.frontend

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private var permissionResult: MethodChannel.Result? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"requestMediaPermissions" -> requestMediaPermissions(result)
					else -> result.notImplemented()
				}
			}
	}

	private fun requestMediaPermissions(result: MethodChannel.Result) {
		val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
			arrayOf(
				Manifest.permission.READ_MEDIA_AUDIO,
				Manifest.permission.READ_MEDIA_VIDEO,
			)
		} else {
			arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE)
		}

		val missingPermissions = permissions.filter {
			ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
		}

		if (missingPermissions.isEmpty()) {
			result.success(true)
			return
		}

		permissionResult = result
		ActivityCompat.requestPermissions(
			this,
			missingPermissions.toTypedArray(),
			MEDIA_PERMISSION_REQUEST_CODE,
		)
	}

	override fun onRequestPermissionsResult(
		requestCode: Int,
		permissions: Array<out String>,
		grantResults: IntArray,
	) {
		super.onRequestPermissionsResult(requestCode, permissions, grantResults)

		if (requestCode == MEDIA_PERMISSION_REQUEST_CODE) {
			permissionResult?.success(
				grantResults.isNotEmpty() && grantResults.all {
					it == PackageManager.PERMISSION_GRANTED
				},
			)
			permissionResult = null
		}
	}

	companion object {
		private const val CHANNEL = "otune/permissions"
		private const val MEDIA_PERMISSION_REQUEST_CODE = 1001
	}
}
