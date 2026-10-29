#!/usr/bin/env python3
"""Prime-type glyphs (GlyphProperties type 2): Atonement, Void Lasher, Spellstriker and Bound Fiend.

Writes one data/sql/db-world/zz_moonlit_primeglyph_<n>_*.sql per glyph. Four records each, allocated in the registry:

  spell_dbc            <id>   installer: a clone of Glyph of Smite's use spell (56182) whose APPLY_GLYPH effect names the GlyphProperties row
  glyphproperties_dbc  <gid>  SpellID = the hidden passive that IS the glyph (the Favor's first aura), type 2 (Prime), icon 3122 (UI-Glyph-Rune-2)
  item_dbc             <id>   a Glyph of Smite clone row (class 16, subclass 5, display 58834)
  item_template        <id>   Glyph of Smite (42416) cloned, renamed, use spell <id>, RequiredLevel 1

  Atonement      priest block 1,610,000: item and installer 1,610,020, GlyphProperties 16,100, aura 1,610,010 (zz_..._20_atonement_glyph.sql)
  Cauterizer     mage fire block 1,420,000: item and installer 1,420,140, GlyphProperties 14,201, aura 1,420,060 (zz_..._24_cauterizer_glyph.sql)
  Spellstriker   mage block 1,440,100 (Spellblade recipes): item and installer 1,440,290, GlyphProperties 14,401, aura 1,440,270 (zz_..._22_spellstriker_glyph.sql)
  Void Lasher    priest block 1,630,000: item and installer 1,630,100, GlyphProperties 16,300, aura 1,630,070 (zz_..._21_void_lasher_glyph.sql)
                 (the glyph also needs the wand passive 1,630,080 and the loss of Mind Flay and Mind Sear: those come from the Favor data, see
                 tools/build_primeglyph_data.py)
  Bound Fiend    priest block 1,630,000: item and installer 1,630,110, GlyphProperties 16,301, aura 1,630,050 (zz_..._23_bound_fiend_glyph.sql)
                 (the Favor also takes the stock Shadowfiend spell 34433 away: from the Favor data, as for the Void Lasher)

Type 2 matches no real glyph socket (core EffectApplyGlyph and the client both need equal types), so the glyph can only be socketed through the Prime
socket (lua_scripts/primeglyph). Gen-1 record of Atonement: docs/legacy/gen1-repo/docs/Atonement Project/Ruling_Atonement_Glyph_Build.md.

Run:  python -I tools/gen_prime_glyph.py < /dev/null      (database up; READ-ONLY, nothing is written to a database)
Then the client patch needs one Phase 2 manifest line per glyph (docs/Ruling_Phase2_Manifest.csv):
  Spell,<id>,new,ours,4,<id>,custom: <name> (installer)
The Item and GlyphProperties client rows come from the overlay tables (tools/clientpatch/build.py reads them), so they need no manifest line.
~Moonlit Nights Team
"""
import sys
from pathlib import Path

ROOT = next(p for p in Path(__file__).resolve().parents if (p / "tools" / "mn.py").exists())
MODULE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools" / "talents"))      # spellkit pulls in tools/phase2 itself
import spellkit as k  # noqa: E402
import gen_sql as gs  # noqa: E402

