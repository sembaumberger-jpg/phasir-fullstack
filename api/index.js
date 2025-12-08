import dotenv from 'dotenv';
dotenv.config();

import cors from 'cors';
import express from 'express';
import { v4 as uuid } from 'uuid';
import { createClient } from '@supabase/supabase-js';
import OpenAI from 'openai';
import bcrypt from 'bcryptjs'; // 🔐 Passwort-Hashing
import fs from 'fs'; // 📁 File persistence for in-memory fallback

const PORT = process.env.PORT || 4000;
const app = express();

// ---- Supabase Setup ----
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey =
  process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.warn(
    '⚠️ Supabase URL oder Key fehlen. Backend läuft mit In-Memory Demo-Daten.'
  );
} else {
  console.log(
    '✅ Supabase-Konfiguration gefunden. Verwende Postgres-Datenbank.'
  );
}

const supabase =
  supabaseUrl && supabaseKey ? createClient(supabaseUrl, supabaseKey) : null;
const SUPABASE_TABLE = 'houses';

app.use(cors());
app.use(express.json());

const intervals = {
  heating: 2,
  roof: 4,
  windows: 15,
  smoke: 1,
};

// 🆕 ---- News API Setup (für Immobilien-News) ----

const NEWS_API_BASE_URL = process.env.NEWS_API_BASE_URL || '';
const NEWS_API_KEY = process.env.NEWS_API_KEY || '';

// 🗺️ ---- Google Places API Setup (für Dienstleister-Karte) ----
const GOOGLE_PLACES_API_KEY = process.env.GOOGLE_PLACES_API_KEY || '';

if (!GOOGLE_PLACES_API_KEY) {
  console.warn(
    '⚠️ GOOGLE_PLACES_API_KEY fehlt. /vendors/search liefert nur Demo-Daten.'
  );
}

if (!NEWS_API_BASE_URL || !NEWS_API_KEY) {
  console.warn(
    '⚠️ NEWS_API_BASE_URL oder NEWS_API_KEY fehlen. /news/real-estate liefert nur Demo-Daten.'
  );
}

// ---- OpenAI Setup ----
const openaiApiKey = process.env.OPENAI_API_KEY || '';

const openai = openaiApiKey ? new OpenAI({ apiKey: openaiApiKey }) : null;

if (!openai) {
  console.warn('⚠️ OPENAI_API_KEY fehlt. AI-Endpunkte laufen im Demo-Modus.');
} else {
  console.log('✅ OpenAI erfolgreich geladen.');
}

// In‑Memory Demo‑Daten (werden verwendet, wenn Supabase nicht konfiguriert ist und kein houses.json vorhanden ist)
const demoHouses = [
  {
    id: uuid(),
    ownerName: 'Lisa Rhein',
    name: 'Stadtvilla Rheinblick',
    address: 'Rheinufer 12, Köln',
    buildYear: 2008,
    heatingType: 'Gas',
    heatingInstallYear: 2015,
    lastHeatingService: new Date('2023-05-10'),
    roofInstallYear: 2016,
    lastRoofCheck: new Date('2022-07-01'),
    windowInstallYear: 2018,
    lastSmokeCheck: new Date('2024-06-12'),
    // Grobe Koordinaten für Köln (nur Demo)
    lat: 50.940664,
    lng: 6.959912,
  },
  {
    id: uuid(),
    ownerName: 'Tom Berger',
    name: 'Alpen Chalet',
    address: 'Talweg 5, Garmisch',
    buildYear: 1995,
    heatingType: 'Wärmepumpe',
    heatingInstallYear: 2020,
    lastHeatingService: new Date('2022-11-03'),
    roofInstallYear: 2018,
    lastRoofCheck: new Date('2023-09-15'),
    windowInstallYear: 2015,
    lastSmokeCheck: new Date('2023-12-01'),
    lat: 47.497954,
    lng: 11.095993,
  },
  {
    id: uuid(),
    ownerName: 'Mara Schulz',
    name: 'Stadthaus Mitte',
    address: 'Chausseestraße 21, Berlin',
    buildYear: 2012,
    heatingType: 'Fernwärme',
    heatingInstallYear: 2012,
    lastHeatingService: new Date('2024-01-18'),
    roofInstallYear: 2012,
    lastRoofCheck: new Date('2021-04-20'),
    windowInstallYear: 2017,
    lastSmokeCheck: new Date('2024-04-09'),
    lat: 52.531677,
    lng: 13.390364,
  },
];

// ⚠️ houses.json Persistence: falls Supabase nicht genutzt wird, versuchen wir, Häuser aus einer JSON-Datei zu laden.
const housesFilePath = './data/houses.json';

// Stelle sicher, dass der Datenordner existiert, damit writeFileSync nicht fehlschlägt
if (!fs.existsSync('./data')) {
  try {
    fs.mkdirSync('./data');
  } catch (e) {
    console.warn('⚠️ Konnte Datenordner nicht erstellen:', e);
  }
}

let houses;

try {
  const fileData = fs.readFileSync(housesFilePath, 'utf8');
  const parsed = JSON.parse(fileData);
  // Konvertiere Datumsstrings zurück in Date-Objekte
  houses = parsed.map((h) => ({
    ...h,
    lastHeatingService: h.lastHeatingService ? new Date(h.lastHeatingService) : null,
    lastRoofCheck: h.lastRoofCheck ? new Date(h.lastRoofCheck) : null,
    lastSmokeCheck: h.lastSmokeCheck ? new Date(h.lastSmokeCheck) : null,
  }));
  console.log(`✅ Loaded ${houses.length} houses from persistence file`);
} catch (err) {
  // Wenn Datei fehlt oder Fehler beim Parsen → Demo- oder leere Daten verwenden
  // Standardmäßig laden wir KEINE Demo-Häuser mehr, damit Nutzer nicht ungefragt Testobjekte sehen.
  // Über die Umgebungsvariable INCLUDE_DEMO_HOUSES=true lassen sich Demo-Objekte aktivieren.
  const includeDemoHouses = process.env.INCLUDE_DEMO_HOUSES === 'true';
  houses = includeDemoHouses ? demoHouses : [];
  if (includeDemoHouses) {
    console.log('ℹ️ No houses.json found or failed to parse. Using demo houses.');
  } else {
    console.log('ℹ️ No houses.json found or failed to parse. Starting with an empty house list.');
  }
}

// Helper zum Speichern der Houses-Liste auf die Festplatte (nur wenn kein Supabase genutzt wird)
function saveHousesToFile() {
  try {
    const replacer = (key, value) => {
      // Speichere Date-Objekte als ISO-Strings
      if (value instanceof Date) {
        return value.toISOString();
      }
      return value;
    };
    fs.writeFileSync(housesFilePath, JSON.stringify(houses, replacer, 2));
    console.log('💾 Houses saved to persistence file');
  } catch (e) {
    console.error('🔴 Failed to write houses.json:', e);
  }
}

// 🧑‍💻 Nutzerverwaltung
// Alle Benutzer werden entweder aus einer persistierten JSON‑Datei gelesen oder
// einmalig mit einem Demo‑Benutzer initialisiert. Dadurch bleiben Accounts
// auch nach einem Server‑Neustart bestehen. Das Demo‑Konto ist optional und
// dient nur zum schnellen Testen (E-Mail: demo@phasir.app, Passwort: test1234).

// 🗂️ Datei, in der Nutzer beim Fallback-Modus gespeichert werden.
const usersFilePath = './data/users.json';

// Wir definieren users als mutable Variable, damit neue Accounts angelegt
// und gespeichert werden können.
let users;

// Versuche, bestehende Benutzer aus dem Dateisystem zu laden. Falls keine
// Datei existiert, wird sie später beim ersten Speichern automatisch
// angelegt. In diesem Fall legen wir einen Demo‑Benutzer an, damit sich
// mindestens ein Konto anmelden lässt.
try {
  const userFileData = fs.readFileSync(usersFilePath, 'utf8');
  users = JSON.parse(userFileData);
  console.log(`✅ Loaded ${users.length} users from persistence file`);
} catch (err) {
  // Falls das Laden fehlschlägt oder die Datei fehlt, initialisiere mit einem
  // Demo‑Benutzer. Dieser kann anschließend gelöscht oder überschrieben
  // werden, sobald echte Nutzer registriert sind.
  users = [
    {
      id: uuid(),
      email: 'demo@phasir.app',
      passwordHash: bcrypt.hashSync('test1234', 10),
      createdAt: new Date().toISOString(),
    },
  ];
  console.log('ℹ️ No users.json found or failed to parse. Using demo user.');
}

