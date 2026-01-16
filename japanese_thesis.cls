% japanese_thesis.cls
% -------------------------------------------------------------------
% このクラスファイルは、「bxjsreport」を基にした日本語論文用クラスです。
% LuaTeX + luatexja + titlesec による和文組版を想定しています。
% 
% 作成日: 2024/12/20
% -------------------------------------------------------------------

%====================================================================
% 1. クラス宣言とバージョン情報
%====================================================================
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{japanese_thesis}[2024/12/20 Custom class for Japanese academic theses]

%====================================================================
% 2. クラスオプションの定義と処理
%    - bxjsreport で必須となるエンジンオプション (luatex, ... )
%    - デフォルトオプションの設定
%====================================================================
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{bxjsreport}}

% デフォルトオプションを指定：luatex で日本語組版を行う
\ExecuteOptions{
    luatex,           % bxjsreport には luatex などのエンジンオプションが必須
    a4paper,
    base=12pt,
    openright,
    onecolumn,
    openany,
    final,
    ja=standard,
    japaram={units}
}
\ProcessOptions\relax

%====================================================================
% 3. bxjsreport クラスの読み込み
%====================================================================
\LoadClassWithOptions{bxjsreport}

%====================================================================
% 4. 必要パッケージの読み込み
%    - titlesec 等
%====================================================================
\RequirePackage{etoolbox}               % ifboolなどの論理スイッチ機能
\RequirePackage{titlesec}               % 章・節見出しを再定義
\RequirePackage{tocloft}                % 目次の見出しを再定義
\RequirePackage{indentfirst}            % 全ての段落で字下げを行う
\RequirePackage{appendix}               % 付録を扱う

%====================================================================
% 5. ページレイアウトの調整
%    - 余白設定
%====================================================================
\setlength{\topmargin}{0.3cm}
\setlength{\headsep}{5mm}
\setlength{\oddsidemargin}{0.6cm}
\setlength{\evensidemargin}{0.6cm}
\setlength{\textheight}{23.3cm}
\setlength{\textwidth}{14.8cm}

%====================================================================
% 6. 諸情報（論文タイトル・氏名等）を保存するコマンド類の定義
%    - \Title, \Author, \StudentNumber など
%====================================================================
\makeatletter

