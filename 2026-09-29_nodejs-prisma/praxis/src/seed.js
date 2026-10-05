// src/seed.js — Mini-Musik-DB befüllen (idempotent: erst leeren, dann neu).
import { prisma } from "./prisma.js";

async function main() {
  // Reihenfolge wegen Fremdschlüsseln: Kinder zuerst (Join-Tabelle hängt an beiden).
  await prisma.playlist.deleteMany();
  await prisma.song.deleteMany();
  await prisma.kuenstler.deleteMany();
  await prisma.label.deleteMany();

  await prisma.label.createMany({
    data: [{ name: "Ohrwurm Records" }, { name: "Indie Nord" }],
  });
  const ohrwurm = await prisma.label.findUnique({ where: { name: "Ohrwurm Records" } });
  const indie = await prisma.label.findUnique({ where: { name: "Indie Nord" } });

  await prisma.kuenstler.createMany({
    data: [
      { name: "Nova", labelId: ohrwurm.id },
      { name: "Pixel", labelId: ohrwurm.id },
      { name: "Solveig", labelId: indie.id },
      { name: "Ohne Label", labelId: null }, // für COUNT(*)-vs-COUNT(col)-Demo
    ],
  });
  const nova = await prisma.kuenstler.findFirst({ where: { name: "Nova" } });
  const pixel = await prisma.kuenstler.findFirst({ where: { name: "Pixel" } });
  const solveig = await prisma.kuenstler.findFirst({ where: { name: "Solveig" } });
  const ohne = await prisma.kuenstler.findFirst({ where: { name: "Ohne Label" } });

  await prisma.song.createMany({
    data: [
      { titel: "Nordlicht", dauerSek: 245, kuenstlerId: nova.id },
      { titel: "Glut", dauerSek: 210, kuenstlerId: nova.id },
      { titel: "Funkeln", dauerSek: 198, kuenstlerId: nova.id },
      { titel: "Pixelstaub", dauerSek: 305, kuenstlerId: pixel.id },
      { titel: "Raster", dauerSek: 233, kuenstlerId: pixel.id },
      { titel: "Fjord", dauerSek: 260, kuenstlerId: solveig.id },
      { titel: "Kurz", dauerSek: 120, kuenstlerId: ohne.id },
    ],
  });

  const songs = await prisma.song.count();
  const kuenstler = await prisma.kuenstler.count();
  console.log(`Seed fertig: ${kuenstler} Künstler, ${songs} Songs.`);

  // HÜ-Erweiterung: Demo-Playlists (N:M zu Song).
  const nordlicht = await prisma.song.findFirst({ where: { titel: "Nordlicht" } });
  const glut = await prisma.song.findFirst({ where: { titel: "Glut" } });
  const fjord = await prisma.song.findFirst({ where: { titel: "Fjord" } });
  const kurz = await prisma.song.findFirst({ where: { titel: "Kurz" } });
  await prisma.playlist.create({
    data: {
      name: "Abendrot",
      songs: { connect: [{ id: nordlicht.id }, { id: glut.id }, { id: fjord.id }] },
    },
  });
  await prisma.playlist.create({
    data: { name: "Kurz und gut", songs: { connect: [{ id: kurz.id }] } },
  });
  const playlists = await prisma.playlist.count();
  console.log(`Seed fertig: ${playlists} Playlists.`);
}

main()
  .then(() => prisma.$disconnect())
  .catch(async (e) => {
    console.error(e);
    await prisma.$disconnect();
    process.exit(1);
  });
