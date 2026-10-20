-- Offline smoke test for client-addon/MoonlitPrimeGlyph (gen 2) against a MOCK of the
-- 3.3.5a FrameXML API. Proves the addon's own logic runs without Lua errors,
-- sends the right messages, and NEVER calls the protected SpellStopTargeting()
-- from addon code; proves nothing about textures or placement.
-- Run from the repo root:  luajit core/modules/mod-moonlit-primeglyph/tools/mock_client_test.lua
local sent, hooks, events = {}, {}, {}
local targetingOn = false
local secure = false           -- true only while the mock "secure" OnClick runs
local blocked = 0              -- protected calls from insecure code
local combat = false
local function tex()
    local t = { shown = true, alpha = 1 }
    function t:SetTexture(x) self.file = x end
    function t:SetTexCoord(...) self.coords = { ... } end
    function t:SetVertexColor(...) self.color = { ... } end
    function t:SetWidth(w) self.w = w end; function t:SetHeight() end
    function t:SetPoint() end
    function t:SetAlpha(a) self.alpha = a end
    function t:GetAlpha() return self.alpha end
    function t:Show() self.shown = true end
    function t:Hide() self.shown = false end
    function t:IsShown() return self.shown end
    function t:GetText() return self.text end
    function t:SetText(x) self.text = x end
    return t
end
local tipLines = {}   -- itemId -> lines a tooltip shows for it
local function tooltip(name)
    local tt = { scripts = {}, name = name, n = 0 }
    function tt:GetName() return self.name end
    function tt:SetOwner() end
    function tt:ClearLines() self.n = 0 end
    function tt:AddLine(x) self.n = self.n + 1; _G[self.name .. "TextLeft" .. self.n] = _G[self.name .. "TextLeft" .. self.n] or tex(); _G[self.name .. "TextLeft" .. self.n].text = x end
    function tt:NumLines() return self.n end
    function tt:SetHyperlink(link)
        self.n = 0; self.link = link
        local id = tonumber(link:match("item:(%d+)"))
        for _, l in ipairs(tipLines[id] or tipLines[link] or {}) do self:AddLine(l) end
    end
    function tt:GetItem() return "x", self.link end
    function tt:Hide() end; function tt:Show() end
    function tt:HookScript(k, fn) self.scripts[k] = fn end
    return tt
