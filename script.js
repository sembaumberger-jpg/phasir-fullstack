const properties = [
  {
    id: "p1",
    title: "Skyline Loft",
    type: "Wohnung",
    location: "Frankfurt",
    price: 880000,
    yield: 3.2,
    size: 145,
    tags: ["Penthouse", "Erstbezug", "Smart Home"],
    image:
      "https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=1200&q=80",
  },
  {
    id: "p2",
    title: "Altbau Charme",
    type: "Wohnung",
    location: "Berlin",
    price: 520000,
    yield: 3.8,
    size: 92,
    tags: ["Stuck", "Balkon"],
    image:
      "https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=1200&q=80",
  },
  {
    id: "p3",
    title: "Family Home",
    type: "Haus",
    location: "Hamburg",
    price: 1250000,
    yield: 2.9,
    size: 210,
    tags: ["Garten", "Garage", "Neubau"],
    image:
      "https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=1200&q=80",
  },
  {
    id: "p4",
    title: "Quarter Office",
    type: "Gewerbe",
    location: "München",
    price: 1650000,
    yield: 4.4,
    size: 320,
    tags: ["Coworking", "Zentrumsnah"],
    image:
      "https://images.unsplash.com/photo-1484156818044-c040038b0710?auto=format&fit=crop&w=1200&q=80",
  },
  {
    id: "p5",
    title: "Rheinufer Haus",
    type: "Haus",
    location: "Köln",
    price: 990000,
    yield: 3.1,
    size: 180,
    tags: ["Wasserblick", "PV-Anlage"],
    image:
      "https://images.unsplash.com/photo-1481277542470-605612bd2d61?auto=format&fit=crop&w=1200&q=80",
  },
];

const grid = document.getElementById("property-grid");
const favoritesList = document.getElementById("favorites-list");
const clearFavorites = document.getElementById("clear-favorites");
const filterType = document.getElementById("filter-type");
const filterLocation = document.getElementById("filter-location");
const filterPrice = document.getElementById("filter-price");
const sortSelect = document.getElementById("sort-select");
const tradeSelect = document.getElementById("selected-property");
const tradeForm = document.getElementById("trade-form");
const tradeFeedback = document.getElementById("trade-feedback");

let favorites = new Map();

function formatPrice(value) {
  return value.toLocaleString("de-DE", { style: "currency", currency: "EUR", maximumFractionDigits: 0 });
}

function renderProperties(list) {
  grid.innerHTML = "";
  list.forEach((property) => {
    const card = document.createElement("article");
    card.className = "card";
    card.innerHTML = `
      <img src="${property.image}" alt="${property.title}" />
      <div class="card__body">
        <div class="card__meta">
          <h3>${property.title}</h3>
          <span class="badge">${property.yield}% Rendite</span>
        </div>
        <p class="muted">${property.size} m² • ${property.location} • ${property.type}</p>
        <div class="pill-row">
          ${property.tags.map((tag) => `<span class="pill">${tag}</span>`).join("")}
        </div>
      </div>
      <div class="card__footer">
        <div>
          <strong>${formatPrice(property.price)}</strong>
          <div class="muted">${(property.price / property.size).toFixed(0)} €/m²</div>
        </div>
        <button class="btn btn--ghost" data-id="${property.id}">Merken</button>
      </div>
    `;
    card.querySelector("button").addEventListener("click", () => toggleFavorite(property));
    grid.appendChild(card);
  });
}

function toggleFavorite(property) {
  if (favorites.has(property.id)) {
    favorites.delete(property.id);
  } else {
    favorites.set(property.id, property);
  }
  renderFavorites();
}

function renderFavorites() {
  favoritesList.innerHTML = "";
  if (favorites.size === 0) {
    favoritesList.innerHTML = '<p class="placeholder">Noch keine Favoriten. Füge Angebote hinzu, um sie hier zu vergleichen.</p>';
    return;
  }

  favorites.forEach((property) => {
    const card = document.createElement("div");
    card.className = "favorite-card";
    card.innerHTML = `
      <div class="card__meta">
        <strong>${property.title}</strong>
        <span class="badge">${property.yield}%</span>
      </div>
      <p class="muted">${property.size} m² • ${property.location}</p>
      <p><strong>${formatPrice(property.price)}</strong></p>
      <button class="btn btn--ghost" data-id="${property.id}">Entfernen</button>
    `;
    card.querySelector("button").addEventListener("click", () => toggleFavorite(property));
    favoritesList.appendChild(card);
  });
}

function filterAndSort() {
  const [minPrice, maxPrice] = (filterPrice.value || "0-99999999").split("-").map(Number);
  const filtered = properties.filter((p) => {
    const matchesType = !filterType.value || p.type === filterType.value;
    const matchesLoc = !filterLocation.value || p.location === filterLocation.value;
    const matchesPrice = p.price >= minPrice && p.price <= maxPrice;
    return matchesType && matchesLoc && matchesPrice;
  });

  const sorted = filtered.sort((a, b) => {
    switch (sortSelect.value) {
      case "price-asc":
        return a.price - b.price;
      case "price-desc":
        return b.price - a.price;
      case "yield-desc":
        return b.yield - a.yield;
      default:
        return 0;
    }
  });

  renderProperties(sorted);
}

function populateTradeSelect() {
  tradeSelect.innerHTML = properties
    .map((p) => `<option value="${p.id}">${p.title} (${formatPrice(p.price)})</option>`) 
    .join("");
}

function handleTradeSubmit(event) {
  event.preventDefault();
  const formData = new FormData(tradeForm);
  const payload = Object.fromEntries(formData.entries());
  const property = properties.find((p) => p.id === payload["selected-property"]);

  tradeFeedback.textContent = `Anfrage gesendet! ${payload["buyer-name"]} bietet ${formatPrice(
    Number(payload.offer)
  )} für ${property.title}. Wir melden uns kurzfristig.`;
  tradeForm.reset();
  populateTradeSelect();
}

filterType.addEventListener("change", filterAndSort);
filterLocation.addEventListener("change", filterAndSort);
filterPrice.addEventListener("change", filterAndSort);
sortSelect.addEventListener("change", filterAndSort);
clearFavorites.addEventListener("click", () => {
  favorites.clear();
  renderFavorites();
});
tradeForm.addEventListener("submit", handleTradeSubmit);

renderProperties(properties);
populateTradeSelect();
