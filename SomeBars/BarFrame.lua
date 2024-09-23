local min, select, getmetatable, pairs, setmetatable = min, select, getmetatable, pairs, setmetatable
local CreateFrame, GetTime, IsSpellKnown, UIParent = CreateFrame, GetTime, IsSpellKnown, UIParent
local C_Item, C_Spell = C_Item, C_Spell
local GetItemCooldown = C_Item.GetItemCooldown
local GetSpellCharges, GetSpellCooldown = C_Spell.GetSpellCharges, C_Spell.GetSpellCooldown

--- @type Namespace
local N = select(2, ...)
local A = LibStub("Abacus-2.0")
local D = LibStub("DoomCore-2.1")
local colUnpack = A.colUnpack
local borders, convertDims, growAnchors, orientGrowth = D.borders, D.convertDims, D.growAnchors, D.orientGrowth

--- @class TexturedFrame: Frame
--- @field tex Texture

---@param FrameType FrameType
---@param name? string
---@param parent? any
---@return TexturedFrame
local function CreateTexturedFrame(FrameType, name, parent)
  local frame = CreateFrame(FrameType, name, parent)
  local tex = frame:CreateTexture(name and (name .. ".tex"))
  tex:SetAllPoints(frame)
  frame.tex = tex
  return frame
end

--- @class BarFrame: DoomFrame
--- @field anchor FramePoint
--- @field appear AlphaAnimation
--- @field appearGroup AnimationGroup
--- @field bars { [number]: Bar }
--- @field bg Texture
--- @field border { ["TOP" | "BOTTOM" | "LEFT" | "RIGHT"]: Texture }
--- @field button Button
--- @field charges number
--- @field dimX number
--- @field dimY number
--- @field duration number | nil
--- @field fade AlphaAnimation
--- @field fadeGroup AnimationGroup
--- @field fg Texture
--- @field Goals TexturedFrame[]
--- @field group BarGroup
--- @field icon Texture
--- @field lastActive Bar | nil
--- @field maxCharges number
--- @field Spark TexturedFrame
--- @field start number | nil
--- @field iconPos "after" | "before" | "hide" | nil
--- @field empty boolean
local BarFrame = {}
setmetatable(BarFrame, getmetatable(UIParent))

--- @param visible boolean
--- @return nil
function BarFrame:SetVisible(visible)
  if visible == self:IsShown() then
    return
  end
  if visible then
    self.appearGroup:Play()
  else
    self.fadeGroup:Play()
  end
end

--- @return nil
function BarFrame:Update()
  local start, spark = self.start, self.Spark
  if start and spark and spark:IsVisible() then
    local progress = min(1, ((self.charges or 0) + (GetTime() - start) / self.duration) / (self.maxCharges or 1))
    local anchor = self.anchor
    spark:SetPoint(anchor, self, anchor, progress * self.dimX, progress * self.dimY)
  end
end

--- @param type "item"|"spell"
--- @param id number
--- @return number start
--- @return number duration
--- @return boolean enabled
--- @return number? charges
--- @return number? maxCharges
local function getCooldown(type, id)
  if type == "item" then
    return GetItemCooldown(id)
  end
  local chargeInfo = GetSpellCharges(id)
  if chargeInfo then
    return chargeInfo.cooldownStartTime, chargeInfo.cooldownDuration, true, chargeInfo.currentCharges,
        chargeInfo.maxCharges
  end
  local cooldownInfo = GetSpellCooldown(id)
  if cooldownInfo then
    return cooldownInfo.startTime, cooldownInfo.duration, cooldownInfo.isEnabled
  end
  return 0, 0, false
end

