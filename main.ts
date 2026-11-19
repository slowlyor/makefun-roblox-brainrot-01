// Brainrot Bazaar — make.fun roblox-brainrot-01 entry program (Node 22, standard library only).
//
// The game is this directory's Rojo project: src/ holds every Luau script of the place and
// `rojo build default.project.json --output game.rbxl` turns them into game.rbxl. This program
// hands the entry in: it copies game.rbxl, src/, screenshots/ and PLAY.json from beside this
// file to /output and writes /output/dossier.json with buildDossier from the vendored library.
//
// Every name under /output must start with a letter, a digit or _ and hold only letters,
// digits, . _ and -, so the copies below skip any name that starts with a dot (.gitkeep,
// .DS_Store and friends would fail the entry outright).
//
// Outside the grader's container, MAKEFUN_OUTPUT_DIR stands in for /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

/** cpSync filter: leave out every file and directory whose name starts with a dot. */
const notDotted = (path: string): boolean => !basename(path).startsWith('.');

mkdirSync(out, { recursive: true });
copyFileSync(join(here, 'game.rbxl'), join(out, 'game.rbxl'));
copyFileSync(join(here, 'PLAY.json'), join(out, 'PLAY.json'));
cpSync(join(here, 'src'), join(out, 'src'), { recursive: true, filter: notDotted });
mkdirSync(join(out, 'screenshots'), { recursive: true });
if (existsSync(join(here, 'screenshots'))) cpSync(join(here, 'screenshots'), join(out, 'screenshots'), { recursive: true, filter: notDotted });

// The gate's own caps, passed through so this program refuses exactly what the scorer would
// refuse: at most 4 screenshots of at most 256 KiB, a place of at most 500000 instances whose
// scripts hold at most 8 MiB of source and at most 1048576 path characters in all.
writeFileSync(
  join(out, 'dossier.json'),
  buildDossier(out, { text_max_bytes: 65536, screenshots: { max: 4, max_bytes: 262144 }, max_instances: 500000, scripts_max_source_bytes: 8388608, scripts_max_path_chars: 1048576 }),
);

// One line of proof in the grader's log: where the entry landed.
console.log('Brainrot Bazaar entry written to ' + out + ' (game.rbxl, src/, screenshots/, PLAY.json, dossier.json)');
