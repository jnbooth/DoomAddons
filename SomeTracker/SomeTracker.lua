local shortName, N = ...
----------------
-- File globals
----------------

local LibStub = LibStub
local A = LibStub("Abacus-2.0")
local D = LibStub("DoomCore-2.1")

--- @class SomeTracker: Handler
--- @field core SomeTrackerCore
--- @field settings SomeTrackerSettings
local Addon = D.Addon(shortName, "Some Tracker", N)
Addon.version = 1.4

local CreateFrame, CombatLog_Object_IsA, floor, GetTime, GetSpecialization, GetSpellDescription, GetSpellInfo, IsPassiveSpell, pairs, rawget, select, tinsert, tostring, type, unpack, UIParent, FindAuraByName, UnitClass, UnitGUID, UnitHealthMax, UnitName, UnitRace =
    CreateFrame, CombatLog_Object_IsA, floor, GetTime, GetSpecialization, GetSpellDescription, GetSpellInfo,
    IsPassiveSpell,
    pairs, rawget, select, tinsert, tostring, type, unpack, UIParent, AuraUtil.FindAuraByName, UnitClass, UnitGUID,
    UnitHealthMax, UnitName, UnitRace

local abbrev, assertType, capitalize, colPack, colUnpack, isEmpty, nilSort, subInfo, NodeCrawler, setFont, TypeCode, updateFrame =
    A.abbrev, A.assertType, A.capitalize, A.colPack, A.colUnpack, A.isEmpty, A.nilSort, D.subInfo, D.NodeCrawler,
    D.setFont, A.TypeCode, D.updateFrame

local type_string, type_table = TypeCode.String, TypeCode.Table

local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo --[[@as fun(): ...]]
--- @type number
local COMBATLOG_FILTER_MY_PET = COMBATLOG_FILTER_MY_PET
--- @type number
local COMBATLOG_FILTER_MINE = COMBATLOG_FILTER_MINE

local getIconColor = N.Niji.GetIconColor
--- @type HighScores
local HighScores = N.HighScores

--- @class PlayerInfo
--- @field id string
--- @field name string
--- @field race string
--- @field class string
--- @field spec number
local player = {}
--- @type { [string]: boolean }
local pcMoves = {}
local unique = NodeCrawler:New()
--- @type { [string]: EffectLog }
local log = {}
--- @type { [string]: LogKey }
local logKeys = {}
--- @type { [string]: EffectLog }
local logTotals = {}

--- @type { [string]: TrackerFrame }
local frames = {}
todoFrames = frames
local spacing = 5
local fadeDuration = 0.6
local missingIcon = "Interface\\Icons\\INV_Misc_QuestionMark"

--------
-- Core
--------

--- @return nil
function Addon:OnInitialize()
  self:Register({
    masque = "Masque"
  })

  self.lib.settings:AddToBlizOptions(self.name .. ": High Scores", "High Scores", self.name)

  self:TrackEvent("COMBAT_LOG_EVENT_UNFILTERED")
  self:TrackEvent("PLAYER_LOGIN")
end

--- @return nil
--- @param registered? boolean
function Addon:OnLoad(registered)
  if registered == false and self:RunMigration() then return end
  local core = self.core
  self:Make(core, "scoring", "High Scores")
  local trackers = core.Trackers
  if trackers == nil then
    trackers = {}
    core.Trackers = trackers
  end
  local damage = self:Make(trackers, "tracker", "Default Damage")
  if not rawget(damage, "overflow") then
    damage.overflow = "addition"
  end
  local healing = self:Make(trackers, "tracker", "Default Healing")
  healing.trackerType = "healing"
  if not rawget(healing, "offsetX") then
    healing.offsetX = 30 * abs(damage.offsetX) / damage.offsetX - damage.offsetX
  end
  local highscores = core.highscores
  if highscores == nil then
    highscores = {}
    core.highscores = highscores
  end
  HighScores:Load(self, highscores)

  for trackerName in pairs(trackers) do
    self:BuildTracker(trackerName)
  end
end

