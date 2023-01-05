local _, N = ...
--- @class HighScores
local HighScores = {}
N.HighScores = HighScores

local pairs, print, tostring = pairs, print, tostring
local LibStub = LibStub

local A = LibStub("Abacus-2.0")
local scores
local options

--- @return nil
local function clearScores()
  local handler = options.handler
  handler.core.highscores = {}
  HighScores:Load(handler, handler.core.highscores)
end

--- @return nil
local function resetOptions()
  options = {
    name = "scoring",
    get = "ConfGet",
    set = "ConfSet",
    type = "group",
    args = {
      output = {
        type = "description",
        name = "Output:",
        width = "half",
        fontSize = "medium",
        order = 10
      },
      scoreChat = {
        type = "toggle",
        name = "Chat",
        width = "half",
        order = 11
      },
      scoreIcon = {
        type = "toggle",
        name = "Flash icon",
        order = 12
      },
      space = {
        type = "description",
        name = "",
        order = 13
      },
      clear = {
        func = clearScores,
        type = "execute",
        name = "Delete all",
        order = 14
      },
      sep = {
        type = "header",
        name = "Scores",
        width = "full",
        order = 20
      }
    }
  }
end

resetOptions()

local lib = {}
lib.registry = LibStub("AceConfigRegistry-3.0")
lib.settings = LibStub("AceConfigDialog-3.0")

lib.registry:RegisterOptionsTable("Some Tracker: High Scores", options)

--- @param name string
--- @param score Score
function HighScores:Display(name, score)
  options.args[name .. "_label"] = {
    type = "description",
    name = A.colorify(name, score.col),
    fontSize = "medium",
    image = tostring(score.icon),
    imageWidth = 16,
    imageHeight = 16,
    width = "double",
    order = 100 + (1000000000 - score.amount) + A.orderNum(name)
  }
  options.args[name] = {
    type = "description",
    fontSize = "medium",
    name = A.colorify(A.abbrev(score.amount), score.col),
    order = 100.001 + (1000000000 - score.amount) + A.orderNum(name),
    width = "half"
  }
end

--- @param handler Handler
--- @param newDB { [string]: Score }
--- @return nil
function HighScores:Load(handler, newDB)
  resetOptions()
  options.handler = handler
  lib.registry:RegisterOptionsTable("Some Tracker: High Scores", options)
  scores = newDB

  for scoreName, score in pairs(scores) do
    self:Display(scoreName, score)
  end
end

--- @param name string
--- @param amount number
--- @param icon number
--- @param col Color
--- @return boolean
function HighScores:Score(name, amount, icon, col)
  if not scores then
    return false
  end
  if scores[name] and scores[name].amount > amount then
    return false
  end
  scores[name] = { amount = amount, icon = icon, col = col }
  self:Display(name, scores[name])
  if options.handler:ConfGet({ "scoring", "scoreChat" }) then
    print(A.colorify("New high score of " .. A.abbrev(amount) .. " for |T" .. icon .. ":TextHeight|t" .. name .. "!",
      "00ff00"))
  end
  return true
end

--- @param name string
--- @return number | nil
function HighScores:GetScore(name)
  if not scores or not name then return end
  local score = scores[name]
  if not score then return 0 end
  return score.amount
end
