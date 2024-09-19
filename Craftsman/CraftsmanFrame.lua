---@class BFC
local BFC = select(2, ...)

local PAD = 2
local SPACING = 2
local ATTIC_HEIGHT = 90

---------------------------------------------------------------------
-- comparator
---------------------------------------------------------------------
local function SortComparator(a, b)
    if a.isFavorite ~= b.isFavorite then
        return a.isFavorite
    end
    return a.createTime > b.createTime
end

---------------------------------------------------------------------
-- factory
---------------------------------------------------------------------
local function ElementFactory(factory, elementData)
    factory("CraftsmanButtonTemplate", function(button, elementData)
        elementData.playerFull = elementData.player .. "-" .. elementData.server
        elementData.isFavorite = BFCCraftsman.favorites[elementData.playerFull]
        button:UpdateText(elementData)
        button:UpdateFavoriteButton()

        button:SetScript("OnClick", function(button, buttonName, down)
            if buttonName == "LeftButton" then
                BFC.ShowMessageFrame(elementData.player, elementData.playerFull)
            end
        end)
    end)
end

---------------------------------------------------------------------
-- list
---------------------------------------------------------------------
local function CreateList(parent, name)
    local list = CreateFrame("ScrollFrame", name, parent, "WowScrollBoxList")
    list:SetPoint("TOPLEFT")
    list:SetPoint("BOTTOMRIGHT", -20, 2)

    list.scrollBar = CreateFrame("EventFrame", nil, parent, "MinimalScrollBar")
    list.scrollBar:SetPoint("TOPLEFT", list, "TOPRIGHT", 5, 0)
    list.scrollBar:SetPoint("BOTTOMLEFT", list, "BOTTOMRIGHT", 5, 0)

    list.dataProvider = CreateDataProvider()
    list.dataProvider:SetSortComparator(SortComparator)

    list.view = CreateScrollBoxListLinearView()
    list.view :SetElementFactory(ElementFactory)
    list.view :SetPadding(PAD, PAD, PAD, PAD, SPACING)

    ScrollUtil.InitScrollBoxListWithScrollBar(list, list.scrollBar, list.view)
    list:SetDataProvider(list.dataProvider)

    return list
end

---------------------------------------------------------------------
-- CraftsmanButtonMixin
---------------------------------------------------------------------
CraftsmanButtonMixin = {}

function CraftsmanButtonMixin:OnLoad()
    self.FavoriteButton:SetScript("OnEnter", function()
        self:OnEnter()
    end)

    self.FavoriteButton:SetScript("OnLeave", function()
        self:OnLeave()
    end)

    self.FavoriteButton:SetScript("OnClick", function()
        self:GetData().isFavorite = not self:GetData().isFavorite
        -- update BFCCraftsman.favorites
        if self:GetData().isFavorite then
            BFCCraftsman.favorites[self:GetData().playerFull] = true
        else
            BFCCraftsman.favorites[self:GetData().playerFull] = nil
        end

        -- update list
        for index, elementData in normalList.dataProvider:Enumerate() do
            elementData.isFavorite = BFCCraftsman.favorites[elementData.playerFull]
            local button = normalList.view:FindFrame(elementData)
            if button then
                button:UpdateFavoriteButton()
            end
        end
        for index, elementData in searchList.dataProvider:Enumerate() do
            elementData.isFavorite = BFCCraftsman.favorites[elementData.playerFull]
            local button = searchList.view:FindFrame(elementData)
            if button then
                button:UpdateFavoriteButton()
            end
        end
    end)
end

function CraftsmanButtonMixin:OnEnter()
    self.MouseoverOverlay:Show()
    self.FavoriteButton.NormalTexture:Show()
end

function CraftsmanButtonMixin:OnLeave()
    self.MouseoverOverlay:Hide()
    if not self:GetData().isFavorite then
        self.FavoriteButton.NormalTexture:Hide()
    end
end

function CraftsmanButtonMixin:UpdateFavoriteButton()
    local isFavorite = self:GetData().isFavorite
    local currAtlas = isFavorite and "auctionhouse-icon-favorite" or "auctionhouse-icon-favorite-off"
    self.FavoriteButton.NormalTexture:SetAtlas(currAtlas)
    self.FavoriteButton.NormalTexture:SetShown(isFavorite)
    self.FavoriteButton.HighlightTexture:SetAtlas(currAtlas)
    self.FavoriteButton.HighlightTexture:SetAlpha(isFavorite and 0.2 or 0.4)
