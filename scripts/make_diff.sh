#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./scripts/make_diff.sh [ROOT_TEX=main.tex] [BASE_REF=HEAD~1] [HEAD_REF=HEAD]
#
# Optional environment variables (recommended defaults are shown):
#   LTXDIFF_STYLE="ja-color"            # ja-color | ja-underline | ja-uline | cfont | underline
#   LTXDIFF_MATH_MARKUP="coarse"        # off|whole|coarse|fine (or 0..3)
#   LTXDIFF_GRAPHICS_MARKUP="new-only"  # none|new-only|both
#   LTXDIFF_DISABLE_CITATION_MARKUP="auto" # auto|true|false (auto enables for underline styles)
#   LTXDIFF_CLEANUP_MODE="pdf+changed"  # none|pdf-only|pdf+changed
#
# Examples:
#   ./scripts/make_diff.sh                      # HEAD~1 vs HEAD (committed)
#   ./scripts/make_diff.sh main.tex main HEAD   # main vs HEAD
#   ./scripts/make_diff.sh main.tex main        # main vs working tree (uncommitted changes)
#
# Requirements (macOS/Linux):
#   - git
#   - latexdiff-vc (TeX Live "latexdiff" package; it uses latexpand for --flatten)
#   - lualatex, biber
#   - python3

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
CLEANUP_MODE="${LTXDIFF_CLEANUP_MODE:-pdf+changed}"

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


# --- reviewer-friendly summary inside the diff PDF ---
DIFF_ROOT_BASENAME="$(basename "${ROOT_TEX}")"

CHANGED_LIST_FILE="diff/.changed_files.txt"
: > "${CHANGED_LIST_FILE}"
if [[ "$COMPARE_WORKTREE" == "true" ]]; then
  git diff --name-only "${BASE_REF}" -- >> "${CHANGED_LIST_FILE}" || true
  git ls-files --others --exclude-standard >> "${CHANGED_LIST_FILE}" || true
  HEAD_LABEL="working tree"
else
  git diff --name-only "${BASE_REF}" "${HEAD_REF}" -- >> "${CHANGED_LIST_FILE}" || true
  HEAD_LABEL="${HEAD_REF}"
fi

export BASE_REF HEAD_REF HEAD_LABEL COMPARE_WORKTREE DIFF_ROOT_BASENAME

python3 - <<'PY'
import os, re, subprocess
from pathlib import Path
from collections import defaultdict

def esc(s: str) -> str:
    s = s.replace("\\", "/")
    s = re.sub(r'([#\$%&_{}])', r'\\\1', s)
    s = s.replace("^", r"\textasciicircum{}")
    s = s.replace("~", r"\textasciitilde{}")
    return s

base_ref = os.environ.get("BASE_REF", "")
head_ref = os.environ.get("HEAD_REF", "")
head_label = os.environ.get("HEAD_LABEL", "")
compare_worktree = (os.environ.get("COMPARE_WORKTREE", "false").lower() == "true")
diff_root = os.environ["DIFF_ROOT_BASENAME"]

# --- changed files (grouped) ---
changed = [l.strip() for l in Path("diff/.changed_files.txt").read_text(encoding="utf-8", errors="ignore").splitlines() if l.strip()]
seen = set()
uniq = []
for p in changed:
    key = p.lower().replace("\\", "/")
    if key not in seen:
        seen.add(key)
        uniq.append(p)

tex, bib, img, other = [], [], [], []
for p in uniq:
    ext = Path(p).suffix.lower()
    if ext == ".tex":
        tex.append(p)
    elif ext in {".bib", ".bbx", ".cbx", ".bst"}:
        bib.append(p)
    elif ext in {".pdf", ".png", ".jpg", ".jpeg", ".eps", ".svg", ".webp"}:
        img.append(p)
    else:
        other.append(p)