--- @param version number
--- @return boolean
function Addon:Migrate(version)
  if version < 1.0 then return true end
  local core = self.core
  if version < 1.1 then
    for trackerName, tracker in pairs(core --[[@as any]].trackers) do
      local oldGrow = tracker.grow
      if oldGrow == "up" then
        tracker.grow = "TOP"
      elseif oldGrow == "down" then
        tracker.grow = "BOTTOM"
      end
    end
  end
  if version < 1.2 then
    local fieldsToMigrate = { "anchor", "columnGrowth", "grow", "grow2", "rowGrowth" }
    for _, tracker in pairs(core --[[@as any]].trackers) do
      for _, field in ipairs(fieldsToMigrate) do
        local old = tracker[field]
        if type(old) == "string" then
          tracker[field] = old:upper()
        end
      end
    end
  end
  if version < 1.3 then
    local trackers = self.core.Trackers
    if trackers == nil then
      trackers = {}
      self.core.Trackers = trackers
    end
    for trackerName, tracker in pairs(self.core) do
      if type(tracker) == "table" and tracker.type == "tracker" then
        self.core[trackerName] = nil
        trackers[trackerName] = tracker
      end
    end
  end
  if version < 1.4 then
    self.core.Extras = self.core --[[@as any]]._debug
    self.core._debug = nil
    self.core.Trackers = self.core --[[@as any]].trackers
    self.core.trackers = nil
    self.core["High Scores"] = self.core --[[@as any]].scoring
    self.core.scoring = nil
  end
  return false
end

-------------------
-- Tracker editing
-------------------

--- @param info CorePath
--- @param name string
--- @return nil
function Addon:AddTracker(info, name)
  assertType(info, type_table, name, type_string)
  self:Make(self.core.Trackers, "tracker", name)
  self:BuildTracker(name)
end

--- @param info CorePath
--- @param new string
--- @return nil
function Addon:RenameTracker(info, new)
  assertType(info, type_table, new, type_string)
  local trackers = self.core.Trackers
  if trackers[new] then return end
  local old = info[1]
  trackers[new] = trackers[old]
  trackers[old] = nil

  self.settings.options.args.trackers[old] = nil
  frames[new] = frames[old]
  frames[old] = nil
  self:BuildTracker(new)
end

--- @param info CorePath
--- @return nil
function Addon:DeleteTracker(info)
  assertType(info, type_table)
  local trackerName = info[1]
  self.core.Trackers[trackerName] = nil
  self.settings.options.args.trackers[trackerName] = nil
end

--- @param info CorePath
--- @return nil
function Addon:DeleteMeter(info)
  assertType(info, type_table)
  local tracker, kind, deleter = unpack(info)
  local meter = deleter:sub(2)
  self.core.Trackers[tracker][kind][meter] = nil
  local trackerSettings = self.settings.options.args.trackers[tracker].args[kind].args
  trackerSettings[meter] = nil
  trackerSettings[deleter] = nil
end

--- @param info CorePath
--- @return nil
function Addon:AddMeter(info, meter)
  assertType(info, type_table, meter, type_string)
  self.core.Trackers[info[1]].ignore = {}
  local key = subInfo(info, 1, -2)
  tinsert(key, meter)
  self:Set(key, colPack(getIconColor(GetSpellTexture(meter))))
  self:BuildTracker(info[1])
end

----------
-- Frames
----------

--- @overload fun(self: SomeTracker, info: CorePath | nil, r: number, g: number, b: number, a: number): nil
--- @overload fun(self: SomeTracker, info: CorePath | nil, r: number, g: number, b: number): nil
--- @overload fun(self: SomeTracker, info: CorePath | nil, val: any): nil
function Addon:UpdateSettings(info, r, g, b, a)
  if info then
    self:ConfSet(info, r, g, b, a)
  end
end

