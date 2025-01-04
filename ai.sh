#!/bin/bash
set -x  # echo on

# 1. 環境変数設定
YOUR_API_KEY="${OPEN_AI_KEY}"

# 2. JSONファイル:filesize.jsonを読み込む
if [ -f "filesize.json" ]; then
  filesize_json=$(cat filesize.json)
else
  filesize_json="{}"  # JSONデータがない場合は空オブジェクトを初期化
fi

# 3. prompts ディレクトリ内の txt ファイルを配列 prompt_files に格納
prompt_files=($(find prompts -type f -name "*.txt"))

# 4. 各ファイルについて処理
for file in "${prompt_files[@]}"; do
  # 現在のファイルサイズを取得
  current_filesize=$(stat -c%s "$file")

  # JSONから以前のファイルサイズを取得
  previous_filesize=$(echo "$filesize_json" | jq -r --arg file "$file" '.[$file] // empty')

  # ファイルサイズが変わっていなければスキップ
  if [ "$current_filesize" == "$previous_filesize" ]; then
    continue
  fi

  # ファイルの中身を処理
  mapfile -t lines < "$file"
  output_filename=$(echo "${lines[0]}" | tr -d '\r\n')

  # ファイル名の長さをチェック
  if [ ${#output_filename} -ge 24 ]; then
    echo "Error: Output filename exceeds 24 characters."
    exit 1
  fi

  # プロンプトの生成（2行目から最終行まで）
  prompt=$(printf "%s\n" "${lines[@]:1}")
  prompt+="\n返答はコードのみです。説明はコメントで入れてください。"

  # APIリクエストのデータ作成
  json_payload=$(jq -n --arg model "gpt-4o-2024-11-20" --arg prompt "$prompt" '{
    "model": $model,
    "messages": [{"role": "user", "content": $prompt}]
  }')

  # OpenAI APIにリクエストを送信
  response=$(curl -s -X POST "https://api.openai.com/v1/chat/completions" \
    -H "Authorization: Bearer $YOUR_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$json_payload")

  # レスポンスをファイルに保存
  echo "$response" | jq -r '.choices[0].message.content' > "$output_filename"

  # ``` を含む行を削除
  sed -i '/```/d' "$output_filename"

  # 出力ファイルのサイズを取得
  output_filesize=$(stat -c%s "$output_filename")

  # filesize.json を更新
  filesize_json=$(echo "$filesize_json" | jq --arg file "$file" --argjson size "$output_filesize" '.[$file] = $size')

  # 更新内容を保存
  echo "$filesize_json" > filesize.json
done

# 5. filesize.json を削除
#rm -f filesize.json
