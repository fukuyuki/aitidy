#!/bin/bash
set -x  # デバッグ用

# 親ディレクトリの名前を取得
REPO_NAME=$(basename "$(pwd)")

# GitHubリポジトリを作成
if ! gh repo create "$REPO_NAME" --public; then
  echo "GitHubリポジトリの作成に失敗しました。"
  exit 1
fi

# git init（必要に応じて）
git init

# リモートリポジトリを追加
git remote add origin "https://github.com/$(gh auth status --show-token | grep 'Logged in to' | awk '{print $NF}')/$REPO_NAME.git"

# readme.txtを作成
echo "# $REPO_NAME" > readme.txt

# ファイルをステージング
find . -maxdepth 1 \( -name "*.html" -o -name "*.js" -o -name "*.txt" \) -exec git add {} +

# git commit
git commit -m "test"

# git push
git push -u origin main

# 完了メッセージ
echo "GitHubリポジトリのセットアップが完了しました。"
