import express from 'express';
import cors from 'cors';
import { v4 as uuid } from 'uuid';
import { createClient } from '@supabase/supabase-js';

const PORT = process.env.PORT || 4000;
const app = express();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY;
const supabase = supabaseUrl && supabaseKey ? createClient(supabaseUrl, supabaseKey) : null;
const SUPABASE_TABLE = 'houses';

app.use(cors());
app.use(express.json());

const intervals = {
  heating: 2,
  roof: 4,
  windows: 15,
  smoke: 1,
};

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

const ensureHouseNumbers = (house) => ({
  ...house,
  buildYear: Number(house.buildYear),
  heatingInstallYear: Number(house.heatingInstallYear),
  roofInstallYear: Number(house.roofInstallYear),
  windowInstallYear: Number(house.windowInstallYear),
});

const ensureHouseDates = (house) => ({
  ...house,
  lastHeatingService: new Date(house.lastHeatingService),
  lastRoofCheck: house.lastRoofCheck ? new Date(house.lastRoofCheck) : null,
  lastSmokeCheck: new Date(house.lastSmokeCheck),
});

const normalizeHouse = (house) => ensureHouseDates(ensureHouseNumbers(house));

const addYears = (date, years) => {
  const copy = new Date(date);
  copy.setFullYear(copy.getFullYear() + years);
  return copy;
};

const computeNext = (house) => ({
  heating: addYears(house.lastHeatingService, intervals.heating),
  roof: addYears(house.lastRoofCheck ?? `${house.roofInstallYear}-01-01`, intervals.roof),
  windows: addYears(`${house.windowInstallYear}-01-01`, intervals.windows),
  smoke: addYears(house.lastSmokeCheck, intervals.smoke),
});

const serializeHouse = (house) => {
  const normalized = normalizeHouse(house);
  return {
    ...normalized,
    lastHeatingService: normalized.lastHeatingService.toISOString(),
    lastRoofCheck: normalized.lastRoofCheck ? normalized.lastRoofCheck.toISOString() : null,
    lastSmokeCheck: normalized.lastSmokeCheck.toISOString(),
    next: computeNext(normalized),
  };
};

const parseHousePayload = (payload) => ({
  ownerName: payload.ownerName ?? 'Demo Nutzer',
  name: payload.name,
  address: payload.address,
  buildYear: Number(payload.buildYear),
  heatingType: payload.heatingType,
  heatingInstallYear: Number(payload.heatingInstallYear),
  lastHeatingService: new Date(payload.lastHeatingService),
  roofInstallYear: Number(payload.roofInstallYear),
  lastRoofCheck: payload.lastRoofCheck ? new Date(payload.lastRoofCheck) : new Date(`${payload.roofInstallYear}-01-01`),
  windowInstallYear: Number(payload.windowInstallYear),
  lastSmokeCheck: new Date(payload.lastSmokeCheck),
});

const toSupabasePayload = (house) => {
  const normalized = normalizeHouse(house);
  return {
    id: house.id,
    ownerName: normalized.ownerName,
    name: normalized.name,
    address: normalized.address,
    buildYear: normalized.buildYear,
    heatingType: normalized.heatingType,
    heatingInstallYear: normalized.heatingInstallYear,
    lastHeatingService: normalized.lastHeatingService.toISOString(),
    roofInstallYear: normalized.roofInstallYear,
    lastRoofCheck: normalized.lastRoofCheck ? normalized.lastRoofCheck.toISOString() : null,
    windowInstallYear: normalized.windowInstallYear,
    lastSmokeCheck: normalized.lastSmokeCheck.toISOString(),
  };
};

const fetchAllHouses = async () => {
  if (!supabase) return houses;

  const { data, error } = await supabase.from(SUPABASE_TABLE).select('*');
  if (error) {
    throw new Error(`Supabase fetchAllHouses failed: ${error.message}`);
  }

  return data.map(normalizeHouse);
};

const fetchHouseById = async (id) => {
  if (!supabase) return houses.find((h) => h.id === id) ?? null;

  const { data, error } = await supabase.from(SUPABASE_TABLE).select('*').eq('id', id).single();
  if (error && error.code !== 'PGRST116') {
    throw new Error(`Supabase fetchHouseById failed: ${error.message}`);
  }

  return data ? normalizeHouse(data) : null;
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
    throw new Error(`Supabase createHouse failed: ${error.message}`);
  }

  return normalizeHouse(data);
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

  const merged = { id, ...existing, ...parseHousePayload({ ...existing, ...payload }) };
  const { data, error } = await supabase
    .from(SUPABASE_TABLE)
    .update(toSupabasePayload(merged))
    .eq('id', id)
    .select()
    .single();

  if (error) {
    throw new Error(`Supabase updateHouseById failed: ${error.message}`);
  }

  return normalizeHouse(data);
};

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', supabase: Boolean(supabase) });
});

app.get('/houses', async (_req, res) => {
  try {
    const result = await fetchAllHouses();
    res.json(result.map(serializeHouse));
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Failed to fetch houses' });
  }
});

app.get('/houses/:id', async (req, res) => {
  try {
    const house = await fetchHouseById(req.params.id);
    if (!house) return res.status(404).json({ error: 'House not found' });
    res.json(serializeHouse(house));
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Failed to fetch house' });
  }
});

app.post('/houses', async (req, res) => {
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
    return res.status(400).json({ error: `Missing fields: ${missing.join(', ')}` });
  }

  try {
    const house = await createHouse(req.body);
    res.status(201).json(serializeHouse(house));
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Failed to create house' });
  }
});

app.put('/houses/:id', async (req, res) => {
  try {
    const house = await updateHouseById(req.params.id, req.body);
    if (!house) return res.status(404).json({ error: 'House not found' });
    res.json(serializeHouse(house));
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Failed to update house' });
  }
});

app.listen(PORT, () => {
  console.log(`Phasir API listening on http://localhost:${PORT}`);
});
