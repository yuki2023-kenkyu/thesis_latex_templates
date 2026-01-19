# 査読・レビュー用運用（checkstyle + latexdiff）

このテンプレートでは、レビュー用途を **2 系統**に分けて扱います。

1. **changes（手動トラック）**: 追加・削除・置換・コメントを本文中に明示して、著者（レビュー担当）ごとに色分け。
2. **latexdiff-vc（git 差分）**: `origin/main` と `HEAD` など **git の2つの参照**の差分から、差分PDFを自動生成。

両者は役割が異なります。
- latexdiff: 「実際に何が変わったか」を機械的に可視化（PRレビュー向き）
- changes: 「どんな意図の修正か」「どこを直したいか」を手動で注釈（共同執筆・レビュー対応向き）

---

## 1. draft / final の切替

`japanese_thesis` クラスに `draft` を渡すと、`preambles/checkstyle.sty` が **changes と色付きコメント**を有効化します。

```tex
\documentclass[draft]{japanese_thesis} % レビュー用（changes・コメント表示ON）
% \documentclass[final]{japanese_thesis} % 提出用（changes・コメント表示OFF）
```

- `draft`: 変更マークアップ（[+]/[-] 等）とコメント環境が表示されます。
- `final`: 表示は抑制されます（コマンドは残るため、消し忘れてもPDFに出ません）。

> 注意: changes の変更一覧（\listofchanges）は draft で変更がある場合に末尾へ自動出力します。
> 不要なら本文プリアンブルで `\checkstyleAutoListfalse` を宣言してください。

---

## 2. 著者（レビュー担当）IDの定義

`preambles/checkstyle_authors.sty` を編集して、changes の著者IDを定義します。

```tex
% preambles/checkstyle_authors.sty
\CheckstyleDefineAuthor{HK}{Hashimoto}{RoyalBlue}
\CheckstyleDefineAuthor{AD}{Advisor}{ForestGreen}
\CheckstyleDefineAuthor{RV}{Reviewer}{BrickRed}
```

- **ID**: 本文で `\Added[ID]{...}` のように使う短い識別子
- **表示名**: PDF上に出る名前
- **色**: `xcolor` の色名（`dvipsnames` 有効）

運用のコツ:
- IDは「git contributor の表示名（あるいは役割）」に対応するものに揃える
- 共同執筆で ID を固定し、論文中で一貫して使う

---

## 3. changes（手動トラック）の書き方

checkstyle が提供するラッパーコマンド（推奨）:

```tex
\Added[HK]{追加したい文章}
\Deleted[HK]{削除したい文章}
\Replaced[AD]{新しい表現}{古い表現}
\Highlighted[RV]{ここは要確認}
\ChangeComment[AD]{この段落の構成を再検討}
```

- 追加: **[+]** が付く
- 削除: **[-]** が付く
- 置換: **[~]** が付く（新しい表現側）

### 色付きコメント環境（review / note / todo）

```tex
\begin{review}
この節の論旨が弱いので、関連研究の段落を先に移動したい。
\end{review}

\begin{note}
図2のキャプションはPRDのスタイルに合わせる。
\end{note}

\begin{cstodo}
導入の最後に貢献（新規性）を箇条書きで追加。
\end{cstodo}
```

- `todo` は、既に他パッケージ（todonotes 等）で衝突しやすいため、常に `cstodo` を使う運用を推奨します。

---

## 4. git 差分PDF（latexdiff）を作る

### 4.1 VS Code から実行（推奨）

本テンプレートは、既存の LaTeX Workshop recipe（`.vscode/settings.json`）を **一切変更せず**、差分PDF生成だけを VS Code の Task として追加できます。

- 追加ファイル: `.vscode/tasks.json`
- 実行: `Terminal: Run Task` → 次のいずれかを選択
  - `Diff PDF + open: origin/main -> HEAD`
  - `Diff PDF + open: baseRef -> working tree`

