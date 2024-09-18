---@class BFC
local BFC = select(2, ...)

local Serializer = LibStub:GetLibrary("LibSerialize")
local LibDeflate = LibStub:GetLibrary("LibDeflate")
local deflateConfig = {level = 9}

local importExportFrame, confirmDialog
local editboxContainer, scrollingEditBox, importButton
local mode, exportedStr, importedData

---------------------------------------------------------------------
-- HighlightText
---------------------------------------------------------------------
local function HighlightText()
    scrollingEditBox.eb:HighlightText()
end

---------------------------------------------------------------------
-- DoImport
---------------------------------------------------------------------
local function DoImport()
    if not importedData then return end

end

---------------------------------------------------------------------
-- OnTextChanged
---------------------------------------------------------------------
local function OnTextChanged()
    if mode == "export" then
        -- refill text
        scrollingEditBox:SetText(exportedStr)
        HighlightText()

    elseif mode == "import" then
        -- import
        local type, data = string.match(scrollingEditBox.eb:GetText(), "^!BFC:(%u+)!(.+)$")
        if type and data then
            local success
            data = LibDeflate:DecodeForPrint(data) -- decode
            success, data = pcall(LibDeflate.DecompressDeflate, LibDeflate, data) -- decompress
            success, data = Serializer:Deserialize(data) -- deserialize

            if success and data then
                -- BFCList = data
                print("OK")
                importedData = data
                importButton:SetEnabled(true)
            else
                -- TODO: failed
                print("failed")
                importedData = nil
                importButton:SetEnabled(false)
            end
        else
            -- TODO: error
            print("error")
            importedData = nil
            importButton:SetEnabled(false)
        end
    end
end

---------------------------------------------------------------------
-- CreateConfirmDialog
---------------------------------------------------------------------
local function CreateConfirmDialog()
    confirmDialog = CreateFrame("Frame", "BFC_ImportExportConfirm", importExportFrame, "PortraitFrameTemplate")
    confirmDialog:SetFrameLevel(BFC_MainFrame:GetFrameLevel() + 1500)
    confirmDialog:SetSize(300, 200)
    confirmDialog:SetPoint("CENTER")
    ButtonFrameTemplate_HidePortrait(confirmDialog)
    confirmDialog:Hide()

    confirmDialog:SetScript("OnShow", function()
        BFC_MainFrameMask:SetFrameLevel(BFC_MainFrame:GetFrameLevel() + 1000)
    end)

    confirmDialog:SetScript("OnHide", function()
        confirmDialog:Hide()
        BFC_MainFrameMask:SetFrameLevel(BFC_MainFrame:GetFrameLevel() + 200)
    end)
end

