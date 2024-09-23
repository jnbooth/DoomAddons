---@diagnostic disable: redefined-local
local shortName, N = ...

----------------
-- File globals
----------------

local LibStub = LibStub
local A = LibStub:GetLibrary("Abacus-2.0")
local D = LibStub:GetLibrary("DoomCore-2.1")

local LCG = LibStub("LibCustomGlow-1.0")
ActionButton_ShowOverlayGlow = LCG.ButtonGlow_Start
ActionButton_HideOverlayGlow = LCG.ButtonGlow_Stop


--- @class CooldownInfo
--- @field [1] number | nil Record
--- @field [2] CooldownButton | nil

--- @class SomeCooldowns: Handler
--- @field core SomeCooldownsCore
--- @field lib SomeCooldownsLib
--- @field settings SomeCooldownsSettings
--- @field cooldowns { item: { [number]: CooldownInfo }, spell: { [number|string]: CooldownInfo } }
local Addon = D.Addon(shortName, "Some Cooldowns", N)
Addon.version = 0.4

local _G, C_Container, C_ToyBox, CreateFrame, GameTooltip, GetInventoryItemID, GetTime, ipairs, NUM_BAG_SLOTS, pairs, PlayerHasToy, select, tinsert, tostring, type, UIParent, unpack =
    _G
    , C_Container, C_ToyBox, CreateFrame, GameTooltip,
    GetInventoryItemID, GetTime,
    ipairs, NUM_BAG_SLOTS, pairs, PlayerHasToy, select, tinsert, tostring, type, UIParent, unpack
local GetContainerNumSlots, GetContainerItemID = C_Container.GetContainerNumSlots, C_Container.GetContainerItemID
local GetNumToys = C_ToyBox.GetNumToys --[[@as fun(): number]]
local GetToyFromIndex = C_ToyBox
    .GetToyFromIndex --[[@as fun(itemIndex: number): number, string, number, boolean, boolean, Enum.ItemQuality]]
local CheckPlayerHasControl = ArkInventory.CheckPlayerHasControl
local colUnpack, getItemID, nilSort, tooltip, tooltipAnchors, makeGrid, updateFrame = A.colUnpack, A.getItemID, A
    .nilSort
    , A.tooltip,
    D.tooltipAnchors, D.makeGrid, D.updateFrame

local C_Item, C_Spell, C_SpellBook = C_Item, C_Spell, C_SpellBook
local GetItemCooldown, GetItemIcon, GetItemInfo, GetItemName = C_Item.GetItemCooldown, C_Item.GetItemIconByID,
    C_Item.GetItemInfo, C_Item.GetItemNameByID
local GetSpellCharges, GetSpellCooldown, GetSpellID, GetSpellName, GetSpellTexture = C_Spell.GetSpellCharges,
    C_Spell.GetSpellCooldown, C_Spell.GetSpellIDForSpellIdentifier, C_Spell.GetSpellName, C_Spell.GetSpellTexture
local GetSpellBookItemInfo = C_SpellBook.GetSpellBookItemInfo

local gcd = 1.5
Addon.cooldowns = { spell = {}, item = {} }
--- @type CooldownsFrame
local frame

local count = 0

--------
-- Core
--------

--- @return nil
function Addon:OnInitialize()
  frame = CreateFrame("Frame", shortName, UIParent, "BackdropTemplate") --[[@as CooldownsFrame]]
  frame:SetFrameStrata("LOW")
  frame.conf = self.core
  frame.tex = frame:CreateTexture(frame:GetName() .. ".tex")
  frame.tex:SetAllPoints(frame)
  frame.tex:SetColorTexture(0, 1, 0, 0.5)
  frame.tex:Hide()

  self:Register({
    media = "LibSharedMedia-3.0",
    masque = "Masque",
    somebars = "SomeBars"
  }, "Default")

  self:TrackEvent("PLAYER_LOGIN")
  self:TrackEvent("GET_ITEM_INFO_RECEIVED")
  self:TrackMultiEventQueue("Update",
    "SPELL_UPDATE_COOLDOWN", "SPELL_UPDATE_USABLE", "SPELL_UPDATE_CHARGES",
    "BAG_UPDATE"
  )
