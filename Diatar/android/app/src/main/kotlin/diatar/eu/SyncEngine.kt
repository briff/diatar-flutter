package diatar.eu

import android.content.Context
import android.net.Uri
import android.provider.DocumentsContract
import androidx.documentfile.provider.DocumentFile
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.security.MessageDigest
import java.util.ArrayDeque
import kotlin.math.abs
import kotlin.math.max

data class SyncProgress(
    val percent: Int,
    val processedFiles: Int,
    val totalFiles: Int,
    val currentFile: String,
    val status: String
)

data class SyncResult(
    val newFiles: Int,
    val updatedFiles: Int,
    val deletedFiles: Int,
    val unchangedFiles: Int,
    val errors: List<String>,
    val dryRun: Boolean
)

class DeletionConfirmationRequired(
    val deleteCount: Int
) : Exception()

internal data class FileEntry(
    val relativePath: String,
    val uri: Uri,
    val name: String,
    val mimeType: String?,
    val size: Long,
    val modified: Long
)

private data class ScanResult(
    val files: Map<String, FileEntry>,
    val directories: Map<String, Uri>
)

internal data class CopyOperation(
    val source: FileEntry,
    val relativePath: String,
    val isNew: Boolean
)

internal data class DeleteOperation(
    val target: FileEntry
)

/*
 * Ez a már elkészített szinkronterv.
 *
 * A MainActivity ezt megtarthatja a törlési
 * megerősítés idejére, majd ugyanazt a tervet
 * adhatja vissza végrehajtásra.
 */
class PreparedSyncPlan internal constructor(
    internal val sourceUri: Uri,
    internal val targetUri: Uri,
    internal val copies: List<CopyOperation>,
    internal val deletions: List<DeleteOperation>,
    internal val targetDirectories: Map<String, Uri>,
    internal val sourceFiles: Map<String, FileEntry>,
    internal val targetFiles: Map<String, FileEntry>,
    internal val knownEqualPaths: Set<String>,
    internal val syncState: SyncStateSnapshot,
    val unchangedFiles: Int,
    val mirrorMode: Boolean,
    val dryRun: Boolean
) {
    val deleteCount: Int
        get() = deletions.size

    val copyCount: Int
        get() = copies.size

    val newFileCount: Int
        get() = copies.count { it.isNew }

    val updatedFileCount: Int
        get() = copies.count { !it.isNew }
}

object SyncEngine {

    private const val TIME_TOLERANCE_MS = 2000L
    private const val BUFFER_SIZE = 256 * 1024
    private const val SCAN_PROGRESS_INTERVAL = 100
    private const val COMPARE_PROGRESS_INTERVAL = 100

    fun hasSyncState(
        context: Context,
        firstUri: Uri,
        secondUri: Uri
    ): Boolean = SyncStateStore.hasState(context, firstUri, secondUri)