--- @overload fun(self: SomeTracker, info: CorePath | nil, r: number, g: number, b: number, a: number): nil
--- @overload fun(self: SomeTracker, info: CorePath | nil, r: number, g: number, b: number): nil
--- @overload fun(self: SomeTracker, info: CorePath | nil, val: any): nil
function Addon:Rebuild(info, r, g, b, a)
  if info then
    self:ConfSet(info, r, g, b, a)
    self:BuildTrackerFrame(info[1])
  end
end

--- @param name string
--- @return nil
function Addon:BuildTracker(name)
  assertType(name, type_string)
  local tracker = self.core.Trackers[name]
  tracker.ignore = tracker.ignore or {}
  self.settings:BuildTrackerSettings(name, tracker)
  self:BuildTrackerFrame(name, tracker)
end

--- @param name string
--- @param tracker? Tracker
--- @return TrackerFrame
function Addon:BuildTrackerFrame(name, tracker)
  if not tracker then tracker = self.core.Trackers[name] end
  assertType(name, type_string, tracker, type_table)
  self:AutoDefault(tracker)
  local frame = frames[name]
  if not frame then
    frame = CreateFrame("Frame", self.shortName .. name, UIParent, "BackdropTemplate") --[[@as TrackerFrame]]
    frame.conf = tracker
    frame.tex = frame:CreateTexture(frame:GetName() .. ".tex", "BACKGROUND")
    frame.tex:SetAllPoints(frame)
    frame.tex:SetColorTexture(0, 1, 0, 0.5)

    frames[name] = frame
    if self.lib.masque then
      frame.msq = self.lib.masque:Group(self.name, name)
    end
  end
  self:Draggable(frame, tracker)
  frame.count = 0
  frame:ClearAllPoints()
  local size = tracker.iconSize
  frame:SetSize(size, size)
  self:Clear(name)
  updateFrame(frame, tracker)
  frame:Show()
  return frame
end

--- @param button AlertFrame
--- @param frame Frame
--- @param tracker Tracker
--- @return nil
function Addon:InitButton(button, frame, tracker)
  button:EnableMouse(false)
  button.NormalTexture:Hide()
  button:Disable()
  button.text = button:CreateFontString(button:GetName() .. ".text")
  button.text:SetShadowOffset(1, -1)
  local animations = button:CreateAnimationGroup()
  local fade = animations:CreateAnimation("Alpha")
  fade:SetStartDelay(tracker.duration)
  fade:SetDuration(fadeDuration)
  fade:SetFromAlpha(1)
  fade:SetToAlpha(0)
  button.fade = fade

  button.highlight = {}
  for i, layer in pairs({ button.Border, button.Flash }) do
    layer:Show()
    layer:SetAlpha(0)
    local highlight = layer:CreateAnimationGroup()
    highlight:SetLooping("BOUNCE")
    local flash = highlight:CreateAnimation("Alpha")
    flash:SetDuration(0.25)
    flash:SetFromAlpha(0)
    flash:SetToAlpha(1)
    button.highlight[i] = highlight
  end

  animations:SetScript("OnFinished", function()
    HighScores:Score(button.metername, button.amount + button.over, button.icon:GetTexture() --[[@as number]],
      colPack(button.text:GetTextColor()))
    button:Hide()
    for _, highlight in pairs(button.highlight) do
      highlight:Stop()
    end
    self:Queue("Sort", frame)
  end)
  button.animation = animations
end

--- @param trackerName string
--- @param tracker Tracker
--- @param kind string
--- @return AlertFrame
function Addon:GetFreeButton(trackerName, tracker, kind)
  assertType(trackerName, type_string, tracker, type_table, kind, type_string)
  local frame = frames[trackerName]
  local button
  for _, b in pairs { frame:GetChildren() } do
    if not b:IsShown() then
      button = b
      break
    end
  end
  if not button then
    frame.count = frame.count + 1
    --- @type AlertFrame
    button = CreateFrame("Button", frame:GetName() .. "-" .. frame.count, frame, "ActionButtonTemplate")
    self:InitButton(button, frame, tracker)
    if frame.msq then frame.msq:AddButton(button) end
  end

  local text = button.text
  setFont(text, tracker)
  if kind == "aura" then
    text:SetShadowColor(colUnpack(tracker.specialShadow))
  else
    text:SetShadowColor(colUnpack(tracker.shadow))
  end
  local size = tracker.iconSize
  button.Flash:SetAlpha(0)
  button.Border:SetAlpha(0)
  button:SetSize(size, size)
  text:SetPoint("LEFT", size + 5, 1)
  button.kind = kind
  button:Show()
  return button