end

--- @param registered? boolean
--- @return nil
function Addon:OnLoad(registered)
  if registered == false and self:RunMigration() then return end
  if self.lib.masque and not frame.msq then
    frame.msq = self.lib.masque:Group(self.name)
  end
  frame:SetScript("OnReceiveDrag", nil)
  self:Draggable(frame, self.core)

  self.core.group = self.core.group or {}
  local settings = self.settings
  for cooldown, data in pairs(self.core.group) do
    local cooldownType = data.type
    if cooldownType == "blacklist" or cooldownType == "whitelist" then
      settings:Add(cooldownType, cooldown)
    end
  end
  self:SetFilter()
  updateFrame(frame, self.core)
end

--- @return nil
function Addon:PLAYER_LOGIN()
  self:OnLoad()
end

--- @return nil
function Addon:GET_ITEM_INFO_RECEIVED()
  for valName, val in pairs(self.core.group or {}) do
    if type(valName) == "number" and val.type then
      local entry = self.settings.crawler:Get({ val.type, "args", tostring(valName) })
      if not entry and GetItemInfo(valName) then
        self:Add({ val.type }, valName)
      end
    end
  end
end

--- @param version number
--- @return boolean
function Addon:Migrate(version)
  if version < 0.1 then return true end
  local core = self.core
  if version < 0.2 then
    if core.rowGrowth == "up" then core.rowGrowth = "TOP" end
    if core.rowGrowth == "down" then core.rowGrowth = "BOTTOM" end
  end
  if version < 0.3 then
    local fieldsToMigrate = { "anchor", "columnGrowth", "grow", "grow2", "rowGrowth", "tooltipAnchor" }
    for _, field in ipairs(fieldsToMigrate) do
      local old = core[field]
      if type(old) == "string" then
        core[field] = old:upper()
      end
    end
  end
  if version < 0.4 then
    core.Extras = core --[[@as any]]._debug
    core --[[@as any]]._debug = nil
  end
  return false
end

--- @param info? CooldownsCorePath
--- @param val? boolean
--- @return nil
function Addon:SetFilter(info, val)
  if not frame then return end
  local update = false
  if info then
    if self:ConfGet(info) ~= val then
      update = true
      self.cooldowns = { item = {}, spell = {} }
    end
  end
  for cooldown, data in pairs(self.core.group) do
    if data.type == "blacklist" then
      local cooldowns
      if type(cooldown) == "number" then
        cooldowns = self.cooldowns.item
      else
        cooldowns = self.cooldowns.spell
      end
      cooldowns[cooldown] = {}
      update = true
    end
  end

  self:Update(update)
end

--- @param info CooldownsCorePath
--- @param val boolean
function Addon:SetText(info, val)
  self:ConfSet(info, val)
  for _, v in pairs({ frame:GetChildren() }) do
    v.cooldown:SetHideCountdownNumbers(not val)
  end
end

--- @param info CooldownsCorePath
--- @param val boolean
function Addon:SetReverse(info, val)
  self:ConfSet(info, val)
  for _, v in pairs({ frame:GetChildren() }) do
    v.cooldown:SetReverse(val)
  end
end

--- @param info CooldownsCorePath
--- @param r number
--- @param g number
--- @param b number
--- @param a? number
--- @return nil
function Addon:SetSwipeColor(info, r, g, b, a)
  self:ConfSet(info, r, g, b, a)
  for _, button in pairs({ frame:GetChildren() }) do
    button.cooldown:SetSwipeColor(r, g, b, a)
  end
end

----------
-- Events
----------

