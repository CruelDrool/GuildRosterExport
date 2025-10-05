---@class Private
local Private = select(2, ...)

---@class Debug
local Debug = Private.Debug

---@class Utils
local Utils = Private.Utils

---@class Translate
local Translate = Private.Translate

---@class ExportFrame
local ExportFrame = {}

local L = Translate:GetLocaleEntries()

---@class BackdropFrame: Frame
---@class BackdropFrame: BackdropTemplate
local frame = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)

function ExportFrame:LoadPosition()
	frame:ClearAllPoints()
	frame:SetPoint(unpack(Private.db.profile.exportFrame.position))
	frame:SetSize(unpack(Private.db.profile.exportFrame.size))
	frame.editBox:SetSize(frame.scrollFrame:GetSize())
end

function ExportFrame:Show()
	frame.closeButton:SetText(L["Close"])
	frame.closeAndReturnButton:SetText(L["Close & Return"])
	frame.editBox:HighlightText()
	frame:Show()
end

function ExportFrame:SetText(text)
	frame.editBox:SetMaxLetters(Private.db.profile.exportFrame.maxLetters)
	frame.editBox:SetText("")
	frame.editBox:SetText(text)
end

function ExportFrame:SetTextAndShow(text)
	self:SetText(text)
	self:Show()
end

function ExportFrame:Hide()
	frame:Hide()
end

function ExportFrame:IsShown()
	return frame:IsShown()
end

function ExportFrame:IsVisible()
	return frame:IsVisible()
end

do
	frame:Hide()
	frame:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileEdge = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 5, right = 5, top = 5, bottom = 5 },
	})
	frame:SetBackdropColor(0,0,0,0.75)
	frame:SetMovable(true)
	frame:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			self:StartMoving()
		end
	end)
	frame:SetScript("OnMouseUp", function(self, button)
		self:StopMovingOrSizing()
		Private.db.profile.exportFrame.position = {self:GetPoint()}
	end)

	-- Buttons
	local closeButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
	closeButton:SetPoint("BOTTOM", frame, "BOTTOM", -75, 7.5)
	closeButton:SetScript("OnClick", function(self, button) frame.editBox:SetText(""); frame:Hide(); PlaySound(Utils.sounds.closeExportFrame) end)
	frame.closeButton = closeButton

	local closeAndReturnButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
	closeAndReturnButton:SetPoint("BOTTOM", frame, "BOTTOM", 75, 7.5)
	closeAndReturnButton:SetScript("OnClick", function(self, button) frame.editBox:SetText(""); Private.Core:ToggleOptions() end)
	frame.closeAndReturnButton = closeAndReturnButton

	-- Scroll frame
	local sf = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
	sf:SetPoint("TOP", 0, -19.5)
	sf:SetPoint("LEFT", 18.5, 0)
	sf:SetPoint("RIGHT", -42, 0)
	sf:SetPoint("BOTTOM", closeButton, "TOP", 0, 2.5)
	frame.scrollFrame = sf

	-- Edit box
	local eb = CreateFrame("EditBox", nil, sf)
	eb:SetMultiLine(true)
	eb:SetAutoFocus(true)
	eb:SetFontObject("ChatFontNormal")
	eb:SetScript("OnEscapePressed", function() frame.editBox:SetText(""); frame:Hide() end)
	sf:SetScrollChild(eb)
	frame.editBox = eb

	-- Resizing
	frame:SetResizable(true)

	-- :SetMinResize removed in patch 10.0.0.
	if frame.SetResizeBounds then
		frame:SetResizeBounds(340, 110)
	else
		-- Backwards compatibility with any client not using the new method yet.
		---@diagnostic disable-next-line: undefined-field
		frame:SetMinResize(340, 110)
	end

	local rb = CreateFrame("Button", nil, frame)
	rb:SetPoint("BOTTOMRIGHT", -4, 4)
	rb:SetSize(16, 16)

	rb:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	rb:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	rb:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

	rb:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			frame:StartSizing("BOTTOMRIGHT")
			self:GetHighlightTexture():Hide() -- more noticeable
		end
	end)

	rb:SetScript("OnMouseUp", function(self, button)
		frame:StopMovingOrSizing()
		self:GetHighlightTexture():Show()
		eb:SetWidth(sf:GetWidth())
		Private.db.profile.exportFrame.size = {frame:GetSize()}
	end)

end

Private.ExportFrame = ExportFrame
