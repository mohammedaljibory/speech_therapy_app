const functions = require('firebase-functions');
const admin = require('firebase-admin');
const fetch = require('node-fetch');
const FormData = require('form-data');
const Busboy = require('busboy');
const cors = require('cors')({ origin: true });

admin.initializeApp();

// Get API keys from Firebase environment config
// Set with: firebase functions:config:set openai.key="sk-xxx" claude.key="sk-ant-xxx"
const getOpenAIKey = () => functions.config().openai?.key || process.env.OPENAI_API_KEY;
const getClaudeKey = () => functions.config().claude?.key || process.env.CLAUDE_API_KEY;

/**
 * Whisper Speech-to-Text Proxy
 * Receives audio file and returns transcription
 */
exports.whisperTranscribe = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.method !== 'POST') {
      return res.status(405).json({ error: 'Method not allowed' });
    }

    const apiKey = getOpenAIKey();
    if (!apiKey) {
      return res.status(500).json({ error: 'OpenAI API key not configured' });
    }

    try {
      // Parse multipart form data
      const busboy = Busboy({ headers: req.headers });
      let audioBuffer = null;
      let audioFilename = 'audio.m4a';
      let language = 'ar';

      const parsePromise = new Promise((resolve, reject) => {
        busboy.on('file', (fieldname, file, info) => {
          const chunks = [];
          audioFilename = info.filename || audioFilename;
          file.on('data', (chunk) => chunks.push(chunk));
          file.on('end', () => {
            audioBuffer = Buffer.concat(chunks);
          });
        });

        busboy.on('field', (fieldname, val) => {
          if (fieldname === 'language') language = val;
        });

        busboy.on('finish', resolve);
        busboy.on('error', reject);
      });

      req.pipe(busboy);
      await parsePromise;

      if (!audioBuffer) {
        return res.status(400).json({ error: 'No audio file provided' });
      }

      // Determine content type based on file extension
      let contentType = 'audio/m4a';
      if (audioFilename.endsWith('.webm')) {
        contentType = 'audio/webm';
      } else if (audioFilename.endsWith('.mp3')) {
        contentType = 'audio/mpeg';
      } else if (audioFilename.endsWith('.wav')) {
        contentType = 'audio/wav';
      } else if (audioFilename.endsWith('.ogg')) {
        contentType = 'audio/ogg';
      }

      console.log(`Processing audio file: ${audioFilename}, size: ${audioBuffer.length} bytes, type: ${contentType}`);

      // Create form data for OpenAI
      const formData = new FormData();
      formData.append('file', audioBuffer, {
        filename: audioFilename,
        contentType: contentType,
      });
      formData.append('model', 'whisper-1');
      formData.append('language', language);
      formData.append('response_format', 'json');

      // Call OpenAI Whisper API
      const response = await fetch('https://api.openai.com/v1/audio/transcriptions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${apiKey}`,
          ...formData.getHeaders(),
        },
        body: formData,
      });

      const data = await response.json();

      if (!response.ok) {
        console.error('Whisper API error:', data);
        return res.status(response.status).json({ error: data.error?.message || 'Whisper API error' });
      }

      return res.json({ success: true, text: data.text });
    } catch (error) {
      console.error('Whisper transcription error:', error);
      return res.status(500).json({ error: error.message });
    }
  });
});

/**
 * Claude AI Evaluation Proxy
 * Receives evaluation request and returns AI analysis
 */
