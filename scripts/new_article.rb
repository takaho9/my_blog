require "optparse"
require "fileutils"

def create_article(file_name)
  # content/posts ディレクトリにファイルを作成
  posts_dir = "content/posts"
  FileUtils.mkdir_p(posts_dir)
  post_path = File.join(posts_dir, "#{file_name}.md")

  # .prompt_history ディレクトリにプロンプト履歴を作成
  prompt_dir = ".prompt_history"
  FileUtils.mkdir_p(prompt_dir)
  prompt_path = File.join(prompt_dir, "#{file_name}.md")

template_prompt = <<TEXT
以下の指示と内容に従って、技術ブログの記事を生成してください：

## 基本情報
- タイトル：[記事のタイトルを入力]
  - メインキーワードを含む、30-60文字程度
  - 検索意図に合致する具体的な表現を使用
- メタディスクリプション：[120-160文字で記事の価値を簡潔に説明]
- 対象読者：[初級者/中級者/上級者]
- 想定読了時間：[XX分]
- 主要キーワード：[3-5個のターゲットキーワード]

## 記事の構成
1. はじめに
   - 記事の背景と課題提起（キーワードを自然に含める）
   - 解決したい課題
   - 読者が得られる具体的な価値
   - 目次（h2見出しの一覧）

2. 本文
   - 技術の概要説明
   - 実装方法や手順（段階的に説明）
   - コードサンプル（該当する場合）
   - 具体的なユースケース
   - 注意点やベストプラクティス

3. まとめ
   - 主要なポイントの要約
   - 次のステップの提案
   - 参考リソース・引用（信頼性の向上）

## コンテンツ最適化のポイント

- キーワードを自然に配置（最適な密度を維持）
- 画像にalt属性を設定
- 内部リンク・外部リンクを適切に配置

## 記事のトーン・スタイル
- 専門用語は初出時に簡単な説明を付ける
- 実践的な例を含める
- 図表やコードブロックを適切に使用
  - 図表する際はmermaid記法を使用
- 読者との対話的な文体を心がける
- スキャンしやすい文章構成
  - 短めの段落
  - 箇条書きの活用
  - 重要部分の強調
- 表なども適切であれば使用して良い

## 品質チェックリスト
- [ ] 技術的な正確性
- [ ] 文章の論理的な流れ
- [ ] コードの動作確認
- [ ] 誤字脱字のチェック
- [ ] 参考文献の明記
- [ ] SEO要素の確認
TEXT

  # 記事のテンプレートを作成
  article_template = <<TEXT
---
title: "#{full_file_name}"
date: #{Time.now.strftime('%Y-%m-%d')}
draft: true
categories:
  - プログラミング
tags:
  - プログラミング
cover:
  image:
  alt: "cover image"
---

ここに記事の内容を書いてください。
TEXT

  # ファイルの書き込み
  File.write(post_path, article_template)
  File.write(prompt_path, template_prompt)

  puts "記事ファイルを作成しました: #{post_path}"
  puts "プロンプト履歴を作成しました: #{prompt_path}"
end

# コマンドライン引数の処理
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ruby new_article.rb FILENAME"

  opts.on("-h", "--help", "ヘルプを表示") do
    puts opts
    exit
  end
end.parse!

if ARGV.empty?
  puts "エラー: ファイル名を指定してください"
  puts "使用方法: ruby new_article.rb FILENAME"
  exit 1
end

create_article(ARGV[0])