end

function CraftsmanButtonMixin:UpdateText(elementData)
    self.TitleLabel:SetText(elementData.title)
    self.PriceLabel:SetText(elementData.price .. "|A:Coin-Gold:0:0|a")
    self.PlayerLabel:SetText(elementData.player)
    self:UpdateFavoriteButton()
end





---------------------------------------------------------------------
-- craftsman frame
---------------------------------------------------------------------
local isSearch = false
local listUpdateRequired = true
local listEntries, searchEntries = 0, 0
local categoryFilter, matchedResult

local LoadData

---------------------------------------------------------------------
-- create craftsman frame
---------------------------------------------------------------------
local craftsmanFrame
local categoryDropdown, searchBox, topInfoText, updateTimeText, maskFrame
local normalList, searchList

local function CreateCraftsmanFrame()
    craftsmanFrame = CreateFrame("Frame", "BFC_CraftsmanFrame", BFC_MainFrame)
    craftsmanFrame:SetAllPoints()

    ---------------------------------------------------------------------
    -- top info
    ---------------------------------------------------------------------
    topInfoText = craftsmanFrame:CreateFontString(nil, "OVERLAY", "BFC_FONT_WHITE")
    topInfoText:SetPoint("TOPLEFT", 15, -70)

    function topInfoText.Update()
        topInfoText:SetFormattedText("总计：%d    本服：%d    列出的条目：%d", BFC.count_total, BFC.count_server, isSearch and searchEntries or listEntries)
    end

    ---------------------------------------------------------------------
    -- bottom info
    ---------------------------------------------------------------------
    local bottomInfoText = craftsmanFrame:CreateFontString(nil, "OVERLAY", "BFC_FONT_WHITE")
    bottomInfoText:SetPoint("BOTTOMLEFT", 15, 7)
    bottomInfoText:SetText("本插件数据由 |cffffff00魔兽工坊|r 提供")

    ---------------------------------------------------------------------
    -- update time
    ---------------------------------------------------------------------
    updateTimeText = craftsmanFrame:CreateFontString(nil, "OVERLAY", "BFC_FONT_WHITE")
    updateTimeText:SetPoint("BOTTOMRIGHT", -15, 7)

    ---------------------------------------------------------------------
    -- frame container
    ---------------------------------------------------------------------
    local scrollContainer = CreateFrame("Frame", "BFC_MainFrameContainer", craftsmanFrame)
    scrollContainer:SetPoint("TOPLEFT", 15, -ATTIC_HEIGHT-5)
    scrollContainer:SetPoint("BOTTOMRIGHT", -11, 32)

    -- scrollContainer.bg = scrollContainer:CreateTexture(nil, "ARTWORK")
    -- scrollContainer.bg:SetAllPoints(scrollContainer)
    -- scrollContainer.bg:SetColorTexture(0.03, 0.03, 0.03, 1)

    ---------------------------------------------------------------------
    -- mask
    ---------------------------------------------------------------------
    maskFrame = CreateFrame("Frame", nil, craftsmanFrame)
    maskFrame:EnableMouse(true)
    maskFrame:SetFrameLevel(craftsmanFrame:GetFrameLevel() + 100)
    maskFrame:SetAllPoints(scrollContainer)
    maskFrame:Hide()

    maskFrame.texture = maskFrame:CreateTexture(nil, "ARTWORK")
    maskFrame.texture:SetAllPoints()
    maskFrame.texture:SetColorTexture(0.15, 0.15, 0.15, 0.9)

    maskFrame.text = maskFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    maskFrame.text:SetPoint("LEFT", 10, 0)
    maskFrame.text:SetPoint("RIGHT", -10, 0)
    maskFrame.text:SetJustifyH("CENTER")
    maskFrame.text:SetJustifyV("MIDDLE")
    maskFrame.text:SetSpacing(7)

    function maskFrame.FadeOut()
        UIFrameFadeOut(maskFrame, 0.25, 1, 0)
        C_Timer.After(0.25, function()
            maskFrame:Hide()
        end)
    end

    ---------------------------------------------------------------------
    -- list
    ---------------------------------------------------------------------
    normalList = CreateList(scrollContainer, "BFC_CraftsmanNormalList")
    searchList = CreateList(scrollContainer, "BFC_CraftsmanSearchList")

        ---------------------------------------------------------------------
    -- category
    ---------------------------------------------------------------------
    local ALL = _G.ALL

    categoryDropdown = CreateFrame("DropdownButton", "BFC_CategoryDropdown", craftsmanFrame, "WowStyle1DropdownTemplate")
    categoryDropdown:SetWidth(150)
    categoryDropdown:SetHeight(25)
    categoryDropdown:SetPoint("TOPLEFT", 15, -35)
    categoryDropdown:SetDefaultText(ALL)

    -- local selectedValue = nil

    -- local function IsSelected(value)
    --     return value == selectedValue
    -- end

    -- local function SetSelected(value)
    --     selectedValue = value
    -- end

    -- MenuUtil.CreateRadioMenu(categoryDropdown,
    --     IsSelected,
    --     SetSelected,
    --     {"Radio 1", 1},
    --     {"Radio 2", 2},
    --     {"Radio 3", 3},
    -- )

    local function DropdownOnClick(category)
        if category then
            local c1, c2, c3 = strsplit("|", category)
            categoryDropdown:OverrideText(c3 or c2 or c1)
            categoryFilter = BFC.GetRelatedCategories(category)
        else -- all
            categoryDropdown:OverrideText(ALL)
            categoryFilter = nil
        end
        listUpdateRequired = isSearch
        LoadData(isSearch and searchBox:GetText())
    end

    categoryDropdown:SetupMenu(function(dropdown, rootDescription)
        -- rootDescription:SetGridMode(MenuConstants.VerticalGridDirection, 3)
        rootDescription:CreateButton(ALL, DropdownOnClick)
        rootDescription:CreateDivider()

        for _, t1 in pairs(BFC.category) do
            local b1 = rootDescription:CreateButton(t1.category)
            -- all
            b1:CreateButton(ALL, DropdownOnClick, t1.category)
            -- divider
            b1:CreateDivider()

            for _, t2 in pairs(t1.subs) do
                local b2 = b1:CreateButton(t2.category, DropdownOnClick, (not t2.subs) and (t1.category .. "|" .. t2.category))

                if t2.subs then
                    -- all
                    b2:CreateButton(ALL, DropdownOnClick, t1.category .. "|" .. t2.category)
                    -- divider
                    b2:CreateDivider()

                    for _, t3 in pairs(t2.subs) do
                        local b3 = b2:CreateButton(t3, DropdownOnClick, t1.category .. "|" .. t2.category .. "|" .. t3)
                    end
                end
            end
        end

        -- rootDescription:CreateTitle()
        -- rootDescription:CreateTitle(_G.ARMOR)
        -- rootDescription:CreateTitle(_G.INVTYPE_PROFESSION_GEAR)
    end)

    ---------------------------------------------------------------------
    -- search
    ---------------------------------------------------------------------
    searchBox = CreateFrame("EditBox", "BFC_SearchBox", craftsmanFrame, "SearchBoxTemplate")
    searchBox:SetScript("OnTextChanged", function(self, userChanged)
        SearchBoxTemplate_OnTextChanged(self)

        local text = searchBox:GetText()
        if string.len(text) == 0 then
            isSearch = false
            normalList:Show()
            normalList.scrollBar:Show()
            searchList:Hide()
            searchList.scrollBar:Hide()
            if listUpdateRequired then
                listUpdateRequired = false
                LoadData()
            else
                topInfoText.Update()
            end
        else
            isSearch = true
            dropdownChangedBySearch = false
            searchList:Show()
            searchList.scrollBar:Show()
            normalList:Hide()
            normalList.scrollBar:Hide()
            if userChanged then
                LoadData(strtrim(text))
            end
        end
    end)

    searchBox:SetPoint("TOPRIGHT", -10, -35)
    searchBox:SetPoint("LEFT", categoryDropdown, "RIGHT", 20, 0)
    searchBox:SetHeight(25)

    ---------------------------------------------------------------------
    -- export
    ---------------------------------------------------------------------
    local exportButton = CreateFrame("Button", nil, craftsmanFrame, "UIPanelButtonTemplate")
    exportButton:SetPoint("TOPRIGHT", -15, -65)
    exportButton:SetTextToFit("导出")
    exportButton:SetScript("OnClick", function()
        BFC.ShowExportFrame()
    end)

    ---------------------------------------------------------------------
    -- import
    ---------------------------------------------------------------------
    local importButton = CreateFrame("Button", nil, craftsmanFrame, "UIPanelButtonTemplate")
    importButton:SetPoint("BOTTOMRIGHT", exportButton, "BOTTOMLEFT", -3, 0)
    importButton:SetTextToFit("导入")
    importButton:SetScript("OnClick", function()
        BFC.ShowImportFrame()
    end)
