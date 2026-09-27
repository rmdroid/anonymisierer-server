# Lizenz bestellen

Der Einzelplatzbetrieb auf dem eigenen Rechner ist kostenfrei und braucht
keine Bestellung. Eine Lizenz wird erst nötig, wenn mehrere Arbeitsplätze auf
denselben Server zugreifen oder der Windows-Client im Mehrbenutzerbetrieb läuft.

## 30 Tage kostenlos testen

Kostenlos, voller Funktionsumfang, ohne Verpflichtung: als Testschlüssel für
den eigenen Server oder als Zugang zu unserem Testserver, mit dem Sie die
Erkennung ohne Installation über die Chrome-Erweiterung prüfen.

Anfrage über https://anonymisierer-tools.de/#testzugang oder an
**rm@kostenmanager.net**. Für den Testserver gilt: nur erfundene Daten, es
besteht kein Auftragsverarbeitungsvertrag.

Der Windows-Client ist kostenlos. Lizenziert werden die Arbeitsplätze am
Server.

## Was Sie erhalten

- Signierter Lizenzschlüssel für die vereinbarte Zahl an Arbeitsplätzen
- Freischaltung des Netzwerkbetriebs
- Nutzung des Windows-Clients in der Mehrbenutzerfassung
- Aktualisierungen für die Laufzeit der Lizenz (bei unbefristeten Lizenzen 12 Monate)

## Bestellung

**rm@kostenmanager.net**

Bitte geben Sie an:

```
Firma / Behörde:
Ansprechpartner:
Rechnungsanschrift:
USt-IdNr. (falls vorhanden):

Zahl der Arbeitsplätze:
Laufzeit:            [ ] 1 Jahr   [ ] unbefristet
Windows-Client:      [ ] ja       [ ] nein
```

Sie erhalten ein Angebot. Nach Zahlungseingang wird der Lizenzschlüssel per
E-Mail zugestellt.

## Schlüssel eintragen

Nach Erhalt in der Oberfläche unter **Lizenzschlüssel** eintragen
(`http://localhost:9090`), oder in der Datei `.env`:

```
NETWORK=1
LICENSE_KEY=KIA1....
API_KEY=ein-langer-zufallswert
```

Danach neu starten:

```bash
docker compose up -d
```

Der Schlüssel wird lokal geprüft. Es findet keine Onlineaktivierung statt und
es werden keine Daten übertragen.

## Fragen vorab

Für Sicherheitsfragebögen, Auftragsverarbeitungsverträge oder eine
Teststellung: **rm@kostenmanager.net**
