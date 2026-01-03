Param(
  [string]$RootTex = "main.tex",
  [string]$BaseRef = "HEAD~1",
  [string]$HeadRef = "HEAD",
  [switch]$CompareWorktree,

  # latexdiff style (Japanese-friendly default)
  [ValidateSet("ja-color","ja-underline","ja-uline","cfont","underline")]
  [string]$Style = "ja-color",

  # latexdiff knobs
  [string]$MathMarkup = "coarse",
  [ValidateSet("none","new-only","both")]
  [string]$GraphicsMarkup = "new-only",

  # auto: enable for underline styles; true/false: force
  [ValidateSet("auto","true","false")]
  [string]$DisableCitationMarkup = "auto",

  # Temporary workspace root (default: system temp)
  [string]$TmpRoot = ""
)

<#
PowerShell-native diff builder for Windows.

Why this script exists:
  * latexdiff-vc uses a POSIX-shell pipeline (git archive ... | ( cd ... ; tar -xf -)),
    which often fails when executed from PowerShell/cmd on Windows.
  * This script avoids that by using `git archive --format=zip` + Expand-Archive,
    then running `latexdiff` directly.

Outputs:
  - diff/<project files...>  (a copy of HeadRef or your worktree)
  - diff/<RootTex>           (diff-marked root tex, overwriting the copied version)
  - diff/out/<jobname>.pdf   (compiled diff PDF)

Requirements:
  - git (must be on PATH)
  - TeX Live / LuaLaTeX + biber
  - latexdiff (TeX Live: scripts/latexdiff)
  - (optional) latexpand (for --flatten; TeX Live typically includes it)
#>

$ErrorActionPreference = "Stop"

function Assert-Command([string]$cmd) {
  if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
    throw "Required command not found on PATH: $cmd"
  }
}

function Sanitize-Name([string]$s) {
  # For directory/file names: replace characters not allowed in Windows paths.
  return ($s -replace '[\\/:*?"<>|]', '_') -replace '\s+', '_'
}

function Export-GitRefToDir([string]$ref, [string]$destDir) {
  # Exports the repository state at $ref into $destDir using zip (PowerShell-friendly).
  $zipName = "git-archive-{0}-{1}.zip" -f (Sanitize-Name $ref), $PID
  $zipPath = Join-Path $Global:TmpRootAbs $zipName

  if (Test-Path $destDir) { Remove-Item -Recurse -Force $destDir }
  New-Item -ItemType Directory -Force $destDir | Out-Null

  Write-Host "Exporting $ref -> $destDir"
  & git archive --format=zip -o $zipPath $ref | Out-Null
  Expand-Archive -Force -Path $zipPath -DestinationPath $destDir
  Remove-Item -Force $zipPath
}

function Copy-WorktreeToDir([string]$destDir) {
  # Copies current working tree to destDir, excluding .git and build artifacts.
  if (Test-Path $destDir) { Remove-Item -Recurse -Force $destDir }
  New-Item -ItemType Directory -Force $destDir | Out-Null

  Write-Host "Copying working tree -> $destDir"
  # robocopy is reliable for large trees; /NFL /NDL to reduce noise.
  $excludeDirs = @(".git","out","build","diff",".vscode","node_modules")
  $xd = $excludeDirs | ForEach-Object { "/XD", (Join-Path $RepoRoot $_) }
  & robocopy $RepoRoot $destDir /E /NFL /NDL /NJH /NJS /NC /NS /NP @xd | Out-Null
}

# --- setup ---
Assert-Command git
Assert-Command lualatex
Assert-Command biber
Assert-Command latexdiff

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $RepoRoot

# temp root
if ([string]::IsNullOrWhiteSpace($TmpRoot)) {
  $TmpRootAbs = $env:TEMP
} else {
  $TmpRootAbs = (Resolve-Path $TmpRoot).Path
}
$Global:TmpRootAbs = $TmpRootAbs

# Prepare diff workspace
if (Test-Path "diff") { Remove-Item -Recurse -Force "diff" }
New-Item -ItemType Directory -Force "diff" | Out-Null

