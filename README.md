# makefun-roblox-brainrot-01

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/slowlyor/makefun-roblox-brainrot-01/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/slowlyor/makefun-roblox-brainrot-01/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

**Brainrot Bazaar** — an original 3D "steal-a-brainrot" game for Roblox, built entirely procedurally: the server builds the whole world (map, shop conveyor, eight player bases, characters) out of parts at runtime, so the place runs the moment Play is pressed, with no assets to import. Brainrot characters ride the shop conveyor with price tags on their heads; buy one and it sprints to your base, stands on a pad and earns cash every second. Bank the cash on your base's green collect pad and climb the ladder — Common → Rare → Epic → Legendary → Mythic → Divine — with Gold (x2), Diamond (x3) and Rainbow (x5) mutations across 18 original Indonesian-meme characters (Bambang Blender, Kakek Kulkas, Ratu Rendang Abadi, TITAN TUMIS GALAKSI, ...). A tsunami sweeps the map every 3 minutes and washes away anything caught outside a base, a wandering thief (Maling) steals the richest brainrot from unlocked bases (lock yours for 60 s), and Rebirth trades a full reset for a permanent +0.75x income multiplier. Play it live: https://www.roblox.com/games/108382585327542

Layout: `default.project.json` is the Rojo project (`src/shared` → ReplicatedStorage, `src/server` → ServerScriptService, `src/client` → StarterPlayerScripts). `src/shared/BrainrotData.luau` holds the rarities, mutations and cast; `src/server/` holds the game loop (`init.server.luau`), the procedural map (`WorldBuilder.luau`), characters (`BrainrotFactory.luau`), the pivot-stepping walker (`MoveService.luau`), the heist AI (`Thief.luau`) and shared state (`GameState.luau`); `src/client/Hud.client.luau` is the HUD. `main.ts` hands the entry in: it copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to the output directory and writes `dossier.json` via `vendor/makefun-roblox.ts` (the kit's library, unchanged).

## Run it

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

Then open `game.rbxl` in Roblox Studio and press Play — or play the published place: https://www.roblox.com/games/108382585327542

---

<sub>Entered on [make.fun](https://make.fun/?ref=vxw5vmyv&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>
