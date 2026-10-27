-- Moonlit Prime Glyph: stock spells a Prime glyph took away from a character (the Void Lasher loses Mind Flay and Mind Sear), so they can be given
-- back exactly as removed when the glyph is gone or another talent spec is active. Spells belong to the character, not the spec. Idempotent.
-- Add this table to the character-wipe cascade list in docs/Ruling_Lessons_Learned.md (guid-keyed).
CREATE TABLE IF NOT EXISTS `moonlit_prime_glyph_removed` (
  `guid` INT UNSIGNED NOT NULL,
  `spell` INT UNSIGNED NOT NULL COMMENT 'stock spell id the glyph removed',
  PRIMARY KEY (`guid`, `spell`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='mod-moonlit-primeglyph';
-- ~Moonlit Nights Team
