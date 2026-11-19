// Brainrot Bazaar -- make.fun entry program (roblox-brainrot-01).
//
// The game itself is the Rojo project in this repository: Luau sources
// under src/ are built into game.rbxl with
//   rojo build default.project.json --output game.rbxl
// This program is the hand-in step the grader runs. It copies game.rbxl,
// PLAY.json, src/ and screenshots/ from beside this file into the output
// directory and writes dossier.json there with buildDossier from the
// vendored make.fun library (vendor/makefun-roblox.ts, the kit's copy,
// byte for byte unchanged).
//
// Output hygiene rule from the bounty: every name under the output must
// start with a letter, a digit or _ and contain only letters, digits,
// '.', '_' and '-'. A single dotted name (.gitkeep, .DS_Store) fails the
// entry, so the copy filter below drops every dotted file or directory
// at any depth.
//
// Outside the grader's container, MAKEFUN_OUTPUT_DIR stands in for
// /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, statSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const repoDir = fileURLToPath(new URL('.', import.meta.url));
const outputDir = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

/** True for names the grader accepts; dotted names are left behind. */
function isCleanName(path: string): boolean {
  return !basename(path).startsWith('.');
}

mkdirSync(outputDir, { recursive: true });
copyFileSync(join(repoDir, 'game.rbxl'), join(outputDir, 'game.rbxl'));
copyFileSync(join(repoDir, 'PLAY.json'), join(outputDir, 'PLAY.json'));
cpSync(join(repoDir, 'src'), join(outputDir, 'src'), { recursive: true, filter: isCleanName });
mkdirSync(join(outputDir, 'screenshots'), { recursive: true });
if (existsSync(join(repoDir, 'screenshots'))) {
  cpSync(join(repoDir, 'screenshots'), join(outputDir, 'screenshots'), { recursive: true, filter: isCleanName });
}

// The dossier is the judge-facing summary of the place. The caps passed
// here mirror the sealed scorer's own limits (65536 bytes of dossier
// text, at most 4 screenshots of at most 256 KiB, at most 500000
// instances, at most 8 MiB of script source, at most 1048576 characters
// of script instance paths): buildDossier refuses anything beyond them
// instead of emitting an entry the scorer would refuse.
// A one-line receipt on stdout, handy when running the program by hand:
// it names the place file size so a stale or empty game.rbxl (the classic
// "built the starter by mistake" failure) is obvious at a glance.
console.log(`brainrot-bazaar: game.rbxl ${statSync(join(outputDir, 'game.rbxl')).size} bytes -> ${outputDir}`);

const dossier = buildDossier(outputDir, {
  text_max_bytes: 65536,
  screenshots: { max: 4, max_bytes: 262144 },
  max_instances: 500000,
  scripts_max_source_bytes: 8388608,
  scripts_max_path_chars: 1048576,
});
writeFileSync(join(outputDir, 'dossier.json'), dossier);
