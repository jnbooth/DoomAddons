---@diagnostic disable: redefined-local
local shortName, N = ...

----------------
-- File globals
----------------

local LibStub = LibStub
local A = LibStub:GetLibrary("Abacus-2.0")
local D = LibStub:GetLibrary("DoomCore-2.1")

--- @class SomeCooldowns: Handler
--- @field core SomeCooldownsCore
--- @field lib SomeCooldownsLib
--- @field settings SomeCooldownsSettings
local Addon = D.Addon(shortName, "Some Cooldowns", N)
Addon.version = 0.4

local _G, ActionButton_ShowOverlayGlow, ActionButton_HideOverlayGlow, C_Container, C_ToyBox, CreateFrame, GetItemIcon, GetItemInfo, GetInventoryItemID, GetSpellBookItemInfo, GetSpellCharges, GetSpellCooldown, GetSpellInfo, GetTime, ipairs, NUM_BAG_SLOTS, pairs, PlayerHasToy, select, tinsert, tostring, type, UIParent, unpack = _G
    , ActionButton_ShowOverlayGlow, ActionButton_HideOverlayGlow, C_Container, C_ToyBox, CreateFrame, GetItemIcon,
    GetItemInfo, GetInventoryItemID, GetSpellBookItemInfo, GetSpellCharges, GetSpellCooldown, GetSpellInfo, GetTime,
    ipairs, NUM_BAG_SLOTS, pairs, PlayerHasToy, select, tinsert, tostring, type, UIParent, unpack
local GetContainerNumSlots, GetContainerItemID = C_Container.GetContainerNumSlots, C_Container.GetContainerItemID
local GetNumToys = C_ToyBox.GetNumToys --[[@as fun(): number]]
local GetToyFromIndex = C_ToyBox.GetToyFromIndex --[[@as fun(itemIndex: number): number, string, number, boolean, boolean, Enum.ItemQuality]]
local CheckPlayerHasControl = ArkInventory.CheckPlayerHasControl
local colUnpack, getItemID, nilSort, tooltip, tooltipAnchors, makeGrid, updateFrame = A.colUnpack, A.getItemID, A.nilSort
    , A.tooltip,
    D.tooltipAnchors, D.makeGrid, D.updateFrame
local GetItemCooldown = GetItemCooldown --[[@as fun(itemID: number): number, number, number]]

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
  local crawler = self.settings.crawler
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
    core.Extras = core--[[@as any]] ._debug
    core._debug = nil
  end
  return false
end

--- @param info? CorePath
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
      cooldowns[cooldown] = true
      update = true
    end
  end

  self:Update(update)
end

--- @param info CorePath
--- @param val boolean
function Addon:SetText(info, val)
  self:ConfSet(info, val)
  for _, v in pairs({ frame:GetChildren() }) do
    v.cooldown:SetHideCountdownNumbers(not val)
  end
end

--- @param info CorePath
--- @param val boolean
function Addon:SetReverse(info, val)
  self:ConfSet(info, val)
  for _, v in pairs({ frame:GetChildren() }) do
    v.cooldown:SetReverse(val)
  end
end

--- @param info CorePath
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
          if type == "spell" then
            local charges, maxCharges, chargeStart, chargeDuration = GetSpellCharges(subject)
            if charges and charges < maxCharges and chargeStart and chargeStart > 0 and chargeDuration > gcd then
              start = chargeStart
              duration = chargeDuration * (maxCharges - charges)
            else
              start, duration = GetSpellCooldown(subject)
            end
          elseif type == "item" then
            start, duration = GetItemCooldown(subject)
          end
          if not start or not duration or duration <= gcd or start + duration + 1 <= time
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

  makeGrid {
    frame        = frame,
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
  }

  if frame.msq then frame.msq:ReSkin() end
end

