# テストディレクトリの使い方

このディレクトリでは，LaTeXを用いたドキュメント作成のサンプルコードを提供しています．`main.tex`を中心に，プロジェクトの構成やビルド方法について説明します．

## ファイル構成

- **main.tex**：メインのLaTeXソースファイル。ドキュメント全体の構成を定義します．
- **jlisting.sty**：付録のソースコード出力用スタイルファイル
- **jtygm.sty**：Warning対策
- **listings.sty**：付録のソースコード出力用スタイルファイル
- **lab_thesis.cls**：研究室用の論文クラスファイル
- **preambles**：プリアンブル設定をまとめたディレクトリ．
  - **preamble.tex**：パッケージやコマンドの定義が含まれるファイル．
  - **numerical_formulas.tex**：数式用のコマンド定義が含まれるファイル．
- **documents/**：各章の内容を含むディレクトリ。任意の本文ファイルを追加．
- **images/**：図表を保存するディレクトリ．
- **references**：参考文献リストを含むディレクトリ．
  - **references_1.bib**
- **source_codes**：付録のソースコードを出力する設定ファイルとソースコードを含むディレクトリ．
  - **sourcecode_output_settings.tex**：ソースコードを付録に出力する際の設定ファイル．

## 使い方

### 1. 環境の準備

- **LaTeXディストリビューション**：TeX LiveやMiKTeXなどをインストールしてください．
- **必要なパッケージ**：以下のパッケージが必要です。インストールされていない場合は追加してください．
  - `amsmath`
  - `graphicx`
  - `hyperref`
  - その他，`preamble.tex`に記載のパッケージ
- 付録のソースコード出力に関する準備
1. `jlisting.sty` を C:\texlive\texmf-local\tex\latex\local\listings に置く（listingsディレクトリがなければ作成）．
2. コマンドプロンプトを管理者モードで開き`mktexlsr`と入力し実行．

### 2. コンテンツの編集

- **章の追加・編集**：
  - `documents/`ディレクトリ内の`.tex`ファイルを編集します．
  - 新しい章を追加する場合は，新しい`.tex`ファイルを作成し，`main.tex`で`\include{./documents/your_chapter}`を追加します．
- **図の挿入**：
  - 画像ファイルを`images/`ディレクトリに保存します．
  - 本文中で`\includegraphics{./images/your_image}`を使用して挿入します．
- **参考文献の追加**：
  - `references/`ディレクトリの`reference_1.bib`にBibTeX形式で文献情報を追加します．
  - 本文中で`\cite{your_reference_key}`を使用して引用します．

### 3. プリアンブルのカスタマイズ

`preamble.tex`ファイルで，以下の設定を行えます．

- **パッケージの追加**：必要なパッケージを`\usepackage{}`で追加します．
- **コマンドの定義**：`\newcommand{}`や`\renewcommand{}`でカスタムコマンドを定義します．

## 注意事項

- **コンパイルエラーの対処**：エラーが発生した場合，ログファイル（`.log`）を確認して原因を特定してください．
- **パスの確認**：ファイルや画像のパスが正しいか確認してください．
- **文字コード**：ソースファイルの文字コードはUTF-8を推奨します．

## ライセンス

このプロジェクトはMITライセンスのもとで公開されています．詳細は[LICENSE](../LICENSE)ファイルを参照してください．

## 問い合わせ

質問や提案がありましたら，リポジトリの[Issueセクション](https://github.com/yuki2023-kenkyu/latex_templates/issues)までご連絡ください．