// Hilfsfunktion zum Persistieren der Nutzerliste. Ruft man nach dem
// Registrieren eines neuen Kontos auf, werden die Daten dauerhaft in
// users.json gespeichert. Beim Einsatz von Supabase wird die Datei zwar
// geschrieben, sie hat dann aber keine praktische Wirkung.
function saveUsersToFile() {
  try {
    fs.writeFileSync(usersFilePath, JSON.stringify(users, null, 2));
    console.log('💾 Users saved to persistence file');
  } catch (e) {
    console.error('🔴 Failed to write users.json:', e);
  }
}

// 🗝️ Sessions: ordnen Tokens den Benutzer-IDs zu.
// Nach dem Login/Registrieren wird hier ein Eintrag abgelegt, damit wir den
// Benutzer anhand des "Authorization: Bearer <token>" Headers identifizieren können.
const sessions = [];

// 🔐 Authentication-Middleware: liest den Bearer-Token aus dem Header aus und setzt req.userId
app.use((req, _res, next) => {
  const auth = req.headers.authorization || req.headers.Authorization;
  if (auth && typeof auth === 'string' && auth.startsWith('Bearer ')) {
    const token = auth.replace(/^Bearer\s+/, '');
    const session = sessions.find((s) => s.token === token);
    if (session) {
      req.userId = session.userId;
    }
  }
  next();
});

// 👉 Mapping: Supabase-Row -> internes House-Objekt (camelCase)
const fromSupabaseRow = (row) => ({
  id: row.id,
  ownerId: row.ownerid ?? null,
  ownerName: row.ownername ?? 'Demo Nutzer',
  name: row.name,
  address: row.address,
  buildYear: row.buildyear,
  heatingType: row.heatingtype,
  heatingInstallYear: row.heatinginstallyear,
  lastHeatingService: row.lastheatingservice,
  roofInstallYear: row.roofinstallyear,
  lastRoofCheck: row.lastroofcheck,
  windowInstallYear: row.windowinstallyear,
  lastSmokeCheck: row.lastsmokecheck,

  // Koordinaten (Latitude/Longitude) – optional
  lat: row.lat ?? row.latitude ?? null,
  lng: row.lng ?? row.longitude ?? null,

  // --- Energieprofil ---
  livingArea: row.livingarea ?? null,
  numberOfFloors: row.numberoffloors ?? null,
  propertyType: row.propertytype ?? null,
  residentsCount: row.residentscount ?? null,
  locationType: row.locationtype ?? null,
  insulationLevel: row.insulationlevel ?? null,
  windowGlazing: row.windowglazing ?? null,
  roofType: row.rooftype ?? null,
  hasSolarPanels: row.hassolarpanels ?? null,
  energyCertificateClass: row.energycertificateclass ?? null,
  estimatedAnnualEnergyConsumption: row.estimatedannualenergyconsumption ?? null,
  typicalEmptyHoursPerDay: row.typicalemptyhoursperday ?? null,
  hasHomeOfficeUsage: row.hashomeofficeusage ?? null,
  comfortPreference: row.comfortpreference ?? null,

  // --- Sicherheitsprofil ---
  doorSecurityLevel: row.doorsecuritylevel ?? null,
  hasGroundFloorWindowSecurity: row.hasgroundfloorwindowsecurity ?? null,
  hasAlarmSystem: row.hasalarmsystem ?? null,
  hasCameras: row.hascameras ?? null,
  hasSmartLocks: row.hassmartlocks ?? null,
  hasMotionLightsOutside: row.hasmotionlightsoutside ?? null,
  hasSmokeDetectorsAllRooms: row.hassmokedetectorsallrooms ?? null,
  hasCO2Detector: row.hasco2detector ?? null,
  neighbourhoodRiskLevel: row.neighbourhoodrisklevel ?? null,

  // --- Nutzung & Finanzen ---
  usageType: row.usagetype ?? null,

  monthlyRentCold: row.monthlyrentcold ?? null,
  monthlyRentWarm: row.monthlyrentwarm ?? null,
  expectedVacancyRate: row.expectedvacancyrate ?? null,

  monthlyUtilities: row.monthlyutilities ?? null,
  monthlyHoaFees: row.monthlyhoafees ?? null,
  insurancePerYear: row.insuranceperyear ?? null,
  maintenanceBudgetPerYear: row.maintenancebudgetperyear ?? null,

  purchasePrice: row.purchaseprice ?? null,
  equity: row.equity ?? null,
  remainingLoanAmount: row.remainingloanamount ?? null,
  interestRate: row.interestrate ?? null,
  loanMonthlyPayment: row.loanmonthlypayment ?? null,
});

// sorgt dafür, dass Zahlen wirklich Zahlen sind (Jahreszahlen)
const ensureHouseNumbers = (house) => ({
  ...house,
  buildYear: Number(house.buildYear),
  heatingInstallYear: Number(house.heatingInstallYear),
  roofInstallYear: Number(house.roofInstallYear),
  windowInstallYear: Number(house.windowInstallYear),
  // Stelle sicher, dass Koordinaten als Zahlen vorliegen
  lat: house.lat !== undefined ? Number(house.lat) : house.lat,
  lng: house.lng !== undefined ? Number(house.lng) : house.lng,
});

// internes House-Objekt -> Supabase-Row
const toSupabasePayload = (house) => {
  const normalized = ensureHouseNumbers(house);
  return {
    id: normalized.id,
    ownerid: normalized.ownerId ?? null,
    ownername: normalized.ownerName,
    name: normalized.name,
    address: normalized.address,
    buildyear: normalized.buildYear,
    heatingtype: normalized.heatingType,
    heatinginstallyear: normalized.heatingInstallYear,
    lastheatingservice: normalized.lastHeatingService
      ? new Date(normalized.lastHeatingService).toISOString()
      : null,
    roofinstallyear: normalized.roofInstallYear,
    lastroofcheck: normalized.lastRoofCheck
      ? new Date(normalized.lastRoofCheck).toISOString()
      : null,
    windowinstallyear: normalized.windowInstallYear,
    lastsmokecheck: normalized.lastSmokeCheck
      ? new Date(normalized.lastSmokeCheck).toISOString()
      : null,

    // --- Energieprofil ---
    livingarea: normalized.livingArea ?? null,
    numberoffloors: normalized.numberOfFloors ?? null,
    propertytype: normalized.propertyType ?? null,
    residentscount: normalized.residentsCount ?? null,
    locationtype: normalized.locationType ?? null,
    insulationlevel: normalized.insulationLevel ?? null,
    windowglazing: normalized.windowGlazing ?? null,
    rooftype: normalized.roofType ?? null,
    hassolarpanels: normalized.hasSolarPanels ?? null,
    energycertificateclass: normalized.energyCertificateClass ?? null,
    estimatedannualenergyconsumption:
      normalized.estimatedAnnualEnergyConsumption ?? null,
    typicalemptyhoursperday: normalized.typicalEmptyHoursPerDay ?? null,
    hashomeofficeusage: normalized.hasHomeOfficeUsage ?? null,
    comfortpreference: normalized.comfortPreference ?? null,

    // --- Sicherheitsprofil ---
    doorsecuritylevel: normalized.doorSecurityLevel ?? null,
    hasgroundfloorwindowsecurity:
      normalized.hasGroundFloorWindowSecurity ?? null,
    hasalarmsystem: normalized.hasAlarmSystem ?? null,
    hascameras: normalized.hasCameras ?? null,
    hassmartlocks: normalized.hasSmartLocks ?? null,
    hasmotionlightsoutside: normalized.hasMotionLightsOutside ?? null,
    hassmokedetectorsallrooms:
      normalized.hasSmokeDetectorsAllRooms ?? null,
    hasco2detector: normalized.hasCO2Detector ?? null,
    neighbourhoodrisklevel: normalized.neighbourhoodRiskLevel ?? null,

    // --- Nutzung & Finanzen ---
    usagetype: normalized.usageType ?? null,

    monthlyrentcold: normalized.monthlyRentCold ?? null,
    monthlyrentwarm: normalized.monthlyRentWarm ?? null,
    expectedvacancyrate: normalized.expectedVacancyRate ?? null,

    monthlyutilities: normalized.monthlyUtilities ?? null,
    monthlyhoafees: normalized.monthlyHoaFees ?? null,
    insuranceperyear: normalized.insurancePerYear ?? null,
    maintenancebudgetperyear: normalized.maintenanceBudgetPerYear ?? null,

    purchaseprice: normalized.purchasePrice ?? null,
    equity: normalized.equity ?? null,
    remainingloanamount: normalized.remainingLoanAmount ?? null,
    interestrate: normalized.interestRate ?? null,
    loanmonthlypayment: normalized.loanMonthlyPayment ?? null,

    // Koordinaten, falls vorhanden
    lat: normalized.lat ?? null,
    lng: normalized.lng ?? null,
  };
};