end

--- @param trackerName string
--- @return nil
function Addon:Clear(trackerName)
  assertType(trackerName, type_string)
  local children = { frames[trackerName]:GetChildren() }
  if #children == 0 then return end
  for _, child in pairs(children) do
    self:RemoveAlert(trackerName, child)
  end
end

--- @param trackerName string
--- @param button AlertFrame
--- @return nil
function Addon:RemoveAlert(trackerName, button)
  assertType(trackerName, type_string, button, type_table)
  local frame = frames[trackerName]
  button:Hide()
  button:ClearAllPoints()

  button.icon:SetTexture(missingIcon)
  button.image = nil
  button.kind = nil
  button.meter = nil
  button.text:SetText()
  button.text:SetTextColor(1, 1, 1, 1)
end

local sortAnchors = {
  BOTTOM = { "TOPLEFT", "BOTTOMLEFT", -1 },
  TOP    = { "BOTTOMLEFT", "TOPLEFT", 1 }
}

--- @param frame TrackerFrame
--- @return nil
function Addon:Sort(frame)
  self:Output("Sorting")
  local anchor1, anchor2, dir = unpack(sortAnchors[frame.conf.grow])
  local children = { frame:GetChildren() }
  if #children == 0 then
    unique:Set({}, nil)
    return
  end
  local visible = {}
  for _, child in pairs(children) do
    if child:IsShown() then
      tinsert(visible, child)
    end
  end
  if #visible == 0 then return end
  nilSort(visible, "timed")
  visible[1]:ClearAllPoints()
  visible[1]:SetPoint(anchor1, frame)
  for i = 2, #visible do
    visible[i]:ClearAllPoints()
    visible[i]:SetPoint(anchor1, visible[i - 1], anchor2, 0, dir * spacing)
  end

  if frame.msq then frame.msq:ReSkin() end
end

--- @param trackerName string
--- @param metername string
--- @param meter string
--- @param color Color
--- @param id number
--- @param log EffectLog
--- @param delay? number
--- @param priority? number
--- @return AlertFrame | nil
function Addon:BuildAlert(trackerName, metername, meter, color, id, log, delay, priority)
  local amount, crit, over, timed, cat = log.amount, log.crit, log.over, log.timed, log.cat
  timed = timed - 1000 * (priority or 0)
  self:Output("Building ", meter, " -> ", amount, " / ", crit, " / ", over)
  local kind = "spell"
  --- @type Tracker
  local tracker = self.core.Trackers[trackerName]
  local displayOver = tracker.over
  if displayOver ~= "include" and displayOver ~= "additional" and amount == 0 then
    return nil
  end
  local frame = frames[trackerName]
  local alert
  for _, child in pairs({ frame:GetChildren() }) do
    if child.kind == kind and child.meter == meter and child:IsShown() then
      alert = child
      break
    end
  end
  if not alert then
    alert = self:GetFreeButton(trackerName, tracker, kind)
    local image = GetSpellTexture(metername)
    if not image then
      if kind == "aura" then
        image = select(2, FindAuraByName(meter, "player")) or select(2, FindAuraByName(meter, "player"))
      else
        image = select(3, GetSpellInfo(meter)) or select(3, GetSpellInfo(meter))
      end
      if not image and kind == "spell" then image = select(3, GetSpellInfo(id)) end
    end
    if color then alert.text:SetTextColor(colUnpack(color)) end
    if image then alert.icon:SetTexture(image) end
    alert.displayCrit = tracker.markCrits
    alert.crit = false
    alert.amount = 0
    alert.over = 0
    alert.kind = kind
    alert.meter = meter
    alert.metername = metername
    alert.timed = timed
    alert.count = 0
    if self.core["High Scores"].scoreIcon then
      alert.record = HighScores:GetScore(meter)
    else
      alert.record = nil
    end
    self:Queue("Sort", frame)
  end

  alert.animation:Stop()
  alert.fade:SetStartDelay(tracker.duration + (delay or 0))
  alert.animation:Play()

  alert.count = alert.count + 1
  alert.amount = alert.amount + amount

  if alert.record and alert.amount + alert.over > alert.record then
    for _, highlight in pairs(alert.highlight) do highlight:Play() end
  end

  local displayAmount = alert.amount

  if over then alert.over = alert.over + over end
  if displayOver == "include" then
    displayAmount = displayAmount + alert.over
  end

  if cat then
    if displayAmount > 1 then
      alert.text:SetText(capitalize(cat) .. " " .. abbrev(displayAmount))
    else
      alert.text:SetText(capitalize(cat))
    end
  else
    local amountString = abbrev(displayAmount)
    alert.crit = alert.displayCrit and (alert.crit or crit)
    if kind == "spell" and alert.crit then
      amountString = amountString .. "*"
    end
    if alert.over >= 1000 and displayOver == "additional" then
      amountString = amountString .. " (" .. abbrev(alert.over) .. ")"
    end
    if meter == "Touch of Karma" then
      amountString = amountString .. "/" .. abbrev(UnitHealthMax("player") / 2)
    end
    alert.text:SetText(amountString)
  end
  return alert