--- @param type "item"|"spell"|string|nil
--- @param id number
--- @return number start
--- @return number duration
--- @return boolean enabled
local function getCooldown(type, id)
  if type == "item" then
    return GetItemCooldown(id)
  end
  if type ~= "spell" then
    return 0, 0, false
  end
  local chargeInfo = GetSpellCharges(id)
  if chargeInfo then
    local charges = chargeInfo.currentCharges
    local maxCharges = chargeInfo.maxCharges
    local start = chargeInfo.cooldownStartTime
    local duration = chargeInfo.cooldownDuration
    if charges and charges < maxCharges and start > 0 and duration > gcd then
      return start, duration * (maxCharges - charges), true
    end
  end
  local cooldownInfo = GetSpellCooldown(id)
  if not cooldownInfo then
    return 0, 0, false
  end
  return cooldownInfo.startTime, cooldownInfo.duration, cooldownInfo.isEnabled
end


--- @param force? boolean
--- @return nil
function Addon:Sort(force)
  Addon:Output("Sorting")
  local children = { frame:GetChildren() }
  if not force and #children == 0 then return end
  local remove = {}
  local add = {}
  local time = GetTime()

  for _, button in pairs(children) do
    if button.active then
      local start, duration
      local type = button:GetAttribute("type")
      if type then
        local subject = button:GetAttribute(type)
        if subject then
          local start, duration = getCooldown(type, subject)
          if not start or not duration
              or duration <= gcd or start + duration + 1 <= time
              or not button.cooldown:IsShown()
              or button.cooldown:GetCooldownDuration() == 0 then
            tinsert(remove, button)
          else
            tinsert(add, button)
          end
        end
      end
    end
  end

  for _, button in pairs(remove) do
    self:CancelButton(button)
    button:Hide()
  end

  if not force and #add == 0 then return end

  local core = self.core

  nilSort(add, core.sort == "long" and "-expires" or "expires")

  makeGrid(frame, {
    els          = add,
    parent       = UIParent,
    anchor       = core.anchor,
    x            = core.offsetX,
    y            = core.offsetY,
    center       = { x = core.xCenter, y = core.yCenter },
    size         = core.iconSize,
    padding      = core.padding,
    spacing      = core.spacing,
    grow         = core.grow,
    rowGrowth    = core.rowGrowth,
    columnGrowth = core.columnGrowth,
    max          = core.max,
    limit        = core.limit,
    background   = core.background,
    border       = core.border,
    edge         = core.edge
  })

  if frame.msq then frame.msq:ReSkin() end
end

--- @param id number | nil
function Addon:OnSpellCooldown(id)
  if not id then return end
  local spellCooldowns = self.cooldowns.spell
  local record = 0
  local oldRecord, button
  local info = spellCooldowns[id]
  if info then
    if info == true then return end
    oldRecord, button = unpack(info)
  else
    info = {}
    spellCooldowns[id] = info
  end
  if oldRecord == true then return end
  local start, duration, enabled
  local chargeInfo = GetSpellCharges(id)
  if chargeInfo and chargeInfo.currentCharges then
    local charges = chargeInfo.currentCharges
    local maxCharges = chargeInfo.maxCharges
    local chargeStart = chargeInfo.cooldownStartTime
    local chargeDuration = chargeInfo.cooldownDuration
    record = charges
    if oldRecord == record then return end
    if not self.core.recharge and charges > 0 then return end
    if record == maxCharges then return end
    if oldRecord and button and record > oldRecord then
      ActionButton_ShowOverlayGlow(button)
      ActionButton_HideOverlayGlow(button)
    end
    if charges < maxCharges and chargeStart and chargeStart > 0 and chargeDuration > gcd then
      start = chargeStart
      duration = chargeDuration * (maxCharges - charges)
      enabled = true
    end
  else
    if oldRecord == record then return end
    local cooldownInfo = GetSpellCooldown(id)
    start = cooldownInfo.startTime
    duration = cooldownInfo.duration
    enabled = cooldownInfo.isEnabled
  end
  if id and start and start > 0 and duration > gcd and enabled then
    info[1] = record
    self:AddButton("spell", id, start, duration)
    self:Output("Sorting with spell ", id)
    return true
  end
end