const ensureHouseDates = (house) => ({
  ...house,
  lastHeatingService: house.lastHeatingService
    ? new Date(house.lastHeatingService)
    : null,
  lastRoofCheck: house.lastRoofCheck ? new Date(house.lastRoofCheck) : null,
  lastSmokeCheck: house.lastSmokeCheck ? new Date(house.lastSmokeCheck) : null,
});

const normalizeHouse = (house) => ensureHouseDates(ensureHouseNumbers(house));

const addYears = (date, years) => {
  const copy = new Date(date);
  copy.setFullYear(copy.getFullYear() + years);
  return copy;
};

const computeNext = (house) => ({
  heating: house.lastHeatingService
    ? addYears(house.lastHeatingService, intervals.heating)
    : null,
  roof: addYears(
    house.lastRoofCheck ?? `${house.roofInstallYear}-01-01`,
    intervals.roof
  ),
  windows: addYears(`${house.windowInstallYear}-01-01`, intervals.windows),
  smoke: house.lastSmokeCheck
    ? addYears(house.lastSmokeCheck, intervals.smoke)
    : null,
});

const serializeHouse = (house) => {
  const normalized = normalizeHouse(house);
  return {
    ...normalized,
    lastHeatingService: normalized.lastHeatingService?.toISOString() ?? null,
    lastRoofCheck: normalized.lastRoofCheck
      ? normalized.lastRoofCheck.toISOString()
      : null,
    lastSmokeCheck: normalized.lastSmokeCheck?.toISOString() ?? null,
    next: computeNext(normalized),
  };
};

// ---------- Energie-"KI" (Heuristik) ----------

const computeEnergyAdvice = (house) => {
  let score = 50;
  const insights = [];
  const recommendedActions = [];

  // Baujahr
  if (house.buildYear < 1980) {
    score -= 10;
    insights.push(
      'Das Gebäude ist vor 1980 gebaut – hier besteht oft großes Dämmpotenzial.'
    );
    recommendedActions.push(
      'Energieberatung vor Ort für Dämmung von Fassade, Dach und Kellerdecke durchführen lassen.'
    );
  } else if (house.buildYear > 2005) {
    score += 5;
    insights.push(
      'Relativ modernes Baujahr – die Bausubstanz ist meist energetisch besser als der Durchschnitt.'
    );
  }

  // Dämmstandard
  if (house.insulationLevel) {
    const lvl = house.insulationLevel.toLowerCase();
    if (lvl.includes('kfw') || lvl.includes('gut')) {
      score += 15;
      insights.push('Der Dämmstandard ist bereits sehr gut.');
    } else if (lvl.includes('unsaniert')) {
      score -= 15;
      insights.push(
        'Unsanierte Gebäude verlieren viel Wärme über Fassade, Dach und Keller.'
      );
      recommendedActions.push(
        'Schrittweise Sanierung planen: zuerst Dach, danach Fassade und Fenster.'
      );
    } else if (lvl.includes('teilsaniert')) {
      score -= 5;
      insights.push(
        'Teilsanierung vorhanden – hier liegen noch weitere Einsparpotenziale.'
      );
    }
  }

  // Fenster
  if (house.windowGlazing) {
    const glazing = house.windowGlazing.toLowerCase();
    if (glazing.includes('dreifach')) {
      score += 15;
      insights.push('Dreifachverglasung reduziert Wärmeverluste deutlich.');
    } else if (glazing.includes('zweifach')) {
      score += 5;
      insights.push(
        'Zweifachverglasung ist solide – ein Wechsel auf dreifach kann in manchen Fällen sinnvoll sein.'
      );
    } else if (glazing.includes('einfach')) {
      score -= 10;
      insights.push(
        'Einfachverglasung verursacht große Wärmeverluste – hier besteht ein sehr großes Einsparpotenzial.'
      );
      recommendedActions.push(
        'Fenster schrittweise durch moderne, gut gedämmte Modelle ersetzen.'
      );
    }
  }

  // Solar
  if (house.hasSolarPanels === true) {
    score += 10;
    insights.push('Es ist bereits eine PV-/Solaranlage installiert.');
  } else if (house.hasSolarPanels === false) {
    insights.push(
      'Es ist derzeit keine PV-/Solaranlage installiert – je nach Dachausrichtung könnte hier Potenzial liegen.'
    );
    recommendedActions.push(
      'Wirtschaftlichkeit einer PV-Anlage prüfen (Dachfläche, Ausrichtung, Verschattung).'
    );
  }

  // Homeoffice
  if (house.hasHomeOfficeUsage === true) {
    insights.push(
      'Durch Homeoffice entstehen höhere Heiz- und Stromlaufzeiten tagsüber.'
    );
    recommendedActions.push(
      'Raumweise Heizungssteuerung und zeitabhängige Temperaturabsenkung prüfen.'
    );
  }

  // Jahresverbrauch
  let potentialSavingsKwh = null;
  let potentialSavingsEuro = null;

  if (house.estimatedAnnualEnergyConsumption) {
    const annual = Number(house.estimatedAnnualEnergyConsumption);
    let factor = 0.2;
    if (score < 50) factor = 0.3;
    if (score > 70) factor = 0.15;

    potentialSavingsKwh = Math.round(annual * factor);
    const assumedPricePerKwh = 0.3;
    potentialSavingsEuro = Math.round(potentialSavingsKwh * assumedPricePerKwh);

    insights.push(
      `Auf Basis deines angegebenen Verbrauchs könnten etwa ${potentialSavingsKwh} kWh pro Jahr eingespart werden.`
    );
    recommendedActions.push(
      'Konkrete Maßnahmen priorisieren (Dämmung, Fenstertausch, Heizungsoptimierung), um das Einsparpotenzial zu heben.'
    );
  }

  score = Math.max(0, Math.min(100, score));

  let grade = 'D';
  let summary = 'Deutliches Einsparpotenzial vorhanden.';

  if (score >= 80) {
    grade = 'A';
    summary = 'Sehr effizientes Energieprofil – nur noch Feintuning nötig.';
  } else if (score >= 60) {
    grade = 'B';
    summary = 'Gutes Niveau, dennoch sind weitere Optimierungen möglich.';
  } else if (score >= 40) {
    grade = 'C';
    summary = 'Solide Basis, aber mit klaren Einsparmöglichkeiten.';
  }

  return {
    score: grade,
    numericScore: score,
    summary,
    insights,
    recommendedActions,
    potentialSavingsKwh,
    potentialSavingsEuro,
  };
};

// ---------- ECHTE ENERGIE-KI MIT OPENAI ----------

