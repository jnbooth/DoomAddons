local LibStub = LibStub

--- @meta
--- @class DoomCore-2.1
local D = LibStub:NewLibrary("DoomCore-2.1", 4)
if not D then return end

local A = LibStub("Abacus-2.0")
local SharedMedia = LibStub("LibSharedMedia-3.0")
local AceAddon = LibStub("AceAddon-3.0")

function AA(addon)
  return AceAddon:GetAddon(addon, true)
end

local BNGetInfo, ceil, CreateFrame, error, floor, min, next, rawget, pairs, print, select, setmetatable, tonumber, tostring, type, UIParent, unpack = BNGetInfo
    , ceil, CreateFrame, error, floor, min, next, rawget, pairs, print, select, setmetatable, tonumber, tostring,
    type, UIParent, unpack
local assertType, capitalize, colPack, colUnpack, Inherits, setIndex, sublist, tappend, tostrings, TypeCode = A.assertType
    , A.capitalize, A.colPack, A.colUnpack, A.Inherits, A.setIndex, A.sublist, A.tappend,
    A.tostrings, A.TypeCode

local type_boolean, type_number, type_string, type_table = TypeCode.Boolean, TypeCode.Number, TypeCode.String,
    TypeCode.Table

--- @type fun(): nil
local ReloadUI = ReloadUI

-----------
-- Anchors
-----------

local anchors = {
  CENTER      = "Center",
  TOPLEFT     = "Top Left",
  TOP         = "Top",
  TOPRIGHT    = "Top Right",
  LEFT        = "Left",
  RIGHT       = "Right",
  BOTTOMLEFT  = "Bottom Left",
  BOTTOM      = "Bottom",
  BOTTOMRIGHT = "Bottom Right"
}
D.anchors = anchors

--- @type { [AnchorPoint]: TooltipAnchor }
local tooltipAnchors = {}
for anchor in pairs(anchors) do
  tooltipAnchors[anchor] = "ANCHOR_" .. anchor
end
tooltipAnchors.CENTER = "ANCHOR_CURSOR"
D.tooltipAnchors = tooltipAnchors

--- @param anchor AnchorPoint
--- @return TooltipAnchor
local function anchorToTooltip(anchor)
  if anchor == "CENTER" then
    return "ANCHOR_NONE"
  end
  return "ANCHOR_" .. anchor
end

D.anchorToTooltip = anchorToTooltip

local VERTICAL = 1
D.VERTICAL = VERTICAL
local HORIZONTAL = 2
D.HORIZONTAL = HORIZONTAL
local orientations = {
  HORIZONTAL = "Horizontal",
  VERTICAL = "Vertical"
}
D.orientations = orientations
local orientGrowth = {
  HORIZONTAL = {
    [false] = "right",
    [true] = "left"
  },
  VERTICAL = {
    [false] = "top",
    [true] = "bottom"
  }
}
D.orientGrowth = orientGrowth

local direction = {
  TOP = VERTICAL,
  BOTTOM = VERTICAL,
  LEFT = HORIZONTAL,
  RIGHT = HORIZONTAL,
  HORIZONTAL = HORIZONTAL,
  VERTICAL = VERTICAL
}
D.direction = direction

--- @param anchor1 AnchorPoint
--- @param anchor2 AnchorPoint
--- @return AnchorPoint
local function compound(anchor1, anchor2)
  local dir1, dir2 = direction[anchor1], direction[anchor2]
  if not dir1 then return anchor1 end
  if not dir2 then return anchor2 end
  if dir1 < dir2 then
    return anchor1 .. anchor2
  else
    return anchor2 .. anchor1
  end
end

D.compound = compound

local grow = {
  LEFT = "Left",
  RIGHT = "Right",
  TOP = "Up",
  BOTTOM = "Down"
}
D.grow = grow

--- @class GrowAnchorData
--- @field [1] AnchorPoint | nil
--- @field [2] AnchorPoint | nil
--- @field [3] number
--- @field [4] number

--- @type { [AnchorPoint]: GrowAnchorData }
local growAnchors = {
  LEFT   = { "RIGHT", "LEFT", -1, 0 },
  RIGHT  = { "LEFT", "RIGHT", 1, 0 },
  TOP    = { "BOTTOM", "TOP", 0, 1 },
  BOTTOM = { "TOP", "BOTTOM", 0, -1 },
  CENTER = { "CENTER", "CENTER", 0, 0 }
}
D.growAnchors = growAnchors
for _, dir1 in pairs({ "LEFT", "RIGHT" }) do for _, dir2 in pairs({ "TOP", "BOTTOM" }) do
    growAnchors[compound(growAnchors[dir1][1], growAnchors[dir2][1])] = { nil, nil, growAnchors[dir1][3],
      growAnchors[dir2][4] }
  end
