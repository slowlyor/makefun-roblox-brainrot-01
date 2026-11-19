# Brainrot Bazaar

A Steal-a-Brainrot-style 3D tycoon for Roblox, built entirely from
procedural Luau -- no external assets, no uploaded meshes, in-memory
state only (no DataStore). Indonesian food and household objects come
alive as collectible brainrots: a blender, a rice cooker, a speaker, a
fan, satay skewers, a rendang pot, an omelet, a sambal jar, and 16 more.

## How it plays

- **Conveyor belt shop.** Brainrots spawn under the TOKO BRAINROT arch
  and ride a 140-stud conveyor across the plaza. Walk up and buy one
  with its prompt; it hops off the belt and walks home to a free pad in
  your base (8 bases x 6 pads).
- **Income and harvesting.** Each placed brainrot earns $/s into a
  stored pool. Stand on your base's green collect pad to bank it.
- **24 characters, 6 rarities.** Common to Divine, $25 to $4,000,000,
  income scaling with price. Mutations -- Gold x2 (10%), Diamond x3
  (4%), Rainbow x5 (1.5%) -- multiply both price and income.
- **Lock your base.** The lock button (or the HUD) seals your base for
  60 seconds.
- **The thief.** A thief NPC periodically stalks the richest brainrot
  in an UNLOCKED base, walks over and steals it. Locked bases are
  skipped entirely.
- **Tsunami.** Every 180 seconds, after a 10-second warning, a wave
  washes away belt brainrots and kills any player caught outside a
  base. Placed brainrots stay safe -- the dash home is yours.
- **Gacha machine.** On the plaza: an escalating price per roll, a
  weighted-rarity prize that walks to a free pad in your base, and a
  full refund if your base is full.
- **Rebirth.** Reset cash and brainrots for a permanent +0.75x income
  multiplier per rebirth; cost 10,000 x 3^rebirths. The HUD button is
  two-tap so it never fires by accident.
- **Buku Koleksi.** The collection index (button or the B key): owned
  brainrots lit with stats, the rest as "???" silhouettes.

## The world

A fountain plaza with market stalls and a rainbow arch, a spinning
ferris wheel (BIANGLALA BRAINROT), a tapering tower (MENARA BRAINROT)
with a beacon, six rarity billboards along the belt, trees, rocks and
lamp posts -- every part placed on the ground by WorldBuilder, every
sign on posts. Divine spawns (and Rainbow gacha prizes) arrive with a
burst of procedural sparkle parts, because a $4,000,000 rendang god
should never enter quietly.

Controls in one line: walk with the usual Roblox controls, use the
prompts on belt brainrots, pads and buttons, tap the HUD buttons for
gacha / lock / collect / rebirth, and press B for the collection book.

## Layout of the code

- `src/shared/BrainrotData.luau` -- the cast, rarities, mutations and
  money formatting; the one source of truth for server and client.
- `src/server/GameState.luau` -- all mutable state: players, pads,
  locks, rebirth math, gacha pricing, client snapshots.
- `src/server/WorldBuilder.luau` -- the whole map, built from the
  layout constants in its LAYOUT table.
- `src/server/BrainrotFactory.luau` -- procedural character models
  with nameplates.
- `src/server/MoveService.luau` -- XZ steering with the pivot Y pinned
  absolutely from the walker's current surface.
- `src/server/Thief.luau`, `src/server/GachaService.luau` -- the
  threat and the machine.
- `src/server/init.server.luau` -- bootstrap: remotes, economy loops,
  belt spawner, tsunami clock, client actions.
- `src/client/Hud.client.luau` -- cash/income/stored panel, tsunami
  countdown, toasts, gacha/lock/collect/rebirth buttons.
- `src/client/Index.client.luau` -- the Buku Koleksi book.

## Build with Rojo

    rojo build default.project.json --output game.rbxl

`default.project.json` maps `src/shared` to ReplicatedStorage,
`src/server` to ServerScriptService and `src/client` to
StarterPlayerScripts. Then publish `game.rbxl` over the experience
named in PLAY.json from Roblox Studio.

## Hand in (make.fun)

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

`main.ts` copies game.rbxl, src/, screenshots/ and PLAY.json to the
output directory and writes dossier.json with the vendored library in
vendor/ (the kit's copy, unchanged).
