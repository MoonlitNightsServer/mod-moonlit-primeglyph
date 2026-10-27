-- Offline logic test for lua_scripts/primeglyph/primeglyph_core.lua against a MOCK ALE (gen 2).
-- Run from the repo root:  luajit core/modules/mod-moonlit-primeglyph/tools/mock_primeglyph_test.lua
local reg, db, sent = {}, {}, {}
function RegisterServerEvent(e, f) reg["s" .. e] = f end
function RegisterPlayerEvent(e, f) reg["p" .. e] = f end
local removedDb = {}      -- moonlit_prime_glyph_removed: guid:spell
function CharDBExecute(sql)
    if sql:find("moonlit_prime_glyph_removed", 1, true) then
        local g, sp = sql:match("VALUES %((%d+), (%d+)%)")
        if g then removedDb[g .. ":" .. sp] = true return end
        g, sp = sql:match("guid = (%d+) AND spell = (%d+)")
        if g then removedDb[g .. ":" .. sp] = nil return end
        g = sql:match("guid = (%d+)$")
        if g then for k in pairs(removedDb) do if k:match("^" .. g .. ":") then removedDb[k] = nil end end return end
        error(sql)
    end
    local g, sp, it = sql:match("VALUES %((%d+), (%d+), (%d+)%)")
    if g then db[g .. ":" .. sp] = tonumber(it) return end
    g, sp = sql:match("guid = (%d+) AND spec = (%d+)")
    if g then db[g .. ":" .. sp] = nil return end
    g = sql:match("guid = (%d+)$")
    if g then for k in pairs(db) do if k:match("^" .. g .. ":") then db[k] = nil end end return end
    error(sql)
