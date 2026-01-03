#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./scripts/make_diff.sh [ROOT_TEX=main.tex] [BASE_REF=HEAD~1] [HEAD_REF=HEAD]
#
# Optional environment variables (recommended defaults are shown):
#   LTXDIFF_STYLE="ja-color"        # ja-color | ja-underline | ja-uline | cfont | underline
#   LTXDIFF_MATH_MARKUP="coarse"    # off|whole|coarse|fine (or 0..3)
#   LTXDIFF_GRAPHICS_MARKUP="new-only"  # none|new-only|both
#   LTXDIFF_DISABLE_CITATION_MARKUP="auto" # auto|true|false (auto enables for underline styles)
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

# --- latexdiff style selection (Japanese-friendly default) ---
STYLE="${LTXDIFF_STYLE:-ja-color}"
MATH_MARKUP="${LTXDIFF_MATH_MARKUP:-coarse}"
GRAPHICS_MARKUP="${LTXDIFF_GRAPHICS_MARKUP:-new-only}"
DISABLE_CITATION_MARKUP="${LTXDIFF_DISABLE_CITATION_MARKUP:-auto}"

DIFF_OPTS=("--encoding=utf8" "--math-markup=${MATH_MARKUP}" "--graphics-markup=${GRAPHICS_MARKUP}")

case "$STYLE" in
  ja-color)
    DIFF_OPTS+=("--preamble=preambles/latexdiff_preamble_ja_color.ltxdiff")
    ;;
  ja-underline)
    DIFF_OPTS+=("--preamble=preambles/latexdiff_preamble_ja_underline.ltxdiff")
    ;;
  ja-uline)
    DIFF_OPTS+=("--preamble=preambles/latexdiff_preamble_ja_uline.ltxdiff")
    ;;
  cfont)
    DIFF_OPTS+=("--type=CFONT")
    ;;
  underline)
    DIFF_OPTS+=("--type=UNDERLINE")
    ;;
  *)
    echo "Unknown LTXDIFF_STYLE: ${STYLE} (expected: ja-color | ja-underline | ja-uline | cfont | underline)" >&2
    exit 2
    ;;
esac

if [[ "$DISABLE_CITATION_MARKUP" == "true" ]]; then
  DIFF_OPTS+=("--disable-citation-markup")
elif [[ "$DISABLE_CITATION_MARKUP" == "auto" ]]; then
  if [[ "$STYLE" == "underline" || "$STYLE" == "ja-underline" ]]; then
    DIFF_OPTS+=("--disable-citation-markup")
  fi
fi

if [[ "$COMPARE_WORKTREE" == "true" ]]; then
  echo "Generating diff: ${BASE_REF} -> working tree (${ROOT_TEX})"
  latexdiff-vc "${DIFF_OPTS[@]}" --git --flatten --force -d diff -r "${BASE_REF}" "${ROOT_TEX}"
else
  echo "Generating diff: ${BASE_REF} -> ${HEAD_REF} (${ROOT_TEX})"
  latexdiff-vc "${DIFF_OPTS[@]}" --git --flatten --force -d diff -r "${BASE_REF}" -r "${HEAD_REF}" "${ROOT_TEX}"
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
