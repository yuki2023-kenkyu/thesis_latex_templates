%% This is file `lab_thesis.cls',
%% based on `jbook.cls'
%% 福島大学馬塲研究室の論文用クラスファイル（jbookベース）
%% 作成者：Yuki Hashimoto

\NeedsTeXFormat{pLaTeX2e}[2023-02-14]
\ProvidesClass{lab_thesis}[2024/10/14 Bamba Lab Thesis Style class]
\epTeXinputencoding utf8

% カウンターやフラグの定義
\newcounter{paper}% 用紙サイズを管理するカウンター
\newif\if@lab@landscape          % 横向き設定のフラグ
\@lab@landscapefalse             % デフォルトは縦向き
\newcommand{\lab@ptsize}{}       % フォントサイズを管理するコマンド
\newif\if@lab@restonecol         % 一段組への戻りフラグ
\newif\if@lab@titlepage          % タイトルページの有無フラグ
\@lab@titlepagetrue              % デフォルトでタイトルページあり
\newif\if@lab@openright          % 章の開始ページを右側にするかのフラグ

% 用紙サイズのオプションを宣言
\DeclareOption{a4paper}{\setcounter{paper}{1}%
  \setlength\paperheight {297mm}%
  \setlength\paperwidth  {210mm}}
% 他の用紙サイズも同様に定義
\DeclareOption{a5paper}{\setcounter{paper}{2}%
  \setlength\paperheight {210mm}%
  \setlength\paperwidth  {148mm}}
\DeclareOption{b4paper}{\setcounter{paper}{3}%
  \setlength\paperheight {364mm}%
  \setlength\paperwidth  {257mm}}
\DeclareOption{b5paper}{\setcounter{paper}{4}%
  \setlength\paperheight {257mm}%
  \setlength\paperwidth  {182mm}}

% フォントサイズのオプションを宣言
\DeclareOption{10pt}{\renewcommand{\lab@ptsize}{0}} % 10ptの場合
\DeclareOption{11pt}{\renewcommand{\lab@ptsize}{1}} % 11ptの場合
\DeclareOption{12pt}{\renewcommand{\lab@ptsize}{2}} % 12ptの場合

% その他のオプションを宣言
\DeclareOption{oneside}{\@twosidefalse}    % 片面印刷
\DeclareOption{twoside}{\@twosidetrue}     % 両面印刷
\DeclareOption{openright}{\@lab@openrighttrue} % 章を右側から開始
\DeclareOption{openany}{\@lab@openrightfalse}  % 章を任意のページから開始
\DeclareOption{landscape}{%                % 横向き設定
  \@lab@landscapetrue
  \setlength\@tempdima{\paperheight}%
  \setlength\paperheight{\paperwidth}%
  \setlength\paperwidth{\@tempdima}}

% デフォルトオプションを実行
\ExecuteOptions{a4paper,10pt,oneside,onecolumn,final,openany}
\ProcessOptions\relax  % オプションを処理

% ベースとなるクラスファイルを読み込み（jbookに変更）
\LoadClass{jbook}  % jbookから継承

% フォントサイズ設定ファイルを読み込み
\ifcase\lab@ptsize
  \def\lab@size{10}
\or
  \def\lab@size{11}
\or
  \def\lab@size{12}
\fi
\input{jsize\lab@size.clo} % フォントサイズに応じた設定

% ページレイアウトの調整
\setlength{\topmargin}{0.3cm}      % 上マージンの設定
\setlength{\headsep}{5mm}          % ヘッダーと本文の間隔
\setlength{\oddsidemargin}{0.6cm}  % 奇数ページ左マージン
\setlength{\evensidemargin}{0.6cm} % 偶数ページ左マージン
\setlength{\textheight}{23.3cm}    % テキスト高さ
\setlength{\textwidth}{14.8cm}     % テキスト幅

% ページスタイルの設定
\pagestyle{plain}    % ページ番号のみを表示するスタイル
\setlength{\parindent}{1zw} % 段落の字下げを全角1文字分

