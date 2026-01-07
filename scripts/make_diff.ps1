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
  powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\make_diff.ps1 -RootTex main.tex -BaseRef origin/main -HeadRef HEAD
  powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\make_diff.ps1 -RootTex main.tex -BaseRef HEAD~1 -CompareWorktree
  powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\make_diff.ps1 -CleanupMode none
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
  [ValidateSet("none","project","all")]
  [string]$InputBoundaries = "project",

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

function New-StringHashSet {
  # PowerShell 5.1 で確実に generic HashSet を生成できる表記
  return New-Object 'System.Collections.Generic.HashSet`1[System.String]' ([System.StringComparer]::OrdinalIgnoreCase)
}

function Convert-ToStringHashSet($value) {
  # 既に HashSet[string] ならそのまま
  if ($value -is [System.Collections.Generic.HashSet[string]]) { return $value }

  $set = New-StringHashSet
  if ($null -eq $value) { return $set }

  # 文字列1本/配列/複合でも列挙して詰める
  foreach ($v in @($value)) {
    $n = Normalize-RelPath ([string]$v)
    if ($n) { [void]$set.Add($n) }
  }
  return $set
}

function Get-ChangedPathsSafe([string]$baseRef, [string]$headRef, [bool]$compareWorktree) {
  $set = New-StringHashSet
  try {
    if ($compareWorktree) {
      # baseRef vs working tree (tracked)
      $tracked = & git diff --name-only $baseRef --
      foreach ($p in $tracked) { $n = Normalize-RelPath $p; if ($n) { [void]$set.Add($n) } }

      # include untracked files as well (practical for review)
      $untracked = & git ls-files --others --exclude-standard
      foreach ($p in $untracked) { $n = Normalize-RelPath $p; if ($n) { [void]$set.Add($n) } }
    } else {
      $tracked = & git diff --name-only $baseRef $headRef --
      foreach ($p in $tracked) { $n = Normalize-RelPath $p; if ($n) { [void]$set.Add($n) } }
    }
  } catch {
    Write-Warning "Failed to get changed paths; fallback to keeping only PDF + diff root tex. Details: $($_.Exception.Message)"
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

  # ★重要: keepRelSet が文字列化されて渡ってきても必ず HashSet に正規化
  $keepRelSet = Convert-ToStringHashSet $keepRelSet

  Cleanup-OutDirKeepPdf -outDir $outDir -pdfPath $pdfPath

  # Always keep the diff root tex (it contains DIF markup)
  $rootNorm = Normalize-RelPath $rootTexRel
  if ($rootNorm) { [void]$keepRelSet.Add($rootNorm) }
  [void]$keepRelSet.Add((Normalize-RelPath "change_summary.tex"))

  $diffRoot = (Resolve-Path $diffDir).Path.TrimEnd('\')
  $prefix = $diffRoot + '\'
  $outPrefix = (Join-Path $diffDir "out") + '\'

  # Iterate all files under diffDir except out/
  Get-ChildItem -LiteralPath $diffDir -Force -Recurse -File | ForEach-Object {
    # Skip out directory
    if ($_.FullName.StartsWith($outPrefix, [System.StringComparison]::OrdinalIgnoreCase)) { return }

    $full = $_.FullName
    $rel = if ($full.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
      $full.Substring($prefix.Length)
    } else {
      $_.Name
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

function Escape-LatexText([string]$s) {
  if ($null -eq $s) { return "" }
  $t = $s -replace '\\','/'  # unify for display
  # Escape LaTeX special chars in file paths
  $t = $t -replace '([#\$%&_{}\^~])', '\\$1'
  # Handle caret/tilde more safely
  $t = $t -replace '\\\^', '\\textasciicircum{}'
  $t = $t -replace '\\~', '\\textasciitilde{}'
  return $t
}

function Get-ChangedPathsList([string]$baseRef, [string]$headRef, [bool]$compareWorktree) {
  $list = @()
  try {
    if ($compareWorktree) {
      $tracked = & git diff --name-only $baseRef --
      if ($tracked) { $list += $tracked }
      $untracked = & git ls-files --others --exclude-standard
      if ($untracked) { $list += $untracked }
    } else {
      $tracked = & git diff --name-only $baseRef $headRef --
      if ($tracked) { $list += $tracked }
    }
  } catch {
    Write-Warning "Failed to get changed path list for summary: $($_.Exception.Message)"
  }
  # unique while keeping order (case-insensitive)
  $seen = New-StringHashSet
  $out = @()
  foreach ($p in $list) {
    $n = Normalize-RelPath ([string]$p)
    if ($n -and -not $seen.Contains($n)) { [void]$seen.Add($n); $out += ([string]$p) }
  }
  return $out
}

function Write-ChangeSummaryTex([string]$diffDir, [string[]]$changedPaths, [string]$baseLabel, [string]$headLabel) {
  $dst = Join-Path $diffDir "change_summary.tex"

  $texChanged = @()
  $bibChanged = @()
  $imgChanged = @()
  $otherChanged = @()

  foreach ($p in $changedPaths) {
    $pp = ([string]$p).Trim()
    if ($pp.Length -eq 0) { continue }
    $ext = [System.IO.Path]::GetExtension($pp).ToLowerInvariant()
    if ($ext -eq ".tex") { $texChanged += $pp }
    elseif ($ext -eq ".bib" -or $ext -eq ".bbx" -or $ext -eq ".cbx") { $bibChanged += $pp }
    elseif ($ext -in @(".pdf",".png",".jpg",".jpeg",".eps",".svg")) { $imgChanged += $pp }
    else { $otherChanged += $pp }
  }

  $lines = @()
  $lines += "% Auto-generated by scripts/make_diff.ps1"
  $lines += "\begingroup"
  $lines += "\ifdefined\chapter\chapter*{Changes in this diff}\else\section*{Changes in this diff}\fi"
  $lines += "\noindent\texttt{Base: " + (Escape-LatexText $baseLabel) + "}\\"
  $lines += "\texttt{Head: " + (Escape-LatexText $headLabel) + "}"
  $lines += "\par\medskip"
  $lines += "\noindent\textbf{Changed files (grouped):}"
  $lines += "\begin{itemize}"

  function Add-Group([string]$title, [string[]]$items) {
    if ($items.Count -eq 0) { return }
    $lines += "  \item \textbf{$title}"
    $lines += "  \begin{itemize}"
    foreach ($it in $items) {
      $lines += "    \item \texttt{" + (Escape-LatexText $it) + "}"
    }
    $lines += "  \end{itemize}"
  }

  Add-Group "TeX sources" $texChanged
  Add-Group "Bibliography / styles" $bibChanged
  Add-Group "Images / figures" $imgChanged
  Add-Group "Other files" $otherChanged

  if ($texChanged.Count -eq 0 -and $bibChanged.Count -eq 0 -and $imgChanged.Count -eq 0 -and $otherChanged.Count -eq 0) {
    $lines += "  \item (No changed files detected by git diff)"
  }

  $lines += "\end{itemize}"
  $lines += "\endgroup"
  $lines += ""

  $content = ($lines -join "`n")
  [System.IO.File]::WriteAllText($dst, $content, [System.Text.Encoding]::UTF8)
  return $dst
}

function Insert-ChangeSummaryIntoRootTex([string]$rootTexPath) {
  if (!(Test-Path $rootTexPath)) { return }
  $txt = Get-Content -LiteralPath $rootTexPath -Raw -Encoding utf8
  $ins = "\input{change_summary.tex}`n\clearpage`n"
  $pattern = "\\begin\{document\}"
  if ($txt -match $pattern) {
    $txt2 = [regex]::Replace($txt, $pattern, "\begin{document}`n$ins", 1)
    Set-Content -LiteralPath $rootTexPath -Value $txt2 -Encoding utf8
  } else {
    Write-Warning "Could not find \begin{document} in diff root tex; change summary was not inserted."
  }
}

function Apply-InputBoundaryMarkers([string]$flatTexPath, [string]$scope) {
  if ($scope -eq "none") { return }
  if (!(Test-Path $flatTexPath)) { return }
  $txt = Get-Content -LiteralPath $flatTexPath -Raw -Encoding utf8
  $rx = [regex]'(?m)^\s*%+\s*start\s+input\s+(?<path>.+?)\s*$'
  $txt2 = $rx.Replace($txt, {
    param($m)
    $p = $m.Groups["path"].Value.Trim()
    $pNorm = Normalize-RelPath $p
    if ($scope -eq "project") {
      if ($pNorm -notmatch '^(?:\./)?(documents|tables|source_codes|references)/') {
        return $m.Value  # keep comment as-is
      }
    }
    $escaped = Escape-LatexText $p
    return "\DIFinput{$escaped}"
  })
  if ($txt2 -ne $txt) {
    Set-Content -LiteralPath $flatTexPath -Value $txt2 -Encoding utf8
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

  # Compute keep-set early (before we overwrite diff/)
  $keepSet = New-StringHashSet
  if ($CleanupMode -eq "pdf+changed") {
    $keepSet = Get-ChangedPathsSafe -baseRef $BaseRef -headRef $HeadRef -compareWorktree ([bool]$CompareWorktree)
    if ($null -eq $keepSet) { $keepSet = New-StringHashSet }
  }

  # For reviewer-friendly summary inside the diff PDF
  $changedList = Get-ChangedPathsList -baseRef $BaseRef -headRef $HeadRef -compareWorktree ([bool]$CompareWorktree)

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

  # Write change summary into diff/ so reviewers can see which split files changed
  $headLabel = if ($CompareWorktree) { "working tree" } else { $HeadRef }
  Write-ChangeSummaryTex -diffDir $DiffDir -changedPaths $changedList -baseLabel $BaseRef -headLabel $headLabel | Out-Null

  $BaseTex = Join-Path $TempBase $RootTex
  $HeadTex = Join-Path $TempHead $RootTex
  if (!(Test-Path $BaseTex)) { throw "Base tex not found: $BaseTex" }
  if (!(Test-Path $HeadTex)) { throw "Head tex not found: $HeadTex" }

  $BaseFlat = Join-Path $env:TEMP ("latexdiff-base-flat-{0}.tex" -f (Get-Random))
  $HeadFlat = Join-Path $env:TEMP ("latexdiff-head-flat-{0}.tex" -f (Get-Random))

  if ($HasLatexpand) {
    Write-Host "Flattening with latexpand (resolving \input relative to each exported tree)..."
    Push-Location $TempBase
    try {
      & latexpand --keep-comments --explain "$RootTex" | Out-File -FilePath $BaseFlat -Encoding utf8
      if ($LASTEXITCODE -ne 0) { throw "latexpand failed (base)" }
    } finally { Pop-Location | Out-Null }

    Push-Location $TempHead
    try {
      & latexpand --keep-comments --explain "$RootTex" | Out-File -FilePath $HeadFlat -Encoding utf8
      if ($LASTEXITCODE -ne 0) { throw "latexpand failed (head)" }
    } finally { Pop-Location | Out-Null }

    # Optionally show input-file boundaries inside the final PDF (useful for split files under documents/, tables/, etc.)
    Apply-InputBoundaryMarkers -flatTexPath $BaseFlat -scope $InputBoundaries
    Apply-InputBoundaryMarkers -flatTexPath $HeadFlat -scope $InputBoundaries
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

  # Insert a reviewer-friendly change summary near the beginning of the document
  Insert-ChangeSummaryIntoRootTex -rootTexPath $diffTexPath

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

# End of script
