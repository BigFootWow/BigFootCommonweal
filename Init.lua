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
        if type(BFCConfig.favorites) ~= "table" then BFCConfig.favorites = {} end
        -- if type(BFCList) ~= "table" then BFCList = {} end

    elseif name == "Blizzard_ProfessionsCustomerOrders" then
        eventFrame:UnregisterEvent("ADDON_LOADED")
        local button = CreateFrame("Button", "BFC_SearchCraftsmanButton", ProfessionsCustomerOrdersFrame.Form, "UIPanelButtonTemplate")
        button:SetPoint("BOTTOMRIGHT", ProfessionsCustomerOrdersFrame.Form, "TOPRIGHT", 0, 5)
        button:SetSize(100, 22)
        button:SetText("查询工匠")
        button:SetScript("OnClick", function()
            BFC.ShowMainFrame()
            BFC.ShowCraftsmanFrame(ProfessionsCustomerOrdersFrame.Form.RecipeName:GetText())
        end)
    end
end

function eventFrame:PLAYER_LOGIN()
    BFC.server = GetNormalizedRealmName()

    -- pre-process data
    if type(BFC.craftsman.data) == "table" then
        -- print("BEFORE", #BFC.craftsman.data)
        BFC.count_total = #BFC.craftsman.data
        for i = BFC.count_total, 1, -1 do
            if BFC.craftsman.data[i].serverName ~= BFC.server
                or not BFC.craftsman.data[i].gameCharacterName
                or BFC.craftsman.data[i].gameCharacterName == ""
                or not BFC.craftsman.data[i].createTime then
                tremove(BFC.craftsman.data, i)
            end
        end
        BFC.count_server = #BFC.craftsman.data
        -- print("AFTER", #BFC.craftsman.data)
    end
end