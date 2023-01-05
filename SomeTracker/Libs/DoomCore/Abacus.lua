--- @class Abacus-2.0
local A = LibStub:NewLibrary("Abacus-2.0", 10)
if not A then return end
tconcat       = tconcat or table.concat
local tconcat = tconcat
pow           = pow or math.pow
local pow     = pow
fmod          = fmod or math.fmod
local fmod    = fmod
local band    = bit.band

local _G, ceil, CreateFrame, error, floor, GameTooltip, getmetatable, getn, HideUIPanel, ipairs, min, max, next, pairs, print, select, setmetatable, ShowUIPanel, sort, strbyte, strsplit, tinsert, tonumber, tostring, type, UIParent, unpack = _G
    , ceil, CreateFrame, error, floor, GameTooltip, getmetatable, getn, HideUIPanel, ipairs, min, max, next, pairs, print
    , select, setmetatable, ShowUIPanel, sort, strbyte, strsplit, tinsert, tonumber, tostring, type, UIParent, unpack
local GetItemInfo, GetSpellInfo = GetItemInfo, GetSpellInfo

--- Searches for an element within a table and returns the key/value pair if found.
--- @generic K, V
--- @param list { [K]: V }
--- @param el V
--- @return K|nil, V|nil
local function tcontains(list, el)
  for k, v in pairs(list) do
    if v == el then return k, v end
  end
end

A.tcontains = tcontains

--- Clamps a number within a range.
--- @param minBound number
--- @param val number
--- @param maxBound number
--- @return number
local function bounded(minBound, val, maxBound)
  if minBound and val < minBound then return minBound
  elseif maxBound and val > maxBound then return maxBound
  else return val
  end
end

A.bounded = bounded

--- Returns true if the value is nil, an empty string, or an empty table.
--- @param val any
--- @return boolean
local function isEmpty(val)
  return val == nil or val == "" or (type(val) == "table" and next(val) == nil)
end

A.isEmpty = isEmpty

--- Transforms a string into a number for lexicographical ordering.
--- @param text string
--- @return number
local function orderNum(text)
  text = text:upper()
  local order = 0
  for i = 1, #text do
    order = order + (strbyte(text, i)) / pow(100, i)
  end
  return order
end

A.orderNum = orderNum

--- Applies `tostring` to multiple elements and concatenates the results.
--- @see tostring
--- @param ... any
--- @return string
local function tostrings(...)
  local output = {}
  for i = 1, select("#", ...) do
    output[i] = tostring(select(i, ...))
  end
  return tconcat(output, "")
end

A.tostrings = tostrings

--- Stringifies a table to a JSON-esque representation.
--- @param val any
--- @return string
local function tovstring(val)
  if type(val) == "table" then
    if isEmpty(val) then return "{}"
    elseif #val > 0 then
      local output = {}
      for i = 1, #val do
        output[i] = tostring(val[i])
      end
      return "{" .. tconcat(output, ", ") .. "}"
    else
      local output = {}
      for k, v in pairs(val) do
        tinsert(output, tostring(k) .. " = " .. tostring(v))
      end
      return "{" .. tconcat(output, ", ") .. "}"
    end
  end
  return tostring(val)
end

A.tovstring = tovstring

--- Applies `tovstring` to multiple elements and concatenates the results.
--- @see tovstring
--- @param ... any
--- @return string
local function tovstrings(...)
  local output = {}
  for i = 1, select("#", ...) do
    output[i] = tovstring(select(i, ...))
  end
  return tconcat(output, "")
end

A.tovstrings = tovstrings

--- Prints out key and value pairs of a table.
--- @param table table
--- @return nil
local function tprint(table)
  for k, v in pairs(table) do
    print(k, v)
  end
end

A.tprint = tprint

--- Tests whether a list starts with one or more elements passed as varargs.
--- @generic T
--- @param from T[]
--- @param ... T
--- @return boolean
local function tstartswith(from, ...)
  for i = 1, select("#", ...) do
    if from[i] ~= select(i, ...) then return false end
  end
  return true
end

A.tstartswith = tstartswith

--- Appends varargs to a list.
--- @generic T
--- @param t T[]
--- @param ... T
--- @return T[]
local function tappend(t, ...)
  local len = #t
  for i = 1, select("#", ...) do
    t[len + i] = select(i, ...)
  end
  return t
end

A.tappend = tappend

