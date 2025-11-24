const API_BASE = "http://localhost:4000";

const features = [
  {
    title: "Login & Mobile Dashboard",
    description:
      "E-Mail + Passwort oder Magic Link, danach persönliches Dashboard mit allen eigenen Häusern und Wartungen.",
    tags: ["Auth", "Personalisierung", "Mobile"],
  },
  {
    title: "Handy-Datei-Safe",
    description:
      "Eigenen PDF- oder Foto-Nachweise pro Haus sicher ablegen. Zugriff nur nach Login, jede Datei bekommt einen Owner.",
    tags: ["Secure Storage", "Files", "Owner-bound"],
  },
  {
    title: "Haus-Detail",
    description:
      "Adresse, Baujahr, Heizungsart, Historie der letzten Services und nächste Termine für jedes Gewerk – optimiert für kleine Screens.",
    tags: ["Historie", "Next Steps", "Timeline"],
  },
  {
    title: "Haus-Formular",
    description:
      "Eingabe von Installation & letzten Checks für Heizung, Dach, Fenster, Rauchmelder – Next wird automatisch berechnet.",
    tags: ["Form", "Validierung", "Auto-Berechnung"],
  },
  {
    title: "Benachrichtigungen",
    description: "Expo Notifications oder FCM erinnern 30 Tage vor Fälligkeit. Für den Prototyp simuliert das Frontend Badges.",
    tags: ["Push", "Reminder", "Optional"],
  },
  {
    title: "Analytics",
    description: "Wartungs-Timeline und Budget-Preview als Chart (react-native-chart-kit oder Victory Native).",
    tags: ["Charts", "Budget", "Planung"],
  },
];

const fallbackHouses = [
  {
    id: "h1",
    ownerEmail: "lisa@phasir.app",
    name: "Stadtvilla Rheinblick",
    address: "Rheinufer 12, Köln",
    buildYear: 2008,
    heatingType: "Gas",
    heatingInstallYear: 2015,
    lastHeatingService: "2023-05-10",
    roofInstallYear: 2016,
    lastRoofCheck: "2022-07-01",
    windowInstallYear: 2018,
    lastSmokeCheck: "2024-06-12",
  },
  {
    id: "h2",
    ownerEmail: "tom@phasir.app",
    name: "Alpen Chalet",
    address: "Talweg 5, Garmisch",
    buildYear: 1995,
    heatingType: "Wärmepumpe",
    heatingInstallYear: 2020,
    lastHeatingService: "2022-11-03",
    roofInstallYear: 2018,
    lastRoofCheck: "2023-09-15",
    windowInstallYear: 2015,
    lastSmokeCheck: "2023-12-01",
  },
  {
    id: "h3",
    ownerEmail: "mara@phasir.app",
    name: "Stadthaus Mitte",
    address: "Chausseestraße 21, Berlin",
    buildYear: 2012,
    heatingType: "Fernwärme",
    heatingInstallYear: 2012,
    lastHeatingService: "2024-01-18",
    roofInstallYear: 2012,
    lastRoofCheck: "2021-04-20",
    windowInstallYear: 2017,
    lastSmokeCheck: "2024-04-09",
  },
];

const demoUsers = {
  "lisa@phasir.app": {
    name: "Lisa Rhein",
    password: "demo123",
    files: [
      { name: "Heizung_Service_2023.pdf", type: "PDF", size: "380 KB" },
      { name: "Energieausweis.png", type: "Bild", size: "1.1 MB" },
    ],
  },
  "tom@phasir.app": {
    name: "Tom Berger",
    password: "demo123",
    files: [
      { name: "Dachcheck_2023.pdf", type: "PDF", size: "220 KB" },
      { name: "SmartHome-Plan.jpg", type: "Bild", size: "890 KB" },
    ],
  },
  "mara@phasir.app": {
    name: "Mara Schulz",
    password: "demo123",
    files: [
      { name: "Fensterrechnung.pdf", type: "PDF", size: "640 KB" },
      { name: "Rauchmelder_Checkliste.docx", type: "Docx", size: "120 KB" },
    ],
  },
};

let sessionUser = null;
let houseState = [...fallbackHouses];

const featureGrid = document.getElementById("feature-grid");
const houseGrid = document.getElementById("house-grid");
const vaultGrid = document.getElementById("file-vault");
const loginForm = document.getElementById("login-form");
const loginFeedback = document.getElementById("login-feedback");
const sessionBadge = document.getElementById("session-badge");
const sessionLogout = document.getElementById("session-logout");

