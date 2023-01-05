--- @class AlphaAnimation: Animation
--- @field SetFromAlpha fun(self: Animation, alpha: number): nil
--- @field SetToAlpha fun(self: Animation, alpha: number): nil

--- @alias Visibility "auto" | "show" | "hide"

--- @class BarItem
--- @field color Color
--- @field image number

--- @class Bar
--- @field position number
--- @field color Color
--- @field combat Visibility
--- @field noncombat Visibility
--- @field iconAlpha number
--- @field barAlpha number
--- @field sparkAlpha number
--- @field dim1 number
--- @field dim2 number
--- @field watch { [number|string]: BarItem }
--- @field newColor Color
--- @field reverse boolean

--- @class BarGroup: FrameSettings
--- @field add { barType: "item" | "spell" }
--- @field bars { [string]: Bar }
--- @field bg Color
--- @field dim1 number
--- @field dim2 number
--- @field flexible boolean
--- @field iconPos "hide" | "before" | "after"
--- @field iconSize number
--- @field orientation "HORIZONTAL" | "VERTICAL"
--- @field Default Bar

--- @class LastActive
--- @field bar Bar
--- @field name number | string
--- @field data BarItem
--- @field icon number | nil

--- @class TexturedFrame: Frame
--- @field tex Texture

--- @class BarFrame: DoomFrame
--- @field anchor AnchorPoint
--- @field appear AlphaAnimation
--- @field appearGroup AnimationGroup
--- @field bars { [string]: Bar }
--- @field bg Texture
--- @field border { ["TOP" | "BOTTOM" | "LEFT" | "RIGHT"]: Texture }
--- @field button Button
--- @field charges number
--- @field dimX number
--- @field dimY number
--- @field duration number
--- @field fade AlphaAnimation
--- @field fadeGroup AnimationGroup
--- @field fg Texture
--- @field Goals TexturedFrame[]
--- @field group BarGroup
--- @field icon Texture
--- @field lastActive LastActive | nil
--- @field maxCharges number
--- @field Spark TexturedFrame
--- @field start number

--- @class BarGroupFrame: DoomFrame
--- @field button Button
--- @field tex Texture
--- @field slots BarFrame[]
--- @field conf BarGroup

--- @class SomeBarsCore: HandlerCore
--- @field groups { [string]: BarGroup }

--- @class CorePath
--- @field [1] "groups"
--- @field [2] string Group name.
--- @field [3] string Setting name.
--- @field [4] string Optional bar name.
--- @field [5]? string Optional bar setting name.
--- @field [6]? number | string Optional bar item name.
--- @field [7]? string Optional bar item setting name.