async function generateEnergyAdviceWithAI(house) {
  // Wenn kein OpenAI-Key → alte Heuristik
  if (!openai) return computeEnergyAdvice(house);

  const systemPrompt =
    'Du bist ein erfahrener Energieberater in Deutschland. ' +
    'Du analysierst Wohngebäude auf Energieeffizienz und Einsparpotenziale. ' +
    'Antworte immer im JSON-Format. Keine Fließtexte außerhalb von JSON.';

  const userPrompt = `
Analysiere dieses Wohngebäude energetisch und gib konkrete Einsparpotenziale an.

Input-Hausdaten (JSON):
${JSON.stringify(house, null, 2)}

Erstelle eine Antwort GENAU in diesem JSON-Format:

{
  "score": "A" | "B" | "C" | "D" | "E" | "F" | "G",
  "numericScore": 0-100,
  "summary": "Kurze Zusammenfassung der Lage in 1–3 Sätzen.",
  "insights": ["Stichpunkt 1", "Stichpunkt 2", "..."],
  "recommendedActions": ["Maßnahme 1", "Maßnahme 2", "..."],
  "potentialSavingsKwh": number | null,
  "potentialSavingsEuro": number | null
}

Regeln:
- Schreibe auf Deutsch.
- Sei realistisch und konservativ mit Einsparschätzungen.
- Wenn du keine sinnvolle Schätzung machen kannst, setze potentialSavingsKwh/potentialSavingsEuro auf null.
`;

  const completion = await openai.chat.completions.create({
    model: 'gpt-4.1-mini',
    response_format: { type: 'json_object' },
    messages: [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userPrompt },
    ],
  });

  const content = completion.choices[0]?.message?.content || '{}';

  let parsed;
  try {
    parsed = JSON.parse(content);
  } catch (err) {
    console.error(
      '🔴 Konnte AI-JSON für Energy Advice nicht parsen, fallback:',
      err
    );
    return computeEnergyAdvice(house);
  }

  const fallback = computeEnergyAdvice(house);

  return {
    score: parsed.score || fallback.score,
    numericScore:
      typeof parsed.numericScore === 'number'
        ? parsed.numericScore
        : fallback.numericScore,
    summary: parsed.summary || fallback.summary,
    insights:
      Array.isArray(parsed.insights) && parsed.insights.length
        ? parsed.insights
        : fallback.insights,
    recommendedActions:
      Array.isArray(parsed.recommendedActions) &&
      parsed.recommendedActions.length
        ? parsed.recommendedActions
        : fallback.recommendedActions,
    potentialSavingsKwh:
      typeof parsed.potentialSavingsKwh === 'number'
        ? parsed.potentialSavingsKwh
        : fallback.potentialSavingsKwh,
    potentialSavingsEuro:
      typeof parsed.potentialSavingsEuro === 'number'
        ? parsed.potentialSavingsEuro
        : fallback.potentialSavingsEuro,
  };
}

// ---------- PROBLEM-DIAGNOSE-KI ----------

async function generateProblemAnalysisWithAI(house, description) {
  // Fallback-Heuristik, falls kein OpenAI konfiguriert ist
  if (!openai) {
    const text = (description || '').toLowerCase();
    let category = 'general';
    if (
      text.includes('heiz') ||
      text.includes('radiator') ||
      text.includes('wärme')
    ) {
      category = 'heating';
    } else if (
      text.includes('wasser') ||
      text.includes('leitung') ||
      text.includes('rohr')
    ) {
      category = 'water';
    } else if (
      text.includes('strom') ||
      text.includes('elektr') ||
      text.includes('sicherung')
    ) {
      category = 'electric';
    } else if (text.includes('dach') || text.includes('regen')) {
      category = 'roof';
    } else if (
      text.includes('schimmel') ||
      text.includes('feucht') ||
      text.includes('nass')
    ) {
      category = 'humidity';
    }

    return {
      category,
      urgency: 3,
      likelyCause:
        'Basierend auf einer einfachen Heuristik geschätzte Ursache.',
      recommendedAction:
        'Lass die genaue Ursache von einem passenden Fachbetrieb prüfen. Nutze die vorgeschlagenen Dienstleister in deiner Umgebung.',
      firstAidSteps: FIRST_AID_STEPS[category] || FIRST_AID_STEPS.general,
    };
  }

  const systemPrompt =
    'Du bist ein erfahrener Gebäudetechniker und Hausmeister-Profi in Deutschland. ' +
    'Du analysierst Probleme in Wohngebäuden und ordnest sie klaren Kategorien zu (heating, water, plumbing, roof, electric, humidity, energy, general). ' +
    'Antworte ausschließlich im JSON-Format, ohne Fließtext außen herum.';

  const userPrompt = `
Der Nutzer beschreibt ein Problem in seinem Haus.

Hausdaten (JSON):
${JSON.stringify(house, null, 2)}

Problembeschreibung:
"${description}"

Gib genau dieses JSON-Format zurück:

{
  "category": "heating" | "water" | "plumbing" | "roof" | "electric" | "humidity" | "energy" | "general",
  "urgency": 1-5,
  "likelyCause": "Kurzbeschreibung der wahrscheinlichen Ursache.",
  "recommendedAction": "Konkrete Empfehlung, was der Eigentümer jetzt tun sollte."
}

Regeln:
- Schreibe auf Deutsch.
- Sei realistisch bei der Einschätzung der Dringlichkeit.
- Wenn die Kategorie unklar ist, verwende "general".
`;

  const completion = await openai.chat.completions.create({
    model: 'gpt-4.1-mini',
    response_format: { type: 'json_object' },
    messages: [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userPrompt },
    ],
  });

  const content = completion.choices[0]?.message?.content || '{}';

  let parsed;
  try {
    parsed = JSON.parse(content);
  } catch (err) {
    console.error(
      '🔴 Konnte AI-JSON für Problem-Analyse nicht parsen, fallback:',
      err
    );
    return {
      category: 'general',
      urgency: 3,
      likelyCause:
        'Die KI konnte keine eindeutige Analyse durchführen.',
      recommendedAction:
        'Lass die genaue Ursache von einem passenden Fachbetrieb prüfen. Nutze die vorgeschlagenen Dienstleister in deiner Umgebung.',
      firstAidSteps: FIRST_AID_STEPS.general,
    };
  }

  return {
    category: parsed.category || 'general',
    urgency: typeof parsed.urgency === 'number' ? parsed.urgency : 3,
    likelyCause:
      parsed.likelyCause || 'Keine genaue Ursache ermittelt.',
    recommendedAction:
      parsed.recommendedAction ||
      'Lass die genaue Ursache von einem passenden Fachbetrieb prüfen.',
    firstAidSteps:
      FIRST_AID_STEPS[parsed.category] || FIRST_AID_STEPS.general,
  };
}

// ---------- Mietspiegel / Markt-Benchmark ----------

// grobe Heuristik für Markt-Miete je m²
const estimateMarketRentPerSqm = (house) => {
  let base = 10.5; // grober Deutschland-Durchschnitt in €/m²

  const address = (house.address || '').toLowerCase();
  const propertyType = (house.propertyType || '').toLowerCase();

  // Großstadt-Bonus
  if (
    address.includes('berlin') ||
    address.includes('münchen') ||
    address.includes('hamburg') ||
    address.includes('köln') ||
    address.includes('frankfurt')
  ) {
    base += 2.0;
  }

  // Baujahr-Effekt
  if (house.buildYear > 2015) {
    base += 1.0;
  } else if (house.buildYear < 1980) {
    base -= 0.5;
  }

  // Haus vs. Wohnung
  if (propertyType.includes('haus')) {
    base -= 0.5;
  } else if (propertyType.includes('wohnung')) {
    base += 0.3;
  }

  // sehr große Fläche -> etwas niedriger
  if (house.livingArea && house.livingArea > 120) {
    base -= 0.3;
  }

  return Number(base.toFixed(2));
};

const emptyRentBenchmark = {
  portfolio: {
    averageRentPerSqm: null,
    estimatedMarketRentPerSqm: null,
    averageDeviationPercent: null,
    rating: 'Keine Daten',
    summary:
      'Es liegen noch keine ausreichenden Angaben zu Kaltmiete und Wohnfläche vor.',
  },
  houses: [],
  recommendations: [
    'Hinterlege bei mindestens einer Immobilie Wohnfläche und Kaltmiete.',
    'Nutze Nutzungstyp „Vermietet“, „Gewerblich“ oder „Kurzzeitvermietung“ für einen sinnvolleren Vergleich.',
  ],
};

