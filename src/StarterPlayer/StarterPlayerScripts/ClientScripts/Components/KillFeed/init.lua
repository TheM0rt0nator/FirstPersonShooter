--[[
	- Create a component which, similarly to hit markers, only shows up when a new kill happens and then fades after a certain time
	- Latest kill will be at the bottom, and will stay in memory for 20 seconds or so, then get removed
	- Have a max size so if loads of kills happen at once, the UI doesn't get too big
]]

local KillFeed = {}



return KillFeed