local ContinueScene = Scene:extend()

function ContinueScene:new()
	self.option_selected = 2
	self.frames = 0
	self.frames_left = 600
	if game_credits == 0 then
		self.frames = 99
		self.selected = true
	end
end

function ContinueScene:update()
	if self.selected then
		self.frames = self.frames + 1
	end
	self.frames_left = self.frames_left - 1
	if self.frames_left <= 0 then
		self.frames_left = 0
		self.selected = true
		self.option_selected = 2
		self.frames = 99
	end
	if self.frames > 30 then
		if self.option_selected == 1 then
			if config.visualsettings.mode_select_type == 1 then
				scene = ModeSelectScene()
			else
				scene = RevModeSelectScene()
			end
		else
			scene = TitleScene()
		end
	end
end

function ContinueScene:render()
	drawBackground(0)
	love.graphics.setFont(font_8x11)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf("CONTINUE? " .. math.floor(self.frames_left / 60), 0, 120, 640, "center")
	love.graphics.setColor(1, 1, 1, 0.5)
	love.graphics.rectangle("fill", 260, 150 + self.option_selected * 40, 120, 50)
	love.graphics.setColor(1, 1, (self.option_selected == 1 and self.frames % 10 < 5) and 0 or 1, 1)
	love.graphics.printf("YES", 0, 200, 640, "center")
	love.graphics.setColor(1, 1, (self.option_selected == 2 and self.frames % 10 < 5) and 0 or 1, 1)
	love.graphics.printf("NO", 0, 240, 640, "center")
end

function ContinueScene:onInputPress(e)
	if self.selected then return end
	if e.input == "menu_up" then
		playSE("cursor")
		self.option_selected = Mod1(self.option_selected - 1, 2)
	elseif e.input == "menu_down" then
		playSE("cursor")
		self.option_selected = Mod1(self.option_selected + 1, 2)
	elseif e.input == "menu_decide" then
		playSE("main_decide")
		self.frames_left = 59
		self.selected = true
	end
end

return ContinueScene