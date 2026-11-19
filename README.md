# Brainrot Bazaar

A Steal-a-Brainrot-style 3D Roblox tycoon, built entirely in procedural Luau —
no external assets. Published at
https://www.roblox.com/games/108382585327542

## How to play

- **Buy brainrots**: characters walk along the conveyor belt in the Toko
  Brainrot. Click one to buy it onto a free pad in your base (8 bases x 6 pads).
- **Earn**: each brainrot pays income every second into your base's stored cash.
  Click the green collect pad to take it.
- **Lock your base**: click the red lock button to seal your base for 60 seconds
  — the thief can't steal from a locked base.
- **Beware the thief**: every 90 seconds a thief tries to steal the richest
  brainrot from an unlocked base.
- **Tsunami**: every 180 seconds a wave sweeps the map (10s warning). It washes
  away the belt and kills anyone caught outside a base.
- **Gacha**: the machine in the plaza rolls a weighted-rarity brainrot for
  escalating cash. It walks to a free pad — full base, full refund.
- **Rebirth**: reset for a permanent +0.75x income multiplier per rebirth
  (cost 10,000 x 3^rebirths). Two taps to confirm.
- **Buku Koleksi**: the Collection Index lists all 24 characters — owned ones
  lit, unowned ones as `???`.

## The cast

24 original Indonesian-meme characters across 6 rarities (Common → Divine,
$25 → $4,000,000), with Gold x2 (10%), Diamond x3 (4%) and Rainbow x5 (1.5%)
mutations that multiply both price and income.

## The world

Conveyor shop with the TOKO BRAINROT arch, spawn pad, welcome sign, 8 plotted
bases, plaza fountain, 4 market stalls, the BIANGLALA BRAINROT ferris wheel,
MENARA BRAINROT tower, rainbow arch, 6 rarity billboards, trees, rocks and
lamp posts — all built in code by `src/server/WorldBuilder.luau`.

## Build

```sh
rojo build default.project.json --output game.rbxl
```

Hand in with `main.ts` (Node 22+):

```sh
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

## Layout

- `src/shared/BrainrotData.luau` — the 24 characters, rarities, mutations, gacha weights
- `src/server/init.server.luau` — wiring: shop, income, tsunami, rebirth, remotes
- `src/server/WorldBuilder.luau` — the whole procedural world
- `src/server/BrainrotFactory.luau` — procedural character models + Divine sparkles
- `src/server/MoveService.luau` — XZ-plane belt riding and walking (Y pinned)
- `src/server/GameState.luau` — in-memory player data + remotes
- `src/server/Thief.luau` — the stealing NPC
- `src/server/GachaService.luau` — the plaza gacha machine
- `src/client/Hud.client.luau` — cash/income/stored panel, tsunami countdown, toasts, rebirth
- `src/client/Index.client.luau` — Buku Koleksi

## License

MIT — see `LICENSE`.