end

----------
-- Events
----------

--- @return nil
function Addon:PLAYER_LOGIN()
  player.id = UnitGUID("player") --[[@as string]]
  player.name = UnitName("player") --[[@as string]]
  player.race = select(2, UnitRace("player"))
  player.class = select(2, UnitClass("player"))
  player.spec = GetSpecialization()
  for trackerName, tracker in pairs(self.core.Trackers) do
    self:BuildTracker(trackerName)
  end
end

local DELIM = "`"

--- @param logged EffectLog
--- @param amount number | nil
--- @param over number | nil
--- @param crit boolean | nil
--- @param timed number | nil
--- @return nil
function Addon:UpdateLog(logged, amount, over, crit, timed)
  logged.amount = (logged.amount or 0) + (amount or 0) - (over or 0)
  logged.over = (logged.over or 0) + (over or 0)
  logged.crit = logged.crit or crit or false
  logged.timed = logged.timed or timed
end

--- @param spellName string
--- @param spellID string
--- @param trackerName string
--- @param seconds number
--- @param destGUID string
--- @param log EffectLog
--- @return nil
function Addon:Match(spellName, spellID, trackerName, seconds, destGUID, log)
  --- @type Tracker
  local tracker = self.core.Trackers[trackerName]
  if tracker.ignore[spellName] then return end
  spellID = select(7, GetSpellInfo(spellName)) or spellID
  local notFound = true
  local desc = tracker.related and (not IsSpellKnown(spellID) or IsPassiveSpell(spellID)) and
      GetSpellDescription(spellID)
  local tracker_spell = tracker.spell
  for meter, color in pairs(tracker_spell) do
    if meter == spellName or (desc and desc:find(meter, 1, true)) then
      notFound = false
      if isEmpty(color) then
        local tex = GetSpellTexture(meter) or GetSpellTexture(spellID)
        if tex then
          color = colPack(getIconColor(tex))
          tracker_spell[meter] = color
        end
      end
      local missDisplay = tracker.misses
      local finalSuff = tostring(seconds)
      local suff = ""
      local spell, aura, recent
      spell = unique:Get({ "spell", meter })
      --if destGUID then aura = unique:Get({ "aura", meter, destGUID }) end
      if destGUID then aura = unique:Get({ "aura", meter }) end
      recent = unique:Get({ "recent", meter })
      self:Output(meter, " - ", aura, "/ ", spell, " / ", recent and recent[2])
      if aura then
        suff = suff .. aura
        finalSuff = ""
      elseif spell then
        suff = suff .. spell
        finalSuff = ""
      elseif recent and seconds - recent[2] < 2 then
        suff = suff .. recent[1]
        finalSuff = ""
      elseif recent then
        recent = { seconds }
      end
      if not recent then recent = { seconds } end
      recent[2] = seconds

      unique:Set({ "recent", meter }, recent)
      local display = "TODO"
      if (missDisplay == "all" or (missDisplay == "total" and (not log.amount or log.amount == 0) and not log.partial))
          and log.miss then
        for missType, missAmount in pairs(log.miss) do
          if not tracker.missType or tracker.missType[missType] then
            self:BuildAlert(trackerName, meter, meter, color, spellID,
              {
                cat = missType,
                amount = missAmount,
                timed = log.timed
              })
          end
        end
      end
      if (log.amount or 0) + (log.over or 0) > 0 then
        local umeter = meter
        if display ~= "aggregate" then
          umeter = umeter .. suff .. finalSuff
          finalSuff = ""
        end
        if display == "individual" then
          umeter = umeter .. finalSuff .. unique:Incr({ "timed", log.timed })
          finalSuff = ""
        end

        self:BuildAlert(trackerName, meter, umeter, color, spellID, log)
      end
    end
  end
  if notFound then
    tracker.ignore[spellName] = true
  end
