local getmetatable, min, pairs, select, setmetatable, tinsert = getmetatable, min, pairs, select, setmetatable, tinsert
local CreateFrame, InCombatLockdown, UIParent = CreateFrame, InCombatLockdown,
    UIParent

--- @type Namespace
local N = select(2, ...)
local BarFrame = N.BarFrame
local A = LibStub("Abacus-2.0")
local D = LibStub("DoomCore-2.1")

local flip, nilSort = A.flip, A.nilSort
local borders, convertDims, direction, growAnchors, orientGrowth, updateFrame, HORIZONTAL = D.borders, D.convertDims,
    D.direction, D.growAnchors, D.orientGrowth, D.updateFrame, D.HORIZONTAL

local C_Spell = C_Spell
local GetSpellCooldown = C_Spell.GetSpellCooldown

--- @class BarGroupFrame: DoomFrame
--- @field button Button
--- @field tex Texture
--- @field slots BarFrame[]
--- @field conf BarGroup
--- @field msq MasqueGroup | nil
local BarGroupFrame = {}
setmetatable(BarGroupFrame, getmetatable(UIParent))

function BarGroupFrame:Update()
  for _, slot in pairs(self.slots) do
    slot:Update()
  end
end

--- @param group BarGroup
function BarGroupFrame:Build(group)
  self.conf = group
  self:ClearAllPoints()

  local bg, border, iconSize, iconPos, orientation, spacing, grow, offsetX, offsetY = group.barBackgroundColor,
      group.barBorderColor or {}, group.iconSize, group.iconPos, group.orientation, group.spacing, group.grow,
      group.offsetX, group.offsetY
  local bg_r, bg_g, bg_b, bg_a = bg.r, bg.g, bg.b, bg.a
  local border_r, border_g, border_b, border_a = border.r, border.g, border.b, border.a

  local frame_slots = self.slots

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

  --- @type Bar[]
  local bars = {}
  for _, bar in pairs(group.bars) do
    tinsert(bars, bar)
  end
  nilSort(bars, function(bar) return bar.position end)

  --- @type Bar[][]
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
      local barSlot = barSlots[slotI]
      if not barSlot then
        barSlot = {}
        barSlots[slotI] = barSlot
      end
      tinsert(barSlot, bar)
    end
  end

  local combat = InCombatLockdown()
  local name = self:GetName()
  local msq = self.msq
  local maxSlot = 0
  local gcd = GetSpellCooldown(61304).duration

  for i, barList in pairs(barSlots) do
    maxSlot = i
    local slot = frame_slots[i]
    if not slot then
      slot = BarFrame:Create(name .. "_" .. i, self)
      slot:SetFrameStrata("LOW")
      frame_slots[i] = slot
      slot.group = group

      if msq then
        msq:AddButton(slot.button, { Icon = slot.icon })
      end
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
      slot:SetPoint(anchors[1], self, anchors[1])
    else
      slot:SetPoint(anchors[1], frame_slots[i - 1], anchors[2], xSpace, ySpace)
    end
    slot.lastActive = nil
    slot.bars = barList

    slot:CheckCooldowns(gcd, combat)
  end
  for i = maxSlot + 1, #frame_slots do
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
    self:SetSize(convertDims(grow, frameDim1, frameDim2))
  else
    self:SetSize(convertDims(orientation, group.dim1 - iconSpacing / 2, group.dim2))
    local spacing1, spacing2 = flip(not linear, iconSpacing / 2 + (spacing + iconSpacing) * (maxSlot - 1), 0)

    local barDim1 = (group.dim1 - spacing1) / maxSlot
    local barDim2 = (group.dim2 - spacing2)
    for i = 1, maxSlot do
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
  end
  if direction[orientation] == HORIZONTAL then
    offsetX = offsetX - iconSpacing / 4
  else
    offsetY = offsetY - iconSpacing / 4
  end

  self:Update()
  if msq then
    msq:ReSkin()
  end
  updateFrame(self)
  self:Show()
end

--- @class BarGroupFrameConstructor
local BarGroupFrameConstructor = { __index = BarGroupFrame }

--- @param name string
--- @param parent? Region
--- @return BarGroupFrame
function BarGroupFrameConstructor:Create(name, parent)
  local frame = CreateFrame("Frame", name, parent) --[[@as BarGroupFrame]]
  frame:SetScript("OnUpdate", BarGroupFrame.Update)
  frame.tex = frame:CreateTexture(frame:GetName() .. ".tex", "BORDER")
  frame.tex:SetAllPoints(frame)
  frame.tex:SetColorTexture(0, 1, 0, 0.5)
  frame.slots = {}
  setmetatable(frame, self)
  return frame
end

N.BarGroupFrame = BarGroupFrameConstructor