--- @param name string | nil
--- @param icon number
function Addon:OnSpellCooldown(name, icon)
  if not name then return end
  local spellCooldowns = self.cooldowns.spell
  local record = 0
  local oldRecord, button
  local info = spellCooldowns[name]
  if info then
    if info == true then return end
    oldRecord, button = unpack(info)
  else
    info = {}
    spellCooldowns[name] = info
  end
  if oldRecord == true then return end
  local start, duration, cooldown
  local charges, maxCharges, chargeStart, chargeDuration = GetSpellCharges(name)
  if charges then
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
      cooldown = true
    end
  else
    if oldRecord == record then return end
    start, duration, cooldown = GetSpellCooldown(name)
  end
  if name and start and start > 0 and duration > gcd and cooldown then
    info[1] = record
    self:AddButton("spell", name, start, duration, icon)
    self:Output("Sorting with spell ", name)
    return true
  end
end

--- @param name number | nil
function Addon:OnItemCooldown(name)
  if not name then return end
  local itemCooldowns = self.cooldowns.item
  local oldRecord, button
  local info = itemCooldowns[name]
  if info then
    if info == true then return end
    oldRecord, button = unpack(info)
    if oldRecord then return end
  else
    info = {}
    itemCooldowns[name] = info
  end
  if oldRecord then return end
  local start, duration, cooldown = GetItemCooldown(name)
  if not start then return end

  if start > 0 and duration > gcd and cooldown then
    info[1] = 0
    self:AddButton("item", name, start, duration, GetItemIcon(name))
    self:Output("Sorting with item ", name)
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
        local icon = select(3, GetSpellInfo(cooldown))
        local fromCooldown = self:OnSpellCooldown(cooldown, icon)
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
      local _, id = GetSpellBookItemInfo(index, "spell")
      if not id then break end
      local spell, _, icon = GetSpellInfo(id)
      spell = GetSpellInfo(spell) or spell
      local fromCooldown = self:OnSpellCooldown(spell, icon)
      if fromCooldown then
        self:Output("Sorted from spell ", spell)
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

--- @overload fun(self: SomeCooldowns, info: CorePath, r: number, g: number, b: number, a?: number): nil
--- @overload fun(self: SomeCooldowns, info: CorePath, val: any): nil
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

--- @param info CorePath
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

  if not GetSpellInfo(val) then
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
--- @param subject string | number
--- @param time number
--- @param duration number
--- @param texture number
function Addon:AddButton(buttonType, subject, time, duration, texture)
  local typeCooldowns = self.cooldowns[buttonType]
  for cooldown, data in pairs(self.core.group) do
    if data.type == "blacklist" and (subject == cooldown
        or (buttonType == "spell" and GetSpellInfo(subject) == cooldown)
        or (buttonType == "item" and GetItemInfo(subject) == GetItemInfo(cooldown))) then
      return
    end
  end
  local somebars = self.core.Extras.somebars and self.lib.somebars
  if somebars then
    local name
    if buttonType == "spell" then
      name = GetSpellInfo(subject)
    elseif buttonType == "item" then
      name = GetItemInfo(subject)
    end
    for _, bar in pairs(somebars.exports) do
      for _, watched in ipairs(bar) do
        if subject == watched or name == watched then
          return
        end
      end
    end
  end
  local button
  local oldInfo = typeCooldowns[subject]
  if oldInfo then
    button = oldInfo[2]
  else
    oldInfo = {}
    typeCooldowns[subject] = oldInfo
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
  typeCooldowns[subject][2] = button
  button.icon:SetTexture(texture)
  local iconSize = self.core.iconSize
  button:SetSize(iconSize, iconSize)
  button:SetAttribute("type", buttonType)
  button:SetAttribute(buttonType, subject)
  button:GetNormalTexture():Hide()
  button.cooldownFrame:SetCooldown(time, duration)
  button.cooldownFrame:SetReverse(self.core.reverse)
  button.expires = time + duration
  button.active = true
  --button:Show()
end

--- @param info CorePath
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
