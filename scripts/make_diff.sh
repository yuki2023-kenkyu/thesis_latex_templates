#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./scripts/make_diff.sh [ROOT_TEX=main.tex] [BASE_REF=HEAD~1] [HEAD_REF=HEAD]
#
# Examples:
#   ./scripts/make_diff.sh                      # HEAD~1 vs HEAD (committed)
#   ./scripts/make_diff.sh main.tex main HEAD   # main vs HEAD
#   ./scripts/make_diff.sh main.tex main        # main vs working tree (uncommitted changes)
#
# Requirements (macOS/Linux):
#   - git
#   - latexdiff-vc (TeX Live "latexdiff" package; on macOS with MacTeX it is usually available)
#   - lualatex, biber

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ROOT_TEX="${1:-main.tex}"
BASE_REF="${2:-HEAD~1}"
HEAD_REF="${3:-HEAD}"

# If the user provided BASE_REF only (2 args total), compare BASE_REF vs working tree
COMPARE_WORKTREE="false"
if [[ $# -eq 2 ]]; then
  COMPARE_WORKTREE="true"
fi

rm -rf diff
mkdir -p diff

if [[ "$COMPARE_WORKTREE" == "true" ]]; then
  echo "Generating diff: ${BASE_REF} -> working tree (${ROOT_TEX})"
  latexdiff-vc --git --flatten --force -d diff -r "${BASE_REF}" "${ROOT_TEX}"
else
  echo "Generating diff: ${BASE_REF} -> ${HEAD_REF} (${ROOT_TEX})"
  latexdiff-vc --git --flatten --force -d diff -r "${BASE_REF}" -r "${HEAD_REF}" "${ROOT_TEX}"
fi

DIFF_TEX="diff/$(basename "${ROOT_TEX}")"
JOBNAME="$(basename "${ROOT_TEX}" .tex)"
OUTDIR="diff/out"
mkdir -p "${OUTDIR}"

echo "Compiling ${DIFF_TEX} with LuaLaTeX + biber (output: ${OUTDIR}/)"
lualatex -synctex=1 -interaction=nonstopmode -file-line-error -halt-on-error -output-directory="${OUTDIR}" "${DIFF_TEX}"
biber --input-directory="${OUTDIR}" --output-directory="${OUTDIR}" --bblencoding=utf8 -u -U --output_safechars "${JOBNAME}"
lualatex -synctex=1 -interaction=nonstopmode -file-line-error -halt-on-error -output-directory="${OUTDIR}" "${DIFF_TEX}"
lualatex -synctex=1 -interaction=nonstopmode -file-line-error -halt-on-error -output-directory="${OUTDIR}" "${DIFF_TEX}"

echo "Done: ${OUTDIR}/${JOBNAME}.pdf"