ICON = 3122
DONOR_SPELL, DONOR_ITEM = 56182, 42416
OUT_DIR = MODULE / "data" / "sql" / "db-world"
GLYPHS = [
    dict(cls=5, item=1610020, glyph=16100, aura=1610010, name="Glyph of Atonement", file="zz_moonlit_primeglyph_20_atonement_glyph.sql",
         text="Your Smite and Holy Fire deal 50% less damage, but heal a nearby injured ally for 200% of the damage dealt."),
    dict(cls=5, item=1630100, glyph=16300, aura=1630070, name="Glyph of the Void Lasher", file="zz_moonlit_primeglyph_21_void_lasher_glyph.sql",
         text="You lose Mind Flay and Mind Sear. Spell haste becomes attack speed, and each different damage over time you keep up calls a Tentacle "
              "of the Old Gods that lashes nearby enemies. Mind Blast makes every tentacle lash again. Wand hits may reset Mind Blast."),
    dict(cls=5, item=1630110, glyph=16301, aura=1630050, name="Glyph of the Bound Fiend", file="zz_moonlit_primeglyph_23_bound_fiend_glyph.sql",
         text="You keep a permanent Shadowfiend that hits 30% harder, and your Shadow talents feed it. The Shadowfiend no longer returns mana, and you lose the Shadowfiend spell."),
    dict(cls=11, item=1220100, glyph=12201, aura=1220090, name="Glyph of the Pack Hunting", file="zz_moonlit_primeglyph_32_pack_hunting_glyph.sql",
         text="A companion of the hunter pet system fights beside you in Cat Form. You and it deal more damage while close together, and your Mangle and Rake bleeds are weaker."),
    dict(cls=7, item=1820180, glyph=18202, aura=1820070, name="Glyph of the Greatsword", file="zz_moonlit_primeglyph_31_greatsword_glyph.sql",
         text="You fight with one big two-handed weapon: Stormstrike and Windfury hit harder the slower the weapon, Earth Slam replaces Lava Lash, and the off-hand slot stays empty."),
    dict(cls=7, item=1820110, glyph=18201, aura=1820080, name="Glyph of the Spirit Healer", file="zz_moonlit_primeglyph_30_spirit_healer_glyph.sql",
         text="You deal 50% less damage, but your weapon strikes heal the group member with the lowest health for 85% of your normal damage, and your Spirit Wolves heal too."),
    dict(cls=2, item=1530150, glyph=15301, aura=1530140, name="Glyph of the Dual Verdict", file="zz_moonlit_primeglyph_29_dual_verdict_glyph.sql",
         text="You fight with a one-handed weapon in each hand and keep two Seals up. Judgement judges both Seals and Crusader Strike also strikes with your off-hand weapon."),
    dict(cls=8, item=1410110, glyph=14101, aura=1410090, name="Glyph of the Missile Storm", file="zz_moonlit_primeglyph_28_missile_storm_glyph.sql",
         text="Arcane Missiles deals 30% more damage and can be cast and channelled while moving, but the missiles cannot critically strike while you move."),
    dict(cls=6, item=1140250, glyph=11405, aura=1140190, name="Glyph of the Bloodforged Bulwark", file="zz_moonlit_primeglyph_26_bloodforged_bulwark_glyph.sql",
         text="Death Strike no longer heals you. It forges an over-shield from the damage you took in the last 5 seconds, and Improved Death Strike makes that shield larger."),
    dict(cls=6, item=1140270, glyph=11407, aura=1140200, name="Glyph of the Frozen Bastion", file="zz_moonlit_primeglyph_27_frozen_bastion_glyph.sql",
         text="Rune Strike needs no dodge or parry and gives a stack of Frozen Plate. Toughness makes each stack stronger and Anticipation turns the stacks into dodge."),
    dict(cls=6, item=1140220, glyph=11402, aura=1140230, name="Glyph of the Unbroken Bones", file="zz_moonlit_primeglyph_25_unbroken_bones_glyph.sql",
         text="Bone Shield no longer raises your damage done, and every Plague Strike or Scourge Strike adds one bone to it, up to the most it can hold."),
    dict(cls=8, item=1420140, glyph=14201, aura=1420060, name="Glyph of the Cauterizer", file="zz_moonlit_primeglyph_24_cauterizer_glyph.sql",
         text="Your damage is 50% lower, but your Fire damage heals the ally with the lowest health in your group for 75% of your normal damage, and you learn Cauterize, "
              "Phoenix Flame, Hearth Fire and Ember Ward."),
    dict(cls=8, item=1440290, glyph=14401, aura=1440270, name="Glyph of the Spellstriker", file="zz_moonlit_primeglyph_22_spellstriker_glyph.sql",
         text="You fight in melee: Arcane Blast and Arcane Missiles become weapon and uninterruptible versions, you call melee Mirror Images, and Intellect gives 2 attack power each. You lose Mana Ward."),
]


