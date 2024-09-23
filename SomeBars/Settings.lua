﻿local _, N = ...
--- @class SomeBarsSettings: HandlerSettings
local Settings = {}
N.Settings = Settings

local A = LibStub("Abacus-2.0")
local D = LibStub("DoomCore-2.1")

local GetSpellInfo, next, select, tconcat, tinsert, tostring, type, UIParent, UnitRace = GetSpellInfo, next, select,
tconcat, tinsert, tostring, type, UIParent, UnitRace
local tappend, convertDims, orderNum, opt, subInfo = A.tappend, D.convertDims, A.orderNum, D.opt, D.subInfo

------------
-- Defaults
------------

local defaults = {}
defaults.db = {
  profile = {}
}
defaults.options = opt("parent", {
  name = "Groups",
  args = {
    { "add", "input", "Add group", {
      set = "AddGroup",
      width = "full"
    } }
  }
})
--- @type BarGroup
defaults.group = {
  add = { barType = "spell" },
  anchor = "TOP",
  barBackgroundColor = { r = 0, g = 0, b = 0, a = 0.4 },
  barBorderColor = { r = 0, g = 0, b = 0, a = 0 },
  dim1 = 1395,
  dim2 = 3,
  flexible = false,
  grow = "RIGHT",
  iconPos = "after",
  iconSize = 22,
  iconSpacing = -2,
  lock = true,
  offsetX = 0,
  offsetY = -50,
  orientation = "HORIZONTAL",
  spacing = 25,
}
--- @type Bar
defaults.bar = {
  barAlpha = 0.66,
  combat = "show",
  dim1 = 150,
  dim2 = 3,
  iconAlpha = 1,
  newColor = { r = 1, g = 1, b = 1, a = 1 },
  noncombat = "auto",
  reverse = false,
  sparkAlpha = 1,
}

Settings.defaults = defaults

Settings.fromItem = {}
Settings.fromOther = {}
Settings.fromSpellbook = {}
Settings.fromPvp = {}


-----------------
-- Settings page
-----------------

--- @param groupName string
--- @param group BarGroup
--- @return nil
function Settings:BuildGroupSettings(groupName, group)
  local width = floor(UIParent:GetWidth())
  local height = floor(UIParent:GetHeight())
  local dim1, dim2 = convertDims(group.grow, width, height)
  local name = groupName
  local opts = opt(100 + orderNum(name), "group", name, {
    set = "Rebuild",
    args = {
      { "bars",        "parent" },
      { "rename", "input", {
        get = "GetParentName",
        set = "RenameGroup",
        width = "full"
      } },
      { "iconPos", "select", "Icon display", {
        width = "half",
        values = { "hide", "before", "after" }
      } },
      { "space" },
      { "iconSize" },
      { "iconSpacing" },
      { "space" },
      { "grow" },
      { "orientation", nil,     "Bar orientation" },
      { "spacing", "range", "Bar spacing", {
        min = -10,
        max = 1000,
        softMin = 0,
        softMax = 100,
        step = 1,
        order = 20
      } },
      { "space" },
      { "flexible", "toggle", "Flexible size" },
      { "space" },
      { "dim1", "range", {
        name = function(info)
          return convertDims(info.handler:Get(tappend(subInfo(info, 1, -2), "orientation")), "Width", "Height")
        end,
        min = 1,
        max = dim1,
        softMin = 10,
        softMax = dim1,
        step = 1,
        disabled = ({ "^1", "flexible" })
      } },
      { "dim2", "range", {
        name = function(info)
          return convertDims(info.handler:Get(tappend(subInfo(info, 1, -2), "orientation")), "Height", "Width")
        end,
        min = 1,
        max = dim2,
        softMin = 10,
        softMax = dim2,
        step = 1,
        disabled = ({ "^1", "flexible" })
      } },
      { "space" },
      { "anchor" },
      { "lock",               { width = "half" } },
      { "space" },
      { "offsetX" },
      { "offsetY" },
      { "space" },
      { "barBackgroundColor", "aColor",          "Background" },
      { "barBorderColor",     "aColor",          "Border" },
      { "delete", "execute", {
        func = "DeleteGroup"
      } },
      { "add", "group", "Add to group", {
        args = {
          { "barType", "select", "Type", {
            values = { "spell", "item" }
          } },
          { "barName", "input", {
            name = function(info)
              return "New " .. (info.handler:Get(tappend(subInfo(info, 1, -2), "barType")) or "spell")
            end,
            set = "AddBar"
          } }
        }
      } }
    }
  })
  self.crawler:Set({ groupName }, opts)
  self:BuildBarSettings(groupName, nil, group.Default)
  for barName, bar in pairs(group.bars) do
    self:BuildBarSettings(groupName, barName, bar)
  end
