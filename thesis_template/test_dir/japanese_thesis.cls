% japanese_thesis.cls
% LuaLaTeX + bxjsreport ベースの日本語学位論文クラス
% 作成日: 2024/12/20

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{japanese_thesis}[2024/12/20 Custom class for Japanese academic theses]

% クラスオプションの定義
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{bxjsreport}}
% デフォルトオプションを実行
\ExecuteOptions{
    lualatex,
    a4paper,
    12pt,
    openright,
    onecolumn,
    openany,
    final,
    ja=standard,
    japaram={units}
}
\ProcessOptions\relax  % オプションを処理
% 基本クラスの読み込み
\LoadClassWithOptions{bxjsreport} % オプションを正しく渡す

\RequirePackage{etoolbox} % パッケージの読み込み（bool変数の判定用）
\RequirePackage{luatexja} % 日本語処理用パッケージ
\RequirePackage[haranoaji]{luatexja-preset} % HaranoAji フォントの設定 % フォント設定用パッケージ

% ページレイアウトの調整
\setlength{\topmargin}{0.3cm}      % 上マージンの設定
\setlength{\headsep}{5mm}          % ヘッダーと本文の間隔
\setlength{\oddsidemargin}{0.6cm}  % 奇数ページ左マージン
\setlength{\evensidemargin}{0.6cm} % 偶数ページ左マージン
\setlength{\textheight}{23.3cm}    % テキスト高さ
\setlength{\textwidth}{14.8cm}     % テキスト幅

% カスタムコマンドの定義
% タイトル情報を保存するためのマクロ定義
\makeatletter

