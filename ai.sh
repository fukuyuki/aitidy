#!/bin/bash

# API keyの設定
YOUR_API_KEY="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"
set -x

# JSONファイルの読み込み
if [ -f timestamps.json ]; then
    timestamps=$(cat timestamps.json)
else
    timestamps="{}"
fi

# プロンプトファイルの取得
prompt_files=(prompts/*.txt)

# 各プロンプトファイルの処理
for file in "${prompt_files[@]}"; do
    # ファイルのタイムスタンプを取得
    timestamp=$(stat -f %m "$file" 2>/dev/null || stat -c %Y "$file")
    
    # タイムスタンプの比較
    current_timestamp=$(echo "$timestamps" | jq -r ".timestamps[\"$file\"]" 2>/dev/null)
    if [ "$current_timestamp" = "$timestamp" ]; then
        continue
    fi

    # 出力ファイル名の取得（1行目）
    output_filename=$(head -n 1 "$file" | tr -d '\r\n')
    
    # ファイル名の長さチェック
    if [ ${#output_filename} -ge 24 ]; then
        echo "Error: Output filename is too long (max 23 characters): $output_filename"
        exit 1
    fi

    # プロンプトの取得（2行目以降）
    prompt=$(tail -n +2 "$file")
    prompt="${prompt}返答はコードのみです。説明はコメントで入れてください。"

    # APIリクエストの作成と送信
    response=$(curl -s https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $YOUR_API_KEY" \
        -d "{
            \"model\": \"gpt-4o-2024-11-20\",
            \"messages\": [{
                \"role\": \"user\",
                \"content\": $(echo "$prompt" | jq -Rs .)
            }]
        }")

    # レスポンスの処理と保存
    echo "$response" | jq -r '.choices[0].message.content' | \
        sed '/^```/d' > "$output_filename"

    # タイムスタンプの更新
    timestamps=$(echo "$timestamps" | jq --arg file "$file" --arg timestamp "$timestamp" \
        '.timestamps[$file] = $timestamp')
done

# 更新されたタイムスタンプの保存
echo "$timestamps" > timestamps.json

# timestamps.jsonの削除
#rm timestamps.json