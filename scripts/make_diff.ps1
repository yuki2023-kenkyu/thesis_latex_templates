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
  [string]$DisableCitationMarkup = "auto"
)

<#
Usage:
  powershell -ExecutionPolicy Bypass -File .\scripts\make_diff.ps1
  powershell -ExecutionPolicy Bypass -File .\scripts\make_diff.ps1 -RootTex main.tex -BaseRef main -HeadRef HEAD
  powershell -ExecutionPolicy Bypass -File .\scripts\make_diff.ps1 -RootTex main.tex -BaseRef main -CompareWorktree

Requirements (Windows):
  - git
  - TeX Live (lualatex, biber)
  - latexdiff-vc
    * If TeX Live is installed, latexdiff-vc is typically available.
    * Otherwise, install latexdiff (Perl script) via TeX Live package manager.
#>

$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $RepoRoot

if (Test-Path "diff") { Remove-Item -Recurse -Force "diff" }
New-Item -ItemType Directory -Force "diff" | Out-Null

# --- latexdiff options ---
$diffOpts = @(
  "--encoding=utf8",
  "--math-markup=$MathMarkup",
  "--graphics-markup=$GraphicsMarkup"
)

switch ($Style) {
  "ja-color" { $diffOpts += "--preamble=preambles/latexdiff_preamble_ja_color.ltxdiff" }
  "ja-underline" { $diffOpts += "--preamble=preambles/latexdiff_preamble_ja_underline.ltxdiff" }
  "ja-uline" { $diffOpts += "--preamble=preambles/latexdiff_preamble_ja_uline.ltxdiff" }
  "cfont" { $diffOpts += "--type=CFONT" }
  "underline" { $diffOpts += "--type=UNDERLINE" }
}

if ($DisableCitationMarkup -eq "true") {
  $diffOpts += "--disable-citation-markup"
} elseif ($DisableCitationMarkup -eq "auto") {
  if (($Style -eq "underline") -or ($Style -eq "ja-underline")) {
    $diffOpts += "--disable-citation-markup"
  }
}

if ($CompareWorktree) {
  Write-Host "Generating diff: $BaseRef -> working tree ($RootTex)"
  & latexdiff-vc @diffOpts --git --flatten --force -d diff -r $BaseRef $RootTex
} else {
  Write-Host "Generating diff: $BaseRef -> $HeadRef ($RootTex)"
  & latexdiff-vc @diffOpts --git --flatten --force -d diff -r $BaseRef -r $HeadRef $RootTex
}

$DiffTex = Join-Path "diff" ([System.IO.Path]::GetFileName($RootTex))
$JobName = [System.IO.Path]::GetFileNameWithoutExtension($RootTex)
$OutDir = Join-Path "diff" "out"
New-Item -ItemType Directory -Force $OutDir | Out-Null

Write-Host "Compiling $DiffTex with LuaLaTeX + biber (output: $OutDir)"
& lualatex -synctex=1 -interaction=nonstopmode -file-line-error -halt-on-error -output-directory=$OutDir $DiffTex
& biber --input-directory=$OutDir --output-directory=$OutDir --bblencoding=utf8 -u -U --output_safechars $JobName
& lualatex -synctex=1 -interaction=nonstopmode -file-line-error -halt-on-error -output-directory=$OutDir $DiffTex
& lualatex -synctex=1 -interaction=nonstopmode -file-line-error -halt-on-error -output-directory=$OutDir $DiffTex

Write-Host "Done: $OutDir\$JobName.pdf"
