%% File: lab_thesis.cls
%% Based on bxjsreport.cls
%% 福島大学馬塲研究室の学位論文用クラスファイル（bxjsreportベース）
%% 作成者：Yuki Hashimoto
%% 更新日：2024/12/19

\NeedsTeXFormat{LaTeX2e}[2023-02-14]
\ProvidesClass{lab_thesis}[2024/12/19 Bamba Lab Thesis Style Class]

% 1. オプションの処理にkvoptionsとetoolboxを使用
\RequirePackage{kvoptions}
\RequirePackage{etoolbox} % \ifbool を使用するため

\SetupKeyvalOptions{
  family=labthesis,
  prefix=labthesis@
}

% 2. クラスオプションの定義（master, doctor, graduate）
\DeclareBooleanOption{master}
\DeclareBooleanOption{doctor}
\DeclareBooleanOption{graduate} % オプション、デフォルトはfalse

% 未知のオプションは基底クラスに転送（ユーザーが指定したオプションは無視される）
\DeclareDefaultOption*{\PassOptionsToClass{\CurrentOption}{bxjsreport}}

% オプションの処理
\ProcessKeyvalOptions*

% 3. 固定オプションを基底クラスに渡す
\PassOptionsToClass{
  engine=luatex,
  12pt,
  a4paper,
  oneside,
  final,
  ja=standard
}{bxjsreport}

% 4. 基底クラスをオプション付きで読み込む
\LoadClassWithOptions{bxjsreport}

% 5. LuaLaTeX専用パッケージの読み込み
\RequirePackage{luatexja}
\RequirePackage{luatexja-fontspec}

% 日本語フォント設定（必要に応じてコメントを外して設定）
%\setmainjfont{IPAexMincho} % 例: IPAexMinchoがインストールされている場合

% 6. ページレイアウトの調整
\setlength{\topmargin}{0.3cm}
\setlength{\headsep}{5mm}
\setlength{\oddsidemargin}{0.6cm}
\setlength{\evensidemargin}{0.6cm}
\setlength{\textheight}{23.3cm}
\setlength{\textwidth}{14.8cm}

% 7. ページスタイルの設定
\pagestyle{plain}
\setlength{\parindent}{2em}

% 8. 脚注番号をアラビア数字に変更
\renewcommand{\thefootnote}{\arabic{footnote}}
\renewcommand{\footnoterule}{%
  \kern -3pt
  \hrule width \textwidth height 0.5pt
  \kern 2.6pt
}

% 9. 日本語名の再定義
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

