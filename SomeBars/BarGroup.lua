local pairs, select, setmetatable = pairs, select, setmetatable

--- @type Namespace
local N = select(2, ...)
local Bar = N.Bar

local D = LibStub("DoomCore-2.1")
local confGet, confSet, convertDims = D.confGet, D.confSet, D.convertDims
local opt, orderNum = D.opt, D.orderNum

--- @class BarGroup: FrameSettings
--- @field addType "item" | "spell"
--- @field bars { [string]: Bar }
--- @field barBackgroundColor Color
--- @field barBorderColor Color
--- @field dim1 number
--- @field dim2 number
--- @field flexible boolean
--- @field iconPos "hide" | "before" | "after"
--- @field iconSize number
--- @field orientation "HORIZONTAL" | "VERTICAL"
--- @field __index Bar
local BarGroup = {
  anchor = "TOP",
  barBackgroundColor = { r = 0, g = 0, b = 0, a = 0.4 },
  barBorderColor = { r = 0, g = 0, b = 0, a = 0 },
  dim1 = 1395,
  dim2 = 3,
  flexible = false,
  grow = "RIGHT",
  iconPos = "after",
  iconSize = 22,
  iconSpacing = 0,
  lock = true,
  offsetX = 0,
  offsetY = -50,
  orientation = "HORIZONTAL",
  spacing = 25,
}

function BarGroup:GetSize()
  local size = 0
  for _, bar in pairs(self.bars) do
    local position = bar.position
    if position and position > size then
      size = position
    end
  end
  return size
end

--- @param barName string
--- @return Bar
function BarGroup:CreateBar(barName)
  local position = self:GetSize()
  local type = self.addType
  local bar = Bar:New(type, barName, position)
  setmetatable(bar, self)
  self.bars[barName] = bar
  return bar
end

--- @class BarGroupConstructor
local BarGroupConstructor = { __index = BarGroup }

--- @return BarGroup
function BarGroupConstructor:New()
  local instance = {
    addType = "spell",
    bars = {},
    __index = Bar:New("spell", 0),
  }
  setmetatable(instance, self)
  return instance
end

--- @param obj BarGroup
--- @return nil
function BarGroupConstructor:Init(obj)
  setmetatable(obj, self)
  Bar:Init(obj.__index)
  for _, bar in pairs(obj.bars) do
    Bar:Init(bar)
    setmetatable(bar, obj)
  end
end

N.BarGroup = BarGroupConstructor

-----------
-- Settings
-----------

--- @generic T
--- @param from T
--- @param to T
local function copyFrom(from, to)
  for k, v in pairs(from) do
    to[k] = v
  end
end

local visibilityOptions = {
  auto = "On cooldown",
  show = "Always",
  hide = "Never",
}

local baseBarSettings = opt(999, "group", "Bar", {
  args = {
    { "color" },
    { "reverse",    "toggle",  "Reverse direction" },
    { "space" },
    { "combat",     "select",  "Show in combat",     { values = visibilityOptions } },
    { "noncombat",  "select",  "Show out of combat", { values = visibilityOptions } },
    { "space" },
    { "iconAlpha",  "percent", "Icon visibility" },
    { "barAlpha",   "percent", "Bar visibility" },
    { "sparkAlpha", "percent", "Spark visibility" },
    { "space" }
  }
}).args

local baseDefaultBarSettings = {
  reverse = baseBarSettings.reverse,
  spaceBeforeVisibility = baseBarSettings.spaceBeforeVisibility,
  combat = baseBarSettings.combat,
  noncombat = baseBarSettings.noncombat,
  spaceBeforeAlpha = baseBarSettings.spaceBeforeAlpha,
  iconAlpha = baseBarSettings.iconAlpha,
  barAlpha = baseBarSettings.barAlpha,
  sparkAlpha = baseBarSettings.sparkAlpha,
  spaceBeforeDims = baseBarSettings.spaceBeforeDims,
}

local baseGroupSettings = opt(2, "group", "Group", {
  args = {
    { "iconPos", "select", "Icon display", {
      width = "half",
      values = { "hide", "before", "after" }
    } },
    { "space" },
    { "iconSize" },
    { "iconSpacing" },
    { "space" },
    { "grow" },
    { "orientation", "orientation", "Bar orientation" },
    { "spacing", "range", "Bar spacing", {
      min = -10,
      max = 1000,
      softMin = 0,
      softMax = 100,
      step = 1,
    } },
    { "space" },
    { "space",              { order = 20 } },
    { "anchor" },
    { "lock",               "toggle",      "Lock" },
    { "space" },
    { "offsetX" },
    { "offsetY" },
    { "space" },
    { "barBackgroundColor", "aColor",      "Background" },
    { "barBorderColor",     "aColor",      "Border" },
    { "add", "group", "Add to group", {
      args = {
        { "addType", "select", "Type", {
          values = { "spell", "item" },
          width = "half"
        } },
        { "barName", "input", "Add to group", {
          set = function(info, val)
            (info.handler --[[@as BarGroup]]):CreateBar(val)
          end
        } }
      }
    } }
  }
}).args

----------------
-- Configuration
----------------

--- @param frame BarGroupFrame
--- @return table
function BarGroup:BuildSettings(frame)
  local args = {}

  local dimOption = {
    type = "range",
    name = function(info)
      local dim1, dim2 = select(1, convertDims(self.orientation, "Width", "Height"))
      return info[#info - 1] == "dim1" and dim1 or dim2
    end,
    step = 0.5,
    min = 1,
    max = 1000,
    softMin = 50,
    softMax = 500,
    disabled = function() return self.flexible end,
    order = function(info) return info[#info - 1] == "dim1" and 1010 or 1011 end,
  }

  local positionOption

  local function recalculateSize()
    local size = self:GetSize()
    positionOption.max = size
    positionOption.hidden = size < 2
  end

  positionOption = {
    type = "range",
    name = "Position",
    step = 1,
    min = 1,
    width = "full",
    order = 2,
    set = function(info, position)
      confSet(info, position)
      recalculateSize()
      frame:Build(self)
    end
  }

  recalculateSize()

  for barName, bar in pairs(self.bars) do
    local barArgs = {
      position = positionOption,
      dim1 = dimOption,
      dim2 = dimOption,
    }
    copyFrom(baseBarSettings, barArgs)

    args[barName] = {
      type = "group",
      name = bar:GetName() or barName,
      icon = bar:GetIcon(),
      handler = bar,
      args = barArgs,
      order = bar.position,
    }
  end
  local defaultBarArgs = {
    dim1 = dimOption,
    dim2 = dimOption,
    reset = {
      type = "execute",
      name = "Reset all bars to default",
      func = function()
        for _, bar in pairs(self.bars) do
          bar:Reset()
        end
      end,
      width = "full",
      order = 0
    }
  }
  copyFrom(baseDefaultBarSettings, defaultBarArgs)
  args.default = {
    type = "group",
    handler = self.__index,
    name = "Default",
    inline = true,
    args = defaultBarArgs,
    order = 2000,
  }
  copyFrom(baseGroupSettings, args)

  local settings = {
    type = "group",
    name = function(info) return info[#info - 1] end,
    handler = self,
    get = confGet,
    set = function(...)
      confSet(...)
      frame:Build(self)
    end,
    args = args,
  }
  return settings
end
