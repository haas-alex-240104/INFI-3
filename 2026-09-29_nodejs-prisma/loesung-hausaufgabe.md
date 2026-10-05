# HÜ-Lösung — KM5-01 Node.js + Prisma 7 (Ordner 2026-09-29_nodejs-prisma)

## 1. Vorhersage vor dem Ausführen (Query 1 Top-Künstler + COUNT)

Vorhersage: Query 1 (`song.groupBy(by kuenstlerId, _count, orderBy desc, take 5)`)
liefert Nova auf Platz 1 mit 3 Tracks, danach Pixel mit 2, dann Solveig und
„Ohne Label" mit je 1. Begründung aus `src/seed.js`: Nova hat Nordlicht/Glut/Funkeln
(3), Pixel hat Pixelstaub/Raster (2), Solveig hat Fjord (1), „Ohne Label" hat Kurz (1).

Bestätigt nach dem Lauf:

```text
1) Top-Kuenstler: [ { Nova, 3 }, { Pixel, 2 }, { Ohne Label, 1 }, { Solveig, 1 } ]
4) COUNT: { alle: 4, mitLabel: 3 }
```

`COUNT(*)` = 4, `COUNT(labelId)` = 3, weil `COUNT(*)` alle Zeilen zählt, `COUNT(spalte)`
aber NULL-Werte ignoriert: Der Künstler „Ohne Label" wurde mit `labelId: null`
geseedet (Independent-Fall aus dem Mini-Seed), fällt also aus `COUNT(labelId)` bzw.
aus `prisma.kuenstler.count({ where: { labelId: { not: null } } })` heraus.
Gleiche Logik wie im Deno-Rep (`alle=6, mit_label=5` — dort ist es Frei mit NULL).

## 2. Setup wiederholen (Protokoll, verifiziert)

Befehle (in `praxis/`):

```bash
npm i prisma@7 @prisma/client@7 @prisma/adapter-better-sqlite3@7 dotenv
npm approve-scripts --all   # nur falls frisch installiert (better-sqlite3 + Prisma-Engines)
cp .env.example .env        # bzw. Copy-Item .env.example .env (enthält DATABASE_URL="file:./dev.db")
npm run db:migrate          # = prisma migrate dev (hier: 20260928220811_init + playlist-n-m)
npm run db:seed             # Seed fertig: 4 Künstler, 7 Songs + 2 Playlists
npm run run                 # siehe Hinweis unten
npm test                    # node:test
```

Auffälligkeiten auf diesem Rechner (wichtig für Abgabe):

- System-Node war v20.18.0, Prisma 7.10 verlangt aber `^20.19 || ^22.12 || >=24.0`
  (`prisma generate` bricht mit „Prisma only supports Node.js versions …" ab).
  Gelöst mit portablem Node v22.18.0; `npm i prisma@7 …` danach grün
  (`Generated Prisma Client v7.10.0`).
- `npm i prisma` ohne `@7` zieht aktuell die 8.0.0-RC (Update-Hinweis beim Migrate) —
  genau die Falle vom 22.09., daher unbedingt `@7` pinnen.
- `node src/queries.js` gab auf Windows keine Ausgabe: der Guard
  `if (import.meta.url === \`file://${process.argv[1]}\`)` ist auf Windows immer false
  (Backslashes vs. `file:///C:/…`). Workaround für die 5 Konsolen-Zeilen: Funktionen
  direkt importieren (Ergebnis identisch zu `npm run run` gedacht):

```text
1) Top-Kuenstler: [ { Nova, 3 }, { Pixel, 2 }, { Ohne Label, 1 }, { Solveig, 1 } ]
2) Label-Paare: [ { Nova, Pixel, Ohrwurm Records } ]
3) Labels mit >1 Kuenstler: [ { Ohrwurm Records, 2 } ]
4) COUNT: { alle: 4, mitLabel: 3 }
5) Lange: [ { Nova, 2 }, { Pixel, 2 } ]
6) Playlists: [ { Abendrot, 3 }, { Kurz und gut, 1 } ]
```

`npm test` / `node --test`: **5/5 grün** (Top-Künstler, COUNT, volle Labels,
Label-Paare, WHERE+HAVING).

## 3. Erweiterung: Model Playlist (N:M zu Song)

`prisma/schema.prisma` ergänzt (implizite N:M-Tabelle `_PlaylistToSong`):

```prisma
model Song {
  id          Int        @id @default(autoincrement())
  titel       String
  dauerSek    Int
  kuenstlerId Int
  kuenstler   Kuenstler  @relation(fields: [kuenstlerId], references: [id])
  playlists   Playlist[]
}

model Playlist {
  id    Int    @id @default(autoincrement())
  name  String @unique
  songs Song[]
}
```

Migration: `prisma/migrations/20261005183025_playlist_n_m/migration.sql`
(`CREATE TABLE "Playlist"`, `CREATE TABLE "_PlaylistToSong"` mit
`_PlaylistToSong_AB_unique`). Danach `prisma generate` neu laufen lassen,
sonst kennt der Client `prisma.playlist` nicht (`Cannot read properties of undefined`).

Eine Prisma-Query, die pro Playlist die Song-Anzahl liefert (`src/queries.js`):

```js
export async function songsProPlaylist() {
  const lists = await prisma.playlist.findMany({
    include: { _count: { select: { songs: true } } },
    orderBy: { name: "asc" },
  });
  return lists.map((p) => ({ name: p.name, songs: p._count.songs }));
}
```

Demo-Seed in `src/seed.js`: „Abendrot" → Nordlicht + Glut + Fjord (3),
„Kurz und gut" → Kurz (1). Ergebnis verifiziert:

```text
[ { name: 'Abendrot', songs: 3 }, { name: 'Kurz und gut', songs: 1 } ]
```

SQL-Äquivalent wäre `Playlist LEFT JOIN _PlaylistToSong GROUP BY` — Prisma spart hier
das manuelle GROUP BY über `_count`.

## 4. Reflexion (5–6 Sätze)

Prisma war bei den Zähl- und Filterfragen deutlich kürzer als SQL: `count()`,
`count({ where: { labelId: { not: null } } })` und `findMany({ include: { _count } })`
ersetzen GROUP-BY-/HAVING-Boilerplate, und die Playlist-Anzahl geht sogar ganz ohne
GROUP BY über `_count.songs`. Gekippt ist das bei allem, was Prisma nicht als Relation
kennt: Künstlerpaare als Self-JOIN (`x.id < y.id`) lassen sich nicht über die API
ausdrücken, sodass nur `prisma.$queryRaw` mit rohem SQL bleibt — inklusive
manueller Tabellennamen (`Kuenstler` statt `kuenstler`). Dazu kommt Setup-Reibung
(Adapter-Pflicht, `@7`-Pin gegen die 8.0.0-RC, Node-Version, Windows-Guard-Bug).
Ich bleibe vorerst bei Prisma für CRUD und Zähl-Queries, schreibe Self-JOINs und
komplexe Reports aber bewusst weiter in SQL bzw. `$queryRaw`.
