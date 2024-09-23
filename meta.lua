--- @meta

--- @alias tablekey boolean | number | string

----------
-- Globals
----------

--- @return nil
function ReloadUI() end

NUM_BAG_SLOTS = 4

--- @class AlphaAnimation: Animation
local AlphaAnimation = {}

--- @param alpha number
--- @return nil
function AlphaAnimation:SetFromAlpha(alpha) end

--- @param alpha number
--- @return nil
function AlphaAnimation:SetToAlpha(alpha) end

--- @generic P, T
--- @param acquire fun(pool: P): T
--- @param release fun(pool: P, resource: T)
--- @return P
function CreateObjectPool(acquire, release) end

--- @class ObjectPool<T>
local ObjectPool = {}

--- @generic T
--- @param self ObjectPool<T>
--- @return T
function ObjectPool:Acquire() end

--- @generic T
--- @param self ObjectPool<T>
--- @param resource T
function ObjectPool:Release(resource) end

--- @generic T
--- @param self ObjectPool<T>
function ObjectPool:ReleaseAll() end

--- @generic T
--- @param self ObjectPool<T>
--- @return fun(): T, boolean
function ObjectPool:EnumerateActive() end

--- @generic T
--- @param self ObjectPool<T>
--- @return fun(): number, T
function ObjectPool:EnumerateInactive() end

--- @generic T
--- @param self ObjectPool<T>
--- @param resource T
--- @return T?
function ObjectPool:GetNextActive(resource) end

--- @generic T
--- @param self ObjectPool<T>
--- @param resource T
--- @return T?
function ObjectPool:GetNextInactive(resource) end

--- @generic T
--- @param self ObjectPool<T>
--- @param resource T
--- @return boolean
function ObjectPool:IsActive(resource) end

--- @generic T
--- @param self ObjectPool<T>
--- @return number
function ObjectPool:GetNumActive() end

--- @generic T
--- @param self ObjectPool<T>
function ObjectPool:SetResetDisallowedIfNew() end

------------
-- Libraries
------------

--- @class ArkInventory
ArkInventory = {}

--- @return boolean
function ArkInventory.CheckPlayerHasControl() end

--- @class MasqueButton
--- @field Icon Texture?
--- @field Normal Texture?
--- @field Disabled Texture?
--- @field Pushed Texture?
--- @field Count Texture?
--- @field Duration Texture?
--- @field Border Texture?
--- @field Highlight Texture?
--- @field Cooldown Texture?
--- @field ChargeCooldown Texture?

--- @class MasqueGroup
--- @field AddButton fun(self: MasqueGroup, button: Button, config?: MasqueButton): nil
--- @field ReSkin fun(self: MasqueGroup): nil

--- @class Masque
--- @field Group fun(self: Masque, name: string, subName?: string): MasqueGroup

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

--- @alias AceOptionType
---| "execute"
---| "input"
---| "toggle"
---| "range"
---| "select"
---| "multiselect"
---| "color"
---| "keybinding"
---| "header"
---| "description"
---| "group"

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

--- @class AceOption
--- @field type AceOptionType
--- @field name string | fun(info: AceInfo): string Display name for the option.
--- @field desc nil | string | fun(info: AceInfo): nil | string Description for the option (or nil for a self-describing name).
--- @field validate nil | false | string | methodname | fun(info: AceInfo): nil | false | string Validate the input/value before setting it. Return a string (error message) to indicate error.
--- @field confirm nil | boolean | methodname | fun(info: AceInfo): boolean | string Prompt for confirmation before changing a value.
--- @field order nil | number | methodname | fun(info: AceInfo): number Relative position of item [default=100]. 0=first, -1=last.
--- @field disabled nil | boolean | methodname | fun(info: AceInfo): boolean Disabled but visible [default=false].
--- @field hidden nil | boolean | methodname | fun(info: AceInfo): boolean Hidden (but usable if you can get to it, i.e. via commandline) [default=false].
--- @field guiHidden boolean? Hide this from graphical UIs (dialog, dropdown) [default=false].
--- @field dialogHidden boolean? Hide this from dialog UIs [default=false].
--- @field dropdownHidden boolean? Hide this from dropdown UIs [default=false].
--- @field cmdHidden boolean? Hide this from commandline [default=false].
--- @field icon nil | number | string | fun(info: AceInfo): number | string Path to icon texture.
--- @field iconCoords nil | TexCoords | methodname | fun(info: AceInfo): TexCoords Arguments to pass to SetTexCoord.
--- @field handler { [methodname]: function }? Object on which getter/setter functions are called if they are declared as strings rather than function references.
--- @field width AceOptionWidth? In a GUI provide a hint for how wide this option needs to be. Optional support in implementations.

--- @class AceOptionExecute: AceOption A button that runs a function.
--- @field type "execute"
--- @field func methodname | fun(info: AceInfo): nil Function to execute.
--- @field image nil | number | string | fun(info: AceInfo): nil | number | string, nil | number, nil | number Path to image texture. If set, displayed by the option in place of a button. If a function, can optionally return imageWidth and imageHeight as 2nd and 3rd return values.
--- @field imageCoords nil | TexCoords | methodname | fun(info: AceInfo): TexCoords Arguments to pass to SetTexCoord.
--- @field imageWidth number? Width of the displayed image.
--- @field imageHeight number? Width of the displayed image.

---@class AceOptionInput: AceOption A simple text input.
--- @field type "input"
--- @field get nil | methodname | fun(info: AceInfo): string Getter function.
--- @field set nil | methodname | fun(info: AceInfo, state: string): nil Setter function.
--- @field multiline nil | boolean | integer If true, will be shown as a multiline editbox. Integer = # of lines in editbox.
--- @field pattern string? Optional validation pattern. (Use the validation field for more advanced checks!)
--- @field usage string? Usage string. Displayed if pattern mismatches and in console help messages.
--- @field dialogControl string? Custom GUI control.

