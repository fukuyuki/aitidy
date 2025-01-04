// npm install express sqlite3 axios body-parser fs

const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const axios = require('axios');
const bodyParser = require('body-parser');
const fs = require('fs');
const os = require('os');
const path = require('path');

const app = express();
app.use(bodyParser.json());

// Determine database filename path
const dbFilename = os.release().includes('WSL') ? './ai2025.db' : '/mnt/test/ai2025.db';

// Initialize SQLite Database
const db = new sqlite3.Database(dbFilename);
db.run(
  `CREATE TABLE IF NOT EXISTS users (
    id CHAR(36) PRIMARY KEY,
    email CHAR(64),
    paytime INT DEFAULT 0,
    count INT DEFAULT 5,
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  )`
);

// Upload endpoint
app.post('/upload', async (req, res) => {
  try {
    const { uid, image } = req.body;

    // Convert image to BASE64
    const base64img = Buffer.from(image).toString('base64');

    // Read tidy_prompt.txt file
    const prompt_tidy = fs.readFileSync('tidy_prompt.txt', 'utf8').trim();

    // Send REST API request using axios
    const url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=AIzaSyCCogqa39KQnXsMRquF55kbZr3jEJJbsB0';
    const apiResponse = await axios.post(
      url,
      {
        contents: [
          {
            parts: [
              { text: prompt_tidy },
              { inline_data: { mime_type: 'image/jpeg', data: base64img } },
            ],
          },
        ],
      },
      { headers: { 'Content-Type': 'application/json' } }
    );

    console.log(apiResponse.data);

    // Parse and log AI response content
    const ai_response_json = JSON.parse(apiResponse.data.candidates[0].content.parts[0].text);
    console.log(ai_response_json);

    res.send('Upload complete');
  } catch (error) {
    console.error(error);
    res.status(500).send('Error processing upload');
  }
});

// Pay endpoint
app.post('/pay', (req, res) => {
  res.send('Pay endpoint not implemented yet'); // Placeholder
});

// Webhook endpoint
app.post('/webhook', (req, res) => {
  res.send('Webhook endpoint not implemented yet'); // Placeholder
});

// Skip endpoint
app.post('/skip', (req, res) => {
  res.send('Skip endpoint not implemented yet'); // Placeholder
});

// Review endpoint
app.post('/review', (req, res) => {
  const { uid } = req.body;

  db.get('SELECT * FROM users WHERE id = ?', [uid], (err, row) => {
    if (err) {
      console.error(err);
      return res.status(500).send('Database error');
    }

    if (row) {
      res.json(row);
    } else {
      res.status(404).send('User not found');
    }
  });
});

// Page endpoint
app.get('/page/:pageid', (req, res) => {
  const pageid = req.params.pageid;
  const filePath = path.join(__dirname, `${pageid}.html`);

  if (fs.existsSync(filePath)) {
    res.sendFile(filePath);
  } else {
    res.status(404).send('Page not found');
  }
});

// Start server
const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
