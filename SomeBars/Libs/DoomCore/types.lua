--- @meta

--- @alias tablekey boolean | number | string

--- @class AceInfo: { [number]: tablekey }
--- @field options table
--- @field arg? any
--- @field handler? table
--- @field type string
--- @field option any
--- @field uiType string
--- @field uiName string

----------
-- Globals
----------

--- @type GameTooltip
GameTooltip = {}

--- @return nil
function ReloadUI() end

--- @class Locker: Button
--- @field frames { [string]: Frame | DoomFrame }
--- @field Update fun(self: Locker): nil
DoomCoreLocker = {}

----------
-- Frames
----------

--- @alias DIRECTION "TOP" | "BOTTOM" | "LEFT" | "RIGHT" | "RIGHT" | "HORIZONTAL" | "VERTICAL"

--- @class FrameSettings
--- @field anchor AnchorPoint | nil
--- @field background string | nil
--- @field backgroundColor Color | nil
--- @field border string | nil
--- @field borderColor Color | nil
--- @field columnGrowth AnchorPoint | nil
--- @field edge number | nil
--- @field els Frame[] | nil
--- @field font string | nil
--- @field fontColor Color
--- @field fontSize number | nil
--- @field frame DoomFrame
--- @field grow AnchorPoint | nil
--- @field grow2 AnchorPoint | nil
--- @field iconSpacing number | nil
--- @field inset number | nil
--- @field limit number | nil
--- @field lock boolean | nil
--- @field max number | nil
--- @field offsetX number | nil
--- @field offsetY number | nil
--- @field padding number | nil
--- @field parent Frame | nil
--- @field rowGrowth AnchorPoint | nil
--- @field size number | nil
--- @field spacing number | nil
--- @field x number | nil
--- @field y number | nil

--- @class DoomFrame: BackdropTemplate, Frame
--- @field conf FrameSettings
--- @field tex Texture | nil

------------
-- Libraries
------------

--- @class MasqueButton
--- @field Icon Texture | nil
--- @field Normal Texture | nil
--- @field Disabled Texture | nil
--- @field Pushed Texture | nil
--- @field Count Texture | nil
--- @field Duration Texture | nil
--- @field Border Texture | nil
--- @field Highlight Texture | nil
--- @field Cooldown Texture | nil
--- @field ChargeCooldown Texture | nil

--- @class MasqueGroup
--- @field AddButton fun(self: MasqueGroup, button: Button, config?: MasqueButton): nil
--- @field ReSkin fun(self: MasqueGroup): nil

--- @class Masque
--- @field Group fun(self: Masque, name: string, subName?: string): MasqueGroup

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