% 脚注番号を記号に変更
\renewcommand{\thefootnote}{\fnsymbol{footnote}}

% タイトル情報を保存するためのマクロ定義
\def\Title#1{\gdef\Titlebox{#1}}        % タイトル
\def\@Title{\@ifundefined{Titlebox}{{What title is this ?}}{\Titlebox}}

\def\Author#1{\gdef\Authorbox{#1}}      % 著者名
\def\@Author{\@ifundefined{Authorbox}{{Who are you ?}}{\Authorbox}}

\def\Professor#1{\gdef\Professorbox{#1}} % 指導教員名
\def\@Professor{\@ifundefined{Professorbox}{{Who are you ?}}{\Professorbox}}

\def\StudentNumber#1{\gdef\StudentNumberbox{#1}} % 学籍番号
\def\@StudentNumber{\@ifundefined{StudentNumberbox}{{Who are you ?}}{\StudentNumberbox}}

% 均等割り付けを行うコマンドの定義
\def\kintou#1#2{%
  \makebox[#1]{\kanjiskip=0pt plus 1fill minus 1fill%
    \xkanjiskip=\kanjiskip#2}}

% 年度を設定するコマンドの定義
\def\Date#1{\gdef\Datebox{令和#1年度}}
\def\@Date{\@ifundefined{Datebox}{{What day is today ?}}{\Datebox}}

% 論文種別のフラグ設定
\def\master{\gdef\@master{}}   % 修士論文の場合
\def\doctor{\gdef\@doctor{}}   % 博士論文の場合

% 表紙を作成するコマンドの定義
\def\Maketitle{%
  \pagestyle{empty} % ページ番号を表示しない
  \begin{center}
    \vspace*{-.6cm}
    {\huge \kintou{8zw}{%
      \@ifundefined{@doctor}{%
        \@ifundefined{@master}{卒業論文}{修士論文}%
      }{博士論文}}%
    \par}
    \vspace{.6cm}
     % タイトルを大きく太字で表示
    \vtop to 4.5cm {\hsize=\textwidth
      \begin{center}
        \vfil
        {\Huge \bf \@Title \par}
        \vfil
      \end{center}
    }
    \vspace{5.5cm}
    % 所属を出力
    {\LARGE \kintou{12zw}{福島大学}}\par
    \vspace{0.5cm}
    {\LARGE
      \@ifundefined{@doctor}{%
        \@ifundefined{@master}{%
          % 卒業論文の場合
        \kintou{12zw}{理工学群共生システム理工学類}\par
        \kintou{12zw}{物理・システム工学コース}\par
        }{%
          % 修士論文の場合
        \kintou{12zw}{大学院共生システム理工学研究科}\par
        \kintou{12zw}{共生システム理工学専攻}\par
        %\kintou{12zw}{物理・メカトロニクス分野}\par
        }%
      }{%
        % 博士論文の場合
        \kintou{12zw}{大学院共生システム理工学研究科}\par
        \kintou{12zw}{共生システム理工学専攻}\par
        %\kintou{12zw}{共生数理システム領域}\par
      }%
    }%
    \vspace{1cm}
    {\huge \kintou{7zw}{\textbf{学籍番号：\@StudentNumber}}}\par % 学籍番号（太字）
    \vspace{0.5cm}
    {\huge \kintou{7zw}{\textbf{氏　　名：\@Author}}}\par        % 氏名（太字）
    \vspace{0.5cm}
    {\huge \kintou{7zw}{指導教員：\@Professor}}\par     % 指導教員名
    \vspace{2.5cm}
    {\LARGE \kintou{11zw}{\@Date}}\par                 % 年度
  \end{center}
  \newpage % 新しいページへ
}

% 日本語名の再定義
\renewcommand{\prechaptername}{第}
\renewcommand{\postchaptername}{章}
\renewcommand{\contentsname}{目 次}
\renewcommand{\listfigurename}{図 目 次}
\renewcommand{\listtablename}{表 目 次}
\renewcommand{\bibname}{参考文献}
\renewcommand{\indexname}{索 引}
\renewcommand{\figurename}{図}
\renewcommand{\tablename}{表}
\renewcommand{\appendixname}{付 録}

% 章タイトルサイズの調整コマンド
\def\chaptersize#1{\gdef\@chapsize{#1}}

% 章のスタイルを再定義
\renewcommand{\chapter}{%
  \if@lab@openright\cleardoublepage\else\clearpage\fi % 章を右から開始
  \thispagestyle{plain} % このページのスタイルをplainに
  \global\@topnum\z@    % ページ上部に図や表が来ないように
  \@afterindenttrue     % 次の段落で字下げを行う
  \secdef\@lab@chapter\@lab@schapter % 番号付き・なしの章の処理
}

% 章のタイトル出力を再定義
\def\@lab@chapter[#1]#2{%
  \ifnum \c@secnumdepth >\m@ne
    \refstepcounter{chapter}%
    \addcontentsline{toc}{chapter}{%
      \protect\numberline{\prechaptername\thechapter\postchaptername}#1}%
  \else
    \addcontentsline{toc}{chapter}{#1}%
  \fi
  \chaptermark{#1}%
  \addtocontents{lof}{\protect\addvspace{10pt}}%
  \addtocontents{lot}{\protect\addvspace{10pt}}%
  \@makechapterhead{#2}%
  \@afterheading%
}

\def\@lab@schapter#1{%
  \@makeschapterhead{#1}%
  \@afterheading%
}

% 章タイトルのスタイルを再定義
\def\@makechapterhead#1{%
  \vspace*{20pt}%
  {\parindent \z@ \raggedright
    \interlinepenalty\@M
    \ifnum \c@secnumdepth >\m@ne %
      \chapnumfont{\prechaptername\thechapter\postchaptername}%
      \hskip 15pt % 章番号とタイトルの間にスペースを追加
    \fi
    \chaptitlefont{#1}\par
    \nobreak \vskip 15pt
  }}

% 章番号とタイトルのフォント設定
\newcommand{\chapnumfont}[1]{\Huge \bfseries #1}
\newcommand{\chaptitlefont}[1]{\Huge \bfseries #1}

% セクションのスタイルを再定義
\renewcommand{\section}{\@startsection{section}{1}{\z@}%
  {1.5\Cvs \@plus .5\Cvs \@minus .2\Cvs}%
  {.5\Cvs}%
  {\reset@font\Large\bfseries}}

\renewcommand{\subsection}{\@startsection{subsection}{2}{\z@}%
  {1.25\Cvs \@plus .5\Cvs \@minus .2\Cvs}%
  {.25\Cvs}%
  {\reset@font\large\bfseries}}

\renewcommand{\subsubsection}{\@startsection{subsubsection}{3}{\z@}%
  {1\Cvs \@plus .5\Cvs \@minus .2\Cvs}%
  {.2\Cvs}%
  {\reset@font\normalsize\bfseries}}

% 付録の設定
\def\appendix{%
  \par
  \setcounter{chapter}{0}%
  \setcounter{section}{0}%
  \renewcommand{\prechaptername}{付 録}%
  \addcontentsline{toc}{chapter}{付 録}
  \renewcommand{\postchaptername}{}%
  \renewcommand{\thechapter}{\Alph{chapter}}%
}

% 謝辞を出力するコマンドの定義
\def\thanks{\chapter*{謝 辞}%
  \addcontentsline{toc}{chapter}{謝 辞}}% 目次に追加
\def\endthanks{\par\vfil\null}

% 文字間隔の調整（日本語用）
\spaceskip=.45em plus .1667em minus .1111em% 単語間のスペース
\xspaceskip=.6em plus .5em minus .037em    % 文末のスペース
\kanjiskip=.1zw plus .035zw minus .04zw    % 漢字間のスペース
\xkanjiskip=.13zw plus .01zw minus .01zw   % 漢字と半角文字の間

% ページ番号のスタイルを再定義
\pagenumbering{arabic}
\setcounter{tocdepth}{2}

\endinput
