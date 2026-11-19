# Brainrot Bazaar

A Steal-a-Brainrot-style 3D tycoon for Roblox, built entirely from
procedural Luau — no external assets, no DataStore, all state in memory.

## The game

Brainrots — absurd Indonesian kitchen and street-food characters come to
life — walk a conveyor belt under the **TOKO BRAINROT** arch. Walk up to
one, buy it, and it hops off the belt and walks home to a pad in your
base, where it earns money every second. Stored cash piles up on each
pad; step on your green collect pad to harvest it all.

- **8 bases × 6 pads** around a plaza with a fountain, market stalls, a
  gacha machine, a Ferris wheel (**BIANGLALA BRAINROT**), a tower
  (**MENARA BRAINROT**) and a rainbow arch over the spawn path.
- **24 original characters** across 6 rarities (Common → Divine), from
  the $25 **Blender Budi** to the $4,000,000 **Dewa Speaker Semesta**,
  plus Gold (×2), Diamond (×3) and Rainbow (×5) mutations that multiply
  both price and income.
- **Lock your base** for 60 seconds, because a thief NPC periodically
  sneaks into the richest *unlocked* base and runs off with its best
  brainrot.
- **A tsunami every 180 seconds** (10-second warning) washes away
  everything on the belt and every player caught outside a base.
- **Gacha machine** on the plaza: escalating price per roll, a
  weighted-rarity prize that walks home to a free pad, full refund if
  your base is full.
- **Rebirth**: reset cash and brainrots for a permanent +0.75× income
  multiplier; cost grows ×3 each time (10,000 × 3^rebirths).
- **Buku Koleksi**: a collection index showing owned brainrots lit with
  their stats and unowned ones as "???" silhouettes.

## How it works

| File | Job |
| --- | --- |
| `src/shared/BrainrotData.luau` | The 24-character catalogue: rarities, prices, income, mutations |
| `src/server/GameState.luau` | All per-player state (cash, pads, collection, locks, rebirths) |
| `src/server/WorldBuilder.luau` | Builds the whole map procedurally from layout constants |
| `src/server/BrainrotFactory.luau` | Builds each walking character model and its billboard label |
| `src/server/MoveService.luau` | XZ-plane steering with heights pinned per surface (belt vs ground) |
| `src/server/Thief.luau` | The stealing NPC's raid logic |
| `src/server/GachaService.luau` | The plaza gacha machine |
| `src/server/init.server.luau` | Orchestration: belt spawner, prompts, events, HUD sync |
| `src/client/Hud.client.luau` | Cash/income/stored panel, tsunami countdown, toasts, rebirth |
| `src/client/Index.client.luau` | The Buku Koleksi collection book |

## Building

The place is a Rojo project. With Rojo 7.7.1:

    rojo build default.project.json --output game.rbxl

Then hand the entry in (Node 22, standard library only):

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

`main.ts` copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to
the output directory and writes `dossier.json` with the vendored
`vendor/makefun-roblox.ts` library, unchanged from the make.fun kit.

Play it: https://www.roblox.com/games/108382585327542

## Tips for your first run

1. You start with $150 — enough for the first Common on the belt.
2. Income is stored on the pad, not in your pocket: visit the green pad.
3. The lock button is at your base's front corner. Sixty seconds of
   safety is a long time when the thief is about.
4. When the tsunami warning sounds, stand on any base slab. Any base.
5. Save the gacha for after your first Legendary — its price climbs
   1.6× with every roll, but so does your income.
