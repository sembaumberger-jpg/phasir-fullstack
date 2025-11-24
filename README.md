# Phasir

Phasir ist jetzt auf eine native SwiftUI-App umgestellt. Das Backend läuft in Node.js/Express und persistiert die Daten in
Postgres über Supabase.

## Technologie-Stack

- **Frontend:** SwiftUI (`swift-frontend/`), kommuniziert per REST mit dem Node-Backend.
- **Backend:** Node.js + Express (`api/`), Supabase/Postgres als Datenbank.
- **Datenmodell:** Wartungsintervalle werden serverseitig berechnet (Heizung 2 Jahre, Dach 4 Jahre, Fenster 15 Jahre,
  Rauchmelder 1 Jahr).

## Lokales Setup

1. Abhängigkeiten installieren:

```bash
npm install
```

2. Supabase-Umgebung setzen (Service-Role empfohlen, Anon-Key funktioniert ebenfalls für lokale Entwicklung). Die API nutzt
   standardmäßig das bereitgestellte Projekt `https://xbaokwesgokpffjonpwt.supabase.co`:

```bash
export SUPABASE_URL="https://xbaokwesgokpffjonpwt.supabase.co"
export SUPABASE_SERVICE_ROLE_KEY="<your-service-role-key>"  # Service-Role-Key des Supabase-Projekts
```

Der `SUPABASE_SERVICE_ROLE_KEY` (oder alternativ `SUPABASE_ANON_KEY`) wird nur serverseitig gelesen. Für lokale Entwicklung
kannst du ihn z. B. in einem `.env` ablegen oder direkt in der Shell exportieren, bevor du das Backend startest.

Ohne gesetzte Variablen läuft das Backend weiter mit den eingebauten Demo-Daten im Speicher.

3. Backend starten (Standard-Port 4000):

```bash
npm start
```

4. SwiftUI-Frontend öffnen:

- In Xcode: `swift-frontend/Package.swift` öffnen und das Schema **PhasirApp** auf einem iOS 17+ Simulator ausführen.
- Alternativ im Terminal: `cd swift-frontend && swift run` (zeigt die SwiftUI-Previews/Logs, erfordert ein macOS/iOS Toolchain).
