#requires -Version 5.1
<#
make_diff.ps1
- Generate a LaTeX diff PDF between two git refs for a thesis project (LuaLaTeX + biber).
- Windows-first implementation: uses `git archive --format=zip` + Expand-Archive.
- Produces: diff\out\<job>.pdf (job = root tex filename without extension)

Cleanup modes:
  -CleanupMode pdf+changed (default): keep diff\out\<job>.pdf + changed files (from git diff --name-only) + diff root tex
  -CleanupMode pdf-only            : keep only diff\out\<job>.pdf
  -CleanupMode none                : keep everything under diff\ (no cleanup)

Examples:
  powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\make_diff.ps1 -RootTex main.tex -BaseRef HEAD~1 -HeadRef HEAD -Style ja-color
  powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\make_diff.ps1 -RootTex main.tex -BaseRef HEAD~1 -CleanupMode pdf-only
  powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\make_diff.ps1 -RootTex main.tex -BaseRef HEAD~1 -CleanupMode none
#>

[CmdletBinding()]
param(
  [string]$RootTex = "main.tex",
  [string]$BaseRef = "HEAD~1",
  [string]$HeadRef = "HEAD",
  [ValidateSet("ja-color","ja-underline","ja-uline","underline","cfont")]
  [string]$Style = "ja-color",
  [ValidateSet("coarse","fine")]
  [string]$MathMarkup = "coarse",
  [ValidateSet("new-only","none","both")]
  [string]$GraphicsMarkup = "new-only",
  [ValidateSet("auto","on","off")]
  [string]$DisableCitationMarkup = "auto",
  [switch]$CompareWorktree,
  [switch]$ShellEscape,
  [ValidateSet("pdf+changed","pdf-only","none")]
  [string]$CleanupMode = "pdf+changed"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Reduce mojibake in console output from perl/latexdiff (best-effort)
try { & chcp 65001 | Out-Null } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# repo root = parent of scripts/
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Assert-Command([string]$cmd) {
  $null = Get-Command $cmd -ErrorAction Stop
}

function New-EmptyDir([string]$path) {
  if (Test-Path $path) { Remove-Item -Recurse -Force $path }
  New-Item -ItemType Directory -Force -Path $path | Out-Null
}

function Ensure-Dir([string]$path) {
  if (!(Test-Path $path)) { New-Item -ItemType Directory -Force -Path $path | Out-Null }
}

function Try-HasCommand([string]$cmd) {
  try { Get-Command $cmd -ErrorAction Stop | Out-Null; return $true } catch { return $false }
}

function Export-GitZip([string]$ref, [string]$dest) {
  Ensure-Dir $dest
  $zip = Join-Path $env:TEMP ("latexdiff-{0}-{1}.zip" -f ($ref -replace '[^\w\.-]','_'), (Get-Random))
  if (Test-Path $zip) { Remove-Item -Force $zip }

  & git archive --format=zip --output "$zip" $ref
  if ($LASTEXITCODE -ne 0) { throw "git archive failed for ref=$ref" }

  Expand-Archive -Path $zip -DestinationPath $dest -Force
  Remove-Item -Force $zip
}

function Copy-Worktree([string]$src, [string]$dest) {
  New-EmptyDir $dest
  $exclude = @(".git","out","diff","build")
  Get-ChildItem -LiteralPath $src -Force | ForEach-Object {
    if ($exclude -contains $_.Name) { return }
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $dest $_.Name) -Recurse -Force
  }
}

function Get-PreamblePath([string]$style) {
  $map = @{
    "ja-color"     = "latexdiff_preamble_ja_color.ltxdiff"
    "ja-underline" = "latexdiff_preamble_ja_underline.ltxdiff"
    "ja-uline"     = "latexdiff_preamble_ja_uline.ltxdiff"
  }
  if ($map.ContainsKey($style)) {
    $p = Join-Path $RepoRoot (Join-Path "preambles" $map[$style])
    if (!(Test-Path $p)) { throw "latexdiff preamble not found: $p" }
    return $p
  }
  return $null
}