end

local corners = {
  TOPLEFT     = { "BOTTOMRIGHT", "TOPLEFT", -1, -1 },
  TOPRIGHT    = { "BOTTOMLEFT", "TOPRIGHT", 1, -1 },
  BOTTOMLEFT  = { "TOPRIGHT", "BOTTOMLEFT", -1, 1 },
  BOTTOMRIGHT = { "TOPLEFT", "BOTTOMRIGHT", 1, 1 }
}
D.corners = corners

local borders = {
  TOP    = { { "BOTTOMLEFT", "TOPLEFT", -1, 0 }, { "BOTTOMRIGHT", "TOPRIGHT", 1, 0 }, 0, 1 },
  BOTTOM = { { "TOPLEFT", "BOTTOMLEFT", -1, 0 }, { "TOPRIGHT", "BOTTOMRIGHT", 1, 0 }, 0, 1 },
  LEFT   = { { "TOPRIGHT", "TOPLEFT", 0, 1 }, { "BOTTOMRIGHT", "BOTTOMLEFT", 0, -1 }, 1, 0 },
  RIGHT  = { { "TOPLEFT", "TOPRIGHT", 0, 1 }, { "BOTTOMLEFT", "BOTTOMRIGHT", 0, -1 }, 1, 0 }
}
D.borders = borders

--- @generic T
--- @param dir AnchorPoint | "HORIZONTAL" | "VERTICAL" | nil
--- @param dim1 T
--- @param dim2 T
--- @return T, T
local function convertDims(dir, dim1, dim2)
  if direction[dir] == HORIZONTAL then
    return dim1, dim2
  else
    return dim2, dim1
  end
end

D.convertDims = convertDims


----------
-- Frames
----------

--- @return Locker
local function Locker()
  local locker = DoomCoreLocker
  if locker then return locker end
  locker = CreateFrame("Button", "DoomCoreLocker", UIParent, "UIPanelButtonTemplate") --[[@as Locker]]
  locker:SetFrameStrata("DIALOG")
  locker.frames = {}
  locker:SetText("Lock all")
  locker:SetSize(80, 25)
  locker:SetPoint("BOTTOM", 0, 150)
  locker:Hide()
  function locker:Update()
    local visible = false
    for frameName, frame in pairs(self.frames) do
      if frame and frame.conf and frame.conf.lock == false then
        visible = true
        break
      end
    end
    if visible then
      self:Show()
    else
      self:Hide()
    end
  end

  locker:SetScript("OnClick", function(self)
    for frameName, frame in pairs(self.frames) do
      if frame.conf then frame.conf.lock = true end
      if frame.tex then frame.tex:Hide() end
    end
    self.frames = {}
    self:Hide()
  end)
  return locker
end

D.Locker = Locker

--- @param frame Frame
--- @param padding number
--- @param parent? Region
--- @return nil
local function pad(frame, padding, parent)
  parent = parent or frame:GetParent() --[[@as Region]]
  frame:ClearAllPoints()
  for _, corner in pairs(corners) do
    frame:SetPoint(corner[1], parent, corner[1], padding * corner[3], padding * corner[4])
  end
end

D.pad = pad

--- @param frame Frame | DoomFrame
--- @param c? table
--- @param anchor? string
--- @param parent? Region
--- @return nil
local function updateFrame(frame, c, anchor, parent)
  c = c or frame.conf or {}
  anchor = anchor or c.anchor
  parent = parent or UIParent

  local height, lock, offsetX, offsetY, scale, width = c.height, c.lock, c.offsetX, c.offsetY, c.scale, c.width
  if anchor and not anchors[anchor:lower()] then anchor = nil end

  local unlocked = false
  if width then frame:SetWidth(width) end
  if height then frame:SetHeight(height) end
  if anchor then
    frame:ClearAllPoints()
    frame:SetPoint(anchor, parent, anchor, offsetX or 0, offsetY or 0)
  end
  if lock ~= nil then
    unlocked = not lock
    local locker = Locker()
    locker.frames[frame:GetName()] = frame
    locker:Update()
  end

  if scale then
    if frame:GetParent() == nil then scale = scale * UIParent:GetScale() end
    frame:SetScale(scale)
  end

  frame:SetMovable(unlocked)
  frame:EnableMouse(unlocked)
  if not frame.tex then
  elseif unlocked then
    frame.tex:Show()
  else
    frame.tex:Hide()
  end
  for _, child in pairs({ frame:GetChildren() }) do
    if child.EnableMouse then child:EnableMouse(not unlocked) end
  end
  return unlocked
