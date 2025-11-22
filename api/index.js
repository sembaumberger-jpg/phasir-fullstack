import express from 'express';
import cors from 'cors';
import { v4 as uuid } from 'uuid';

const PORT = process.env.PORT || 4000;
const app = express();

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

const serializeHouse = (house) => ({
  ...house,
  lastHeatingService: new Date(house.lastHeatingService).toISOString(),
  lastRoofCheck: house.lastRoofCheck ? new Date(house.lastRoofCheck).toISOString() : null,
  lastSmokeCheck: new Date(house.lastSmokeCheck).toISOString(),
  next: computeNext(house),
});

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

app.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});

app.get('/houses', (_req, res) => {
  res.json(houses.map(serializeHouse));
});

app.get('/houses/:id', (req, res) => {
  const house = houses.find((h) => h.id === req.params.id);
  if (!house) return res.status(404).json({ error: 'House not found' });
  res.json(serializeHouse(house));
});

app.post('/houses', (req, res) => {
  const required = ['name', 'address', 'buildYear', 'heatingType', 'heatingInstallYear', 'lastHeatingService', 'roofInstallYear', 'windowInstallYear', 'lastSmokeCheck'];
  const missing = required.filter((key) => !req.body?.[key]);
  if (missing.length) {
    return res.status(400).json({ error: `Missing fields: ${missing.join(', ')}` });
  }

  const house = {
    id: uuid(),
    ...parseHousePayload(req.body),
  };
  houses.push(house);
  res.status(201).json(serializeHouse(house));
});

app.put('/houses/:id', (req, res) => {
  const house = houses.find((h) => h.id === req.params.id);
  if (!house) return res.status(404).json({ error: 'House not found' });

  const updates = parseHousePayload({ ...house, ...req.body });
  Object.assign(house, updates);
  res.json(serializeHouse(house));
});

app.listen(PORT, () => {
  console.log(`Phasir API listening on http://localhost:${PORT}`);
});