# --- contributors (git log) ---
contributors = []  # list of (author, commit_count, sorted_files)
if not compare_worktree:
    try:
        proc = subprocess.run(
            ["git", "log", "--no-merges", "--name-only", f"{base_ref}..{head_ref}", "--pretty=format:@@@%an"],
            check=False,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        author = None
        data = defaultdict(lambda: {"commits": 0, "files": set()})
        for line in proc.stdout.splitlines():
            s = line.rstrip("\n")
            if s.startswith("@@@"): 
                author = s[3:].strip() or "(unknown)"
                data[author]["commits"] += 1
                continue
            s = s.strip()
            if s and author:
                data[author]["files"].add(s)

        contributors = sorted(
            [(a, v["commits"], sorted(v["files"])) for a, v in data.items()],
            key=lambda t: (-t[1], t[0]),
        )
    except Exception:
        contributors = []

lines = []
lines.append("% Auto-generated by scripts/make_diff.sh")
lines.append(r"\begingroup")
lines.append(r"\ifdefined\chapter\chapter*{Changes in this diff}\else\section*{Changes in this diff}\fi")
lines.append(r"\noindent\texttt{Base: " + esc(base_ref) + r"}\\")
lines.append(r"\texttt{Head: " + esc(head_label) + r"}")

lines.append(r"\par\medskip")
lines.append(r"\noindent\textbf{Changed files (grouped):}")
lines.append(r"\begin{itemize}")

def add_group(title, items):
    if not items:
        return
    lines.append(r"  \item \textbf{" + title + "}")
    lines.append(r"  \begin{itemize}")
    for it in items:
        lines.append(r"    \item \texttt{" + esc(it) + "}")
    lines.append(r"  \end{itemize}")

add_group("TeX sources", tex)
add_group("Bibliography / styles", bib)
add_group("Images / figures", img)
add_group("Other files", other)
if not (tex or bib or img or other):
    lines.append(r"  \item (No changed files detected by git diff)")
lines.append(r"\end{itemize}")

lines.append(r"\par\medskip")
lines.append(r"\noindent\textbf{Contributors (git log):}")
lines.append(r"\begin{itemize}")
if compare_worktree:
    lines.append(r"  \item \textit{(Contributor attribution is unavailable for working tree diffs.)}")
elif not contributors:
    lines.append(r"  \item \textit{(No commits found in this range, or contributor summary unavailable.)}")
else:
    for author, n_commits, files in contributors:
        lines.append(r"  \item \textbf{" + esc(author) + r"} (\texttt{" + str(int(n_commits)) + r"} commits)")
        if files:
            lines.append(r"  \begin{itemize}")
            for f in files:
                lines.append(r"    \item \texttt{" + esc(f) + "}")
            lines.append(r"  \end{itemize}")
lines.append(r"\end{itemize}")

lines.append(r"\endgroup")
lines.append("")

Path("diff/change_summary.tex").write_text("\n".join(lines), encoding="utf-8")

# Insert into diff root tex after \begin{document}
root_path = Path("diff") / diff_root
tex_src = root_path.read_text(encoding="utf-8", errors="ignore")
if re.search(r"\\input\{change_summary\.tex\}", tex_src):
    # already inserted (e.g. rerun)
    raise SystemExit(0)

m = re.search(r"\\begin\{document\}", tex_src)
if not m:
    raise SystemExit("Could not find \\begin{document} in diff root tex")

ins = "\\input{change_summary.tex}\n\\clearpage\n"
tex_out = tex_src[:m.end()] + "\n" + ins + tex_src[m.end():]
root_path.write_text(tex_out, encoding="utf-8")
PY

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

# --- cleanup (optional) ---
case "${CLEANUP_MODE}" in
  none)
    ;;
  pdf-only|pdf+changed)
    tmpdir="$(mktemp -d)"
    # keep PDF
    if [[ -f "${OUTDIR}/${JOBNAME}.pdf" ]]; then
      cp "${OUTDIR}/${JOBNAME}.pdf" "${tmpdir}/" || true
    fi
    if [[ "${CLEANUP_MODE}" == "pdf+changed" ]]; then
      [[ -f diff/change_summary.tex ]] && cp diff/change_summary.tex "${tmpdir}/" || true
      [[ -f diff/.changed_files.txt ]] && cp diff/.changed_files.txt "${tmpdir}/" || true
      [[ -f "diff/$(basename "${ROOT_TEX}")" ]] && cp "diff/$(basename "${ROOT_TEX}")" "${tmpdir}/" || true
    fi

    rm -rf diff
    mkdir -p diff/out

    [[ -f "${tmpdir}/${JOBNAME}.pdf" ]] && mv "${tmpdir}/${JOBNAME}.pdf" diff/out/ || true
    if [[ "${CLEANUP_MODE}" == "pdf+changed" ]]; then
      [[ -f "${tmpdir}/change_summary.tex" ]] && mv "${tmpdir}/change_summary.tex" diff/ || true
      [[ -f "${tmpdir}/.changed_files.txt" ]] && mv "${tmpdir}/.changed_files.txt" diff/ || true
      rootleaf="$(basename "${ROOT_TEX}")"
      [[ -f "${tmpdir}/${rootleaf}" ]] && mv "${tmpdir}/${rootleaf}" diff/ || true
    fi

    rm -rf "${tmpdir}"
    ;;
  *)
    echo "Unknown LTXDIFF_CLEANUP_MODE: ${CLEANUP_MODE} (expected: none | pdf-only | pdf+changed)" >&2
    exit 2
    ;;
esac
