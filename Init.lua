---@class BFC
local BFC = select(2, ...)

---------------------------------------------------------------------
-- vars
---------------------------------------------------------------------
BFC.name = ...
BFC.displayedName = "大脚公益助手"
BFC.count_total = 0
BFC.count_server = 0
BFC.count_matched = 0

---------------------------------------------------------------------
-- font
---------------------------------------------------------------------
local font = CreateFont("BFC_FONT_WHITE")
font:SetFont("Fonts/ARKai_T.ttf", 14, "")
font:SetShadowColor(0, 0, 0, 1)
font:SetShadowOffset(1, -1)

---------------------------------------------------------------------
-- process data
---------------------------------------------------------------------
local LRI = LibStub("LibRealmInfoCN")
function BFC.ProcessCraftsmanData(data, updateTime, force)
    if (BFCCraftsman.updateTime and BFCCraftsman.updateTime <= updateTime) or force then
        BFCCraftsman.updateTime = updateTime
        wipe(BFCCraftsman.data)

        if type(data) == "table" then
            -- print("BEFORE", #data)
            for _, t in pairs(data) do
                if LRI.IsConnectedRealm(t.serverName)
                and t.gameCharacterName and t.gameCharacterName ~= ""
                and t.createTime then
                    tinsert(BFCCraftsman.data, t)
                end
            end
            -- print("AFTER", #BFCCraftsman.data)
        end
    end

    BFC.count_server = #BFCCraftsman.data
    BFC.count_total = max(#BFC.craftsman.data, BFC.count_server)
end

---------------------------------------------------------------------
-- events
---------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    self[event](...)
end)

function eventFrame.ADDON_LOADED(name)
    if name == BFC.name then
        if type(BFCConfig) ~= "table" then BFCConfig = {} end
        if type(BFCCraftsman) ~= "table" then
            BFCCraftsman = {
                updateTime = 0,
                data = {},
                favorites = {},
            }
        end

    elseif name == "Blizzard_ProfessionsCustomerOrders" then
        eventFrame:UnregisterEvent("ADDON_LOADED")
        -- order browsing
        local button1 = CreateFrame("Button", "BFC_SearchCraftsmanButton", ProfessionsCustomerOrdersFrame.BrowseOrders, "UIPanelButtonTemplate")
        button1:SetPoint("TOPLEFT", ProfessionsCustomerOrdersFrame.BrowseOrders, 70, -38)
        button1:SetSize(100, 22)
        button1:SetText("工匠列表")
        button1:SetScript("OnClick", function()
            BFC.ShowMainFrame()
        end)

        -- order form
        local button2 = CreateFrame("Button", "BFC_SearchCraftsmanButton", ProfessionsCustomerOrdersFrame.Form, "UIPanelButtonTemplate")
        button2:SetPoint("BOTTOMRIGHT", ProfessionsCustomerOrdersFrame.Form, "TOPRIGHT", 0, 5)
        button2:SetSize(100, 22)
        button2:SetText("查询工匠")
        button2:SetScript("OnClick", function()
            BFC.ShowMainFrame()
            BFC.ShowCraftsmanFrame(ProfessionsCustomerOrdersFrame.Form.RecipeName:GetText())
        end)
    end
end

function eventFrame:PLAYER_LOGIN()
    -- BFC.server = GetNormalizedRealmName()
    BFC.ProcessCraftsmanData(BFC.craftsman.data, BFC.craftsman.updateTime)
end

---------------------------------------------------------------------
-- slash
---------------------------------------------------------------------
SLASH_BFCRAFTSMAN1 = "/bfc"
SlashCmdList["BFCRAFTSMAN"] = function(text)
    local command, rest = text:match("^(%S*)%s*(.-)$")
    command = strlower(command or "")
    rest = strlower(rest or "")

    if command == "reset" then
        BFCConfig = nil
        BFCCraftsman = nil
        ReloadUI()
    else
        BFC.ShowMainFrame()
    end
end