const computeRentBenchmark = (housesList) => {
  const relevant = (housesList || []).filter(
    (h) =>
      h.livingArea &&
      h.monthlyRentCold &&
      h.livingArea > 0 &&
      h.monthlyRentCold > 0
  );

  if (relevant.length === 0) {
    return emptyRentBenchmark;
  }

  const houseEntries = relevant.map((h) => {
    const rentPerSqm = h.monthlyRentCold / h.livingArea;
    const market = estimateMarketRentPerSqm(h);
    const deviationPercent = ((rentPerSqm - market) / market) * 100;

    let rating = 'Im Rahmen';
    if (deviationPercent < -10) rating = 'Unter Markt';
    else if (deviationPercent > 10) rating = 'Über Markt';

    return {
      id: h.id,
      name: h.name,
      address: h.address,
      livingArea: h.livingArea,
      monthlyRentCold: h.monthlyRentCold,
      rentPerSqm: Number(rentPerSqm.toFixed(2)),
      estimatedMarketRentPerSqm: Number(market.toFixed(2)),
      deviationPercent: Number(deviationPercent.toFixed(1)),
      rating,
    };
  });

  const avgRentPerSqm =
    houseEntries.reduce((sum, e) => sum + e.rentPerSqm, 0) /
    houseEntries.length;

  const avgMarketPerSqm =
    houseEntries.reduce(
      (sum, e) => sum + e.estimatedMarketRentPerSqm,
      0
    ) / houseEntries.length;

  const avgDeviationPercent =
    ((avgRentPerSqm - avgMarketPerSqm) / avgMarketPerSqm) * 100;

  let rating = 'Im Rahmen';
  let summary =
    'Deine Mieten bewegen sich im Rahmen des geschätzten regionalen Mietniveaus.';

  if (avgDeviationPercent < -10) {
    rating = 'Unter Markt';
    summary =
      'Deine Mieten liegen im Schnitt deutlich unter dem geschätzten regionalen Mietniveau.';
  } else if (avgDeviationPercent > 10) {
    rating = 'Über Markt';
    summary =
      'Deine Mieten liegen im Schnitt deutlich über dem geschätzten regionalen Mietniveau.';
  }

  const recommendations = [];

  if (rating === 'Unter Markt') {
    recommendations.push(
      'Prüfe, ob moderate Mieterhöhungen im Rahmen des Mietrechts möglich sind.',
      'Vergleiche deine Mieten mit dem lokalen Mietspiegel und ähnlichen Objekten in der Umgebung.'
    );
  } else if (rating === 'Über Markt') {
    recommendations.push(
      'Stelle sicher, dass Ausstattung und Zustand der Objekte das Mietniveau rechtfertigen.',
      'Plane Leerstandspuffer ein, falls sich der Markt abkühlt oder Konkurrenz günstiger wird.'
    );
  } else {
    recommendations.push(
      'Halte dein Mietniveau regelmäßig mit dem Marktvergleich aktuell (alle 12–24 Monate).'
    );
  }

  return {
    portfolio: {
      averageRentPerSqm: Number(avgRentPerSqm.toFixed(2)),
      estimatedMarketRentPerSqm: Number(avgMarketPerSqm.toFixed(2)),
      averageDeviationPercent: Number(avgDeviationPercent.toFixed(1)),
      rating,
      summary,
    },
    houses: houseEntries,
    recommendations,
  };
};

// ---------- Payload-Parser ----------

const parseHousePayload = (payload) => {
  // Bestimme ein sinnvolles Baujahr (Default: aktuelles Jahr)
  const currentYear = new Date().getFullYear();
  const buildYearRaw = payload.buildYear !== undefined && payload.buildYear !== null && payload.buildYear !== '' ? Number(payload.buildYear) : null;
  const buildYear = Number.isFinite(buildYearRaw) ? buildYearRaw : currentYear;

  // Installationsjahre, fallen auf das Baujahr zurück, falls nicht angegeben
  const heatingInstallRaw = payload.heatingInstallYear !== undefined && payload.heatingInstallYear !== null && payload.heatingInstallYear !== '' ? Number(payload.heatingInstallYear) : null;
  const heatingInstallYear = Number.isFinite(heatingInstallRaw) ? heatingInstallRaw : buildYear;
  const roofInstallRaw = payload.roofInstallYear !== undefined && payload.roofInstallYear !== null && payload.roofInstallYear !== '' ? Number(payload.roofInstallYear) : null;
  const roofInstallYear = Number.isFinite(roofInstallRaw) ? roofInstallRaw : buildYear;
  const windowInstallRaw = payload.windowInstallYear !== undefined && payload.windowInstallYear !== null && payload.windowInstallYear !== '' ? Number(payload.windowInstallYear) : null;
  const windowInstallYear = Number.isFinite(windowInstallRaw) ? windowInstallRaw : buildYear;

  // Dates: falls nicht angegeben, null oder sinnvolle Defaults
  const lastHeatingService = payload.lastHeatingService ?? null;
  // Wenn lastRoofCheck nicht gesetzt, verwende das Dach-Installationsjahr
  const lastRoofCheck = payload.lastRoofCheck ?? `${roofInstallYear}-01-01`;
  const lastSmokeCheck = payload.lastSmokeCheck ?? null;

  return {
    ownerId: payload.ownerId ?? null,
    ownerName: payload.ownerName ?? 'Demo Nutzer',
    // Leere oder fehlende Namen werden zu "Neue Immobilie"
    name:
      payload.name && String(payload.name).trim()
        ? String(payload.name).trim()
        : 'Neue Immobilie',
    // Adresse darf leer sein; Standardwert ist leerer String
    address: payload.address ?? '',
    buildYear,
    heatingType: payload.heatingType ?? '',
    heatingInstallYear,
    lastHeatingService,
    roofInstallYear,
    lastRoofCheck,
    windowInstallYear,
    lastSmokeCheck,

    // --- Energieprofil ---
    livingArea: payload.livingArea ?? null,
    numberOfFloors: payload.numberOfFloors ?? null,
    propertyType: payload.propertyType ?? null,
    residentsCount: payload.residentsCount ?? null,
    locationType: payload.locationType ?? null,
    insulationLevel: payload.insulationLevel ?? null,
    windowGlazing: payload.windowGlazing ?? null,
    roofType: payload.roofType ?? null,
    hasSolarPanels: payload.hasSolarPanels ?? null,
    energyCertificateClass: payload.energyCertificateClass ?? null,
    estimatedAnnualEnergyConsumption:
      payload.estimatedAnnualEnergyConsumption ?? null,
    typicalEmptyHoursPerDay: payload.typicalEmptyHoursPerDay ?? null,
    hasHomeOfficeUsage: payload.hasHomeOfficeUsage ?? null,
    comfortPreference: payload.comfortPreference ?? null,

    // --- Sicherheitsprofil ---
    doorSecurityLevel: payload.doorSecurityLevel ?? null,
    hasGroundFloorWindowSecurity:
      payload.hasGroundFloorWindowSecurity ?? null,
    hasAlarmSystem: payload.hasAlarmSystem ?? null,
    hasCameras: payload.hasCameras ?? null,
    hasSmartLocks: payload.hasSmartLocks ?? null,
    hasMotionLightsOutside: payload.hasMotionLightsOutside ?? null,
    hasSmokeDetectorsAllRooms: payload.hasSmokeDetectorsAllRooms ?? null,
    hasCO2Detector: payload.hasCO2Detector ?? null,
    neighbourhoodRiskLevel: payload.neighbourhoodRiskLevel ?? null,

    // --- Nutzung & Finanzen ---
    usageType: payload.usageType ?? null,

    monthlyRentCold: payload.monthlyRentCold ?? null,
    monthlyRentWarm: payload.monthlyRentWarm ?? null,
    expectedVacancyRate: payload.expectedVacancyRate ?? null,

    monthlyUtilities: payload.monthlyUtilities ?? null,
    monthlyHoaFees: payload.monthlyHoaFees ?? null,
    insurancePerYear: payload.insurancePerYear ?? null,
    maintenanceBudgetPerYear: payload.maintenanceBudgetPerYear ?? null,

    purchasePrice: payload.purchasePrice ?? null,
    equity: payload.equity ?? null,
    remainingLoanAmount: payload.remainingLoanAmount ?? null,
    interestRate: payload.interestRate ?? null,
    loanMonthlyPayment: payload.loanMonthlyPayment ?? null,

    // Optional: Koordinaten, wenn der Client sie liefert
    lat: payload.lat ?? payload.latitude ?? null,
    lng: payload.lng ?? payload.longitude ?? null,
  };
};

// ---------- DB Funktionen ----------

const fetchAllHouses = async (ownerId) => {
  if (!supabase) {
    // 🔧 Fallback: In-Memory-Daten, aber mit ownerId-Filter
    console.log('⚙️ Using in-memory houses, ownerId filter =', ownerId);

    let result = houses;

    if (ownerId) {
      result = houses.filter((h) => h.ownerId === ownerId);
    }

    return result.map(normalizeHouse);
  }

  console.log('🗄️ Using Supabase, ownerId filter =', ownerId);

  let query = supabase.from(SUPABASE_TABLE).select('*');

  if (ownerId) {
    query = query.eq('ownerid', ownerId);
  }

  const { data, error } = await query;

  if (error) {
    console.error('🔴 Supabase fetchAllHouses failed:', error);
    throw new Error(`Supabase fetchAllHouses failed: ${error.message}`);
  }

  return data.map(fromSupabaseRow).map(normalizeHouse);
};

