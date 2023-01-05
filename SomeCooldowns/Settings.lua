local _, N = ...
--- @meta
--- @class SomeCooldownsSettings: HandlerSettings
local Settings = {}
N.Settings = Settings
local A = LibStub:GetLibrary("Abacus-2.0")
local D = LibStub:GetLibrary("DoomCore-2.1")

local GetItemInfo, GetItemIcon, GetSpellInfo, select, tonumber, tostring, type = GetItemInfo, GetItemIcon, GetSpellInfo,
    select, tonumber, tostring, type
local direction, HORIZONTAL, opt, orderNum, VERTICAL = D.direction, D.HORIZONTAL, D.opt, A.orderNum, D.VERTICAL

local defaults = {}
defaults.global = {
  background = "None",
  border = "None",
  lock = true,
  displayItems = true,
  displaySpells = false,
  displayToys = true,
  reverse = true,
  anchor = "bottom",
  sort = "long",
  offsetX = 485,
  offsetY = 120,
  grow = "left",
  padding = 0,
  edge = 4,
  text = false,
  limit = 24,
  max = 0,
  color = { r = 0, g = 0, b = 0, a = 1 },
  recharge = true,
  rowGrowth = "top",
  columnGrowth = "right",
  iconSize = 38,
  spacing = 4,
  tooltip = true,
  tooltipOverride = false,
  tooltipAnchor = "topright"
}
defaults.db = {
  profile = {
  }
}
defaults.options = opt("parent", {
  name = "",
  set = "Rebuild",
  args = {
    { "display", "description", "Display all:", {
      width = "half",
      fontSize = "medium"
    } },
    { "displayItems", "toggle", "Items", {
      width = "half",
      set = "SetFilter"
    } },
    { "displaySpells", "toggle", "Spells", {
      width = "half",
      set = "SetFilter"
    } },
    { "displayToys", "toggle", "Toys", {
      width = "half",
      set = "SetFilter"
    } },
    { "sort", "select", "Start with", {
      width = "half",
      values = {
        short = "Shortest",
        long = "Longest"
      }
    } },
    { "space" },
    { "max", "range", "Max buttons", {
      min = 0,
      softMax = 48,
      step = 1,
      desc = "0 - Unlimited"
    } },
    { "grow", { width = "half" } },
    { "limit", "range", {
      name = function(info)
        return direction[info.handler:ConfGet({ "grow" })] == HORIZONTAL
            and "Max per row"
            or "Max per column"
      end,
      min = 0,
      softMax = 48,
      step = 1,
      desc = "0 = Unlimited"
    } },
    { "rowGrowth", "select", "Grow rows", {
      width = "half",
      values = {
        top = "Up",
        bottom = "Down"
      },
      hidden = function(info)
        local limit = tonumber(N.Handler:ConfGet({ "limit" }))
        if not limit or limit <= 0 then return true end
        return direction[info.handler:ConfGet({ "grow" })] ~= HORIZONTAL
      end
    } },
    { "columnGrowth", "select", "Grow columns", {
      width = "half",
      values = { "right", "left" },
      hidden = function(info)
        local limit = tonumber(info.handler:ConfGet { "limit" })
        if not limit or limit <= 0 then return true end
        return direction[info.handler:ConfGet { "grow" }] ~= VERTICAL
      end
    } },
    { "space" },
    { "iconSize", "bigIconSize" },
    { "spacing", "iconSpacing" },
    { "space" },
    { "recharge", "toggle", "Show recharges", {
      desc = "Show spells with charges remaining",
      set = "SetText"
    } },
    { "text", "toggle", "Show numbers", {
      desc = "Show time remaining on cooldowns",
      set = "SetText"
    } },
    { "color", "aColor", "Shading", {
      desc = "Color of the shaded portion of cooldowns",
      set = "SetSwipeColor"
    } },
    { "reverse", "toggle", "Reverse shading", {
      desc = "Reverse the shaded portion of cooldowns",
      set = "SetReverse"
    } },
    { "space" },
    { "background" },
    { "backgroundColor", "aColor" },
    { "padding", "range", {
      desc = "Padding around edge of window",
      min = 0,
      max = 100,
      softMax = 24,
      step = 0.5
    } },
    { "space" },
    { "border" },
    { "borderColor", "aColor" },
    { "edge" },
    { "space" },
    { "anchor" },
    { "xCenter", "toggle", "Center horizontally" },
    { "yCenter", "toggle", "Center vertically" },
    { "lock", { width = "full" } },
    { "offsetX" },
    { "offsetY" },
    { "space" },
    { "tooltip", "toggle", "Show Tooltips", {
      set = "UpdateTooltips"
    } },
    { "tooltipOverride", "toggle", "Override Anchor", {
      set = "UpdateTooltips",
      disabled = ({ false, "tooltip" }),
    } },
    { "tooltipAnchor", "anchor", {
      set = "UpdateTooltips",
      disabled = ({ false, "and", { "tooltip" }, { "tooltipOverride" } })
    } },
    { "whitelist", "group", {
      inline = true,
      desc = "Always track (even when category's display is turned off)",
      args = {}
    } },
    { "addToWhitelist", "input", "Add to Whitelist", {
      width = "full",
      set = "Add"
    } },
    { "blacklist", "group", {
      inline = true,
      desc = "Always ignore",
      args = {}
    } },
    { "addToBlacklist", "input", "Add to Blacklist", {
      width = "full",
      set = "Add"
    } }
  }
})
Settings.defaults = defaults

function Settings:Add(group, val)
  local entry = {
    type = "execute",
    func = function(info)
      info.handler:ConfDelete({ "group", val })
      if type(val) == "number" then
        info.handler.cooldowns.item[val] = nil
      else
        info.handler.cooldowns.spell[val] = nil
      end
      self.crawler:Set({ group, "args", tostring(val) }, nil)

      info.handler:Update(group == "whitelist")
    end
  }
  if type(val) == "number" then
    entry.name = GetItemInfo(val)
    entry.image = GetItemIcon(val)
  else
    entry.name = val
    entry.image = select(3, GetSpellInfo(val))
  end
  if not entry.name then return end
  entry.order = orderNum(entry.name)

  self.crawler:Set({ group, "args", tostring(val) }, entry)
end

Settings.debug = {
  somebars = {
    type = "toggle",
    name = "Blacklist all from Some Bars",
    hidden = function() return not N.Handler.lib.somebars end,
    width = "full",
    order = 10
  }
}