def build(g):
    ITEM_ID = SPELL_ID = g["item"]
    GLYPH_ID, AURA, NAME, TEXT, OUT = g["glyph"], g["aura"], g["name"], g["text"], OUT_DIR / g["file"]
    row = k.make(SPELL_ID, DONOR_SPELL, (NAME, TEXT, ""))
    ix = k.IDX
    assert row[ix["Effect_1"]] == 74, "donor effect 1 is not APPLY_GLYPH"
    row[ix["EffectMiscValue_1"]] = GLYPH_ID
    assert row[0] == SPELL_ID and all(ord(c) < 128 and c != "'" for c in NAME + TEXT) and len(TEXT) <= 255
    if not OUT.exists():        # first generation: the IDs must be free (regenerating an applied file finds its own rows)
        assert SPELL_ID not in k.g2.ids("Spell"), f"spell {SPELL_ID} already exists in the binary DBC or the live overlay"
        assert not k.g2.row("Item", ITEM_ID), f"item {ITEM_ID} already exists in Item.dbc or item_dbc"
        assert not k.g2.row("GlyphProperties", GLYPH_ID), f"GlyphProperties {GLYPH_ID} already exists"

    donor = k.g2.row("Item", DONOR_ITEM)
    assert donor and donor[1] == 16 and donor[2] == 5, "Glyph of Smite Item.dbc row not found"
    item_vals = [ITEM_ID] + [int(v) for v in donor[1:]]
    CLS = g["cls"]
    item_vals[2] = CLS                  # Item.dbc SubclassID: glyph subclass = class id

    cols = ", ".join(f"`{c[0]}`" for c in k.COLS)
    vals = ", ".join(gs.q(v, k.COLS[i][1]) for i, v in enumerate(row))
    sql = f"""-- Moonlit Prime Glyph: {NAME}, a Prime-type glyph (type 2). Generated by tools/gen_prime_glyph.py; do not edit by hand.
-- Installer spell {SPELL_ID} (full overlay row cloned from stock {DONOR_SPELL}), GlyphProperties {GLYPH_ID} (aura {AURA}, type 2, icon {ICON}),
-- Item.dbc row and item_template {ITEM_ID} (cloned from Glyph of Smite {DONOR_ITEM}). Idempotent (delete by exact ID, then insert). ~Moonlit Nights Team
DELETE FROM `spell_dbc` WHERE `ID` = {SPELL_ID};
INSERT INTO `spell_dbc` ({cols}) VALUES
({vals});

DELETE FROM `glyphproperties_dbc` WHERE `ID` = {GLYPH_ID};
INSERT INTO `glyphproperties_dbc` (`ID`, `SpellID`, `GlyphSlotFlags`, `SpellIconID`) VALUES ({GLYPH_ID}, {AURA}, 2, {ICON});

DELETE FROM `item_dbc` WHERE `ID` = {ITEM_ID};
INSERT INTO `item_dbc` (`ID`, `ClassID`, `SubclassID`, `Sound_Override_Subclassid`, `Material`, `DisplayInfoID`, `InventoryType`, `SheatheType`) VALUES ({", ".join(str(v) for v in item_vals)});

DELETE FROM `item_template` WHERE `entry` = {ITEM_ID};
CREATE TEMPORARY TABLE `mn_glyph_clone` AS SELECT * FROM `item_template` WHERE `entry` = {DONOR_ITEM};
UPDATE `mn_glyph_clone` SET `entry` = {ITEM_ID}, `name` = '{NAME}', `description` = '{TEXT}', `spellid_1` = {SPELL_ID}, `RequiredLevel` = 1, `subclass` = {CLS}, `AllowableClass` = {1 << (CLS - 1)};
INSERT INTO `item_template` SELECT * FROM `mn_glyph_clone`;
DROP TEMPORARY TABLE `mn_glyph_clone`;
"""
    OUT.write_text(sql, encoding="utf-8", newline="\n")
    print(f"wrote {OUT}")
    print(f"manifest line: Spell,{SPELL_ID},new,ours,4,{SPELL_ID},custom: {NAME} (installer)")


for _g in GLYPHS:
    build(_g)