    /*
     * =========================================================
     * 1. FÁZIS
     * FELMÉRÉS + SZINKRONTERV ELKÉSZÍTÉSE
     * =========================================================
     */
    suspend fun prepareSync(
        context: Context,
        sourceUri: Uri,
        targetUri: Uri,
        mirrorMode: Boolean,
        dryRun: Boolean,
        onProgress: (SyncProgress) -> Unit
    ): PreparedSyncPlan = withContext(Dispatchers.IO) {

        val sourceRoot =
            DocumentFile.fromTreeUri(
                context,
                sourceUri
            ) ?: throw Exception(
                "A forrásmappa nem nyitható meg."
            )

        val targetRoot =
            DocumentFile.fromTreeUri(
                context,
                targetUri
            ) ?: throw Exception(
                "A célmappa nem nyitható meg."
            )

        if (!sourceRoot.exists()) {
            throw Exception(
                "A forrásmappa nem létezik."
            )
        }

        if (!targetRoot.exists()) {
            throw Exception(
                "A célmappa nem létezik."
            )
        }

        /*
         * FORRÁS FELMÉRÉSE
         */
        onProgress(
            SyncProgress(
                percent = 0,
                processedFiles = 0,
                totalFiles = 0,
                currentFile = "",
                status = "Forrás vizsgálata..."
            )
        )

        val sourceScan =
            scanTreeFast(
                context = context,
                treeUri = sourceUri,
                statusText = "Forrás vizsgálata...",
                onProgress = onProgress
            )

        /*
         * CÉL FELMÉRÉSE
         */
        onProgress(
            SyncProgress(
                percent = 0,
                processedFiles = 0,
                totalFiles = 0,
                currentFile = "",
                status = "Cél vizsgálata..."
            )
        )

        val targetScan =
            scanTreeFast(
                context = context,
                treeUri = targetUri,
                statusText = "Cél vizsgálata...",
                onProgress = onProgress
            )

        /*
         * ÖSSZEHASONLÍTÁS
         */
        onProgress(
            SyncProgress(
                percent = 0,
                processedFiles = 0,
                totalFiles = sourceScan.files.size,
                currentFile = "",
                status = "Változások összehasonlítása..."
            )
        )

        val syncState =
            SyncStateStore.load(
                context = context,
                firstUri = sourceUri,
                secondUri = targetUri
            )

        val plan =
            createPlan(
                context = context,
                sourceRoot = sourceUri.toString(),
                targetRoot = targetUri.toString(),
                sourceFiles = sourceScan.files,
                targetFiles = targetScan.files,
                mirrorMode = mirrorMode,
                syncState = syncState,
                onProgress = onProgress
            )

        PreparedSyncPlan(
            sourceUri = sourceUri,
            targetUri = targetUri,
            copies = plan.copies,
            deletions = plan.deletions,
            targetDirectories = targetScan.directories,
            sourceFiles = sourceScan.files,
            targetFiles = targetScan.files,
            knownEqualPaths = plan.knownEqualPaths,
            syncState = syncState,
            unchangedFiles = plan.unchanged,
            mirrorMode = mirrorMode,
            dryRun = dryRun
        )
    }

