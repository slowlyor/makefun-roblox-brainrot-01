// Brainrot Bazaar — make.fun roblox-brainrot-01 entry hand-in (Node 22, standard library only).
// The game is this directory's Rojo project; build it first with
//   rojo build default.project.json --output game.rbxl
// then run this program, which copies game.rbxl, src/, screenshots/ and PLAY.json into the output
// directory and writes dossier.json there with the vendored make.fun library.
//
// Names under the output must start with a letter, digit or _ and use only letters, digits, . _ -,
// so the copies below skip every file or directory whose name starts with a dot (.makefun, .git).
//
// Outside the grader's container, MAKEFUN_OUTPUT_DIR stands in for /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

/** Filter for cpSync: drop anything whose name starts with a dot. */
const keepName = (path: string): boolean => !basename(path).startsWith('.');

mkdirSync(out, { recursive: true });
// game.rbxl must already exist beside this file (see the rojo build above); a missing one throws here.
copyFileSync(join(here, 'game.rbxl'), join(out, 'game.rbxl'));
copyFileSync(join(here, 'PLAY.json'), join(out, 'PLAY.json'));
cpSync(join(here, 'src'), join(out, 'src'), { recursive: true, filter: keepName });
mkdirSync(join(out, 'screenshots'), { recursive: true });
if (existsSync(join(here, 'screenshots'))) {
  cpSync(join(here, 'screenshots'), join(out, 'screenshots'), { recursive: true, filter: keepName });
}

// The dossier carries the scorer's own caps: at most 4 screenshots of 256 KiB each, a place of at
// most 500000 instances, script sources totalling at most 8 MiB and script paths at most 1048576
// characters; text files are shaped to 65536 bytes.
writeFileSync(
  join(out, 'dossier.json'),
  buildDossier(out, {
    text_max_bytes: 65536,
    screenshots: { max: 4, max_bytes: 262144 },
    max_instances: 500000,
    scripts_max_source_bytes: 8388608,
    scripts_max_path_chars: 1048576,
  }),
);
