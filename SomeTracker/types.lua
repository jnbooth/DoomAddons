--- @meta

COMBATLOG_FILTER_MINE = 0x00004511
COMBATLOG_FILTER_MY_PET = 0x00003111

--- @alias miss "ABSORB" | "BLOCK" |  "DEFLECT" | "DODGE" | "EVADE" | "IMMUNE" | "MISS" | "PARRY" | "REFLECT" | "RESIST"

--- @class Meter
--- @field name string
--- @field icon number

--- @class EffectLog
--- @field amount number | nil
--- @field crit boolean | nil
--- @field over number | nil
--- @field timed number | nil
--- @field cat string | nil
--- @field partial boolean | nil
--- @field miss { [miss]: number } | nil

--- @class LogKey
--- @field kind string | nil
--- @field timed number | nil
--- @field seconds number | nil
--- @field sourceName string | nil
--- @field petMatch boolean | nil
--- @field destGUID string | nil
--- @field spellID string | nil

--- @class Tracker: FrameSettings
--- @field color Color
--- @field duration number
--- @field enabled boolean
--- @field grow "TOP" | "BOTTOM"
--- @field iconSize number
--- @field markCrits boolean
--- @field misses "all" | "total" | "none"
--- @field missType { [miss]: boolean }
--- @field offsetX number
--- @field offsetY number
--- @field over "include" | "exclude" | "additional"
--- @field related boolean
--- @field shadow Color
--- @field specialShadow Color
--- @field trackerType "damage" | "healing"
--- @field overrideColor boolean
--- @field aura { [string]: Color }
--- @field spell { [string]: Color }
--- @field ignore { [string]: boolean }

--- @class ButtonPool
--- @field frame TrackerFrame
--- @field name string
--- @field size number
local ButtonPool = {}

--- @return AlertFrame
function ButtonPool:Acquire() end

--- @param button AlertFrame
function ButtonPool:Release(button) end

function ButtonPool:ReleaseAll() end

--- @return fun(): AlertFrame, boolean
function ButtonPool:EnumerateActive() end

--- @return fun(): number, AlertFrame
function ButtonPool:EnumerateInactive() end

--- @param button AlertFrame
--- @return AlertFrame?
function ButtonPool:GetNextActive(button) end

--- @param button AlertFrame
--- @return AlertFrame?
function ButtonPool:GetNextInactive(button) end

--- @param button AlertFrame
--- @return boolean
function ButtonPool:IsActive(button) end

--- @return number
function ButtonPool:GetNumActive() end

function ButtonPool:SetResetDisallowedIfNew() end

--- @class TrackerFrame: DoomFrame
--- @field msq MasqueGroup
--- @field count number
--- @field pool ButtonPool

--- @class AlertFrame: Button
--- @field Border Texture
--- @field Flash Texture
--- @field NormalTexture Texture
--- @field amount number
--- @field animation AnimationGroup
--- @field crit boolean | nil
--- @field displayCrit boolean | nil
--- @field fade Animation
--- @field icon Texture
--- @field image Texture | nil
--- @field kind "spell" | "aura" | nil
--- @field meter string
--- @field metername string
--- @field over number
--- @field text FontString
--- @field timed number
--- @field count number

--- @class SomeTrackerCore: HandlerCore
--- @field Trackers { [string]: Tracker }

--- @class TrackersCorePath
--- @field [1] string Tracker name.
--- @field [2] string Setting name.
--- @field [3]? string Optional nested setting name.
