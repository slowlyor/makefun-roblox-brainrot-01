// Brainrot Bazaar — make.fun entry program for roblox-brainrot-01.
// The game itself is the Rojo project in this repository: Luau sources
// under src/, built into game.rbxl with
//   rojo build default.project.json --output game.rbxl
// This program hands the entry in: it copies game.rbxl, PLAY.json,
// src/ and screenshots/ from beside this file into the output folder
// and writes dossier.json there with buildDossier from the vendored
// library (vendor/makefun-roblox.ts, the kit's copy, unchanged).
//
// Output names must start with a letter, digit or _ and use only
// letters, digits, . _ and -, so the copies below skip every dotted
// name (.gitkeep, .DS_Store, ...) at any depth — one dotted file in
// the output fails the whole entry.
//
// Outside the grader, MAKEFUN_OUTPUT_DIR stands in for /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const repoDir = fileURLToPath(new URL('.', import.meta.url));
const outputDir = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

/** Filter for cpSync: true unless the file or directory name starts with a dot. */
function keepUndotted(path: string): boolean {
  return !basename(path).startsWith('.');
}

mkdirSync(outputDir, { recursive: true });
copyFileSync(join(repoDir, 'game.rbxl'), join(outputDir, 'game.rbxl'));
copyFileSync(join(repoDir, 'PLAY.json'), join(outputDir, 'PLAY.json'));
cpSync(join(repoDir, 'src'), join(outputDir, 'src'), { recursive: true, filter: keepUndotted });
if (existsSync(join(repoDir, 'screenshots'))) {
  mkdirSync(join(outputDir, 'screenshots'), { recursive: true });
  cpSync(join(repoDir, 'screenshots'), join(outputDir, 'screenshots'), { recursive: true, filter: keepUndotted });
}

// The caps mirror the scorer's own limits: text_max_bytes shapes the
// dossier text; the rest make this program fail exactly where the
// scorer would refuse the entry anyway.
const dossier = buildDossier(outputDir, {
  text_max_bytes: 65536,
  screenshots: { max: 4, max_bytes: 262144 },
  max_instances: 500000,
  scripts_max_source_bytes: 8388608,
  scripts_max_path_chars: 1048576,
});
writeFileSync(join(outputDir, 'dossier.json'), dossier);

// A last sanity note for whoever runs this by hand: name the place the
// entry points at, so a stale PLAY.json is obvious in the run log.
import { readFileSync } from 'node:fs';
const play = JSON.parse(readFileSync(join(repoDir, 'PLAY.json'), 'utf8')) as { url?: unknown; place_id?: unknown };
console.log(`Brainrot Bazaar entry written to ${outputDir} (dossier ${dossier.length} bytes)`);
console.log(`PLAY.json names place ${String(play.place_id)} at ${String(play.url)}`);
