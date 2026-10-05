-- auffrischungs-queries.sql — HÜ bis 06.10. (UE 2026-09-29 Rep ohne Node)
-- DB: seed-musik-mini.sql (6 Künstler, 10 Songs, 1 Künstler ohne Label)
-- Ausführen z.B.: sqlite3 musik-mini.db < auffrischungs-queries.sql
-- Verifiziert mit: deno task run / deno task test (3 Tests grün)

-- Q1: Top-Künstler nach Track-Anzahl (JOIN + GROUP BY + ORDER BY + LIMIT).
-- Beantwortet: Wer hat die meisten Songs? Erwartet: Auer (3), dann Frei (2), Demir (2).
SELECT k.name, COUNT(*) AS tracks
FROM kuenstler k JOIN song s ON s.kuenstler_id = k.id
GROUP BY k.id
ORDER BY tracks DESC
LIMIT 5;

-- Q2: Künstlerpaare desselben Labels (Self-JOIN, x.id < y.id gegen Doppelpaare).
-- Beantwortet: Welche Künstler teilen sich ein Label? Erwartet: Auer/Beck (Nordklang),
-- Cevik/Demir, Cevik/Egger, Demir/Egger (Suedton). Frei (NULL-Label) taucht nie auf.
SELECT x.name AS a, y.name AS b, l.name AS label
FROM kuenstler x
JOIN kuenstler y ON x.label_id = y.label_id AND x.id < y.id
JOIN label l ON l.id = x.label_id;

-- Q3: Labels mit mehr als einem Künstler (GROUP BY + HAVING filtert Gruppen).
-- Beantwortet: Welche Labels haben >1 Künstler? Erwartet: Nordklang (2), Suedton (3).
-- Westbeat (0 Künstler) taucht nicht auf, weil INNER JOIN.
SELECT l.name, COUNT(*) AS n
FROM kuenstler k JOIN label l ON l.id = k.label_id
GROUP BY l.id
HAVING COUNT(*) > 1;

-- Q4: COUNT(*) vs. COUNT(label_id) — NULL-Demo (ein Künstler hat kein Label).
-- Beantwortet: Wie viele Künstler gibt es vs. wie viele haben ein Label?
-- Erwartet: alle=6, mit_label=5, weil Frei label_id IS NULL hat (COUNT(spalte) ignoriert NULL).
SELECT COUNT(*) AS alle, COUNT(label_id) AS mit_label FROM kuenstler;

-- Q5: WHERE + HAVING kombiniert: lange Songs (>200s) je Künstler, nur Künstler mit 2+ langen Songs.
-- Beantwortet: Wer hat mindestens 2 Songs über 200 s? WHERE filtert Zeilen vor dem
-- Gruppieren, HAVING filtert Gruppen danach. Erwartet: nur Auer (Silent Lines 210, Hafenlicht 240).
SELECT k.name, COUNT(*) AS n
FROM kuenstler k JOIN song s ON s.kuenstler_id = k.id
WHERE s.dauer_sek > 200
GROUP BY k.id
HAVING COUNT(*) >= 2;