const fetchHouseById = async (id) => {
  if (!supabase) return houses.find((h) => h.id === id) ?? null;

  const { data, error } = await supabase
    .from(SUPABASE_TABLE)
    .select('*')
    .eq('id', id)
    .single();

  if (error && error.code !== 'PGRST116') {
    console.error('🔴 Supabase fetchHouseById failed:', error);
    throw new Error(`Supabase fetchHouseById failed: ${error.message}`);
  }

  return data ? normalizeHouse(fromSupabaseRow(data)) : null;
};

const createHouse = async (payload) => {
  const house = { id: uuid(), ...parseHousePayload(payload) };

  if (!supabase) {
    houses.push(house);
    return house;
  }

  const { data, error } = await supabase
    .from(SUPABASE_TABLE)
    .insert(toSupabasePayload(house))
    .select()
    .single();

  if (error) {
    console.error('🔴 Supabase createHouse failed:', error);
    throw new Error(`Supabase createHouse failed: ${error.message}`);
  }

  return normalizeHouse(fromSupabaseRow(data));
};

const updateHouseById = async (id, payload) => {
  if (!supabase) {
    const house = houses.find((h) => h.id === id);
    if (!house) return null;
    const updates = parseHousePayload({ ...house, ...payload });
    Object.assign(house, updates);
    return house;
  }

  const existing = await fetchHouseById(id);
  if (!existing) return null;

  const merged = {
    id,
    ...existing,
    ...parseHousePayload({ ...existing, ...payload }),
  };

  const { data, error } = await supabase
    .from(SUPABASE_TABLE)
    .update(toSupabasePayload(merged))
    .eq('id', id)
    .select()
    .single();

  if (error) {
    console.error('🔴 Supabase updateHouseById failed:', error);
    throw new Error(`Supabase updateHouseById failed: ${error.message}`);
  }

  return normalizeHouse(fromSupabaseRow(data));
};

// ---------- Helpers ----------

const asyncRoute = (handler) => async (req, res) => {
  try {
    await handler(req, res);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// ---------- Routes ----------

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', supabase: Boolean(supabase) });
});

app.get(
  '/houses',
  asyncRoute(async (req, res) => {
    // Nutze vorrangig die userId aus dem Bearer-Token, falls vorhanden.
    // Falls kein Token gesetzt ist, kann ownerId als Query-Parameter übergeben werden (z.B. für Admins).
    // Erlaube den Zugriff nur, wenn der Benutzer authentifiziert ist. Ohne gültigen Bearer‑Token
    // soll keine Hausliste ausgeliefert werden (ansonsten würden Demo‑Objekte oder fremde Objekte angezeigt).
    const ownerId = req.userId || req.query.ownerId || null;
    if (!ownerId) {
      return res.status(401).json({ error: 'Nicht authentifiziert.' });
    }
    const result = await fetchAllHouses(ownerId);
    res.json(result.map(serializeHouse));
  })
);

app.get(
  '/houses/:id',
  asyncRoute(async (req, res) => {
    const house = await fetchHouseById(req.params.id);
    if (!house)
      return res.status(404).json({ error: 'House not found' });
    res.json(serializeHouse(house));
  })
);

app.post(
  '/houses',
  asyncRoute(async (req, res) => {
    // nur angemeldete Nutzer dürfen neue Häuser anlegen
    const userId = req.userId;
    if (!userId) {
      return res.status(401).json({ error: 'Nicht authentifiziert.' });
    }

    // Bestimme den aktuellen Benutzername (z. B. E-Mail als Besitzername). Falls der User nicht
    // gefunden wird, verwende einen generischen Platzhalter. Wir ignorieren ownerId aus dem
    // Request-Body und setzen ihn immer auf den eingeloggten Nutzer. Dadurch kann kein
    // User versehentlich die Zuordnung manipulieren.
    const user = users.find((u) => u.id === userId);
    const ownerName = user ? user.email : 'Unbekannter Eigentümer';
    const payload = { ...req.body, ownerId: userId, ownerName };

    // Erzeuge das Haus ohne strikte Feldvalidierung. Fehlende Werte
    // werden in parseHousePayload mit sinnvollen Defaults belegt (z. B. "Neue Immobilie" als Name).
    const house = await createHouse(payload);

    // Persistiere ins Dateisystem, falls kein Supabase vorhanden ist
    if (!supabase) {
      saveHousesToFile();
    }

    res.status(201).json(serializeHouse(house));
  })
);

app.put(
  '/houses/:id',
  asyncRoute(async (req, res) => {
    const userId = req.userId;
    if (!userId) {
      return res.status(401).json({ error: 'Nicht authentifiziert.' });
    }
    const existing = await fetchHouseById(req.params.id);
    if (!existing) {
      return res.status(404).json({ error: 'House not found' });
    }
    // Verhindere, dass ein Nutzer ein Haus aktualisiert, das ihm nicht gehört
    if (existing.ownerId && existing.ownerId !== userId) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    // Setze ownerId und ownerName immer auf den eingeloggten Nutzer, damit die Zuordnung konsistent bleibt
    const user = users.find((u) => u.id === userId);
    const ownerName = user ? user.email : 'Unbekannter Eigentümer';
    const payload = { ...req.body, ownerId: userId, ownerName };
    const house = await updateHouseById(req.params.id, payload);
    if (!house) {
      return res.status(404).json({ error: 'House not found' });
    }
    if (!supabase) {
      saveHousesToFile();
    }
    res.json(serializeHouse(house));
  })
);

// ---------- Wetterwarnungen ----------
// Gibt eine Liste von Wetterwarnungen (via Bright‑Sky) für die angegebene Haus‑ID zurück.
// Die Immobilie muss Koordinaten (lat/lng) besitzen. Wenn das nicht der Fall ist,
// wird eine leere Liste zurückgegeben. Bei Supabase‑Betrieb sollte die Tabelle
// entsprechende Spalten für Latitude und Longitude enthalten und in fetchHouseById
// integriert sein.
app.get(
  '/weather-alerts/:houseId',
  asyncRoute(async (req, res) => {
    const houseId = req.params.houseId;
    let house;
    // Nutze Supabase wenn verfügbar, sonst In-Memory
    if (supabase) {
      house = await fetchHouseById(houseId);
    } else {
      house = houses.find((h) => h.id === houseId);
    }
    if (!house) {
      return res.status(404).json({ alerts: [] });
    }
    // Stelle sicher, dass Koordinaten vorhanden sind
    const lat = house.lat;
    const lon = house.lng || house.lon;
    if (!lat || !lon) {
      return res.json({ alerts: [] });
    }
    try {
      const url = `https://api.brightsky.dev/alerts?lat=${lat}&lon=${lon}&tz=Europe/Berlin`;
      const response = await fetch(url);
      if (!response.ok) {
        console.error('🔴 BrightSky responded with status:', response.status);
        return res.status(502).json({ alerts: [] });
      }
      const data = await response.json();
      const alerts = data.alerts || [];
      res.json({ alerts });
    } catch (error) {
      console.error('🔴 Error fetching weather alerts:', error);
      res.status(500).json({ alerts: [] });
    }
  })
);

// ---------- AI ENDPOINTS ----------

app.post(
  '/ai/energy-advice',
  asyncRoute(async (req, res) => {
    const { houseId } = req.body || {};
    if (!houseId) {
      return res
        .status(400)
        .json({ error: 'houseId is required' });
    }

    const house = await fetchHouseById(houseId);
    if (!house) {
      return res.status(404).json({ error: 'House not found' });
    }

    try {
      const advice = await generateEnergyAdviceWithAI(house);
      res.json(advice);
    } catch (error) {
      console.error(
        'Error in /ai/energy-advice, fallback to heuristic:',
        error
      );
      const advice = computeEnergyAdvice(house);
      res.json(advice);
    }
  })
);

// Mietspiegel / Markt-Benchmark
app.post(
  '/ai/rent-benchmark',
  asyncRoute(async (req, res) => {
    const { ownerId } = req.body || {};
    console.log('📊 /ai/rent-benchmark ownerId =', ownerId);

    // Fallback: wenn irgendwas schief ist, lieber 200 + "Keine Daten" zurückgeben
    if (!ownerId) {
      return res.json(emptyRentBenchmark);
    }

    const userHouses = await fetchAllHouses(ownerId);
    console.log(
      '📊 /ai/rent-benchmark houses found =',
      userHouses.length
    );

    const result = computeRentBenchmark(userHouses);
    res.json(result);
  })
);

