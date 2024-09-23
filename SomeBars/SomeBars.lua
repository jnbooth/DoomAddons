local shortName, N = ...
----------------
-- File globals
----------------

local A = LibStub("Abacus-2.0")
local D = LibStub("DoomCore-2.1")

--- @class SomeBars: Handler
--- @field core SomeBarsCore
--- @field settings SomeBarsSettings
local Addon = D.Addon(shortName, "Some Bars", N)
Addon.version = 1.0

local CreateFrame, GetSpellCharges, GetSpellBaseCooldown, GetSpellCooldown, GetSpellInfo, GetTime, InCombatLockdown, IsPlayerSpell, IsSpellKnown, min, next, pairs, select, strsub, tinsert, unpack, UIParent =
    CreateFrame, GetSpellCharges, GetSpellBaseCooldown, GetSpellCooldown, GetSpellInfo, GetTime, InCombatLockdown,
    IsPlayerSpell, IsSpellKnown, min, next, pairs, select, strsub, tinsert, unpack, UIParent
local assertType, colUnpack, flip, getItemID, nilSort, setIndex, tappend, TypeCode = A.assertType, A.colUnpack, A.flip,
    A.getItemID, A.nilSort, A.setIndex, A.tappend, A.TypeCode
local borders, convertDims, direction, growAnchors, HORIZONTAL, NodeCrawler, orientGrowth, subInfo, updateFrame =
    D.borders, D.convertDims, D.direction, D.growAnchors, D.HORIZONTAL, D.NodeCrawler, D.orientGrowth, D.subInfo,
    D.updateFrame

local type_number, type_string, type_table = TypeCode.Number, TypeCode.String, TypeCode.Table

--- @type table<string, BarGroupFrame>
local frames = {}

-------
-- Math
-------

--- @param val number
--- @param gcd number
--- @return boolean
function notGCD(val, gcd)
  return val > 1.5 or (val > 0 and not gcd)
end

--------
-- Frame
--------

--- @param self BarGroupFrame
local function frame_update(self)
  for _, slot in ipairs(self.slots) do
    local start = slot.start
    local spark = slot.Spark
    if start and spark and spark:IsVisible() then
      local progress = min(1, (slot.charges + (GetTime() - start) / slot.duration) / slot.maxCharges)
      local anchor = slot.anchor
      spark:SetPoint(anchor, slot, anchor, progress * slot.dimX, progress * slot.dimY)
    end
  end
end

--------
-- Core
--------

--- @return nil
function Addon:OnInitialize()
  self:Register({
    media = "LibSharedMedia-3.0",
    masque = "Masque"
  })

  self:TrackEvent("PLAYER_LOGIN")
  self:TrackMultiEventQueue("Update",
    "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_ENTER_COMBAT",
    "SPELL_UPDATE_COOLDOWN", "SPELL_UPDATE_USABLE", "SPELL_UPDATE_CHARGES",
    "BAG_UPDATE"
  )
end

--- @param registered boolean | nil
--- @return nil
function Addon:OnLoad(registered)
  if registered == false and self:RunMigration() then
    return
  end
  self.exports = {}
  local core = self.core
  local groups = core.Groups
  if groups == nil then
    groups = {}
    core.Groups = groups
  end
  for _, group in pairs(core.Groups) do
    for _, bar in pairs(group.bars) do
      bar.watch = bar.watch or {}
    end
  end

  for groupName, group in pairs(groups) do
    local default = group.Default
    self:AutoDefault(default)
    for barName, bar in pairs(group.bars) do
      bar.newColor = bar.watch[barName].color
      setIndex(bar, default)
    end
    self:BuildGroup(groupName)
  end
end

