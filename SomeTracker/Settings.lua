local _, N = ...

local LibStub = LibStub

local A = LibStub("Abacus-2.0")
local D = LibStub("DoomCore-2.1")
local pairs, tinsert = pairs, tinsert
local opt, orderNum = D.opt, A.orderNum

--- @class SomeTrackerSettings: HandlerSettings
local Settings = {
  prefix = "trackers"
}
N.Settings = Settings

------------
-- Defaults
------------

local defaults = {}
defaults.db = {
  profile = {}
}
defaults.options = opt("parent", {
  args = {
    { "add", "input", "Add tracker", {
      width = "full",
      set = "AddTracker"
    } }
  }
})
--- @type ScoringSettings
defaults.scoring = {
  scoreChat = false,
  scoreIcon = false,
}
--- @type Tracker
defaults.tracker = {
  enabled = true,
  trackerType = "damage",
  misses = "none",
  related = false,
  markCrits = false,
  color = { r = 1, g = 1, b = 1, a = 1 },
  shadow = { r = 0, g = 0, b = 0, a = 1 },
  specialShadow = { r = 0, g = 0, b = 0, a = 0.5 },
  overrideColor = false,
  duration = "3",
  over = "exclude",
  lock = true,
  grow = "top",
  anchor = "CENTER",
  offsetX = -210,
  offsetY = 100,
  iconSize = 31,
  font = "Accidental Presidency",
  fontSize = 22,
}
Settings.defaults = defaults

Settings.custom = {
  ["Note#12985"] = {
    tracker = {
      offsetX = -200,
      offsetY = 100,
      iconSize = 26,
      fontSize = 21
    }
  }
}
local missTypes = {
  ABSORB = "Absorb",
  BLOCK = "Block",
  DEFLECT = "Deflect",
  DODGE = "Dodge",
  EVADE = "Evade",
  IMMUNE = "Immune",
  MISS = "Miss",
  PARRY = "Parry",
  REFLECT = "Reflect",
  RESIST = "Resist",
}

local kinds = {
  aura = "Aura",
  spell = "Spell"
}
Settings.kinds = kinds
local trackerTypes = {
  damage = "Damage",
  healing = "Healing"
}

-----------------
-- Settings page
-----------------

--- @param tracker Tracker
--- @param kind "aura" | "spell"
local function buildMeterSettings(tracker, kind)
  if not kinds[kind] then return end
  local meters = {
    { "meterName", "input", {
      name = "Add spell",
      set = "AddMeter",
      width = "full"
    } }
  }
  for meter in pairs(tracker[kind]) do
    tinsert(meters, { "space" })
    tinsert(meters, { "_" .. meter, "execute", {
      name = "X",
      func = "DeleteMeter",
      width = 0.25
    } })
    tinsert(meters, { meter, "color", {
      name = meter,
      icon = GetSpellTexture(meter),
      width = 1.5
    } })
  end
  return { kind, "group", "Tracked " .. kinds[kind] .. "s", {
    set = "UpdateSettings",
    args = meters
  } }
end

--- @param trackerName string
--- @param tracker Tracker
function Settings:BuildTrackerSettings(trackerName, tracker)
  local name = trackerName
  if not tracker.missType then
    tracker.missType = {}
    for missType in pairs(missTypes) do
      tracker.missType[missType] = true
    end
  end
  local opts = opt(100 + orderNum(name), "group", name, {
    set = "Rebuild",
    args = {
      { "rename", "input", {
        width = "full",
        get = "GetParentName",
        set = "RenameTracker"
      } },
      { "enabled", "toggle", { width = "full" } },
      { "trackerType", "select", "Type", {
        width = "half",
        values = trackerTypes
      } },
      { "misses", "select", "Show misses", {
        width = "half",
        values = { "all", "total", "none" },
        hidden = true --{ false, "trackerType", "damage" }
      } },
      { "related", "toggle", "Show related bonuses" },
      { "missType", "multiselect", "Include miss types", {
        width = "half",
        values = missTypes,
        hidden = { "or", { false, "trackerType", "damage" }, { "misses", "none" } }
      } },
      { "space" },
      { "duration", "input", "Duration (s)", {
        width = "half",
        desc = "Time in seconds before alerts fade",
        get = "ConfGetString",
        validate = "Number"
      } },
      { "over", "select", "Overflow", {
        width = "half",
        desc = "Overdamage/Overhealing",
        values = { "include", "exclude", additional = "Separate" }
      } },
      { "markCrits", "toggle", "Mark crits" },
      { "space" },
      { "color", nil, "Font", { width = "half" } },
      { "shadow", "aColor" },
      { "specialShadow", "aColor", "Shadow for auras", { width = "normal" } },
      { "space" },
      { "iconSize", "bigIconSize", { width = "half" } },
      { "font" },
      { "fontSize", { width = "half" } },
      { "space" },
      { "grow", "select", {
        width = "half",
        values = { top = "up", bottom = "down" }
      } },
      { "anchor" },
      { "lock", { width = "half" } },
      { "space" },
      { "offsetX" },
      { "offsetY" },
      { "space" },
      { "delete", "execute", {
        func = "DeleteTracker"
      } },
      buildMeterSettings(tracker, "aura"),
      buildMeterSettings(tracker, "spell")
    }
  })
  if name == "Default Damage" or name == "Default Healing" then
    opts.args.delete = nil
    opts.args.rename = nil
  end
  self.crawler:Set({ trackerName }, opts)
end

---------------
-- Debug panel
---------------

Settings.debug = {}
