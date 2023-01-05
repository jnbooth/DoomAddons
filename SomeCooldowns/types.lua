--- @meta

NUM_BAG_SLOTS = 4

--- @param button Button
--- @return nil
function ActionButton_HideOverlayGlow(button) end

--- @param button Button
--- @return nil
function ActionButton_ShowOverlayGlow(button) end

--- @class ArkInventory
ArkInventory = {}

--- @return boolean
function ArkInventory.CheckPlayerHasControl() end

--- @class CooldownButton: Button
--- @field Border Texture
--- @field Flash Texture
--- @field NormalTexture Texture
--- @field icon Texture
--- @field active boolean
--- @field GetAttribute fun(self: CooldownButton, attribute: string): any
--- @field cooldown Cooldown
--- @field cooldownFrame Cooldown
--- @field IsMouseOver fun(self: CooldownButton, offsetTop?: number, offsetBottom?: number, offsetLeft?: number, offsetRight?: number): boolean

--- @class CooldownsFrame: DoomFrame
--- @field GetChildren fun(self: CooldownsFrame): CooldownButton

--- @class ListedCooldown
--- @field type "blacklist" | "whitelist"

--- @class SomeCooldownsDebugConfig: DebugConfig
--- @field somebars boolean | nil

--- @class SomeCooldownsCore: HandlerCore, FrameSettings
--- @field _debug SomeCooldownsDebugConfig | nil
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
--- @field tooltipAnchor AnchorPoint
--- @field tooltipOverride boolean
--- @field xCenter boolean
--- @field yCenter boolean

--- @class SomeCooldownsLib: HandlerLib
--- @field somebars { exports: { [string]: (number|string)[] } }

--- @class CorePath
--- @field [1] string Setting name.
--- @field [2]? number Group number.
