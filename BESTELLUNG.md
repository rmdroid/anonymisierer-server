# Lizenz bestellen

Der Einzelplatzbetrieb auf dem eigenen Rechner ist kostenfrei und braucht
keine Bestellung. Eine Lizenz wird erst nötig, wenn mehrere Arbeitsplätze auf
denselben Server zugreifen oder der Windows-Agent im Mehrbenutzerbetrieb läuft.

## Was Sie erhalten

- Signierter Lizenzschlüssel für die vereinbarte Zahl an Arbeitsplätzen
- Freischaltung des Netzwerkbetriebs
- Nutzung des Windows-Agents in der Mehrbenutzerfassung
- Aktualisierungen für die Laufzeit der Lizenz

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
Windows-Agent:       [ ] ja       [ ] nein
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