% 10. タイトル情報を保存するためのマクロ定義
\makeatletter
\newcommand{\Title}[1]{\gdef\labthesis@title{#1}}
\newcommand{\Author}[1]{\gdef\labthesis@author{#1}}
\newcommand{\Professor}[1]{\gdef\labthesis@professor{#1}}
\newcommand{\StudentNumber}[1]{\gdef\labthesis@studentnumber{#1}}
\newcommand{\Date}[1]{\gdef\labthesis@date{令和#1年度}}
\makeatother

% 11. 表紙作成コマンド
\makeatletter
\newcommand{\Maketitle}{%
  \begingroup
  \pagestyle{empty}
  \thispagestyle{empty}
  \begin{center}
    \vspace*{2cm}
    {\huge
      \ifbool{doctor}
        {博士論文}
        {\ifbool{master}
            {修士論文}
            {卒業論文}
        }
    }
    \vspace{1cm}
    
    % タイトル部分
    \vbox to 4.5cm {
      \vfil
      {\Huge \bfseries \labthesis@title \par}
      \vfil
    }
    \vspace{5.5cm}
    
    {\LARGE 福島大学}\par
    \vspace{0.5cm}
    
    {\LARGE
      \ifbool{doctor}
        {大学院共生システム理工学研究科\\共生システム理工学専攻}
        {\ifbool{master}
            {大学院共生システム理工学研究科\\共生システム理工学専攻}
            {理工学群共生システム理工学類\\物理・システム工学コース}
        }
    }
    \vspace{1cm}
    
    {\huge \textbf{学籍番号：\labthesis@studentnumber}}\par
    \vspace{0.5cm}
    
    {\huge \textbf{氏　　名：\labthesis@author}}\par
    \vspace{0.5cm}
    
    {\huge \textbf{指導教員：\labthesis@professor}}\par
    \vspace{2.5cm}
    
    {\LARGE \labthesis@date}\par
  \end{center}
  \vfill
  \endgroup
  \newpage
}
\makeatother

% 12. 謝辞コマンドの再定義
\makeatletter
\renewcommand{\thanks}[1]{%
  \chapter*{謝 辞}%
  #1%
  \addcontentsline{toc}{chapter}{謝 辞}%
}
\makeatother

% 13. frontmatter と mainmatter の定義と自動呼び出し
% ユーザーが明示的に呼び出すように自動呼び出しを削除
% \AtBeginDocument{%
%   \frontmatter
% }

% 14. 章タイトルサイズ調整コマンド（必要に応じて）
\makeatletter
\newcommand{\chaptersize}[1]{\gdef\labthesis@chapsize{#1}}
\makeatother

% 15. 章スタイル再定義
\makeatletter
\renewcommand{\chapter}{%
  \clearpage
  \thispagestyle{plain}
  \global\@topnum\z@
  \@afterindenttrue
  \secdef\@lab@chapter\@lab@schapter
}

\def\@lab@chapter[#1]#2{%
  \ifnum \c@secnumdepth >\m@ne
    \refstepcounter{chapter}%
    \addcontentsline{toc}{chapter}{\protect\numberline{\prechaptername\thechapter\postchaptername}#1}%
  \else
    \addcontentsline{toc}{chapter}{#1}%
  \fi
  \chaptermark{#1}%
  \addtocontents{lof}{\protect\addvspace{10pt}}%
  \addtocontents{lot}{\protect\addvspace{10pt}}%
  \@makechapterhead{#2}%
  \@afterheading%
  \pagestyle{plain}
}

\def\@lab@schapter#1{%
  \chaptermark{#1}%
  \@makeschapterhead{#1}%
  \@afterheading%
  \pagestyle{plain}
}

\newlength{\tempwidth}

% 章タイトル（番号付き）
\def\@makechapterhead#1{%
  \vspace*{20pt}%
  {%
    \parindent=0pt % 段落インデントを0に設定
    \interlinepenalty\@M
    \ifnum \c@secnumdepth >\m@ne
      % 章番号「第#章」の幅を計算
      \settowidth{\tempwidth}{\chapnumfont{\prechaptername\thechapter\postchaptername}\quad}%
      % 章番号を表示し、幅を確保
      \makebox[\tempwidth][l]{\chapnumfont{\prechaptername\thechapter\postchaptername}\quad}%
      % タイトルのインデントを設定
      \hangindent=\tempwidth
      \hangafter=1
      % タイトルを表示
      \chaptitlefont{#1}\par
    \else
      \chaptitlefont{#1}\par
    \fi
    \nobreak \vskip 15pt
  }%
}

% 章タイトル（番号なし）
\def\@makeschapterhead#1{%
  \vspace*{20pt}%
  {%
    \parindent=0pt % 段落インデントを0に設定
    \interlinepenalty\@M
    \chaptitlefont{#1}\par
    \nobreak \vskip 15pt
  }%
}

% 章番号とタイトルのフォント設定
\newcommand{\chapnumfont}[1]{\Huge \bfseries #1}
\newcommand{\chaptitlefont}[1]{\Huge \bfseries #1}

% セクションのスタイル再定義
\renewcommand{\section}{%
  \@startsection{section}{1}{\z@}%
    {1.5\Cvs \@plus .5\Cvs \@minus .2\Cvs}%
    {.5\Cvs}%
    {\reset@font\Large\bfseries}%
}

\renewcommand{\subsection}{%
  \@startsection{subsection}{2}{\z@}%
    {1.25\Cvs \@plus .5\Cvs \@minus .2\Cvs}%
    {.25\Cvs}%
    {\reset@font\large\bfseries}%
}

\renewcommand{\subsubsection}{%
  \@startsection{subsubsection}{3}{\z@}%
    {1\Cvs \@plus .5\Cvs \@minus .2\Cvs}%
    {.2\Cvs}%
    {\reset@font\normalsize\bfseries}%
}

% 付録設定
\renewcommand{\appendix}{%
  \clearpage
  \setcounter{chapter}{0}%
  \setcounter{section}{0}%
  \renewcommand{\prechaptername}{付 録}%
  \renewcommand{\postchaptername}{}%
  \renewcommand{\thechapter}{\Alph{chapter}}%
  \addcontentsline{toc}{chapter}{\appendixname}%
}

% ページ番号再定義
\setcounter{tocdepth}{2}
\setcounter{secnumdepth}{3}

% 参考文献の目次表示制御
\renewcommand{\thebibliography}[1]{%
  \chapter*{\bibname}%
  \addcontentsline{toc}{chapter}{\bibname}%
  \begin{list}{\@biblabel{\@arabic\c@enumiv}}{%
      \setlength{\labelwidth}{\z@}%
      \setlength{\leftmargin}{\parindent}%
      \setlength{\itemindent}{-\parindent}%
      \setlength{\itemsep}{0pt}%
      \setlength{\parsep}{\z@}%
      \usecounter{enumiv}%
      \let\p@enumiv\@empty%
      \renewcommand{\theenumiv}{\@arabic\c@enumiv}%
  }%
  \sloppy
  \sfcode`\.=1000\relax
}
\makeatother

% ハイパーリンクの調整
\makeatletter
% chapterおよびsectionのタイトルの前に\phantomsectionを挿入
\pretocmd{\@makechapterhead}{\phantomsection}{}{}
\pretocmd{\@makeschapterhead}{\phantomsection}{}{}
\makeatother

\endinput
