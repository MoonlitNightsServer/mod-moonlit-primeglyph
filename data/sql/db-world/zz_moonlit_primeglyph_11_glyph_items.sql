-- Moonlit Prime Glyph: every glyph item can be used from level 1, so a level-1 character can fill the Prime socket (and a
-- level-10 character the first real socket). Stock glyphs ask for level 15 to 80 and the client refuses to use an item below
-- its level, so USE_GLYPH would never fire. Only existing base rows change (no custom ID). Idempotent. ~Moonlit Nights Team
UPDATE `item_template` SET `RequiredLevel` = 1 WHERE `class` = 16 AND `RequiredLevel` > 1;
