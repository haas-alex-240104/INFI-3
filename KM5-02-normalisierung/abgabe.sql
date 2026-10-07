-- Abgabe KM5-02 Normalisierung 1NF-3NF
-- Autor: Alex Haas, 3AHWII
-- Rekonstruiertes Ausgangsschema aus lesson.html Kap. 8 + seed-Name bestellung_denorm
-- bestellung_denorm(bestell_nr PK, kunde, tracks, plz, ort)
-- Hinweis: Beispielprojekt ../../Beispielprojekte/km5-02-normalisierung/ existiert
-- im Repo nicht, daher wurde die Demo mit sqlite3 nachgebaut (siehe Abgabe-Markdown).

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS bestellung_denorm;
DROP TABLE IF EXISTS bestellposition;
DROP TABLE IF EXISTS bestellung;
DROP TABLE IF EXISTS ort;
DROP TABLE IF EXISTS track;

-- 0) Denormalisierte Ausgangstabelle (zum Zeigen der Anomalien)
CREATE TABLE bestellung_denorm(
  bestell_nr INTEGER PRIMARY KEY,
  kunde      TEXT NOT NULL,
  tracks     TEXT NOT NULL,  -- 1NF-Verletzung: Liste in einer Zelle, z.B. '1,2'
  plz        TEXT NOT NULL,
  ort        TEXT NOT NULL   -- 3NF-Verletzung: haengt an plz, nicht an bestell_nr
);

INSERT INTO bestellung_denorm(bestell_nr, kunde, tracks, plz, ort) VALUES
  (101, 'Auer',  '1,2', 1020, 'Wien'),
  (102, 'Beck',  '3',   1020, 'Wien'),
  (103, 'Cevik', '2,3', 4020, 'Linz');

-- 1) Normalisiertes Schema (3NF)
CREATE TABLE ort(
  plz TEXT PRIMARY KEY,
  ort TEXT NOT NULL
);

CREATE TABLE bestellung(
  bestell_nr INTEGER PRIMARY KEY,
  kunde      TEXT NOT NULL,
  plz        TEXT NOT NULL REFERENCES ort(plz)
);

CREATE TABLE track(
  track_id  INTEGER PRIMARY KEY,
  titel     TEXT NOT NULL,
  dauer_sek INTEGER NOT NULL
);

CREATE TABLE bestellposition(
  bestell_nr INTEGER NOT NULL REFERENCES bestellung(bestell_nr),
  position   INTEGER NOT NULL,
  track_id   INTEGER NOT NULL REFERENCES track(track_id),
  PRIMARY KEY (bestell_nr, position)
);

INSERT INTO ort(plz, ort) VALUES
  ('1020', 'Wien'),
  ('4020', 'Linz'),
  ('8010', 'Graz');  -- Einfuege-Anomalie behoben: Ort ohne Bestellung speicherbar

INSERT INTO bestellung(bestell_nr, kunde, plz) VALUES
  (101, 'Auer',  '1020'),
  (102, 'Beck',  '1020'),
  (103, 'Cevik', '4020');

INSERT INTO track(track_id, titel, dauer_sek) VALUES
  (1, 'Silent Lines', 215),
  (2, 'Night Ferry',  189),
  (3, 'Regenrot',     240);

INSERT INTO bestellposition(bestell_nr, position, track_id) VALUES
  (101, 1, 1),
  (101, 2, 2),
  (102, 1, 3),
  (103, 1, 2),
  (103, 2, 3);

-- 2) Zusatzaufgabe Kap. 8.3: Bestellung inkl. Track-Titel (JOIN)
-- SELECT b.bestell_nr, b.kunde, o.ort, p.position, t.titel
-- FROM bestellung b
-- JOIN ort o ON o.plz = b.plz
-- JOIN bestellposition p ON p.bestell_nr = b.bestell_nr
-- JOIN track t ON t.track_id = p.track_id
-- ORDER BY b.bestell_nr, p.position;

-- 3) Zwei eigene Quiz-Tabellen, zerlegt
-- A) 2NF-Verletzung aus Quiz 7: song_playlist(song_id, playlist_id, song_titel)
DROP TABLE IF EXISTS song;
DROP TABLE IF EXISTS song_playlist;
CREATE TABLE song(
  song_id INTEGER PRIMARY KEY,
  titel   TEXT NOT NULL
);
CREATE TABLE song_playlist(
  song_id     INTEGER NOT NULL REFERENCES song(song_id),
  playlist_id INTEGER NOT NULL,
  PRIMARY KEY (song_id, playlist_id)
);
INSERT INTO song(song_id, titel) VALUES
  (1, 'Silent Lines'),
  (2, 'Night Ferry'),
  (3, 'Regenrot');
INSERT INTO song_playlist(song_id, playlist_id) VALUES
  (1, 10),
  (1, 20),
  (2, 20);

-- B) 3NF-Verletzung aus Quiz 13: konto(iban PK, inhaber, blz, bankname)
DROP TABLE IF EXISTS bank;
DROP TABLE IF EXISTS konto;
CREATE TABLE bank(
  blz      TEXT PRIMARY KEY,
  bankname TEXT NOT NULL
);
CREATE TABLE konto(
  iban    TEXT PRIMARY KEY,
  inhaber  TEXT NOT NULL,
  blz     TEXT NOT NULL REFERENCES bank(blz)
);
INSERT INTO bank(blz, bankname) VALUES
  ('10000', 'Erste Bank'),
  ('20000', 'Raiffeisen'),
  ('30000', 'BAWAG');
INSERT INTO konto(iban, inhaber, blz) VALUES
  ('AT111', 'Auer',  '10000'),
  ('AT222', 'Beck',  '10000'),
  ('AT333', 'Cevik', '20000');
