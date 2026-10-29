-- RogueKit: on demand (/roguekit setup) creates Logan's rogue macros, places spells and
-- macros into reserved action slots (main bar, the stealth bar page and the bottom-left bar),
-- sets keybinds (with /roguekit undo), and fills the reserved slots as new spells are learned.
-- Nothing happens until setup is run once. Stock Blizzard UI; only runs on a ROGUE.

-- =====================================================================================
-- Config. Edit names here; everything below reads from these tables.
-- =====================================================================================

-- Spell names exactly as the spellbook shows them. Ranks share one name, so the highest
-- known rank is found by name.
local S = {
	sinisterStrike = "Sinister Strike",
	eviscerate = "Eviscerate",
	sliceAndDice = "Slice and Dice",
	rupture = "Rupture",              -- 20
	bladeFlurry = "Blade Flurry",     -- talent (30)
	kick = "Kick",                    -- 12
	gouge = "Gouge",                  -- 6
	kidneyShot = "Kidney Shot",       -- 30
	stealth = "Stealth",
	vanish = "Vanish",                -- 22
	evasion = "Evasion",              -- 8
	sprint = "Sprint",                -- 10
	-- stealth page
	cheapShot = "Cheap Shot",         -- 26
	garrote = "Garrote",              -- 14
	ambush = "Ambush",                -- 18, needs a dagger in the main hand
	sap = "Sap",                      -- 10
	pickPocket = "Pick Pocket",       -- 4
	distract = "Distract",            -- 22
	-- bottom-left bar
	blind = "Blind",                  -- 34
	adrenalineRush = "Adrenaline Rush", -- talent (40)
	exposeArmor = "Expose Armor",     -- 14
	feint = "Feint",                  -- 16
	riposte = "Riposte",              -- talent (20)
	-- ranged pull
	throw = "Throw",
	shootBow = "Shoot Bow",
	shootGun = "Shoot Gun",
	shootCrossbow = "Shoot Crossbow",
}

-- Profiles keyed by class (UnitClass token). Only ROGUE exists.
--   macros: name -> body (string, or function(profile, known) returning a string)
--   keys:   in order; each has a key plus one of:
--     slot + spell [+ placeholder]  spell in that action slot (placeholder until learned)
--     slot + macro [+ needs]        macro in that action slot (once the "needs" spell is known)
--   stealth = true: a stealth-page slot. It shares the key of the main-bar button above it
--   (the game swaps the whole main bar while stealthed), so no binding is set for it.
-- Stock Blizzard slots: main bar 1-12, rogue stealth page 73-84, bottom-left bar 61-72.
local PROFILES = {
	ROGUE = {
		macros = {
			-- Same key enters and leaves stealth. "!" stops a double tap from cancelling it
			-- on the way in; the stealth-page copy cancels it on purpose.
			{ name = "RK Stealth", body = ("#showtooltip %s\n/cast [nostealth] !%s\n/cancelaura [stealth] %s"):format(S.stealth, S.stealth, S.stealth) },
			{ name = "RK Sap", body = ("#showtooltip %s\n/cast [@mouseover,harm,nodead][] %s"):format(S.sap, S.sap) },
			{ name = "RK Throw", body = ("#showtooltip\n/cast [equipped:Thrown] %s; [equipped:Bows] %s; [equipped:Guns] %s; [equipped:Crossbows] %s")
				:format(S.throw, S.shootBow, S.shootGun, S.shootCrossbow) },
		},
		keys = {
			-- Main bar 1 (normal)
			{ key = "1", slot = 1, spell = S.sinisterStrike },
			{ key = "2", slot = 2, spell = S.eviscerate },
			{ key = "3", slot = 3, spell = S.sliceAndDice },
			{ key = "4", slot = 4, spell = S.rupture },
			{ key = "5", slot = 5, spell = S.bladeFlurry },
			{ key = "Q", slot = 6, spell = S.kick },
			{ key = "E", slot = 7, spell = S.gouge },
			{ key = "R", slot = 8, spell = S.kidneyShot },
			{ key = "F", slot = 9, macro = "RK Stealth" },
			{ key = "G", slot = 10, spell = S.vanish },
			{ key = "Z", slot = 11, spell = S.evasion },
			{ key = "V", slot = 12, spell = S.sprint },
			-- Stealth page (same keys; E and R stay empty)
			{ key = "1", slot = 73, spell = S.cheapShot, stealth = true },
			{ key = "2", slot = 74, spell = S.garrote, stealth = true },
			{ key = "3", slot = 75, spell = S.ambush, stealth = true },
			{ key = "4", slot = 76, macro = "RK Sap", needs = S.sap, stealth = true },
			{ key = "5", slot = 77, spell = S.pickPocket, stealth = true },
			{ key = "Q", slot = 78, spell = S.distract, stealth = true },
			{ key = "F", slot = 81, macro = "RK Stealth", stealth = true },
			{ key = "G", slot = 82, spell = S.vanish, stealth = true },
			{ key = "Z", slot = 83, spell = S.evasion, stealth = true },
			{ key = "V", slot = 84, spell = S.sprint, stealth = true },
			-- Bottom-left bar ("Action Bar 2", MULTIACTIONBAR1BUTTON1-6)
			{ key = "X", slot = 61, spell = S.blind },
			{ key = "C", slot = 62, spell = S.adrenalineRush },
			{ key = "SHIFT-Q", slot = 63, spell = S.exposeArmor },
			{ key = "SHIFT-E", slot = 64, spell = S.feint },
			{ key = "SHIFT-R", slot = 65, macro = "RK Throw" },
			{ key = "T", slot = 66, spell = S.riposte },
		},
	},
}

