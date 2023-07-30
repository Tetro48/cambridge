local Sequence = require 'tetris.randomizers.fixed_sequence'
local binser   = require 'libs.binser'
local sha2     = require 'libs.sha2'

local ReplayScene = Scene:extend()

ReplayScene.title = "Replay"

local savestate_frames = nil
local state_loaded = false

function ReplayScene:new(replay, game_mode, ruleset)
	config.gamesettings = replay["gamesettings"]
	if replay["delayed_auto_shift"] then config.das = replay["delayed_auto_shift"] end
	if replay["auto_repeat_rate"] then config.arr = replay["auto_repeat_rate"] end
	if replay["das_cut_delay"] then config.dcd = replay["das_cut_delay"] end
	love.math.setRandomSeed(replay["random_low"], replay["random_high"])
	love.math.setRandomState(replay["random_state"])
	self.sha_tbl = {mode = sha2.sha256(binser.s(game_mode)), ruleset = sha2.sha256(binser.s(ruleset))}
	self.retry_replay = replay
	self.retry_mode = game_mode
	self.retry_ruleset = ruleset
	self.secret_inputs = replay["secret_inputs"]
	self.replay = deepcopy(replay)
	self.game = game_mode(self.secret_inputs, self.replay.properties)
	self.game.save_replay = false
	self.ruleset = ruleset(self.game)
	self.game:initialize(self.ruleset)
	self.inputs = {
		left=false,
		right=false,
		up=false,
		down=false,
		rotate_left=false,
		rotate_left2=false,
		rotate_right=false,
		rotate_right2=false,
		rotate_180=false,
		hold=false,
	}
	self.paused = false
	self.frames = 0
	self.relative_frames = 0
	self.game.pause_count = replay["pause_count"]
	self.game.pause_time = replay["pause_time"]
	self.replay_index = 1
	self.replay_speed = 1
	self.show_invisible = false
	DiscordRPC:update({
		details = "Viewing a replay",
		state = self.game.name,
		largeImageKey = "ingame-"..self.game:getBackground().."00"
	})
end

function ReplayScene:replayCutoff()
	self.retry_replay["inputs"][self.replay_index]["frames"] = self.relative_frames
	for i = self.replay_index + 1, #self.retry_replay["inputs"] do
		self.retry_replay.inputs[i] = nil
	end
end

function ReplayScene:update()
	local frames_left = self.replay_speed
	local pre_sfx_volume
	if TAS_mode and state_loaded then
		pre_sfx_volume = config.sfx_volume
		config.sfx_volume = 0	--This is to stop blasting your ears every time you load a state.
		frames_left = savestate_frames
	end
	if not self.paused or frame_steps > 0 then
		if frame_steps > 0 then
			self.game.ineligible = self.rerecord or self.game.ineligible
			frame_steps = frame_steps - 1
		end
		while frames_left > 0 do
			frames_left = frames_left - 1
			if not self.rerecord then
				self.inputs = self.replay["inputs"][self.replay_index]["inputs"]
				self.replay["inputs"][self.replay_index]["frames"] = self.replay["inputs"][self.replay_index]["frames"] - 1
				self.relative_frames = self.relative_frames + 1
				self.frames = self.frames + 1
				if self.replay["inputs"][self.replay_index]["frames"] == 0 and self.replay_index < #self.replay["inputs"] then
					self.replay_index = self.replay_index + 1
					self.relative_frames = 1
				end
			end
			local input_copy = {}
			for input, value in pairs(self.inputs) do
				input_copy[input] = value
			end
			self.game:update(input_copy, self.ruleset)
			self.game.grid:update()
		end
	end
	if state_loaded then
		state_loaded = false
		config.sfx_volume = pre_sfx_volume --Returns the volume to normal.
		self.paused = true
	end
	DiscordRPC:update({
		details = self.rerecord and self.game.rpc_details or ("Viewing a".. (self.replay["toolassisted"] and " tool-assisted" or "") .." replay"),
		state = self.game.name,
		largeImageKey = "ingame-"..self.game:getBackground().."00"
	})
	
	if love.thread.getChannel("savestate"):peek() == "save" then
		love.thread.getChannel("savestate"):clear()
		savestate_frames = self.frames
		print("State saved at frame "..self.frames)
	end

	if love.thread.getChannel("savestate"):peek() == "load" then
		love.thread.getChannel("savestate"):clear()
		if savestate_frames == nil then
			print("Load the state first. Press F4 for that. Alt-F4 will close the game, so, keep that in mind.")
			return
		end
		--restarts like usual, but not really.
		self.game:onExit()
		scene = ReplayScene(
			self.retry_replay, self.retry_mode,
			self.retry_ruleset, self.secret_inputs
		)
		state_loaded = true
	end
