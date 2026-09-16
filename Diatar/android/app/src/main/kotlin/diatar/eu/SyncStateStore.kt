package diatar.eu

import android.content.Context
import android.net.Uri
import android.util.AtomicFile
import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.DataInputStream
import java.io.DataOutputStream
import java.io.File
import java.security.MessageDigest

internal data class StoredFileMeta(
    val size: Long,
    val modified: Long
)

internal data class StoredSyncEntry(
    val first: StoredFileMeta,
    val second: StoredFileMeta
)

internal class SyncStateSnapshot(
    val firstRoot: String,
    val secondRoot: String,
    val entries: MutableMap<String, StoredSyncEntry>
) {
    fun metaFor(root: String, entry: StoredSyncEntry): StoredFileMeta? =
        when (root) {
            firstRoot -> entry.first
            secondRoot -> entry.second
            else -> null
        }

    fun makeEntry(
        firstEndpointRoot: String,
        firstMeta: StoredFileMeta,
        secondEndpointRoot: String,
        secondMeta: StoredFileMeta
    ): StoredSyncEntry? {
        return when {
            firstEndpointRoot == firstRoot && secondEndpointRoot == secondRoot ->
                StoredSyncEntry(firstMeta, secondMeta)

            firstEndpointRoot == secondRoot && secondEndpointRoot == firstRoot ->
                StoredSyncEntry(secondMeta, firstMeta)

            else -> null
        }
    }
}

internal object SyncStateStore {
    private const val MAGIC = 0x4453594E // DSYN
    private const val VERSION = 1

    fun hasState(context: Context, firstUri: Uri, secondUri: Uri): Boolean =
        stateFile(context, firstUri.toString(), secondUri.toString()).exists()

    fun load(context: Context, firstUri: Uri, secondUri: Uri): SyncStateSnapshot {
        val roots = orderedRoots(firstUri.toString(), secondUri.toString())
        val file = stateFile(context, roots.first, roots.second)

        if (!file.exists()) {
            return SyncStateSnapshot(roots.first, roots.second, linkedMapOf())
        }

        return try {
            DataInputStream(BufferedInputStream(file.inputStream())).use { input ->
                if (input.readInt() != MAGIC) throw Exception("Érvénytelen szinkronállapot.")
                if (input.readInt() != VERSION) throw Exception("Nem támogatott szinkronállapot-verzió.")

                val storedFirstRoot = input.readUTF()
                val storedSecondRoot = input.readUTF()
                if (storedFirstRoot != roots.first || storedSecondRoot != roots.second) {
                    throw Exception("A szinkronállapot másik mappapárhoz tartozik.")
                }

                val count = input.readInt()
                val entries = LinkedHashMap<String, StoredSyncEntry>(count.coerceAtLeast(16))
                repeat(count) {
                    val path = input.readUTF()
                    entries[path] = StoredSyncEntry(
                        first = StoredFileMeta(input.readLong(), input.readLong()),
                        second = StoredFileMeta(input.readLong(), input.readLong())
                    )
                }
                SyncStateSnapshot(storedFirstRoot, storedSecondRoot, entries)
            }
        } catch (_: Exception) {
            // Sérült/olvashatatlan állapot esetén biztonságosan első szinkronként viselkedünk.
            SyncStateSnapshot(roots.first, roots.second, linkedMapOf())
        }
    }

    fun save(context: Context, snapshot: SyncStateSnapshot) {
        val file = stateFile(context, snapshot.firstRoot, snapshot.secondRoot)
        val atomicFile = AtomicFile(file)
        val stream = atomicFile.startWrite()

        try {
            val output = DataOutputStream(BufferedOutputStream(stream))
            output.writeInt(MAGIC)
            output.writeInt(VERSION)
            output.writeUTF(snapshot.firstRoot)
            output.writeUTF(snapshot.secondRoot)
            output.writeInt(snapshot.entries.size)

            for ((path, entry) in snapshot.entries) {
                output.writeUTF(path)
                output.writeLong(entry.first.size)
                output.writeLong(entry.first.modified)
                output.writeLong(entry.second.size)
                output.writeLong(entry.second.modified)
            }
            output.flush()
            atomicFile.finishWrite(stream)
        } catch (e: Exception) {
            atomicFile.failWrite(stream)
            throw e
        }
    }

    private fun stateFile(context: Context, firstRoot: String, secondRoot: String): File {
        val roots = orderedRoots(firstRoot, secondRoot)
        val digest = MessageDigest.getInstance("SHA-256")
            .digest((roots.first + "\u0000" + roots.second).toByteArray(Charsets.UTF_8))
            .joinToString("") { "%02x".format(it) }
        return File(context.filesDir, "sync_state_$digest.bin")
    }

    private fun orderedRoots(first: String, second: String): Pair<String, String> =
        if (first <= second) first to second else second to first
}