function renderFeatures() {
  featureGrid.innerHTML = "";
  features.forEach((feature) => {
    const card = document.createElement("article");
    card.className = "card";
    card.innerHTML = `
      <div class="card__body">
        <div class="card__meta">
          <h3>${feature.title}</h3>
          <span class="badge">Frontend</span>
        </div>
        <p class="muted">${feature.description}</p>
        <div class="pill-row">
          ${feature.tags.map((tag) => `<span class="pill">${tag}</span>`).join("")}
        </div>
      </div>
    `;
    featureGrid.appendChild(card);
  });
}

function addYears(date, years) {
  const copy = new Date(date);
  copy.setFullYear(copy.getFullYear() + years);
  return copy;
}

function formatDate(date) {
  return new Intl.DateTimeFormat("de-DE", { year: "numeric", month: "2-digit", day: "2-digit" }).format(date);
}

const toDate = (value) => (value instanceof Date ? value : new Date(value));

function computeNext(house) {
  const heatingBase = toDate(house.lastHeatingService);
  const roofBase = house.lastRoofCheck ? toDate(house.lastRoofCheck) : new Date(`${house.roofInstallYear}-01-01`);
  const windowBase = new Date(`${house.windowInstallYear}-01-01`);
  const smokeBase = toDate(house.lastSmokeCheck);

  return {
    heating: addYears(heatingBase, 2),
    roof: addYears(roofBase, 4),
    windows: addYears(windowBase, 15),
    smoke: addYears(smokeBase, 1),
  };
}

function daysUntil(date) {
  const today = new Date();
  const diff = date.getTime() - today.getTime();
  return Math.round(diff / (1000 * 60 * 60 * 24));
}

function statusPill(days) {
  if (days <= 30) return '<span class="pill warning">Bald fällig</span>';
  if (days <= 120) return '<span class="pill success">Geplant</span>';
  return '<span class="pill">OK</span>';
}

function renderHouses(list = houseState) {
  houseGrid.innerHTML = "";
  if (!sessionUser) {
    houseGrid.innerHTML = '<p class="muted placeholder">Melde dich an, um deine hinterlegten Häuser zu sehen.</p>';
    return;
  }

  if (!list.length) {
    houseGrid.innerHTML = '<p class="muted placeholder">Keine Häuser gefunden. Lege dein erstes Objekt an.</p>';
    return;
  }

  list.forEach((house) => {
    const next = house.next || computeNext(house);
    const card = document.createElement("article");
    card.className = "card";
    card.innerHTML = `
      <img src="https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=1200&q=80" alt="${house.name}" />
      <div class="card__body">
        <div class="card__meta">
          <h3>${house.name}</h3>
          <span class="badge">${house.heatingType}</span>
        </div>
        <p class="muted">${house.address} • Baujahr ${house.buildYear}</p>
        <div class="pill-row">
          <span class="pill">Heizung: ${formatDate(toDate(next.heating))}</span>
          ${statusPill(daysUntil(toDate(next.heating)))}
        </div>
        <div class="pill-row">
          <span class="pill">Dach: ${formatDate(toDate(next.roof))}</span>
          ${statusPill(daysUntil(toDate(next.roof)))}
        </div>
        <div class="pill-row">
          <span class="pill">Fenster: ${formatDate(toDate(next.windows))}</span>
          ${statusPill(daysUntil(toDate(next.windows)))}
        </div>
        <div class="pill-row">
          <span class="pill">Rauchmelder: ${formatDate(toDate(next.smoke))}</span>
          ${statusPill(daysUntil(toDate(next.smoke)))}
        </div>
      </div>
      <div class="card__footer">
        <div>
          <strong>Letzte Services</strong>
          <div class="muted">Heizung ${formatDate(toDate(house.lastHeatingService))} • Rauchmelder ${formatDate(toDate(
            house.lastSmokeCheck
          ))}</div>
        </div>
        <button class="btn btn--ghost">Details öffnen</button>
      </div>
    `;
    houseGrid.appendChild(card);
  });
}

