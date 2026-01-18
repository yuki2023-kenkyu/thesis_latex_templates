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
%
% NOTE:
% - 'final' をここで強制しない。
%   \documentclass[draft]{japanese_thesis} を有効にするため。
% - changes など \documentclass の draft/final を再利用するパッケージがあり，
%   ここで常に final を渡すと意図せず無効化される。
% - bxjsreport はデフォルトで final なので，final を明示しなくても通常の
%   出力は維持される。
\ExecuteOptions{
    luatex,           % bxjsreport には luatex などのエンジンオプションが必須
    a4paper,
    base=12pt,
    openright,
    onecolumn,
    openany,
    ja=standard,
    japaram={units}
}
\ProcessOptions\relax

%====================================================================
% 3. bxjsreport クラスの読み込み
%====================================================================
\LoadClassWithOptions{bxjsreport}


%====================================================================
% Review / draft support (changes + colored comments)
%====================================================================
% This keeps markup commands available in both draft/final, while
% automatically suppressing their output in final builds.
\RequirePackage{./preambles/checkstyle}

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
% -------------------------------------------------------------------
% Public API (user-facing macros)
%
%  Metadata setters:
%    \Title{...}\Author{...}\StudentNumber{...}\Professor{...}
%    \University{...}\AffiliationLineA{...}\AffiliationLineB{...}
%    \DateofSubmission{...}
%
%  Thesis type selectors (also set sensible cover defaults):
%    \SetMasterThesis, \SetDoctoralThesis
%
%  Cover switches (independent; may be overridden after thesis type selection):
%    \ShowStudentNumberOnCover / \HideStudentNumberOnCover
%    \ShowAuthorLabelOnCover   / \HideAuthorLabelOnCover
%    \ShowProfessorOnCover     / \HideProfessorOnCover
%
% Notes:
%  - The internal implementation uses the jt@* namespace and should not be
%    redefined in user documents unless you understand the implications.
% -------------------------------------------------------------------

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

