local ModeSelectScene = Scene:extend()

ModeSelectScene.title = "Mode list"

--Interpolates in a smooth fashion unless the visual setting for scrolling is nil or off.
local function interpolateListPos(input, from, speed)
	if config.visualsettings["smooth_scroll"] == 2 or config.visualsettings["smooth_scroll"] == nil then
		return from
	end
    if speed == nil then speed = 1 end
	if from > input then
		input = input + ((from - input) / 4) * speed
		if input > from - 0.02 then
			input = from
		end
	elseif from < input then
		input = input + ((from - input) / 4) * speed
		if input < from + 0.02 then
			input = from
		end
	end
	return input
end

function ModeSelectScene:new()
	-- reload custom modules
	initModules()
	if highscores == nil then highscores = {} end
	if #game_modes == 0 or #rulesets == 0 then
		self.display_warning = true
		current_mode = 1
		current_ruleset = 1
	else
		self.display_warning = false
		if current_mode > #game_modes then
			current_mode = 1
		end
		if current_ruleset > #rulesets then
			current_ruleset = 1
		end
	end
	self.game_mode_folder = game_modes
	self.game_mode_selections = {game_modes}
	self.ruleset_folder = rulesets
	self.ruleset_folder_selections = {rulesets}
	self.menu_state = {
		mode = current_mode,
		ruleset = current_ruleset,
	}
	self.secret_inputs = {}
	self.das_x, self.das_y = 0, 0
	self.menu_mode_y = 20
	self.menu_ruleset_x = 20
	self.auto_mode_offset = 0
    self.auto_ruleset_offset = 0
	self.start_frames, self.starting = 0, false
	DiscordRPC:update({
		details = "In menus",
		state = "Chosen ??? and ???.",
		largeImageKey = "ingame-000"
	})
end
function ModeSelectScene:update()
	switchBGM(nil)
	if self.starting then
		self.start_frames = self.start_frames + 1
		if self.start_frames > 60 or config.visualsettings.mode_entry == 1 then
			self:startMode()
		end
		return
	end
	if self.das_up or self.das_down then
		self.das_y = self.das_y + 1
	else
		self.das_y = 0
	end
	if self.das_left or self.das_right then
		self.das_x = self.das_x + 1
	else
		self.das_x = 0
	end
	if self.auto_mode_offset ~= 0 then
		self:changeMode(self.auto_mode_offset < 0 and -1 or 1)
		if self.auto_mode_offset > 0 then self.auto_mode_offset = self.auto_mode_offset - 1 end
		if self.auto_mode_offset < 0 then self.auto_mode_offset = self.auto_mode_offset + 1 end
	end
	if self.auto_ruleset_offset ~= 0 then
		self:changeRuleset(self.auto_ruleset_offset < 0 and -1 or 1)
		if self.auto_ruleset_offset > 0 then self.auto_ruleset_offset = self.auto_ruleset_offset - 1 end
		if self.auto_ruleset_offset < 0 then self.auto_ruleset_offset = self.auto_ruleset_offset + 1 end
	end
	if self.das_y >= 15 then
		self:changeMode(self.das_up and -1 or 1)
		self.das_y = self.das_y - 4
	end
	if self.das_x >= 15 then
		self:changeRuleset(self.das_left and -1 or 1)
		self.das_x = self.das_x - 15
	end
	DiscordRPC:update({
		details = "In menus",
		state = "Chosen ".. ((self.game_mode_folder[self.menu_state.mode] or {name = "No mode"}).name) .." and ".. ((self.ruleset_folder[self.menu_state.ruleset] or {name = "No rulset"}).name) ..".",
		largeImageKey = "ingame-000"
	})
