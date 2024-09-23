--- @meta

--- @class CooldownButton: Button
--- @field Border Texture
--- @field Flash Texture
--- @field NormalTexture Texture
--- @field icon Texture
--- @field active boolean
--- @field cooldown Cooldown
--- @field cooldownFrame Cooldown
local CooldownButton = {}

--- @param attribute string
--- @return any
function CooldownButton:GetAttribute(attribute) end

--- @param offsetTop number?
--- @param offsetBottom number?
--- @param offsetLeft number?
--- @param offsetRight number?
--- @return boolean
function CooldownButton:IsMouseOver(offsetTop, offsetBottom, offsetLeft, offsetRight) end

--- @class CooldownsFrame: DoomFrame
local CooldownsFrame = {}

--- @return CooldownButton
function CooldownsFrame:GetChildren() end

--- @class ListedCooldown
--- @field type "blacklist" | "whitelist"

--- @class SomeCooldownsDebugConfig: DebugConfig
--- @field somebars boolean | nil

--- @class SomeCooldownsCore: HandlerCore, FrameSettings
--- @field Extras SomeCooldownsDebugConfig | nil
--- @field group { [number]: ListedCooldown }
--- @field color Color
--- @field displayItems boolean
--- @field displaySpells boolean
--- @field displayToys boolean
--- @field iconSize number
--- @field recharge boolean
--- @field reverse boolean
--- @field sort "long" | "short"
--- @field text boolean
--- @field tooltip boolean
--- @field tooltipAnchor FramePoint
--- @field tooltipOverride boolean
--- @field xCenter boolean
--- @field yCenter boolean

--- @class SomeCooldownsLib: HandlerLib
--- @field somebars { exports: { item: { [number]: true }, spell: { [number]: true } } }

--- @class CooldownsCorePath
--- @field [1] string Setting name.
--- @field [2]? number Group number.
