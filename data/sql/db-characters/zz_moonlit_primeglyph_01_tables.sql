-- Moonlit Prime Glyph: the glyph in the virtual seventh socket, per character and talent spec. Idempotent (CREATE IF NOT EXISTS).
-- Add this table to the character-wipe cascade list in docs/Ruling_Lessons_Learned.md (guid-keyed).
CREATE TABLE IF NOT EXISTS `moonlit_prime_glyph` (
  `guid` INT UNSIGNED NOT NULL,
  `spec` TINYINT UNSIGNED NOT NULL COMMENT '0 primary, 1 secondary',
  `item` INT UNSIGNED NOT NULL COMMENT 'glyph item entry',
  PRIMARY KEY (`guid`, `spec`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='mod-moonlit-primeglyph';
-- ~Moonlit Nights Team