end
function ModeSelectScene:render()
	love.graphics.draw(
		backgrounds[0],
		0, 0, 0,
		0.5, 0.5
	)

	love.graphics.setFont(font_3x5_4)
	local b = CursorHighlight(0, 40, 50, 30)
	love.graphics.setColor(1, 1, b, 1)
	love.graphics.printf("<-", 0, 40, 50, "center")
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setFont(font_3x5_2)
	love.graphics.draw(misc_graphics["select_mode"], 50, 44)

	if self.display_warning then
		love.graphics.setFont(font_3x5_3)
		love.graphics.printf(
			"You have no modes or rulesets.",
			80, 200, 480, "center"
		)
		love.graphics.setFont(font_3x5_2)
		love.graphics.printf(
			"Come back to this menu after getting more modes or rulesets. " ..
			"Press any button to return to the main menu.",
			80, 250, 480, "center"
		)
		return
	end

	local mode_selected, ruleset_selected = self.menu_state.mode, self.menu_state.ruleset

	self.menu_mode_y = interpolateListPos(self.menu_mode_y / 20, mode_selected) * 20
	self.menu_ruleset_x = interpolateListPos(self.menu_ruleset_x / 120, ruleset_selected) * 120

    love.graphics.setColor(1, 1, 1, 0.5)
	love.graphics.rectangle("fill", 20, 258 + (mode_selected * 20) - self.menu_mode_y, 240, 22)
	love.graphics.rectangle("fill", 260 + (ruleset_selected * 120) - self.menu_ruleset_x, 440, 120, 22)
    love.graphics.setColor(1, 1, 1, 1)

    local hash = ((self.game_mode_folder[mode_selected] or {}).hash or "not a value") .. "-" .. ((self.ruleset_folder[ruleset_selected] or {}).hash or "not a value")
    local mode_highscore = highscores[hash]

	if 	self.game_mode_folder[self.menu_state.mode]
	and not self.game_mode_folder[self.menu_state.mode].is_directory then
		love.graphics.printf(
			"Tagline: "..(self.game_mode_folder[mode_selected].tagline or "Missing."),
			 300, 40, 320, "left")
	end
    if mode_highscore ~= nil then
        for key, slot in pairs(mode_highscore) do
            if key == 11 then
                break
            end
            local idx = 1
            for name, value in pairs(slot) do
                if key == 1 then
                    love.graphics.printf(name, 180 + idx * 100, 100, 100)
                end
                love.graphics.printf(tostring(value), 180 + idx * 100, 100 + 20 * key, 100)
                idx = idx + 1
            end
        end
    end

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setFont(font_3x5_2)
	local mode_path_name = ""
	if #self.game_mode_selections > 1 then
		for index, value in ipairs(self.game_mode_selections) do
			mode_path_name = mode_path_name..(value.name or "modes").." > "
		end
		love.graphics.printf(
			"Path: "..mode_path_name:sub(1, #mode_path_name-3),
			 40, 220 - self.menu_mode_y, 200, "left")
	end
	local ruleset_path_name = ""
	if #self.ruleset_folder_selections > 1 then
		for index, value in ipairs(self.ruleset_folder_selections) do
			ruleset_path_name = ruleset_path_name..(value.name or "rulesets").." > "
		end
		love.graphics.printf(
			"Path: "..ruleset_path_name:sub(1, #ruleset_path_name-3),
			 360 - self.menu_ruleset_x, 420, 60 + (#ruleset_path_name * 9), "left")
	end
	love.graphics.setFont(font_3x5_2)
	if #self.game_mode_folder == 0 then
		love.graphics.printf("No modes in this folder!", 40, 280 - self.menu_mode_y, 260, "left")
	end
	if #self.ruleset_folder == 0 then
		love.graphics.printf("Empty folder!", 380 - self.menu_ruleset_x, 440, 120, "center")
	end
	for idx, mode in ipairs(self.game_mode_folder) do
		if(idx >= self.menu_mode_y / 20 - 10 and
		   idx <= self.menu_mode_y / 20 + 10) then
			local b = 1
			if mode.is_directory then
				b = 0.4
			end
			local highlight = CursorHighlight(
				0,
				(260 - self.menu_mode_y) + 20 * idx,
				320,
				20)
			if highlight < 0.5 then
				b = highlight
			end
			if idx == self.menu_state.mode and self.starting then
				b = self.start_frames % 10 > 4 and 0 or 1
			end
			love.graphics.setColor(1, 1, b, FadeoutAtEdges(
				-self.menu_mode_y + 20 * idx + 20,
				160,
				20))
			love.graphics.printf(mode.name,
			40, (260 - self.menu_mode_y) + 20 * idx, 200, "left")
		end
	end
	for idx, ruleset in ipairs(self.ruleset_folder) do
		if(idx >= self.menu_ruleset_x / 120 - 3 and
		   idx <= self.menu_ruleset_x / 120 + 3) then
			local b = 1
			if ruleset.is_directory then
				b = 0.4
			end
			local highlight = CursorHighlight(
				260 - self.menu_ruleset_x + 120 * idx, 440,
				120, 20)
			if highlight < 0.5 then
				b = highlight
			end
			love.graphics.setColor(1, 1, b, FadeoutAtEdges(
				-self.menu_ruleset_x + 120 * idx,
				240,
				120)
			)
			love.graphics.printf(ruleset.name,
			260 - self.menu_ruleset_x + 120 * idx, 440, 120, "center")
		end
	end
end

function FadeoutAtEdges(input, edge_distance, edge_width)
	if input < 0 then
		input = input * -1
	end
	if input > edge_distance then
		return 1 - (input - edge_distance) / edge_width
	end
	return 1
end
function ModeSelectScene:indirectStartMode()
	if self.ruleset_folder[self.menu_state.ruleset].is_directory then
		playSE("main_decide")
		self.ruleset_folder = self.ruleset_folder[self.menu_state.ruleset]
		self.ruleset_folder_selections[#self.ruleset_folder_selections+1] = self.ruleset_folder
		self.menu_state.ruleset = 1
		return
	end
	if self.game_mode_folder[self.menu_state.mode].is_directory then
		playSE("main_decide")
		self.game_mode_folder = self.game_mode_folder[self.menu_state.mode]
		self.game_mode_selections[#self.game_mode_selections+1] = self.game_mode_folder
		self.menu_state.mode = 1
		return
	end
	playSE("mode_decide")
	if config.visualsettings.mode_entry == 1 then
		self:startMode()
	else
		self.starting = true
	end
end
--Direct way of starting a mode.
function ModeSelectScene:startMode()
	if #self.game_mode_selections == 1 then
		current_mode = self.menu_state.mode
	end
	if #self.ruleset_folder_selections == 1 then
		current_ruleset = self.menu_state.ruleset
	end
	config.current_mode = current_mode
	config.current_ruleset = current_ruleset
	saveConfig()
	scene = GameScene(
		self.game_mode_folder[self.menu_state.mode],
		self.ruleset_folder[self.menu_state.ruleset],
		self.secret_inputs
	)
end
function ModeSelectScene:menuGoBack(type)
	if type == "mode" and #self.game_mode_selections > 1 then
		self.game_mode_selections[#self.game_mode_selections] = nil
		self.game_mode_folder = self.game_mode_selections[#self.game_mode_selections]
	elseif #self.ruleset_folder_selections > 1 then
		self.ruleset_folder_selections[#self.ruleset_folder_selections] = nil
		self.ruleset_folder = self.ruleset_folder_selections[#self.ruleset_folder_selections]
	end
end

function ModeSelectScene:menuGoForward(type)
	if type == "mode" then
		self.game_mode_folder = self.game_mode_folder[self.menu_state.mode]
		self.game_mode_selections[#self.game_mode_selections+1] = self.game_mode_folder
	else
		self.ruleset_folder = self.ruleset_folder[self.menu_state.ruleset]
		self.ruleset_folder_selections[#self.ruleset_folder_selections+1] = self.ruleset_folder
	end
end
function ModeSelectScene:onInputPress(e)
	if e.input and (self.display_warning or #self.game_mode_folder == 0 or #self.ruleset_folder == 0) then
		if self.display_warning then
			scene = TitleScene()
		elseif #self.game_mode_folder == 0 then
			self:menuGoBack("mode")
		else
			self:menuGoBack("ruleset")
		end
	elseif e.input == "menu_back" or e.scancode == "delete" or e.scancode == "backspace" then
		if #self.game_mode_selections > 1 then
			self:menuGoBack("mode")
			self.menu_state.mode = 1
			return
		end
		if #self.ruleset_folder_selections > 1 then
			self:menuGoBack("ruleset")
			self.menu_state.ruleset = 1
			return
		end
		if self.starting then
			self.starting = false
			self.start_frames = 0
		else
			scene = TitleScene()
		end
	elseif e.type == "mouse" then
		if e.y < 80 then
			if e.x > 0 and e.y > 40 and e.x < 50 then
				playSE("main_decide")
				if #self.game_mode_selections > 1 then
					self:menuGoBack("mode")
					self.menu_state.mode = 1
					return
				end
				if #self.ruleset_folder_selections > 1 then
					self:menuGoBack("ruleset")
					self.menu_state.ruleset = 1
					return
				end
				scene = TitleScene()
			end
			return
		end
		if #self.game_mode_folder == 0 then
			self:menuGoBack("mode")
			self.menu_state.mode = 1
			return
		end
		if #self.ruleset_folder == 0 then
			self:menuGoBack("ruleset")
			self.menu_state.ruleset = 1
			return
		end
        if e.y < 440 then
            if e.x < 260 then
                self.auto_mode_offset = math.floor((e.y - 260)/20)
                if self.auto_mode_offset == 0 then
					if self.game_mode_folder[self.menu_state.mode].is_directory then
						playSE("main_decide")
						self:menuGoForward("mode")
						self.menu_state.mode = 1
						return
					end
					self:indirectStartMode()
                end
            end
        else
            self.auto_ruleset_offset = math.floor((e.x - 260)/120)
			if self.auto_ruleset_offset == 0 and self.ruleset_folder[self.menu_state.ruleset].is_directory then
				playSE("main_decide")
				self:menuGoForward("ruleset")
				self.menu_state.ruleset = 1
			end
        end
    elseif self.starting then return
    elseif e.type == "wheel" then
        if e.x ~= 0 then
            self:changeRuleset(-e.x)
        end
        if e.y ~= 0 then
            self:changeMode(-e.y)
        end
    elseif e.input == "menu_decide" or e.scancode == "return" then
        self:indirectStartMode()
    elseif e.input == "up" or e.scancode == "up" then
        self:changeMode(-1)
        self.das_up = true
        self.das_down = nil
    elseif e.input == "down" or e.scancode == "down" then
        self:changeMode(1)
        self.das_down = true
        self.das_up = nil
    elseif e.input == "left" or e.scancode == "left" then
        self:changeRuleset(-1)
        self.das_left = true
        self.das_right = nil
    elseif e.input == "right" or e.scancode == "right" then
        self:changeRuleset(1)
        self.das_right = true
        self.das_left = nil
    elseif e.input then
        self.secret_inputs[e.input] = true
    end
end

function ModeSelectScene:onInputRelease(e)
	if e.input == "up" or e.scancode == "up" then
		self.das_up = nil
	elseif e.input == "down" or e.scancode == "down" then
		self.das_down = nil
    elseif e.input == "left" or e.scancode == "left" then
        self.das_left = nil
    elseif e.input == "right" or e.scancode == "right" then
        self.das_right = nil
	elseif e.input then
		self.secret_inputs[e.input] = false
	end
end

function ModeSelectScene:changeMode(rel)
	playSE("cursor")
	local len = #self.game_mode_folder
	self.menu_state.mode = Mod1(self.menu_state.mode + rel, len)
end

function ModeSelectScene:changeRuleset(rel)
	playSE("cursor_lr")
	local len = #self.ruleset_folder
	self.menu_state.ruleset = Mod1(self.menu_state.ruleset + rel, len)
end

return ModeSelectScene