    /*
     * =========================================================
     * 2. FÁZIS
     * A MÁR ELKÉSZÍTETT TERV VÉGREHAJTÁSA
     * =========================================================
     */
    suspend fun executePreparedSync(
        context: Context,
        plan: PreparedSyncPlan,
        allowDelete: Boolean,
        onProgress: (SyncProgress) -> Unit
    ): SyncResult = withContext(Dispatchers.IO) {

        /*
         * Biztonsági védelem:
         * éles törlést csak kifejezett engedéllyel.
         */
        if (
            plan.mirrorMode &&
            !plan.dryRun &&
            plan.deletions.isNotEmpty() &&
            !allowDelete
        ) {
            throw DeletionConfirmationRequired(
                plan.deletions.size
            )
        }

        /*
         * Mielőtt a régi tervhez nyúlunk,
         * ellenőrizzük, hogy a két tárhely
         * még elérhető-e.
         */
        val sourceRoot =
            DocumentFile.fromTreeUri(
                context,
                plan.sourceUri
            )

        val targetRoot =
            DocumentFile.fromTreeUri(
                context,
                plan.targetUri
            )

        if (
            sourceRoot == null ||
            !sourceRoot.exists()
        ) {
            throw Exception(
                "A forrásmappa már nem érhető el."
            )
        }

        if (
            targetRoot == null ||
            !targetRoot.exists()
        ) {
            throw Exception(
                "A célmappa már nem érhető el."
            )
        }

        val newStateEntries = linkedMapOf<String, StoredSyncEntry>()

        for (path in plan.knownEqualPaths) {
            val source = plan.sourceFiles[path] ?: continue
            val target = plan.targetFiles[path] ?: continue
            makeStateEntry(plan, source, target)?.let {
                newStateEntries[path] = it
            }
        }

        val totalOperations =
            plan.copies.size +
                    plan.deletions.size

        if (totalOperations == 0) {

            onProgress(
                SyncProgress(
                    percent = 100,
                    processedFiles = 0,
                    totalFiles = 0,
                    currentFile = "",
                    status =
                        "Nincs szinkronizálandó változás."
                )
            )

            if (!plan.dryRun) {
                saveSyncState(
                    context = context,
                    plan = plan,
                    entries = newStateEntries
                )
            }

            return@withContext SyncResult(
                newFiles = 0,
                updatedFiles = 0,
                deletedFiles = 0,
                unchangedFiles =
                    plan.unchangedFiles,
                errors = emptyList(),
                dryRun = plan.dryRun
            )
        }

        val totalBytes =
            plan.copies.sumOf {
                max(
                    it.source.size,
                    1L
                )
            } +
                    plan.deletions.size

        var completedBytes = 0L
        var processedOperations = 0

        var newFiles = 0
        var updatedFiles = 0
        var deletedFiles = 0

        val errors =
            mutableListOf<String>()

        /*
         * =====================================================
         * MÁSOLÁS / FRISSÍTÉS
         * =====================================================
         */
        for (operation in plan.copies) {

            val fileSize =
                max(
                    operation.source.size,
                    1L
                )

            if (plan.dryRun) {

                completedBytes += fileSize
                processedOperations++

                if (operation.isNew) {
                    newFiles++
                } else {
                    updatedFiles++
                }

                reportProgress(
                    onProgress = onProgress,
                    completedBytes = completedBytes,
                    totalBytes = totalBytes,
                    processed = processedOperations,
                    total = totalOperations,
                    currentFile =
                        operation.relativePath,
                    status =
                        if (operation.isNew) {
                            "Próbaüzem – új fájl"
                        } else {
                            "Próbaüzem – frissítendő"
                        }
                )

                continue
            }

            try {

                val copiedTarget = copyFile(
                    context = context,
                    source = operation.source,
                    targetRoot = targetRoot,
                    relativePath =
                        operation.relativePath,
                    alreadyCompletedBytes =
                        completedBytes,
                    totalBytes = totalBytes,
                    processedOperations =
                        processedOperations,
                    totalOperations =
                        totalOperations,
                    onProgress = onProgress
                )

                makeStateEntry(
                    plan = plan,
                    source = operation.source,
                    target = copiedTarget
                )?.let {
                    newStateEntries[operation.relativePath] = it
                }

                completedBytes += fileSize
                processedOperations++

                if (operation.isNew) {
                    newFiles++
                } else {
                    updatedFiles++
                }

                reportProgress(
                    onProgress = onProgress,
                    completedBytes = completedBytes,
                    totalBytes = totalBytes,
                    processed = processedOperations,
                    total = totalOperations,
                    currentFile =
                        operation.relativePath,
                    status =
                        if (operation.isNew) {
                            "Új fájl másolása"
                        } else {
                            "Fájl frissítése"
                        }
                )

            } catch (e: Exception) {

                completedBytes += fileSize
                processedOperations++

                errors +=
                    "${operation.relativePath}: " +
                            (
                                    e.message
                                        ?: "ismeretlen hiba"
                                    )

                reportProgress(
                    onProgress = onProgress,
                    completedBytes = completedBytes,
                    totalBytes = totalBytes,
                    processed = processedOperations,
                    total = totalOperations,
                    currentFile =
                        operation.relativePath,
                    status =
                        "Hiba – folytatás..."
                )
            }
        }

        /*
         * =====================================================
         * TÜKRÖZÉSES TÖRLÉS
         * =====================================================
         */
        val affectedDirectories =
            mutableSetOf<String>()

        for (operation in plan.deletions) {

            val parentPath =
                getParentPath(
                    operation.target.relativePath
                )

            if (plan.dryRun) {

                completedBytes++
                processedOperations++
                deletedFiles++

                reportProgress(
                    onProgress = onProgress,
                    completedBytes = completedBytes,
                    totalBytes = totalBytes,
                    processed = processedOperations,
                    total = totalOperations,
                    currentFile =
                        operation.target.relativePath,
                    status =
                        "Próbaüzem – törlendő"
                )

                continue
            }

            try {

                if (
                    !DocumentsContract.deleteDocument(
                        context.contentResolver,
                        operation.target.uri
                    )
                ) {

                    throw Exception(
                        "A fájl nem törölhető."
                    )
                }

                deletedFiles++

                if (parentPath.isNotEmpty()) {
                    affectedDirectories +=
                        parentPath
                }

            } catch (e: Exception) {

                errors +=
                    "${operation.target.relativePath}: " +
                            (
                                    e.message
                                        ?: "törlési hiba"
                                    )
            }

            completedBytes++
            processedOperations++

            reportProgress(
                onProgress = onProgress,
                completedBytes = completedBytes,
                totalBytes = totalBytes,
                processed = processedOperations,
                total = totalOperations,
                currentFile =
                    operation.target.relativePath,
                status =
                    "Felesleges fájl törlése"
            )
        }

        /*
         * =====================================================
         * CSAK AZ ÉRINTETT ÜRES MAPPÁK ELLENŐRZÉSE
         * =====================================================
         */
        if (
            plan.mirrorMode &&
            !plan.dryRun &&
            affectedDirectories.isNotEmpty()
        ) {

            onProgress(
                SyncProgress(
                    percent = 99,
                    processedFiles =
                        totalOperations,
                    totalFiles =
                        totalOperations,
                    currentFile = "",
                    status =
                        "Üres mappák ellenőrzése..."
                )
            )

            try {

                removeAffectedEmptyDirectories(
                    context = context,
                    directories =
                        plan.targetDirectories,
                    affectedDirectories =
                        affectedDirectories
                )

            } catch (e: Exception) {

                errors +=
                    "Üres mappák ellenőrzése: " +
                            (
                                    e.message
                                        ?: "ismeretlen hiba"
                                    )
            }
        }

        if (!plan.dryRun && errors.isEmpty()) {
            saveSyncState(
                context = context,
                plan = plan,
                entries = newStateEntries
            )
        }

        /*
         * KÉSZ
         */
        onProgress(
            SyncProgress(
                percent = 100,
                processedFiles =
                    totalOperations,
                totalFiles =
                    totalOperations,
                currentFile = "",
                status =
                    if (errors.isEmpty()) {

                        if (plan.dryRun) {
                            "Próbaüzem kész."
                        } else {
                            "Szinkronizálás kész."
                        }

                    } else {

                        "Szinkronizálás kész, hibákkal."
                    }
            )
        )

        SyncResult(
            newFiles = newFiles,
            updatedFiles = updatedFiles,
            deletedFiles = deletedFiles,
            unchangedFiles =
                plan.unchangedFiles,
            errors = errors,
            dryRun = plan.dryRun
        )
    }

