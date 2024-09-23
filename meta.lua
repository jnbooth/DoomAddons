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
