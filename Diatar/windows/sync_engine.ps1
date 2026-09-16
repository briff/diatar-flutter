param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("prepare", "execute")]
    [string]$Mode,

    [Parameter(Mandatory = $true)]
    [string]$Source,

    [Parameter(Mandatory = $true)]
    [string]$Target,

    [Parameter(Mandatory = $true)]
    [ValidateSet(0, 1)]
    [int]$MirrorMode,

    [Parameter(Mandatory = $true)]
    [ValidateSet(0, 1)]
    [int]$DryRun
)

$MirrorEnabled = ($MirrorMode -eq 1)
$DryRunEnabled = ($DryRun -eq 1)

$ErrorActionPreference = "Stop"

# A Flutter/Dart oldal UTF-8 JSON sorokat vár.
# Windows PowerShell 5.1 alatt a konzol alapértelmezett kódlapja
# egyébként elronthatná a magyar ékezeteket.
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[Console]::OutputEncoding = $Utf8NoBom
[Console]::InputEncoding = $Utf8NoBom
$OutputEncoding = $Utf8NoBom

function Write-JsonLine {
    param([hashtable]$Data)
    [Console]::Out.WriteLine(($Data | ConvertTo-Json -Compress -Depth 5))
}

function Normalize-Root {
    param([string]$Path)
    return [System.IO.Path]::GetFullPath($Path).TrimEnd('\')
}

function Get-RelativePath {
    param(
        [string]$Root,
        [string]$FullName
    )

    $rootWithSlash = (Normalize-Root $Root) + '\'
    if ($FullName.StartsWith($rootWithSlash, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $FullName.Substring($rootWithSlash.Length)
    }

    return [System.IO.Path]::GetFileName($FullName)
}

function Get-FileMap {
    param([string]$Root)

    $map = @{}

    if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
        return $map
    }

    Get-ChildItem -LiteralPath $Root -File -Recurse -Force -ErrorAction Stop |
        ForEach-Object {
            $relative = Get-RelativePath -Root $Root -FullName $_.FullName
            $map[$relative.ToLowerInvariant()] = [pscustomobject]@{
                Relative = $relative
                FullName = $_.FullName
                Length = $_.Length
                LastWriteTimeUtc = $_.LastWriteTimeUtc
            }
        }

    return $map
}

function Test-NeedsCopy {
    param(
        $SourceFile,
        $TargetFile,
        [bool]$Mirror
    )

    if ($null -eq $TargetFile) {
        return $true
    }

    $timeDifference = [Math]::Abs(
        ($SourceFile.LastWriteTimeUtc - $TargetFile.LastWriteTimeUtc).TotalSeconds
    )

    if ($Mirror) {
        return (
            $SourceFile.Length -ne $TargetFile.Length -or
            $timeDifference -gt 2.0
        )
    }

    # A végrehajtás /E /XO kapcsolókkal történik.
    # /XO esetén a célon újabb fájlt nem írjuk felül.
    if ($SourceFile.LastWriteTimeUtc -lt $TargetFile.LastWriteTimeUtc.AddSeconds(-2)) {
        return $false
    }

    return (
        $SourceFile.Length -ne $TargetFile.Length -or
        $timeDifference -gt 2.0
    )
}

function Get-SyncPlan {
    param(
        [string]$From,
        [string]$To,
        [bool]$Mirror
    )

    if (-not (Test-Path -LiteralPath $From -PathType Container)) {
        throw "A forrás mappa nem létezik: $From"
    }

    $sourceFiles = Get-FileMap -Root $From
    $targetFiles = Get-FileMap -Root $To

    $newCount = 0
    $updatedCount = 0
    $deleteCount = 0

    foreach ($key in $sourceFiles.Keys) {
        $sourceFile = $sourceFiles[$key]
        $targetFile = $targetFiles[$key]

        if ($null -eq $targetFile) {
            $newCount++
        }
        elseif (Test-NeedsCopy -SourceFile $sourceFile -TargetFile $targetFile -Mirror $Mirror) {
            $updatedCount++
        }
    }

    if ($Mirror) {
        foreach ($key in $targetFiles.Keys) {
            if (-not $sourceFiles.ContainsKey($key)) {
                $deleteCount++
            }
        }
    }

    return [pscustomobject]@{
        NewFileCount = $newCount
        UpdatedFileCount = $updatedCount
        CopyCount = $newCount + $updatedCount
        DeleteCount = $deleteCount
        UnchangedCount = [Math]::Max(
            0,
            $sourceFiles.Count - $newCount - $updatedCount
        )
        SourceFileCount = $sourceFiles.Count
    }
}

function Invoke-Robocopy {
    param(
        [string]$From,
        [string]$To,
        [bool]$Mirror,
        [bool]$ListOnly
    )

    if (-not (Test-Path -LiteralPath $From -PathType Container)) {
        throw "A forrás mappa nem létezik: $From"
    }

    if (-not (Test-Path -LiteralPath $To -PathType Container)) {
        if ($ListOnly) {
            # A /L felmérés kedvéért nem hozunk létre tartós célmappát.
            # A tényleges futás előtt viszont létre kell hozni.
        }
        else {
            New-Item -ItemType Directory -Path $To -Force | Out-Null
        }
    }

    $exe = Join-Path $env:SystemRoot "System32\robocopy.exe"
    if (-not (Test-Path -LiteralPath $exe)) {
        $exe = "robocopy.exe"
    }

    $arguments = @(
        $From,
        $To,
        "/R:1",
        "/W:1",
        "/FFT",
        "/XJ",
        "/NP",
        "/NJH",
        "/NJS"
    )

    if ($Mirror) {
        $arguments += "/MIR"
    }
    else {
        $arguments += "/E"
        $arguments += "/XO"
    }

    if ($ListOnly) {
        $arguments += "/L"
    }

    # A kimenetet elnyeljük; a Flutter felé kizárólag JSON sorok mennek.
    & $exe @arguments 2>&1 | Out-Null
    $exitCode = $LASTEXITCODE

    # Robocopy: 0..7 siker / figyelmeztetés, 8+ hiba.
    if ($exitCode -ge 8) {
        throw "Robocopy hiba, exitcode=$exitCode"
    }

    return $exitCode
}

try {
    $sourcePath = Normalize-Root $Source
    $targetPath = Normalize-Root $Target

    if ($sourcePath.Equals($targetPath, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "A forrás és a cél mappa nem lehet azonos."
    }

    Write-JsonLine @{
        type = "progress"
        percent = 0
        processedFiles = 0
        totalFiles = 0
        currentFile = ""
        status = "Felmérés..."
    }

    $plan = Get-SyncPlan -From $sourcePath -To $targetPath -Mirror $MirrorEnabled

    if ($Mode -eq "prepare") {
        # A bevált Robocopy kapcsolókkal egy valódi /L próbakört is lefuttatunk.
        # Ha a cél még nem létezik, a felmérésünk már így is pontosan tudja,
        # hogy minden forrásfájl új lesz; ilyenkor nincs szükség Robocopy /L-re.
        if (Test-Path -LiteralPath $targetPath -PathType Container) {
            [void](Invoke-Robocopy `
                -From $sourcePath `
                -To $targetPath `
                -Mirror $MirrorEnabled `
                -ListOnly $true)
        }

        Write-JsonLine @{
            type = "progress"
            percent = 100
            processedFiles = $plan.SourceFileCount
            totalFiles = $plan.SourceFileCount
            currentFile = ""
            status = "Felmérés kész."
        }

        Write-JsonLine @{
            type = "plan"
            copyCount = $plan.CopyCount
            deleteCount = $plan.DeleteCount
            newFileCount = $plan.NewFileCount
            updatedFileCount = $plan.UpdatedFileCount
            mirrorMode = $MirrorEnabled
            dryRun = $DryRunEnabled
        }

        exit 0
    }

    if ($DryRunEnabled) {
        Write-JsonLine @{
            type = "progress"
            percent = 100
            processedFiles = $plan.SourceFileCount
            totalFiles = $plan.SourceFileCount
            currentFile = ""
            status = "Próbaüzem kész."
        }

        Write-JsonLine @{
            type = "result"
            newFiles = $plan.NewFileCount
            updatedFiles = $plan.UpdatedFileCount
            deletedFiles = $plan.DeleteCount
            unchangedFiles = $plan.UnchangedCount
            errors = @()
            dryRun = $true
        }

        exit 0
    }

    Write-JsonLine @{
        type = "progress"
        percent = 0
        processedFiles = 0
        totalFiles = $plan.CopyCount + $plan.DeleteCount
        currentFile = ""
        status = "Robocopy indítása..."
    }

    [void](Invoke-Robocopy `
        -From $sourcePath `
        -To $targetPath `
        -Mirror $MirrorEnabled `
        -ListOnly $false)

    Write-JsonLine @{
        type = "progress"
        percent = 100
        processedFiles = $plan.CopyCount + $plan.DeleteCount
        totalFiles = $plan.CopyCount + $plan.DeleteCount
        currentFile = ""
        status = "Szinkronizálás kész."
    }

    Write-JsonLine @{
        type = "result"
        newFiles = $plan.NewFileCount
        updatedFiles = $plan.UpdatedFileCount
        deletedFiles = $plan.DeleteCount
        unchangedFiles = $plan.UnchangedCount
        errors = @()
        dryRun = $false
    }

    exit 0
}
catch {
    Write-JsonLine @{
        type = "error"
        message = $_.Exception.Message
    }
    exit 1
}