end

D.updateFrame = updateFrame

--- @param frame Frame
--- @param frameSettings? FrameSettings
--- @param onReceiveDrag? fun(): nil
--- @return nil
local function draggable(frame, frameSettings, onReceiveDrag)
  if frame:GetScript("OnReceiveDrag") then return end
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:SetScript("OnReceiveDrag", function()
    local orig, _, dest, x, y = frame:GetPoint(1)
    local a = growAnchors[orig]
    if frameSettings then
      frameSettings.anchor = dest:lower()
      frameSettings.offsetX = floor(x * 10) / 10
      frameSettings.offsetY = floor(y * 10) / 10
    end
    if onReceiveDrag then onReceiveDrag() end
  end)
end

D.draggable = draggable

--- @param text FontInstance
--- @param conf FrameSettings
--- @return nil
local function setFont(text, conf)
  local font = SharedMedia:Fetch(SharedMedia.MediaType.FONT, conf.font)
  text:SetFont(font, conf.fontSize)
  if conf.fontColor then text:SetTextColor(colUnpack(conf.fontColor)) end
end

D.setFont = setFont

--- @param frame BackdropTemplate
--- @param background? string
--- @param backgroundColor? Color
--- @param inset? number
--- @param border? string
--- @param borderColor? Color
--- @param edge? number
--- @return nil
local function setBg(frame, background, backgroundColor, inset, border, borderColor, edge)
  edge = edge or 4
  inset = inset or 4
  backgroundColor = backgroundColor or { r = 1, g = 1, b = 1, a = 1 }
  borderColor = borderColor or { r = 1, g = 1, b = 1, a = 1 }
  local bg = {}
  if background and background ~= "None" then
    bg.bgFile = SharedMedia:Fetch(SharedMedia.MediaType.BACKGROUND, background)
  end
  if border and border ~= "None" then
    bg.edgeFile = SharedMedia:Fetch(SharedMedia.MediaType.BORDER, border)
    bg.edgeSize = edge
  end
  bg.insets = { left = inset, right = inset, top = inset, bottom = inset }
  frame:SetBackdrop(bg)
  frame:SetBackdropColor(colUnpack(backgroundColor))
  frame:SetBackdropBorderColor(colUnpack(borderColor))
end

D.setBg = setBg

--- @param frame DoomFrame
--- @param conf? FrameSettings
local function setBgFromConf(frame, conf)
  conf = conf or frame.conf
  setBg(frame, conf.background, conf.backgroundColor, conf.inset, conf.border, conf.borderColor, conf.edge)
end

D.setBgFromConf = setBgFromConf

--- @param c FrameSettings
--- @return nil
local function makeGrid(c)
  c.padding = c.padding or 0
  c.spacing = c.spacing or c.iconSpacing or 0

  if not c.grow2 then
    if direction[c.grow] == HORIZONTAL then
      c.grow2 = c.rowGrowth
    else
      c.grow2 = c.columnGrowth
    end
  end

  local anchor, frame, grow, grow2, parent, x, y = c.anchor, c.frame, c.grow, c.grow2, c.parent, c.x, c.y
  local els, limit, cMax, padding, size, spacing = c.els, c.limit, c.max, c.padding, c.size, c.spacing or c.iconSpacing

  local a1 = growAnchors[grow] or growAnchors.CENTER
  local a2 = growAnchors[grow2] or growAnchors.CENTER
  local comp = compound(a1[1], a2[1])
  local growComp = growAnchors[comp]

  frame:ClearAllPoints()
  if parent and anchor then
    frame:SetPoint(comp, parent, anchor,
      --conf_x - (conf_size + conf_padding * 2) * growComp[3] / 2,
      --conf_y - (conf_size + conf_padding * 2) * growComp[4] / 2)
      x, y)
  end

  if not els or #els == 0 then
    frame:SetSize(size + padding * 2, size + padding * 2)
    return
  end

  els[1]:ClearAllPoints()
  els[1]:SetPoint(comp, frame, comp, growComp[3] * padding, growComp[4] * padding)
  els[1]:Show()

  local toMax = #els
  if cMax and cMax > 0 then toMax = min(toMax, cMax) end

  for i = 2, toMax do
    els[i]:ClearAllPoints()

    if limit and limit > 0 and (i - 1) % limit == 0 then
      els[i]:SetPoint(a2[1], els[i - limit], a2[2], a2[3] * spacing, a2[4] * spacing)
    else
      els[i]:SetPoint(a1[1], els[i - 1], a1[2], a1[3] * spacing, a1[4] * spacing)
    end
    els[i]:Show()
  end
  for i = toMax + 1, #els do
    els[i]:Hide()
  end
  local dim1, dim2
  if limit and limit > 0 and toMax > limit then
    dim1 = padding * 2 + size * limit + spacing * (limit - 1)
    local subs = ceil(toMax / limit)
    dim2 = padding * 2 + size * subs + spacing * (subs - 1)
  else
    dim1 = padding * 2 + size * toMax + spacing * (toMax - 1)
    dim2 = padding * 2 + size
  end
  frame:SetSize(convertDims(grow, dim1, dim2))
  setBgFromConf(frame, c)
  --conf_frame:Show()
