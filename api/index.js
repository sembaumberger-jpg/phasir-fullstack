import dotenv from 'dotenv';
dotenv.config();

import cors from 'cors';
import express from 'express';
import { v4 as uuid } from 'uuid';
import { createClient } from '@supabase/supabase-js';
import OpenAI from 'openai';
import bcrypt from 'bcryptjs'; // 🔐 Passwort-Hashing

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

// In-Memory Demo-Daten (Fallback, falls Supabase nicht konfiguriert ist)
const houses = [
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
  },
];

// 🧑‍💻 In-Memory-User (für Entwicklung)
// Achtung: wird bei jedem Server-Neustart zurückgesetzt.
// Passwort für Demo-User: "test1234"
const users = [
  {
    id: uuid(),
    email: 'demo@phasir.app',
    passwordHash: bcrypt.hashSync('test1234', 10),
    createdAt: new Date().toISOString(),
  },
];

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
      likelyCause: 'Die KI konnte keine eindeutige Analyse durchführen.',
      recommendedAction:
        'Lass die genaue Ursache von einem passenden Fachbetrieb prüfen. Nutze die vorgeschlagenen Dienstleister in deiner Umgebung.',
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

const parseHousePayload = (payload) => ({
  ownerId: payload.ownerId ?? null,
  ownerName: payload.ownerName ?? 'Demo Nutzer',
  name: payload.name,
  address: payload.address,
  buildYear: Number(payload.buildYear),
  heatingType: payload.heatingType,
  heatingInstallYear: Number(payload.heatingInstallYear),
  lastHeatingService: payload.lastHeatingService,
  roofInstallYear: Number(payload.roofInstallYear),
  lastRoofCheck: payload.lastRoofCheck || `${payload.roofInstallYear}-01-01`,
  windowInstallYear: Number(payload.windowInstallYear),
  lastSmokeCheck: payload.lastSmokeCheck,

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
});

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
    const ownerId = req.query.ownerId || null;
    const result = await fetchAllHouses(ownerId);
    res.json(result.map(serializeHouse));
  })
);

app.get(
  '/houses/:id',
  asyncRoute(async (req, res) => {
    const house = await fetchHouseById(req.params.id);
    if (!house) return res.status(404).json({ error: 'House not found' });
    res.json(serializeHouse(house));
  })
);

app.post(
  '/houses',
  asyncRoute(async (req, res) => {
    const required = [
      'name',
      'address',
      'buildYear',
      'heatingType',
      'heatingInstallYear',
      'lastHeatingService',
      'roofInstallYear',
      'windowInstallYear',
      'lastSmokeCheck',
    ];
    const missing = required.filter((key) => !req.body?.[key]);
    if (missing.length) {
      return res.status(400).json({
        error: `Missing fields: ${missing.join(', ')}`,
      });
    }

    const house = await createHouse(req.body);
    res.status(201).json(serializeHouse(house));
  })
);

app.put(
  '/houses/:id',
  asyncRoute(async (req, res) => {
    const house = await updateHouseById(req.params.id, req.body);
    if (!house) return res.status(404).json({ error: 'House not found' });
    res.json(serializeHouse(house));
  })
);

// ---------- AI ENDPOINTS ----------

app.post(
  '/ai/energy-advice',
  asyncRoute(async (req, res) => {
    const { houseId } = req.body || {};
    if (!houseId) {
      return res.status(400).json({ error: 'houseId is required' });
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
    console.log('📊 /ai/rent-benchmark houses found =', userHouses.length);

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

    const analysis = await generateProblemAnalysisWithAI(house, description);

    // ein wenig angereicherte Antwort für die App
    res.json({
      category: analysis.category,
      urgency: analysis.urgency,
      likelyCause: analysis.likelyCause,
      recommendedAction: analysis.recommendedAction,
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

    const vendors = results.slice(0, 10).map((place) => ({
      id: place.place_id || place.id || place.reference,
      name: place.name,
      lat: place.geometry?.location?.lat ?? null,
      lng: place.geometry?.location?.lng ?? null,
      rating: place.rating ?? null,
      phone: null, // könnte über Place Details ergänzt werden
      website: place.website ?? null,
      address: place.formatted_address ?? null,
      distanceKm: null, // könnte berechnet werden, wenn du die Haus-Koordinate kennst
    }));

    res.json({ vendors });
  })
);

// ---------- AUTH ENDPOINTS (Register & Login mit Passwort) ----------

// Registrierung
app.post(
  '/auth/register',
  asyncRoute(async (req, res) => {
    const { email, password } = req.body || {};

    if (!email || !password) {
      res
        .status(400)
        .json({ error: 'E-Mail und Passwort sind erforderlich.' });
      return;
    }

    const normalizedEmail = String(email).trim().toLowerCase();

    // existiert schon?
    const existing = users.find((u) => u.email === normalizedEmail);
    if (existing) {
      res.status(409).json({ error: 'Für diese E-Mail existiert bereits ein Konto.' });
      return;
    }

    if (password.length < 8) {
      res
        .status(400)
        .json({ error: 'Passwort muss mindestens 8 Zeichen haben.' });
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

    const token = `sess-${uuid()}`;

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
      res.status(400).json({ error: 'E-Mail und Passwort sind erforderlich.' });
      return;
    }

    const normalizedEmail = String(email).trim().toLowerCase();
    const user = users.find((u) => u.email === normalizedEmail);

    if (!user) {
      // kein User mit dieser Mail
      res
        .status(401)
        .json({
          error: 'Diese Kombination aus E-Mail und Passwort ist nicht gültig.',
        });
      return;
    }

    const isValid = await bcrypt.compare(password, user.passwordHash);
    if (!isValid) {
      res
        .status(401)
        .json({
          error: 'Diese Kombination aus E-Mail und Passwort ist nicht gültig.',
        });
      return;
    }

    const token = `sess-${uuid()}`;

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
      return res
        .status(502)
        .json({ error: 'Failed to fetch news from upstream API' });
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