exports.claudeEvaluate = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.method !== 'POST') {
      return res.status(405).json({ error: 'Method not allowed' });
    }

    const apiKey = getClaudeKey();
    if (!apiKey) {
      return res.status(500).json({ error: 'Claude API key not configured' });
    }

    try {
      const { expectedWord, transcription, childName, childAge, childLevel } = req.body;

      if (!expectedWord) {
        return res.status(400).json({ error: 'expectedWord is required' });
      }

      // Build the evaluation prompt
      const prompt = `
أنت مساعد متخصص في علاج النطق للأطفال المصابين بالتوحد. مهمتك تقييم نطق الطفل وتقديم ملاحظات مشجعة ومفيدة.

معلومات الطفل:
- الاسم: ${childName || 'الطفل'}
- العمر: ${childAge || 5} سنوات
- المستوى: ${childLevel || 'مبتدئ'}

الكلمة المطلوب نطقها: "${expectedWord}"
ما نطقه الطفل: "${transcription || 'لم يتم التعرف على الكلام'}"

قم بتقييم النطق وأرجع النتيجة بصيغة JSON فقط (بدون أي نص إضافي) كالتالي:

{
  "accuracy": <رقم من 0 إلى 100 يمثل دقة النطق>,
  "similarity": <رقم من 0 إلى 100 يمثل التشابه النصي>,
  "wer": <معدل خطأ الكلمات من 0 إلى 100، أقل أفضل>,
  "cer": <معدل خطأ الأحرف من 0 إلى 100، أقل أفضل>,
  "mos": <تقييم جودة النطق من 1 إلى 5>,
  "overallScore": <الدرجة الإجمالية من 0 إلى 100>,
  "level": "<ممتاز أو جيد جداً أو جيد أو مقبول أو يحتاج تحسين>",
  "feedback": "<ملاحظة قصيرة ومشجعة للطفل باللغة العربية>",
  "detailedAnalysis": "<تحليل مفصل للنطق للمدرب>",
  "improvements": ["<اقتراح تحسين 1>", "<اقتراح تحسين 2>"],
  "encouragement": "<رسالة تشجيعية قصيرة ومحببة للطفل>"
}

ملاحظات مهمة:
1. كن مشجعاً ولطيفاً - هذا طفل مصاب بالتوحد ويحتاج دعماً
2. استخدم لغة بسيطة مناسبة لعمر الطفل
3. ركز على الإيجابيات حتى لو كان النطق غير صحيح
4. قدم اقتراحات عملية وبسيطة للتحسين
5. إذا كان النطق صحيحاً تماماً، أعطِ درجات عالية واحتفل مع الطفل
6. إذا كان النطق قريباً، شجع الطفل وأخبره أنه على الطريق الصحيح

أرجع JSON فقط بدون أي نص قبله أو بعده.
`;

      // Call Claude API
      const response = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: JSON.stringify({
          model: 'claude-sonnet-4-20250514',
          max_tokens: 1024,
          messages: [{ role: 'user', content: prompt }],
        }),
      });

      const data = await response.json();

      if (!response.ok) {
        console.error('Claude API error:', data);
        return res.status(response.status).json({ error: data.error?.message || 'Claude API error' });
      }

      // Extract the response text
      const content = data.content?.[0]?.text;
      if (!content) {
        return res.status(500).json({ error: 'Empty response from Claude' });
      }

      // Try to parse the JSON response
      try {
        let jsonStr = content.trim();
        // Remove markdown code blocks if present
        if (jsonStr.startsWith('```')) {
          jsonStr = jsonStr.replace(/^```json?\n?/, '').replace(/\n?```$/, '');
        }
        const jsonMatch = jsonStr.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          const result = JSON.parse(jsonMatch[0]);
          return res.json({ success: true, ...result });
        }
      } catch (parseError) {
        console.error('JSON parse error:', parseError);
      }

      // Return raw response if parsing fails
      return res.json({ success: true, rawResponse: content });
    } catch (error) {
      console.error('Claude evaluation error:', error);
      return res.status(500).json({ error: error.message });
    }
  });
});

/**
 * Health check endpoint
 */
exports.healthCheck = functions.https.onRequest((req, res) => {
  cors(req, res, () => {
    res.json({
      status: 'ok',
      timestamp: new Date().toISOString(),
      openaiConfigured: !!getOpenAIKey(),
      claudeConfigured: !!getClaudeKey(),
    });
  });
});
