--- @meta

COMBATLOG_FILTER_MINE = 0x00004511
COMBATLOG_FILTER_MY_PET = 0x00003111

--- @alias miss "ABSORB" | "BLOCK" |  "DEFLECT" | "DODGE" | "EVADE" | "IMMUNE" | "MISS" | "PARRY" | "REFLECT" | "RESIST"

--- @class Meter
--- @field name string
--- @field icon number

--- @class EffectLog
--- @field amount number
--- @field crit boolean
--- @field over number
--- @field timed number
--- @field cat string | nil
--- @field partial boolean | nil
--- @field miss { [miss]: number } | nil

--- @class LogKey
--- @field kind string
--- @field timed number
--- @field seconds number
--- @field sourceName string
--- @field petMatch boolean
--- @field destGUID string
--- @field spellID string

--- @class Tracker: FrameSettings
--- @field color Color
--- @field duration string
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

--- @class TrackerFrame: DoomFrame
--- @field msq MasqueGroup

--- @class AlertFrame: Button
--- @field Border Texture
--- @field Flash Texture
--- @field NormalTexture Texture
--- @field amount number
--- @field animation AnimationGroup
--- @field crit boolean | nil
--- @field fade Animation
--- @field icon Texture
--- @field highlight AnimationGroup[]
--- @field image Texture | nil
--- @field kind "spell" | "aura" | nil
--- @field meter string
--- @field metername string
--- @field over number
--- @field text FontString
--- @field timed number
--- @field count number
--- @field record number | nil

--- @class Score
--- @field col Color
--- @field icon number
--- @field amount number

--- @class ScoringSettings
--- @field scoreChat boolean
--- @field scoreIcon boolean

--- @class SomeTrackerCore: HandlerCore
--- @field highscores { [string]: Score }
--- @field ["High Scores"] ScoringSettings
--- @field Trackers { [string]: Tracker }

--- @class CorePath
--- @field [1] string Tracker name.
--- @field [2] string Setting name.
--- @field [3]? string Optional nested setting name.
