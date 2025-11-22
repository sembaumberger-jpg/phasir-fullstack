# Phasir

Landing-Page-Prototyp für die mobile App "Phasir". Die App unterstützt Hausbesitzer dabei, Wartungen und Modernisierungen zu
planen. Kernideen:

- React Native + Expo Frontend mit Login/Signup, Dashboard, Haus-Detail, Haus-Formular, Wartungs-Timeline.
- Node.js + Express Backend mit MongoDB (oder SQLite/In-Memory) und CRUD-Endpunkten für Houses.
- Automatische Berechnung von Wartungsintervallen (z. B. Heizung alle 2 Jahre, Rauchmelder jährlich) beim Erstellen/Updaten
  eines Hauses.
- Optional: Push-Notifications via Expo/Firebase sowie Charting für Wartungs-Timelines.

## Lokales Setup

1. Abhängigkeiten installieren:

```bash
npm install
```

2. Backend starten (Standard-Port 4000):

```bash
npm start
```

3. `index.html` im Browser öffnen. Das Frontend ruft automatisch `http://localhost:4000/houses` auf und zeigt Demo-Daten. Über das Formular im Bereich "Häuser" können neue Häuser angelegt werden; der Server berechnet die nächsten Wartungsintervalle und liefert sie zurück.
