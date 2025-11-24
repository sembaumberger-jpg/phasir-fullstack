# SwiftUI Frontend für Phasir

Dieses Verzeichnis enthält eine schlanke SwiftUI-App, die das Node.js-Backend unter `http://localhost:4000` anspricht. Sie
zeigt Häuser, deren Wartungsintervalle sowie einen Button zum Anlegen eines Demo-Hauses.

## Starten

1. Backend wie in der Projektwurzel beschrieben starten (inkl. Supabase-Umgebungsvariablen, falls vorhanden).
2. `swift-frontend/Package.swift` in Xcode öffnen und das Schema **PhasirApp** auf einem iOS 17+ Simulator ausführen.
3. Alternativ: `cd swift-frontend && swift run` (benötigt eine Apple-Toolchain mit Swift 5.9+).

## Anpassen der API-URL

In `Sources/PhasirApp/PhasirApp.swift` kann die Basis-URL des Backends geändert werden, z. B. auf einen gehosteten Supabase-
Edge-Function-Endpunkt.
