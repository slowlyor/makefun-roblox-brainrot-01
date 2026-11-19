// Brainrot Bazaar -- make.fun entry program (Node 22, standard library only).
//
// The game is the Rojo project in this repository: src/ holds every Luau
// script, default.project.json lays them out, and `rojo build` produces
// game.rbxl from them. This program hands the entry in: it copies
// game.rbxl, src/, screenshots/ and PLAY.json to the output directory and
// writes dossier.json there with buildDossier from the vendored library.
//
// Run it the way the grader does, with a local stand-in for /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

// The grader refuses any output name that starts with a dot, so the copy
// filter drops dotted names (.gitkeep, .DS_Store, ...) at every depth.
const keepName = (path: string): boolean => !basename(path).startsWith('.');

mkdirSync(out, { recursive: true });
copyFileSync(join(here, 'game.rbxl'), join(out, 'game.rbxl'));
copyFileSync(join(here, 'PLAY.json'), join(out, 'PLAY.json'));
cpSync(join(here, 'src'), join(out, 'src'), { recursive: true, filter: keepName });
mkdirSync(join(out, 'screenshots'), { recursive: true });
if (existsSync(join(here, 'screenshots'))) {
  cpSync(join(here, 'screenshots'), join(out, 'screenshots'), { recursive: true, filter: keepName });
}

// The dossier caps mirror the scorer's gate: the text cap shapes the
// bytes; the rest refuse exactly what the scorer would refuse.
// Brainrot Bazaar's place is small (a few hundred procedural parts and
// ten scripts), so a dossier failure here means something structural
// broke -- a missing game.rbxl or an oversized screenshot -- and the
// thrown error is the right thing to surface.
const dossier = buildDossier(out, {
  text_max_bytes: 65536,
  screenshots: { max: 4, max_bytes: 262144 },
  max_instances: 500000,
  scripts_max_source_bytes: 8388608,
  scripts_max_path_chars: 1048576,
});
writeFileSync(join(out, 'dossier.json'), dossier);
console.log(`Brainrot Bazaar entry written to ${out} (dossier ${dossier.length} bytes)`);