--- @param id number | nil
function Addon:OnItemCooldown(id)
  if not id then return end
  local itemCooldowns = self.cooldowns.item
  local oldRecord
  local info = itemCooldowns[id]
  if info then
    if info == true then return end
    oldRecord = info[1]
    if oldRecord then return end
  else
    info = {}
    itemCooldowns[id] = info
  end
  if oldRecord then return end
  local start, duration, cooldown = GetItemCooldown(id)
  if not start then return end

  if start > 0 and duration > gcd and cooldown then
    info[1] = 0
    self:AddButton("item", id, start, duration)
    self:Output("Sorting with item ", id)
    return true
  end
end

--- @param hard? boolean
function Addon:Update(hard)
  gcd = select(2, GetSpellCooldown(61304)) or gcd
  local resort = false
  if not CheckPlayerHasControl() then return end
  if hard == true then
    self:Output("Hard reset")
    for _, button in pairs({ frame:GetChildren() }) do
      button.active = false
      button:Hide()
    end
    self.cooldowns = { spell = {}, item = {} }
  end
  for cooldown, data in pairs(self.core.group) do
    if data.type == "whitelist" then
      if type(cooldown) == "number" then
        local fromCooldown = self:OnItemCooldown(cooldown)
        if fromCooldown then
          self:Output("Sorted from whitelist item ", cooldown)
        end
        resort = fromCooldown or resort
      else
        local id = GetSpellID(cooldown)
        local fromCooldown = self:OnSpellCooldown(id)
        if fromCooldown then
          self:Output("Sorted from whitelist spell ", cooldown)
        end
        resort = fromCooldown or resort
      end
    end
  end

  if self.core.displaySpells then
    local index = 1
    while true do
      local _, id = GetSpellBookItemInfo(index, 0)
      if not id then break end
      local fromCooldown = self:OnSpellCooldown(id)
      if fromCooldown then
        self:Output("Sorted from spell ", id)
      end
      resort = fromCooldown or resort
      index = index + 1
    end
  end

  if self.core.displayItems then
    for slot = 1, 19 do
      local item = GetInventoryItemID("player", slot)
      local fromCooldown = self:OnItemCooldown(item)
      if fromCooldown then
        self:Output("Sorted from equipped item ", item)
      end
      resort = fromCooldown or resort
    end
    for bag = 0, NUM_BAG_SLOTS do
      for slot = 1, GetContainerNumSlots(bag) do
        local item = GetContainerItemID(bag, slot)
        local fromCooldown = self:OnItemCooldown(item)
        if fromCooldown then
          self:Output("Sorted from inventory item ", item)
        end
        resort = fromCooldown or resort
      end
    end
  end

  if self.core.displayToys then
    for i = 1, GetNumToys() do
      local toy = GetToyFromIndex(i)
      if PlayerHasToy(toy) then
        local fromCooldown = self:OnItemCooldown(toy)
        if fromCooldown then
          self:Output("Sorted from toy ", toy)
        end
        resort = fromCooldown or resort
      end
    end
  end
  if resort then self:Queue("Sort") end
end

----------
-- Frames
----------

--- @overload fun(self: self, info: CorePath, r: number, g: number, b: number, a?: number): nil
--- @overload fun(self: self, info: CorePath, val: any): nil
function Addon:Rebuild(info, r, g, b, a)
  if info then self:ConfSet(info, r, g, b, a) end
  local size = self.core.iconSize
  frame:SetSize(size + 4, size + 4)

  for _, button in pairs({ frame:GetChildren() }) do
    button:SetSize(size, size)
  end

  self:Update()
  self:Sort(true)

  updateFrame(frame, self.core)
end

--- @param info CooldownsCorePath
--- @param val number | string
function Addon:Add(info, val)
  local group
  if info[1] == "addToWhitelist" then
    group = "whitelist"
  elseif info[1] == "addToBlacklist" then
    group = "blacklist"
  else
    return
  end

  if not GetSpellID(val) then
    local itemId = getItemID(val)
    if itemId == nil then
      return
    end
    val = itemId
  end

  if info[1] == "addToBlacklist" then
    for _, b in pairs({ frame:GetChildren() }) do
      local contained = b:GetAttribute(b:GetAttribute("type"))
      if contained == val then
        b.active = false
        b:Hide()
        break
      end
    end
  end

  self:Make(self.core.group, group, val)

  self.settings:Add(group, val)

  self:Update()
