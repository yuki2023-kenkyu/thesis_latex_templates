# thesis_templateの使い方

このディレクトリでは，$\LaTeX$を用いたドキュメント作成のサンプルコードを提供しています．`main.tex`を中心に，プロジェクトの構成やビルド方法について説明します．

## ファイル構成

- **main.tex**：メインの$\LaTeX$ソースファイル．ドキュメント全体の構成を定義．
- **japanese_thesis.cls**：研究室用の日本語論文クラスファイル．
- **bxjsreport_test.cls**：元のbxjsreportクラスファイル．
- **biblatex.cfg**：参考文献の出力形式を制御するbiblatex用の設定ファイル．
- **.vscode/**：vscodeの設定ファイルをまとめたディレクトリ．
  - **settings.json**：`thesis_template`内で適用される$\LaTeX$のコンパイルレシピ等の設定を記述した設定ファイル．
  - **extensions.json**：本パッケージを実行する上でインストールを推奨するvscodeの拡張機能をまとめた設定ファイル．
- **preambles/**：プリアンブル設定をまとめたディレクトリ．
  - **packages_lualatex.sty**：パッケージやコマンドの定義が含まれるスタイルファイル．
  - **macros.sty**：コマンド定義（自作マクロ）が含まれるスタイルファイル．
  - **biblatex-journal-style.sty**：ADSのbibtexファイルの独自コマンドを使えるよう定義したスタイルファイル．
  - **zref-settings.sty**：zref-cleverパッケージに関する設定用のスタイルファイル．
- **documents/**：各章の内容を含むディレクトリ．任意の本文ファイルを含む．
- **images/**：図表を保存するディレクトリ．
- **references/**：参考文献リストを含むディレクトリ．
  - **reference_1.bib**
- **source_codes/**：付録のソースコードを含むディレクトリ．
  - **source_code_1.py**：付録に出力するソースコードの元ファイル．

## 使い方

### 1. 環境の準備

- **LaTeXディストリビューション**：最新のTeX LiveやMiKTeXなどをインストールしてください．
- **必要なパッケージ**：以下のパッケージが必要です。インストールされていない場合は追加してください．
  - `amsmath`
  - `graphicx`
  - `hyperref`
  - その他，`./preambles/packages_lualatex.sty`に記載のパッケージ
- vscodeをインストールしてください．

### 2. 実行方法

以下の手順に従い`main.tex`を実行してください．

- 本パッケージのダウンロード・解凍
　- 本ディレクトリの親ディレクトリからzipファイルをダウンロードし，各々の適当なフォルダに本ディレクトリを解凍してください．
- インストールしたvscodeを開く．
- vscodeのワークスペースとして「フォルダを開く」で`latex_templates`内の`thesis_template_lualatex`を指定．
- 「おすすめの拡張機能」として表示される拡張機能をインストール
  - `.vscode/extensions.json`に記載の拡張機能が表示されます．
- `main.tex`の実行
  - vscodeの左側に表示されている拡張機能のメニューのうち，`TEX`を選択．
  - 一番上の`LaTeXプロジェクトビルド`を選択．
  - `レシピ:lualatex (biblatex+biber)`を選択して実行．

### 3. コンテンツの編集

- **章の追加・編集**：
  - `./documents/`ディレクトリ内の`.tex`ファイルを編集します．
  - 新しい章を追加する場合は，新しい`.tex`ファイルを作成し，`main.tex`で`\input{./documents/your_chapter}`を追加します．
- **自作マクロの追加**：
  - `./preambles/macros.sty`内に`\newcommand{}`を用いて論文中でよく用いるマクロを定義することができます．
- **図の挿入**：
  - 画像ファイルを`./images/`ディレクトリに保存します．
  - 本文中で`\includegraphics{./images/your_image}`を使用して挿入します．
- **ソースコードの挿入**：
  - `./source_codes/`ディレクトリに付録として出力したいソースコードを追加します．
  - `./documents/appendix.tex`中で`\lstinputlisting[caption = 使用した数値解析コード, label = program2]{./source_codes/your_source_codes_file}`コマンドのcaptionやlabel，引用したいソースコードのファイル名を書き換えます．
- **参考文献の追加**：
  - `./references/`ディレクトリの`reference_1.bib`にBibTeX形式で文献情報を追加します．
  - 本文中で`\cite{your_reference_key}`を使用して引用します．
  - 日本語文献の情報を挿入する場合，`reference_1.bib`に追加した文献情報フィールドの最後に`langid = {japanese}`を追記してください．また，authorフィールドは必ず`author = {姓, 名}`としてください．
- 新たに`.bib`ファイルを追加する際は`./references/`内に追加し，`main.tex`（必要に応じて `style_guide_updated.tex`）の`\addbibresource{...}`の近くに，`\addbibresource{./references/追加したファイル名.bib}`を追記してください．

### 4. プリアンブルのカスタマイズ

`./preambles/packages_lualatex.sty`ファイルで，以下の設定を行えます．

- **パッケージの追加**：必要なパッケージを`\usepackage{}`で追加します．
- **数式番号の出力形式の変更**：`\numberwithin{equation}{chapter}`部分を変更することにより数式番号の出力形式を変更できます．
- **図・表番号の出力形式の変更**：`\renewcommand{\thefigure}{\thechapter.\arabic{figure}}`部分を変更することにより図や表番号の出力形式を変更できます．

### 5. その他
- 本テンプレートは，従来の`siunitx`と`Physics`パッケージの競合を避けるため，`Physics2`パッケージを使用しています．
- パッケージを追加する場合は，`./preambles/packages_lualatex.sty`に記載のパッケージとの競合に注意してください．
- `cleveref`パッケージに関するエラーが相次いだため，新たに`zref-clever`を導入し，従来使用していたコマンド`\cref{}`が使えなくなりました．数式などの相互参照を行う場合は，`\zcref{}`を利用してください．また，範囲指定しての参照の場合は`range`オプションを利用し，`\zcref[range]{label:a, label:b}`等としてください．

## 注意事項

- **コンパイルエラーの対処**：エラーが発生した場合，ログファイル（`.log`）を確認して原因を特定してください．
- **パスの確認**：ファイルや画像のパスが正しいか確認してください．
- **文字コード**：ソースファイルの文字コードは必ずUTF-8にしてください．

---

## VSCodeビルド設定（重要）

本テンプレートは **biblatex + biber** を前提とし，**LuaLaTeXのみ**でビルドします。

- `.vscode/settings.json` では，生成物を `out/` に集約するために `latex-workshop.latex.outDir: "out"` を設定しています（OS共通）。
- 既定レシピは `lualatex (biblatex+biber)` です。

### `-shell-escape` が必要になるケース（minted等）

`-shell-escape` は，LaTeXコンパイル中に外部コマンド実行（\write18）を許可するオプションです。  
主に以下のようなパッケージ・機能で必要になります。

- `minted`（Pygmentsを呼び出すため）
- `gnuplottex` / `pythontex` 等（外部プログラム実行が前提）

本テンプレートは標準で `listings` を使うため **通常は不要**です。必要な場合のみ，
VSCodeのレシピ `lualatex + shell-escape (minted等)` に切り替えてください。

---

## Gitでのレビュー効率化（差分PDF）

TeX原稿レビューでは，テキスト差分に加えて **「差分PDF」** があると確認が格段に容易になります。

### ローカルで差分PDFを生成（latexdiff-vc）

- macOS/Linux: `./scripts/make_diff.sh`
- Windows(PowerShell): `./scripts/make_diff.ps1`

例（直近2コミット間）：

- macOS/Linux:
  - `./scripts/make_diff.sh main.tex HEAD~1 HEAD`
- Windows:
  - `powershell -ExecutionPolicy Bypass -File .\scripts\make_diff.ps1 -RootTex main.tex -BaseRef HEAD~1 -HeadRef HEAD`

生成物は `diff/out/main.pdf` に出力されます。

#### 差分表示スタイル（下線/色/日本語の崩れ対策）

TeX原稿（特に日本語）では、`ulem` による **下線/打消し（UNDERLINE系）** が原因で
行分割が不自然になったり、パッケージ相性でコンパイルが不安定になることがあります。

本リポジトリでは、次の5つを用意しています。

- `ja-color`（既定・推奨）: **色のみ**（`ulem`不使用、フォント切替なし）で最も安定
- `ja-underline`: 下線/打消し（`ulem`使用）。日本語で崩れる場合は `ja-color` に戻す
- `ja-uline`: 下線/打消し（`uline--`使用）。日本語の改行崩れ対策の選択肢（要インストール）
- `cfont`: latexdiff標準のCFONT（色+フォント切替）
- `underline`: latexdiff標準のUNDERLINE（`ulem`使用）

切り替えは環境変数で行います。

- macOS/Linux:
  - `LTXDIFF_STYLE=ja-color ./scripts/make_diff.sh`
  - `LTXDIFF_STYLE=ja-underline ./scripts/make_diff.sh`
  - `LTXDIFF_STYLE=ja-uline ./scripts/make_diff.sh`  （要 uline--）
- Windows:
  - `powershell -ExecutionPolicy Bypass -File .\scripts\make_diff.ps1 -Style ja-color`
  - `powershell -ExecutionPolicy Bypass -File .\scripts\make_diff.ps1 -Style ja-underline`
  - `powershell -ExecutionPolicy Bypass -File .\scripts\make_diff.ps1 -Style ja-uline`  （要 uline--）

追加で、以下も調整可能です。

- `LTXDIFF_MATH_MARKUP`（既定: `coarse`）: 数式差分が壊れる場合は `whole` や `off` を検討
- `LTXDIFF_GRAPHICS_MARKUP`（既定: `new-only`）: 図の強調が原因でエラーが出る場合は `none`
- `LTXDIFF_DISABLE_CITATION_MARKUP`（既定: `auto`）: UNDERLINE系のときに `\mbox` 保護を抑制

## PRの作成・レビュー手順（差分PDF自動生成）

本リポジトリでは，Pull Request（PR）作成時に GitHub Actions が **通常PDF** と **差分PDF（latexdiff）** を自動生成し，PR上でレビューできるようにしています．基本的には以下のフローで運用してください．

### 0. 前提（重要）

- **PRは原則「同一リポジトリ内ブランチ」から作成**してください（fork PR の場合，GitHub の権限制約により PR コメント投稿が無効になることがあります）．
- 追加・更新した **図（images/）・表（tables/）・参考文献（references/）等は必ずコミット**してください（Actions 側はリポジトリの内容だけでビルドします）．
- ソースの文字コードは **UTF-8** を前提とします（`.bib` も含む）．

### 1. ブランチ作成（作業開始）

1) main を最新化：
- `git switch main`
- `git pull`

2) 作業ブランチ作成（例）：
- `git switch -c feature/<内容が分かる名前>`

3) 編集（`documents/` 配下の章ファイル，`images/`，`tables/`，`references/` など）

### 2. ローカルでの事前確認（推奨）

レビューでの手戻りを減らすため，PRを出す前にローカルで最低限の確認を行ってください．

- VSCode：`レシピ:lualatex (biblatex+biber)` で `main.tex` が通ること
- 参考文献：`\cite{...}` が `biber` で解決できること（`biber` エラーがないこと）
- 図表：パスが正しく，意図した見た目であること

さらに，差分確認が必要な場合はローカルで差分PDFも生成できます．

- macOS/Linux: `./scripts/make_diff.sh`
- Windows(PowerShell): `./scripts/make_diff.ps1`

（例：直近2コミット間の差分）
- macOS/Linux: `./scripts/make_diff.sh main.tex HEAD~1 HEAD`
- Windows: `powershell -ExecutionPolicy Bypass -File .\scripts\make_diff.ps1 -RootTex main.tex -BaseRef HEAD~1 -HeadRef HEAD`

### 3. PRの作成

1) 変更をコミット：
- `git add -A`
- `git commit -m "（変更内容が分かるメッセージ）"`

2) ブランチを push：
- `git push -u origin feature/<内容が分かる名前>`

3) GitHub上で PR を作成し，PRテンプレート（Summary/Checklist など）を記入します．
可能であれば以下も書いてください．
- 何を変えたか（What changed）
- なぜ変えたか（Why）
- レビュー時に見てほしい観点（図表・参考文献・レイアウト等）

### 4. GitHub Actions / Artifacts の確認（ここがレビューの要点）

PR を作成すると，次のワークフローが走ります．

- **PR Review PDFs (build + latexdiff)**（`.github/workflows/pr-review-pdfs.yml`）

成功すると，Artifacts として次が生成されます．

- `pr-pdf`：通常ビルドPDF（例：`main.pdf`，`style_guide_updated.pdf`）
- `pr-diff-pdf`：差分PDF（latexdiff）

また，同一リポジトリ内ブランチの PR であれば，PR本文にボットコメントとして
**"Review PDFs (auto-generated)"** が投稿（または更新）され，Artifacts へのリンクが提示されます．

#### ボットコメントが出ない場合

- PR が **fork からの作成**：権限上，コメント投稿が無効になることがあります．（Artifacts 自体は Actions 画面から取得可能です）
- Actions が失敗している：PR の **Checks** タブや Actions のログを確認してください．

### 5. レビュー対応（更新の流れ）

レビューコメントや差分PDFの確認結果に応じて修正し，作業ブランチに追加コミットして push します．
push すると Actions が再実行され，Artifacts とボットコメントは自動更新されます．

### 6. よくある失敗と対処（Actions/latexdiff）

- **LaTeXコンパイルエラー**：まずログ（Actions のログ，またはローカルの `out/*.log` / `diff/out/*.log`）でエラー箇所を特定してください．
- **biberエラー**：`.bib` の文字コード（UTF-8），エントリキーの重複，必須フィールド不足を確認してください．
- **latexdiffで崩れる/落ちる**：
  - 日本語では下線系（`ulem`）が不安定になりがちです．本リポジトリの既定は **`ja-color`（色のみ）** です．
  - 数式差分が壊れる場合：`MathMarkup` を `fine`→`coarse` 等に変更して再生成してください（ローカルスクリプトで検証推奨）．
- **minted等で `-shell-escape` が必要**：VSCode のレシピを `shell-escape` 付きに切り替えるか，ローカルで該当オプションを付けてください．

### 7. 生成物をコミットしない（推奨）

ローカルビルドや差分生成で作られる `out/`，`diff/` などは原則コミットしない運用を推奨します．
（`.gitignore` で除外しています）

### GitHub Actions（PRごとに自動生成）

- `build-pdf.yml`（mainブランチpush時）: `main.tex` と `style_guide_updated.tex` をビルドしてPDFをArtifactとして保存
- `pr-review-pdfs.yml`（PR時）:
  - `main.tex` / `style_guide_updated.tex` をビルド
  - PRのbase/head間で `latexdiff-vc` により差分TeXを生成し，差分PDFをビルド
  - Artifactのダウンロードリンクを **PRコメントに自動投稿（既存コメントは更新）**

注意: PRがforkから作られた場合、権限の都合でPRコメント投稿が無効になることがあります。

---
## ライセンス

このプロジェクトはMITライセンスのもとで公開されています．詳細は[LICENSE](../LICENSE)ファイルを参照してください．

## 問い合わせ

質問や提案がありましたら，リポジトリの[Issueセクション](https://github.com/yuki2023-kenkyu/thesis_latex_templates/issues)までご連絡ください．

