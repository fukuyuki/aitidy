echo '{
  "contents":[
    {
      "parts":[
        {"text": "What is this picture?"},
        {
          "inline_data": {
            "mime_type":"image/jpeg",
            "data": "'$(base64 -w0 room.jpg)'"
          }
        }
      ]
    }
  ]
}' > request.json
