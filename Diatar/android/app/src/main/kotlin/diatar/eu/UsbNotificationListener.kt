package diatar.eu

import android.app.PendingIntent
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import java.util.Locale

enum class UsbEjectResult {
    SUCCESS,
    LISTENER_NOT_RUNNING,
    USB_NOTIFICATION_NOT_FOUND,
    EJECT_ACTION_NOT_FOUND,
    PENDING_INTENT_CANCELLED,
    ERROR
}

class UsbNotificationListener : NotificationListenerService() {

    companion object {

        @Volatile
        private var instance: UsbNotificationListener? = null

        fun isRunning(): Boolean {
            return instance != null
        }

        /*
         * Megkeresi a Samsung / SystemUI USB-tárhely értesítését,
         * azon belül a "Leválasztás" műveletet, majd pontosan
         * annak a rendszer által létrehozott PendingIntentjét futtatja.
         */
        fun ejectUsb(): UsbEjectResult {

            val service =
                instance
                    ?: return UsbEjectResult.LISTENER_NOT_RUNNING

            return try {

                val notifications =
                    service.activeNotifications
                        ?: emptyArray()

                val usbNotifications =
                    notifications.filter {
                        isUsbStorageNotification(it)
                    }

                if (usbNotifications.isEmpty()) {
                    return UsbEjectResult.USB_NOTIFICATION_NOT_FOUND
                }

                for (sbn in usbNotifications) {

                    val actions =
                        sbn.notification.actions
                            ?: continue

                    /*
                     * Magyar Samsung:
                     * "Leválasztás"
                     *
                     * Angol / más ROM esetére is teszünk
                     * néhány tartalék megnevezést.
                     */
                    val ejectAction =
                        actions.firstOrNull { action ->

                            val title =
                                normalize(
                                    action.title
                                        ?.toString()
                                        .orEmpty()
                                )

                            title.contains("levalaszt") ||
                                    title.contains("unmount") ||
                                    title.contains("eject") ||
                                    title.contains("remove")
                        }

                    if (ejectAction != null) {

                        try {

                            ejectAction.actionIntent.send()

                            return UsbEjectResult.SUCCESS

                        } catch (
                            _: PendingIntent.CanceledException
                        ) {

                            return UsbEjectResult
                                .PENDING_INTENT_CANCELLED
                        }
                    }
                }

                UsbEjectResult.EJECT_ACTION_NOT_FOUND

            } catch (_: Exception) {

                UsbEjectResult.ERROR
            }
        }

        /*
         * A telefonon látott USB-tároló értesítés:
         *
         * package = com.android.systemui
         * tag     = public:...
         *
         * Ez sokkal biztosabb az értesítés magyar
         * szövegének vizsgálatánál.
         */
        private fun isUsbStorageNotification(
            sbn: StatusBarNotification
        ): Boolean {

            if (
                sbn.packageName !=
                "com.android.systemui"
            ) {
                return false
            }

            val tag =
                sbn.tag.orEmpty()

            if (
                tag.startsWith(
                    "public:",
                    ignoreCase = true
                )
            ) {
                return true
            }

            /*
             * Tartalék felismerés arra az esetre,
             * ha egy későbbi Samsung verzió
             * megváltoztatná a notification taget.
             */
            val extras =
                sbn.notification.extras

            val title =
                normalize(
                    extras
                        ?.getCharSequence(
                            "android.title"
                        )
                        ?.toString()
                        .orEmpty()
                )

            return (
                    title.contains("usb") &&
                            (
                                    title.contains("tarolo") ||
                                            title.contains("storage")
                                    )
                    )
        }

        private fun normalize(
            text: String
        ): String {

            return text
                .lowercase(
                    Locale.ROOT
                )
                .replace("á", "a")
                .replace("é", "e")
                .replace("í", "i")
                .replace("ó", "o")
                .replace("ö", "o")
                .replace("ő", "o")
                .replace("ú", "u")
                .replace("ü", "u")
                .replace("ű", "u")
        }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()

        instance =
            this
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()

        if (
            instance === this
        ) {
            instance = null
        }
    }

    override fun onDestroy() {

        if (
            instance === this
        ) {
            instance = null
        }

        super.onDestroy()
    }
}