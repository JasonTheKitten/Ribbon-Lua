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