end
function CharDBQuery(sql)
    if sql:find("moonlit_prime_glyph_removed", 1, true) then
        local g, rows = sql:match("guid = (%d+)"), {}
        for k in pairs(removedDb) do local kg, ks = k:match("(%d+):(%d+)") if kg == g then rows[#rows + 1] = tonumber(ks) end end
        if #rows == 0 then return nil end
        local i = 1
        return { GetUInt32 = function() return rows[i] end, NextRow = function() i = i + 1 return i <= #rows end }
    end
    local g = sql:match("guid = (%d+)")
    local rows = {}
    for k, v in pairs(db) do local kg, ks = k:match("(%d+):(%d+)") if kg == g then rows[#rows + 1] = { tonumber(ks), v } end end
    if #rows == 0 then return nil end
    local i = 1
    return { GetUInt32 = function(_, c) return rows[i][c + 1] end,
             NextRow = function() i = i + 1 return i <= #rows end }
end
local _print = print; print = function() end
dofile("lua_scripts/primeglyph/primeglyph_data.lua")
dofile("lua_scripts/primeglyph/primeglyph_core.lua")
print = _print

local function P(guid, class, level)
    local p = { guid = guid, class = class, level = level, spec = 0, auras = {}, spells = {}, glyphs = {}, bag = {}, ev = {} }
    local M = {}
    function M:GetGUIDLow() return self.guid end
    function M:GetName() return "P" end
    function M:GetClass() return self.class end
    function M:GetLevel() return self.level end
    function M:GetActiveSpec() return self.spec end
    function M:GetGlyph(i) return self.glyphs[i] or 0 end
    function M:HasItem(e, c) return (self.bag[e] or 0) >= c end
    function M:RemoveItem(e, c) self.bag[e] = self.bag[e] - c end
    function M:HasAura(s) return self.auras[s] == true end
    function M:HasSpell(s) return self.spells[s] == true end
    function M:LearnSpell(s) self.spells[s] = true end
    function M:RemoveSpell(s) self.spells[s] = nil end
    function M:RemoveAura(s) self.auras[s] = nil end
    function M:CastSpell(t, s, trig)
        if s == 5800010 then self.casting = (self.casting or 0) + 1 return end   -- inscription cast bar
        t.auras[s] = true
    end
    function M:IsInCombat() return self.combat == true end
    function M:SendAddonMessage(pre, m, t, r) sent[#sent + 1] = m end
    function M:RegisterEvent(f) self.ev[#self.ev + 1] = f end
    function M:Tick() for _, f in ipairs(self.ev) do f(0, 0, 0, self) end end
    return setmetatable(p, { __index = M })
end
local pass, fail = 0, 0
local function ok(n, c) if c then pass = pass + 1 else fail = fail + 1 _print("FAIL " .. n) end end
local function say(p, m) return reg.s30(30, p, 7, "MNPRIME", m, p) end

local WARRIOR, PRIEST, SHAMAN = 1, 5, 7
local MAJ, MAJ_AURA, MAJ_USE, MAJ_GLYPH = 43412, 58369, 58408, 490      -- Glyph of Bloodthirst
local MIN = 43395                                                       -- Glyph of Battle (minor)
local ICON = PRIME_GLYPHS[MAJ].icon
-- gen 2 has no Prime-type (type 2) glyph yet: invent one to prove the mechanism still works
local PRI, PRI_AURA, PRI_USE = 99999, 99990, 99991
PRIME_GLYPHS[PRI] = { glyph = 9999, spell = PRI_AURA, use = PRI_USE, class = WARRIOR, prime = true, icon = "I", name = "Test Prime" }
PRIME_GLYPH_ITEMS = { PRI }
PRIME_GLYPH_BY_USE[PRI_USE] = PRI

-- data facts
local n, byClass = 0, {}
for e, g in pairs(PRIME_GLYPHS) do if e ~= PRI then n = n + 1; byClass[g.class] = true end end
ok("data has glyphs", n > 200)
ok("no Priest or Shaman rows", not byClass[PRIEST] and not byClass[SHAMAN])

PrimeGlyph.CONFIG.CAST_SPELL = 0       -- the rules first, without the cast bar
local pr = P(7, WARRIOR, 0); pr.bag[MAJ] = 1; reg.p3(3, pr)
say(pr, "SET:" .. MAJ); ok("level gate", sent[#sent] == "S:0:0:level:0:" and not pr.auras[MAJ_AURA])
pr.level = 1
ok("swallowed", say(pr, "SET:" .. 40897) == false)                     -- a druid glyph
ok("class gate", sent[#sent] == "S:1:0:class:0:")
say(pr, "SET:12345"); ok("unknown item", sent[#sent] == "S:1:0:notglyph:0:")
say(pr, "SET:" .. MAJ); ok("set ok", sent[#sent] == "S:1:" .. MAJ .. ":ok:" .. MAJ_AURA .. ":" .. ICON)
ok("aura on", pr.auras[MAJ_AURA]); ok("item consumed", pr.bag[MAJ] == 0); ok("db row", db["7:0"] == MAJ)
say(pr, "SET:" .. MAJ); ok("same refused", sent[#sent] == "S:1:" .. MAJ .. ":same:" .. MAJ_AURA .. ":" .. ICON)
ok("other prefix ignored", reg.s30(30, pr, 7, "OTHER", "SET:1", pr) == nil)
-- spec swap: spec 1 empty -> aura off; back -> on
pr.spec = 1; pr:Tick(); ok("spec2 no aura", not pr.auras[MAJ_AURA])
pr.spec = 0; pr:Tick(); ok("spec1 aura back", pr.auras[MAJ_AURA])
-- relog restores from DB
reg.p4(4, pr); local pr2 = P(7, WARRIOR, 10); reg.p3(3, pr2); pr2:Tick()
ok("relog reapply", pr2.auras[MAJ_AURA])
-- duplicate with real slot refused
local pr3 = P(8, WARRIOR, 20); pr3.glyphs[0] = MAJ_GLYPH; pr3.bag[MAJ] = 1; reg.p3(3, pr3)
say(pr3, "SET:" .. MAJ); ok("dup refused", sent[#sent] == "S:1:0:duplicate:0:" and pr3.bag[MAJ] == 1)
-- clear keeps a real-slot aura
pr2.glyphs[0] = MAJ_GLYPH; say(pr2, "CLR")
ok("clear keeps real-slot aura", pr2.auras[MAJ_AURA] and db["7:0"] == nil)
pr2.glyphs[0] = 0; pr2.auras[MAJ_AURA] = true; say(pr2, "SET:" .. MAJ)
ok("no item -> refused", sent[#sent] == "S:1:0:noitem:0:")
-- no item, no aura after clear w/o real slot
local pr4 = P(9, WARRIOR, 10); pr4.bag[MAJ] = 1; reg.p3(3, pr4); say(pr4, "SET:" .. MAJ); say(pr4, "CLR")
ok("clear removes aura", not pr4.auras[MAJ_AURA])
-- right-click flow: identified by the item's use spell
local pr5 = P(11, WARRIOR, 1); pr5.bag[MAJ] = 1; reg.p3(3, pr5)
say(pr5, "USE:" .. MAJ_USE); ok("USE by spell", pr5.auras[MAJ_AURA] and pr5.bag[MAJ] == 0)
say(pr5, "USE:999999"); ok("USE unknown spell", sent[#sent]:find(":notglyph:", 1, true) ~= nil)
-- Q sends the socket rules and the Prime item list before the state
local n0 = #sent
say(pr5, "Q")
ok("Q rules", sent[n0 + 1] == "C:1:1" and sent[n0 + 2] == "L0" and sent[n0 + 3] == "L:" .. PRI
    and sent[n0 + 4]:match("^S:1:" .. MAJ .. ":ok:"))
ok("minor flag in data", PRIME_GLYPHS[MIN].minor == true and not PRIME_GLYPHS[MAJ].minor)
-- Major glyphs can be switched off; a Prime glyph still fits
PrimeGlyph.CONFIG.ALLOW_MAJOR = false
local pr6 = P(12, WARRIOR, 1); pr6.bag[MAJ] = 1; pr6.bag[PRI] = 1; pr6.bag[MIN] = 1; reg.p3(3, pr6)
say(pr6, "SET:" .. MAJ); ok("major refused when off", sent[#sent] == "S:1:0:major:0:" and pr6.bag[MAJ] == 1)
say(pr6, "SET:" .. PRI); ok("prime fits when major off", sent[#sent]:match("^S:1:" .. PRI .. ":ok:") ~= nil)
n0 = #sent; say(pr6, "Q"); ok("rules say major off", sent[n0 + 1] == "C:0:1")
PrimeGlyph.CONFIG.ALLOW_MAJOR = true
PrimeGlyph.CONFIG.ALLOW_MINOR = false
say(pr6, "SET:" .. MIN); ok("minor refused when off", sent[#sent]:find(":minor:", 1, true) ~= nil and pr6.bag[MIN] == 1)
PrimeGlyph.CONFIG.ALLOW_MINOR = true
-- Shaman and Priest use Favors: refused, nothing stored, no aura, the status says the socket is off
local ps = P(20, SHAMAN, 60); ps.bag[MAJ] = 1; reg.p3(3, ps)
say(ps, "SET:" .. MAJ); ok("shaman refused", sent[#sent]:match("^S:0:0:blessing:0:") ~= nil and ps.bag[MAJ] == 1 and db["20:0"] == nil)
local pp = P(21, PRIEST, 60); pp.bag[MAJ] = 1; reg.p3(3, pp)
say(pp, "SET:" .. MAJ); ok("priest refused", sent[#sent]:match("^S:0:0:blessing:0:") ~= nil and not pp.auras[MAJ_AURA])
say(pp, "Q"); ok("priest Q says off", sent[#sent]:match("^S:0:0:blessing:") ~= nil)
-- rev 5: the inscription CASTS; nothing happens until the cast completes
PrimeGlyph.CONFIG.CAST_SPELL = 5800010
local function done(p, id) reg.p5(5, p, { GetEntry = function() return id end }, false) end
local pc = P(13, WARRIOR, 1); pc.bag[MAJ] = 1; reg.p3(3, pc)
say(pc, "SET:" .. MAJ)
ok("cast started", pc.casting == 1 and sent[#sent] == "S:1:0:cast:0:")
ok("nothing consumed yet", pc.bag[MAJ] == 1 and not pc.auras[MAJ_AURA] and db["13:0"] == nil)
done(pc, 5800010)
ok("cast completes -> inscribed", pc.bag[MAJ] == 0 and pc.auras[MAJ_AURA] and db["13:0"] == MAJ)
ok("completion reply", sent[#sent] == "S:1:" .. MAJ .. ":ok:" .. MAJ_AURA .. ":" .. ICON)
local n1 = #sent
done(pc, 5800010)
ok("a stray completion does nothing", #sent == n1)
-- in combat: refused before any cast
local pd = P(14, WARRIOR, 1); pd.bag[MAJ] = 1; pd.combat = true; reg.p3(3, pd)
say(pd, "SET:" .. MAJ)
ok("combat refused", sent[#sent] == "S:1:0:combat:0:" and not pd.casting)
-- combat starts DURING the cast (hook fires before the core's final check)
pd.combat = false
say(pd, "SET:" .. MAJ); pd.combat = true; done(pd, 5800010)
ok("combat at completion refused", sent[#sent] == "S:1:0:combat:0:" and pd.bag[MAJ] == 1 and db["14:0"] == nil)
-- the glyph left the bags during the cast
pd.combat = false
say(pd, "SET:" .. MAJ); pd.bag[MAJ] = 0; done(pd, 5800010)
ok("item gone at completion", sent[#sent] == "S:1:0:noitem:0:")
-- spec swapped during the cast
local pe = P(15, WARRIOR, 1); pe.bag[MAJ] = 1; reg.p3(3, pe)
say(pe, "SET:" .. MAJ); pe.spec = 1; done(pe, 5800010)
ok("spec swap cancels", pe.bag[MAJ] == 1 and db["15:0"] == nil and db["15:1"] == nil)
-- another spell's completion is ignored
pe.spec = 0; say(pe, "SET:" .. MAJ); local n2 = #sent; done(pe, 12345)
ok("other spell ignored", #sent == n2 and pe.bag[MAJ] == 1)
-- logout mid-cast forgets it
reg.p4(4, pe); local pe2 = P(15, WARRIOR, 1); pe2.bag[MAJ] = 1; reg.p3(3, pe2); done(pe2, 5800010)
ok("logout clears the pending cast", pe2.bag[MAJ] == 1)
-- USE: path also casts
local pf = P(16, WARRIOR, 1); pf.bag[MAJ] = 1; reg.p3(3, pf)
say(pf, "USE:" .. MAJ_USE); done(pf, 5800010)
ok("USE casts then inscribes", pf.casting == 1 and pf.auras[MAJ_AURA])
-- a Prime glyph with a kit: extra auras, and spells taken away and given back exactly as recorded
local KIT, KIT_AURA, KIT_EXTRA, KIT_USE, GONE = 99998, 99980, 99981, 99982, 99983
PRIME_GLYPHS[KIT] = { glyph = 9998, spell = KIT_AURA, extra = { KIT_EXTRA }, removes = { GONE, GONE + 1 }, use = KIT_USE, class = WARRIOR, prime = true, icon = "I", name = "Test Kit" }
PRIME_GLYPH_BY_USE[KIT_USE] = KIT
local pk = P(20, WARRIOR, 1); pk.bag[KIT] = 1; pk.spells[GONE] = true; reg.p3(3, pk)      -- knows GONE but not GONE + 1
say(pk, "SET:" .. KIT)
ok("kit: both auras", pk.auras[KIT_AURA] and pk.auras[KIT_EXTRA])
ok("kit: known spell taken, recorded", not pk.spells[GONE] and removedDb["20:" .. GONE] and not removedDb["20:" .. (GONE + 1)])
reg.p4(4, pk); reg.p3(3, pk)                                                           -- relog: the record is read back
pk.spec = 1
reg.p13(13, pk, 1)                                                                      -- the other spec has no glyph
ok("kit: other spec gives the spell back", pk.spells[GONE] and not pk.spells[GONE + 1] and not removedDb["20:" .. GONE])
ok("kit: other spec drops the auras", not pk.auras[KIT_AURA] and not pk.auras[KIT_EXTRA])
-- garbage
ok("garbage swallowed", say(pr4, "SET:abc") == false)
reg.p2(2, 9); ok("delete", db["9:0"] == nil)
_print(string.format("mock_primeglyph_test: %d passed, %d failed", pass, fail))
if fail > 0 then os.exit(1) end
