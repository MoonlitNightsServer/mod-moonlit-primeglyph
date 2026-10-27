# mod-moonlit-primeglyph

**Moonlit Nights, generation 2: the Prime glyph.** A virtual seventh glyph socket in the centre of the glyph panel, open from
level 1, for the classes that do not have Moonlit Blessings yet. It takes any Major or Minor glyph of the player's class (one per
talent spec), consumed when inscribed, like a real socket. Shaman and Priest use a Favor instead and do not get it.

> This folder holds the **SQL, the C++ loader and the documentation only.** The two parts that do the work live in the main
> repo, because that is where the deploy and the client install read them from:
>
> | Part | Where |
> |---|---|
> | Server logic and glyph data (ALE Lua) | `lua_scripts/primeglyph/` (`primeglyph_core.lua`, `primeglyph_data.lua`) |
> | Client add-on | `client-addon/MoonlitPrimeGlyph/` |
>
> `python tools/mn.py deploy` copies `lua_scripts/` into the server. The six real sockets (levels 10 to 60) are done in the core
> and the client patch, not here.

## What is in this module

```
src/mod_moonlit_primeglyph_loader.cpp                  empty loader, so the build sees the module and applies its SQL
data/sql/db-characters/zz_moonlit_primeglyph_01_tables.sql   moonlit_prime_glyph (guid, spec, item)
data/sql/db-world/zz_moonlit_primeglyph_10_spell_dbc.sql     Prime Inscription, spell 5,800,010 (full spell_dbc overlay row, generated)
data/sql/db-world/zz_moonlit_primeglyph_11_glyph_items.sql   glyph items usable from level 1
tools/gen_prime_inscription.py      writes the _10_ file (read-only database access)
tools/build_primeglyph_data.py      writes lua_scripts/primeglyph/primeglyph_data.lua from item_template + Spell + GlyphProperties
tools/mock_primeglyph_test.lua      offline server test (luajit)
tools/mock_client_test.lua          offline add-on test (luajit)
docs/DESIGN.md                      design, what changed from gen 1, limits
```

## Rules

- **Level:** the socket opens at level 1.
- **Class:** the glyph must be for the player's class. Shaman and Priest are refused (`EXCLUDED_CLASSES`, set in three places:
  the Lua core, the add-on and the data generator).
- **Inscribing:** right-click the glyph, then click the Prime socket. The server casts "Prime Inscription" (a glyph's cast bar,
  not usable in combat); the glyph goes in, and the item is consumed, when the cast completes. Shift-right-click removes.
- **Per spec:** each talent spec has its own Prime glyph. A glyph already in one of the six real sockets is refused.
- **Types:** Major and Minor fit (`ALLOW_MAJOR` / `ALLOW_MINOR` in the Lua core). A Prime-type glyph (GlyphProperties type 2)
  always fits; Glyph of Atonement (item 1,610,020) is the first.

## Rebuilding the generated files

```
python -I core/modules/mod-moonlit-primeglyph/tools/gen_prime_inscription.py < /dev/null
python -I core/modules/mod-moonlit-primeglyph/tools/build_primeglyph_data.py < /dev/null
luajit core/modules/mod-moonlit-primeglyph/tools/mock_primeglyph_test.lua
luajit core/modules/mod-moonlit-primeglyph/tools/mock_client_test.lua
```

The client patch needs this Phase 2 manifest line so the spell reaches the client: `Spell,5800010,new,ours,4,5800010,custom: prime glyph (Prime Inscription)`.

~Moonlit Nights Team
