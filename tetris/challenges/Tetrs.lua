require 'funcs'

local GameMode = require 'tetris.modes.gamemode'
local Piece = require 'tetris.components.piece'
local Grid = require 'tetris.components.grid'
local Randomizer = require 'tetris.randomizers.randomizer'
local Bag7Randomizer = require 'tetris.randomizers.bag7noI'
local MarathonGF = require 'tetris.modes.marathon_gf'

local TetrsChallenge = MarathonGF:extend()

TetrsChallenge.name = "Tetrs"
TetrsChallenge.hash = "Tetrs"
TetrsChallenge.mode = "MarathonGF"
TetrsChallenge.ruleset = "Standard"
TetrsChallenge.tagline = "Where's the long bar? Seriously, I can't find it."
TetrsChallenge.description = "Complete a 150-line Marathon...without the I piece!"

function TetrsChallenge:new()

    TetrsChallenge.super:new()
  self.randomizer = Bag7Randomizer()
  self.next_queue_length = 6
end

return TetrsChallenge
