package diatar.eu

import android.app.Activity
import android.app.AlertDialog
import android.content.ComponentName
import android.provider.DocumentsContract
import android.provider.Settings
import android.service.notification.NotificationListenerService
import androidx.core.app.NotificationManagerCompat
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.io.File

class MainActivity : FlutterActivity() {
	companion object {
		private const val DIA_SAVE_CHANNEL = "diatar.eu/dia_save"
		private const val ZIP_IMPORT_CHANNEL = "diatar.eu/zip_import"
		private const val EXTERNAL_COMMAND_CHANNEL = "diatar.eu/external_command"
		private const val REQUEST_SAVE_DIA = 6091
		private const val REQUEST_PICK_ZIP = 6092

        private const val STORAGE_CHANNEL = "com.example.sync_app/storage"
        private const val SYNC_CHANNEL = "com.example.sync_app/sync"
        private const val REQUEST_FOLDER = 1001
        private const val PREFS_NAME = "sync_app_folders"
        private const val KEY_LOCAL_URI = "local_uri"
        private const val KEY_LOCAL_NAME = "local_name"
        private const val KEY_USB_URI = "usb_uri"
        private const val KEY_USB_NAME = "usb_name"
	}

	private var pendingSaveResult: MethodChannel.Result? = null
	private var pendingSaveBytes: ByteArray? = null
	private var pendingSavePath: String? = null
	private var pendingZipImportResult: MethodChannel.Result? = null
	private var backupSaveProgressChannel: MethodChannel? = null