% 指導教員（表示用＋中身のみの両方を保持）
\newcommand{\Professor}[1]{%
  \gdef\ProfessorRawbox{#1}%
  \gdef\Professorbox{指導教員：#1}%
}
\newcommand{\@Professor}{\@ifundefined{Professorbox}{{Who are you ?}}{\Professorbox}}
\newcommand{\@ProfessorRaw}{\@ifundefined{ProfessorRawbox}{{Who are you ?}}{\ProfessorRawbox}}

%====================================================================
% Cover affiliation strings (university / grad school / department)
% - Do not hard-code these strings in \Maketitle; manage via variables.
% - Thesis-type switching updates the defaults, while users can override.
%====================================================================
\newcommand{\University}[1]{\gdef\Universitybox{#1}}
\newcommand{\@University}{\@ifundefined{Universitybox}{{Which university ?}}{\Universitybox}}

% 2 affiliation lines shown below university name
\newcommand{\AffiliationLineA}[1]{\gdef\AffilAbox{#1}}
\newcommand{\AffiliationLineB}[1]{\gdef\AffilBbox{#1}}
\newcommand{\@AffiliationLineA}{\@ifundefined{AffilAbox}{{}}{\AffilAbox}}
\newcommand{\@AffiliationLineB}{\@ifundefined{AffilBbox}{{}}{\AffilBbox}}

% Default affiliation (undergraduate)
\University{福島大学}
\AffiliationLineA{理工学群共生システム理工学類}
\AffiliationLineB{物理・システム工学コース}
% 提出年度
\newcommand{\DateofSubmission}[1]{\gdef\Datebox{令和#1年度}}
\newcommand{\@DateofSubmission}{\@ifundefined{Datebox}{{What day is today ?}}{\Datebox}}
% 論文種別(卒業論文・修士論文・博士論文)
\newbool{isMasterThesis}
\newbool{isDoctoralThesis}
\boolfalse{isMasterThesis}
\boolfalse{isDoctoralThesis}
\newcommand{\ThesisType}{卒業論文}

% -------------------------------------------------------------------
% Internal implementation details (jt@* namespace)
%
% Convention:
%  - Any macro/length/flag whose name begins with jt@ is considered internal
%    and may change without notice. User documents should rely only on the
%    Public API listed above.
% -------------------------------------------------------------------
% Internal helper: set default affiliation for graduate theses.
% (Keeps SetMasterThesis / SetDoctoralThesis DRY without changing behavior.)
\newcommand{\jt@SetGraduateAffiliationDefaults}{%
    \University{福島大学}%
    \AffiliationLineA{大学院共生システム理工学研究科}%
    \AffiliationLineB{共生システム理工学専攻}%
}
\newcommand{\SetMasterThesis}{
    \renewcommand{\ThesisType}{修士論文}
    \booltrue{isMasterThesis}
    \boolfalse{isDoctoralThesis}
    % Default affiliation for master thesis
    \jt@SetGraduateAffiliationDefaults
    \ShowProfessorOnCover       % 既に入れている想定
    \ShowStudentNumberOnCover   % 追加：修士では学籍番号を表示
    \ShowAuthorLabelOnCover     % 追加：修士では「氏名：」を表示
}
\newcommand{\SetDoctoralThesis}{
    \renewcommand{\ThesisType}{博士論文}
    \boolfalse{isMasterThesis}
    \booltrue{isDoctoralThesis}
    % Default affiliation for doctoral thesis
    \jt@SetGraduateAffiliationDefaults
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

% --- Cover: parameterized layout + boxed, aligned fields ---
% 表紙内の位置調整は極力「変数（長さ）」で管理し、\Maketitle 内に数値を直書きしない。
% また、学籍番号／氏名／指導教員は
%  (1) ラベル部分と値部分を別々の箱に分けて
%  (2) ラベル箱の幅を固定して右揃えし、コロン位置を揃える。
%  (3) 3行全体をさらに大きな箱（info block）で括り、その箱を中央配置する。

% --- Cover layout parameters (lengths) ---
\newlength{\jt@cover@topshift}
\newlength{\jt@cover@aftertype}
\newlength{\jt@cover@titleheight}
\newlength{\jt@cover@afteruniv}
\newlength{\jt@cover@afteraffil}
\newlength{\jt@cover@betweeninfolines}
\newlength{\jt@cover@typewidth}
\newlength{\jt@cover@univwidth}
\newlength{\jt@cover@datewidth}
\newlength{\jt@cover@authorwidth}

\setlength{\jt@cover@topshift}{-0.6cm}
\setlength{\jt@cover@aftertype}{0.6cm}
\setlength{\jt@cover@titleheight}{4.5cm}
\setlength{\jt@cover@afteruniv}{0.5cm}
\setlength{\jt@cover@afteraffil}{1cm}
\setlength{\jt@cover@betweeninfolines}{0.5cm}
\setlength{\jt@cover@typewidth}{8\zw}
\setlength{\jt@cover@univwidth}{12\zw}
\setlength{\jt@cover@datewidth}{11\zw}
\setlength{\jt@cover@authorwidth}{7\zw}

% --- Labels (as variables) ---
\newcommand{\jt@label@studentnumber}{学籍番号：}
\newcommand{\jt@label@author}{氏\hspace{2\zw}名：}
\newcommand{\jt@label@professor}{指導教員：}

% --- Info block geometry ---
\newlength{\jt@cover@labelwidth}
\newlength{\jt@cover@tmpdima}
\newlength{\jt@cover@infoblockwidth}
\newlength{\jt@cover@valuewidth}
\newlength{\jt@cover@labelvaluesep}
\setlength{\jt@cover@labelvaluesep}{1\zw}

% If the computed (label + sep + max(value)) exceeds \linewidth, switch to a
% wrapping mode for values to avoid impossible centering when the block is wider
% than the available line width.
\newif\ifjt@coverwrapvalues

% Compute max value width among the actually displayed items.
% Requirement: values (StudentNumber/Author/Professor) are centered within the
% *same* value box whose width equals the maximum of the three strings.
\newcommand{\jt@calcvaluewidth}{%
  % Author is always present.
  \settowidth{\jt@cover@valuewidth}{{\huge\bfseries \@AuthorRaw}}%
  % Student number (optional)
  \ifjt@hasnumberline
    \settowidth{\jt@cover@tmpdima}{{\huge\bfseries \@StudentNumberRaw}}%
    \ifdim\jt@cover@valuewidth<\jt@cover@tmpdima \setlength{\jt@cover@valuewidth}{\jt@cover@tmpdima}\fi
  \fi
  % Professor (optional)
  \ifjt@hasprofline
    \settowidth{\jt@cover@tmpdima}{{\huge\bfseries \@ProfessorRaw}}%
    \ifdim\jt@cover@valuewidth<\jt@cover@tmpdima \setlength{\jt@cover@valuewidth}{\jt@cover@tmpdima}\fi
  \fi
}

% Set info block width.
% - Avoid fixed magic numbers.
% - Prefer the *natural* required width = labelwidth + sep + max(valuewidth).
% - If that required width exceeds the available line width (\linewidth), fall
%   back to a wrapping mode (values become a centered \parbox).
\newcommand{\jt@setinfoblockwidth}{%
  \jt@coverwrapvaluesfalse
  \setlength{\jt@cover@infoblockwidth}{\dimexpr\jt@cover@labelwidth+\jt@cover@labelvaluesep+\jt@cover@valuewidth\relax}%
  \ifdim\jt@cover@infoblockwidth>\linewidth
    \jt@coverwrapvaluestrue
    \setlength{\jt@cover@infoblockwidth}{\linewidth}%
    \setlength{\jt@cover@valuewidth}{\dimexpr\jt@cover@infoblockwidth-\jt@cover@labelwidth-\jt@cover@labelvaluesep\relax}%
    \ifdim\jt@cover@valuewidth<0pt \setlength{\jt@cover@valuewidth}{0pt}\fi
  \fi
}

% Compute max label width using the *actual* label strings.
\newcommand{\jt@calclabelwidth}{%
  \settowidth{\jt@cover@labelwidth}{{\huge\bfseries \jt@label@studentnumber}}%
  \settowidth{\jt@cover@tmpdima}{{\huge\bfseries \jt@label@author}}%
  \ifdim\jt@cover@labelwidth<\jt@cover@tmpdima \setlength{\jt@cover@labelwidth}{\jt@cover@tmpdima}\fi
  \settowidth{\jt@cover@tmpdima}{{\huge\bfseries \jt@label@professor}}%
  \ifdim\jt@cover@labelwidth<\jt@cover@tmpdima \setlength{\jt@cover@labelwidth}{\jt@cover@tmpdima}\fi
}

% One aligned line = one box that contains two sub-boxes (label/value).
% - Label box: fixed width, right-aligned (colon alignment)
% - Value box: fixed width (= max value width among displayed lines), and the
%   value is centered inside.
% - If the whole block would exceed \linewidth, switch to a wrapping mode where
%   the value is a centered \parbox.
\newcommand{\jt@coverline}[2]{%
  \noindent
  \hbox to \jt@cover@infoblockwidth{%
    \hbox to \jt@cover@labelwidth{\hfil #1}%
    \hskip\jt@cover@labelvaluesep
    \ifjt@coverwrapvalues
      \parbox[t]{\jt@cover@valuewidth}{\centering #2}%
    \else
      \hbox to \jt@cover@valuewidth{\hfil\mbox{#2}\hfil}%
    \fi
  }\par
}

% Center a box of a given width within the current line width (\linewidth).
% This is more robust than \makebox[\textwidth][c]{...} inside list-based
% environments (e.g., center/trivlist) where \linewidth can differ from
% \textwidth.
\newcommand{\jt@centerinfoblock}[2]{%
  \noindent\hbox to \linewidth{\hfil\begin{minipage}{#1}#2\end{minipage}\hfil}\par
}

% Internal switches used during cover rendering (set within \Maketitle)
\newif\ifjt@hasnumberline
\newif\ifjt@hasprofline
\newif\ifjt@coveraligned


\newcommand{\Maketitle}{
    \begin{titlepage}
      \pagestyle{empty} % ページ番号を表示しない
      \begin{center}
        \vspace*{\jt@cover@topshift}
        % 論文種別 (卒業論文・修士論文・博士論文)
        {\huge \kintou{\jt@cover@typewidth}{\ThesisType}\par}
        \vspace{\jt@cover@aftertype}

        % タイトル
        \vtop to \jt@cover@titleheight {\hsize=\textwidth
            \begin{center}
              \vfil
              {\Huge \textbf{\@Title}}\par
              \vfil
            \end{center}
        }
        \vfill

        % 大学名
        {\LARGE \kintou{\jt@cover@univwidth}{\@University}}\par
        \vspace{\jt@cover@afteruniv}

        % 学部・学科・専攻(論文種別に応じて切替)
        {\LARGE
          \kintou{\jt@cover@univwidth}{\@AffiliationLineA}\par
          \kintou{\jt@cover@univwidth}{\@AffiliationLineB}\par
        }\par
        \vspace{\jt@cover@afteraffil}
        % === 学籍番号／氏名／指導教員：ラベル位置を揃えて出力 ===
        % - ラベル（学籍番号：/氏名：/指導教員：）は固定幅で右揃え（コロン位置を揃える）
        % - 値は同一の開始位置から出力
        % - 既存の表示/非表示スイッチ（博士論文など）を尊重
        %
        % NOTE:
        % - 固定長の \vspace を多用すると，わずかな高さ増加（行折返し等）で表紙が溢れて
        %   2ページ目に送られることがあるため，下部余白は \vfill で吸収する。

        % 表示対象の有無を判定（未設定なら出力しない）
        \jt@hasnumberlinefalse
        \ifjt@shownumber
          \@ifundefined{StudentNumberRawbox}{}{\jt@hasnumberlinetrue}%
        \fi
        \jt@hasproflinefalse
        \ifjt@showprofessor
          \@ifundefined{ProfessorRawbox}{}{\jt@hasproflinetrue}%
        \fi

        % 「ラベル列の整列」が必要か（少なくとも1つラベル付き行を出す場合）
        \jt@coveralignedfalse
        \ifjt@showauthorlabel \jt@coveralignedtrue\fi
        \ifjt@hasnumberline \jt@coveralignedtrue\fi
        \ifjt@hasprofline \jt@coveralignedtrue\fi

        \ifjt@coveraligned
            \jt@calclabelwidth
            \jt@calcvaluewidth
            \jt@setinfoblockwidth
          {\huge\bfseries
            % Center the whole info block against the *current* line width.
            % Use \linewidth (not \textwidth) to be robust inside list-based
            % environments such as center/trivlist.
            \jt@centerinfoblock{\jt@cover@infoblockwidth}{%
              % Student number (optional)
              \ifjt@hasnumberline
                \jt@coverline{\jt@label@studentnumber}{\@StudentNumberRaw}
                \vspace{\jt@cover@betweeninfolines}
              \fi
              % Author (label optional)
              \ifjt@showauthorlabel
                \jt@coverline{\jt@label@author}{\@AuthorRaw}
              \else
                \jt@coverline{}{\@AuthorRaw}
              \fi
              % Professor (optional)
              \ifjt@hasprofline
                \vspace{\jt@cover@betweeninfolines}
                \jt@coverline{\jt@label@professor}{\@ProfessorRaw}
              \fi
            }%
          }\par
        \else
          % 博士論文などで「氏名ラベル無し」かつ学籍番号/指導教員も非表示のときは，
          % 単独行を中央配置（余計なブロック化で高さを増やさない）。
          {\huge \kintou{\jt@cover@authorwidth}{\textbf{\@AuthorRaw}}}\par
          \vspace{\jt@cover@betweeninfolines}
        \fi
        \vfill
        % 年度
        {\LARGE \kintou{\jt@cover@datewidth}{\@DateofSubmission}}\par
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