--- Returns a subsection of a list.
--- @generic T
--- @param list T[]
--- @param first number Starting index. If negative, counts from the end.
--- @param last number End index. If negative, counts from the end.
--- @return T[]
local function sublist(list, first, last)
  if first < 0 then
    first = 1 + #list + first
  end
  if last < 0 then
    last = 1 + #list + last
  end
  local toreturn = {}
  for i = 0, last - first do
    toreturn[i + 1] = list[i + first]
  end
  return toreturn
end

A.sublist = sublist

--- Throws an error if any argument is nil.
--- @param ... any
--- @return nil
local function assertNotNil(...)
  local failures = {}
  for i = 1, select("#", ...) do
    if select(i, ...) == nil then
      tinsert(failures, tostrings("Arg #", ceil(i / 2), " is nil."))
    end
  end
  if #failures > 0 then error(tconcat(failures, " "), 2) end
  return ...
end

A.assertNotNil = assertNotNil

--- @enum
local TypeCode = {
  Nil      = 1,
  Number   = 2,
  String   = 4,
  Boolean  = 8,
  Table    = 16,
  Function = 32,
  Thread   = 64,
  Userdata = 128,
}
A.TypeCode = TypeCode

--- @param valType type
--- @param typeCode number
--- @return boolean
local function isType(valType, typeCode)
  return (band(typeCode, TypeCode.Nil) ~= 0 and valType == "nil")
      or (band(typeCode, TypeCode.Number) ~= 0 and valType == "number")
      or (band(typeCode, TypeCode.String) ~= 0 and valType == "string")
      or (band(typeCode, TypeCode.Boolean) ~= 0 and valType == "boolean")
      or (band(typeCode, TypeCode.Table) ~= 0 and valType == "table")
      or (band(typeCode, TypeCode.Function) ~= 0 and valType == "function")
      or (band(typeCode, TypeCode.Thread) ~= 0 and valType == "thread")
      or (band(typeCode, TypeCode.Userdata) ~= 0 and valType == "userdata")
end

--- Tests the type of arguments in pairs. Odd-numbered arguments are strings
--- made up of one or more type strings (possible outputs of `type()`),
--- separated by `/`. Even-numbered arguments are the items to match against
--- the preceding type strings.
---
--- If there is an extra odd-numbered argument at the end, it is used as the
--- level of the error thrown if any of the types do not match.
--- @param ... any
--- @return nil
local function assertType(...)
  local failures
  for i = 1, select("#", ...) - 1, 2 do
    local matchType = type(select(i, ...))
    if not isType(matchType, select(i + 1, ...)) then
      failures = failures or {}
      tinsert(failures, tostrings("Arg #", ceil(i / 2), " must be ", matchType, ", is ", isType, "."))
    end
  end
  if failures and #failures > 0 then
    error(tconcat(failures, " "), tonumber(select(-1, ...)) or 2)
  end
end

A.assertType = assertType

--- @generic T, P
--- @param projection string | fun(el: T): P
--- @return (fun(el: T): P), boolean
local function createProjectionFunction(projection)
  if type(projection) ~= "string" then
    return projection, false
  end
  local reverse = false
  if projection:sub(1, 1) == "-" then
    reverse = true
    projection = projection:sub(2)
  end
  if projection == "" then
    return function(el) return el end, reverse
  end
  return function(el) return el[projection] end, reverse
end

--- @generic T
--- @param a T
--- @param b T
--- @return boolean
local function defaultSortFunction(a, b)
  return a < b
end

--- @generic T, P
--- @param val T[]
--- @param projection string | fun(el: T): P
--- @param sortFunc? fun(a: P, b: P): boolean)
--- @return nil
local function nilSort(val, projection, sortFunc)
  local projectionFunction, reverse = createProjectionFunction(projection)
  sortFunc = sortFunc or defaultSortFunction
  sort(val, function(a, b)
    if a ~= nil then a = projectionFunction(a) end
    if b ~= nil then b = projectionFunction(b) end
    if a == nil and b == nil then
      return false
    end
    if a == nil then
      return false
    end
    if b == nil then
      return true
    end
    return reverse ~= sortFunc(a, b)
  end)
end

A.nilSort = nilSort

--- @param val string
--- @return string
local function capitalize(val)
  return val:sub(1, 1):upper() .. val:sub(2):lower()
end

A.capitalize = capitalize

--- @param val number
--- @param places? number
--- @return string
local function abbrev(val, places)
  if places == nil then
    if val >= 1000 then
      places = 2
    else
      places = 0
    end
  end
  local suffix = ""
  if val >= 1000000 then
    val = val / 1000000
    suffix = "m"
  elseif val >= 1000 then
    val = val / 1000
    suffix = "k"
  end
  local place = pow(10, places)
  return (floor(val * place) / place) .. suffix
