--- @meta

--- @class Namespace
--- @field Bar BarConstructor
--- @field BarFrame BarFrameConstructor
--- @field BarGroup BarGroupConstructor
--- @field BarGroupFrame BarGroupFrameConstructor
--- @field BarItem BarItemConstructor

--- @class SomeBarsCore: HandlerCore
--- @field Groups { [string]: BarGroup }

--- @class CorePath
--- @field [1] string Group name.
--- @field [2] string Setting name.
--- @field [3] string Optional bar name.
--- @field [4]? string Optional bar setting name.
--- @field [5]? number | string Optional bar item name.
--- @field [6]? string Optional bar item setting name.