-- Binding command per action slot range (first slot of a 12-slot page -> command prefix).
-- Blizzard: bottom-left bar = page 6 (slots 61-72); the rogue stealth page is page
-- NUM_ACTIONBAR_PAGES(6) + GetBonusBarOffset()(1) = 7 (slots 73-84), driven by ACTIONBUTTONn.
local BAR_COMMANDS = {
	[1] = "ACTIONBUTTON",           -- main bar
	[61] = "MULTIACTIONBAR1BUTTON", -- bottom-left bar
	[73] = "ACTIONBUTTON",          -- main bar while stealthed
}

-- Never take a key away from one of these if it's the command's only key.
local MOVEMENT = {
	MOVEFORWARD = true, MOVEBACKWARD = true, TURNLEFT = true, TURNRIGHT = true,
	STRAFELEFT = true, STRAFERIGHT = true, JUMP = true, TOGGLEAUTORUN = true,
}

local MACRO_ICON = 134400 -- INV_Misc_QuestionMark: #showtooltip picks the real icon
local CHARACTER_SET = (BINDING_SET and BINDING_SET.Character) or CHARACTER_BINDINGS or 2
local MAX_CHAR_MACROS = (Constants and Constants.MacroConsts and Constants.MacroConsts.MAX_CHARACTER_MACROS) or MAX_CHARACTER_MACROS or 18
local BAR2_HELP = "Can't see bar 2 (X, C, T, Shift-Q/E/R)? Type /reload, or turn it on: Options > Action Bars > tick Bar 2 (\"Bottom Left\")."

-- =====================================================================================
-- Helpers
-- =====================================================================================

local C_Spell, C_SpellBook = C_Spell or {}, C_SpellBook or {}
local InCombatLockdown = InCombatLockdown
local GetActionText = (C_ActionBar and C_ActionBar.GetActionText) or GetActionText
local HasAction = (C_ActionBar and C_ActionBar.HasAction) or HasAction

local issecretvalue = issecretvalue or function() return false end
local function Safe(value)
	if issecretvalue(value) then return nil end
	return value
end

local function Print(...)
	print("|cfffff468RogueKit:|r", ...)
end

local profile, db -- set at login for a class with a profile

local function SpellName(spellID)
	if not spellID then return end
	if C_Spell.GetSpellName then return Safe(C_Spell.GetSpellName(spellID)) end
	return GetSpellInfo and Safe((GetSpellInfo(spellID)))
end