end

A.abbrev = abbrev

--- @overload fun(list: any[]): any[]
--- @overload fun(...): ...
local function reverse(...)
  local l, t
  if select("#", ...) > 1 then
    l = { ... }
    t = true
  else
    l = ...
  end
  local newL = {}
  for i = getn(l), 1, -1 do tinsert(newL, l[i]) end
  if t then return unpack(newL) else return newL end
end

A.reverse = reverse

--- @overload fun(shouldFlip: boolean, list: any[]): any[]
--- @overload fun(shouldFlip: boolean, ...): ...
local function flip(shouldFlip, ...)
  if shouldFlip then return reverse(...) else return ... end
end

A.flip = flip

--- @param func fun(...): any
--- @param ... any
--- @return fun(...): nil
local function scopify(func, ...)
  local scope
  local scopeCount = select("#", ...)
  if scopeCount > 0 then scope = { ... } end
  return function(...)
    if scope == nil then return func(...) end
    local count = select("#", ...)
    if count == 0 then return func(unpack(scope)) end
    local copy = { unpack(scope) }
    for i = 1, count do
      copy[scopeCount + i - 1] = select(i, ...)
    end
    func(unpack(copy))
  end
end

A.scopify = scopify

--- @generic T
--- @param func fun(...): T
--- @param before any[] | nil
--- @param subArgs any[]
--- @param after any[] | nil
--- @return T ...
local function map(func, before, subArgs, after)
  local r = {}
  local result
  local args = { unpack(before or {}) }
  local slot = #args + 1
  if after then for i = 1, #after do args[slot + i] = after[i] end end
  for i = 1, #subArgs do
    local arg = subArgs[i]
    args[slot] = arg
    result = { func(unpack(args)) }
    if isEmpty(result) then result = nil elseif #result == 1 then result = result[1] end
    r[i] = result
  end
  return unpack(r)
end

A.map = map

--- @class Color
--- @field r number
--- @field g number
--- @field b number
--- @field a number | nil

--- @param col number[] | Color
--- @return number, number, number, number
local function colUnpack(col)
  if isEmpty(col) then
    return 0, 0, 0, 0
  end
  if #col >= 3 then
    return unpack(col)
  end
  local alpha = col.a
  if alpha == nil then
    alpha = 1
  end
  return col.r, col.g, col.b, alpha
end

A.colUnpack = colUnpack

--- @param r number
--- @param g number
--- @param b number
--- @param a? number
--- @return Color
local function colPack(r, g, b, a)
  return { r = r, g = g, b = b, a = a }
end

A.colPack = colPack

--- @param code string
--- @return Color
local function hexToCol(code)
  if code:sub(1, 1) == "#" then code = code:sub(2) end
  if isEmpty(code) then return { r = 1, g = 1, b = 1, a = 1 } end
  return {
    r = tonumber("0x" .. code:sub(1, 2)) / 255,
    g = tonumber("0x" .. code:sub(3, 4)) / 255,
    b = tonumber("0x" .. code:sub(5, 6)) / 255,
    a = 1
  }
end

A.hexToCol = hexToCol


local hexstr = "0123456789abcdef"

--- @param num number
--- @return string
local function numToHex(num)
  local s = ""
  while num > 0 do
    local mod = fmod(num, 16)
    s = hexstr:sub(mod + 1, mod + 1) .. s
    num = floor(num / 16)
  end
  if s == "" then s = "0" end
  return s
end

A.numToHex = numToHex

--- @param col number[] | Color
--- @return string
local function colToHex(col)
  local r, g, b, a = colUnpack(col)
  local s = ""
  local lst = a and { a, r, g, b } or { r, g, b }
  for _, val in ipairs(lst) do
    local val = numToHex(val * 255)
    if #val < 2 then val = "0" .. val end
    s = s .. val
  end
  return s
end

A.colToHex = colToHex

--- @param col number[] | Color
--- @return number
local function colToHue(col)
  local r, g, b = colUnpack(col)
  if r == g and g == b then return 360 end
  local hue
  local minCol = min(r, g, b)
  local maxCol = max(r, g, b)
  local range = maxCol - minCol
  if maxCol == r then
    hue = (g - b) / range
  elseif maxCol == g then
    hue = 2 + (b - r) / range
  else
    hue = 4 + (r - g) / range
  end
  hue = (hue * 60) % 360
  return hue