end

--- @param groupName string
--- @param barName string | nil
--- @param bar Bar
function Settings:BuildBarSettings(groupName, barName, bar)
  bar.newColor = barName and bar.watch[barName].color
  --- @type CorePath
  local tableKey
  if barName == nil then
    tableKey = { groupName, "args", "Default" }
  else
    tableKey = { groupName, "args", "bars", "args", barName }
  end
  local barSettings = opt(nil, "group", barName or "Default", {
    set = "Rebuild",
    order = function() return bar.position end,
    icon = barName and function() return select(3, GetSpellInfo(barName)) end,
    args = {
      { "position", "range", {
        step = 1,
        min = 1,
        max = N.Handler:BarCount(groupName),
        width = "full",
        hidden = function(info) return info.handler:BarCount(groupName) < 2 end
      } },
      { "watch", "input", "Add", {
        set = "Watch"
      } },
      { "newColor", "aColor", "" },
      { "space" },
      { "reverse", "toggle", "Reverse direction", {
        order = 100
      } },
      { "space", {
        order = 101
      } },
      { "combat", "select", "Show in combat", {
        values = {
          auto = "On cooldown",
          show = "Always",
          hide = "Never"
        },
        order = 102
      } },
      { "noncombat", "select", "Show out of combat", {
        values = {
          auto = "On cooldown",
          show = "Always",
          hide = "Never"
        },
        order = 103
      } },
      { "space", {
        order = 104
      } },
      { "iconAlpha", "percent", "Icon visibility", {
        order = 105
      } },
      { "barAlpha", "percent", "Bar visibility", {
        order = 106
      } },
      { "sparkAlpha", "percent", "Spark visibility", {
        order = 107
      } },
      { "space", {
        order = 108
      } },
      { "dim1", "range", {
        name = function(info)
          return convertDims(info.handler:Get(tappend(subInfo(info, 1, -2), "orientation")), "Width", "Height")
        end,
        step = 0.5,
        min = 1,
        max = 1000,
        softMin = 50,
        softMax = 500,
        disabled = ({ false, "^2", "flexible" }),
        order = 109
      } },
      { "dim2", "range", {
        name = function(info)
          return convertDims(info.handler:Get(tappend(subInfo(info, 1, -2), "orientation")), "Height", "Width")
        end,
        min = 1,
        max = 1000,
        step = 0.5,
        softMin = 50,
        softMax = 500,
        disabled = ({ false, "^2", "flexible" }),
        order = 110,
      } },
      { "delete", "execute", "Delete", {
        func = "DeleteBar",
        order = 111
      } }
    }
  })
  local i = 11
  for watch in pairs(bar.watch or {}) do
    local order = watch == barName and 10 or i
    barSettings.args[watch .. "color"] = {
      type = "color",
      hasAlpha = true,
      get = "ConfGetWatchColor",
      set = "ConfSetWatchColor",
      name = watch,
      order = order
    }
    if watch ~= barName then
      barSettings.args[watch .. "delete"] = {
        type = "execute",
        name = "x",
        width = "half",
        func = function(info)
          barSettings.args[watch .. "color"] = nil
          barSettings.args[watch .. "delete"] = nil
          info.handler:Unwatch(info, watch)
        end,
        order = order + 1
      }
    end
    barSettings.args[watch .. "space"] = {
      type = "description",
      name = "",
      width = "full",
      order = order + 2
    }
    i = i + 3
  end
  if barName == nil then
    barSettings.inline = true
    barSettings.order = 100
    barSettings.args.reset = {
      type = "execute",
      name = "Reset all bars to default",
      func = "ResetGroup",
      width = "full",
      order = 0
    }
    barSettings.args.color = nil
    barSettings.args.position = nil
    barSettings.args.newColor = nil
    barSettings.args.watch = nil
    barSettings.args.delete = nil
  end
  self.crawler:Set(tableKey, barSettings)
end

---------------
-- Debug panel
---------------


Settings.debug = {}