end

--- @param button CooldownButton
--- @return nil
function Addon:CancelButton(button)
  local type = button:GetAttribute("type")
  if not type then return end
  local subject = button:GetAttribute(type)
  self:Output("Canceling ", type, " ", subject)
  button.active = false
  self.cooldowns[type][subject] = {}
end

--- @param button CooldownButton
--- @return nil
function Addon:InitButton(button)
  button:Hide()
  ActionButton_ShowOverlayGlow(button)
  ActionButton_HideOverlayGlow(button)
  for _, child in pairs({ button:GetChildren() }) do
    if child.outerGlowOver then
      child.outerGlow:Hide()
      child.outerGlowOver:Hide()
      child.ants:Hide()
    end
  end
  button:SetAttribute("unit", "player")
  button.cooldownFrame = _G[button:GetName() .. "Cooldown"]
  button.cooldownFrame:SetEdgeTexture("Interface\\Cooldown\\edge-LoC")
  button.cooldownFrame:SetScript("OnHide", function() self:Sort() end)
  button.cooldown:SetSwipeColor(colUnpack(self.core.color))
  button.cooldown:SetHideCountdownNumbers(not self.core.text)
  button:Disable()
  tooltip(button, self.core.tooltip, self.core.tooltipOverride and self.core.tooltipAnchor or nil,
    function(button) Addon:CancelButton(button) end)
end

--- @param buttonType "item" | "spell"
--- @param id number
--- @param time number
--- @param duration number
function Addon:AddButton(buttonType, id, time, duration)
  local typeCooldowns = self.cooldowns[buttonType]
  --- @type string?, number?
  local name, icon
  if buttonType == "spell" then
    name = GetSpellName(id)
    icon = GetSpellTexture(id)
  else
    name = GetItemName(id)
    icon = GetItemIcon(id)
  end
  for cooldown, data in pairs(self.core.group) do
    if data.type == "blacklist" and (id == cooldown or name == cooldown) then
      return
    end
  end
  local somebars = self.core.Extras.somebars and self.lib.somebars
  local somebars_exports = somebars and somebars.exports
  if somebars_exports and somebars_exports[buttonType][id] then
    return
  end
  local button
  local oldInfo = typeCooldowns[id]
  if oldInfo then
    button = oldInfo[2]
  else
    oldInfo = {}
    typeCooldowns[id] = oldInfo
  end
  if not button then
    for _, b in pairs({ frame:GetChildren() }) do
      if not b.active then
        button = b
        break
      end
    end
  end
  if not button then
    count = count + 1
    button = CreateFrame("Button", frame:GetName() .. count, frame, "ActionButtonTemplate") --[[@as CooldownButton]]
    self:InitButton(button)
    if frame.msq then frame.msq:AddButton(button) end
  end
  typeCooldowns[id][2] = button
  button.icon:SetTexture(icon)
  local iconSize = self.core.iconSize
  button:SetSize(iconSize, iconSize)
  button:SetAttribute("type", buttonType)
  button:SetAttribute(buttonType, id)
  button:GetNormalTexture():Hide()
  button.cooldownFrame:SetCooldown(time, duration)
  button.cooldownFrame:SetReverse(self.core.reverse)
  button.expires = time + duration
  button.active = true
  --button:Show()
end

--- @param info CooldownsCorePath
--- @param val any
function Addon:UpdateTooltips(info, val)
  self:ConfSet(info, val)
  local tooltip = self.core.tooltip
  --- @type TooltipAnchor
  local anchor
  if self.core.tooltipOverride then
    anchor = tooltipAnchors[self.core.tooltipAnchor]
  else
    anchor = "ANCHOR_PRESERVE"
  end
  for _, button in pairs({ frame:GetChildren() }) do
    if button:IsMouseOver() then
      if tooltip then
        GameTooltip:SetOwner(button, tooltipAnchors[anchor])
      else
        button:GetScript("OnLeave")(button)
      end
    end
    button:SetMotionScriptsWhileDisabled(tooltip)
  end
end
