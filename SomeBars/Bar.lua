local select, setmetatable, type = select, setmetatable, type
local GetItemInfoFromHyperlink, IsSpellKnown = GetItemInfoFromHyperlink, IsSpellKnown
local C_Item, C_Spell, C_SpellBook =
    C_Item, C_Spell, C_SpellBook
local GetItemCount, GetItemIcon, GetItemInfo, GetItemName =
    C_Item.GetItemCount, C_Item.GetItemIconByID, C_Item.GetItemInfo, C_Item.GetItemNameByID
local GetSpellID, GetSpellName, GetSpellTexture =
    C_Spell.GetSpellIDForSpellIdentifier, C_Spell.GetSpellName, C_Spell.GetSpellTexture

--- @type Namespace
local N = select(2, ...)
local getIconColor = N.Niji.GetIconColor
local A = LibStub("Abacus-2.0")
local colPack = A.colPack

--- @alias Visibility "auto" | "show" | "hide"

--- @class Bar
--- @field barAlpha number
--- @field color Color
--- @field id number
--- @field type "item" | "spell"
--- @field combat Visibility
--- @field dim1 number
--- @field dim2 number
--- @field iconAlpha number
--- @field noncombat Visibility
--- @field position number | nil
--- @field reverse boolean
--- @field sparkAlpha number
local Bar = {
  barAlpha = 0.66,
  color = { r = 1, g = 1, b = 1, a = 1 },
  combat = "show",
  dim1 = 150,
  dim2 = 3,
  iconAlpha = 1,
  noncombat = "auto",
  reverse = false,
  sparkAlpha = 1,
}

function Bar:Reset()
  self.barAlpha = nil
  self.combat = nil
  self.dim1 = nil
  self.dim2 = nil
  self.iconAlpha = nil
  self.noncombat = nil
  self.reverse = nil
  self.sparkAlpha = nil
end

--- @return number | nil
function Bar:GetIcon()
  if self.type == "item" then
    return GetItemIcon(self.id)
  else
    return select(1, GetSpellTexture(self.id))
  end
end

--- @return string | nil
function Bar:GetName()
  if self.type == "item" then
    return GetItemName(self.id)
  else
    return GetSpellName(self.id)
  end
end

--- @param inCombat boolean
--- @return Visibility
function Bar:GetVisibility(inCombat)
  if inCombat then
    return self.combat
  else
    return self.noncombat
  end
end

--- @return boolean
function Bar:IsActive()
  if self.type == "item" then
    return GetItemCount(self.id) ~= 0
  else
    return IsSpellKnown(self.id)
  end
end

--- @class BarConstructor
local BarConstructor = { __index = Bar }

--- @param barType "item" | "spell"
--- @param id number | string
--- @param position? number
--- @return Bar
function BarConstructor:New(barType, id, position)
  if barType == "item" then
    local link = select(2, GetItemInfo(id))
    id = link and GetItemInfoFromHyperlink(link) or id
  else
    id = GetSpellID(id)
  end
  local instance = {
    id = id,
    position = position,
    type = barType,
  }
  setmetatable(instance, self)
  local icon = instance:GetIcon()
  instance.color = icon and colPack(getIconColor(icon)) or { r = 0, g = 0, b = 0 }
  return instance
end

--- @param obj Bar
--- @return nil
function BarConstructor:Init(obj)
  setmetatable(obj, self)
end

N.Bar = BarConstructor
