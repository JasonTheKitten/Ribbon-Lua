--Thank you, OC, for key codes and colors
--TODO: Finish
--TODO: Move code for hex into here; place code for ABCs here
local statics = ...

local mstatics = {}
statics.get = function(t)
	return mstatics[t]
end
statics.set = function(t, v)
	mstatics[t] = v
end

local colors = {
	white = 0,
	orange = 1,
	magenta = 2,
	lightBlue = 3,
	yellow = 4,
	lime = 5,
	pink = 6,
	darkGray = 7,
	lightGray = 8,
	cyan = 9,
	purple = 10,
	darkBlue = 11,
	brown = 12,
	green = 13,
	red = 14,
	black = 15
}
colors.darkGreen = colors.green
colors.lightGreen = colors.lime
colors.silver = colors.lightGray
colors.gray = colors.darkGray
colors.grey = colors.gray
colors.darkGrey = colors.darkGray
colors.lightGrey = colors.lightGray
colors.lightRed = colors.pink
colors.darkRed = colors.red
colors.blue = colors.darkBlue

local copy = {}
for k, v in pairs(colors) do
	copy[k:upper()] = v
end
for k, v in pairs(copy) do
	colors[k] = v
end

mstatics.colors = colors
mstatics.colours = colors
mstatics.COLORS = colors
mstatics.COLOURS = colors

local keys = { 
	["F11"] = 0x57,
	["F12"] = 0x58,
	["backspace"] = 0x0E,
	["space"] = 0x39,
	["tab"] = 0x0F,
	["up"] = 0xC8,
	["down"] = 0xD0,
	["left"] = 0xCB,
	["right"] = 0xCD,
	["home"] = 0xC7,
	["pageup"] = 0xC9,
	["enter"] = 0x1C,
	["lshift"] = 0x2A,
	["rshift"] = 0x36,
	["lctrl"] = 0x1D,
	["rctrl"] = 0x9D,
	["lalt"] = 0x38,
	["ralt"] = 0xB8,
} --TODO: alot more keys
local function putRow(code, letters)
	for i=1, #letters do
		keys[code-1+i] = letters:sub(i, i)
	end
end
local function putRowT(code, k)
	for i=1, #k do
		keys[code-1+i] = k[i]
	end
end
putRow(0x01, "`1234567890-=")
putRow(0x10, "qertyuiop[]\\")
putRow(0x1E, "asdfghjkl;'")
putRow(0x2C,"zxcvbnm,./")
putRowT(0x3B, {"F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10"})
putRowT(0xCF, {"end", "pagedown", "insert", "delete"})



for k, v in pairs(keys) do
	keys[v] = k
end
keys.space = keys[" "]

mstatics.keys = keys
statics.KEYS = mstatics.keys

local mouse = {
    MOUSE_LEFT = 1,
    MOUSE_CENTER = 3,
    MOUSE_RIGHT = 2
}

mstatics.mouse = mouse
statics.MOUSE = mstatics.mouse