end

--- @type { [string]: string }
local summoned = {}

--- @return nil
function Addon:COMBAT_LOG_EVENT_UNFILTERED()
  local timed, suffix, hide, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool, amount, overflow, school, resisted, blocked, absorbed, crit, extra =
      CombatLogGetCurrentEventInfo()
  local kind
  if suffix == "SPELL_CAST_SUCCESS" then
    kind = "spell"
  elseif suffix == "SPELL_MISSED" then
    kind = "miss"
  elseif suffix == "SPELL_SUMMON" then
    kind = "summon"
  elseif suffix == "SWING_DAMAGE" then
    amount = spellID
    spellID = nil
    spellName = nil
    kind = "damage"
  elseif suffix == "SPELL_DAMAGE" or suffix == "SPELL_BUILDING_DAMAGE"
      or suffix == "SPELL_PERIODIC_DAMAGE" or suffix == "RANGE_DAMAGE" then
    kind = "damage"
  elseif suffix == "SPELL_HEAL" or suffix == "SPELL_BUILDING_HEAL"
      or suffix == "SPELL_PERIODIC_HEAL" or suffix == "RANGE_HEAL" then
    kind = "healing"
    absorbed = school
    crit = resisted
  elseif suffix == "SPELL_ABSORBED" then
    kind = "healing"
    if type(spellID) == "number" then
      sourceGUID, sourceName, sourceFlags, sourceRaidFlags, spellID, spellName, spellSchool, amount = amount, overflow,
          spellSchool, resisted, blocked, absorbed, crit, extra
    else
      sourceGUID, sourceName, sourceFlags, sourceRaidFlags, spellID, spellName, spellSchool, amount = spellID, spellName
      , spellSchool, amount, overflow, school, resisted, blocked
    end
    ---@diagnostic disable-next-line: unbalanced-assignments
    overflow, spellSchool, resisted, blocked, absorbed, crit, extra = nil
  elseif suffix == "SPELL_AURA_APPLIED" or suffix == "SPELL_AURA_REFRESH" or suffix == "SPELL_AURA_REMOVED" then
    kind = "aura"
  else
    return
  end
  if sourceName == "Wild Imp" then return end -- There's just too many of the damned things.
  local unitMatch = sourceGUID == player.id
  local petMatch = not unitMatch and sourceFlags ~= nil and (
    CombatLog_Object_IsA(sourceFlags, COMBATLOG_FILTER_MY_PET) or
    CombatLog_Object_IsA(sourceFlags, COMBATLOG_FILTER_MINE))

  local destMatch = destGUID == player.id or destFlags ~= nil and (
    CombatLog_Object_IsA(destFlags, COMBATLOG_FILTER_MY_PET) or CombatLog_Object_IsA(destFlags, COMBATLOG_FILTER_MINE)
  )
  if destMatch and kind == "damage" then return end

  if not unitMatch and not petMatch then return end

  local summon = summoned[sourceGUID]
  if summon then
    spellName = summon
  end

  local seconds = tostring(floor(timed))

  if kind == "spell" then
    ---@diagnostic disable-next-line: need-check-nil
    if unitMatch then pcMoves[spellName] = true elseif pcMoves[spellName] then return end
    if spellName == UnitChannelInfo("player") then
      self:Output("Channeled spell ", spellName, " ", seconds)
    else
      self:Output("Unique spell ", spellName, " ", seconds)
      unique:Set({ "spell", spellName }, seconds)
      if destGUID and destGUID ~= player.id then
        unique:Set({ "dest", spellName, destGUID }, seconds)
      end
    end
    return
  elseif kind == "aura" then
    if unitMatch and destGUID and destGUID ~= player.id then
      if spellName == UnitChannelInfo("player") then
        self:Output("Channeled aura ", spellName, " ", destGUID, " ", seconds)
      else
        self:Output("Unique aura ", spellName, " ", destGUID, " ", seconds)
        unique:Set({ "aura", spellName or sourceName }, unique:Get({ "spell", spellName }) or seconds)
        --unique:Set({ "aura", spellName or sourceName, destGUID }, unique:Get({ "dest", spellName, destGUID }) or seconds)
      end
    end
    return
  elseif kind == "summon" then
    summoned[destGUID] = spellName
  end

  local miss = kind == "miss"
  if miss then kind = "damage" end

  if sourceName == player.name then sourceName = "%n" end
  local key = strjoin(DELIM,
    tostring(kind),
    tostring(timed),
    tostring(seconds),
    tostring(sourceName),
    tostring(petMatch),
    tostring(destGUID),
    tostring(spellID),
    tostring(spellName))
  self:Output("Logging ", key)
  logKeys[key] = { kind, timed, seconds, sourceName, petMatch, destGUID, spellID, spellName }
  local logged = log[key]
  if not logged then
    logged = {}
    log[key] = logged
  end
  logged.timed = logged.timed or timed
  if miss then
    if school and school > 0 then logged.partial = true end
    if not school or school == 0 then school = 1 end
    logged.miss = logged.miss or {}
    logged.miss[amount] = school + (logged.miss[amount] or 0)
  else
    self:UpdateLog(logged, amount, overflow, crit, timed)
    local logTotal = logTotals[kind]
    if not logTotal then
      logTotal = {}
      logTotals[kind] = logTotal
    end
    self:UpdateLog(logTotal, amount, overflow, crit, timed)
  end
  self:Queue("ResolveLog")
