const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const dotenv = require('dotenv');
const fetch = require('node-fetch');
const { z } = require('zod');
const { redactPII } = require('./redactor');

dotenv.config();

const PORT = process.env.PORT || 8080;
const ORIGINS = (process.env.ALLOWED_ORIGINS || '').split(',');
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
const MODEL = process.env.OPENAI_REALTIME_MODEL || 'gpt-4o-realtime-preview';

if (!OPENAI_API_KEY) {
  console.error('Missing OPENAI_API_KEY');
  process.exit(1);
}

const app = express();
app.use(express.json({ limit: '1mb' }));
app.use(cors({ origin: ORIGINS }));

const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '60000', 10),
  max: parseInt(process.env.RATE_LIMIT_MAX || '60', 10),
});
app.use(limiter);

// POST /webrtc/offer
app.post('/webrtc/offer', async (req, res) => {
  const schema = z.object({ sdp: z.string() });
  const parseResult = schema.safeParse(req.body);
  if (!parseResult.success) {
    return res.status(400).json({ error: 'Invalid payload' });
  }
  const { sdp } = parseResult.data;
  try {
    const response = await fetch(`https://api.openai.com/v1/realtime/calls?model=${MODEL}&voice=alloy`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
        'Content-Type': 'application/sdp',
      },
      body: sdp,
    });
    if (!response.ok) {
      const text = await response.text();
      console.error('OpenAI error', text);
      return res.status(500).json({ error: 'Upstream error' });
    }
    const answer = await response.text();
    res.json({ sdp: answer });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /analytics
app.post('/analytics', (req, res) => {
  const schema = z.object({
    event: z.string(),
    payload: z.any().optional(),
    consent: z.boolean(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: 'Invalid payload' });
  }
  const { event, payload, consent } = parsed.data;
  if (consent) {
    const redactedPayload = payload ? JSON.parse(redactPII(JSON.stringify(payload))) : undefined;
    console.log('analytics', event, redactedPayload);
  }
  res.json({ ok: true });
});

app.listen(PORT, () => {
  console.log(`Service listening on ${PORT}`);
});
