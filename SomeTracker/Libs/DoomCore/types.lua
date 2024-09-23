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

-----------
-- External
-----------

--- @class TexCoords
--- @field [1] number left
--- @field [2] number right
--- @field [3] number top
--- @field [4] number bottom

--- @class AceInfo: { [number]: tablekey }
--- @field options table
--- @field arg? any
--- @field handler? table
--- @field type string
--- @field option any
--- @field uiType string
--- @field uiName string

--- @alias AceOptionDescStyle
---| "inline" if you want the description to show below the option in a GUI (rather than as a tooltip)

--- @alias AceOptionFontSize
---| "large"
---| "medium"
---| "small"
---| number

--- @alias AceOptionChildGroups
---| "tree" Child nodes in a tree control.
---| "tab" Tabs.
---| "select" Dropdown list.

--- @alias AceOptionSelectStyle
---| "dropdown"
---| "radio"

--- @alias AceOptionWidth
---| "double" increase the size of the option
---| "half" decrease the size of the option
---| "full" make the option the full width of the window
---| "normal" use the default widget width defined for the implementation (useful to overwrite widgets that default to full)
---| number multiplier of the default width, i.e. 0.5 equals half, 2.0 equals double

--- @alias methodname string

--- @class AceOptionBase
--- @field name string | fun(info: AceInfo): string Display name for the option.
--- @field desc nil | string | fun(info: AceInfo): nil | string Description for the option (or nil for a self-describing name).
--- @field validate nil | false | string | methodname | fun(info: AceInfo): nil | false | string Validate the input/value before setting it. Return a string (error message) to indicate error.
--- @field confirm nil | boolean | methodname | fun(info: AceInfo): boolean | string Prompt for confirmation before changing a value.
--- @field order nil | number | methodname | fun(info: AceInfo): number Relative position of item [default=100]. 0=first, -1=last.
--- @field disabled nil | boolean | methodname | fun(info: AceInfo): boolean Disabled but visible [default=false].
--- @field hidden nil | boolean | methodname | fun(info: AceInfo): boolean Hidden (but usable if you can get to it, i.e. via commandline) [default=false].
--- @field guiHidden nil | boolean Hide this from graphical UIs (dialog, dropdown) [default=false].
--- @field dialogHidden nil | boolean Hide this from dialog UIs [default=false].
--- @field dropdownHidden nil | boolean Hide this from dropdown UIs [default=false].
--- @field cmdHidden nil | boolean Hide this from commandline [default=false].
--- @field icon nil | number | string | fun(info: AceInfo): number | string Path to icon texture.
--- @field iconCoords nil | TexCoords | methodname | fun(info: AceInfo): TexCoords Arguments to pass to SetTexCoord.
--- @field handler nil | { [methodname]: function } Object on which getter/setter functions are called if they are declared as strings rather than function references.
--- @field width nil | AceOptionWidth In a GUI provide a hint for how wide this option needs to be. Optional support in implementations.

--- @class AceOptionExecute: AceOptionBase A button that runs a function.
--- @field type "execute"
--- @field func methodname | fun(info: AceInfo): nil Function to execute.
--- @field image nil | number | string | fun(info: AceInfo): nil | number | string, nil | number, nil | number Path to image texture. If set, displayed by the option in place of a button. If a function, can optionally return imageWidth and imageHeight as 2nd and 3rd return values.
--- @field imageCoords nil | TexCoords | methodname | fun(info: AceInfo): TexCoords Arguments to pass to SetTexCoord.
--- @field imageWidth nil | number Width of the displayed image.
--- @field imageHeight nil | number Width of the displayed image.

---@class AceOptionInput: AceOptionBase A simple text input.
--- @field type "input"
--- @field get nil | methodname | fun(info: AceInfo): string Getter function.
--- @field set nil | methodname | fun(info: AceInfo, state: string): nil Setter function.
--- @field multiline nil | boolean | integer If true, will be shown as a multiline editbox. Integer = # of lines in editbox.
--- @field pattern nil | string Optional validation pattern. (Use the validation field for more advanced checks!)
--- @field usage nil | string Usage string. Displayed if pattern mismatches and in console help messages.
--- @field dialogControl nil | string Custom GUI control.

--- @class AceOptionToggle: AceOptionBase A simple checkbox.
--- @field type "toggle"
--- @field get nil | methodname | fun(info: AceInfo): boolean | nil Getter function.
--- @field set nil | methodname | fun(info: AceInfo, state: boolean | nil): nil Setter function.
--- @field descStyle nil | AceOptionDescStyle
--- @field tristate nil | boolean Make the toggle a tri-state checkbox [default=false]. Values are cycled through unchecked (false), checked (true), greyed (nil) - in that order.
--- @field image nil | number | string | fun(info: AceInfo): nil | number | string, nil | number, nil | number Path to image texture. If set, displayed by the option.
--- @field imageCoords nil | TexCoords | methodname | fun(info: AceInfo): TexCoords Arguments to pass to SetTexCoord.