end

D.makeGrid = makeGrid

-------------------
-- Crawling
-------------------

local type_tablekey = type_boolean + type_number + type_string

--- @param node table
--- @param key AceInfo | tablekey[]
--- @param noChildren? boolean
--- @param raw? boolean
--- @return any
local function crawl(node, key, noChildren, raw)
  assertType(node, type_table, key, type_table, 3)
  local options = key.options
  if options then
    local prefix = options.name
    if prefix then
      node = node[prefix]
    end
  end
  local max = #key
  if max == 0 then return node elseif max < 0 then return nil end
  local child
  for i = 1, max do
    if node == nil then return end
    local segment = key[i]
    if raw then
      child = rawget(node, segment)
    else
      child = node[segment]
    end
    if not noChildren and child == nil then
      child = {}
      node[segment] = child
    end
    node = child
  end
  return node
end

D.crawl = crawl

--- @class NodeCrawler: Inherits
--- @field core table
local NodeCrawler = Inherits:New()

--- @param core? table
--- @return NodeCrawler
function NodeCrawler:New(core)
  core = core or {}
  assertType(core, type_table, 3)
  local new = NodeCrawler._super.New(self)
  new.core = core
  return new
end

--- @param key? tablekey[]
--- @return any | nil
function NodeCrawler:Get(key)
  if key == nil then return self.core end
  return crawl(self.core, key, true)
end

