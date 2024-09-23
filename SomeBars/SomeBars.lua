--- @meta

--- @type string, Namespace
local shortName, N = ...
----------------
-- File globals
----------------

local Bar, BarGroup, BarGroupFrame = N.Bar, N.BarGroup, N.BarGroupFrame
local A = LibStub("Abacus-2.0")
local D = LibStub("DoomCore-2.1")

--- @class SomeBars: Handler
--- @field core SomeBarsCore
--- @field settings SomeBarsSettings
--- @field exports { item: { [number]: true }, spell: { [number]: true } }
local Addon = D.Addon(shortName, "Some Bars", N)
Addon.version = 2

local InCombatLockdown, UIParent, UnitControllingVehicle = InCombatLockdown, UIParent, UnitControllingVehicle
local pairs, select = pairs, select
local assertType, TypeCode = A.assertType, A.TypeCode
local type_string, type_table = TypeCode.String, TypeCode.Table
local C_Item, C_Spell = C_Item, C_Spell
local GetItemInfo = C_Item.GetItemInfo
local GetSpellCooldown, GetSpellID, GetSpellName = C_Spell.GetSpellCooldown, C_Spell.GetSpellIDForSpellIdentifier,
    C_Spell.GetSpellName

--- @type table<string, BarGroupFrame>
local frames = {}

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
  local core = self.core
  local groups = core.groups
  if groups == nil then
    groups = {}
    core.groups = groups
  end
  for groupName, group in pairs(groups) do
    BarGroup:Init(group)
    self:BuildGroup(groupName)
  end
  self:UpdateExports()
end

--- @param version number
--- @return boolean
function Addon:Migrate(version)
  if version < 1.0 then
    return true
  end
  local core = self.core --[[@as any]]
  if version < 1.85 then
    local groups = {}
    core.groups = groups
    for groupName, oldGroup in pairs(core.Groups) do
      local group = BarGroup:New()
      local bars = group.bars
      for key, val in pairs(oldGroup) do
        if key == "Default" then
          local default = group.__index
          for defaultKey, defaultVal in pairs(val) do
            default[defaultKey] = defaultVal
          end
        elseif key == "bars" then
          for barName, oldBar in pairs(val) do
            if barName then
              local type
              if GetItemInfo(barName) then
                type = "item"
              else
                type = "spell"
              end
              local bar = Bar:New(type, barName, oldBar.position)
              if bar.id then
                bar.color = oldBar.newColor
                bar.position = oldBar.position
                bars[barName] = bar
              end
            end
          end
        elseif key ~= "add" then
          group[key] = val
        end
      end
      groups[groupName] = group
    end
  end
  if version < 2 then
    for _, group in pairs(core.groups) do
      for _, bar in pairs(group.bars) do
        local spellName = GetSpellName(bar.id)
        if spellName then
          bar.id = GetSpellID(spellName) or bar.id
        end
      end
    end
  end
  return false
end

----------------
-- Bar handling
----------------

--- @overload fun(self: self, info: BarsCorePath, r: number, g: number, b: number, a: number): nil
--- @overload fun(self: self, info: BarsCorePath, r: number, g: number, b: number): nil
--- @overload fun(self: self, info: BarsCorePath, val: any): nil
function Addon:Rebuild(info, r, g, b, a)
  if info then
    self:ConfSet(info, r, g, b, a)
  end
  self:BuildGroup(info[1])
end

--- @param info BarsCorePath
--- @param name string
--- @return nil
function Addon:AddGroup(info, name)
  assertType(info, type_table, name, type_string)
  self.core.groups[name] = BarGroup:New()
  self:BuildGroup(name)
end

--- @param info BarsCorePath
--- @param name string
--- @return nil
function Addon:RenameGroup(info, name)
  assertType(info, type_table, name, type_string)
  local groups = self.core.groups
  if groups[name] then
    return
  end
  local old = info[1]
  groups[name] = groups[old]
  groups[old] = nil

  local settings = self.settings.options
  settings[name] = settings[old]
  settings[old] = nil
  frames[name] = frames[old]
  frames[old] = nil
  self:BuildGroup(name)
end

--- @param info BarsCorePath
--- @return nil
function Addon:DeleteGroup(info)
  assertType(info, type_table)
  local group = info[1]
  self.core[group] = nil
  self.settings.options.args[group] = nil
end

function Addon:UpdateExports()
  --- @type { item: { [number]: true }, spell: { [number]: true } }
  local exports = { item = {}, spell = {} }
  for _, group in pairs(self.core.groups) do
    for _, bar in pairs(group.bars) do
      exports[bar.type][bar.id] = true
    end
  end
  self.exports = exports
end

----------
-- Frames
----------

--- @param groupName string
--- @return nil
function Addon:BuildGroup(groupName)
  assertType(groupName, type_string)
  local group = self.core.groups[groupName]
  local frame = self:BuildGroupFrame(groupName, group)
  self.settings:BuildGroupSettings(groupName, group, frame)
end

--- @param name string
--- @param group BarGroup
--- @return BarGroupFrame
function Addon:BuildGroupFrame(name, group)
  local frame = frames[name]
  if not group then
    if frame then
      frames[name]:Hide()
    end
    return frame
  end
  assertType(name, type_string, group, type_table)
  if not frame then
    frame = BarGroupFrame:Create("SomeBars_" .. name, UIParent)
    frames[name] = frame
    local msq = self.lib.masque
    if msq then
      frame.msq = msq:Group(self.name, name)
    end
  end
  self:Draggable(frame, group)
  frame:Build(group)
  self:Queue("Update")
  return frame
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
  local disable = UnitControllingVehicle("player") -- or UnitInVehicle("player")
  local inCombat = InCombatLockdown()
  local gcd = GetSpellCooldown(61304).duration
  for _, frame in pairs(frames) do
    for _, slot in pairs(frame.slots) do
      if disable then
        slot:Hide()
      else
        slot:CheckCooldowns(gcd, inCombat)
      end
    end
  end
end