--- @param gcd number
--- @param dim1 number
--- @param dim2 number
--- @param bar Bar
--- @return boolean | nil
function BarFrame:CheckCooldown(gcd, dim1, dim2, bar)
  local bar_color, bar_id, bar_reverse, bar_type, sparkAlpha = bar.color, bar.id, bar.reverse, bar.type, bar.sparkAlpha
  local start, duration, enabled, charges, maxCharges = getCooldown(bar_type, bar_id)
  if not enabled then
    return
  end
  if charges == nil then
    charges = tonumber(not duration) --[[@as number]]
  end
  if maxCharges == nil then
    maxCharges = 1 --[[@as number]]
  end
  local bg, fg, goals, group, spark = self.bg, self.fg, self.Goals, self.group, self.Spark
  local grow, orientation = group.grow, group.orientation
  local growth = orientGrowth[orientation][bar_reverse]
  local anchors = growAnchors[growth]
  local border = borders[growth]
  local minDim = min(dim1, dim2)
  local r, g, b = colUnpack(bar_color)
  local growAnchor = growAnchors[grow]
  local reverse = growAnchor[3] + growAnchor[4]
  if bar_reverse then
    reverse = -1 * reverse
  end

  local onCooldown = charges ~= maxCharges and (duration > 1.5 or (not gcd and duration > 0))

  if not onCooldown then
  elseif maxCharges == 1 then
    if not self.empty then
      self.empty = true
      fg:Hide()
      bg:Show()
      for _, goal in pairs(goals) do
        goal:Hide()
      end
    end
  elseif charges ~= self.charges or maxCharges ~= self.maxCharges or bar ~= self.lastActive then
    self.empty = false
    for i = 1, charges do
      if goals[i] then
        goals[i]:Hide()
      end
    end
    for i = charges + 1, maxCharges - 1 do
      local goal = goals[i]
      if not goal then
        goal = CreateTexturedFrame("Frame", self:GetName() .. ".Goals[" .. i .. "]", self)
        goal:SetFrameStrata("MEDIUM")
        goal:SetFrameLevel(101)
        goals[i] = goal
      end
      goal:SetSize(minDim, minDim)
      goal.tex:SetColorTexture(r, g, b, sparkAlpha)
      local offsetX, offsetY = convertDims(orientation, dim1 * i / maxCharges, 0)
      goal:SetPoint(anchors[1], self, anchors[1], offsetX, offsetY)
      goal:Show()
    end
    for i = maxCharges, #goals do goals[i]:Hide() end
    if charges > 0 then
      fg:ClearAllPoints()
      fg:SetPoint(border[1][1], self, border[1][1])
      fg:SetPoint(border[2][1], self, border[2][1])
      fg:SetSize(convertDims(orientation, dim1 * charges / maxCharges, dim2))
      bg:Show()
      fg:Show()
    else
      fg:Hide()
      bg:Show()
    end
  end
  self.charges = charges
  self.maxCharges = maxCharges
  self.start = start
  self.duration = duration
  self.anchor = anchors[1]
  self.dimX, self.dimY = convertDims(orientation, reverse * dim1 - minDim, 0)

  spark:Show()
  self:SetActiveBar(bar)
  return onCooldown
end

--- @param gcd number
--- @param inCombat boolean
--- @return nil
function BarFrame:CheckCooldowns(gcd, inCombat)
  local dim1, dim2 = convertDims(self.group.orientation, self:GetWidth(), self:GetHeight())
  --- @type Bar | nil
  local activeBar
  local lastBar = self.lastActive
  if lastBar then
    local lastDisplay = lastBar:GetVisibility(inCombat)
    if lastDisplay ~= "hide" then
      local onCooldown = self:CheckCooldown(gcd, dim1, dim2, lastBar)
      if onCooldown then
        self:SetVisible(true)
        return
      end
      if onCooldown == false and lastDisplay == "show" then
        activeBar = lastBar
      end
    end
  end

  for _, bar in pairs(self.bars) do
    local visibility = bar:GetVisibility(inCombat)
    if visibility ~= "hide" then
      local onCooldown = self:CheckCooldown(gcd, dim1, dim2, bar)
      if onCooldown then
        self:SetVisible(true)
        return
      end
      if onCooldown == false and visibility == "show" then
        activeBar = bar
        self:SetActiveBar(bar)
      end
    end
  end

  self.empty = false

  if not activeBar then
    self:SetVisible(false)
    return
  end

  local bg, fg, goals, spark = self.bg, self.fg, self.Goals, self.Spark

  if not fg:IsShown() or spark:IsShown() then
    fg:SetAllPoints(self)
    for _, goal in pairs(goals) do
      goal:Hide()
    end
    fg:Show()
    bg:Hide()
    fg:SetWidth(self:GetWidth())
    spark:Hide()
  end

  self:SetVisible(true)