local function IsSpellIDKnown(id)
	if C_SpellBook.IsSpellKnown then return C_SpellBook.IsSpellKnown(id) end
	return IsSpellKnown and IsSpellKnown(id)
end

local function PickupSpellID(id)
	if C_Spell.PickupSpell then C_Spell.PickupSpell(id) else PickupSpell(id) end
end

-- Highest known rank of a spell by name, or nil. The spellbook lists ranks in order, so
-- the last match wins. Unlearned "future" spells and passives are skipped.
local function FindSpell(name)
	if not name then return end
	local best
	if C_SpellBook.GetNumSpellBookSkillLines then
		local bank = Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
		local spellType = Enum.SpellBookItemType and Enum.SpellBookItemType.Spell
		for line = 1, C_SpellBook.GetNumSpellBookSkillLines() do
			local lineInfo = C_SpellBook.GetSpellBookSkillLineInfo(line)
			if lineInfo and lineInfo.itemIndexOffset and lineInfo.numSpellBookItems then
				for index = lineInfo.itemIndexOffset + 1, lineInfo.itemIndexOffset + lineInfo.numSpellBookItems do
					local item = C_SpellBook.GetSpellBookItemInfo(index, bank)
					if item and item.name == name and item.spellID and not item.isPassive
						and (not spellType or item.itemType == spellType) then
						best = item.spellID
					end
				end
			end
		end
	elseif GetNumSpellTabs and GetSpellBookItemName then -- older Classic API
		local book = BOOKTYPE_SPELL or "spell"
		for tab = 1, GetNumSpellTabs() do
			local _, _, offset, numSlots = GetSpellTabInfo(tab)
			for index = offset + 1, offset + numSlots do
				local itemName = GetSpellBookItemName(index, book)
				local kind, id = GetSpellBookItemInfo(index, book)
				if itemName == name and kind == "SPELL" and id
					and not (IsPassiveSpell and IsPassiveSpell(index, book)) then
					best = id
				end
			end
		end
	end
	if not best then -- fallback: the name lookup the game itself does
		local id
		if C_Spell.GetSpellInfo then
			local info = C_Spell.GetSpellInfo(name)
			id = info and Safe(info.spellID)
		elseif GetSpellInfo then
			id = select(7, GetSpellInfo(name))
		end
		if id and IsSpellIDKnown(id) then best = id end
	end
	return best
end

local function IsKnown(name) return FindSpell(name) ~= nil end

local function SlotCommand(slot)
	local first = math.floor((slot - 1) / 12) * 12 + 1
	local prefix = BAR_COMMANDS[first]
	return prefix and (prefix .. (slot - first + 1))
end

local function EntryCommand(entry)
	return SlotCommand(entry.slot)
end

local function EntryLabel(entry)
	if entry.macro then return "macro " .. entry.macro end
	if entry.placeholder and not IsKnown(entry.spell) then
		return entry.spell .. " (" .. entry.placeholder .. " until learned)"
	end
	return entry.spell
end

-- =====================================================================================
-- Combat queue: every change waits for PLAYER_REGEN_ENABLED when in combat.
-- =====================================================================================

local queued = {}
local function RunSafe(key, func, quiet)
	if InCombatLockdown() then
		if not queued[key] and not quiet then Print(key .. " will run when this fight is over.") end
		queued[key] = func
		return
	end
	func()
end

-- =====================================================================================
-- Macros
-- =====================================================================================

local function MacroBody(macro)
	if type(macro.body) == "function" then return macro.body(profile, IsKnown) end
	return macro.body
end

