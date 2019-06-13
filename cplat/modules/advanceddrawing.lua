--TODO: Finish
local cplat = require()
local ctxu = cplat.require "contextutils"

local ctxa = ...

ctxa.drawTextBox = function(ctx, x, y, text, color, fg, meta)
	--Man, I do not want to write this
	--TODO: -1 = No Color
	text = text:gsub("\t", "  ")
	
	meta = meta or {}
	meta.borders = meta.borders or {}
	border.width = border.width or ctxu.getLineLength(text)
	border.height = border.height or ctxu.getLines(text)
	local function gborder(border)
		border.border = border.border or 1
		border.borderLeft = border.borderLeft or border.border
		border.borderRight = border.borderRight or border.border
		border.borderTop = border.borderTop or border.border
		border.borderBottom = border.borderBottom or border.border
		
		border.borderColor = border.borderColor or color
		border.borderColorLeft = border.borderColorLeft or border.borderColor
		border.borderColorRight = border.borderColorRight or border.borderColor
		border.borderColorTop = border.borderColorTop or border.borderColor
		border.borderColorBottom = border.borderColorLeft or border.borderColor
		
		border.borderColorCorner = border.borderColorCorner or border.borderColor
		border.borderColorTopLeftCorner = border.borderColorTopLeftCorner or border.borderColorCorner
		border.borderColorTopRightCorner = border.borderColorTopRightCorner or border.borderColorCorner
		border.borderColorBottomLeftCorner = border.borderColorBottomLeftCorner or border.borderColorCorner
		border.borderColorBottomRightCorner = border.borderColorBottomRightCorner or border.borderColorCorner
		
		border.borderTextColor = border.borderTextColor or fg
		border.borderTextColorLeft = border.borderTextColorLeft or border.borderTextColor
		border.borderTextColorRight = border.borderTextColorRight or border.borderTextColor
		border.borderTextColorTop = border.borderTextColorTop or border.borderTextColor
		border.borderTextColorBottom = border.borderTextColorLeft or border.borderTextColor
		
		border.borderTextColorCorner = border.borderTextColorCorner or border.borderTextColor
		border.borderTextColorTopLeftCorner = border.borderTextColorTopLeftCorner or border.borderTextColorCorner
		border.borderTextColorTopRightCorner = border.borderTextColorTopRightCorner or border.borderTextColorCorner
		border.borderTextColorBottomLeftCorner = border.borderTextColorBottomLeftCorner or border.borderTextColorCorner
		border.borderTextColorBottomRightCorner = border.borderTextColorBottomRightCorner or border.borderTextColorCorner
		
		border.borderChar = border.borderChar or " "
		border.borderCharLeft = border.borderCharLeft or border.borderChar
		border.borderCharRight = border.borderCharRight or border.borderChar
		border.borderCharTop = border.borderCharTop or border.borderChar
		border.borderCharBottom = border.borderCharLeft or border.borderChar
		
		border.borderCharCorner = border.borderCharCorner or border.borderChar
		border.borderCharTopLeftCorner = border.borderCharTopLeftCorner or border.borderCharCorner
		border.borderCharTopRightCorner = border.borderCharTopRightCorner or border.borderCharCorner
		border.borderCharBottomLeftCorner = border.borderCharBottomLeftCorner or border.borderCharCorner
		border.borderCharBottomRightCorner = border.borderCharBottomRightCorner or border.borderCharCorner
		
		border.borderMovesText = border.borderMovesText or false
		if border.borderMovesTextX==nil then border.borderMovesTextX = border.borderMovesText end
		if border.borderMovesTextY==nil then border.borderMovesTextY = border.borderMovesText end
		
		return border
	end
	
	local borders = meta.borders
	for k, v in ipairs(borders) do
		borders[k] = gborder(v)
		local border = borders[k]
		if border.borderMovesTextX then startX=startX-border.borderLeft end
	end
	
	
	
	ctx.drawFilledRect(startX, startY, totalWidth, totalHeight, color, meta.borderChar, meta.borderTextColor)
	ctx.drawText(startX+meta.borderLeft, startY+meta.borderTop, text, color, fg)
end