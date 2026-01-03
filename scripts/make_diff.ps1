#requires -Version 5.1
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
  [switch]$ShellEscape
)

$ErrorActionPreference = "Stop"

# 文字化けを減らす（latexdiff の警告表示用）
try {
  & chcp 65001 | Out-Null
} catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# repo root = scripts/ の親
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Assert-Command([string]$cmd) {
  $null = Get-Command $cmd -ErrorAction Stop
}

function New-EmptyDir([string]$path) {
  if (Test-Path $path) { Remove-Item -Recurse -Force $path }
  New-Item -ItemType Directory -Force -Path $path | Out-Null
}

function Export-GitZip([string]$ref, [string]$dest) {
  New-Item -ItemType Directory -Force -Path $dest | Out-Null
  $zip = Join-Path $env:TEMP ("latexdiff-{0}-{1}.zip" -f ($ref -replace '[^\w\.-]','_'), (Get-Random))
  if (Test-Path $zip) { Remove-Item -Force $zip }

  & git archive --format=zip --output "$zip" $ref
  if ($LASTEXITCODE -ne 0) { throw "git archive failed for ref=$ref" }

  Expand-Archive -Path $zip -DestinationPath $dest -Force
  Remove-Item -Force $zip
}

function Copy-Worktree([string]$src, [string]$dest) {
  New-EmptyDir $dest
  # .git, out, diff, build などを避けてコピー（最低限）
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
    return (Join-Path $RepoRoot (Join-Path "preambles" $map[$style]))
  }
  return $null
}

# ---- main ----
Push-Location $RepoRoot

Assert-Command "git"
Assert-Command "latexdiff"
Assert-Command "lualatex"
Assert-Command "biber"

# latexpand は無い環境もあるので任意扱い
$HasLatexpand = $true
try { Get-Command "latexpand" -ErrorAction Stop | Out-Null } catch { $HasLatexpand = $false }

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
$diffTexPath = Join-Path $DiffDir (Split-Path $RootTex -Leaf)
$ldArgs = @("--encoding=utf8", "--math-markup=$MathMarkup", "--graphics-markup=$GraphicsMarkup")
if ($preamble) { $ldArgs += "--preamble=$preamble" }

# cite markup は style/文献状況によって壊れることがあるので auto 選択
if ($DisableCitationMarkup -eq "on") { $ldArgs += "--disable-citation-markup" }
elseif ($DisableCitationMarkup -eq "auto" -and $Style -like "*underline*") { $ldArgs += "--disable-citation-markup" }

# latexdiff の出力を diff\main.tex に書く
& latexdiff @ldArgs "$BaseFlat" "$HeadFlat" | Out-File -FilePath $diffTexPath -Encoding utf8
if ($LASTEXITCODE -ne 0) { throw "latexdiff failed" }
Write-Host "Writing diff tex -> $diffTexPath"

# ---- compile diff ----
$outDir = Join-Path $DiffDir "out"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

Push-Location $DiffDir

$texLeaf = Split-Path $RootTex -Leaf
$job = [System.IO.Path]::GetFileNameWithoutExtension($texLeaf)

$lualatexArgs = @(
  "-synctex=1",
  "-interaction=nonstopmode",
  "-file-line-error",
  "-halt-on-error",
  "-output-directory=$outDir"
)
if ($ShellEscape) { $lualatexArgs += "-shell-escape" }

Write-Host "Compiling diff\$texLeaf with LuaLaTeX + biber (output: diff\out)"
& lualatex @lualatexArgs "$texLeaf"
if ($LASTEXITCODE -ne 0) { throw "lualatex failed (1st pass). Check diff\out\$job.log" }

& biber "--input-directory=$outDir" "--output-directory=$outDir" "$job"
if ($LASTEXITCODE -ne 0) { throw "biber failed. Check diff\out\$job.blg" }

& lualatex @lualatexArgs "$texLeaf"
if ($LASTEXITCODE -ne 0) { throw "lualatex failed (2nd pass). Check diff\out\$job.log" }

& lualatex @lualatexArgs "$texLeaf"
if ($LASTEXITCODE -ne 0) { throw "lualatex failed (3rd pass). Check diff\out\$job.log" }

Pop-Location

Write-Host ("Done: {0}" -f (Join-Path $outDir "$job.pdf"))

# cleanup temp
try { Remove-Item -Recurse -Force $TempBase, $TempHead } catch {}
try { Remove-Item -Force $BaseFlat, $HeadFlat } catch {}

Pop-Location