-- Creates missing macros and resets existing ones to the canonical body.
-- quiet: only report problems (used by the automatic refresh).
local function UpdateMacros(quiet)
	local created, edited, failed = {}, 0, {}
	for _, macro in ipairs(profile.macros) do
		local body = MacroBody(macro)
		local index = GetMacroIndexByName(macro.name)
		if index and index > 0 then
			local _, _, oldBody = GetMacroInfo(index)
			if oldBody ~= body then
				EditMacro(index, macro.name, nil, body)
				edited = edited + 1
			end
		else
			local _, numChar = GetNumMacros()
			if numChar >= MAX_CHAR_MACROS then
				table.insert(failed, macro.name)
			else
				CreateMacro(macro.name, MACRO_ICON, body, true)
				table.insert(created, macro.name)
			end
		end
	end
	if #failed > 0 then
		Print(("|cffff5555Your character macro list is full (%d/%d)|r, so these weren't made: %s. Delete a few (/macro) and run /roguekit setup again.")
			:format(MAX_CHAR_MACROS, MAX_CHAR_MACROS, table.concat(failed, ", ")))
	end
	if not quiet and (#created > 0 or edited > 0) then
		Print(("Macros: %d made, %d updated."):format(#created, edited))
	end
end

-- =====================================================================================
-- Action slots
-- =====================================================================================

-- What a reserved slot should hold right now: "macro", macroIndex | "spell", spellID | nil.
local function Wanted(entry)
	if entry.macro then
		if entry.needs and not IsKnown(entry.needs) then return end
		local index = GetMacroIndexByName(entry.macro)
		if index and index > 0 then return "macro", index end
		return
	end
	local id = FindSpell(entry.spell) or FindSpell(entry.placeholder)
	if id then return "spell", id end
end

-- true when the slot is empty or holds this entry's item (any rank, or its placeholder),
-- or still holds a Blizzard starter-bar spell recorded at the first setup.
local function SlotIsOurs(entry)
	local kind, id = GetActionInfo(entry.slot)
	kind, id = Safe(kind), Safe(id)
	if not kind then return true end
	if kind == "spell" and db.starter and db.starter[entry.slot]
		and db.starter[entry.slot] == SpellName(id) then
		return true
	end
	if entry.macro then
		return kind == "macro" and Safe(GetActionText(entry.slot)) == entry.macro
	end
	if kind ~= "spell" then return false end
	local name = SpellName(id)
	return name == entry.spell or (entry.placeholder ~= nil and name == entry.placeholder)
end

local function SlotWhere(entry)
	if entry.stealth then return "stealth bar" end
	if entry.slot >= 61 and entry.slot <= 72 then return "bar 2" end
	return "main bar"
end

-- A new character's bar comes pre-filled by Blizzard (Attack, Sinister Strike, Eviscerate...).
-- At the first setup, reserved slots holding Attack or one of RogueKit's own spells count as
-- starter slots RogueKit may replace. Anything Logan places after that is his.
local STARTER = { ["Attack"] = true, ["Auto Attack"] = true }
for _, name in pairs(S) do STARTER[name] = true end

local function ScanStarterBar()
	if db.starterScanned then return end
	db.starter = {}
	for _, entry in ipairs(profile.keys) do
		local kind, id = GetActionInfo(entry.slot)
		kind, id = Safe(kind), Safe(id)
		local name = kind == "spell" and SpellName(id)
		if name and STARTER[name] then db.starter[entry.slot] = name end
	end
	db.starterScanned = true
end

-- Fills reserved slots. A slot is only touched when it's empty or already holds the
-- RogueKit item; spells are re-placed when a new rank arrives.
local function PlaceActions(quiet)
	if GetCursorInfo() then return end -- don't drop whatever Logan is dragging
	db.placed = db.placed or {}
	local placed, skipped = {}, {}
	for _, entry in ipairs(profile.keys) do
		if entry.slot then
			local kind, id = Wanted(entry)
			if kind and not SlotIsOurs(entry) then
				table.insert(skipped, ("%s on %s (slot %d)"):format(entry.key, SlotWhere(entry), entry.slot))
			elseif kind then
				local hasAction = Safe(HasAction(entry.slot))
				-- Macro indexes shift as macros are added, so macros are tracked by name.
				local current = kind == "macro" and ("macro:" .. entry.macro) or ("spell:" .. id)
				local _, actionID = GetActionInfo(entry.slot)
				-- Spell slots: compare by name too, so a placeholder gets swapped out.
				local stale = not hasAction or db.placed[entry.slot] ~= current
					or (kind == "spell" and SpellName(Safe(actionID)) ~= SpellName(id))
				if stale then
					ClearCursor()
					if kind == "macro" then PickupMacro(id) else PickupSpellID(id) end
					if GetCursorInfo() then
						PlaceAction(entry.slot)
						ClearCursor() -- drops the old rank that PlaceAction picked up
						db.placed[entry.slot] = current
						if db.starter then db.starter[entry.slot] = nil end
						local label = kind == "macro" and entry.macro or SpellName(id) or entry.spell
						table.insert(placed, ("%s [%s%s]"):format(label, entry.key, entry.stealth and ", stealth" or ""))
					end
				end
			end
		end
	end
	if #placed > 0 then Print("New on your bars: " .. table.concat(placed, ", ")) end
	if #skipped > 0 and not quiet then
		Print("Left alone because something else is there: " .. table.concat(skipped, ", ")
			.. ". Want RogueKit's spell there? Drag it off the bar and type /roguekit setup again.")
	end
end

-- =====================================================================================
-- Bottom-left bar ("Bar 2"): hidden by default on a new character.
-- =====================================================================================

local function Bar2Shown()
	local bar = _G.MultiBarBottomLeft
	return bar and bar:IsShown()
end

local function ShowBar2()
	if Bar2Shown() then return end
	-- Modern settings panel (proxy setting behind the "Action Bar 2" checkbox).
	if Settings and Settings.GetSetting and Settings.SetValue then
		pcall(function()
			if Settings.GetSetting("PROXY_SHOW_ACTIONBAR_2") then
				Settings.SetValue("PROXY_SHOW_ACTIONBAR_2", true)
			end
		end)
	end
	-- Classic-style toggles. Saved for the next UI load; RogueKit doesn't write Blizzard's
	-- SHOW_MULTI_ACTIONBAR_* globals itself (that would taint the action bars).
	if not Bar2Shown() and SetActionBarToggles and GetActionBarToggles then
		pcall(function()
			local _, bottomRight, sideRight, sideLeft, alwaysShow = GetActionBarToggles()
			SetActionBarToggles(true, bottomRight, sideRight, sideLeft, alwaysShow)
		end)
	end
	C_Timer.After(1, function()
		if not Bar2Shown() and not (C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("ElvUI")) then
			Print(BAR2_HELP)
		end
	end)
end

-- =====================================================================================
-- Bindings
-- =====================================================================================

local function ApplyBindings()
	db.undo = db.undo or {}
	if db.prevBindingSet == nil then db.prevBindingSet = GetCurrentBindingSet() end
	local replaced, refused = {}, {}
	for _, entry in ipairs(profile.keys) do
		if not entry.stealth then -- stealth-page slots ride on the main bar's keys
			local command = EntryCommand(entry)
			local old = GetBindingAction(entry.key) or ""
			if old ~= command then
				if MOVEMENT[old] and select("#", GetBindingKey(old)) <= 1 then
					table.insert(refused, entry.key .. " (" .. old .. ")")
				else
					-- Keep the first recorded value so a re-run can still undo to the original.
					if db.undo[entry.key] == nil then db.undo[entry.key] = old end
					if old ~= "" then table.insert(replaced, entry.key .. ": " .. old) end
					if not SetBinding(entry.key, command) then
						table.insert(refused, entry.key .. " (SetBinding failed)")
					end
				end
			end
		end
	end
	SaveBindings(CHARACTER_SET)
	if #replaced > 0 then Print("Changed these keys (undo brings them back): " .. table.concat(replaced, ", ")) end
	if #refused > 0 then
		Print("|cffff5555Not changed|r (it's your only key for moving, or an error): " .. table.concat(refused, ", "))
	end
end

local function UndoBindings()
	if not db.undo or not next(db.undo) then
		Print("Nothing to undo.")
		return
	end
	local restored = 0
	for key, old in pairs(db.undo) do
		if old == "" then SetBinding(key) else SetBinding(key, old) end
		restored = restored + 1
	end
	SaveBindings(db.prevBindingSet or CHARACTER_SET)
	db.undo, db.prevBindingSet = nil, nil
	db.applied, db.declined = false, true
	Print(("Put back %d keys. Your bars and macros stay as they are; new spells won't be added until /roguekit setup."):format(restored))
end

-- =====================================================================================
-- Commands
-- =====================================================================================

local function Setup()
	UpdateMacros(false)
	ScanStarterBar()
	PlaceActions(false)
	ApplyBindings()
	ShowBar2()
	db.applied, db.declined = true, nil
	Print("All set! Stealth (F) swaps your main bar to stealth moves. New spells land on their keys by themselves. /roguekit status to check, /roguekit undo to get your old keys back.")
end

local function Status()
	Print(("Status (%s, auto-fill %s):"):format(db.applied and "set up" or "not set up", db.applied and "on" or "off"))
	for _, entry in ipairs(profile.keys) do
		local want = EntryCommand(entry)
		local bound = GetBindingAction(entry.key)
		local mark = bound == want and "|cff55ff55ok|r" or "|cffffd100" .. (bound ~= "" and bound or "unbound") .. "|r"
		local learned = ""
		if entry.spell then
			learned = IsKnown(entry.spell) and " |cff55ff55learned|r" or " |cff888888not learned yet|r"
		elseif entry.macro then
			local index = GetMacroIndexByName(entry.macro)
			learned = (index and index > 0) and " |cff55ff55macro ok|r" or " |cffff5555macro missing|r"
		end
		print(("  %-8s %s (%s, slot %d) -> %s%s"):format(entry.key, EntryLabel(entry), SlotWhere(entry), entry.slot, mark, learned))
	end
	if not Bar2Shown() then Print(BAR2_HELP) end
end

local function Help()
	Print("/roguekit setup  - make the macros, fill your bars, set your keys")
	Print("/roguekit status - every key, what it does, learned or not")
	Print("/roguekit undo   - put back the keys RogueKit changed")
end

SLASH_ROGUEKIT1 = "/roguekit"
SlashCmdList.ROGUEKIT = function(msg)
	if not profile then
		Print("RogueKit only works on a rogue.")
		return
	end
	local cmd = strtrim(msg or ""):lower()
	if cmd == "setup" then
		RunSafe("Setup", Setup)
	elseif cmd == "status" then
		Status()
	elseif cmd == "undo" then
		RunSafe("Undo", UndoBindings)
	else
		Help()
	end
end

-- =====================================================================================
-- Events
-- =====================================================================================

local frame = CreateFrame("Frame")

-- SPELLS_CHANGED fires in bursts; refresh once things settle.
local refreshPending
local function AutoFill()
	refreshPending = nil
	if not (db and db.applied) then return end
	RunSafe("Auto-fill", function()
		UpdateMacros(true)
		PlaceActions(true)
	end, true)
end
local function RequestAutoFill()
	if refreshPending or not (db and db.applied) then return end
	refreshPending = true
	C_Timer.After(1, AutoFill)
end

local function OnLogin()
	local _, class = UnitClass("player")
	profile = PROFILES[class]
	if not profile then
		frame:UnregisterAllEvents()
		return
	end
	RogueKitCharDB = RogueKitCharDB or {}
	db = RogueKitCharDB
	frame:RegisterEvent("SPELLS_CHANGED")
	frame:RegisterEvent("PLAYER_REGEN_ENABLED")
	-- Classic fires LEARNED_SPELL_IN_TAB, modern clients LEARNED_SPELL_IN_SKILL_LINE;
	-- registering an event the client doesn't have is an error, so try each.
	pcall(frame.RegisterEvent, frame, "LEARNED_SPELL_IN_TAB")
	pcall(frame.RegisterEvent, frame, "LEARNED_SPELL_IN_SKILL_LINE")
	if not db.applied and not db.declined then
		Print("Hi Logan! Type |cfffff468/roguekit setup|r to set up your bars and keys.")
	end
end

frame:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_LOGIN" then
		OnLogin()
	elseif event == "PLAYER_REGEN_ENABLED" then
		for key, func in pairs(queued) do
			queued[key] = nil
			func()
		end
	else
		RequestAutoFill()
	end
end)
frame:RegisterEvent("PLAYER_LOGIN")