実行時に `BaseRef / HeadRef / Style / CleanupMode` を入力（選択）できるようにしています。

生成物:
- 差分PDF: `diff/out/main.pdf`

### 4.2 直接コマンドで実行（CLI）

#### 前提
- `git`
- `latexdiff-vc`（`latexdiff` パッケージ。`--flatten` のために `latexpand` を要求）
- `lualatex`, `biber`
- （macOS/Linux のみ）`python3`

#### Linux / macOS

```bash
# origin/main -> HEAD（コミット同士の比較）
LTXDIFF_STYLE=ja-underline LTXDIFF_CLEANUP_MODE=pdf-only   ./scripts/make_diff.sh main.tex origin/main HEAD

# origin/main -> working tree（未コミット差分を含める）
LTXDIFF_STYLE=ja-underline LTXDIFF_CLEANUP_MODE=pdf-only   ./scripts/make_diff.sh main.tex origin/main
```

指定可能なスタイル（`LTXDIFF_STYLE`）:
- `ja-color` / `ja-underline` / `ja-uline` / `underline` / `cfont`

指定可能なクリーンアップ（`LTXDIFF_CLEANUP_MODE`）:
- `pdf+changed` / `pdf-only` / `none`

#### Windows（PowerShell）

```powershell
# origin/main -> HEAD（コミット同士の比較）
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\make_diff.ps1 `
  -RootTex main.tex -BaseRef origin/main -HeadRef HEAD `
  -Style ja-underline -CleanupMode pdf-only

# origin/main -> working tree（未コミット差分を含める）
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\make_diff.ps1 `
  -RootTex main.tex -BaseRef origin/main -CompareWorktree `
  -Style ja-underline -CleanupMode pdf-only
```

指定可能なスタイル（`-Style`）:
- `ja-color` / `ja-underline` / `ja-uline` / `underline` / `cfont`

指定可能なクリーンアップ（`-CleanupMode`）:
- `pdf+changed` / `pdf-only` / `none`

## 5. 差分PDFの冒頭に出る情報

スクリプトは `diff/change_summary.tex` を自動生成し、差分PDF冒頭に挿入します。
ここには以下が含まれます。

- **Changed files (grouped)**: `git diff --name-only` に基づく変更ファイル一覧（TeX / bib / images / otherでグルーピング）
- **Contributors (git log)**: `git log base..head --name-only` の集計に基づく contributor サマリ（コミット数・ファイル数・ファイル一覧）

> 制限:
> latexdiff は基本的に「2つの版の差分」を示すため、**行ごとに contributor を色分け**する用途には向きません。
> その代替として、本テンプレートは「差分範囲に含まれる contributor の集計」を冒頭に出します。

---

## 6. 推奨ワークフロー

1. **レビュー作業前**: `\documentclass[draft]{japanese_thesis}` で changes を使い、修正意図を明示。
2. **PRレビュー**: `make_diff.(sh|ps1)` で差分PDFを生成し、差分（latexdiff）と意図（changes）を同時に確認。
3. **提出前**: `final` に切替、もしくは draft のままでも changes の出力は抑制されることを確認。

---

## 7. FAQ

### Q1. `\listofchanges` を自動で出したくない
本文プリアンブルで以下を追加:

```tex
\checkstyleAutoListfalse
```

### Q2. 色名が効かない
`checkstyle.sty` は `xcolor[dvipsnames]` を読み込むため、基本的な `dvipsnames` の色は利用できます。
それ以外の色モデル（RGB指定など）を使う場合は、`\CheckstyleDefineAuthor{ID}{Name}{[rgb]{...}}` のような指定は避け、xcolor の標準的な色名を使う運用を推奨します。

### Q3. 図・見出しで changes が崩れる
`changes` は、見出し・キャプション等の「移動引数」や特殊なマクロ内で不安定になりがちです。
その場合は changes を使わず、`review`/`note` でコメントを置くか、本文側に変更を逃がしてください。