end

---------------------------------------------------------------------
-- load data
---------------------------------------------------------------------
local ticker, timer
local loaded = 0
local entries

local function DoLoad()
    loaded = loaded + 1

    local data = matchedResult[loaded]

    -- title
    local title = data.title:gsub("%[", "|cffffff00[")
    title = title:gsub("%]", "]|r")

    -- insert
    local elementData = {
        title = title,
        price = data.price,
        player = data.gameCharacterName,
        server = data.serverName,
        createTime = data.createTime,
    }

    if isSearch then
        searchList.dataProvider:Insert(elementData)
    else
        normalList.dataProvider:Insert(elementData)
    end

    -- update loding
    maskFrame.text:SetFormattedText("正在加载工匠数据……\n%d%%", loaded / entries * 100)

    -- finished
    if loaded == entries then
        timer = C_Timer.After(0.25, maskFrame.FadeOut)
    end
end

local function PrepareData(text)
    local result = {}

    if not categoryFilter then
        result = BFCCraftsman.data
    else
        for _, t in pairs(BFCCraftsman.data) do
            if categoryFilter[t.categoryName] then
                tinsert(result, t)
            end
        end
    end

    if text then
        local matched = {}
        for _, data in pairs(result) do
            -- title
            if (data.title and strfind(data.title, text)) or
                (data.categoryName and strfind(data.categoryName, text)) or
                (data.itemName and strfind(data.itemName, text)) or
                (data.itemLevel and strfind(data.itemLevel, text)) or
                (data.gameCharacterName and strfind(data.gameCharacterName, text)) then
                tinsert(matched, data)
            end
        end
        return matched
    else
        return result
    end
