# Leseauftrag Lösung — Drizzle vs. Prisma 2026 (HÜ Frage 6, mit 1–5 als Vorbereitung)

Quelle: HK Lee, „Drizzle ORM vs Prisma in 2026", DEV Community, 18.02.2026.

## Frage 1: abstraction-first vs. SQL-first (ein Satz)

Bei Prisma (abstraction-first) sehe ich SQL fast nicht mehr — ich definiere Modelle
und Relationen und bekomme typisierte Methoden wie `findMany`/`groupBy`; bei Drizzle
(SQL-first) schreibe ich weiterhin SQL-nahe Queries (`select ... from ... where`),
nur eben typisiert in TypeScript.

## Frage 2: je ein Vorteil Schema-Sprache vs. alles TypeScript

- Eigene Schema-Sprache (Prisma, `schema.prisma`) ist bequemer, wenn man das Datenmodell
  kompakt in einer Datei lesen und die Migrationen/Relationen automatisch ableiten
  lassen will — eine Quelle, klare DSL.
- Alles TypeScript (Drizzle) ist bequemer, wenn man ohnehin im TS-Code lebt: volle
  IDE-Unterstützung (Autocomplete, Refactoring, Type-Checking) ohne zweite Sprache
  und ohne Code-Generierungs-Schritt.

## Frage 3: Schema ändern, aber `prisma generate` vergessen?

Dann passt der generierte Client (`node_modules/@prisma/client`) nicht mehr zum Schema:
TypeScript-Typen und Client-Methoden kennen das neue Feld/die neue Relation nicht,
es gibt Laufzeit- bzw. Typfehler. Bei Drizzle kann das nicht passieren, weil es keinen
Generierungs-Schritt gibt — das Schema *ist* TypeScript-Code und wird direkt importiert.

## Frage 4: Warum sind Benchmarks von vor 2026 „wegzuwerfen"?

Weil sich mit Prisma 7 die Architektur grundlegend geändert hat: weg von der
Rust-Query-Engine (ca. 14 MB Binary) hin zu TypeScript/WASM (ca. 1,6 MB), dadurch bis
zu 9× bessere Cold Starts und bis 3,4× schnellere große Resultate. Alte Benchmarks
haben also eine Engine vermessen, die es so nicht mehr gibt.

## Frage 5: Zu welcher Gruppe gehört unsere Klasse?

Nach dem heutigen Rep-Stand (Self-JOIN, `COUNT(*)` vs. `COUNT(col)`, WHERE vs. HAVING
per Hand in `sqlite3`/`node:sqlite`) sind wir klar die SQL-starke Gruppe im Aufbau.
Nach der Faustregel des Artikels („Prisma, wenn das ORM für dich denken soll —
Drizzle, wenn es mit dir denken soll") folgt daraus: Edge-/Size-Ziele und unser
SQL-Handwerk sprechen eher für Drizzle — aber erst, wenn das Handwerk sitzt.

## Frage 6 (HÜ, 5–6 Sätze)

Wir fahren im Unterricht zuerst reines SQL, weil genau das Handwerk aus UE 1 und dem
Rep — Self-JOIN mit `x.id < y.id`, `COUNT(*)` vs. `COUNT(col)` bei NULL-Labels und
WHERE (Zeilenfilter) vs. HAVING (Gruppenfilter) — die Grundlage ist, auf der man ein
ORM überhaupt beurteilen kann. Dazu kommt die Werkzeug-Lage: Deno bringt `node:sqlite`
eingebaut mit und braucht kein Setup, während Prisma 7 zwingend einen nativen Driver
Adapter (`better-sqlite3`) verlangt und `npm install prisma` ohne `@7`-Pin aktuell auf
einen 8.0.0-RC zeigt — genau die Falle vom 22.09. Ein ORM würde dieses SQL-Verständnis
anfangs nur verstecken und gleichzeitig natives Bauen plus Version-Pinning verlangen.
Wenn wir später ein ORM evaluieren, liegt Drizzle näher: SQL-first passt zu unserem
Rep-Stand, die Runtime ist mit ca. 12 KB gegenüber ca. 1,6 MB deutlich schlanker und
es gibt keinen `generate`-Schritt, den man vergessen kann.
