# Prime Glyph: design and generation-2 changes

Last updated 2026-10-19. Ported from the recovered gen-1 module (rev 5, 2026-09-17).

## Why it is virtual
The core and the client have exactly six glyph sockets (`MAX_GLYPH_SLOT_INDEX`, the player update fields, `character_glyphs`,
the talent packet, the client's C glyph functions). A seventh is therefore server logic plus a client add-on:

```
client add-on (centre socket)  --SET:<item> / USE:<spell> / CLR / Q-->  ALE (lua_scripts/primeglyph)
   right-click glyph, click socket                                     validate, cast Prime Inscription,
                                <--S: / C: / L:--                      on completion consume item, store per spec,
                                                                        cast the glyph's passive aura
```
A glyph's effect is its passive aura (`GlyphProperties.SpellId`), and the core and scripts check glyphs with `HasAura`, so an aura
cast by the script behaves like one from a real socket.

## The cast
A real glyph is inscribed by its item's use spell (`APPLY_GLYPH`, which writes into a real slot). The Prime socket casts its own
spell instead: **Prime Inscription, 5,800,010**, a clone of Glyph of Smite's use spell (56182) keeping Blizzard's cast time
(index 6), "not in combat" (attribute 0x10000000), interrupt flags 63 and the inscription visual, with `Targets` 0 and one DUMMY
effect on the caster. `PLAYER_EVENT_ON_SPELL_CAST` fires from `Spell::_cast`, before the core's final `CheckCast`, so the script
re-checks everything (combat, item, spec) when the cast completes. An interrupted cast changes nothing.

## Changes from generation 1
| Gen 1 | Gen 2 |
|---|---|
| Spell 110030 Prime Inscription | **5,800,010** (Registry section 8, block 5,800,000) |
| Glyph of Atonement (item 60000, GlyphProperties 912, type 2) was the only Prime-type glyph | Atonement is the Penitent's Favor; **dropped**. No Prime-type glyph exists, so `PRIME_GLYPH_ITEMS` is empty and the "Prime Glyph" tooltip relabel never fires. The mechanism is kept |
| 351 glyphs in the table | **281**: 351 minus Atonement minus 69 Shaman/Priest glyphs |
| Every class | Shaman and Priest excluded (they use Favors); decided in `EXCLUDED_CLASSES` |
| Module held Lua, add-on and core patch | Lua in `lua_scripts/primeglyph/`, add-on in `client-addon/MoonlitPrimeGlyph/`, SQL here. The core patch (`glyph-slot-levels.patch`) is not ported: the core and client part is done by the integrator |
| DBC edited by script on both copies | One `spell_dbc` overlay row (the client patch builder reads the live overlay through the manifest) |
| Glyph items got RequiredLevel from Start Me Up | `zz_moonlit_primeglyph_11_glyph_items.sql` sets class 16 items to RequiredLevel 1 |

## A real Prime-type glyph needs (built for Glyph of Atonement, 2026-10-27)
A `GlyphProperties` row with TypeFlags 2 (a narrow 16-bit ID: allocate in the 58,000 mirror), added to **both** the server and the
client copy of `GlyphProperties.dbc` (the `glyphproperties_dbc` overlay table is empty and the build does not write the client copy),
a passive aura spell, the glyph item and its use spell with `APPLY_GLYPH`. Built for **Glyph of Atonement** by `tools/gen_atonement_glyph.py` (`zz_moonlit_primeglyph_20_atonement_glyph.sql`): item and installer spell 1,610,020, `glyphproperties_dbc` row 16,100 (type 2, aura 1,610,010 = the Favor of Atonement passive, which is the glyph's whole effect), `item_dbc` row; the client copies come from the overlay tables through `tools/clientpatch/build.py` (GlyphProperties and Item) plus the manifest line for the spell. Every further Prime-type glyph follows the same four records.

## Known limits (unchanged from gen 1)
- No real socket: the glyph does not appear in the talent packet, so other players inspecting the character, the armory and addons
  reading `GetGlyphSocketInfo` do not see it.
- A player without the add-on keeps an inscribed Prime glyph but cannot change it.
- Viewing the inactive spec in the talent UI still shows the active spec's Prime glyph.
- No learn packet (`SendLearnPacket`) is sent, so tooltips of spells the glyph modifies do not reflect it. Mechanics are unaffected.
- The glyph aura is cast with the full triggered mask, slightly more permissive than the core's own cast.

~Moonlit Nights Team