--- @class AceOptionRange: AceOptionBase A slider for configuring numeric values in a specific range.
--- @field type "range"
--- @field get nil | methodname | fun(info: AceInfo): number Getter function.
--- @field set nil | methodname | fun(info: AceInfo, state: number): nil Setter function.
--- @field min nil | number Minimum value.
--- @field max nil | number Maximum value.
--- @field softMin nil | number "Soft" minimum value. Used by the UI for a convenient limit while allowing manual input of values up to min.
--- @field softMax nil | number "Soft" maximum value. Used by the UI for a convenient limit while allowing manual input of values up to max.
--- @field step nil | number Step value: "smaller than this will break the code". Requires valid values for min and max.
--- @field bigStep nil | number A more generally-useful step size. Support in UIs is optional.
--- @field isPercent nil | boolean Represent e.g. 1.0 as "100%", etc. [default=false].

--- @class AceOptionSelect: AceOptionBase Only one of the values can be selected. In a dropdown menu implementation it would likely be a radio group, in a dialog likely a dropdown combobox.
--- @field type "select"
--- @field get nil | methodname | fun(info: AceInfo): any Getter function.
--- @field set nil | methodname | fun(info: AceInfo, val: any): nil Setter function.
--- @field values { [string]: any } | fun(info: AceInfo): { [string]: any } Key value pair table to choose from. Key is the value passed to "set", value is the string displayed.
--- @field sorting nil | string[] | fun(info: AceInfo): nil | string[] Optional sorted array with the keys of the values table as values to sort the options.
--- @field style nil | AceOptionSelectStyle
--- @field dialogControl nil | string Custom GUI control. Cannot be used if style = "radio".

--- @class AceOptionMultiSelect: AceOptionBase Multiple "toggle" elements condensed into a group of checkboxes, or something else that makes sense in the interface.
--- @field type "multiselect"
--- @field get nil | methodname | fun(info: AceInfo, key: string): any Getter function.
--- @field set nil | methodname | fun(info: AceInfo, key: string, state: any): nil Setter function.
--- @field values { [string]: any } | fun(info: AceInfo): { [string]: any } Key value pair table to choose from. Key is the value passed to "set", value is the string displayed.
--- @field tristate nil | boolean Make the checkmarks tri-state [default=false]. Values are cycled through unchecked (false), checked (true), greyed (nil) - in that order.
--- @field style nil | AceOptionSelectStyle
--- @field dialogControl nil | string Custom GUI control.

--- @class AceOptionColor: AceOptionBase Opens a color picker form.
--- @field type "color"
--- @field get nil | methodname | fun(info: AceInfo): number, number, number, number | nil Getter function. r, g, b, a.
--- @field set nil | methodname | fun(info: AceInfo, r: number, g: number, b: number, a: number): nil Setter function.
--- @field hasAlpha nil | boolean | fun(info: AceInfo): boolean Indicates if alpha is adjustable [default=false]. If false or nil, alpha will always be set() as 1.0.

--- @class AceOptionKeybinding: AceOptionBase
--- @field type "keybinding"
--- @field get nil | methodname | fun(info: AceInfo): string Getter function. r, g, b, a.
--- @field set nil | methodname | fun(info: AceInfo, binding: string): nil Setter function.

--- @class AceOptionHeader: AceOptionBase A heading that displays its name field. In a dialog UI it provides a break in the layout.
--- @field type "header"

--- @class AceOptionDescription: AceOptionBase A paragraph of text to appear next to other options. Name is the text to display.
--- @field type "description"
--- @field fontSize nil | AceOptionFontSize Size of the text [default="small"].
--- @field image nil | number | string | fun(info: AceInfo): nil | number | string, nil | number, nil | number Path to image texture. If set, displayed in front of the text. If a function, can optionally return imageWidth and imageHeight as 2nd and 3rd return values.
--- @field imageCoords nil | TexCoords | methodname | fun(info: AceInfo): TexCoords Arguments to pass to SetTexCoord.
--- @field imageWidth nil | number Width of the displayed image.
--- @field imageHeight nil | number Width of the displayed image.

--- @class AceOptionGroup: AceOptionBase
--- @field type "group"
--- @field get nil | methodname | fun(info: AceInfo): any, number | nil, number | nil, number | nil Getter function.
--- @field set nil | methodname | fun(info: AceInfo, val: any, n1: number | nil, n2: number | nil, n3: number | nil): nil Setter function.
--- @field args { [string]: AceOption }
--- @field plugins nil | { [string]: { [string]: AceOption } } Allows modules and libraries to easily add more content to an addon's options table.
--- @field childGroups nil | AceOptionChildGroups Decides how children groups are displayed [default="tree"].
--- @field inline nil | boolean Show as a bordered box in a dialog UI, or at the parent's level with a separate heading in commandline and dropdown UIs.
--- @field cmdInline nil | boolean Like inline, but only obeyed by command line.
--- @field guiInline nil | boolean Like inline, but only obeyed by graphical UI.
--- @field dropdownInline nil | boolean Like inline, but only obeyed by dropdown UI.
--- @field dialogInline nil | boolean Like inline, but only obeyed by dialog UI.

--- @alias AceOption
---| AceOptionExecute
---| AceOptionInput
---| AceOptionToggle
---| AceOptionRange
---| AceOptionSelect
---| AceOptionMultiSelect
---| AceOptionColor
---| AceOptionKeybinding
---| AceOptionHeader
---| AceOptionDescription
---| AceOptionGroup