---------------------------------------------------------------------
-- CreateImportExportFrame
---------------------------------------------------------------------
local function CreateImportExportFrame()
    importExportFrame = CreateFrame("Frame", "BFC_ImportExportFrame", BFC_MainFrame, "PortraitFrameTemplate")
    importExportFrame:SetFrameLevel(BFC_MainFrame:GetFrameLevel() + 300)
    importExportFrame:SetHeight(300)
    importExportFrame:SetPoint("BOTTOMLEFT", 55, 50)
    importExportFrame:SetPoint("BOTTOMRIGHT", -50, 50)
    ButtonFrameTemplate_HidePortrait(importExportFrame)
    importExportFrame:Hide()

    importExportFrame:SetScript("OnShow", function()
        BFC_MainFrameMask:Show()
    end)
    importExportFrame:SetScript("OnHide", function()
        importExportFrame:Hide()
        BFC_MainFrameMask:Hide()
    end)

    -- editbox container
    editboxContainer = CreateFrame("Frame", nil, importExportFrame, "TooltipBackdropTemplate")
    editboxContainer:SetBackdropColor(0.2, 0.2, 0.2, 0.9)
    editboxContainer:SetBackdropBorderColor(0.9, 0.9, 0.9, 1)
    editboxContainer:SetPoint("TOPLEFT", 30, -40)
    editboxContainer:SetPoint("BOTTOMRIGHT", -25, 40)

    -- scrollingEditBox
    scrollingEditBox = CreateFrame("Frame", "BFC_ImportExportEditBox", editboxContainer, "ScrollingEditBoxTemplate")
    scrollingEditBox:SetPoint("TOPLEFT", 4, -4)
    scrollingEditBox:SetPoint("BOTTOMRIGHT", -3, 4)
    scrollingEditBox:SetScript("OnMouseUp", HighlightText)
    scrollingEditBox.eb = scrollingEditBox:GetEditBox()
    scrollingEditBox.eb:RegisterCallback("OnMouseUp", HighlightText)
    scrollingEditBox.eb:RegisterCallback("OnTextChanged", OnTextChanged)

    -- scroll bar
    local scrollBar = CreateFrame("EventFrame", nil, editboxContainer, "MinimalScrollBar")
    scrollBar:SetPoint("TOPRIGHT", -10, -5)
    scrollBar:SetPoint("BOTTOMRIGHT", -10, 5)

    local scrollBox = scrollingEditBox:GetScrollBox()
    ScrollUtil.RegisterScrollBoxWithScrollBar(scrollBox, scrollBar)

    local scrollBoxAnchorsWithBar = {
        CreateAnchor("TOPLEFT", scrollingEditBox, "TOPLEFT", 0, 0),
        CreateAnchor("BOTTOMRIGHT", scrollingEditBox, "BOTTOMRIGHT", -23, 0),
    }
    local scrollBoxAnchorsWithoutBar = {
        scrollBoxAnchorsWithBar[1],
        CreateAnchor("BOTTOMRIGHT", scrollingEditBox, "BOTTOMRIGHT", -2, 0),
    }
    ScrollUtil.AddManagedScrollBarVisibilityBehavior(scrollBox, scrollBar, scrollBoxAnchorsWithBar, scrollBoxAnchorsWithoutBar)

    -- import button
    importButton = CreateFrame("Button", nil, importExportFrame, "UIPanelButtonTemplate")
    importButton:SetPoint("TOPLEFT", editboxContainer, "BOTTOMLEFT", 0, -5)
    importButton:SetPoint("TOPRIGHT", editboxContainer, "BOTTOMRIGHT", 0, -5)
    importButton:SetText("导入")
    importButton:SetScript("OnClick", function()
        confirmDialog:Show()
    end)

    CreateConfirmDialog()
end

---------------------------------------------------------------------
-- export
---------------------------------------------------------------------
function BFC.ShowExportFrame()
    if not importExportFrame then
        CreateImportExportFrame()
    end

    mode = "export"

    editboxContainer:SetPoint("BOTTOMRIGHT", -25, 20)
    importButton:Hide()

    -- export
    exportedStr = Serializer:Serialize(BFC.craftsman) -- serialize
    exportedStr = LibDeflate:CompressDeflate(exportedStr, deflateConfig) -- compress
    exportedStr = LibDeflate:EncodeForPrint(exportedStr) -- encode
    exportedStr = "!BFC:CRAFT!" .. exportedStr
    scrollingEditBox:SetText(exportedStr)
    scrollingEditBox.eb:HighlightText()

    importExportFrame.TitleContainer.TitleText:SetText("工匠数据导出")
    importExportFrame:Show()
end

---------------------------------------------------------------------
-- import
---------------------------------------------------------------------
function BFC.ShowImportFrame()
    if not importExportFrame then
        CreateImportExportFrame()
    end

    mode = "import"
    importedData = nil

    editboxContainer:SetPoint("BOTTOMRIGHT", -25, 40)
    scrollingEditBox:SetText("")
    importButton:SetEnabled(false)
    importButton:Show()

    importExportFrame.TitleContainer.TitleText:SetText("工匠数据导入")
    importExportFrame:Show()
end