end

function ReplayScene:render()
	self.game:draw(self.paused)
	if self.rerecord then
		return
	end
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setFont(font_3x5_3)
	if self.replay["toolassisted"] then
		love.graphics.printf("TAS REPLAY", 0, 0, 635, "right")
	else
		love.graphics.printf("REPLAY", 0, 0, 635, "right")
	end
	local pauses_y_coordinate = 23
	if self.replay_speed > 1 then
		pauses_y_coordinate = pauses_y_coordinate + 20
		love.graphics.printf(self.replay_speed.."X", 0, 20, 635, "right")
	end
	love.graphics.setFont(font_3x5_2)
	if self.game.pause_time and self.game.pause_count then
		if self.game.pause_time > 0 or self.game.pause_count > 0 then
			love.graphics.printf(string.format(
				"%d PAUSE%s (%s)",
				self.game.pause_count,
				self.game.pause_count == 1 and "" or "S",
				formatTime(self.game.pause_time)
			), 0, pauses_y_coordinate, 635, "right")
		end
	else
		love.graphics.printf("?? PAUSES (--:--.--)", 0, pauses_y_coordinate, 635, "right")
	end
	if self.show_invisible then 
		self.game.grid:draw()
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.setFont(font_3x5_3)
		love.graphics.printf("SHOW INVIS", 64, 60, 160, "center")
	end
end

local movement_directions = {"left", "right", "down", "up"}

function ReplayScene:onInputPress(e)
	if (
		e.input == "menu_back" or
		e.input == "menu_decide" or
		e.input == "mode_exit" or
		e.input == "retry"
 	) then
		switchBGM(nil)
		pitchBGM(1)
		self.game:onExit()
		loadSave()
		love.math.setRandomSeed(os.time())
		if self.rerecord then sortReplays() end
		scene = (
			(e.input == "retry") and
			ReplayScene(
				self.retry_replay, self.retry_mode,
				self.retry_ruleset, self.secret_inputs
			) or ReplaySelectScene()
	 	)
		savestate_frames = nil
	elseif e.input == "frame_step" and (TAS_mode or not self.rerecord) then
		frame_steps = frame_steps + 1
	elseif e.input == "pause" and not (self.game.game_over or self.game.completed) then
		self.paused = not self.paused
		if self.paused then pauseBGM()
		else resumeBGM() end
	elseif e.input and string.sub(e.input, 1, 5) ~= "menu_" and self.rerecord and e.input ~= "frame_step" then
		self.inputs[e.input] = true
		if config.gamesettings["diagonal_input"] == 3 then
			if (e.input == "left" or e.input == "right" or e.input == "down" or e.input == "up") then
				for key, value in pairs(movement_directions) do
					if value ~= e.input then
						self.inputs[value] = false
					end
				end
				self.first_input = self.first_input or e.input
			end
		end
	elseif e.input == "hold" then
		self.rerecord = true
		savestate_frames = self.frames
		self:replayCutoff()
		self.replay_speed = 1
		self.game.save_replay = config.gamesettings.save_replay == 1
		self.game.replay_inputs = self.retry_replay.inputs
		self.paused = true
	elseif e.input == "left" then
		self.replay_speed = self.replay_speed - 1
		if self.replay_speed < 1 then
			self.replay_speed = 1
		end
		pitchBGM(self.replay_speed)
	elseif e.input == "right" then
		self.replay_speed = self.replay_speed + 1
		if self.replay_speed > 99 then
			self.replay_speed = 99
		end
		pitchBGM(self.replay_speed)
	elseif e.input == "hold" then
		self.show_invisible = not self.show_invisible
	end
end

function ReplayScene:onInputRelease(e)
	if e.input and string.sub(e.input, 1, 5) ~= "menu_" and self.rerecord then
		self.inputs[e.input] = false
		if config.gamesettings["diagonal_input"] == 3 then
			if (e.input == "left" or e.input == "right" or e.input == "down" or e.input == "up") then
				
				if self.first_input ~= nil and self.first_input ~= e.input then
					self.inputs[self.first_input] = true
				end
				if self.first_input == e.input then
					self.first_input = nil
				end
			end
		end
	end
end

return ReplayScene