# Prepare base/head working copies
$baseDir = Join-Path $TmpRootAbs ("latexdiff-base-{0}-{1}" -f (Sanitize-Name $BaseRef), $PID)
$headDir = Join-Path $TmpRootAbs ("latexdiff-head-{0}-{1}" -f (Sanitize-Name $HeadRef), $PID)

Export-GitRefToDir $BaseRef $baseDir

if ($CompareWorktree) {
  Copy-WorktreeToDir $headDir
  Copy-WorktreeToDir (Join-Path $RepoRoot "diff")  # compilation workspace
  Write-Host "Generating diff: $BaseRef -> working tree ($RootTex)"
} else {
  Export-GitRefToDir $HeadRef $headDir
  Export-GitRefToDir $HeadRef (Join-Path $RepoRoot "diff")  # compilation workspace
  Write-Host "Generating diff: $BaseRef -> $HeadRef ($RootTex)"
}

$oldTex = Join-Path $baseDir $RootTex
$newTex = Join-Path $headDir $RootTex
$diffTex = Join-Path (Join-Path $RepoRoot "diff") $RootTex

if (-not (Test-Path $oldTex)) { throw "Old tex not found: $oldTex" }
if (-not (Test-Path $newTex)) { throw "New tex not found: $newTex" }

# --- latexdiff options ---
$diffOpts = @(
  "--encoding=utf8",
  "--flatten",
  "--math-markup=$MathMarkup",
  "--graphics-markup=$GraphicsMarkup"
)

switch ($Style) {
  "ja-color"     { $diffOpts += "--preamble=$(Join-Path $RepoRoot 'preambles/latexdiff_preamble_ja_color.ltxdiff')" }
  "ja-underline" { $diffOpts += "--preamble=$(Join-Path $RepoRoot 'preambles/latexdiff_preamble_ja_underline.ltxdiff')" }
  "ja-uline"     { $diffOpts += "--preamble=$(Join-Path $RepoRoot 'preambles/latexdiff_preamble_ja_uline.ltxdiff')" }
  "cfont"        { $diffOpts += "--type=CFONT" }
  "underline"    { $diffOpts += "--type=UNDERLINE" }
}

if ($DisableCitationMarkup -eq "true") {
  $diffOpts += "--disable-citation-markup"
} elseif ($DisableCitationMarkup -eq "auto") {
  if (($Style -eq "underline") -or ($Style -eq "ja-underline")) {
    $diffOpts += "--disable-citation-markup"
  }
}

# Generate diff tex (overwrite the copied RootTex inside diff/)
Write-Host "Writing diff tex -> $diffTex"
$diffDir = Split-Path -Parent $diffTex
if (-not (Test-Path $diffDir)) { New-Item -ItemType Directory -Force $diffDir | Out-Null }

# PowerShell: ensure UTF-8 output without BOM (LuaLaTeX generally ok either way, but be safe)
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$diffContent = & latexdiff @diffOpts $oldTex $newTex
[System.IO.File]::WriteAllText($diffTex, $diffContent, $utf8NoBom)

# --- compile inside diff workspace ---
$jobName = [System.IO.Path]::GetFileNameWithoutExtension($RootTex)
$outDir = Join-Path "out"
Push-Location "diff"

New-Item -ItemType Directory -Force $outDir | Out-Null

Write-Host "Compiling $RootTex with LuaLaTeX + biber (output: diff\$outDir)"
& lualatex -synctex=1 -interaction=nonstopmode -file-line-error -halt-on-error -output-directory=$outDir $RootTex
& biber --input-directory=$outDir --output-directory=$outDir --bblencoding=utf8 -u -U --output_safechars $jobName
& lualatex -synctex=1 -interaction=nonstopmode -file-line-error -halt-on-error -output-directory=$outDir $RootTex
& lualatex -synctex=1 -interaction=nonstopmode -file-line-error -halt-on-error -output-directory=$outDir $RootTex

Pop-Location

Write-Host "Done: diff\out\$jobName.pdf"

# cleanup temp dirs (best-effort)
try { if (Test-Path $baseDir) { Remove-Item -Recurse -Force $baseDir } } catch {}
try { if (Test-Path $headDir) { Remove-Item -Recurse -Force $headDir } } catch {}
