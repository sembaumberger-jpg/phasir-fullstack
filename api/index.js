// index.js
import dotenv from 'dotenv';
dotenv.config();

import cors from 'cors';
import express from 'express';
import { v4 as uuid } from 'uuid';
import { createClient } from '@supabase/supabase-js';
import axios from 'axios';
import OpenAI from 'openai';

const PORT = process.env.PORT || 4000;
const app = express();

// -------------------------------------------------
// Supabase Setup
// -------------------------------------------------
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey =
  process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('❌ SUPABASE_URL oder SUPABASE_SERVICE_ROLE_KEY/ANON_KEY fehlen!');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

// -------------------------------------------------
// OpenAI Setup (für AI-Features)
// -------------------------------------------------
let openai = null;
if (process.env.OPENAI_API_KEY) {
  openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
} else {
  console.warn('⚠️ Kein OPENAI_API_KEY gesetzt – AI-Routen geben nur Dummy-Antworten zurück.');
}

// -------------------------------------------------
// Middleware
// -------------------------------------------------
app.use(
  cors({
    origin: '*', // ggf. einschränken (z.B. auf deine Domains)
  })
);
app.use(express.json());

// Healthcheck
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// 🔐 Auth-Middleware: zieht User aus Supabase-Token
async function requireAuth(req, res, next) {
  try {
    const authHeader = req.headers.authorization || '';
    if (!authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Nicht authentifiziert.' });
    }

    const token = authHeader.replace('Bearer ', '').trim();
    if (!token) {
      return res.status(401).json({ error: 'Nicht authentifiziert.' });
    }

    // Supabase v2: getUser mit Access Token
    const { data, error } = await supabase.auth.getUser(token);

    if (error || !data?.user) {
      console.warn('Auth Fehler:', error?.message);
      return res.status(401).json({ error: 'Nicht authentifiziert.' });
    }

    req.user = data.user;
    next();
  } catch (err) {
    console.error('Fehler in requireAuth:', err);
    res.status(500).json({ error: 'Interner Auth-Fehler.' });
  }
}

// -------------------------------------------------
// Auth: Register & Login
// -------------------------------------------------
app.post('/auth/register', async (req, res) => {
  const { email, password } = req.body || {};
  if (!email || !password) {
    return res.status(400).json({ error: 'Email und Passwort erforderlich.' });
  }

  try {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
    });

    if (error) {
      console.error('Supabase signUp Fehler:', error.message);
      return res.status(400).json({ error: error.message });
    }

    // Supabase schickt keinen AccessToken direkt nach signUp zurück,
    // daher bitten wir den Client, sich im Anschluss mit /auth/login einzuloggen.
    res.status(200).json({
      message: 'Registrierung erfolgreich. Bitte jetzt einloggen.',
      user: data.user,
    });
  } catch (err) {
    console.error('Register Fehler:', err);
    res.status(500).json({ error: 'Interner Fehler bei der Registrierung.' });
  }
});

app.post('/auth/login', async (req, res) => {
  const { email, password } = req.body || {};
  if (!email || !password) {
    return res.status(400).json({ error: 'Email und Passwort erforderlich.' });
  }

  try {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      console.error('Supabase signIn Fehler:', error.message);
      return res.status(400).json({ error: error.message });
    }

    const { session, user } = data;

    if (!session?.access_token) {
      return res.status(500).json({ error: 'Kein AccessToken von Supabase erhalten.' });
    }

    res.json({
      accessToken: session.access_token,
      user: {
        id: user.id,
        email: user.email,
      },
    });
  } catch (err) {
    console.error('Login Fehler:', err);
    res.status(500).json({ error: 'Interner Fehler beim Login.' });
  }
});

// -------------------------------------------------
// HOUSES – CRUD (immer user-scoped)
// -------------------------------------------------

// Alle Häuser des eingeloggten Nutzers
app.get('/houses', requireAuth, async (req, res) => {
  try {
    const userId = req.user.id;

    const { data, error } = await supabase
      .from('houses')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('/houses GET Fehler:', error.message);
      return res.status(500).json({ error: 'Fehler beim Laden der Immobilien.' });
    }

    res.json(data || []);
  } catch (err) {
    console.error('/houses GET Ausnahme:', err);
    res.status(500).json({ error: 'Interner Serverfehler.' });
  }
});

// Neue Immobilie anlegen – POST erzeugt IMMER ein neues Objekt
app.post('/houses', requireAuth, async (req, res) => {
  try {
    const userId = req.user.id;
    const body = req.body || {};

    const newId = uuid();

    // Client-ID & user_id werden ignoriert/überschrieben
    const insertData = {
      ...body,
      id: newId,
      user_id: userId,
    };

    const { data, error } = await supabase
      .from('houses')
      .insert(insertData)
      .select('*')
      .single();

    if (error) {
      console.error('/houses POST Fehler:', error.message, insertData);
      return res.status(500).json({ error: 'Fehler beim Anlegen der Immobilie.' });
    }

    res.status(201).json(data);
  } catch (err) {
    console.error('/houses POST Ausnahme:', err);
    res.status(500).json({ error: 'Interner Serverfehler.' });
  }
});