    /*
     * =========================================================
     * GYORS MAPPABEJÁRÁS
     * =========================================================
     */
    private fun scanTreeFast(
        context: Context,
        treeUri: Uri,
        statusText: String,
        onProgress: (SyncProgress) -> Unit
    ): ScanResult {

        val files =
            linkedMapOf<String, FileEntry>()

        val directories =
            linkedMapOf<String, Uri>()

        val resolver =
            context.contentResolver

        val rootDocumentId =
            DocumentsContract
                .getTreeDocumentId(
                    treeUri
                )

        val rootDocumentUri =
            DocumentsContract
                .buildDocumentUriUsingTree(
                    treeUri,
                    rootDocumentId
                )

        directories[""] =
            rootDocumentUri

        data class FolderToScan(
            val documentId: String,
            val relativePath: String
        )

        val folders =
            ArrayDeque<FolderToScan>()

        folders.add(
            FolderToScan(
                documentId =
                    rootDocumentId,
                relativePath = ""
            )
        )

        var scannedFiles = 0

        while (folders.isNotEmpty()) {

            val current =
                folders.removeFirst()

            val childrenUri =
                DocumentsContract
                    .buildChildDocumentsUriUsingTree(
                        treeUri,
                        current.documentId
                    )

            val projection =
                arrayOf(
                    DocumentsContract.Document
                        .COLUMN_DOCUMENT_ID,

                    DocumentsContract.Document
                        .COLUMN_DISPLAY_NAME,

                    DocumentsContract.Document
                        .COLUMN_MIME_TYPE,

                    DocumentsContract.Document
                        .COLUMN_SIZE,

                    DocumentsContract.Document
                        .COLUMN_LAST_MODIFIED
                )

            resolver.query(
                childrenUri,
                projection,
                null,
                null,
                null
            )?.use { cursor ->

                val idColumn =
                    cursor.getColumnIndexOrThrow(
                        DocumentsContract.Document
                            .COLUMN_DOCUMENT_ID
                    )

                val nameColumn =
                    cursor.getColumnIndexOrThrow(
                        DocumentsContract.Document
                            .COLUMN_DISPLAY_NAME
                    )

                val mimeColumn =
                    cursor.getColumnIndexOrThrow(
                        DocumentsContract.Document
                            .COLUMN_MIME_TYPE
                    )

                val sizeColumn =
                    cursor.getColumnIndex(
                        DocumentsContract.Document
                            .COLUMN_SIZE
                    )

                val modifiedColumn =
                    cursor.getColumnIndex(
                        DocumentsContract.Document
                            .COLUMN_LAST_MODIFIED
                    )

                while (cursor.moveToNext()) {

                    val documentId =
                        cursor.getString(
                            idColumn
                        )

                    val name =
                        cursor.getString(
                            nameColumn
                        ) ?: continue

                    val mimeType =
                        cursor.getString(
                            mimeColumn
                        )

                    val relativePath =
                        if (
                            current
                                .relativePath
                                .isEmpty()
                        ) {

                            name

                        } else {

                            "${current.relativePath}/$name"
                        }

                    val documentUri =
                        DocumentsContract
                            .buildDocumentUriUsingTree(
                                treeUri,
                                documentId
                            )

                    /*
                     * ALMAPPA
                     */
                    if (
                        mimeType ==
                        DocumentsContract.Document
                            .MIME_TYPE_DIR
                    ) {

                        directories[
                            relativePath
                        ] = documentUri

                        folders.add(
                            FolderToScan(
                                documentId =
                                    documentId,
                                relativePath =
                                    relativePath
                            )
                        )

                        continue
                    }

                    /*
                     * FÁJL
                     */
                    val size =
                        if (
                            sizeColumn >= 0 &&
                            !cursor.isNull(
                                sizeColumn
                            )
                        ) {

                            cursor.getLong(
                                sizeColumn
                            )

                        } else {

                            0L
                        }

                    val modified =
                        if (
                            modifiedColumn >= 0 &&
                            !cursor.isNull(
                                modifiedColumn
                            )
                        ) {

                            cursor.getLong(
                                modifiedColumn
                            )

                        } else {

                            0L
                        }

                    files[
                        relativePath
                    ] =
                        FileEntry(
                            relativePath =
                                relativePath,
                            uri =
                                documentUri,
                            name =
                                name,
                            mimeType =
                                mimeType,
                            size =
                                size,
                            modified =
                                modified
                        )

                    scannedFiles++

                    if (
                        scannedFiles %
                        SCAN_PROGRESS_INTERVAL ==
                        0
                    ) {

                        onProgress(
                            SyncProgress(
                                percent = 0,
                                processedFiles =
                                    scannedFiles,
                                totalFiles = 0,
                                currentFile =
                                    current.relativePath,
                                status =
                                    statusText
                            )
                        )
                    }
                }
            }
        }

        onProgress(
            SyncProgress(
                percent = 0,
                processedFiles =
                    scannedFiles,
                totalFiles = 0,
                currentFile = "",
                status =
                    "$statusText kész"
            )
        )

        return ScanResult(
            files = files,
            directories =
                directories
        )
    }