--- @param version number
--- @return boolean
function Addon:Migrate(version)
  if version < 0.1 then return true end
  local core = self.core
  local groups = core.Groups
  if groups == nil then
    groups = {}
    core.Groups = groups
  end
  if version < 0.2 then
    for groupName, group in pairs(core) do
      if type(group) == "table" and group.type == "group" then
        local growth = group --[[@as { growth: string | nil }]].growth
        if growth == "up" then group.grow = "TOP" end
        if growth == "down" then group.grow = "BOTTOM" end
        if group.grow == "up" then group.grow = "TOP" end
        if group.grow == "down" then group.grow = "BOTTOM" end
      end
    end
  end
  if version < 0.3 then
    for groupName, group in pairs(core) do
      if type(group) == "table" and group.type == "group" then
        core[groupName] = nil
        group.grow = group.grow:upper()
        group.orientation = group.orientation:upper()
        groups[groupName] = group
      end
    end
  end
  if version < 0.4 then
    core.Extras = core --[[@as any]]._debug
    core._debug = nil
    core.Groups = core --[[@as any]].groups
    core.groups = nil
  end
  if version < 0.5 then
    for _, group in pairs(core.Groups) do
      local bars = group.bars
      if bars == nil then
        bars = {}
        group.bars = bars
      end
      for barName, bar in pairs(group) do
        if type(bar) == "table" and bar.type == "bar" then
          group[barName] = nil
          bars[barName] = bar
        end
      end
    end
  end
  if version < 0.6 then
    for _, group in pairs(core.Groups) do
      for _, bar in pairs(group.bars) do
        bar.watch = bar.watch or {}
      end
    end
  end
  if version < 0.7 then
    for _, group in pairs(core.Groups) do
      local default = group.bars.Default
      if default then
        group.Default = default
        group.bars.Default = nil
      end
    end
  end
  if version < 0.8 then
    for _, group in pairs(core.Groups) do
      for _, bar in pairs(group.bars) do
        for watchName, watch in pairs(bar) do
          if type(watch) == "table" and watch.type == "also" then
            bar.watch[watchName] = watch
            bar[watchName] = nil
          end
        end
      end
    end
  end
  if version < 0.9 then
    for _, group in pairs(core.Groups) do
      group.barBackgroundColor = group --[[@as any]].bg
      group.barBorderColor = group --[[@as any]].border
    end
  end
  if version < 1.0 then
    for _, group in pairs(core.Groups) do
      for _, bar in pairs(group.bars) do
        bar.color = nil
      end
    end
  end
  return false
end

----------------
-- Bar handling
----------------

--- @overload fun(self: SomeBars, info: CorePath, r: number, g: number, b: number, a: number): nil
--- @overload fun(self: SomeBars, info: CorePath, r: number, g: number, b: number): nil
--- @overload fun(self: SomeBars, info: CorePath, val: any): nil
function Addon:Rebuild(info, r, g, b, a)
  if info then
    self:ConfSet(info, r, g, b, a)
  end
  self:BuildGroup(info[1])
end

