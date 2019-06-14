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

statics.COLORS = mstatics.colors
statics.COLOURS = mstatics.colors

local keys = { --Based off of the OC key list, but should work with CC
	["F11"] = 0x57,
	["F12"] = 0x58,
	["backspace"] = 0x0E,
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
putRow(0x02, "`1234567890-=")
putRow(0x10, "qertyuiop[]\\")
putRow(0x1E, "asdfghjkl;'")
putRow(0x2C,"zxcvbnm,./")
putRowT(0x3B, {"F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10"})

for k, v in pairs(keys) do
	keys[v] = k
end
keys.space = keys[" "]

mstatics.keys = keys
statics.KEYS = mstatics.keys

local mouse = {}
mstatics.mouse = mouse

statics.MOUSE = mstatics.mouse