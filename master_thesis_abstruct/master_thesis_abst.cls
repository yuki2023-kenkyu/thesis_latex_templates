\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{master_thesis_abst}[2024/10/14 修士論文内容要旨]

% ベースとなるクラスを読み込み
\LoadClass[a4paper,12pt]{jsarticle}

% 必要なパッケージを読み込み
\RequirePackage{geometry}
\geometry{
    a4paper,                   % 用紙サイズ
    top=25mm,                  % 上余白
    bottom=25mm,               % 下余白
    left=25mm,                 % 左余白
    right=25mm,                % 右余白
    heightrounded,             % テキスト高さを整数値に
}

\RequirePackage{setspace}
\setstretch{1.3}               % 行間を1.3倍に設定
\pagestyle{empty}              % ページ番号を表示しない

% 追加: arrayパッケージの読み込み
\RequirePackage{array}

% （様式2）を右揃えで配置するコマンド
\newcommand{\formnumber}{
    \begin{flushright}
        \normalsize（様式2）
    \end{flushright}
}

% タイトルを表示するコマンド
\newcommand{\thesistitle}{
    \begin{center}
        \textbf{修士論文内容要旨} \\
        \vspace{1cm}
    \end{center}
}

% 著者情報と学位情報を表示するコマンド
\newcommand{\authorinfo}[6]{
    % 引数:
    % #1: 氏名
    % #2: 本籍
    % #3: 学位記番号
    % #4: 学位授与年月日
    % #5: 学位授与の要件
    % #6: 研究科
    \noindent
    \begin{tabular}{@{} p{25mm} p{100mm}}
        \textbf{氏名（本籍）}：        & #1（#2） \\
        \textbf{学位の種類}：          & 修士（理工学） \\
        \textbf{学位記番号}：          & #3 \\
        \textbf{学位授与年月日}：      & #4 \\
        \textbf{学位授与の要件}：      & #5 \\
        \textbf{研究科}：              & #6 \\
    \end{tabular}
}

% 修士論文題目を表示するコマンド
\newcommand{\thesistopic}[1]{
    \noindent
    \begin{tabular}{@{} p{25mm} p{100mm}}
        \textbf{修士論文題目}：       & #1 \\
    \end{tabular}
}

% 論文審査委員を表示するコマンド
\newcommand{\thesiscommittee}[3]{
    \noindent
    \begin{tabular}{@{} p{25mm} p{100mm}}
        \textbf{論文審査委員}： & \\
        \hspace{2em}（主査）：& #1 \\
        \hspace{2em}（副査）：& #2 \\
        \hspace{2em} & #3 \\
    \end{tabular}
}

% 論文目次を表示するコマンド
\newcommand{\thesiscontents}[1]{
    \vspace{1cm}
    \begin{center}
        \normalsize \textbf{論文目次} \\
    \end{center}
    \begin{flushleft}
        #1
    \end{flushleft}
}

% 論文内容要旨を表示するコマンド
\newcommand{\thesisabstract}[1]{
    \vspace{1cm}
    \begin{center}
        \normalsize \textbf{論文内容要旨} \\
    \end{center}
    \begin{flushleft}
        #1
    \end{flushleft}
}

% クラスファイルの終了
\endinput