--- @overload fun(self: SomeBars, info: CorePath, r: number, g: number, b: number, a: number): nil
--- @overload fun(self: SomeBars, info: CorePath, r: number, g: number, b: number): nil
function Addon:UpdateBarColor(info, r, g, b, a)
  self:ConfSet(info, r, g, b, a)
  self:ConfSet(tappend(subInfo(info, 1, -2), info[#info - 1], "color"), r, g, b, a)
  self:BuildGroup(info[1])
end

--- @param info CorePath
--- @param name string
--- @return nil
function Addon:AddGroup(info, name)
  assertType(info, type_table, name, type_string)
  local group = self:Make(self.core.Groups, "group", name, true)
  if not group then
    return
  end
  self:Make(group, "bar", "Default")
  group.bars = group.bars or {}
  self:BuildGroup(name)
end

--- @param info CorePath
--- @param name string
--- @return nil
function Addon:RenameGroup(info, name)
  assertType(info, type_table, name, type_string)
  local groups = self.core.Groups
  if groups[name] then
    return
  end
  local old = info[1]
  groups[name] = groups[old]
  groups[old] = nil

  self.settings.crawler.old = nil
  frames[name] = frames[old[1]]
  frames[old[1]] = nil
  self:BuildGroup(name)
end

--- @param info CorePath
--- @return nil
function Addon:DeleteGroup(info)
  assertType(info, type_table)
  local group = info[1]
  self.core[group] = nil
  self.settings.options.args[group] = nil
end

--- @param info CorePath
--- @return nil
function Addon:ResetGroup(info)
  --- @type BarGroup
  local group = self.core.Groups[info[1]]
  for barName, bar in pairs(group.bars) do
    bar.combat = nil
    bar.noncombat = nil
    bar.iconAlpha = nil
    bar.barAlpha = nil
    bar.sparkAlpha = nil
    bar.dim1 = nil
    bar.dim2 = nil
    bar.reverse = nil
  end
end

--- @param info CorePath
--- @param name string
--- @return nil
function Addon:AddBar(info, name)
  assertType(info, type_table, name, type_string)
  local groupName = info[1]
  local group = self.core.Groups[groupName]
  --- @type Bar
  local bar = self:Make(group.bars, "bar", name, true)
  if not bar then
    return
  end
  setIndex(bar, group.Default)
  if group.add.barType == "item" then
    bar.item = getItemID(name)
  end
  bar.watch = bar.watch or {}
  bar.watch[name] = {
    color = bar.newColor
  }
  bar.position = self:BarCount(groupName)
  self:BuildGroup(groupName)
end

--- @param info CorePath
--- @return nil
function Addon:DeleteBar(info)
  assertType(info, type_table)
  self:Set(subInfo(info, 1, -2), nil)
  self.settings.crawler:Set({ info[1], "args", info[2] }, nil)
  self:BuildGroup(info[1])
end

--- @param info CorePath
--- @param val string | number
--- @return nil
function Addon:Watch(info, val)
  assertType(info, type_table, val, type_number + type_string)
  local groupName = info[1]
  local barName = info[3]
  --- @type Bar | nil
  local bar = self:GetParent(info)
  if not bar then
    return
  end
  bar.watch = bar.watch or {}
  bar.watch[val] = {
    color = bar.newColor,
    image = select(3, GetSpellInfo(val))
  }
  bar.newColor = bar.watch[barName].color
  self:BuildGroup(groupName)
end

--- @param info CorePath
--- @param name string | number
function Addon:Unwatch(info, name)
  assertType(info, type_table)
  self:Set(subInfo(info, 1, -1), nil)
end

--- @class ColorPath: CorePath
--- @field [7] string

--- @param info ColorPath
--- @return CorePath
local function watchColorKey(info)
  return tappend(subInfo(info, 1, -2), "watch", strsub(info[#info], 0, - #"color" - 1), "color")
end

--- @param info ColorPath
--- @return Color
function Addon:ConfGetWatchColor(info)
  return self:ConfGet(watchColorKey(info))
end

--- @param info ColorPath
--- @param r number
--- @param g number
--- @param b number
--- @param a? number
--- @return nil
function Addon:ConfSetWatchColor(info, r, g, b, a)
  self:ConfSet(watchColorKey(info), r, g, b, a)
  self:BuildGroup(info[1])
end

--- @param bar Bar
--- @param image number
function Addon:SetIcon(bar, image)
  bar.image = image
  return image
end

----------
-- Frames
----------

--- @param groupName string
--- @return nil
function Addon:BuildGroup(groupName)
  assertType(groupName, type_string)
  local group = self.core.Groups[groupName]
  self.settings:BuildGroupSettings(groupName, group)
  self:BuildGroupFrame(groupName, group)
end

--- @param groupName tablekey
--- @return number
function Addon:BarCount(groupName)
  assertType(groupName, type_string)
  return self.core.Groups[groupName].count or 0
end

--- @param spell number | string
--- @return number | nil
function Addon:KnownIcon(spell)
  local name, _, icon, _, _, _, id = GetSpellInfo(spell)
  if id and (IsPlayerSpell(id) or IsSpellKnown(id) or IsSpellKnown(id, true) or GetSpellInfo(name)) then
    return icon
  end
end

--- @param bar Bar
--- @param combat boolean
function Addon:BarDisplay(bar, combat)
  if combat then
    return bar.combat
  else
    return bar.noncombat
  end
end

--- @param slot BarFrame
--- @param gcd number
--- @param dim1 number
--- @param dim2 number
--- @param bar Bar
--- @param spellName number | string
--- @param spellData BarItem
--- @return boolean | nil
function Addon:CheckCooldown(slot, gcd, dim1, dim2, bar, spellName, spellData, prev)
  local icon = self:KnownIcon(spellName)

  if not icon then
    return false
  end

  local charges, maxCharges, chargeStart, chargeDuration = GetSpellCharges(spellName)
  if not maxCharges and type(spellName) == "number" and not GetSpellBaseCooldown(spellName) then
    return false
  end

  local actualName = GetSpellInfo(spellName)
  if actualName and actualName ~= spellName then
    return false
  end

  local bg, button, fg, goals, group, spark = slot.bg, slot.button, slot.fg, slot.Goals, slot.group, slot.Spark

  local grow, iconPos, iconSpacing, orientation = group.grow, group.iconPos, group.iconSpacing, group.orientation

  local barAlpha, barReverse = bar.barAlpha, bar.reverse

  local growth = orientGrowth[orientation][barReverse]
  local anchors = growAnchors[growth]
  local borders = borders[growth]
  local minDim = min(dim1, dim2)
  local diff = spellName ~= prev
  local r, g, b = colUnpack(spellData.color)
  local sparkAlpha = bar.sparkAlpha
  local start, duration, valid
  local reverse = growAnchors[grow][3] + growAnchors[grow][4]
  if barReverse then reverse = -1 * reverse end

  if charges and charges < maxCharges and chargeStart and chargeStart > 0 and notGCD(chargeDuration, gcd) then
    start = chargeStart
    duration = chargeDuration
    valid = true
    for i = 1, charges do if goals[i] then goals[i]:Hide() end end
    for i = charges + 1, maxCharges - 1 do
      local goal = goals[i]
      if not goal then
        goal = CreateFrame("Frame", slot:GetName() .. ".Goals[" .. i .. "]", slot) --[[@as TexturedFrame]]
        goal:SetFrameStrata("MEDIUM")
        goal:SetFrameLevel(101)
        goal.tex = goal:CreateTexture(goal:GetName() .. ".tex")
        goal.tex:SetAllPoints(goal)
        goals[i] = goal
      end
      goal:SetSize(minDim, minDim)
      goal.tex:SetColorTexture(r, g, b, sparkAlpha)
      local offsetX, offsetY = convertDims(orientation, dim1 * i / maxCharges, 0)
      goal:SetPoint(anchors[1], slot, anchors[1], offsetX, offsetY)
      goal:Show()
    end
    for i = maxCharges, #goals do goals[i]:Hide() end
    if charges > 0 then
      fg:ClearAllPoints()
      fg:SetPoint(borders[1][1], slot, borders[1][1])
      fg:SetPoint(borders[2][1], slot, borders[2][1])
      fg:SetSize(convertDims(orientation, dim1 * charges / maxCharges, dim2))
      bg:ClearAllPoints()
      bg:SetPoint(borders[1][2], slot, borders[1][2])
      bg:SetPoint(borders[2][2], slot, borders[2][2])
      bg:SetPoint(borders[1][1], fg, borders[1][2])
      bg:SetPoint(borders[2][1], fg, borders[2][2])
      bg:Show()
      fg:Show()
    else
      fg:Hide()
      bg:SetAllPoints()
      bg:Show()
    end
  end
  if not charges and not valid then
    local cdStart, cdDuration, cdValid = GetSpellCooldown(spellName)
    if cdValid and notGCD(cdDuration, gcd) then
      start = cdStart
      duration = cdDuration
      valid = true
      for _, goal in pairs(goals) do goal:Hide() end
      fg:Hide()
      bg:SetAllPoints()
      bg:Show()
    end
  end
  if not valid then
    return
  end
  slot.charges = charges or 0
  slot.maxCharges = maxCharges or 1
  slot.start = start
  slot.duration = duration
  slot.anchor = anchors[1]
  if direction[orientation] == HORIZONTAL then
    slot.dimX = reverse * dim1
    slot.dimY = 0
  else
    slot.dimX = 0
    slot.dimY = reverse * dim1
  end

  local barAnchors = growAnchors[orientGrowth[orientation][barReverse]]
  if iconPos == "before" then
    button:Show()
    button:SetPoint(barAnchors[2], slot, barAnchors[1], -iconSpacing * barAnchors[3], iconSpacing * barAnchors[4])
  elseif iconPos == "after" then
    button:Show()
    button:SetPoint(barAnchors[1], slot, barAnchors[2], iconSpacing * barAnchors[3], iconSpacing * barAnchors[4])
  else
    button:Hide()
  end
  slot.icon:SetTexture(icon)

  spark.tex:SetColorTexture(r, g, b, sparkAlpha)
  slot.fg:SetColorTexture(r, g, b, barAlpha)

  spark:Show()
  self:SetVisible(slot, true)
  slot.lastActive = { bar = bar, name = spellName, data = spellData, icon = icon }
  return true
end

--- @param slot BarFrame
--- @param gcd number
--- @param combat boolean
--- @return nil
function Addon:UpdateSlot(slot, gcd, combat)
  if not slot.bars or not next(slot.bars) then
    return
  end
  local prev
  local dim1, dim2 = convertDims(slot.group.orientation, slot:GetWidth(), slot:GetHeight())
  local activeBar, activeName, activeData, activeIcon
  local last = slot.lastActive
  if last then
    prev = last.name
    local lastDisplay = self:BarDisplay(last.bar, combat)
    if prev and lastDisplay ~= "hide" then
      local checked = self:CheckCooldown(slot, gcd, dim1, dim2, last.bar, prev, last.data, prev)
      if checked then
        return
      end
      if checked ~= false and lastDisplay == "show" then
        activeBar = last.bar
        activeName = last.name
        activeData = last.data
        activeIcon = last.icon
      end
    end
  end

  for _, bar in pairs(slot.bars) do
    local display = self:BarDisplay(bar, combat)
    if display ~= "hide" then
      for watchName, watch in pairs(bar.watch) do
        local checked = self:CheckCooldown(slot, gcd, dim1, dim2, bar, watchName, watch, prev)
        if checked then
          return
        end
        if checked ~= false and display == "show" then
          activeBar = bar
          activeName = watchName
          activeData = watch
          activeIcon = self:KnownIcon(watchName)
        end
      end
    end
  end
  if not activeName then
    self:SetVisible(slot, false)
    return
  end
  --- @type Color
  local color
  if activeData then
    color = activeData.color
  else
    color = activeBar.watch[activeName].color
  end
  slot.fg:SetColorTexture(color.r, color.g, color.b, activeBar.barAlpha)
  slot.fg:SetAllPoints(slot)
  for _, goal in pairs(slot.Goals) do goal:Hide() end
  slot.fg:Show()
  slot.bg:Hide()
  slot.fg:SetWidth(slot:GetWidth())
  slot.Spark:Hide()
  if activeIcon then slot.icon:SetTexture(activeIcon) end
  slot.button:SetAlpha(activeBar.iconAlpha or 1)
  slot.lastActive = { bar = activeBar, name = activeName, data = activeData, icon = activeIcon }
  self:SetVisible(slot, true)
end

--- @param slot BarFrame
--- @return nil
function Addon:InitSlot(slot)
  local name = slot:GetName()
  local slot_border = {}
  for borderName, border in pairs(borders) do
    slot_border[borderName] = slot:CreateTexture(name .. ".Border." .. borderName, "BACKGROUND")
    local b = slot_border[borderName]
    b:SetSize(1, 1)
    b:SetPoint(border[1][1], slot, border[1][2], border[1][3], border[1][4])
    b:SetPoint(border[2][1], slot, border[2][2], border[2][3], border[2][4])
  end
  slot.border = slot_border

  slot.fg = slot:CreateTexture()
  slot.fg:SetDrawLayer("BORDER")
  slot.fg:SetAllPoints(slot)
  slot.bg = slot:CreateTexture()
  slot.bg:SetDrawLayer("BACKGROUND")
  slot.bg:SetAllPoints(slot)
  slot.bg:Hide()

  slot.button = CreateFrame("Button", slot:GetName() .. "Button", slot)
  slot.button:SetFrameStrata("HIGH")
  slot.button:EnableMouse(false)
  slot.button:Disable()
  slot.Goals = {}
  slot.Spark = CreateFrame("Frame", slot:GetName() .. ".Spark", slot) --[[@as TexturedFrame]]
  local spark = slot.Spark
  spark:SetFrameStrata("MEDIUM")
  spark.tex = spark:CreateTexture(spark:GetName() .. ".tex")
  spark.tex:SetAllPoints(spark)
  --slot.spark.tex:SetBlendMode("DISABLE")
  slot.icon = slot.button:CreateTexture()
  slot.icon:SetAllPoints(slot.button)

  slot.appearGroup = slot:CreateAnimationGroup()
  slot.appear = slot.appearGroup:CreateAnimation("Alpha") --[[@as AlphaAnimation]]
  slot.appear:SetDuration(0.15)
  slot.appear:SetFromAlpha(0)
  slot.appear:SetToAlpha(1)
  slot.appearGroup:SetScript("OnPlay", function()
    slot.fadeGroup:Stop()
    slot:Show()
  end)

  slot.fadeGroup = slot:CreateAnimationGroup()
  slot.fade = slot.fadeGroup:CreateAnimation("Alpha") --[[@as AlphaAnimation]]
  slot.fade:SetDuration(0.075)
  slot.fade:SetFromAlpha(1)
  slot.fade:SetToAlpha(0)
  slot.fadeGroup:SetScript("OnPlay", function() slot.appearGroup:Stop() end)
  slot.fadeGroup:SetScript("OnFinished", function() slot:Hide() end)
end

--- @param slot BarFrame
--- @param visible boolean
--- @return nil
function Addon:SetVisible(slot, visible)
  if visible == slot:IsShown() then
  elseif visible then
    slot.appearGroup:Play()
  else
    slot.fadeGroup:Play()
  end
end

--- @param name string
--- @param group BarGroup
--- @return nil
function Addon:BuildGroupFrame(name, group)
  local tracked = {}
  local time = GetTime()
  local combat = InCombatLockdown()
  if not group then
    if frames[name] then
      frames[name]:Hide()
    end
    return
  end
  assertType(name, type_string, group, type_table)
  self:AutoDefault(group)
  local frame = frames[name]
  if not frame then
    frame = CreateFrame("Frame", self.shortName .. name, UIParent) --[[@as BarGroupFrame]]
    frame:SetScript("OnUpdate", frame_update)
    frame.tex = frame:CreateTexture(frame:GetName() .. ".tex", "BORDER")
    frame.tex:SetAllPoints(frame)
    frame.tex:SetColorTexture(0, 1, 0, 0.5)
    frame.slots = {}

    frames[name] = frame
    if self.lib.masque then
      frame.msq = self.lib.masque:Group(self.name, name)
    end
  end
  frame.conf = group
  self:Draggable(frame, group)
  frame.count = 0
  frame:ClearAllPoints()

  local bg, border, iconSize, iconPos, orientation, spacing = group.barBackgroundColor, group.barBorderColor or {},
      group.iconSize, group.iconPos
      ,
      group.orientation, group.spacing

  local anchor, grow, lock, offsetX, offsetY = group.anchor, group.grow, group.lock, group.offsetX, group.offsetY

  local bg_r, bg_g, bg_b, bg_a, border_r, border_g, border_b, border_a = bg.r, bg.g, bg.b, bg.a, border.r, border.g,
      border.b, border.a

  local frame_slots = frame.slots

  local linear = direction[grow] == direction[orientation]
  local group_iconSpacing = group.iconSpacing
  local iconSpacing
  if linear then
    iconSpacing = iconSize
  else
    iconSpacing = 0
  end
  local anchors = growAnchors[grow]
  local barAnchors = growAnchors[orientGrowth[orientation][false]]
  local xSpace = (spacing + iconSpacing) * anchors[3]
  local ySpace = (spacing + iconSpacing) * anchors[4]

  local bars = {}
  for barName, bar in pairs(group.bars) do
    tinsert(tracked, bar.watch)
    for watch in pairs(bar.watch) do
      tinsert(tracked, watch)
    end
    tinsert(bars, bar)
  end
  nilSort(bars, function(bar) return bar.position end)

  local barSlots = {}
  local slotI = 0
  local atPos = 0
  for _, bar in pairs(bars) do
    local position = bar.position
    if position then
      if position > atPos then
        atPos = position
        slotI = slotI + 1
      end
      barSlots[slotI] = barSlots[slotI] or {}
      tinsert(barSlots[slotI], bar)
    end
  end
  local count = #barSlots
  group.count = max(count, atPos) + 1
  for i, barList in pairs(barSlots) do
    for _, bar in pairs(barList) do
      bar.slot = i
    end
    local slot = frame_slots[i]
    if not slot then
      slot = CreateFrame("Frame", self.shortName .. name .. "_" .. i, frame) --[[@as BarFrame]]
      slot:SetFrameStrata("LOW")
      self:InitSlot(slot)
      frame_slots[i] = slot
      slot.group = group
      if frame.msq then frame.msq:AddButton(slot.button, { Icon = slot.icon }) end
    end

    slot.bg:SetColorTexture(bg_r, bg_g, bg_b, bg_a)

    local slot_border, slot_button = slot.border, slot.button
    for borderName in pairs(borders) do
      slot_border[borderName]:SetColorTexture(border_r, border_g, border_b, border_a)
    end
    slot_button:ClearAllPoints()
    if iconPos == "before" then
      slot_button:Show()
      slot_button:SetPoint(barAnchors[2], slot, barAnchors[1], -group_iconSpacing * barAnchors[3],
        group_iconSpacing * barAnchors[4])
    elseif iconPos == "after" then
      slot_button:Show()
      slot_button:SetPoint(barAnchors[1], slot, barAnchors[2], group_iconSpacing * barAnchors[3],
        group_iconSpacing * barAnchors[4])
    else
      slot_button:Hide()
    end
    slot_button:SetSize(iconSize, iconSize)
    if i == 1 then
      slot:SetPoint(anchors[1], frame, anchors[1])
    else
      slot:SetPoint(anchors[1], frame_slots[i - 1], anchors[2], xSpace, ySpace)
    end
    slot.lastActive = nil
    slot.bars = barList
    self:UpdateSlot(slot, time, combat)
  end
  for i = count + 1, #frame_slots do
    self:Output("Hiding ", i)
    local hide = frame_slots[i]
    hide.bars = {}
    hide:Hide()
  end

  if group.flexible then
    local frameDim1 = -spacing
    local frameDim2 = 0
    for i, barList in pairs(barSlots) do
      local barDim1 = 0
      local barDim2 = 0
      for _, bar in pairs(barList) do
        if bar.dim1 > barDim1 then barDim1 = bar.dim1 end
        if bar.dim2 > barDim2 then barDim2 = bar.dim2 end
      end
      local slot = frame_slots[i]
      slot:SetSize(convertDims(orientation, barDim1, barDim2))
      local relBar1, relBar2 = flip(not linear, barDim1, barDim2)
      frameDim1 = frameDim1 + spacing + relBar1
      if relBar2 > frameDim2 then frameDim2 = relBar2 end
    end
    frame:SetSize(convertDims(grow, frameDim1, frameDim2))
  else
    frame:SetSize(convertDims(orientation, group.dim1 - iconSpacing / 2, group.dim2))
    local spacing1, spacing2 = flip(not linear, iconSpacing / 2 + (spacing + iconSpacing) * (count - 1), 0)

    local barDim1 = (group.dim1 - spacing1) / count
    local barDim2 = (group.dim2 - spacing2)
    for i = 1, count do
      local barSlot = barSlots[i]
      local slot = frame_slots[i]
      slot:SetSize(convertDims(orientation, barDim1, barDim2))
    end
  end
  for _, slot in pairs(frame_slots) do
    local slot_width, slot_height = slot:GetWidth(), slot:GetHeight()
    local minDim = min(slot_width, slot_height)
    local spark = slot.Spark
    spark:SetSize(minDim, minDim)
    spark:ClearAllPoints()
    spark:SetPoint(anchors[1], slot, anchors[1])
    local reverse = growAnchors[grow][3] + growAnchors[grow][4]
  end
  if direction[orientation] == HORIZONTAL then
    offsetX = offsetX - iconSpacing / 4
  else
    offsetY = offsetY - iconSpacing / 4
  end

  updateFrame(frame)
  if frame.msq then frame.msq:ReSkin() end
  frame:Show()
  self:Queue("Update")
  self.exports[name] = tracked
  return frame
end

local function sortFunc(e1, e2)
  local nil1 = e1 == nil or e1.time == nil
  local nil2 = e2 == nil or e2.time == nil
  if nil1 then
    return false
  end
  if nil2 then
    return true
  end
  return e2.time < e1.time
end

----------
-- Events
----------

--- @return nil
function Addon:PLAYER_LOGIN()
  self:Update()
end

--- @return nil
function Addon:Update()
  self:Output("Updating")
  local disable = UnitControllingVehicle("player") -- or UnitInVehicle("player")
  local combat = InCombatLockdown()
  local gcd = GetSpellCooldown(61304)
  for groupName, frame in pairs(frames) do
    for _, slot in pairs(frame.slots) do
      if disable then
        slot:Hide()
      else
        self:UpdateSlot(slot, gcd, combat)
      end
    end
  end
end