\newcommand{\Title}[1]{\gdef\Titlebox{#1}}        % タイトル
\newcommand{\@Title}{\@ifundefined{Titlebox}{{What title is this ?}}{\Titlebox}}
\newcommand{\StudentNumber}[1]{\gdef\StudentNumberbox{学籍番号：#1}} % 学籍番号
\newcommand{\@StudentNumber}{\@ifundefined{StudentNumberbox}{{Who are you ?}}{\StudentNumberbox}}
\newcommand{\Author}[1]{\gdef\Authorbox{氏\hspace{4\jsZw}名：#1}}      % 著者名
\newcommand{\@Author}{\@ifundefined{Authorbox}{{Who are you ?}}{\Authorbox}}
\newcommand{\Professor}[1]{\gdef\Professorbox{指導教員：#1}} % 指導教員名
\newcommand{\@Professor}{\@ifundefined{Professorbox}{{Who are you ?}}{\Professorbox}}
\newcommand{\DateofSubmission}[1]{\gdef\Datebox{令和#1年度}}
\newcommand{\@DateofSubmission}{\@ifundefined{Datebox}{{What day is today ?}}{\Datebox}}

% 論文種別の切り替え判定用のbool変数を定義
\newbool{isMasterThesis}
\newbool{isDoctoralThesis}
\boolfalse{isMasterThesis}
\boolfalse{isDoctoralThesis}

% 論文種別を設定するコマンド
\newcommand{\ThesisType}{卒業論文}
\newcommand{\SetMasterThesis}{
    \renewcommand{\ThesisType}{修士論文}
    \booltrue{isMasterThesis}
    \boolfalse{isDoctoralThesis}
}
\newcommand{\SetDoctoralThesis}{
    \renewcommand{\ThesisType}{博士論文}
    \boolfalse{isMasterThesis}
    \booltrue{isDoctoralThesis}
}

% \kintou{width}{content} を定義
\newcommand{\kintou}[2]{\makebox[#1]{#2}}

% 表紙スタイルの再定義
\newcommand{\Maketitle}{
    \begin{titlepage}
        \pagestyle{empty} % ページ番号を表示しない
        \begin{center}
            \vspace*{-.6cm}
            {\huge \kintou{8\jsZw}{\ThesisType}\par}
            \vspace{.6cm}
            % タイトルを大きく太字で表示
            \vtop to 4.5cm {\hsize=\textwidth
                \begin{center}
                    \vfil
                    {\Huge \textbf{\@Title}}\par
                    \vfil
                \end{center}
            }
            \vspace{5.5cm}
            % 大学を出力
            {\LARGE \kintou{12\jsZw}{福島大学}}\par
            \vspace{0.5cm}
            % 学部・学科を出力
            {\LARGE
                \ifbool{isDoctoralThesis}{
                    \kintou{12\jsZw}{大学院共生システム理工学研究科}\par
                    \kintou{12\jsZw}{共生システム理工学専攻}\par
                }{
                    \ifbool{isMasterThesis}{
                        \kintou{12\jsZw}{大学院共生システム理工学研究科}\par
                        \kintou{12\jsZw}{共生システム理工学専攻}\par
                    }{
                        % 卒業論文の場合
                        \kintou{12\jsZw}{理工学群共生システム理工学類}\par
                        \kintou{12\jsZw}{物理・システム工学コース}\par
                    }
                }
            }\par
            \vspace{1cm}
            % 学籍番号（太字）
            {\huge \kintou{7\jsZw}{\textbf{\@StudentNumber}}}\par
            \vspace{0.5cm}
            % 氏名（太字）
            {\huge \kintou{7\jsZw}{\textbf{\@Author}}}\par
            \vspace{0.5cm}
            % 指導教員名
            {\huge \kintou{7\jsZw}{\@Professor}}\par
            \vspace{2.5cm}
            % 年度
            {\LARGE \kintou{11\jsZw}{\@DateofSubmission}}\par
        \end{center}
    \end{titlepage}
}

\makeatother

% 日本語名の再定義
\renewcommand{\prechaptername}{第}
\renewcommand{\postchaptername}{章}
\renewcommand{\contentsname}{目 次}
\renewcommand{\listfigurename}{図 目 次}
\renewcommand{\listtablename}{表 目 次}
\renewcommand{\bibname}{参考文献}
\renewcommand{\indexname}{索 引}
\renewcommand{\figurename}{Fig}
\renewcommand{\tablename}{Table}
\renewcommand{\appendixname}{付 録}

% ページスタイルの設定
\pagestyle{plain}    % ページ番号のみを表示するスタイル
\setlength{\parindent}{1\jsZw} % 段落の字下げを全角1文字分

% 脚注番号をアラビア数字に変更
\renewcommand{\thefootnote}{\arabic{footnote}}
\renewcommand{\footnoterule}{%
  \kern -3pt
  \hrule width \textwidth height 0.5pt
  \kern 2.6pt
}

% フロントマター（目次など）のページ番号をローマ数字に設定
\AtBeginDocument{
    \pagenumbering{roman}
}

% TOC（目次）のカスタマイズ
\renewcommand{\contentsname}{目 次}
\setcounter{tocdepth}{2} % 章、節、小節まで表示

% 謝辞と参考文献を目次に含めない
\AtBeginDocument{
    \addtocontents{toc}{\protect\setcounter{tocdepth}{-1}}
}

% 本文のページ番号をアラビア数字に設定
\renewcommand{\mainmatter}{
    \cleardoublepage
    \pagenumbering{arabic}
}

% 章のフォーマット設定

% 章のタイトル設定（番号付き）

% 章のタイトル設定（番号なし）

% sectionのフォーマット設定

% subsectionのスタイル定義

% 付録のフォーマット設定
\newcommand{\appendixmatter}{
    \appendix
    \setcounter{chapter}{0}%
    \setcounter{section}{0}%
    \addcontentsline{toc}{chapter}{付 録}
    \renewcommand{\prechaptername}{付 録}%
    \renewcommand{\postchaptername}{}%
    \renewcommand{\thesection}{\Alph{section}} % 数字ではなくアルファベットで数える
    \setcounter{equation}{0}% 式番号を A.1 のようにする
    \renewcommand{\theequation}{\Alph{section}.\arabic{equation}}
    \setcounter{figure}{0}% 図番号
    \renewcommand{\thefigure}{\Alph{section}.\arabic{figure}}
    \setcounter{table}{0}% 表番号
    \renewcommand{\thetable}{\Alph{section}.\arabic{table}}
}

% 謝辞のフォーマット設定
\newcommand{\acknowledgmentsmatter}{
    \cleardoublepage
    \chapter*{謝辞}
}

\endinput
