# Brainrot Bazaar

An entry for make.fun's "Make the best AI Roblox brainrot game" bounty (roblox-brainrot-01):
a 3D Steal-a-Brainrot-style tycoon built entirely from procedural Luau — no external assets,
no DataStore, all state in memory.

## The game

Brainrots walk the conveyor belt of the **TOKO BRAINROT** shop. Buy them and they walk home
to one of the 6 pads in your base (8 bases ring the plaza), where they earn cash every second.
Step on the green pad to harvest the stored cash, and slam the lock button to seal your base
for 60 seconds.

- **24 original brainrots** — Indonesian food and household-object characters (Blender Baper,
  Rice Cooker Nyanyi, Rendang Raja Daging, Sambal Petir Nusantara and friends) across 6
  rarities, Common to Divine, from $25 to $4,000,000.
- **Mutations** — Gold x2, Diamond x3, Rainbow x5, multiplying both price and income.
- **MESIN GACHA BRAINROT** — a plaza gacha machine with an escalating roll price; the prize
  walks itself home to a free pad (no charge when the base is full).
- **A thief NPC** periodically steals the richest brainrot from any unlocked base.
- **A tsunami every 180 seconds** (10-second warning) washes the belt clean and knocks out
  anyone caught standing outside a base.
- **Rebirth** resets cash and brainrots for a permanent +0.75x income multiplier per rebirth,
  costing 10,000 x 3^rebirths. Starting cash is $100.
- **Buku Koleksi** — a collection index of all 24 brainrots: owned ones lit with their stats,
  the rest silhouettes named "???".
- The world is dressed procedurally: an animated fountain, 4 striped market stalls, the
  rotating BIANGLALA BRAINROT ferris wheel, the MENARA BRAINROT tower with its beacon, a
  rainbow arch at spawn, trees, rocks, lamps and big readable signs.

## Layout

- `main.ts` (Node 22, standard library only) hands the game in: it copies `game.rbxl`, `src/`,
  `screenshots/` and `PLAY.json` to `/output`, leaving out every name that starts with a dot,
  and writes `/output/dossier.json` with `vendor/makefun-roblox.ts`, the kit's copy, unchanged.
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json`.
- `src/shared/BrainrotData.luau` — the cast, rarity weights and mutation table.
- `src/server/` — `init.server.luau` (bootstrap, belt shop, tsunami, rebirth), `GameState`
  (all state in one place), `WorldBuilder` (the procedural world), `BrainrotFactory`
  (procedural characters), `MoveService` (XZ steering with pinned height), `Thief`,
  `GachaService`.
- `src/client/` — `Hud.client.luau` (cash/income/stored panel, tsunami countdown, toasts,
  two-tap rebirth) and `Index.client.luau` (the Buku Koleksi).
- `PLAY.json` names the published public place; one of the screenshots is also the game's
  first thumbnail on Roblox.

Run it as the grader does, writing `out/` in place of `/output`:

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

Build the place from source with Rojo 7.7:

    rojo build default.project.json --output game.rbxl

## How to play

1. Walk to the **TOKO BRAINROT** belt and press the buy prompt on a brainrot you can afford —
   it walks to a free pad in your base by itself.
2. Watch the pad's stored cash grow, then step on the green pad to harvest it.
3. Roll the **MESIN GACHA BRAINROT** in the plaza when you feel lucky; lock your base before
   the thief comes calling, and get inside any base when the tsunami warning sounds.
4. Rebirth from the HUD button once you can afford it: the multiplier is forever.