end
GameTooltip = tooltip("GameTooltip")
ItemRefTooltip = tooltip("ItemRefTooltip")
local frames = {}
function CreateFrame(kind, name, parent, template)
    if kind == "GameTooltip" then local tt = tooltip(name); _G[name] = tt; return tt end
    local f = { scripts = {}, shown = true, parent = parent, name = name, attr = {}, template = template }
    function f:SetScript(k, fn) self.scripts[k] = fn end
    function f:HookScript(k, fn) local o = self.scripts[k]; self.scripts[k] = function(...) if o then o(...) end fn(...) end end
    function f:RegisterEvent(e) events[e] = self end
    function f:RegisterForClicks() end
    function f:EnableMouse(v) self.mouse = v end
    function f:SetID(i) self.id = i end; function f:GetID() return self.id end
    function f:SetWidth() end; function f:SetHeight() end
    function f:ClearAllPoints() end; function f:SetPoint() end
    function f:SetParent(p) self.parent = p; if self.scripts.OnShow then self.scripts.OnShow(self) end end
    function f:SetFrameLevel() end; function f:GetFrameLevel() return 1 end
    function f:Hide() self.shown = false end
    function f:GetName() return self.name end
    function f:IsVisible() return true end
    function f:IsMouseOver() return false end
    function f:CreateTexture() return tex() end
    function f:SetAttribute(k, v) if combat and self.template then error("SetAttribute in combat") end self.attr[k] = v end
    function f:GetAttribute(k) return self.attr[k] end
    if template == "GlyphTemplate" then
        for _, k in ipairs({ "Glyph", "Setting", "Highlight", "Background", "Ring", "Shine" }) do _G[name .. k] = tex() end
        f.scripts.OnShow = function() error("template OnShow must never run") end
    end
    if name then _G[name] = f end
    frames[#frames + 1] = f
    return f
end
-- a click on a SecureActionButtonTemplate button: PreClick, secure OnClick, PostClick
local function click(btn, mouse)
    if btn.scripts.PreClick then btn.scripts.PreClick(btn, mouse) end
    if btn.template == "SecureActionButtonTemplate" and mouse == "LeftButton" and btn.attr["*type1"] == "stop" then
        secure = true
        if SpellIsTargeting() then SpellStopTargeting() end
        secure = false
    end
    if btn.scripts.PostClick then btn.scripts.PostClick(btn, mouse) end
end
function hooksecurefunc(name, fn) hooks[name] = fn end
UseContainerItem, UseAction, UseItemByName = function() end, function() end, function() end
function SendAddonMessage(p, m, c, t) sent[#sent + 1] = m end
function UnitName() return "Tester" end
local classToken = "WARRIOR"
function UnitClass() return "Warrior", classToken end
local bagItem = 60000
function GetContainerItemLink(bag, slot) return "|cff|Hitem:" .. bagItem .. ":0|h[x]|h|r" end
function GetActionInfo() return "item", 60000 end
function GetItemInfo(x) return "Glyph of Atonement", "|Hitem:60000|h" end
function GetSpellInfo(x) return "Glyph of Atonement" end
function SpellIsTargeting() return targetingOn end
function SpellStopTargeting() if not secure then blocked = blocked + 1 end targetingOn = false end
function InCombatLockdown() return combat end
function GetTime() return 0 end
function IsModifiedClick() return false end
local shift = false
function IsShiftKeyDown() return shift end
function ChatEdit_GetActiveWindow() return nil end
function IsAddOnLoaded() return true end
function SetCursor() end
function PlaySound() end
local popups = {}
function StaticPopup_Show(which, a) popups[#popups + 1] = which; return {} end
StaticPopupDialogs = {}
SlashCmdList = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) sent[#sent + 1] = "CHAT:" .. m end }
UIErrorsFrame = { AddMessage = function(_, m) sent[#sent + 1] = "ERR:" .. m end }
WorldFrame = {}
GLYPHTYPE_MAJOR, GLYPH_LOCKED, GLYPH_INACTIVE, GLYPH_SLOT_REMOVE_TOOLTIP, YES, NO = 1, "Locked", "Empty", "<remove>", "Yes", "No"
MAJOR_GLYPH, MINOR_GLYPH = "Major Glyph", "Minor Glyph"
CONFIRM_GLYPH_PLACEMENT, CONFIRM_REMOVE_GLYPH = "replace?", "remove %s?"
function GlyphFrameGlyph_SetGlyphType(b, t) b.setting:SetTexture("Interface\\Spellbook\\UI-GlyphFrame"); b.glyph:SetVertexColor(1, .25, 0) end
GlyphFrame = CreateFrame("Frame", "GlyphFrame")
tipLines[60000] = { "Glyph of Atonement", "Minor Glyph", "Classes: Priest" }
tipLines[42408] = { "Glyph of Power Word: Shield", "Major Glyph" }
tipLines[43342] = { "Glyph of Fading", "Minor Glyph" }
tipLines["spell:110025"] = { "Glyph of Atonement", "Para one.\r\n\r\nPara two." }

local pass, fail = 0, 0
local function ok(n, c) if c then pass = pass + 1 else fail = fail + 1; print("FAIL " .. n) end end

dofile("client-addon/MoonlitPrimeGlyph/MoonlitPrimeGlyph.lua")
local ev = events.ADDON_LOADED
local function E(...) ev.scripts.OnEvent(ev, ...) end
local function addon(m) E("CHAT_MSG_ADDON", "MNPRIME", m, "WHISPER", "Tester") end

-- built in combat? deferred until combat ends
combat = true
E("ADDON_LOADED", "Blizzard_GlyphUI")
ok("no build in combat", MoonlitPrimeGlyphSocket == nil)
combat = false
E("PLAYER_REGEN_ENABLED")
local b, c = MoonlitPrimeGlyphSocket, MoonlitPrimeGlyphSocketClick
ok("socket built", b ~= nil and b.minorSetting and b.minorRing and c ~= nil)
ok("click goes to secure button", c.template == "SecureActionButtonTemplate" and b.mouse == false)
ok("no drag handler", b.scripts.OnReceiveDrag == nil and c.scripts.OnReceiveDrag == nil and b.scripts.OnClick == nil)
ok("perimeter sizes", b.minorRing.w == 110 and b.minorSetting.w == 120)
E("PLAYER_ENTERING_WORLD")
ok("queried", sent[#sent] == "Q")
addon("C:1:1"); addon("L0"); addon("L:60000")
addon("S:1:0:ok:0:")
b.scripts.OnUpdate(b, 0.1)
ok("empty socket shows", b.background:IsShown() and not b.glyph:IsShown())
ok("no stop when not targeting", c.attr["*type1"] == nil)

-- right-click flow: the glyph cursor comes up, the socket pulses, click inscribes
hooks.UseContainerItem(0, 1)
targetingOn = true
E("USE_GLYPH")
b.scripts.OnUpdate(b, 0.3)
ok("pulses while targeting", b.highlight:IsShown())
ok("secure stop armed", c.attr["*type1"] == "stop")
click(c, "LeftButton")
ok("right-click flow sends SET", sent[#sent] == "SET:60000")
ok("cursor ended securely", not targetingOn and blocked == 0)

addon("S:1:60000:ok:110025:Interface\\Spellbook\\UI-Glyph-Rune-2")
ok("filled shows rune", b.glyph:IsShown() and b.glyph.file == "Interface\\Spellbook\\UI-Glyph-Rune-2")
ok("no tint", b.glyph.color[1] == 1 and b.glyph.color[2] == 1 and b.glyph.color[3] == 1)

-- socket tooltip: name, Prime Glyph, then the spell text with its breaks
c.scripts.OnEnter(c)
ok("tooltip prime line", GameTooltipTextLeft2.text == "Prime Glyph")
ok("tooltip keeps paragraphs", GameTooltipTextLeft3.text == "Para one.\r\n\r\nPara two.")
c.scripts.OnLeave(c)

-- item tooltips relabel Prime glyphs only
GameTooltip:SetHyperlink("item:60000"); GameTooltip.scripts.OnTooltipSetItem(GameTooltip)
ok("item tooltip says Prime", GameTooltipTextLeft2.text == "Prime Glyph")
GameTooltip:SetHyperlink("item:43342"); GameTooltip.scripts.OnTooltipSetItem(GameTooltip)
ok("minor glyph untouched", GameTooltipTextLeft2.text == "Minor Glyph")

-- a filled socket asks before it is replaced
bagItem = 42408
hooks.UseContainerItem(0, 2)
targetingOn = true
E("USE_GLYPH")
b.scripts.OnUpdate(b, 0.1)
click(c, "LeftButton")
ok("replace confirms", popups[#popups] == "MOONLIT_PRIME_SET" and blocked == 0)

-- Major glyphs switched off on the server: no pulse, no stop, no send
addon("C:0:1")
addon("S:1:0:ok:0:")
targetingOn = true
E("USE_GLYPH")
b.scripts.OnUpdate(b, 0.1)
local before = #sent
click(c, "LeftButton")
ok("major refused client-side", #sent == before and targetingOn and c.attr["*type1"] == nil)
targetingOn = false
addon("C:1:1")

-- targeting cancelled elsewhere: a click does nothing
b.scripts.OnUpdate(b, 0.1)
before = #sent
click(c, "LeftButton")
ok("no stray send after cancel", #sent == before)

-- shift-right-click removes (with confirmation)
addon("S:1:60000:ok:110025:Interface\\Spellbook\\UI-Glyph-Rune-2")
shift = true
click(c, "RightButton")
shift = false
ok("remove confirms", popups[#popups] == "MOONLIT_PRIME_CLEAR")

-- tuning command
SlashCmdList.MOONLITPRIME("ring 130")
ok("slash ring", b.minorRing.w == 130 and MoonlitPrimeGlyphDB.ring == 130)
SlashCmdList.MOONLITPRIME("reset")
ok("slash reset", b.minorRing.w == 110)

-- a started cast is not an error and not a success
local nsnd = #sent
addon("S:1:0:cast:0:")
ok("cast reply is quiet", #sent == nsnd)
addon("S:1:0:combat:0:")
ok("combat message", sent[#sent]:find("ERR:", 1, true) == 1)
addon("S:1:60000:class:110025:x")
ok("error shown", sent[#sent]:find("ERR:", 1, true) == 1)
E("CHAT_MSG_ADDON", "OTHER", "S:1:0:ok:0:", "WHISPER", "Tester")
addon("S:0:0:level:0:")
ok("locked look", b.setting.file == "Interface\\Spellbook\\UI-GlyphFrame-Locked" and not b.minorSetting:IsShown())
ok("never blocked", blocked == 0)
-- Shaman and Priest: nothing is built and nothing is sent
classToken = "PRIEST"
MoonlitPrimeGlyphSocket, MoonlitPrimeGlyphSocketClick = nil, nil
sent = {}
dofile("client-addon/MoonlitPrimeGlyph/MoonlitPrimeGlyph.lua")
ev = events.ADDON_LOADED
E("ADDON_LOADED", "Blizzard_GlyphUI")
E("PLAYER_ENTERING_WORLD")
ok("priest: no socket", MoonlitPrimeGlyphSocket == nil and MoonlitPrimeGlyphSocketClick == nil)
ok("priest: nothing sent", #sent == 0)
classToken = "SHAMAN"
E("PLAYER_REGEN_ENABLED")
ok("shaman: no socket", MoonlitPrimeGlyphSocket == nil)
print(string.format("mock_client_test: %d passed, %d failed", pass, fail))
if fail > 0 then os.exit(1) end
