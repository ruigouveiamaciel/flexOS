
return {
	predicate = function()
		return peripheral.find("speaker") ~= nil
	end,
	execute = function()
		return shell.run("/programs/wave-amp")
	end,
	label = "Music player"
}