function renderVault(files = []) {
  if (!vaultGrid) return;
  vaultGrid.innerHTML = "";

  if (!sessionUser) {
    vaultGrid.innerHTML = '<p class="muted placeholder">Login erforderlich, um deinen Datei-Safe zu öffnen.</p>';
    return;
  }

  if (!files.length) {
    vaultGrid.innerHTML = '<p class="muted placeholder">Noch keine Dateien hochgeladen.</p>';
    return;
  }

  files.forEach((file) => {
    const card = document.createElement("article");
    card.className = "card file-card";
    card.innerHTML = `
      <div class="card__body">
        <div class="card__meta">
          <h3>${file.name}</h3>
          <span class="badge">${file.type}</span>
        </div>
        <p class="muted">${file.size} • Eigentümer: ${sessionUser.name}</p>
        <div class="pill-row">
          <span class="pill">Passwort geschützt</span>
          <span class="pill">Mobile Ready</span>
        </div>
      </div>
    `;
    vaultGrid.appendChild(card);
  });
}

function filterHousesForUser(user) {
  if (!user) return [];
  return houseState.filter((house) => {
    if (house.ownerEmail) return house.ownerEmail === user.email;
    if (house.ownerName && user.name) return house.ownerName.includes(user.name.split(" ")[0]);
    return true;
  });
}

function updateSessionUI() {
  if (!sessionBadge || !sessionLogout) return;
  if (sessionUser) {
    sessionBadge.textContent = `${sessionUser.name} • ${sessionUser.email}`;
    sessionBadge.classList.remove("hidden");
    sessionLogout.classList.remove("hidden");
  } else {
    sessionBadge.textContent = "Nicht angemeldet";
    sessionBadge.classList.add("hidden");
    sessionLogout.classList.add("hidden");
  }
}

async function loadHouses() {
  try {
    const response = await fetch(`${API_BASE}/houses`);
    if (!response.ok) throw new Error('API not reachable');
    const apiHouses = await response.json();
    houseState = apiHouses.map((house, index) => ({
      ...house,
      ownerEmail: fallbackHouses[index % fallbackHouses.length]?.ownerEmail ?? `api-user-${index}@phasir.app`,
    }));
  } catch (error) {
    console.warn('API unreachable, falling back to static data', error);
    houseState = fallbackHouses;
  }

  const userHouses = filterHousesForUser(sessionUser);
  renderHouses(userHouses);
}

function setupHouseForm() {
  const form = document.getElementById('house-form');
  const feedback = document.getElementById('house-feedback');
  if (!form) return;

  form.addEventListener('submit', async (event) => {
    event.preventDefault();
    feedback.textContent = 'Speichere...';

    const formData = new FormData(form);
    const payload = Object.fromEntries(formData.entries());
    if (!payload.lastRoofCheck) delete payload.lastRoofCheck;

    try {
      const response = await fetch(`${API_BASE}/houses`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      if (!response.ok) {
        const message = await response.json();
        throw new Error(message.error || 'Unbekannter Fehler');
      }

      const newHouse = await response.json();
      newHouse.ownerEmail = sessionUser?.email ?? newHouse.ownerEmail;
      houseState = [...houseState, newHouse];
      renderHouses(filterHousesForUser(sessionUser));
      feedback.textContent = 'Haus gespeichert und Wartungen berechnet!';
      form.reset();
    } catch (error) {
      console.error(error);
      const fallbackHouse = { ...payload, id: `local-${Date.now()}`, ownerEmail: sessionUser?.email };
      houseState = [...houseState, fallbackHouse];
      renderHouses(filterHousesForUser(sessionUser));
      feedback.textContent = 'API nicht erreichbar – nutze lokalen Fallback.';
    }
  });
}

function setupLogin() {
  if (!loginForm || !loginFeedback) return;

  loginForm.addEventListener('submit', (event) => {
    event.preventDefault();
    loginFeedback.textContent = 'Prüfe Zugang...';

    const formData = new FormData(loginForm);
    const email = String(formData.get('email') || '').toLowerCase();
    const password = formData.get('password');
    const user = demoUsers[email];

    if (!user || user.password !== password) {
      loginFeedback.textContent = 'Login fehlgeschlagen – nutze demo123 oder prüfe die E-Mail.';
      return;
    }

    sessionUser = { email, name: user.name };
    loginFeedback.textContent = `Eingeloggt als ${user.name}. Deine Daten sind geladen.`;
    const userHouses = filterHousesForUser(sessionUser);
    renderHouses(userHouses);
    renderVault(user.files);
    updateSessionUI();
    loginForm.reset();
  });

  if (sessionLogout) {
    sessionLogout.addEventListener('click', () => {
      sessionUser = null;
      loginFeedback.textContent = 'Abgemeldet.';
      renderHouses();
      renderVault();
      updateSessionUI();
    });
  }
}

renderFeatures();
setupLogin();
setupHouseForm();
loadHouses();
renderVault();
updateSessionUI();
