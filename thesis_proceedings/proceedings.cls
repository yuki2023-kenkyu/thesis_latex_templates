% クラスファイル: proceedings.cls

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{proceedings}[2024/10/15 Graduation Thesis Class]

\LoadClass[a4paper,12pt]{jsarticle}

% 必要なパッケージ
\RequirePackage{graphicx}
\RequirePackage{geometry}
\RequirePackage{titlesec}
\RequirePackage{setspace}
\RequirePackage{multicol}
\RequirePackage{enumitem}
\RequirePackage{balance}

% ページマージンの設定
\geometry{a4paper,left=20mm,right=20mm,top=25mm,bottom=22mm}

% フォントサイズと行間の設定
\renewcommand{\normalsize}{\fontsize{9pt}{14pt}\selectfont}
\renewcommand{\Large}{\fontsize{15pt}{18pt}\selectfont} % 題名15ポイント
\renewcommand{\large}{\fontsize{11pt}{14pt}\selectfont} % 著者名11ポイント

% セクションのフォーマット
\titleformat{\section}[block]{\normalsize\bfseries\filcenter}{\thesection}{1em}{}
\titleformat{\subsection}[runin]{\normalsize\bfseries}{\thesubsection}{1em}{}[]
\titlespacing{\subsection}{0pt}{0.5ex}{0pt}

% ページ番号を表示しない
\pagestyle{empty}

% タイトルのフォーマット
\renewcommand{\maketitle}{
    \thispagestyle{empty}
    \begin{center}
        \vspace*{-20mm} % 余白調整
        {\Large \@title \par}
        \vspace{1em}
        {\large \@author \par}
        \vspace{1em}
    \end{center}
    \@thanks
}

% 行間の設定
\setstretch{1}

% 箇条書きの設定
\setlist[itemize]{leftmargin=0pt,itemsep=0pt,parsep=0pt}
\setlist[enumerate]{leftmargin=0pt,itemsep=0pt,parsep=0pt}

% 図表キャプションの設定
\RequirePackage[font=small,labelfont=bf,labelsep=period]{caption}

% 脚注の設定
\renewcommand{\thefootnote}{}
\renewcommand{\footnoterule}{
  \kern -0.5pt % 水平線直前の余白を削減
  \hrule width 0.5\textwidth % ページ幅の半分の長さ
  \kern 0pt  % 水平線と本文の間のスペースをゼロに
}
\renewcommand{\footnotesize}{\fontsize{9pt}{11pt}\selectfont}
\makeatletter
\renewcommand{\@makefntext}[1]{%
    \noindent#1}
\makeatother

% 本文と脚注の間の余白を削減
\setlength{\skip\footins}{0pt}
%\setlength\footnotesep{0pt}

% 段組の設定
\setlength{\columnsep}{10mm}
\setlength{\columnseprule}{0pt}

% パラグラフの設定
\setlength{\parindent}{0pt}
\setlength{\parskip}{0pt}

% 段落間の余白を調整
\setlength{\topskip}{0pt}
\setlength{\partopsep}{0pt}
\setlength{\parsep}{0pt}
\setlength{\itemsep}{0pt}
