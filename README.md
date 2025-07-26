# thesis_templateの使い方

このディレクトリでは，$\LaTeX$を用いたドキュメント作成のサンプルコードを提供しています．`main.tex`を中心に，プロジェクトの構成やビルド方法について説明します．

## ファイル構成

- **main.tex**：メインの$\LaTeX$ソースファイル．ドキュメント全体の構成を定義．
- **japanese_thesis.cls**：研究室用の日本語論文クラスファイル．
- **bxjsreport_test.cls**：元のbxjsreportクラスファイル．
- **biblatex.cfg**：参考文献の出力形式を制御するbiblatex用の設定ファイル．
- **.vscode/**：vscodeの設定ファイルをまとめたディレクトリ．
  - **settings.json**：`thesis_template`内で適応される$\LaTeX$のコンパイルレシピ等の設定を記述した設定ファイル．
  - **extensions.json**：本パッケージを実行する上でインストールを推奨するvscodeの拡張機能をまとめた設定ファイル．
- **preambles/**：プリアンブル設定をまとめたディレクトリ．
  - **packages_lualatex.sty**：パッケージやコマンドの定義が含まれるスタイルファイル．
  - **macros.sty**：コマンド定義（自作マクロ）が含まれるスタイルファイル．
  - **biblatex-journal-style.sty**：ADSのbibtexファイルの独自コマンドを使えるよう定義したスタイルファイル．
  - **zref-settings.sty**：zref-cleverパッケージに関する設定用のスタイルファイル．
- **documents/**：各章の内容を含むディレクトリ。任意の本文ファイルを含む．
- **images/**：図表を保存するディレクトリ．
- **references/**：参考文献リストを含むディレクトリ．
  - **references_1.bib**
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
  - `レシピ:lualatex`を選択して実行．

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
  - 新たに`.bib`ファイルを追加する際は`./references/`内に追加し，`./preambles/packages_lualatex.sty`の`\addbibresource{./references/reference_1.bib}`のすぐ下に`\addbibresoiurce{./references/追加したファイルの名前.bib}`と追記してください．

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

## ライセンス

このプロジェクトはMITライセンスのもとで公開されています．詳細は[LICENSE](../LICENSE)ファイルを参照してください．

## 問い合わせ

質問や提案がありましたら，リポジトリの[Issueセクション](https://github.com/yuki2023-kenkyu/latex_templates/issues)までご連絡ください．