end

--- @return nil
function Addon:ResolveLog()
  self:Output("Processing")
  local lastLog = log
  local lastKeys = logKeys
  local lastTotals = logTotals
  log = {}
  logKeys = {}
  logTotals = {}

  local trackers = self.core.Trackers
  for trackerName, tracker in pairs(trackers) do
    if tracker and tracker.enabled and lastTotals[tracker.trackerType] then
      local tracker_spell = tracker.spell
      local total = lastTotals[tracker.trackerType]
      for meter, color in pairs(tracker.aura) do
        local name, icon, _, _, _, expires, _, _, _, id = FindAuraByName(meter, "player")
        if color == {} then
          color = colPack(getIconColor(icon))
          tracker_spell[meter] = color
        end
        if name then
          self:BuildAlert(trackerName, meter, meter, color, id, total, 2, expires - GetTime())
        end
      end
    end
  end

  if not lastLog then return end
  for key, logged in pairs(lastLog) do
    local kind, timed, seconds, sourceName, petMatch, destGUID, spellID, spellName = unpack(lastKeys[key])
    if spellName then
      for trackerName in pairs(frames) do
        local tracker = trackers[trackerName]
        if tracker and tracker.enabled and (not kind or kind == tracker.trackerType) then
          self:Match(spellName, spellID, trackerName, seconds, destGUID, logged)
        end
      end
    end
  end
end