    /*
     * =========================================================
     * SZINKRONTERV ELKÉSZÍTÉSE
     * =========================================================
     */
    private data class InternalPlan(
        val copies: List<CopyOperation>,
        val deletions: List<DeleteOperation>,
        val unchanged: Int,
        val knownEqualPaths: Set<String>
    )

    private fun createPlan(
        context: Context,
        sourceRoot: String,
        targetRoot: String,
        sourceFiles:
        Map<String, FileEntry>,
        targetFiles:
        Map<String, FileEntry>,
        mirrorMode: Boolean,
        syncState: SyncStateSnapshot,
        onProgress: (SyncProgress) -> Unit
    ): InternalPlan {

        val copies =
            mutableListOf<CopyOperation>()

        val deletions =
            mutableListOf<DeleteOperation>()

        var unchanged = 0
        var compared = 0
        val knownEqualPaths = mutableSetOf<String>()

        val total =
            sourceFiles.size

        for (
        (relativePath, source)
        in sourceFiles
        ) {

            compared++

            /*
             * Összehasonlítás közben is jelezzük,
             * hogy halad a munka.
             */
            if (
                compared %
                COMPARE_PROGRESS_INTERVAL ==
                0 ||
                compared == total
            ) {

                onProgress(
                    SyncProgress(
                        percent = 0,
                        processedFiles =
                            compared,
                        totalFiles =
                            total,
                        currentFile =
                            relativePath,
                        status =
                            "Változások összehasonlítása..."
                    )
                )
            }

            val target =
                targetFiles[
                    relativePath
                ]

            /*
             * ÚJ
             */
            if (target == null) {

                copies +=
                    CopyOperation(
                        source = source,
                        relativePath =
                            relativePath,
                        isNew = true
                    )

                continue
            }

            /*
             * GYORS ÚT: az előző sikeres szinkronban ez a két
             * fájlpéldány biztosan azonos volt, és azóta egyik
             * oldal metaadata sem változott. Ilyenkor nem nyitjuk
             * meg a fájlokat és nem számolunk SHA-256-ot.
             */
            val storedEntry = syncState.entries[relativePath]
            if (storedEntry != null) {
                val storedSource = syncState.metaFor(sourceRoot, storedEntry)
                val storedTarget = syncState.metaFor(targetRoot, storedEntry)

                if (
                    storedSource != null &&
                    storedTarget != null &&
                    metadataMatches(source, storedSource) &&
                    metadataMatches(target, storedTarget)
                ) {
                    unchanged++
                    knownEqualPaths += relativePath
                    continue
                }
            }

            /*
             * ELTÉRŐ MÉRET
             */
            if (
                source.size !=
                target.size
            ) {

                if (
                    mirrorMode ||
                    isSourceNewer(
                        source,
                        target
                    )
                ) {

                    copies +=
                        CopyOperation(
                            source = source,
                            relativePath =
                                relativePath,
                            isNew = false
                        )

                } else {

                    unchanged++
                }

                continue
            }

            /*
             * AZONOS IDŐBÉLYEG
             */
            if (
                timestampsEquivalent(
                    source.modified,
                    target.modified
                )
            ) {

                unchanged++
                knownEqualPaths += relativePath
                continue
            }

            /*
             * Azonos méret, eltérő dátum:
             * csak akkor jutunk SHA-256-ig, ha a SyncState
             * alapján sem tudtuk bizonyítani a változatlanságot.
             */
            val sameContent =
                try {

                    filesHaveSameContent(
                        context = context,
                        first = source,
                        second = target
                    )

                } catch (_: Exception) {

                    false
                }

            if (sameContent) {

                unchanged++
                knownEqualPaths += relativePath
                continue
            }

            if (
                mirrorMode ||
                isSourceNewer(
                    source,
                    target
                )
            ) {

                copies +=
                    CopyOperation(
                        source = source,
                        relativePath =
                            relativePath,
                        isNew = false
                    )

            } else {

                unchanged++
            }
        }

        /*
         * TÜKRÖZÉS:
         * ami csak a célon van, törlendő.
         */
        if (mirrorMode) {

            for (
            (relativePath, target)
            in targetFiles
            ) {

                if (
                    !sourceFiles
                        .containsKey(
                            relativePath
                        )
                ) {

                    deletions +=
                        DeleteOperation(
                            target
                        )
                }
            }
        }

        return InternalPlan(
            copies = copies,
            deletions = deletions,
            unchanged = unchanged,
            knownEqualPaths = knownEqualPaths
        )
    }