--- @generic T
--- @param key tablekey[]
--- @param value T
--- @param noOverride? boolean
--- @return T | nil
function NodeCrawler:Set(key, value, noOverride)
  assertType(key, type_table, 3)
  if not next(key) then
    if value == nil then value = {} end
    if not noOverride then self.core = value end
    return self.core
  end
  local parent = crawl(self.core, sublist(key, 1, -2), value == nil, true)
  if type(parent) ~= "table" then return end
  local child = key[#key]
  if not (noOverride and parent[child] ~= nil) then
    parent[child] = value
  end
  return parent[child]
end

--- @param key tablekey[]
--- @return {} | nil
function NodeCrawler:GetOrMake(key)
  return self:Set(key, {}, true)
end

--- @param key tablekey[]
--- @param amount? number
--- @return number
function NodeCrawler:Incr(key, amount)
  if (amount == nil) then amount = 1 end
  assertType(key, type_table, amount, type_number, 3)
  local parent = crawl(self.core, sublist(key, 1, -2), false, true)
  local child = key[#key]
  parent[child] = amount + (parent[child] or 0)
  return parent[child]
end

--- @param parent table
--- @param childName tablekey
--- @param ... any
--- @return nil
local function nappend(parent, childName, ...)
  assertType(parent, type_table, childName, type_tablekey, 3)
  local child = parent[childName]
  if child == nil then
    child = {}
    parent[childName] = child
  elseif type(child) ~= "table" then
    return
  end
  tappend(child, ...)
end

D.nappend = nappend

--- @param key tablekey[]
--- @param ... any
--- @return nil
function NodeCrawler:Append(key, ...)
  assertType(key, type_table, 3)
  local parent = crawl(self.core, sublist(key, 1, -2), false, true)
  if parent ~= nil and type(parent) ~= "table" then return end
  local childKey = key[#key]
  nappend(parent, childKey, ...)
end

D.NodeCrawler = NodeCrawler

--- @class Configuration: NodeCrawler
--- @field defaults table | nil
local Configuration = NodeCrawler:New()

--- @return Configuration
function Configuration:New(val)
  local new = Configuration._super.New(self, val)
  return new
end

--- @param child any
function Configuration:AutoDefault(child)
  if not child or not child.type or not self.defaults then return end
  local default = self.defaults[child.type]
  if default then setIndex(child, default, true) end
end

--- @param child tablekey
--- @param parent tablekey
--- @return nil
function Configuration:Inherit(child, parent)
  local defaults = self.defaults
  if not defaults then return end
  defaults[child] = defaults[child] or {}
  defaults[parent] = defaults[parent] or {}
  setIndex(defaults[child], defaults[parent], true)
end

--- @param node? table
--- @param crawled? { [any]: boolean }
--- @return nil
function Configuration:CrawlDefaults(node, crawled)
  crawled = crawled or {}
  if not node then node = self.core end
  crawled[node] = true
  if type(node) ~= "table" then return end
  self:AutoDefault(node)
  for k, v in pairs(node) do
    if not crawled[v] then
      if type(v) == "table" and not (type(k) == "string" and k:find("_")) then
        self:CrawlDefaults(v, crawled)
      end
    end
  end
end

--- @generic T
--- @param parent { [any]: T }
--- @param makeType string
--- @param childName tablekey
--- @return T
function Configuration:Make(parent, makeType, childName, noOverride)
  assertType(parent, type_table, makeType, type_string, childName, type_tablekey, 3)
  if noOverride and Configuration:Overriden(parent, childName) then
    return parent[childName]
  end
  local child = rawget(parent, childName)
  if child == nil then
    child = {}
    parent[childName] = child
  end
  child.type = makeType
  self:AutoDefault(child)
  return child
end

--- @param parent table
--- @param childName tablekey
--- @return boolean
function Configuration:Overriden(parent, childName)
  assertType(parent, type_table, childName, type_tablekey, 3)
  local child = rawget(parent, childName)
  if child == nil then return false end
  return child.type ~= nil
end

--- @param info tablekey[]
--- @return any ...
function Configuration:ConfGet(info)
  local val = self:Get(info)

  if type(val) == "table" and val.r and val.g and val.b then
    return colUnpack(val)
  end

  return val
end

--- @param info tablekey[]
--- @return string
function Configuration:ConfGetString(info)
  return tostring(self:ConfGet(info))
end

--- @overload fun(self: Configuration, info: tablekey[], r: number, g: number, b: number, a?: number): Color
--- @overload fun(self: Configuration, info: tablekey[], val: any): any
function Configuration:ConfSet(info, r, g, b, a)
  if b ~= nil then return self:Set(info, colPack(r, g, b, a))
  elseif tonumber(r) then return self:Set(info, tonumber(r))
  else return self:Set(info, r) end
end

--- @param info tablekey[]
--- @return table | nil
function Configuration:GetParent(info)
  local parent = self:Get(sublist(info, 1, -2))
  if type(parent) == "table" then return parent end
end

--- @param info tablekey[]
--- @return tablekey
function Configuration:GetParentName(info)
  return info[#info - 1]
end

--- @param info tablekey[]
--- @return boolean
function Configuration:ConfOverriden(info)
  local parent = self:GetParent(info)
  return parent ~= nil and self:Overriden(parent, info[#info])
end

--- @param t tablekey[][]
--- @param info? tablekey[]
--- @return boolean
function Configuration:Check(t, info)
  local size = #t
  if size == 0 then return true end

  local start = 1
  local sign
  if t[start] then
    sign = true
  else
    start = start + 1
    sign = false
  end

  if type(t[start + 1]) == "table" then
    local op = t[start]
    if op == "and" then
      for i = start + 1, size do
        if not self:Check(t[i]) then return not sign end
      end
      return sign
    else
      for i = start + 1, size do
        if self:Check(t[i]) then return sign end
      end
      return not sign
    end
  end

  local db = self:Get(info)
  local pref = t[start]
  if info and type(pref) == "string" then
    if pref:sub(1, 1) == "^" then
      start = start + 1
      local parent = tonumber(pref:sub(2))
      if parent then
        local subinfo = {}
        for i = 1, #info - parent do
          subinfo[i] = info[i]
        end
        db = self:Get(subinfo)
      end
    end
  end
  for i = start, size do
    if i == size and db == t[i] then return sign end
    if type(db) ~= "table" then return not sign end
    db = db[t[i]]
  end
  return not db == not sign
end

D.Configuration = Configuration


-----------------
-- Addon handler
-----------------

--- @class Handler: Configuration, AceAddon, AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
--- @field core HandlerCore
--- @field lib HandlerLib
--- @field name string
--- @field settings HandlerSettings
--- @field shortName string
--- @field mediaPath string
--- @field timers { [string]: AceTimerObj }
--- @field version number
--- @field OnLoad nil | fun(self: Handler, registered: boolean | nil): nil
local Handler = Configuration:New()

--- @param addon AceAddon
--- @return Handler
function Handler:New(addon)
  --- @cast addon Handler
  setIndex(addon, Handler)
  local addon_settings = addon.settings
  if addon_settings then
    addon.defaults = addon_settings.defaults
  end
  addon.timers = {}
  addon.frames = {}
  return addon
end

--- @param shortName string
--- @param name string
--- @param N? table
--- @param ... string
function D.Addon(shortName, name, N, ...)
  local addon = AceAddon:NewAddon(shortName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", ...)
  addon.shortName = shortName
  addon.name = name
  addon.mediaPath = "Interface\\AddOns\\" .. shortName .. "\\Media\\"
  if N then addon.settings = N.Settings end
  local handler = Handler:New(addon)
  if N then N.Handler = handler end
  return handler
end

--- @param ... any
--- @return nil
function Handler:Output(...)
  if self.core._debug and self.core._debug.print then print(self.name, " | ", tostrings(...)) end
end

--- @return number
function Handler:GetVersion()
  return self.core._version
end

--- @param version number
--- @return nil
function Handler:SetVersion(version)
  self.core._version = version
end

--- @return nil
function Handler:ResetDB()
  self.lib.db:ResetProfile()
end

--- @param funcName string
--- @return nil
function Handler:Queue(funcName, ...)
  local timers = self.timers
  if type(self[funcName]) ~= "function" then error(tostrings("Invalid function ", funcName, "."), 2) end
  if not self.ScheduleTimer then error("AceTimer not mixed in!", 2) end
  if not timers[funcName] or self:TimeLeft(timers[funcName]) == 0 then
    timers[funcName] = self:ScheduleTimer(funcName, 0.01, ...)
  end
end

--- @param funcName string
--- @param event? string
--- @param ... any
--- @return nil
function Handler:TrackEvent(funcName, event, ...)
  event = event or funcName
  self:RegisterEvent(event, funcName, ...)
end

--- @param funcName string
--- @param event? string
--- @return nil
function Handler:TrackEventQueue(funcName, event)
  event = event or funcName
  self:RegisterEvent(event, "Queue", funcName)
end

--- @param funcName string
--- @param ... any
--- @return nil
function Handler:TrackMultiEvent(funcName, ...)
  self:Map("TrackEvent", { funcName }, { ... })
end

--- @param funcName string
--- @param ... any
--- @return nil
function Handler:TrackMultiEventQueue(funcName, ...)
  self:Map("TrackEventQueue", { funcName }, { ... })
end

--- @param registered? boolean
--- @return nil
function Handler:Reset(registered)
  self.core = self.lib.db.profile
  self:CrawlDefaults()
  if registered ~= false then
    self:SetVersion(self.version)
  end

  local settings = self.settings
  if settings then
    settings.options = { type = "group", args = {}, name = settings.prefix }
    local defaults = self.defaults
    if defaults and defaults.options then
      settings.options = defaults.options
    end
    settings.options.handler = self
    settings.crawler = NodeCrawler:New(settings.options.args)

    if defaults and defaults.global then
      setIndex(self.core, defaults.global)
    end
  end
  if self.OnLoad then self:OnLoad(registered) end

  if settings and settings.options then
    self.lib.registry:RegisterOptionsTable(self.name, settings.options)
  end
end

--- @param ... tablekey[]
--- @return nil
function Handler:MigrateDB(...)
  local old = Configuration:New {}
  for i = 1, select("#", ...) do
    local key = select(i, ...)
    if key == nil then key = {} end
    local subTable = self:Get(key)
    if type(subTable) ~= "table" then
      old:Set(key, subTable)
    else
      for k, v in pairs(subTable) do
        if type(v) ~= "table" then old:Set(tappend({ unpack(key) }, k), v) end
      end
    end
  end

  self:ResetDB()

  for i = 1, select("#", ...) do
    local key = select(i, ...)
    local subTable = old:Get(key)
    if type(subTable) ~= "table" then
      if subTable ~= self:ConfGet(key) then
        self:ConfSet(key, subTable)
      end
    else
      for k, v in pairs(subTable) do
        local subKey = tappend({ unpack(key) }, k)
        if type(v) ~= "table" and v ~= self:ConfGet(subKey) then
          self:ConfSet(subKey, v)
        end
      end
    end
  end

  if self.version then self:SetVersion(self.version) end
end

--- @overload fun(self: Handler, info: tablekey[], r: number, g: number, b: number, a: number): Color
--- @overload fun(self: Handler, info: tablekey[], r: number, g: number, b: number): Color
--- @overload fun(self: Handler, info: tablekey[], val: any): any
--- @return nil
function Handler:ConfSetReload(info, r, g, b, a)
  self:ConfSet(info, r, g, b, a)
  ReloadUI()
end

--- @param args { [string]: any }
--- @return table
function Handler:DebugOptions(args)
  local debug = {
    type = "group",
    name = "_debug",
    handler = self,
    get = "ConfGet",
    set = "ConfSet",
    args = {
      export = {
        type = "description",
        name = 'Exported to AA("' .. self.shortName .. '")',
        width = "full",
        fontSize = "medium",
        order = 0
      },
      print = {
        type = "toggle",
        name = "Print debug messages",
        width = "full",
        set = "ConfSetDebug",
        order = 1
      },
    }
  }
  local debug_args = debug.args
  for k, v in pairs(args) do
    debug_args[k] = v
  end
  return debug
end

local dbCallbacks = { "OnProfileCopied", "OnProfileDeleted", "OnProfileReset", "OnDatabaseReset", "OnProfileChanged" }

--- @param libs { [string]: string }
--- @param defaultProfile? string | boolean
--- @param defaults? table
--- @return nil
function Handler:Register(libs, defaultProfile, defaults)
  self.lib = self.lib or {}
  local name, lib, settings = self.name, self.lib, self.settings
  if settings and settings.custom then
    local subDefaults = settings.defaults or {}
    settings.defaults = subDefaults
    local battletag = select(2, BNGetInfo())
    for name, custom in pairs(settings.custom) do
      if name == battletag then
        for customType, customSettings in pairs(custom) do
          subDefaults[customType] = subDefaults[customType] or {}
          local subDefaultType = subDefaults[customType]
          for propertyName, propertyVal in pairs(customSettings) do
            subDefaultType[propertyName] = propertyVal
          end
        end
      end
    end
    if not defaults and subDefaults.db then
      defaults = settings.defaults.db
    end
  end
  defaults = defaults or {}

  lib.db = LibStub("AceDB-3.0"):New(self.shortName .. "DB", defaults, defaultProfile)

  lib.registry = LibStub("AceConfigRegistry-3.0")
  lib.settings = LibStub("AceConfigDialog-3.0")
  lib.options = LibStub("AceDBOptions-3.0")
  for libKey, libName in pairs(libs or {}) do
    if not lib[libKey] then
      lib[libKey] = LibStub(libName, true) or AceAddon:GetAddon(libName, true)
    end
  end

  self:Reset(false)

  if settings then
    lib.settings:AddToBlizOptions(name)
    local profileSettings = LibStub("AceDBOptions-3.0"):GetOptionsTable(lib.db)
    lib.registry:RegisterOptionsTable(name .. " Profile", profileSettings)
    lib.settings:AddToBlizOptions(name .. " Profile", "Profiles", name)

    if settings.debug then
      local debug = self:DebugOptions(settings.debug)
      lib.registry:RegisterOptionsTable(name .. " Extras", debug)
      lib.settings:AddToBlizOptions(name .. " Extras", "Extras", name)
    end
  end

  for _, callback in pairs(dbCallbacks) do
    ---@diagnostic disable-next-line: undefined-field
    lib.db.RegisterCallback(self, callback, "Reset")
  end
end

--- @param frame Frame
--- @param conf? FrameSettings
--- @param funcName? string | fun(): nil
--- @return nil
function Handler:Draggable(frame, conf, funcName)
  if frame:GetScript("OnReceiveDrag") then return end
  funcName = funcName or "Rebuild"
  local func = function()
    if type(funcName) == "function" then funcName()
    elseif type(self[funcName]) == "function" then self[funcName](self) end
    self.lib.registry:NotifyChange(self.name)
  end
  draggable(frame, conf, func)
end

D.Handler = Handler


----------------------
-- Settings templates
----------------------

local optTs = {}
optTs.parent = {
  type = "group",
  get = "ConfGet",
  set = "ConfSet"
}
optTs.space = {
  type = "description",
  name = "",
  width = "full"
}
optTs.label = {
  type = "description",
  width = "half",
  fontSize = "medium"
}
optTs.text = {
  type = "description",
  width = "full",
  fontSize = "medium"
}
optTs.reload = {
  type = "toggle",
  set = "ConfSetReload",
  desc = "Requires UI reload",
  confirm = function() return "Requires Reload UI" end
}
optTs.lock = {
  type = "toggle",
  name = "Lock"
}
optTs.background = {
  name = "Background",
  type = "select",
  dialogControl = "LSM30_Background",
  values = SharedMedia:HashTable(SharedMedia.MediaType.BACKGROUND)
}
optTs.border = {
  name = "Border",
  type = "select",
  dialogControl = "LSM30_Border",
  values = SharedMedia:HashTable(SharedMedia.MediaType.BORDER)
}
optTs.font = {
  name = "Font",
  type = "select",
  dialogControl = "LSM30_Font",
  values = SharedMedia:HashTable(SharedMedia.MediaType.FONT)
}
optTs.range = {
  type = "range",
  step = 0.5
}
optTs.fontSize = {
  type = "range",
  name = "Font size",
  min = 1,
  max = 100,
  softMin = 10,
  softMax = 50,
  step = 1
}
optTs.iconSize = {
  type = "range",
  name = "Icon size",
  min = 1,
  max = 100,
  softMin = 5,
  softMax = 50,
  step = 0.5
}
optTs.iconSpacing = {
  type = "range",
  name = "Icon Spacing",
  min = -100,
  max = 100,
  softMin = -20,
  softMax = 20,
  step = 0.5
}
optTs.bigIconSize = {
  type = "range",
  name = "Icon size",
  min = 1,
  max = 500,
  softMin = 10,
  softMax = 50,
  step = 0.5
}
optTs.edge = {
  type = "range",
  name = "Border size",
  min = 1,
  max = 100,
  softMax = 36,
  step = 0.5
}
optTs.inset = {
  type = "range",
  name = "Inset",
  min = 0,
  max = 100,
  softMax = 36,
  step = 0.5
}
optTs.anchor = {
  type = "select",
  name = "Anchor",
  values = anchors
}
optTs.offsetX = {
  type = "range",
  name = "X",
  min = -floor(UIParent:GetWidth()),
  max = floor(UIParent:GetWidth()),
  step = 0.5,
  disabled = ({ "lock" })
}
optTs.offsetY = {
  type = "range",
  name = "Y",
  min = -floor(UIParent:GetHeight()),
  max = floor(UIParent:GetHeight()),
  step = 0.5,
  disabled = ({ "lock" })
}
optTs.grow = {
  type = "select",
  name = "Grow",
  values = grow
}
optTs.orientation = {
  type = "select",
  name = "Orientation",
  values = D.orientations,
  order = 12
}
optTs.aColor = {
  name = "Color",
  type = "color",
  hasAlpha = true,
  width = "half"
}
optTs.percent = {
  type = "range",
  min = 0,
  max = 1,
  step = 0.01,
  isPercent = true
}
optTs.scale = {
  type = "range",
  name = "Scale",
  min = 0.001,
  max = 10,
  softMax = 2,
  step = 0.001,
  isPercent = true
}

local checks = {}
for _, check in pairs({ "disabled", "hidden", "confirm" }) do
  checks[check] = true
end
local function ensureCheck(k, v)
  if checks[k] and type(v) == "table" then return function(info)
      tremove(info)
      return info.handler:Check(v, info)
    end
  end
  return v
end

--- @param optOut table
--- @param body table
--- @return nil
local function optCopy(optOut, body)
  for k, v in pairs(body or {}) do
    if k:sub(1, 1) == "_" then
      optOut[k:sub(2)] = v
    elseif k == "values" then
      optOut[k] = optOut[k] or {}
      local values = optOut[k]
      for i, value in pairs(v) do
        if type(i) == "number" then
          values[value] = capitalize(value)
        else
          values[i] = value
        end
      end
    elseif k == "args" then
      optOut[k] = optOut[k] or {}
      local args = optOut[k]
      local shift = 0
      for i, arg in pairs(v) do
        if type(arg) == "number" then shift = arg - i - 1
        elseif type(i) == "number" then
          local newI, optType, name, body = unpack(arg)
          if type(name) == "table" then
            body = name
            name = nil
          elseif type(optType) == "table" then
            body = optType
            optType = nil
            name = nil
          end
          body = body or {}
          if name then
            body.name = body.name or name
          else
            name = capitalize(newI)
          end
          optType = optType or newI
          if args[newI] then newI = newI .. i end
          args[newI] = D.opt(shift + i, optType, name, body)
        else
          args[i] = arg
        end
      end
    else
      optOut[k] = ensureCheck(k, v)
    end
  end
end

--- @overload fun(optType: string, body: table): table
--- @overload fun(order: number, name: string, body: table): table
--- @overload fun(order: number, optType: string, name: string, body: table)
local function opt(order, optType, name, body)
  local optOut = {}
  if order == "parent" then
    order = nil
    name = nil
    --- @type table
    body = optType
    optType = "parent"
  elseif type(name) == "table" then
    body = name
    --- @type string
    name = optType
  end
  for k, v in pairs(optTs[optType] or {}) do optOut[k] = ensureCheck(k, v) end
  optOut.type = optOut.type or optType
  optOut.name = optOut.name or name
  optOut.order = order
  optCopy(optOut, body)
  return optOut
end

D.opt = opt