end

--- @param bar Bar
--- @return nil
function BarFrame:SetActiveBar(bar)
  if self.lastActive == bar then
    return
  end
  self.lastActive = bar

  local button, fg, group, icon, spark = self.button, self.fg, self.group, self.icon, self.Spark

  local iconTexture = bar:GetIcon()
  if iconTexture then
    icon:SetTexture(iconTexture)
    icon:Show()
  else
    icon:Hide()
  end
  local color = bar.color
  local r, g, b = color.r, color.g, color.b
  local barAlpha, iconAlpha, sparkAlpha = bar.barAlpha, bar.iconAlpha, bar.sparkAlpha
  local iconPos, iconSpacing = group.iconPos, group.iconSpacing
  fg:SetColorTexture(r, g, b, barAlpha)
  button:SetAlpha(iconAlpha or 1)
  spark.tex:SetColorTexture(r, g, b, sparkAlpha)

  if iconPos == self.iconPos and (iconPos == "hide" or button:IsShown()) then
    return
  end
  local growth = orientGrowth[group.orientation][bar.reverse]
  local anchors = growAnchors[growth]
  if iconPos == "before" then
    button:Show()
    button:SetPoint(anchors[2], self, anchors[1], -iconSpacing * anchors[3], iconSpacing * anchors[4])
  elseif iconPos == "after" then
    button:Show()
    button:SetPoint(anchors[1], self, anchors[2], iconSpacing * anchors[3], iconSpacing * anchors[4])
  else
    button:Hide()
  end
  self.iconPos = iconPos
end

--- @class BarFrameConstructor
local BarFrameConstructor = { __index = BarFrame }

--- @param name string
--- @param parent? Region
--- @return BarFrame
function BarFrameConstructor:Create(name, parent)
  local frame = CreateFrame("Frame", name, parent) --[[@as BarFrame]]
  local frame_border = {}
  for borderName, border in pairs(borders) do
    frame_border[borderName] = frame:CreateTexture(name .. ".Border." .. borderName, "BACKGROUND")
    local b = frame_border[borderName]
    b:SetSize(1, 1)
    b:SetPoint(border[1][1], frame, border[1][2], border[1][3], border[1][4])
    b:SetPoint(border[2][1], frame, border[2][2], border[2][3], border[2][4])
  end
  frame.border = frame_border

  frame.fg = frame:CreateTexture()
  frame.fg:SetDrawLayer("BORDER")
  frame.fg:SetAllPoints(frame)
  frame.bg = frame:CreateTexture()
  frame.bg:SetDrawLayer("BACKGROUND")
  frame.bg:SetAllPoints(frame)
  frame.bg:Hide()

  frame.button = CreateFrame("Button", frame:GetName() .. "Button", frame)
  frame.button:SetFrameStrata("HIGH")
  frame.button:EnableMouse(false)
  frame.button:Disable()
  frame.Goals = {}
  local spark = CreateTexturedFrame("Frame", frame:GetName() .. ".Spark", frame)
  frame.Spark = spark
  spark:SetFrameStrata("MEDIUM")
  frame.icon = frame.button:CreateTexture()
  frame.icon:SetAllPoints(frame.button)

  frame.appearGroup = frame:CreateAnimationGroup()
  frame.appear = frame.appearGroup:CreateAnimation("Alpha") --[[@as AlphaAnimation]]
  frame.appear:SetDuration(0.15)
  frame.appear:SetFromAlpha(0)
  frame.appear:SetToAlpha(1)
  frame.appearGroup:SetScript("OnPlay", function()
    frame.fadeGroup:Stop()
    frame:Show()
  end)

  frame.fadeGroup = frame:CreateAnimationGroup()
  frame.fade = frame.fadeGroup:CreateAnimation("Alpha") --[[@as AlphaAnimation]]
  frame.fade:SetDuration(0.075)
  frame.fade:SetFromAlpha(1)
  frame.fade:SetToAlpha(0)
  frame.fadeGroup:SetScript("OnPlay", function()
    frame.appearGroup:Stop()
  end)
  frame.fadeGroup:SetScript("OnFinished", function()
    frame:Hide()
  end)
  setmetatable(frame, self)
  return frame
end

N.BarFrame = BarFrameConstructor
