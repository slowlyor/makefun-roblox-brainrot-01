# Brainrot Bazaar

A Steal-a-Brainrot-style 3D Roblox tycoon built entirely from procedural
Luau — no external assets, no DataStore, all state in memory. An entry for
make.fun's **roblox-brainrot-01** bounty ("Make the best AI Roblox brainrot
game").

Play it: https://www.roblox.com/games/108382585327542

## The game

Brainrots walk a conveyor belt shop ("TOKO BRAINROT") across the middle of
the map. Buy one and it is placed on a pad in your base — 8 bases of 6 pads
each ring a plaza with a fountain, market stalls, a gacha machine, a ferris
wheel ("BIANGLALA BRAINROT") and a tower ("MENARA BRAINROT").

- **24 original characters** — Indonesian food and household-object memes
  (Bambang Blender, Rudi Rice Cooker, Sultan Soto Sulaiman, Kosmik Rice
  Cooker…) across 6 rarities, Common to Divine, $25 to $4,000,000.
- **Mutations** — Gold ×2 (10%), Diamond ×3 (4%), Rainbow ×5 (1.5%) multiply
  both price and income.
- **Income loop** — pads bank cash every second; step on the green pad (or
  tap PANEN) to harvest it all.
- **Lock** — seal your base for 60 seconds behind a force-field barrier.
- **Thief NPC** — periodically steals the richest brainrot from any
  *unlocked* base.
- **Tsunami** — every 180 seconds (10s warning) the wave washes away belt
  brainrots and kills anyone caught outside a base.
- **Rebirth** — reset cash and brainrots for a permanent +0.75× income
  multiplier; cost 10,000 × 3^rebirths. Two-tap button, no accidents.
- **Gacha** — an escalating-price machine in the plaza; your prize walks
  across the map to a free pad in your base. Full base = never charged.
- **Buku Koleksi** — a collection index: owned brainrots lit with stats,
  unowned ones shown as "???" silhouettes.

## Layout of the code

- `src/shared/BrainrotData.luau` — the character catalogue, rarities,
  mutations and roll tables (shared by server and client).
- `src/server/GameState.luau` — all per-player state and money rules.
- `src/server/WorldBuilder.luau` — builds the whole world from parts, with
  every layout coordinate in one `Layout` table.
- `src/server/BrainrotFactory.luau` — procedural character models and the
  Divine sparkle burst.
- `src/server/MoveService.luau` — XZ waypoint walking with the pivot Y
  pinned to the floor the walker registered for.
- `src/server/Thief.luau`, `src/server/GachaService.luau` — the thief NPC
  and the gacha machine.
- `src/server/init.server.luau` — bootstrap: remotes, prompts, belt
  spawner, income tick, tsunami clock, plaza animation.
- `src/client/Hud.client.luau` — cash / income / stored HUD, tsunami
  countdown, toasts, action buttons.
- `src/client/Index.client.luau` — the Buku Koleksi book.

## Build and hand in

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

`main.ts` (Node 22, standard library only) copies `game.rbxl`, `src/`,
`screenshots/` and `PLAY.json` to the output folder and writes
`dossier.json` with `vendor/makefun-roblox.ts`, the kit's library,
unchanged.

## Controls

- Walk up to a belt brainrot and press its **Beli** prompt to buy it.
- **PANEN** button, the green pad's prompt, or `C` — harvest stored cash.
- **KUNCI BASE** button, the lock post's prompt, or `L` — lock for 60s.
- **GACHA** button, the machine's prompt, or `G` — roll the gacha.
- **REBIRTH** — tap twice within 3 seconds to confirm.
- **BUKU KOLEKSI** button or `B` — open the collection index.