end

A.colToHue = colToHue

--- @param hue number
--- @return Color
local function hueToCol(hue)
  hue = hue % 360
  if hue == 0 then hue = 360 end
  local r, g, b
  if hue <= 60 then
    r = 1
    g = (hue) / 60
    b = 0
  elseif hue <= 120 then
    r = (120 - hue) / 60
    g = 1
    b = 0
  elseif hue <= 180 then
    r = 0
    g = 1
    b = (hue - 120) / 60
  elseif hue <= 240 then
    r = 0
    g = (240 - hue) / 60
    b = 1
  elseif hue <= 300 then
    r = (hue - 240) / 60
    g = 0
    b = 1
  else
    r = 1
    g = 0
    b = 0.5 + 0.5 * (360 - hue) / 60
  end
  return { r = r, g = g, b = b, a = 1 }
end

A.hueToCol = hueToCol

--- @param text string
--- @param col number[] | Color | string
local function colorify(text, col)
  if type(col) ~= "string" then col = colToHex(col)
  elseif col:sub(1, 1) == "#" then col = col:sub(2)
  end
  if #col == 6 then col = "FF" .. col end
  return "|c" .. col .. tostring(text) .. "|r"
end

A.colorify = colorify

--- @param val string | number
--- @return number | nil
local function getItemID(val)
  local itemString = select(2, GetItemInfo(val))
  if type(itemString) ~= "string" then
    return nil
  end
  local subString = itemString:sub(itemString:find(":") + 1)
  subString = subString:sub(1, subString:find(":") - 1)
  return tonumber(subString)
end

A.getItemID = getItemID

--- @return string
local function keybindmods()
  local text = ""
  if IsShiftKeyDown() then text = "SHIFT-" .. text end
  if IsControlKeyDown() then text = "CTRL-" .. text end
  if IsAltKeyDown() then text = "ALT-" .. text end
  return text
end

A.keybindmods = keybindmods

----------
-- Frames
----------

--- @param button Button
--- @param dW number | nil
--- @param dH number | nil
local function fitToText(button, dW, dH)
  local width, height = button:GetFontString():GetSize()
  button:SetSize(width + (dW or 0), height + (dH or 0))
end

A.fitToText = fitToText

--- @generic T: Button
--- @param button T
--- @param show boolean
--- @param anchor? string
--- @param onHide? fun(button: T): nil
local function tooltip(button, show, anchor, onHide)
  --- @cast button Button
  button:SetMotionScriptsWhileDisabled(show)
  button:SetScript("OnEnter", function(button)
    if not button:IsShown() then return end
    GameTooltip:SetOwner(button, "ANCHOR_" .. (anchor or "NONE"))
    local buttonType = button:GetAttribute("type")
    local subject = buttonType and button:GetAttribute(buttonType)
    if button.tooltip then
      GameTooltip:SetText(button.tooltip)
    elseif buttonType == "spell" then
      if type(subject) ~= "number" then
        subject = select(7, GetSpellInfo(subject))
      end
      GameTooltip:SetSpellByID(subject)
    elseif buttonType == "item" then
      GameTooltip:SetItemByID(subject)
    end
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function(button)
    if not button:IsMouseOver() then
      GameTooltip:FadeOut()
    end
  end)
  button:SetScript("OnHide", function(button)
    if button:IsMouseOver() then
      GameTooltip:FadeOut()
    end
    if onHide then onHide(button) end
  end)
end

A.tooltip = tooltip

-------------------
-- Object-oriented
-------------------

--- @param obj table
--- @param ind table
--- @param noOverride? boolean
local function setIndex(obj, ind, noOverride)
  local meta = getmetatable(obj)
  if meta == nil then
    meta = {}
    setmetatable(obj, meta)
  end
  if noOverride and meta.__index then return end
  meta.__index = ind
end

A.setIndex = setIndex

--- @class Inherits
--- @field _super table
local Inherits = {}

--- @return Inherits
function Inherits:New()
  self.__index = self
  local new = {}
  setmetatable(new, self)
  new._super = self
  return new
end

A.Inherits = Inherits

--- @generic T
--- @param func string | fun(self: T, ...): T
--- @param before any[] | nil
--- @param subArgs any[]
--- @param after any[] | nil
--- @return nil
function Inherits:Map(func, before, subArgs, after)
  if type(func) ~= "function" then func = self[func] end
  before = { self, unpack(before or {}) }
  map(func, before, subArgs, after)
end