end

function LoadData(text)
    if ticker then
        ticker:Cancel()
        ticker = nil
    end

    if timer then
        timer:Cancel()
        timer = nil
    end

    maskFrame:Show()
    maskFrame:SetAlpha(1)
    maskFrame.text:SetText("正在加载工匠数据……")

    if isSearch then
        searchList.dataProvider:Flush()
    else
        normalList.dataProvider:Flush()
        listUpdateRequired = false
    end

    if #BFCCraftsman.data == 0 then
        maskFrame.text:SetText("没有工匠数据……") -- TODO:
        topInfoText.Update()
        return
    end

    -- update time
    updateTimeText:SetText("数据更新时间：" .. date("%Y/%m/%d %H:%M", BFCCraftsman.updateTime))

    -- filter
    matchedResult = PrepareData(text)
    if isSearch then
        searchEntries = min(#matchedResult, 500)
        entries = searchEntries
    else
        listEntries = min(#matchedResult, 500)
        entries = listEntries
    end
    topInfoText.Update()

    if entries == 0 then
        maskFrame.text:SetText("没有匹配条件的工匠数据……") -- TODO:
        maskFrame.FadeOut()
        return
    end

    loaded = 0
    ticker = C_Timer.NewTicker(0, DoLoad, entries)

    -- local start = GetTimePreciseSec()
    -- for i = 1, n do
    --     DoLoad()
    -- end
    -- print("time cost:", GetTimePreciseSec() - start)
end

---------------------------------------------------------------------
-- show
---------------------------------------------------------------------
function BFC.ShowCraftsmanFrame(item)
    if not craftsmanFrame then
        CreateCraftsmanFrame()
    end

    BFC_MainFrame.Inset:SetPoint("TOPLEFT", 11, -ATTIC_HEIGHT)

    craftsmanFrame:Show()

    if not craftsmanFrame.loaded then
        craftsmanFrame.loaded = true
        if not item then
            listUpdateRequired = true
            LoadData()
        end
    end

    if item then
        isSearch = true
        searchBox:SetText(item)
        LoadData(item)
    end
end

---------------------------------------------------------------------
-- reload
---------------------------------------------------------------------
function BFC.ReloadCraftsmanData()
    isSearch = false
    searchBox:SetText("")
    categoryFilter = nil
    categoryDropdown:OverrideText(ALL)
    LoadData()
end