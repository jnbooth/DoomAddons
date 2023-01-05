local _, N = ...
--- @class SomeBarsSettings: HandlerSettings
local Settings = {}
N.Settings = Settings

local A = LibStub("Abacus-2.0")
local D = LibStub("DoomCore-2.1")

local GetSpellInfo, next, select, tconcat, tinsert, tostring, type, UIParent, UnitRace = GetSpellInfo, next, select,
    tconcat, tinsert, tostring, type, UIParent, UnitRace
local sublist, tappend, convertDims, orderNum, opt = A.sublist, A.tappend, D.convertDims, A.orderNum, D.opt

------------
-- Defaults
------------

local defaults = {}
defaults.db = {
  profile = {}
}
defaults.options = opt("parent", {
  args = {
    { "add", "input", "Add group", {
      set = "AddGroup",
      width = "full"
    } }
  }
})
defaults.group = {
  grow = "right",
  orientation = "horizontal",
  spacing = 25,
  iconPos = "after",
  iconSpacing = -2,
  iconSize = 22,
  lock = true,
  flexible = false,
  add = { barType = "spell" },
  dim1 = 1395,
  dim2 = 3,
  anchor = "top",
  offsetX = 0,
  offsetY = -50,
  bg = { r = 0, g = 0, b = 0, a = 0.3 },
  border = { r = 0, g = 0, b = 0, a = 0.4 }
}
defaults.bar = {
  --image = "Interface\\Icons\\INV_Misc_QuestionMark",
  display = "normal",
  --color = conf:ConfGet(key:s(1):a("color")),
  color = { r = 1, g = 1, b = 1, a = 1 },
  dim1 = 150,
  dim2 = 3,
  barAlpha = 0.66,
  sparkAlpha = 1,
  iconAlpha = 1,
  reverse = false,
  combat = "show",
  noncombat = "auto"
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
      { "orientation", nil, "Bar orientation" },
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
          return convertDims(info.handler:Get(tappend(sublist(info, 1, -2), "orientation")), "Width", "Height")
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
          return convertDims(info.handler:Get(tappend(sublist(info, 1, -2), "orientation")), "Height", "Width")
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
      { "lock", { width = "half" } },
      { "space" },
      { "offsetX" },
      { "offsetY" },
      { "space" },
      { "bg", "aColor", "Background" },
      { "border", "aColor" },
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
              return "New " .. (info.handler:Get(tappend(sublist(info, 1, -2), "barType")) or "spell")
            end,
            set = "AddBar"
          } }
        }
      } }
    }
  })
  self.crawler:Set({ groupName }, opts)
  for barName, bar in pairs(group.bars) do
    self:BuildBarSettings(groupName, barName, bar)
  end
end

--- @param bar Bar
function Settings:AliasString(bar)
  local aliases = {}
  for aliasName in pairs(bar.watch) do
    tinsert(aliases, tostring(aliasName))
  end
  if next(aliases) then
    return " (" .. tconcat(aliases, ", ") .. ")"
  else return ""
  end
end

--- @param groupName string
--- @param name string
--- @param bar Bar
function Settings:BuildBarSettings(groupName, name, bar)
  bar.newColor = bar.color
  local tableKey = { groupName, "args", name }
  local barSettings = opt(nil, "group", name, {
    order = function() return bar.position end,
    icon = function() return select(3, GetSpellInfo(name)) end,
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
      { "color", {
        name = function() return name .. self:AliasString(bar) end,
        set = "UpdateBarColor",
        width = "full"
      } },
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
          return convertDims(info.handler:Get(tappend(sublist(info, 1, -2), "orientation")), "Width", "Height")
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
          return convertDims(info.handler:Get(tappend(sublist(info, 1, -2), "orientation")), "Height", "Width")
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
  local i = 10
  for watch in pairs(bar.watch) do
    if watch ~= name then
      barSettings.args[watch .. "color"] = {
        type = "color",
        hasAlpha = true,
        get = "ConfGetWatchColor",
        set = "ConfSetWatchColor",
        name = function() return watch .. self:AliasString(bar[watch]) end,
        order = i
      }
      barSettings.args[watch .. "delete"] = {
        type = "execute",
        name = "x",
        width = "half",
        func = function(info)
          barSettings.args[watch .. "color"] = nil
          barSettings.args[watch .. "delete"] = nil
          info.handler:Unwatch(info, watch)
        end,
        order = i + 1
      }
      barSettings.args[watch .. "space"] = {
        type = "description",
        name = "",
        width = "full",
        order = i + 2
      }
      i = i + 3
    end
  end
  if name == "Default" then
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