--- @param obj table
--- @param ... table
--- @return nil
local function mixin(obj, ...)
  for i = 1, select("#", ...) do
    for k, v in pairs(select(i, ...) or {}) do
      obj[k] = obj[k] or v
    end
  end
end

A.mixin = mixin
Inherits.MixIn = mixin

------------
-- Database
------------

local function emptyIterator() return nil end

--- @param val any
--- @param depth number
--- @param check? fun(el: any): boolean
--- @return (fun(): ...)
local function npairs(val, depth, check)
  if val == nil or type(val) ~= "table" then
    return emptyIterator
  end
  local i = {}
  local done = false

  if depth <= 1 then return function()
      if done then return end
      done = true
      return val
    end
  end

  local subPairs = npairs(val, depth - 1)
  local result = {}

  local function assignNext()
    local subVal = result[depth - 1]
    if subVal == nil or type(subVal) ~= "table" then
      i[depth - 1], i[depth] = nil, nil
      return
    end
    while true do
      i[depth - 1], i[depth] = next(subVal, i[depth - 1])
      if i[depth - 1] == nil then return end
      if not check and i[depth - 1] ~= nil then return end
      if type(check) == "function" and check(i[depth]) then return end
    end
  end

  return function()
    assignNext()
    while not done and i[depth] == nil do
      result = { subPairs() }
      if result[1] == nil then
        done = true
        return
      else
        i = sublist(result, 1, -2)
        assignNext()
      end
    end
    if not done then return unpack(i) end
  end
end

A.npairs = npairs

-----------------
-- Bootstrapping
-----------------

--- @param before function | nil
--- @param oldfunc function | nil
--- @param after function | nil
--- @return nil
local function buildfunc(before, oldfunc, after)
  if type(oldfunc) == "function" then
    if type(before) == "function" then
      if type(after) == "function" then
        return function(...) before(...); oldfunc(...); after(...) end
      else
        return function(...) before(...); oldfunc(...) end
      end
    else
      if type(after) == "function" then
        return function(...) oldfunc(...); after(...) end
      end
    end
  else
    if type(before) == "function" then
      if type(after) == "function" then
        return function(...) before(...); after(...) end
      else
        return function(...) before(...) end
      end
    else
      if type(after) == "function" then
        return function(...) after(...) end
      end
    end
  end
end

A.buildfunc = buildfunc

--- @param parent table
--- @param name string
--- @param before function | nil
--- @param after function | nil
local function overfunc(parent, name, before, after)
  parent[name] = buildfunc(before, parent[name], after)
end

A.overfunc = overfunc


--- @param obj Frame
--- @param script ScriptFrame
--- @param before function | nil
--- @param after function | nil
local function overscript(obj, script, before, after)
  obj:SetScript(script, buildfunc(before, obj:GetScript(script), after))
end

A.overscript = overscript

local fadeUI = UIParent:CreateAnimationGroup()
local fadeUIanim = fadeUI:CreateAnimation("ALPHA")

local Hidden = CreateFrame("FRAME")
Hidden:Hide()

local framestrata = {}
local framelevel = {}
local frameparents = {}

--- @param self Frame
--- @return nil
local function keepHidden(self)
  if self:IsShown() and self:GetNumPoints() and self:GetParent() == Hidden then
    HideUIPanel(self)
    self:Show()
  end
end

--- @param frameName string
--- @return nil
local function disableFrame(frameName)
  local frame = _G[frameName]
  framestrata[frameName] = frame:GetFrameStrata()
  framelevel[frameName] = frame:GetFrameLevel()
  local parent = frame:GetParent()
  if parent == Hidden then return end
  frame:SetParent(Hidden)
  if not frameparents[frameName] then
    frameparents[frameName] = parent
    overscript(frame, "OnEvent", nil, keepHidden)
  end
end

A.disableFrame = disableFrame

--- @param frameName string
--- @return nil
local function enableFrame(frameName)
  local frame = _G[frameName]
  if frame:GetParent() ~= Hidden then return end
  frame:SetParent(frameparents[frameName])
  frame:SetFrameStrata(framestrata[frameName])
  frame:SetFrameLevel(framelevel[frameName])
  if frame:IsShown() then
    ShowUIPanel(frame)
    frame:Raise()
  end
end

A.enableFrame = enableFrame

--- @param frameName string
--- @param display boolean
--- @return nil
local function setFrameEnabled(frameName, display)
  if display then enableFrame(frameName) else disableFrame(frameName) end
end

A.setFrameEnabled = setFrameEnabled
