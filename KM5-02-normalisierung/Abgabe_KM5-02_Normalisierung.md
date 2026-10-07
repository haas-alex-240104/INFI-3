# Abgabe KM5-02 — Normalisierung 1NF–3NF

Autor: Alex Haas, 3AHWII — Datum: 07.10.2026
Zugehörige Dateien: `abgabe.sql` (gesamtes Schema + Daten, mit `sqlite3` getestet)

Ausgangstabelle (rekonstruiert aus `lesson.html` Kap. 8 + Aufgabenstellung,
da `Beispielprojekte/km5-02-normalisierung/seed-normalisierung.sql` im Repo fehlt):

```sql
bestellung_denorm(bestell_nr INTEGER PRIMARY KEY, kunde TEXT, tracks TEXT, plz TEXT, ort TEXT)

  101 | Auer  | '1,2' | 1020 | Wien
  102 | Beck  | '3'   | 1020 | Wien
  103 | Cevik | '2,3' | 4020 | Linz
```

## 1. Vorhersage (vor dem Zerlegen)

| Spalte | Verletzte Stufe | Warum (mit Lesson-Beleg) |
|---|---|---|
| `tracks` | **1NF** | Liste in einer Zelle (`'1,2'`), also nicht atomar. Gleicher Fehlertyp wie Quiz 2 (`hobbys = 'Lesen, Schwimmen'`). Folge: `WHERE tracks = '2'` liefert 0 Zeilen (verifiziert, siehe Demo), `LIKE '%2%'` wäre nur ein Notbehelf mit Teiltreffern (vgl. Kap. 7 „Typische Fehler"). |
| `ort` (+ `plz`) | **3NF** | Transitive Kette `bestell_nr → plz → ort`: `ort` hängt am Nichtschlüssel `plz`, nicht am Schlüssel. Gleicher Fehlertyp wie Quiz 12 (`bestellung`) und Quiz 13 (`iban → blz → bankname`). Folge: alle 3 Anomalien (Wien steht 2×, Graz ohne Bestellung nicht speicherbar, Löschen der letzten 4020-Zeile löscht „4020 = Linz"). |
| — | **2NF: nicht relevant** | 2NF braucht einen zusammengesetzten Schlüssel (Merke Kap. 4, Quiz 6 + 10). PK ist hier nur `bestell_nr` (eine Spalte) → keine Teilabhängigkeit möglich → 2NF automatisch erfüllt. |

## 2. Zerlegen bis 3NF (mit Abhängigkeitspfeilen)

**Schritt 1 — 1NF:** `tracks` ist keine atomare Tatsache über die Bestellung →
Kindtabelle mit einer Zeile pro Vorkommen (+ Positionsnummer, sonst sind
zwei Tracks nicht unterscheidbar):

```
bestell_nr ──✕──> tracks (kein atomarer Wert, Liste!)
```

```sql
bestellposition(bestell_nr FK → bestellung, position, track_id FK → track),
  PK (bestell_nr, position)
```

**Schritt 2 — 2NF:** entfällt mit Begründung. Nach Schritt 1 hat nur
`bestellposition` einen zusammengesetzten PK `(bestell_nr, position)`,
aber `track_id` braucht den *ganzen* Schlüssel (welcher Track an welcher
Position welcher Bestellung — vgl. Quiz 9 `note` braucht `matr_nr + lv_nr`,
und Quiz 15). Keine partielle Abhängigkeit → nichts auszulagern.

**Schritt 3 — 3NF:** Tatsache `plz → ort` auslagern, per FK verweisen:

```
bestell_nr → plz → ort   (transitiv über Nichtschlüssel plz)
```

```sql
ort(plz PK, ort)                        -- „1020 = Wien" genau 1×
bestellung(bestell_nr PK, kunde, plz FK → ort)
```

**Endergebnis (3NF):**

```sql
ort(plz PK, ort)
bestellung(bestell_nr PK, kunde, plz FK)
track(track_id PK, titel, dauer_sek)
bestellposition(bestell_nr FK, position, track_id FK), PK (bestell_nr, position)
```

**Anomalien-Probe:** `INSERT INTO ort VALUES ('8010','Graz')` geht ohne
Bestellung (Einfüge-Anomalie weg), Wien-Umbenennung = 1 Zeile in `ort`
(Änderungs-Anomalie weg), Löschen aller 4020-Bestellungen lässt `('4020','Linz')`
stehen (Lösch-Anomalie weg).

**Zurück zur Abfrage (lesson.html Kap. 8.3, Interleaving)** — ursprüngliche
Bestellung inkl. Track-Titel nach der Zerlegung:

```sql
SELECT b.bestell_nr, b.kunde, o.ort, p.position, t.titel
FROM bestellung b
JOIN ort o            ON o.plz = b.plz
JOIN bestellposition p ON p.bestell_nr = b.bestell_nr
JOIN track t          ON t.track_id = p.track_id
ORDER BY b.bestell_nr, p.position;
-- 101 Auer Wien 1 Silent Lines / 101 Auer Wien 2 Night Ferry /
-- 102 Beck Wien 1 Regenrot / 103 Cevik Linz 1 Night Ferry / 103 Cevik Linz 2 Regenrot
```

## 3. Zwei eigene Quiz-Tabellen, zerlegt

### A) `song_playlist` (Quiz 7) — 2NF-Verletzung

Fehler: PK `(song_id, playlist_id)`, aber `song_titel` hängt nur an
Schlüsselteil `song_id` → partielle Abhängigkeit (`song_id → song_titel`).

```sql
-- vorher (kaputt):
-- song_playlist(song_id, playlist_id, song_titel), PK (song_id, playlist_id)
--   1 | 10 | 'Silent Lines'
--   1 | 20 | 'Silent Lines'   -- Titel zum 2. Mal
--   2 | 20 | 'Night Ferry'

-- nachher (2NF):
CREATE TABLE song(song_id INTEGER PRIMARY KEY, titel TEXT NOT NULL);
CREATE TABLE song_playlist(
  song_id INTEGER NOT NULL REFERENCES song(song_id),
  playlist_id INTEGER NOT NULL,
  PRIMARY KEY (song_id, playlist_id)
);
INSERT INTO song VALUES (1,'Silent Lines'), (2,'Night Ferry'), (3,'Regenrot');
INSERT INTO song_playlist VALUES (1,10), (1,20), (2,20);
```

### B) `konto` (Quiz 13) — 3NF-Verletzung

Fehler: transitive Kette `iban → blz → bankname` (`bankname` hängt am
Nichtschlüssel `blz`).

```sql
-- vorher (kaputt):
-- konto(iban PK, inhaber, blz, bankname)
--   AT111 | Auer  | 10000 | 'Erste Bank'
--   AT222 | Beck  | 10000 | 'Erste Bank'  -- Bankname zum 2. Mal
--   AT333 | Cevik | 20000 | 'Raiffeisen'

-- nachher (3NF):
CREATE TABLE bank(blz TEXT PRIMARY KEY, bankname TEXT NOT NULL);
CREATE TABLE konto(
  iban TEXT PRIMARY KEY,
  inhaber TEXT NOT NULL,
  blz TEXT NOT NULL REFERENCES bank(blz)
);
INSERT INTO bank VALUES ('10000','Erste Bank'), ('20000','Raiffeisen'), ('30000','BAWAG');
INSERT INTO konto VALUES ('AT111','Auer','10000'), ('AT222','Beck','10000'), ('AT333','Cevik','20000');
```

Eselsbrücke (Codd, Kap. 9): Jedes Attribut hängt vom Schlüssel ab,
vom *ganzen* Schlüssel (2NF) und von *nichts als* dem Schlüssel (3NF).

## 4. Demo-Nachweis

`deno task demo` im Original-Beispielprojekt war nicht lauffähig, weil
`Beispielprojekte/km5-02-normalisierung/` im Repo nicht existiert
(geprüft: nur `2026-09-22_normalformen/`, `2026-09-29_nodejs-prisma/`,
`2026-09-29_rep-ohne-node/`, `KM5-02-normalisierung/` vorhanden).
Ersatz-Nachweis mit `sqlite3` auf `abgabe.sql` (alle drei Anomalien live):

```
sqlite3 ":memory:" ".read abgabe.sql" "SELECT * FROM bestellung_denorm; ..."
--- bestellung_denorm ---
101  Auer   1,2  1020  Wien
102  Beck   3    1020  Wien
103  Cevik  2,3  4020  Linz
--- JOIN 3NF (Kap 8.3) ---
101  Auer   Wien  1  Silent Lines
101  Auer   Wien  2  Night Ferry
102  Beck   Wien  1  Regenrot
103  Cevik  Linz  1  Night Ferry
103  Cevik  Linz  2  Regenrot
--- 1NF-Probe ---
WHERE tracks = '2'  → 0 Zeilen (Liste nicht mit = abfragbar!)
Fix: JOIN bestellposition/track WHERE track_id = 2 → 2 Treffer (101/2, 103/1)
```

`abgabe.sql` lädt ohne Fehler; JOIN liefert alle 5 Positionen korrekt zurück.