function Normalize-RelPath([string]$p) {
  if ($null -eq $p) { return $null }
  $t = $p.Trim()
  if ($t.Length -eq 0) { return $null }
  $t = $t -replace '\\','/'
  return $t.ToLowerInvariant()
}

function Get-ChangedPaths([string]$baseRef, [string]$headRef, [bool]$compareWorktree) {
  $paths = New-Object System.Collections.Generic.List[string]

  if ($compareWorktree) {
    # changes between baseRef and working tree (tracked)
    $tracked = & git diff --name-only $baseRef --
    foreach ($p in $tracked) { if ($p) { $paths.Add($p) } }

    # include untracked files too (optional but practical)
    $untracked = & git ls-files --others --exclude-standard
    foreach ($p in $untracked) { if ($p) { $paths.Add($p) } }
  } else {
    $tracked = & git diff --name-only $baseRef $headRef --
    foreach ($p in $tracked) { if ($p) { $paths.Add($p) } }
  }

  # unique normalized set
  $set = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
  foreach ($p in $paths) {
    $n = Normalize-RelPath $p
    if ($n) { [void]$set.Add($n) }
  }
  return $set
}

function Cleanup-OutDirKeepPdf([string]$outDir, [string]$pdfPath) {
  # Delete all files under out except the PDF
  Get-ChildItem -LiteralPath $outDir -Force -Recurse | ForEach-Object {
    if ($_.PSIsContainer) { return }
    if ($_.FullName -ieq $pdfPath) { return }
    Remove-Item -LiteralPath $_.FullName -Force
  }
  # Remove empty dirs under out
  Get-ChildItem -LiteralPath $outDir -Force -Recurse -Directory |
    Sort-Object FullName -Descending |
    ForEach-Object {
      if (-not (Get-ChildItem -LiteralPath $_.FullName -Force)) {
        Remove-Item -LiteralPath $_.FullName -Force
      }
    }
}

function Cleanup-DiffKeepPdfOnly([string]$diffDir, [string]$outDir, [string]$pdfPath) {
  if (!(Test-Path $pdfPath)) { throw "Cleanup requested but PDF not found: $pdfPath" }

  Cleanup-OutDirKeepPdf -outDir $outDir -pdfPath $pdfPath

  # Delete everything under diff\ except "out"
  Get-ChildItem -LiteralPath $diffDir -Force | ForEach-Object {
    if ($_.Name -ieq "out") { return }
    Remove-Item -LiteralPath $_.FullName -Recurse -Force
  }
}