// 🧠 ---------- PROBLEM-DIAGNOSE ENDPOINT ----------
app.post(
  '/ai/problem-diagnosis',
  asyncRoute(async (req, res) => {
    const { houseId, description } = req.body || {};

    if (!houseId || !description) {
      return res
        .status(400)
        .json({ error: 'houseId und description sind erforderlich.' });
    }

    const house = await fetchHouseById(houseId);
    if (!house) {
      return res.status(404).json({ error: 'House not found' });
    }

    const analysis = await generateProblemAnalysisWithAI(
      house,
      description
    );

    // ein wenig angereicherte Antwort für die App
    res.json({
      category: analysis.category,
      urgency: analysis.urgency,
      likelyCause: analysis.likelyCause,
      recommendedAction: analysis.recommendedAction,
      firstAidSteps: analysis.firstAidSteps || [],
      houseName: house.name,
      houseAddress: house.address,
    });
  })
);

// 🗺️ ---------- DIENSTLEISTER-SUCHE / VENDOR MAP ----------

const CATEGORY_TO_QUERY = {
  heating: 'Heizungsbauer',
  water: 'Sanitär Notdienst',
  plumbing: 'Sanitär Installateur',
  roof: 'Dachdecker',
  electric: 'Elektriker',
  humidity: 'Schimmel Sanierung',
  energy: 'Energieberatung',
  general: 'Hausmeister Service',
};

// 🆘 Erste-Hilfe-Anleitungen je Kategorie
// Diese Anweisungen werden dem Nutzer als Sofortmaßnahmen angezeigt, bevor ein Fachbetrieb kontaktiert wird.
const FIRST_AID_STEPS = {
  heating: [
    'Heizung ausschalten und abkühlen lassen.',
    'Sichtprüfung auf offensichtliche Lecks oder Beschädigungen durchführen.',
    'Falls Wasser austritt: Hauptwasserzufuhr abschalten.',
    'Fachbetrieb kontaktieren, bevor Sie die Anlage wieder einschalten.',
  ],
  water: [
    'Hauptwasserhahn sofort schließen, um weitere Schäden zu vermeiden.',
    'Elektrische Geräte in der Nähe ausschalten.',
    'Eimer oder Handtücher bereitstellen, um auslaufendes Wasser aufzufangen.',
    'Schäden dokumentieren (Fotos) für die Versicherung.',
  ],
  plumbing: [
    'Wasserzufuhr an der betroffenen Leitung abstellen.',
    'Stark tropfende Stellen provisorisch abdichten (z. B. mit einem Lappen).',
    'Keine Chemikalien in den Abfluss gießen.',
    'Fachbetrieb kontaktieren, um den Schaden professionell zu beheben.',
  ],
  roof: [
    'Sichern Sie lose Dachziegel, sofern gefahrlos möglich.',
    'Betreten Sie das Dach nur, wenn absolut nötig und sicher.',
    'Beobachten Sie eindringendes Wasser im Inneren und stellen Sie Eimer bereit.',
    'Bei Sturm oder Starkregen: Bereiche unter dem Dach frei räumen.',
  ],
  electric: [
    'Strom am Sicherungskasten für den betroffenen Bereich abschalten.',
    'Keine Steckdosen oder Kabel anfassen.',
    'Bei Brandgeruch: Feuermelder alarmieren und gegebenenfalls Feuerwehr rufen.',
    'Fachbetrieb oder Elektriker kontaktieren.',
  ],
  humidity: [
    'Räume lüften, um Feuchtigkeit zu reduzieren.',
    'Betroffene Bereiche trocken wischen und ggf. Heizung einschalten.',
    'Schimmelbefall nicht direkt berühren – Schutzmaske tragen.',
    'Fachbetrieb für Schimmelbeseitigung kontaktieren.',
  ],
  energy: [
    'Nicht benötigte Geräte ausschalten, um Energieverbrauch zu senken.',
    'Temperatur in Räumen moderat einstellen.',
    'Fenster und Türen schließen, um Wärme zu halten.',
    'Energieberater konsultieren für weitere Maßnahmen.',
  ],
  general: [
    'Ruhe bewahren und Gefahrenquelle absichern.',
    'Fotos des Problems zur Dokumentation machen.',
    'Betroffene Personen aus dem Gefahrenbereich entfernen.',
    'Fachbetrieb kontaktieren und Versicherung informieren.',
  ],
};

app.get(
  '/vendors/search',
  asyncRoute(async (req, res) => {
    const { category, address } = req.query || {};

    if (!category || !address) {
      return res
        .status(400)
        .json({ error: 'category und address sind erforderlich.' });
    }

    const queryLabel =
      CATEGORY_TO_QUERY[category] || CATEGORY_TO_QUERY.general;

    // Kein Places-Key -> Demo-Daten zurückgeben
    if (!GOOGLE_PLACES_API_KEY) {
      return res.json({
        vendors: [
          {
            id: 'demo-1',
            name: `${queryLabel} Musterbetrieb`,
            lat: 50.0,
            lng: 8.0,
            rating: 4.7,
            phone: null,
            website: null,
            address: `In der Nähe von ${address}`,
            distanceKm: null,
          },
          {
            id: 'demo-2',
            name: `${queryLabel} & Sohn`,
            lat: 50.01,
            lng: 8.02,
            rating: 4.5,
            phone: null,
            website: null,
            address: `Region ${address}`,
            distanceKm: null,
          },
        ],
      });
    }

    const url = new URL(
      'https://maps.googleapis.com/maps/api/place/textsearch/json'
    );
    url.search = new URLSearchParams({
      query: `${queryLabel} in der Nähe von ${address}`,
      key: GOOGLE_PLACES_API_KEY,
      language: 'de',
      region: 'de',
    }).toString();

    const response = await fetch(url);
    if (!response.ok) {
      console.error(
        '🔴 Places API responded with status:',
        response.status
      );
      return res.status(502).json({
        error: 'Failed to fetch vendors from Google Places API',
      });
    }

    const data = await response.json();
    const results = data.results || [];

    // Für jede gefundene Location (max. 10) optional Details abrufen (Telefon, Website)
    const vendors = await Promise.all(
      results.slice(0, 10).map(async (place) => {
        let phone = null;
        let website = place.website ?? null;
        if (place.place_id && GOOGLE_PLACES_API_KEY) {
          try {
            const detailsUrl = new URL(
              'https://maps.googleapis.com/maps/api/place/details/json'
            );
            detailsUrl.search = new URLSearchParams({
              place_id: place.place_id,
              key: GOOGLE_PLACES_API_KEY,
              fields: 'formatted_phone_number,website',
            }).toString();
            const detailsRes = await fetch(detailsUrl);
            if (detailsRes.ok) {
              const detailsData = await detailsRes.json();
              const details = detailsData.result || {};
              phone = details.formatted_phone_number || null;
              website = details.website || website;
            }
          } catch (err) {
            console.error(
              '🔴 Fehler beim Abruf von Place-Details:',
              place.place_id,
              err
            );
          }
        }
        return {
          id: place.place_id || place.id || place.reference,
          name: place.name,
          lat: place.geometry?.location?.lat ?? null,
          lng: place.geometry?.location?.lng ?? null,
          rating: place.rating ?? null,
          phone,
          website,
          address: place.formatted_address ?? null,
          distanceKm: null,
        };
      })
    );

    // Nach Bewertung sortieren (höchste zuerst)
    vendors.sort((a, b) => {
      const ra = a.rating || 0;
      const rb = b.rating || 0;
      return rb - ra;
    });

    res.json({ vendors });
  })
);

