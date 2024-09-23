local _, N = ...

local AceConfigDialog = LibStub("AceConfigDialog-3.0")

--- @class SomeBarsSettings: HandlerSettings
local Settings = {
  options = {
    name = "Groups",
    type = "group",
    args = {
      add = {
        type = "input",
        name = "Add group",
        set = "AddGroup",
        width = "full",
      }
    }
  }
}
N.Settings = Settings

-----------------
-- Settings page
-----------------

local dialogStatus

--- @param groupName string
--- @param group BarGroup
--- @param frame BarGroupFrame
--- @return nil
function Settings:BuildGroupSettings(groupName, group, frame)
  local settingKey = groupName
  local settings = group:BuildSettings(frame)
  settings.name = groupName
  self.options.args[settingKey] = settings

  if not dialogStatus then
    local statusTable = AceConfigDialog:GetStatusTable("Some Bars")
    local groups = statusTable.groups
    if not groups then
      groups = { groups = {} }
      statusTable.groups = groups
    end
    dialogStatus = groups.groups
    if not dialogStatus then
      dialogStatus = {}
      groups.groups = dialogStatus
    end
  end
  dialogStatus[settingKey] = true
end

---------------
-- Debug panel
---------------


Settings.debug = {}
