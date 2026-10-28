# Earn ESP models

New models for **Earn ESP (Incremental)**, saved here so they can be added to
the game later:

- **Weapons:** 10 new guns based on the gun pictures in the vault's
  Inspiration note. They're written in the same part-list format as the
  game's 8 guns (`GunModels.luau`), so every gun skin works on them.
- **Characters:** new bot types, three cheater bosses with their own trash
  talk, and friendly lobby NPCs. Their outfits are built like the bots' caps,
  visors and capes in `Bots.luau`.
- **Environment:** new map props written like `Kit.luau`, plus four maps that
  use them.

Everything is Luau that builds the models from Parts. The files sit at the
same paths as in the game's Rojo project. [INSTALL.md](INSTALL.md) lists what
to copy and the few hook lines to add.

## Previews

`previews/` has a picture of every model. The pictures are made by the
preview tool in `tools/preview`, which runs the builder scripts outside
Studio:

```sh
cd tools/preview && npm install && cd ../..
export EARNESP_SRC=/path/to/EarnEsp/src   # the game's src folder, with the INSTALL.md hooks added
lune run tools/preview/check.luau          # checks guns, bots, maps and props against the game's code
tools/preview/preview.sh tools/preview/scenes/guns.luau out/guns   # renders PNGs to out/guns/png
```

The tool needs [Lune](https://github.com/lune-org/lune), StyLua, Node and
Playwright's Chromium.
