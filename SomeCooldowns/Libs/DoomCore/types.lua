--- @meta
--- @diagnostic disable:duplicate-doc-alias
--- @diagnostic disable:duplicate-doc-field
--- @diagnostic disable:duplicate-doc-param
--- @diagnostic disable:duplicate-index
--- @diagnostic disable:duplicate-set-field

--- @class Locker: Button
--- @field frames { [string]: Frame | DoomFrame }
--- @field Update fun(self: self): nil
DoomCoreLocker = {}

----------
-- Frames
----------

--- @alias DIRECTION "TOP" | "BOTTOM" | "LEFT" | "RIGHT" | "RIGHT" | "HORIZONTAL" | "VERTICAL"

--- @class FrameSettings
--- @field anchor FramePoint | nil
--- @field background string | nil
--- @field backgroundColor Color | nil
--- @field border string | nil
--- @field borderColor Color | nil
--- @field columnGrowth FramePoint | nil
--- @field edge number | nil
--- @field els Frame[] | nil
--- @field font string | nil
--- @field fontColor Color | nil
--- @field fontSize number | nil
--- @field grow FramePoint | nil
--- @field grow2 FramePoint | nil
--- @field iconSpacing number | nil
--- @field inset number | nil
--- @field limit number | nil
--- @field lock boolean | nil
--- @field max number | nil
--- @field offsetX number | nil
--- @field offsetY number | nil
--- @field padding number | nil
--- @field parent Frame | nil
--- @field rowGrowth FramePoint | nil
--- @field size number | nil
--- @field spacing number | nil
--- @field x number | nil
--- @field y number | nil

--- @class DoomFrame: BackdropTemplate, Frame
--- @field conf FrameSettings
--- @field tex Texture | nil

-----------------
-- Addon handler
-----------------

--- @class DebugConfig
--- @field print boolean | nil

--- @class HandlerCore
--- @field Extras DebugConfig | nil
--- @field _version number

--- @class HandlerSettingsOptions
--- @field handler Handler
--- @field args table
--- @field name? string

--- @class HandlerSettings
--- @field options HandlerSettingsOptions
--- @field debug table | nil
--- @field defaults table | nil
--- @field crawler NodeCrawler
--- @field custom table | nil

--- @class HandlerLib
--- @field db AceDBObject-3.0
--- @field options AceDBOptions-3.0
--- @field registry AceConfigRegistry-3.0
--- @field settings AceConfigDialog-3.0
--- @field masque Masque | nil
--- @meta
--- @diagnostic disable:duplicate-doc-alias
--- @diagnostic disable:duplicate-doc-field
--- @diagnostic disable:duplicate-doc-param
--- @diagnostic disable:duplicate-index
--- @diagnostic disable:duplicate-set-field

--- @class Locker: Button
--- @field frames { [string]: Frame | DoomFrame }
DoomCoreLocker = {}

--- @return nil
function DoomCoreLocker:Update() end

----------
-- Frames
----------

--- @alias DIRECTION "TOP" | "BOTTOM" | "LEFT" | "RIGHT" | "RIGHT" | "HORIZONTAL" | "VERTICAL"

--- @class FrameSettings
--- @field anchor FramePoint | nil
--- @field background string | nil
--- @field backgroundColor Color | nil
--- @field border string | nil
--- @field borderColor Color | nil
--- @field columnGrowth FramePoint | nil
--- @field edge number | nil
--- @field els Frame[] | nil
--- @field font string | nil
--- @field fontColor Color | nil
--- @field fontSize number | nil
--- @field grow FramePoint | nil
--- @field grow2 FramePoint | nil
--- @field iconSpacing number | nil
--- @field inset number | nil
--- @field limit number | nil
--- @field lock boolean | nil
--- @field max number | nil
--- @field offsetX number | nil
--- @field offsetY number | nil
--- @field padding number | nil
--- @field parent Frame | nil
--- @field rowGrowth FramePoint | nil
--- @field size number | nil
--- @field spacing number | nil
--- @field x number | nil
--- @field y number | nil

--- @class DoomFrame: BackdropTemplate, Frame
--- @field conf FrameSettings
--- @field tex Texture | nil
--- @field msq MasqueGroup?

-----------------
-- Addon handler
-----------------

--- @class DebugConfig
--- @field print boolean | nil

--- @class HandlerCore
--- @field Extras DebugConfig | nil
--- @field _version number

--- @class HandlerSettingsOptions
--- @field handler Handler
--- @field args table
--- @field name? string

--- @class HandlerSettings
--- @field options HandlerSettingsOptions
--- @field debug table | nil
--- @field defaults table | nil
--- @field crawler NodeCrawler
--- @field custom table | nil

--- @class HandlerLib
--- @field db AceDBObject-3.0
--- @field options AceDBOptions-3.0
--- @field registry AceConfigRegistry-3.0
--- @field settings AceConfigDialog-3.0
--- @field masque Masque | nil