    /*
     * =========================================================
     * IDŐBÉLYEG
     * =========================================================
     */
    private fun metadataMatches(
        current: FileEntry,
        stored: StoredFileMeta
    ): Boolean {
        if (current.size != stored.size) return false
        if (current.modified <= 0L || stored.modified <= 0L) return false
        return abs(current.modified - stored.modified) <= TIME_TOLERANCE_MS
    }

    private fun timestampsEquivalent(
        first: Long,
        second: Long
    ): Boolean {

        if (
            first <= 0L ||
            second <= 0L
        ) {
            return false
        }

        return abs(
            first - second
        ) <= TIME_TOLERANCE_MS
    }

    private fun isSourceNewer(
        source: FileEntry,
        target: FileEntry
    ): Boolean {

        if (
            source.modified <= 0L ||
            target.modified <= 0L
        ) {
            return true
        }

        return source.modified >
                target.modified +
                TIME_TOLERANCE_MS
    }

    /*
     * =========================================================
     * SHA-256
     * =========================================================
     */
    private fun filesHaveSameContent(
        context: Context,
        first: FileEntry,
        second: FileEntry
    ): Boolean {

        if (
            first.size !=
            second.size
        ) {
            return false
        }

        val hash1 =
            calculateSha256(
                context,
                first.uri
            )

        val hash2 =
            calculateSha256(
                context,
                second.uri
            )

        return hash1.contentEquals(
            hash2
        )
    }

    private fun calculateSha256(
        context: Context,
        uri: Uri
    ): ByteArray {

        val digest =
            MessageDigest.getInstance(
                "SHA-256"
            )

        context.contentResolver
            .openInputStream(
                uri
            )
            .use { input ->

                if (input == null) {

                    throw Exception(
                        "A fájl nem olvasható."
                    )
                }

                val buffer =
                    ByteArray(
                        BUFFER_SIZE
                    )

                while (true) {

                    val count =
                        input.read(
                            buffer
                        )

                    if (count <= 0) {
                        break
                    }

                    digest.update(
                        buffer,
                        0,
                        count
                    )
                }
            }

        return digest.digest()
    }