function Cleanup-DiffKeepPdfAndChanged([string]$diffDir, [string]$outDir, [string]$pdfPath, $keepRelSet, [string]$rootTexRel) {
  if (!(Test-Path $pdfPath)) { throw "Cleanup requested but PDF not found: $pdfPath" }

  Cleanup-OutDirKeepPdf -outDir $outDir -pdfPath $pdfPath

  # Always keep the diff root tex (it contains DIF markup)
  $rootNorm = Normalize-RelPath $rootTexRel
  if ($rootNorm) { [void]$keepRelSet.Add($rootNorm) }

  # Iterate all files under diffDir except out/
  $diffRoot = (Resolve-Path $diffDir).Path.TrimEnd('\')
  $prefix = $diffRoot + '\'

  Get-ChildItem -LiteralPath $diffDir -Force -Recurse -File | ForEach-Object {
    # Skip out directory
    if ($_.FullName.StartsWith((Join-Path $diffDir "out"), [System.StringComparison]::OrdinalIgnoreCase)) { return }

    $full = $_.FullName
    $rel = $full
    if ($full.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
      $rel = $full.Substring($prefix.Length)
    } else {
      $rel = $_.Name
    }
    $relNorm = Normalize-RelPath $rel

    if (-not $relNorm) {
      Remove-Item -LiteralPath $full -Force
      return
    }

    if (-not $keepRelSet.Contains($relNorm)) {
      Remove-Item -LiteralPath $full -Force
    }
  }

  # Remove empty directories under diffDir except out
  Get-ChildItem -LiteralPath $diffDir -Force -Recurse -Directory |
    Sort-Object FullName -Descending |
    ForEach-Object {
      if ($_.Name -ieq "out") { return }
      if (-not (Get-ChildItem -LiteralPath $_.FullName -Force)) {
        Remove-Item -LiteralPath $_.FullName -Force
      }
    }
}

# ---- main ----
$TempBase = $null
$TempHead = $null
$BaseFlat = $null
$HeadFlat = $null

Push-Location $RepoRoot
try {
  Assert-Command "git"
  Assert-Command "latexdiff"
  Assert-Command "lualatex"
  Assert-Command "biber"

  $HasLatexpand = Try-HasCommand "latexpand"

  # Determine keep set BEFORE creating diff directory (based on refs)
  $keepSet = $null
  if ($CleanupMode -eq "pdf+changed") {
    $keepSet = Get-ChangedPaths -baseRef $BaseRef -headRef $HeadRef -compareWorktree ([bool]$CompareWorktree)
  }

  $TempBase = Join-Path $env:TEMP ("latexdiff-base-{0}-{1}" -f ($BaseRef -replace '[^\w\.-]','_'), (Get-Random))
  $TempHead = Join-Path $env:TEMP ("latexdiff-head-{0}-{1}" -f ($HeadRef -replace '[^\w\.-]','_'), (Get-Random))

  Write-Host "Exporting $BaseRef -> $TempBase"
  New-EmptyDir $TempBase
  Export-GitZip $BaseRef $TempBase

  Write-Host "Exporting $HeadRef -> $TempHead"
  New-EmptyDir $TempHead
  if ($CompareWorktree) {
    Copy-Worktree $RepoRoot $TempHead
  } else {
    Export-GitZip $HeadRef $TempHead
  }

  $DiffDir = Join-Path $RepoRoot "diff"
  Write-Host "Exporting $HeadRef -> $DiffDir"
  Copy-Worktree $TempHead $DiffDir

  $BaseTex = Join-Path $TempBase $RootTex
  $HeadTex = Join-Path $TempHead $RootTex
  if (!(Test-Path $BaseTex)) { throw "Base tex not found: $BaseTex" }
  if (!(Test-Path $HeadTex)) { throw "Head tex not found: $HeadTex" }

  $BaseFlat = Join-Path $env:TEMP ("latexdiff-base-flat-{0}.tex" -f (Get-Random))
  $HeadFlat = Join-Path $env:TEMP ("latexdiff-head-flat-{0}.tex" -f (Get-Random))

  if ($HasLatexpand) {
    Write-Host "Flattening with latexpand..."
    & latexpand "$BaseTex" | Out-File -FilePath $BaseFlat -Encoding utf8
    if ($LASTEXITCODE -ne 0) { throw "latexpand failed (base)" }
    & latexpand "$HeadTex" | Out-File -FilePath $HeadFlat -Encoding utf8
    if ($LASTEXITCODE -ne 0) { throw "latexpand failed (head)" }
  } else {
    Write-Host "latexpand not found; using root tex as-is (diff may miss included-file changes)."
    Copy-Item -Force $BaseTex $BaseFlat
    Copy-Item -Force $HeadTex $HeadFlat
  }

  $preamble = Get-PreamblePath $Style

  Write-Host "Generating diff: $BaseRef -> $HeadRef ($RootTex)"
  $diffTexPath = Join-Path $DiffDir $RootTex
  $diffTexParent = Split-Path -Parent $diffTexPath
  if ($diffTexParent -and !(Test-Path $diffTexParent)) { New-Item -ItemType Directory -Force -Path $diffTexParent | Out-Null }

  $ldArgs = @("--encoding=utf8", "--math-markup=$MathMarkup", "--graphics-markup=$GraphicsMarkup")
  if ($preamble) { $ldArgs += "--preamble=$preamble" }

  # Citation markup can break with underline styles; auto-disable there.
  if ($DisableCitationMarkup -eq "on") { $ldArgs += "--disable-citation-markup" }
  elseif ($DisableCitationMarkup -eq "auto" -and $Style -like "*underline*") { $ldArgs += "--disable-citation-markup" }

  & latexdiff @ldArgs "$BaseFlat" "$HeadFlat" | Out-File -FilePath $diffTexPath -Encoding utf8
  if ($LASTEXITCODE -ne 0) { throw "latexdiff failed" }
  Write-Host "Writing diff tex -> $diffTexPath"

  # ---- compile diff ----
  $outDir = Join-Path $DiffDir "out"
  Ensure-Dir $outDir

  Push-Location $DiffDir
  try {
    $texLeaf = Split-Path -Leaf $RootTex
    $job = [System.IO.Path]::GetFileNameWithoutExtension($texLeaf)

    $lualatexArgs = @(
      "-synctex=1",
      "-interaction=nonstopmode",
      "-file-line-error",
      "-halt-on-error",
      "-output-directory=$outDir"
    )
    if ($ShellEscape) { $lualatexArgs += "-shell-escape" }

    Write-Host "Compiling diff\$RootTex with LuaLaTeX + biber (output: diff\out)"
    & lualatex @lualatexArgs "$RootTex"
    if ($LASTEXITCODE -ne 0) { throw "lualatex failed (1st pass). Check diff\out\$job.log" }

    & biber "--input-directory=$outDir" "--output-directory=$outDir" "$job"
    if ($LASTEXITCODE -ne 0) { throw "biber failed. Check diff\out\$job.blg" }

    & lualatex @lualatexArgs "$RootTex"
    if ($LASTEXITCODE -ne 0) { throw "lualatex failed (2nd pass). Check diff\out\$job.log" }

    & lualatex @lualatexArgs "$RootTex"
    if ($LASTEXITCODE -ne 0) { throw "lualatex failed (3rd pass). Check diff\out\$job.log" }

    $pdfPath = Join-Path $outDir "$job.pdf"
    Write-Host ("Done: {0}" -f $pdfPath)

    # ---- cleanup ----
    if ($CleanupMode -eq "pdf-only") {
      Cleanup-DiffKeepPdfOnly -diffDir $DiffDir -outDir $outDir -pdfPath $pdfPath
      Write-Host ("Cleanup(pdf-only) done: kept only {0}" -f $pdfPath)
    }
    elseif ($CleanupMode -eq "pdf+changed") {
      Cleanup-DiffKeepPdfAndChanged -diffDir $DiffDir -outDir $outDir -pdfPath $pdfPath -keepRelSet $keepSet -rootTexRel $RootTex
      Write-Host ("Cleanup(pdf+changed) done: kept {0} and changed files." -f $pdfPath)
    }
    else {
      Write-Host "Cleanup skipped (CleanupMode=none)."
    }
  }
  finally {
    Pop-Location | Out-Null
  }
}
finally {
  # cleanup temp exports/flats
  try { if ($TempBase -and (Test-Path $TempBase)) { Remove-Item -Recurse -Force $TempBase } } catch {}
  try { if ($TempHead -and (Test-Path $TempHead)) { Remove-Item -Recurse -Force $TempHead } } catch {}
  try { if ($BaseFlat -and (Test-Path $BaseFlat)) { Remove-Item -Force $BaseFlat } } catch {}
  try { if ($HeadFlat -and (Test-Path $HeadFlat)) { Remove-Item -Force $HeadFlat } } catch {}

  Pop-Location | Out-Null
}
# ---- end of script ----