--- @class AceOptionToggle: AceOption A simple checkbox.
--- @field type "toggle"
--- @field get nil | methodname | fun(info: AceInfo): boolean | nil Getter function.
--- @field set nil | methodname | fun(info: AceInfo, state: boolean | nil): nil Setter function.
--- @field descStyle AceOptionDescStyle?
--- @field tristate boolean? Make the toggle a tri-state checkbox [default=false]. Values are cycled through unchecked (false), checked (true), greyed (nil) - in that order.
--- @field image nil | number | string | fun(info: AceInfo): nil | number | string, nil | number, nil | number Path to image texture. If set, displayed by the option.
--- @field imageCoords nil | TexCoords | methodname | fun(info: AceInfo): TexCoords Arguments to pass to SetTexCoord.

--- @class AceOptionRange: AceOption A slider for configuring numeric values in a specific range.
--- @field type "range"
--- @field get nil | methodname | fun(info: AceInfo): number Getter function.
--- @field set nil | methodname | fun(info: AceInfo, state: number): nil Setter function.
--- @field min number? Minimum value.
--- @field max number? Maximum value.
--- @field softMin number? "Soft" minimum value. Used by the UI for a convenient limit while allowing manual input of values up to min.
--- @field softMax number? "Soft" maximum value. Used by the UI for a convenient limit while allowing manual input of values up to max.
--- @field step number? Step value: "smaller than this will break the code". Requires valid values for min and max.
--- @field bigStep number? A more generally-useful step size. Support in UIs is optional.
--- @field isPercent boolean? Represent e.g. 1.0 as "100%", etc. [default=false].

--- @class AceOptionSelect: AceOption Only one of the values can be selected. In a dropdown menu implementation it would likely be a radio group, in a dialog likely a dropdown combobox.
--- @field type "select"
--- @field get nil | methodname | fun(info: AceInfo): any Getter function.
--- @field set nil | methodname | fun(info: AceInfo, val: any): nil Setter function.
--- @field values { [string]: any } | fun(info: AceInfo): { [string]: any } Key value pair table to choose from. Key is the value passed to "set", value is the string displayed.
--- @field sorting nil | string[] | fun(info: AceInfo): nil | string[] Optional sorted array with the keys of the values table as values to sort the options.
--- @field style AceOptionSelectStyle?
--- @field dialogControl string? Custom GUI control. Cannot be used if style = "radio".

--- @class AceOptionMultiSelect: AceOption Multiple "toggle" elements condensed into a group of checkboxes, or something else that makes sense in the interface.
--- @field type "multiselect"
--- @field get nil | methodname | fun(info: AceInfo, key: string): any Getter function.
--- @field set nil | methodname | fun(info: AceInfo, key: string, state: any): nil Setter function.
--- @field values { [string]: any } | fun(info: AceInfo): { [string]: any } Key value pair table to choose from. Key is the value passed to "set", value is the string displayed.
--- @field tristate boolean? Make the checkmarks tri-state [default=false]. Values are cycled through unchecked (false), checked (true), greyed (nil) - in that order.
--- @field style AceOptionSelectStyle?
--- @field dialogControl string? Custom GUI control.

--- @class AceOptionColor: AceOption Opens a color picker form.
--- @field type "color"
--- @field get nil | methodname | fun(info: AceInfo): number, number, number, number | nil Getter function. r, g, b, a.
--- @field set nil | methodname | fun(info: AceInfo, r: number, g: number, b: number, a: number): nil Setter function.
--- @field hasAlpha nil | boolean | fun(info: AceInfo): boolean Indicates if alpha is adjustable [default=false]. If false or nil, alpha will always be set() as 1.0.

--- @class AceOptionKeybinding: AceOption
--- @field type "keybinding"
--- @field get nil | methodname | fun(info: AceInfo): string Getter function. r, g, b, a.
--- @field set nil | methodname | fun(info: AceInfo, binding: string): nil Setter function.

--- @class AceOptionHeader: AceOption A heading that displays its name field. In a dialog UI it provides a break in the layout.
--- @field type "header"

--- @class AceOptionDescription: AceOption A paragraph of text to appear next to other options. Name is the text to display.
--- @field type "description"
--- @field fontSize AceOptionFontSize? Size of the text [default="small"].
--- @field image nil | number | string | fun(info: AceInfo): nil | number | string, nil | number, nil | number Path to image texture. If set, displayed in front of the text. If a function, can optionally return imageWidth and imageHeight as 2nd and 3rd return values.
--- @field imageCoords nil | TexCoords | methodname | fun(info: AceInfo): TexCoords Arguments to pass to SetTexCoord.
--- @field imageWidth number? Width of the displayed image.
--- @field imageHeight number? Width of the displayed image.

--- @class AceOptionGroup: AceOption
--- @field type "group"
--- @field args { [string]: AnyAceOption }
--- @field plugins nil | { [string]: { [string]: AnyAceOption } } Allows modules and libraries to easily add more content to an addon's options table.
--- @field childGroups AceOptionChildGroups? Decides how children groups are displayed [default="tree"].
--- @field inline boolean? Show as a bordered box in a dialog UI, or at the parent's level with a separate heading in commandline and dropdown UIs.
--- @field cmdInline boolean? Like inline, but only obeyed by command line.
--- @field guiInline boolean? Like inline, but only obeyed by graphical UI.
--- @field dropdownInline boolean? Like inline, but only obeyed by dropdown UI.
--- @field dialogInline boolean? Like inline, but only obeyed by dialog UI.

--- @alias AnyAceOption
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