    /*
     * =========================================================
     * FÁJLMÁSOLÁS
     * =========================================================
     */
    private fun copyFile(
        context: Context,
        source: FileEntry,
        targetRoot: DocumentFile,
        relativePath: String,
        alreadyCompletedBytes: Long,
        totalBytes: Long,
        processedOperations: Int,
        totalOperations: Int,
        onProgress: (SyncProgress) -> Unit
    ): FileEntry {

        val parts =
            relativePath
                .split("/")
                .filter {
                    it.isNotBlank()
                }

        if (parts.isEmpty()) {
            throw Exception(
                "Érvénytelen fájlnév."
            )
        }

        var destinationDirectory =
            targetRoot

        /*
         * ALMAPPÁK
         */
        for (
        index in
        0 until parts.lastIndex
        ) {

            val folderName =
                parts[index]

            var next =
                destinationDirectory
                    .findFile(
                        folderName
                    )

            if (next == null) {

                next =
                    destinationDirectory
                        .createDirectory(
                            folderName
                        )
            }

            if (
                next == null ||
                !next.isDirectory
            ) {

                throw Exception(
                    "Nem hozható létre a mappa: $folderName"
                )
            }

            destinationDirectory =
                next
        }

        val fileName =
            parts.last()

        /*
         * RÉGI CÉLFÁJL
         */
        destinationDirectory
            .findFile(
                fileName
            )
            ?.let { oldFile ->

                if (!oldFile.delete()) {

                    throw Exception(
                        "A régi célfájl nem törölhető: $fileName"
                    )
                }
            }

        val mimeType =
            source.mimeType
                ?: "application/octet-stream"

        val destination =
            destinationDirectory
                .createFile(
                    mimeType,
                    fileName
                )
                ?: throw Exception(
                    "A célfájl nem hozható létre: $fileName"
                )

        val sourceSize =
            max(
                source.size,
                1L
            )

        context.contentResolver
            .openInputStream(
                source.uri
            )
            .use { input ->

                if (input == null) {

                    throw Exception(
                        "A forrásfájl nem olvasható: $fileName"
                    )
                }

                context.contentResolver
                    .openOutputStream(
                        destination.uri,
                        "w"
                    )
                    .use { output ->

                        if (output == null) {

                            throw Exception(
                                "A célfájl nem írható: $fileName"
                            )
                        }

                        val buffer =
                            ByteArray(
                                BUFFER_SIZE
                            )

                        var currentFileBytes =
                            0L

                        var lastShownPercent =
                            -1

                        while (true) {

                            val count =
                                input.read(
                                    buffer
                                )

                            if (count <= 0) {
                                break
                            }

                            output.write(
                                buffer,
                                0,
                                count
                            )

                            currentFileBytes +=
                                count

                            val overallBytes =
                                alreadyCompletedBytes +
                                        currentFileBytes

                            val currentPercent =
                                calculatePercent(
                                    overallBytes,
                                    totalBytes
                                )

                            if (
                                currentPercent !=
                                lastShownPercent
                            ) {

                                lastShownPercent =
                                    currentPercent

                                onProgress(
                                    SyncProgress(
                                        percent =
                                            minOf(
                                                currentPercent,
                                                99
                                            ),
                                        processedFiles =
                                            processedOperations,
                                        totalFiles =
                                            totalOperations,
                                        currentFile =
                                            relativePath,
                                        status =
                                            "Másolás..."
                                    )
                                )
                            }
                        }

                        output.flush()
                    }
            }

        /*
         * MÉRETELLENŐRZÉS
         */
        if (
            sourceSize > 1L &&
            destination.length() !=
            source.size
        ) {

            throw Exception(
                "A másolt fájl mérete hibás."
            )
        }

        return FileEntry(
            relativePath = relativePath,
            uri = destination.uri,
            name = fileName,
            mimeType = destination.type ?: mimeType,
            size = destination.length(),
            modified = destination.lastModified()
        )
    }

    private fun makeStateEntry(
        plan: PreparedSyncPlan,
        source: FileEntry,
        target: FileEntry
    ): StoredSyncEntry? {
        return plan.syncState.makeEntry(
            firstEndpointRoot = plan.sourceUri.toString(),
            firstMeta = StoredFileMeta(source.size, source.modified),
            secondEndpointRoot = plan.targetUri.toString(),
            secondMeta = StoredFileMeta(target.size, target.modified)
        )
    }