// Immobilie aktualisieren – nur eigene Immobilie
app.put('/houses/:id', requireAuth, async (req, res) => {
  try {
    const userId = req.user.id;
    const houseId = req.params.id;
    const updates = req.body || {};

    // Sicherheit: user_id & id nicht vom Client überschreiben lassen
    delete updates.id;
    delete updates.user_id;

    const { data, error } = await supabase
      .from('houses')
      .update(updates)
      .eq('id', houseId)
      .eq('user_id', userId)
      .select('*')
      .single();

    if (error) {
      console.error('/houses PUT Fehler:', error.message);
      return res.status(500).json({ error: 'Fehler beim Aktualisieren der Immobilie.' });
    }

    if (!data) {
      return res.status(404).json({ error: 'Immobilie nicht gefunden.' });
    }

    res.json(data);
  } catch (err) {
    console.error('/houses PUT Ausnahme:', err);
    res.status(500).json({ error: 'Interner Serverfehler.' });
  }
});

// -------------------------------------------------
// NEWS – Immobilien-News Feed
// -------------------------------------------------
app.get('/news/real-estate', async (req, res) => {
  try {
    const apiKey = process.env.NEWS_API_KEY;
    const country = 'de';

    if (!apiKey) {
      // Fallback Demo-Daten
      return res.json([
        {
          id: 'demo-1',
          title: 'Immobilienmarkt: Wie sich Zinsen und Preise entwickeln',
          summary:
            'Kurzüberblick über aktuelle Entwicklungen am deutschen Immobilienmarkt. Demo-Artikel, falls NEWS_API_KEY fehlt.',
          source: 'Phasir Demo',
          url: 'https://example.com',
          imageUrl: null,
          publishedAt: new Date().toISOString(),
        },
      ]);
    }

    // Beispiel mit gnews.io (oder eigener News-API)
    const response = await axios.get('https://gnews.io/api/v4/top-headlines', {
      params: {
        token: apiKey,
        topic: 'nation',
        lang: 'de',
        country,
        max: 20,
      },
    });

    const articles = (response.data.articles || []).map((a, index) => ({
      id: a.url || `news-${index}`,
      title: a.title,
      summary: a.description,
      source: a.source?.name ?? 'News',
      url: a.url,
      imageUrl: a.image,
      publishedAt: a.publishedAt ?? new Date().toISOString(),
    }));

    res.json(articles);
  } catch (err) {
    console.error('/news/real-estate Fehler:', err);
    res.status(500).json({ error: 'Fehler beim Laden der Immobilien-News.' });
  }
});

// -------------------------------------------------
// AI-ENDPOINTS (vereinfachte Version)
// -------------------------------------------------
async function aiOrDummy(prompt, fallbackTitle) {
  if (!openai) {
    return `${fallbackTitle}: (Demo-Antwort, da kein OPENAI_API_KEY gesetzt ist)\n\n${prompt}`;
  }

  const completion = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      { role: 'system', content: 'Du bist ein Assistent für Immobilieneigentümer.' },
      { role: 'user', content: prompt },
    ],
    temperature: 0.4,
  });

  return completion.choices[0].message.content;
}

app.post('/ai/energy-advice', requireAuth, async (req, res) => {
  try {
    const { house } = req.body || {};
    const prompt = `
Gib eine kurze Energieeffizienz-Einschätzung für diese Immobilie in Deutschland und nenne konkrete Maßnahmen mit groben Kostenspannen:
${JSON.stringify(house, null, 2)}
    `;
    const text = await aiOrDummy(prompt, 'Energieanalyse');
    res.json({ advice: text });
  } catch (err) {
    console.error('/ai/energy-advice Fehler:', err);
    res.status(500).json({ error: 'Fehler bei der Energieanalyse.' });
  }
});

app.post('/ai/finance-advice', requireAuth, async (req, res) => {
  try {
    const { house } = req.body || {};
    const prompt = `
Bewerte Cashflow, ROI und Risiko dieser Immobilie für einen deutschen Privatinvestor. Kurze, klare Bulletpoints:
${JSON.stringify(house, null, 2)}
    `;
    const text = await aiOrDummy(prompt, 'Finanzanalyse');
    res.json({ advice: text });
  } catch (err) {
    console.error('/ai/finance-advice Fehler:', err);
    res.status(500).json({ error: 'Fehler bei der Finanzanalyse.' });
  }
});

app.post('/ai/repair-support', requireAuth, async (req, res) => {
  try {
    const { description } = req.body || {};
    const prompt = `
Der Nutzer beschreibt ein Problem an seiner Immobilie. Analysiere:
- Wahrscheinliche Ursache
- Dringlichkeit
- Risikostufe
- Erste-Hilfe-Schritte
- Grobe Kostenspanne

Problem:
${description}
    `;
    const text = await aiOrDummy(prompt, 'Reparatur-Support');
    res.json({ advice: text });
  } catch (err) {
    console.error('/ai/repair-support Fehler:', err);
    res.status(500).json({ error: 'Fehler beim Reparatur-Support.' });
  }
});

// Dummy-Rent-Benchmark, falls du ihn schon im iOS benutzt
app.post('/ai/rent-benchmark', requireAuth, async (req, res) => {
  try {
    const { houses } = req.body || {};
    // TODO: Hier könntest du später echte Mietspiegel-APIs einbinden
    res.json({
      summary: 'Demo-Rent-Benchmark – echte Logik folgt später.',
      houses: (houses || []).map((h) => ({
        id: h.id,
        name: h.name ?? 'Objekt',
        rating: 'marktgerecht',
        deviationPercent: 0,
      })),
    });
  } catch (err) {
    console.error('/ai/rent-benchmark Fehler:', err);
    res.status(500).json({ error: 'Fehler beim Miet-Benchmark.' });
  }
});

// -------------------------------------------------
// Server Start
// -------------------------------------------------
app.listen(PORT, () => {
  console.log(`🚀 Phasir Backend läuft auf Port ${PORT}`);
});