% タイトル情報
\newcommand{\Title}[1]{\gdef\Titlebox{#1}}
\newcommand{\@Title}{\@ifundefined{Titlebox}{{What title is this ?}}{\Titlebox}}
% 学籍番号（表示用＋中身のみの両方を保持）
\newcommand{\StudentNumber}[1]{%
  \gdef\StudentNumberRawbox{#1}%
  \gdef\StudentNumberbox{学籍番号：#1}%
}
\newcommand{\@StudentNumber}{\@ifundefined{StudentNumberbox}{{Who are you ?}}{\StudentNumberbox}}
\newcommand{\@StudentNumberRaw}{\@ifundefined{StudentNumberRawbox}{{Who are you ?}}{\StudentNumberRawbox}}

% 氏名（表示用＋中身のみの両方を保持）
\newcommand{\Author}[1]{%
  \gdef\AuthorRawbox{#1}%
  \gdef\Authorbox{氏\hspace{2\zw}名：#1}%
}
\newcommand{\@Author}{\@ifundefined{Authorbox}{{Who are you ?}}{\Authorbox}}
\newcommand{\@AuthorRaw}{\@ifundefined{AuthorRawbox}{{Who are you ?}}{\AuthorRawbox}}

% 指導教員
\newcommand{\Professor}[1]{\gdef\Professorbox{指導教員：#1}}
\newcommand{\@Professor}{\@ifundefined{Professorbox}{{Who are you ?}}{\Professorbox}}
% 提出年度
\newcommand{\DateofSubmission}[1]{\gdef\Datebox{令和#1年度}}
\newcommand{\@DateofSubmission}{\@ifundefined{Datebox}{{What day is today ?}}{\Datebox}}
% 論文種別(卒業論文・修士論文・博士論文)
\newbool{isMasterThesis}
\newbool{isDoctoralThesis}
\boolfalse{isMasterThesis}
\boolfalse{isDoctoralThesis}
\newcommand{\ThesisType}{卒業論文}
\newcommand{\SetMasterThesis}{
    \renewcommand{\ThesisType}{修士論文}
    \booltrue{isMasterThesis}
    \boolfalse{isDoctoralThesis}
    \ShowProfessorOnCover       % 既に入れている想定
    \ShowStudentNumberOnCover   % 追加：修士では学籍番号を表示
    \ShowAuthorLabelOnCover     % 追加：修士では「氏名：」を表示
}
\newcommand{\SetDoctoralThesis}{
    \renewcommand{\ThesisType}{博士論文}
    \boolfalse{isMasterThesis}
    \booltrue{isDoctoralThesis}
    \HideProfessorOnCover       % 既に入れている想定
    \HideStudentNumberOnCover   % 追加：博士では学籍番号を非表示
    \HideAuthorLabelOnCover     % 追加：博士では「氏名：」を非表示
}

% === Cover: student number line switch (default: show) ===
\newif\ifjt@shownumber
\jt@shownumbertrue
\newcommand{\ShowStudentNumberOnCover}{\jt@shownumbertrue}
\newcommand{\HideStudentNumberOnCover}{\jt@shownumberfalse}

% === Cover: author label switch (default: show) ===
% true: 「氏名：」付き（\@Author）を出す / false: 名前だけ（\@AuthorRaw）を出す
\newif\ifjt@showauthorlabel
\jt@showauthorlabeltrue
\newcommand{\ShowAuthorLabelOnCover}{\jt@showauthorlabeltrue}
\newcommand{\HideAuthorLabelOnCover}{\jt@showauthorlabelfalse}

% === Cover: professor(advisor) line switch (default: show) ===
\newif\ifjt@showprofessor
\jt@showprofessortrue

% 博士/修士/卒論の切替で確実に復帰できるよう、明示コマンドも用意（任意）
\newcommand{\ShowProfessorOnCover}{\jt@showprofessortrue}
\newcommand{\HideProfessorOnCover}{\jt@showprofessorfalse}

\makeatother

%====================================================================
% 7. 表紙のスタイル定義
%    - \Maketitle コマンドで表紙を作成する
%====================================================================
% 幅を指定して中央揃えするコマンド
\newcommand{\kintou}[2]{\makebox[#1]{#2}}

\makeatletter

\newcommand{\Maketitle}{
    \begin{titlepage}
      \pagestyle{empty} % ページ番号を表示しない
      \begin{center}
        \vspace*{-0.6cm}
        % 論文種別 (卒業論文・修士論文・博士論文)
        {\huge \kintou{8\zw}{\ThesisType}\par}
        \vspace{0.6cm}

        % タイトル
        \vtop to 4.5cm {\hsize=\textwidth
            \begin{center}
              \vfil
              {\Huge \textbf{\@Title}}\par
              \vfil
            \end{center}
        }
        \vspace{5.5cm}

        % 大学名
        {\LARGE \kintou{12\zw}{福島大学}}\par
        \vspace{0.5cm}

        % 学部・学科・専攻(論文種別に応じて切替)
        {\LARGE
          \ifbool{isDoctoralThesis}{
            \kintou{12\zw}{大学院共生システム理工学研究科}\par
            \kintou{12\zw}{共生システム理工学専攻}\par
          }{
            \ifbool{isMasterThesis}{
              \kintou{12\zw}{大学院共生システム理工学研究科}\par
              \kintou{12\zw}{共生システム理工学専攻}\par
            }{
              % 卒業論文の場合
              \kintou{12\zw}{理工学群共生システム理工学類}\par
              \kintou{12\zw}{物理・システム工学コース}\par
            }
          }
        }\par

        \vspace{1cm}
        % 学籍番号（博士論文では非表示。未設定の場合も出さない）
        \ifjt@shownumber
          \@ifundefined{StudentNumberbox}{}{%
            {\huge \kintou{7\zw}{\textbf{\@StudentNumber}}}\par
            \vspace{0.5cm}
          }%
        \fi

        % 氏名（博士論文では「氏名：」無し＝名前のみ。それ以外は従来通り）
        \ifjt@showauthorlabel
          {\huge \kintou{7\zw}{\textbf{\@Author}}}\par
        \else
          {\huge \kintou{7\zw}{\textbf{\@AuthorRaw}}}\par
        \fi
        \vspace{0.5cm}

        % 指導教員（博士論文では非表示。未設定の場合も出さない）
        \ifjt@showprofessor
          \@ifundefined{Professorbox}{}{%
            {\huge \kintou{7\zw}{\@Professor}}\par
          }%
        \fi
        \vspace{2.5cm}
        % 年度
        {\LARGE \kintou{11\zw}{\@DateofSubmission}}\par
      \end{center}
    \end{titlepage}
}

\makeatother

%====================================================================
% 8. 日本語名(目次・参考文献など)の再定義
%====================================================================
\renewcommand{\prechaptername}{第}
\renewcommand{\postchaptername}{章}
\renewcommand{\contentsname}{目 次}
\renewcommand{\listfigurename}{図 目 次}
\renewcommand{\listtablename}{表 目 次}
\renewcommand{\bibname}{参考文献}
\renewcommand{\indexname}{索 引}
\renewcommand{\figurename}{Fig.}
\renewcommand{\tablename}{Table}
% 表番号，図番号の表示スタイル
\counterwithout{figure}{chapter}
\counterwithout{table}{chapter}
\renewcommand{\thefigure}{\arabic{figure}}
\renewcommand{\thetable}{\Roman{table}}
% \counterwithin{figure}{section}

%====================================================================
% 9. ページスタイルや段落設定のカスタマイズ
%====================================================================
\pagestyle{plain}           % ページ番号などシンプルなページスタイル

%====================================================================
% 10. フロントマターなどのページ番号をローマ数字に
%====================================================================
\AtBeginDocument{
    \pagenumbering{roman}
}

%====================================================================
% 11. 目次(\tableofcontents)の再定義
%     - bxjsreport の独自仕様に対応するため
%     - titlesec との競合対策も兼ねる
%====================================================================
\makeatletter

% 目次の計算用の長さを確保
\newdimen\jsc@tocl@width
\newdimen\@tempdima

% \headfont が未定義だと \settowidth でエラーが出るので定義しておく
\renewcommand{\headfont}{\bfseries}

\renewcommand{\tableofcontents}{%
  % 章名や付録名の幅を比較し、長さを決定
  \settowidth\jsc@tocl@width{\headfont \prechaptername\postchaptername}%
  \settowidth\@tempdima{\headfont \appendixname}%
  \ifdim\jsc@tocl@width<\@tempdima
    \setlength\jsc@tocl@width{\@tempdima}%
  \fi
  \ifdim\jsc@tocl@width<2\zw
    \divide\jsc@tocl@width by 2
    \advance\jsc@tocl@width 1\zw
  \fi

  % 実際の目次出力
  \if@twocolumn
    \@restonecoltrue\onecolumn
  \else
    \@restonecolfalse
  \fi
  \chapter*{\contentsname}%
  \@mkboth{\contentsname}{}%
  \@starttoc{toc}%
  \if@restonecol\twocolumn\fi
}

\makeatother

% 目次の深さを指定（節まで表示：0=章のみ,1=章と節,2=章節小節）
\setcounter{tocdepth}{2}

% 章見出しのインデント幅
\renewcommand{\cftchapnumwidth}{4\zw}
\renewcommand{\cftsecnumwidth}{2.5\zw}
\renewcommand{\cftsubsecnumwidth}{3\zw}

\setlength{\cftbeforechapskip}{0pt}

%====================================================================
% 12. 本文開始(\mainmatter)時のページ番号をアラビア数字に
%====================================================================
\renewcommand{\mainmatter}{
    \cleardoublepage
    \pagenumbering{arabic}
}

%====================================================================
% 13. titlesecを使った章・節タイトルの見出しフォーマット再定義
%====================================================================
\titleformat{\chapter}
  [hang]
  {\Huge\bfseries}                         % 章タイトルのフォント
  {\prechaptername\thechapter\postchaptername} % 章番号の表示
  {1\zw}
  {}

\titleformat{name=\chapter,numberless}
  [hang]
  {\Huge\bfseries}
  {}
  {0pt}
  {}

\titlespacing{\chapter}{0pt}{0pt}{1\zw}
\titlespacing{name=\chapter,numberless}{0pt}{0pt}{1\zw}

%-----------------------------
% section の見出し再定義
%-----------------------------
\titleformat{\section}
  [hang]
  {\LARGE\bfseries}
  {\thesection}
  {1\zw}
  {}

\titleformat{name=\section,numberless}
  [hang]
  {\LARGE\bfseries}
  {}
  {0pt}
  {}

\titlespacing{\section}{0pt}{1\zw}{1\zw}
\titlespacing{name=\section,numberless}{0pt}{1\zw}{1\zw}

%-----------------------------
% subsection の見出し再定義
%-----------------------------
\titleformat{\subsection}
  [hang]
  {\Large\bfseries}
  {\thesubsection}
  {1\zw}
  {}

\titleformat{name=\subsection,numberless}
  [hang]
  {\Large\bfseries}
  {}
  {0pt}
  {}

\titlespacing{\subsection}{0pt}{1\zw}{1\zw}
\titlespacing{name=\subsection,numberless}{0pt}{1\zw}{1\zw}

%-----------------------------
% subsubsection の見出し再定義
%-----------------------------
\titleformat{\subsubsection}
  [hang]
  {\Large\bfseries}
  {}
  {0pt}
  {}

\titlespacing{\subsubsection}{0pt}{1\zw}{1\zw}
\titlespacing{name=\subsubsection,numberless}{0pt}{1\zw}{1\zw}

%====================================================================
% 14. 付録(\appendix)と謝辞(\thanks)の定義
%====================================================================
\renewcommand{\appendixname}{付録} %%ここを付録と変更することで「付録 A」などと変更されます。デフォルトでは「appendix A」。
\renewcommand{\appendixtocname}{付録} %%目次のappendix開始ページに表示される文字列を変更できます。
\renewcommand{\appendixpagename}{付録} %%ページヘッダーに表示される文字列を変更できます。
% \renewcommand{\appendix}{
% %     \setcounter{equation}{0}%
% %     \renewcommand{\theequation}{\Alph{section}.\arabic{equation}}
% %     \setcounter{figure}{0}%
% %     \renewcommand{\thefigure}{\Alph{section}.\arabic{figure}}
% %     \setcounter{table}{0}%
% %     \renewcommand{\thetable}{\Alph{section}.\arabic{table}}
%  }

\newcommand{\appendixstyle}{
    \titleformat{\chapter}
    [hang]
    {\Huge\bfseries}                         % 章タイトルのフォント
    {\appendixname\thechapter} % 章番号の表示
    {1\zw}
    {}
    \titlespacing{\appendix}{0pt}{0pt}{1\zw}

}

\renewcommand{\thanks}{
    \cleardoublepage
    \chapter*{謝 辞}
}

%====================================================================
% 15. クラスファイルの終了
%====================================================================
\endinput