    private fun saveSyncState(
        context: Context,
        plan: PreparedSyncPlan,
        entries: Map<String, StoredSyncEntry>
    ) {
        val snapshot = SyncStateSnapshot(
            firstRoot = plan.syncState.firstRoot,
            secondRoot = plan.syncState.secondRoot,
            entries = LinkedHashMap(entries)
        )
        SyncStateStore.save(context, snapshot)
    }

    /*
     * =========================================================
     * ÜRES MAPPÁK TAKARÍTÁSA
     * =========================================================
     */
    private fun removeAffectedEmptyDirectories(
        context: Context,
        directories: Map<String, Uri>,
        affectedDirectories: Set<String>
    ) {

        val candidates =
            mutableSetOf<String>()

        for (
        originalPath in
        affectedDirectories
        ) {

            var path =
                originalPath

            while (path.isNotEmpty()) {

                candidates += path

                path =
                    getParentPath(
                        path
                    )
            }
        }

        /*
         * Legmélyebb mappa először.
         */
        val sorted =
            candidates.sortedByDescending {
                pathDepth(it)
            }

        for (path in sorted) {

            val directoryUri =
                directories[path]
                    ?: continue

            if (
                !documentExists(
                    context,
                    directoryUri
                )
            ) {
                continue
            }

            if (
                isDirectoryEmpty(
                    context,
                    directoryUri
                )
            ) {

                try {

                    DocumentsContract
                        .deleteDocument(
                            context.contentResolver,
                            directoryUri
                        )

                } catch (_: Exception) {

                    /*
                     * Nem kritikus hiba.
                     */
                }
            }
        }
    }

    private fun isDirectoryEmpty(
        context: Context,
        directoryUri: Uri
    ): Boolean {

        val documentId =
            DocumentsContract
                .getDocumentId(
                    directoryUri
                )

        val childrenUri =
            DocumentsContract
                .buildChildDocumentsUriUsingTree(
                    directoryUri,
                    documentId
                )

        val projection =
            arrayOf(
                DocumentsContract.Document
                    .COLUMN_DOCUMENT_ID
            )

        context.contentResolver
            .query(
                childrenUri,
                projection,
                null,
                null,
                null
            )
            ?.use { cursor ->

                return !cursor.moveToFirst()
            }

        return false
    }

    private fun documentExists(
        context: Context,
        uri: Uri
    ): Boolean {

        return try {

            context.contentResolver
                .query(
                    uri,
                    arrayOf(
                        DocumentsContract.Document
                            .COLUMN_DOCUMENT_ID
                    ),
                    null,
                    null,
                    null
                )
                ?.use { cursor ->

                    cursor.moveToFirst()
                } ?: false

        } catch (_: Exception) {

            false
        }
    }

    /*
     * =========================================================
     * ÚTVONALAK
     * =========================================================
     */
    private fun getParentPath(
        relativePath: String
    ): String {

        val index =
            relativePath
                .lastIndexOf('/')

        return if (index < 0) {

            ""

        } else {

            relativePath.substring(
                0,
                index
            )
        }
    }

    private fun pathDepth(
        path: String
    ): Int {

        if (path.isEmpty()) {
            return 0
        }

        return path.count {
            it == '/'
        } + 1
    }

    /*
     * =========================================================
     * PROGRESS
     * =========================================================
     */
    private fun reportProgress(
        onProgress: (SyncProgress) -> Unit,
        completedBytes: Long,
        totalBytes: Long,
        processed: Int,
        total: Int,
        currentFile: String,
        status: String
    ) {

        val value =
            calculatePercent(
                completedBytes,
                totalBytes
            )

        onProgress(
            SyncProgress(
                percent =
                    minOf(
                        value,
                        99
                    ),
                processedFiles =
                    processed,
                totalFiles =
                    total,
                currentFile =
                    currentFile,
                status =
                    status
            )
        )
    }

    private fun calculatePercent(
        completed: Long,
        total: Long
    ): Int {

        if (total <= 0L) {
            return 100
        }

        return (
                completed
                    .toDouble()
                    .div(
                        total.toDouble()
                    )
                    .times(100.0)
                )
            .toInt()
            .coerceIn(
                0,
                100
            )
    }
}