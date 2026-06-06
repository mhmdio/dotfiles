-- Glow markdown previewer for Yazi
-- Patched for the current Yazi plugin API (verified against Yazi 26.5.6).
-- NOTE: upstream Reledia/glow uses the old API + a hardcoded dark style;
-- keep this local patch until upstream is fixed (ya pkg upgrade will protect it).

local M = {}

function M:peek(job)
	-- Fixed preview width
	local preview_width = 55

	local child = Command("glow")
		:arg({
			"--style",
			"auto", -- glow detects the terminal background and themes itself
			"--width",
			tostring(preview_width),
			tostring(job.file.url),
		})
		:env("CLICOLOR_FORCE", "1")
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()

	if not child then
		return require("code"):peek(job)
	end

	local limit = job.area.h
	local i, lines = 0, ""
	repeat
		local next, event = child:read_line()
		if event == 1 then
			-- glow wrote to stderr (error) -> fall back to the code previewer
			return require("code"):peek(job)
		elseif event ~= 0 then
			break
		end

		i = i + 1
		if i > job.skip then
			lines = lines .. next
		end
	until i >= job.skip + limit

	child:start_kill()
	if job.skip > 0 and i < job.skip + limit then
		ya.emit("peek", {
			tostring(math.max(0, i - limit)),
			only_if = job.file.url,
			upper_bound = true,
		})
	else
		lines = lines:gsub("\t", string.rep(" ", rt.preview.tab_size))
		ya.preview_widget(job, ui.Text.parse(lines):area(job.area))
	end
end

function M:seek(job)
	local h = cx.active.current.hovered
	if not h or h.url ~= job.file.url then
		return
	end
	ya.emit("peek", {
		math.max(0, cx.active.preview.skip + job.units),
		only_if = job.file.url,
	})
end

return M