    private var pendingFolderResult: MethodChannel.Result? = null
    private var pendingFolderType: String? = null
    private var preparedSyncPlan: PreparedSyncPlan? = null
    private var syncMethodChannel: MethodChannel? = null
    private val activityScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DIA_SAVE_CHANNEL)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"saveDiaFile" -> startSaveDiaFlow(call, result)
					"overwriteDiaFile" -> overwriteDiaFile(call, result)
					"saveBackupFile" -> startSaveBackupFlow(call, result)
					else -> result.notImplemented()
				}
		backupSaveProgressChannel = MethodChannel(
				flutterEngine.dartExecutor.binaryMessenger,
				"diatar.eu/dia_save_progress"
		)
			}
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ZIP_IMPORT_CHANNEL)
			.setMethodCallHandler { call, result ->
				if (call.method == "pickZipToCache") {
					startZipImportPick(result)
				} else {
					result.notImplemented()
				}
			}
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EXTERNAL_COMMAND_CHANNEL)
			.setMethodCallHandler { call, result ->
				if (call.method == "run") {
					runExternalCommand(call, result)
				} else {
					result.notImplemented()
				}
			}


        configureStorageChannel(flutterEngine)
        configureSyncChannel(flutterEngine)
	}

	private fun runExternalCommand(call: MethodCall, result: MethodChannel.Result) {
		val command = call.argument<String>("command")?.trim()
		if (command.isNullOrEmpty()) {
			result.error("invalid_args", "Missing command.", null)
			return
		}

		try {
			val isBroadcast = command.startsWith("broadcast:", ignoreCase = true)
			val intentSpec = if (isBroadcast) {
				command.substring("broadcast:".length).trim()
			} else {
				command
			}
			if (intentSpec.isEmpty()) {
				result.error("invalid_args", "Missing intent after broadcast prefix.", null)
				return
			}
			val intent = if (intentSpec.startsWith("intent:", ignoreCase = true)) {
				Intent.parseUri(intentSpec, Intent.URI_INTENT_SCHEME)
			} else {
				Intent(Intent.ACTION_VIEW, Uri.parse(intentSpec))
			}
			if (isBroadcast) {
				sendBroadcast(intent)
			} else {
				startActivity(intent)
			}
			result.success(null)
		} catch (e: Exception) {
			result.error(
				"external_command_failed",
				e.localizedMessage ?: e.toString(),
				null,
			)
		}
	}

	private fun startZipImportPick(result: MethodChannel.Result) {
		if (pendingZipImportResult != null) {
			result.error("busy", "Another ZIP import picker is already in progress.", null)
			return
		}
		pendingZipImportResult = result
		val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
			addCategory(Intent.CATEGORY_OPENABLE)
			type = "application/zip"
			addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
		}
		try {
			startActivityForResult(intent, REQUEST_PICK_ZIP)
		} catch (e: Exception) {
			pendingZipImportResult = null
			result.error("picker_failed", e.localizedMessage ?: e.toString(), null)
		}
	}

	private fun startSaveDiaFlow(call: MethodCall, result: MethodChannel.Result) {
		if (pendingSaveResult != null) {
			result.error("busy", "Another save dialog is already in progress.", null)
			return
		}

		val fileName = (call.argument<String>("fileName") ?: "sorrend.dia").trim().ifEmpty {
			"sorrend.dia"
		}
		val bytes = call.argument<ByteArray>("bytes")
		if (bytes == null || bytes.isEmpty()) {
			result.error("invalid_args", "Missing or empty file bytes.", null)
			return
		}

		pendingSaveResult = result
		pendingSaveBytes = bytes

		val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
			addCategory(Intent.CATEGORY_OPENABLE)
			type = "application/octet-stream"
			putExtra(Intent.EXTRA_TITLE, fileName)
			addFlags(
				Intent.FLAG_GRANT_READ_URI_PERMISSION or
					Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
					Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
			)
		}

		try {
			startActivityForResult(intent, REQUEST_SAVE_DIA)
		} catch (e: Exception) {
			clearPendingSave()
			result.error("save_dialog_failed", e.localizedMessage ?: e.toString(), null)
		}
	}

	private fun overwriteDiaFile(call: MethodCall, result: MethodChannel.Result) {
		val uri = call.argument<String>("uri")
		if (uri.isNullOrEmpty()) {
			result.error("invalid_args", "Missing target URI.", null)
			return
		}
		val bytes = call.argument<ByteArray>("bytes")
		if (bytes == null || bytes.isEmpty()) {
			result.error("invalid_args", "Missing or empty file bytes.", null)
			return
		}
		val targetUri = Uri.parse(uri)
		try {
			val stream = contentResolver.openOutputStream(targetUri, "wt")
				?: throw IOException("Cannot open output stream for target URI.")
			stream.use { out ->
				out.write(bytes)
				out.flush()
			}
			result.success(uri)
		} catch (e: Exception) {
			result.error("overwrite_failed", e.localizedMessage ?: e.toString(), null)
		}
	}

	private fun startSaveBackupFlow(call: MethodCall, result: MethodChannel.Result) {
		if (pendingSaveResult != null) {
			result.error("busy", "Another save dialog is already in progress.", null)
			return
		}

		val fileName = (call.argument<String>("fileName") ?: "diatar-backup.zip").trim().ifEmpty {
			"diatar-backup.zip"
		}
		val path = call.argument<String>("path")
		val bytes = call.argument<ByteArray>("bytes")
		if (path != null) {
			if (!java.io.File(path).isFile) {
				result.error("invalid_args", "Backup file not found.", null)
				return
			}
		} else if (bytes == null || bytes.isEmpty()) {
			result.error("invalid_args", "Missing or empty file data.", null)
			return
		}

		pendingSaveResult = result
		pendingSaveBytes = bytes
		pendingSavePath = path

		val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
			addCategory(Intent.CATEGORY_OPENABLE)
			type = "application/zip"
			putExtra(Intent.EXTRA_TITLE, fileName)
		}

		try {
			startActivityForResult(intent, REQUEST_SAVE_DIA)
		} catch (e: Exception) {
			clearPendingSave()
			result.error("save_dialog_failed", e.localizedMessage ?: e.toString(), null)
		}
	}

	override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
		super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == REQUEST_FOLDER) {
            handleSyncFolderResult(resultCode, data)
            return
        }

		if (requestCode == REQUEST_PICK_ZIP) {
			handleZipImportPick(resultCode, data)
			return
		}
		if (requestCode != REQUEST_SAVE_DIA) {
			return
		}

		val result = pendingSaveResult
		val bytes = pendingSaveBytes
		val path = pendingSavePath
		clearPendingSave()

		if (result == null) {
			return
		}
		if (resultCode != Activity.RESULT_OK || data?.data == null) {
			result.success(null)
			return
		}
		if (bytes == null && path == null) {
			result.error("missing_bytes", "No file data available for save.", null)
			return
		}

		val targetUri = data.data
		if (path != null) {
			saveBackupFileAsync(result, targetUri!!, path)
			return
		}
		try {
			val stream = contentResolver.openOutputStream(targetUri!!)
				?: throw IOException("Cannot open output stream for target URI.")
			stream.use { out ->
				out.write(bytes!!)
				out.flush()
			}
			try {
				contentResolver.takePersistableUriPermission(
					targetUri,
					Intent.FLAG_GRANT_READ_URI_PERMISSION or
						Intent.FLAG_GRANT_WRITE_URI_PERMISSION
				)
			} catch (_: Exception) {
				// The provider does not support persisting the grant. The
				// session grant is enough for this save; later overwrites will
				// fall back to the system picker if the grant is gone.
			}
			result.success(
				mapOf(
					"uri" to targetUri.toString(),
					"displayName" to queryDisplayName(targetUri)
				)
			)
		} catch (e: Exception) {
			result.error("save_failed", e.localizedMessage ?: e.toString(), null)
		}
	}

	private fun saveBackupFileAsync(
		result: MethodChannel.Result,
		targetUri: Uri,
		path: String
	) {
		Thread {
			try {
				val source = File(path)
				val totalBytes = source.length()
				var writtenBytes = 0L
				var lastProgressAt = 0L
				contentResolver.openOutputStream(targetUri, "wt")?.use { output ->
					source.inputStream().use { input ->
						val buffer = ByteArray(64 * 1024)
						while (true) {
							val count = input.read(buffer)
							if (count < 0) break
							output.write(buffer, 0, count)
							writtenBytes += count
							val now = System.currentTimeMillis()
							if (now - lastProgressAt >= 100) {
								sendBackupSaveProgress(writtenBytes, totalBytes)
								lastProgressAt = now
							}
						}
					}
					output.flush()
				} ?: throw IOException("Cannot open output stream for target URI.")
				sendBackupSaveProgress(writtenBytes, totalBytes)
				try {
					contentResolver.takePersistableUriPermission(
						targetUri,
						Intent.FLAG_GRANT_READ_URI_PERMISSION or
							Intent.FLAG_GRANT_WRITE_URI_PERMISSION
					)
				} catch (_: Exception) {
					// The provider does not support persisting the grant.
				}
				runOnUiThread {
					result.success(queryDisplayName(targetUri) ?: source.name)
				}
			} catch (e: Exception) {
				runOnUiThread {
					result.error("save_failed", e.localizedMessage ?: e.toString(), null)
				}
			}
		}.start()
	}

	private fun sendBackupSaveProgress(writtenBytes: Long, totalBytes: Long) {
		runOnUiThread {
			backupSaveProgressChannel?.invokeMethod(
				"backupSaveProgress",
				mapOf("writtenBytes" to writtenBytes, "totalBytes" to totalBytes)
			)
		}
	}

	private fun handleZipImportPick(resultCode: Int, data: Intent?) {
		val result = pendingZipImportResult
		pendingZipImportResult = null
		if (result == null) return
		val uri = data?.data
		if (resultCode != Activity.RESULT_OK || uri == null) {
			result.success(null)
			return
		}
		try {
			contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
		} catch (_: SecurityException) {
			// The one-shot grant from the picker is sufficient for the copy.
		}
		Thread {
			try {
				val displayName = queryDisplayName(uri).ifBlank { "scores.zip" }
				val safeName = displayName.replace(Regex("[^A-Za-z0-9._-]"), "_")
				val target = File(cacheDir, "dtz_import_${System.nanoTime()}_$safeName")
				contentResolver.openInputStream(uri)?.use { input ->
					target.outputStream().use { output ->
						input.copyTo(output, bufferSize = 64 * 1024)
					}
				} ?: throw IOException("Cannot open the selected ZIP file.")
				runOnUiThread { result.success(target.absolutePath) }
			} catch (e: Exception) {
				runOnUiThread {
					result.error("zip_copy_failed", e.localizedMessage ?: e.toString(), null)
				}
			}
		}.start()
	}

	private fun queryDisplayName(uri: Uri): String {
		return try {
			contentResolver.query(uri, null, null, null, null)?.use { cursor ->
				if (cursor.moveToFirst()) {
					val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
					if (index >= 0) cursor.getString(index) else null
				} else {
					null
				}
			} ?: ""
		} catch (_: Exception) {
			""
		}
	}

	private fun clearPendingSave() {
		pendingSaveResult = null
		pendingSaveBytes = null
		pendingSavePath = null
	}


    private fun configureStorageChannel(
        flutterEngine: FlutterEngine
    ) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            STORAGE_CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "selectFolder" -> {
                    val type =
                        call.argument<String>(
                            "type"
                        )

                    if (
                        type != "local" &&
                        type != "usb"
                    ) {
                        result.error(
                            "INVALID_FOLDER_TYPE",
                            "Érvénytelen mappatípus.",
                            null
                        )
                    } else {
                        selectFolder(
                            type,
                            result
                        )
                    }
                }

                "loadFolder" -> {
                    val type =
                        call.argument<String>(
                            "type"
                        )

                    if (
                        type != "local" &&
                        type != "usb"
                    ) {
                        result.error(
                            "INVALID_FOLDER_TYPE",
                            "Érvénytelen mappatípus.",
                            null
                        )
                    } else {
                        result.success(
                            loadFolder(type)
                        )
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun configureSyncChannel(
        flutterEngine: FlutterEngine
    ) {
        syncMethodChannel =
            MethodChannel(
                flutterEngine
                    .dartExecutor
                    .binaryMessenger,
                SYNC_CHANNEL
            )

        syncMethodChannel
            ?.setMethodCallHandler {
                call,
                result ->

                when (call.method) {

                    "hasSyncState" -> {
                        val source =
                            call.argument<String>(
                                "source"
                            )

                        val target =
                            call.argument<String>(
                                "target"
                            )

                        if (
                            source == null ||
                            target == null
                        ) {
                            result.error(
                                "INVALID_ARGUMENT",
                                "Hiányzó forrás vagy cél.",
                                null
                            )
                            return@setMethodCallHandler
                        }

                        try {
                            result.success(
                                SyncEngine.hasSyncState(
                                    context = this,
                                    firstUri =
                                        Uri.parse(
                                            source
                                        ),
                                    secondUri =
                                        Uri.parse(
                                            target
                                        )
                                )
                            )
                        } catch (e: Exception) {
                            result.error(
                                "SYNC_STATE_ERROR",
                                e.message,
                                null
                            )
                        }
                    }

                    "prepareSync" -> {
                        prepareSync(
                            call.argument(
                                "source"
                            ),
                            call.argument(
                                "target"
                            ),
                            call.argument<Boolean>(
                                "mirrorMode"
                            ) ?: false,
                            call.argument<Boolean>(
                                "dryRun"
                            ) ?: false,
                            result
                        )
                    }

                    "executeSync" -> {
                        executeSync(
                            allowDelete =
                                call.argument<Boolean>(
                                    "allowDelete"
                                ) ?: false,
                            result = result
                        )
                    }

                    "ejectUsb" -> {
                        ejectUsb(result)
                    }

                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }

    private fun prepareSync(
        source: String?,
        target: String?,
        mirrorMode: Boolean,
        dryRun: Boolean,
        result: MethodChannel.Result
    ) {
        if (
            source.isNullOrBlank() ||
            target.isNullOrBlank()
        ) {
            result.error(
                "INVALID_ARGUMENT",
                "Hiányzó forrás vagy cél.",
                null
            )
            return
        }

        preparedSyncPlan = null

        activityScope.launch {

            try {
                val plan =
                    SyncEngine.prepareSync(
                        context = this@MainActivity,
                        sourceUri =
                            Uri.parse(source),
                        targetUri =
                            Uri.parse(target),
                        mirrorMode = mirrorMode,
                        dryRun = dryRun,
                        onProgress = {
                            progress ->
                            sendProgress(progress)
                        }
                    )

                preparedSyncPlan = plan

                result.success(
                    mapOf(
                        "copyCount" to
                            plan.copyCount,
                        "deleteCount" to
                            plan.deleteCount,
                        "newFileCount" to
                            plan.newFileCount,
                        "updatedFileCount" to
                            plan.updatedFileCount,
                        "mirrorMode" to
                            plan.mirrorMode,
                        "dryRun" to
                            plan.dryRun
                    )
                )

            } catch (e: Exception) {

                preparedSyncPlan = null

                result.error(
                    "PREPARE_FAILED",
                    e.message
                        ?: "A felmérés nem sikerült.",
                    null
                )
            }
        }
    }

    private fun executeSync(
        allowDelete: Boolean,
        result: MethodChannel.Result
    ) {
        val plan =
            preparedSyncPlan

        if (plan == null) {
            result.error(
                "NO_PREPARED_PLAN",
                "Nincs végrehajtható szinkronterv.",
                null
            )
            return
        }

        activityScope.launch {

            try {
                val syncResult =
                    SyncEngine
                        .executePreparedSync(
                            context =
                                this@MainActivity,
                            plan = plan,
                            allowDelete =
                                allowDelete,
                            onProgress = {
                                progress ->
                                sendProgress(
                                    progress
                                )
                            }
                        )

                preparedSyncPlan = null

                result.success(
                    mapOf(
                        "newFiles" to
                            syncResult.newFiles,
                        "updatedFiles" to
                            syncResult.updatedFiles,
                        "deletedFiles" to
                            syncResult.deletedFiles,
                        "unchangedFiles" to
                            syncResult.unchangedFiles,
                        "errors" to
                            syncResult.errors,
                        "dryRun" to
                            syncResult.dryRun
                    )
                )

            } catch (
                e: DeletionConfirmationRequired
            ) {

                result.error(
                    "DELETE_CONFIRMATION_REQUIRED",
                    "A szinkronizálás " +
                        "${e.deleteCount} fájl " +
                        "törlését igényli.",
                    e.deleteCount
                )

            } catch (e: Exception) {

                preparedSyncPlan = null

                result.error(
                    "EXECUTE_FAILED",
                    e.message
                        ?: "A szinkronizálás nem sikerült.",
                    null
                )
            }
        }
    }

    private fun sendProgress(
        progress: SyncProgress
    ) {
        activityScope.launch {

            syncMethodChannel
                ?.invokeMethod(
                    "progress",
                    mapOf(
                        "percent" to
                            progress.percent,
                        "processedFiles" to
                            progress.processedFiles,
                        "totalFiles" to
                            progress.totalFiles,
                        "currentFile" to
                            progress.currentFile,
                        "status" to
                            progress.status
                    )
                )
        }
    }

    private fun ejectUsb(
        result: MethodChannel.Result
    ) {
        if (!isNotificationAccessGranted()) {
            openNotificationAccessSettings()
            result.error(
                "NOTIFICATION_ACCESS_REQUIRED",
                "A pendrive leválasztásához engedélyezd az értesítés-hozzáférést, majd térj vissza az alkalmazásba és próbáld újra.",
                null
            )
            return
        }

        if (!UsbNotificationListener.isRunning()) {
            try {
                NotificationListenerService.requestRebind(
                    ComponentName(
                        this,
                        UsbNotificationListener::class.java
                    )
                )
            } catch (_: Exception) {
            }
        }

        AlertDialog.Builder(this)
            .setTitle("Pendrive leválasztása")
            .setMessage(
                "Biztosan leválasztod a pendrive-ot?\n\n" +
                    "Csak akkor folytasd, ha a szinkronizálás már befejeződött."
            )
            .setNegativeButton("MÉGSEM") { dialog, _ ->
                dialog.dismiss()
                result.success(false)
            }
            .setPositiveButton("LEVÁLASZTÁS") { dialog, _ ->
                dialog.dismiss()

                val ejectResult =
                    UsbNotificationListener.ejectUsb()

                when (ejectResult) {
                    UsbEjectResult.SUCCESS ->
                        result.success(true)

                    UsbEjectResult.LISTENER_NOT_RUNNING ->
                        result.error(
                            "LISTENER_NOT_RUNNING",
                            "Az értesítésfigyelő még nem aktív. Próbáld meg néhány másodperc múlva újra.",
                            null
                        )

                    UsbEjectResult.USB_NOTIFICATION_NOT_FOUND ->
                        result.error(
                            "USB_NOTIFICATION_NOT_FOUND",
                            "Nem található csatlakoztatott USB-tároló.",
                            null
                        )

                    UsbEjectResult.EJECT_ACTION_NOT_FOUND ->
                        result.error(
                            "EJECT_ACTION_NOT_FOUND",
                            "Az USB értesítésben nem található Leválasztás művelet.",
                            null
                        )

                    UsbEjectResult.PENDING_INTENT_CANCELLED ->
                        result.error(
                            "PENDING_INTENT_CANCELLED",
                            "A rendszer Leválasztás művelete már nem érvényes.",
                            null
                        )

                    UsbEjectResult.ERROR ->
                        result.error(
                            "USB_EJECT_FAILED",
                            "A pendrive leválasztása nem sikerült.",
                            null
                        )
                }
            }
            .setOnCancelListener {
                result.success(false)
            }
            .show()
    }

    private fun isNotificationAccessGranted(): Boolean {
        return NotificationManagerCompat
            .getEnabledListenerPackages(this)
            .contains(packageName)
    }

    private fun openNotificationAccessSettings() {
        try {
            startActivity(
                Intent(
                    Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS
                )
            )
        } catch (_: Exception) {
            try {
                startActivity(
                    Intent(Settings.ACTION_SETTINGS)
                )
            } catch (_: Exception) {
            }
        }
    }

    private fun selectFolder(
        type: String,
        result: MethodChannel.Result
    ) {
        if (pendingFolderResult != null) {
            result.error(
                "FOLDER_PICKER_BUSY",
                "Már folyamatban van egy " +
                    "mappaválasztás.",
                null
            )
            return
        }

        pendingFolderResult = result
        pendingFolderType = type

        val intent =
            Intent(
                Intent.ACTION_OPEN_DOCUMENT_TREE
            ).apply {

                addFlags(
                    Intent.FLAG_GRANT_READ_URI_PERMISSION or
                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                        Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                        Intent.FLAG_GRANT_PREFIX_URI_PERMISSION
                )
            }

        startActivityForResult(
            intent,
            REQUEST_FOLDER
        )
    }

    private fun handleSyncFolderResult(resultCode: Int, data: Intent?) {
        val result = pendingFolderResult
        val type = pendingFolderType
        pendingFolderResult = null
        pendingFolderType = null

        if (result == null || type == null) return

        if (resultCode != Activity.RESULT_OK) {
            result.success(null)
            return
        }

        val uri = data?.data
        if (uri == null) {
            result.success(null)
            return
        }

        try {
            val takeFlags = data.flags and
                (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)

            contentResolver.takePersistableUriPermission(uri, takeFlags)

            val displayName = makeDisplayName(uri)
            saveFolder(type, uri.toString(), displayName)

            result.success(
                mapOf(
                    "value" to uri.toString(),
                    "displayName" to displayName
                )
            )
        } catch (e: Exception) {
            result.error(
                "PERSIST_PERMISSION_FAILED",
                e.message ?: "A tartós mappajogosultság nem adható meg.",
                null
            )
        }
    }

    private fun saveFolder(
        type: String,
        uri: String,
        displayName: String
    ) {
        val prefs =
            getSharedPreferences(
                PREFS_NAME,
                MODE_PRIVATE
            )

        val uriKey =
            if (type == "local") {
                KEY_LOCAL_URI
            } else {
                KEY_USB_URI
            }

        val nameKey =
            if (type == "local") {
                KEY_LOCAL_NAME
            } else {
                KEY_USB_NAME
            }

        prefs.edit()
            .putString(
                uriKey,
                uri
            )
            .putString(
                nameKey,
                displayName
            )
            .apply()
    }

    private fun loadFolder(
        type: String
    ): Map<String, String>? {

        val prefs =
            getSharedPreferences(
                PREFS_NAME,
                MODE_PRIVATE
            )

        val uriKey =
            if (type == "local") {
                KEY_LOCAL_URI
            } else {
                KEY_USB_URI
            }

        val nameKey =
            if (type == "local") {
                KEY_LOCAL_NAME
            } else {
                KEY_USB_NAME
            }

        val uri =
            prefs.getString(
                uriKey,
                null
            ) ?: return null

        val name =
            prefs.getString(
                nameKey,
                null
            ) ?: makeDisplayName(
                Uri.parse(uri)
            )

        return mapOf(
            "value" to uri,
            "displayName" to name
        )
    }

    private fun makeDisplayName(
        uri: Uri
    ): String {
        return try {
            val documentId =
                DocumentsContract
                    .getTreeDocumentId(uri)

            val parts =
                documentId.split(
                    ":",
                    limit = 2
                )

            val storageId =
                parts.getOrNull(0)
                    ?: ""

            val relativePath =
                parts.getOrNull(1)
                    ?: ""

            val storageName =
                if (
                    storageId.equals(
                        "primary",
                        ignoreCase = true
                    )
                ) {
                    "Belső tárhely"
                } else {
                    "Pendrive"
                }

            if (relativePath.isEmpty()) {
                storageName
            } else {
                "$storageName / " +
                    relativePath.replace(
                        "\\",
                        "/"
                    )
            }

        } catch (_: Exception) {
            uri.toString()
        }
    }

    override fun onDestroy() {
        activityScope.cancel()
        super.onDestroy()
    }
}