// ---------- Heuristische Problemradar-Funktion ----------
// Analysiert Alter und Wartungszustände verschiedener Systeme eines Hauses
// und gibt eine Liste möglicher Probleme zurück, sortiert nach Priorität.
function computeProblemRadarForHouse(house) {
  const issues = [];
  const now = new Date();
  const currentYear = now.getFullYear();

  // Heizungsanlage – typischer Austausch nach 15–20 Jahren
  const heatingAge = currentYear - (house.heatingInstallYear || house.buildYear);
  if (heatingAge >= 15) {
    issues.push({
      system: 'heating',
      summary: 'Die Heizungsanlage ist älter als 15 Jahre.',
      recommendation: 'Wartung oder Austausch in Betracht ziehen.',
      severity: heatingAge >= 20 ? 'high' : 'medium',
      projectedYear: currentYear + 1,
    });
  }

  // Dach – Wartung alle 5 Jahre, Austausch nach ca. 20–30 Jahren
  const roofAge = currentYear - (house.roofInstallYear || house.buildYear);
  if (roofAge >= 20) {
    issues.push({
      system: 'roof',
      summary: 'Das Dach ist älter als 20 Jahre.',
      recommendation: 'Dachinspektion und mögliche Sanierung planen.',
      severity: roofAge >= 30 ? 'high' : 'medium',
      projectedYear: currentYear + 1,
    });
  }

  // Fenster – Austausch nach 20 Jahren
  const windowAge = currentYear - (house.windowInstallYear || house.buildYear);
  if (windowAge >= 20) {
    issues.push({
      system: 'windows',
      summary: 'Die Fenster sind älter als 20 Jahre.',
      recommendation: 'Fenster prüfen und ggf. austauschen lassen.',
      severity: windowAge >= 25 ? 'medium' : 'low',
      projectedYear: currentYear + 2,
    });
  }

  // Rauchmelder – jährliche Wartung
  if (house.lastSmokeCheck) {
    const lastSmokeCheckDate = new Date(house.lastSmokeCheck);
    const nextSmokeDue = new Date(lastSmokeCheckDate);
    nextSmokeDue.setFullYear(nextSmokeDue.getFullYear() + 1);
    if (nextSmokeDue < now) {
      issues.push({
        system: 'smoke',
        summary: 'Rauchmelder warten',
        recommendation: 'Wartung oder Batteriewechsel durchführen.',
        severity: 'medium',
        projectedYear: now.getFullYear(),
      });
    }
  }

  // Wartungsintervalle aus "next"-Feld berücksichtigen
  if (house.next) {
    ['heating', 'roof', 'windows', 'smoke'].forEach((key) => {
      const nextDate = house.next[key];
      if (nextDate) {
        const due = new Date(nextDate);
        if (due < now) {
          issues.push({
            system: key,
            summary: `Überfällige Wartung: ${key}`,
            recommendation: 'Wartung zeitnah durchführen.',
            severity: 'high',
            projectedYear: due.getFullYear(),
          });
        }
      }
    });
  }

  return issues;
}

// 🧭 ---------- PROBLEM-RADAR ENDPOINT ----------
// Liefert prognostizierte Probleme für alle Häuser des Nutzers oder für ein einzelnes Haus
app.get(
  '/ai/problem-radar',
  asyncRoute(async (req, res) => {
    const { ownerId, houseId } = req.query || {};
    // Einzelnes Haus anfragen
    if (houseId) {
      const house = await fetchHouseById(houseId);
      if (!house) {
        return res.status(404).json({ error: 'House not found' });
      }
      const issues = computeProblemRadarForHouse(house);
      return res.json({
        houseId: house.id,
        houseName: house.name,
        issues,
      });
    }
    // Alle Häuser eines Nutzers abrufen; ownerId kann optional sein
    const housesList = await fetchAllHouses(ownerId || null);
    const result = housesList.map((h) => ({
      houseId: h.id,
      houseName: h.name,
      issues: computeProblemRadarForHouse(h),
    }));
    res.json({ houses: result });
  })
);

// ---------- AUTH ENDPOINTS (Register & Login mit Passwort) ----------

// Registrierung
app.post(
  '/auth/register',
  asyncRoute(async (req, res) => {
    const { email, password } = req.body || {};

    if (!email || !password) {
      res.status(400).json({
        error: 'E-Mail und Passwort sind erforderlich.',
      });
      return;
    }

    const normalizedEmail = String(email).trim().toLowerCase();

    // existiert schon?
    const existing = users.find((u) => u.email === normalizedEmail);
    if (existing) {
      res.status(409).json({
        error: 'Für diese E-Mail existiert bereits ein Konto.',
      });
      return;
    }

    if (password.length < 8) {
      res.status(400).json({
        error: 'Passwort muss mindestens 8 Zeichen haben.',
      });
      return;
    }

    const passwordHash = await bcrypt.hash(password, 10);

    const newUser = {
      id: uuid(),
      email: normalizedEmail,
      passwordHash,
      createdAt: new Date().toISOString(),
    };

    users.push(newUser);

    // Persistiere den neuen Benutzer ins Dateisystem (unabhängig von Supabase). Dadurch bleiben Konten
    // auch nach einem Server-Neustart bestehen. Fehlschläge werden protokolliert.
    saveUsersToFile();

    const token = `sess-${uuid()}`;
    // Lege eine neue Session ab, damit der Token später dem User zugeordnet werden kann
    sessions.push({ token, userId: newUser.id });

    res.status(201).json({
      token,
      userId: newUser.id,
      email: newUser.email,
    });
  })
);

// Login
app.post(
  '/auth/login',
  asyncRoute(async (req, res) => {
    const { email, password } = req.body || {};

    if (!email || !password) {
      res.status(400).json({
        error: 'E-Mail und Passwort sind erforderlich.',
      });
      return;
    }

    const normalizedEmail = String(email).trim().toLowerCase();
    const user = users.find((u) => u.email === normalizedEmail);

    if (!user) {
      // kein User mit dieser Mail
      res.status(401).json({
        error:
          'Diese Kombination aus E-Mail und Passwort ist nicht gültig.',
      });
      return;
    }

    const isValid = await bcrypt.compare(
      password,
      user.passwordHash
    );
    if (!isValid) {
      res.status(401).json({
        error:
          'Diese Kombination aus E-Mail und Passwort ist nicht gültig.',
      });
      return;
    }

    const token = `sess-${uuid()}`;
    // Lege eine neue Session ab, damit der Token später dem User zugeordnet werden kann
    sessions.push({ token, userId: user.id });

    res.json({
      token,
      userId: user.id,
      email: user.email,
    });
  })
);

// 🆕 ---------- REAL ESTATE NEWS ENDPOINT (mit fetch) ----------

app.get(
  '/news/real-estate',
  asyncRoute(async (req, res) => {
    // Optional: Filter aus Query übernehmen
    const { language = 'de', q = 'Immobilien OR Wohnungmarkt OR Miete' } =
      req.query || {};

    // Wenn keine API konfiguriert ist -> elegante Demo-Antwort
    if (!NEWS_API_BASE_URL || !NEWS_API_KEY) {
      return res.json({
        source: 'demo',
        articles: [
          {
            id: 'demo-1',
            title:
              'Wohnungsmieten in deutschen Großstädten stabilisieren sich',
            summary:
              'Aktuelle Marktberichte zeigen, dass sich die Angebotsmieten in vielen Metropolen seit einigen Monaten seitwärts bewegen.',
            source: 'Phasir Insights (Demo)',
            url: null,
            imageUrl: null,
            publishedAt: new Date().toISOString(),
          },
          {
            id: 'demo-2',
            title:
              'Energieeffiziente Sanierungen rücken bei Eigentümern stärker in den Fokus',
            summary:
              'Getrieben durch Energiepreise und Förderprogramme investieren immer mehr Eigentümer in Dämmung und moderne Heizsysteme.',
            source: 'Phasir Insights (Demo)',
            url: null,
            imageUrl: null,
            publishedAt: new Date().toISOString(),
          },
        ],
      });
    }

    // Richtiger API-Call mit fetch
    const url = new URL(NEWS_API_BASE_URL);
    url.search = new URLSearchParams({
      apiKey: NEWS_API_KEY,
      q: String(q),
      language: String(language),
      sortBy: 'publishedAt',
      pageSize: '10',
    }).toString();

    const response = await fetch(url);
    if (!response.ok) {
      console.error(
        '🔴 News API responded with status:',
        response.status
      );
      return res.status(502).json({
        error: 'Failed to fetch news from upstream API',
      });
    }

    const data = await response.json();
    const rawArticles = data.articles || data.data || [];

    const articles = rawArticles.map((a, idx) => ({
      id: a.id || a.url || `news-${idx}`,
      title: a.title,
      summary: a.description || a.summary || '',
      source: a.source?.name || a.source || null,
      url: a.url || null,
      imageUrl: a.imageUrl || a.image_url || a.urlToImage || null,
      publishedAt: a.publishedAt || a.published_at || null,
    }));

    res.json({
      source: 'live',
      articles,
    });
  })
);

app.listen(PORT, () => {
  console.log(`Phasir API listening on http://localhost:${PORT}`);
});