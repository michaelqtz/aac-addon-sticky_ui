local api = require("api")

local sticky_ui_addon = {
	name = "Sticky UI",
	author = "Michaelqt",
	version = "0.1",
	desc = "Sticks UI elements in place with elmer's glue."
}



raidFrame = nil

local function repositionWindow(window, x, y)
    window:RemoveAllAnchors()
    window:AddAnchor("TOPLEFT", "UIParent", x, y)
end

function repositionRaidWindow()
    if raidFrame ~= nil then
        local settings = api.GetSettings("sticky_ui")
        raidFrame:RemoveAllAnchors()
        raidFrame:AddAnchor("TOPLEFT", "UIParent", settings.raidFrameX, settings.raidFrameY)
    end 
    return true
end 

-- Moving Raid Frame Timer
local moveRaidFrameFlag = false
local moveRaidFrameTimer = 0
local moveRaidFrameTickRate = 500
-- Saving Raid Frame to settings Timer
local saveRaidFrameXYFlag = false
local saveRaidFrameXYTimer = 0
local saveRaidFrameXYTickRate = 10000

local function OnUpdate(dt)
    if moveRaidFrameFlag == true then 
        moveRaidFrameTimer = moveRaidFrameTimer + dt
        if moveRaidFrameTimer > moveRaidFrameTickRate then 
            repositionRaidWindow()
            moveRaidFrameFlag = false
            moveRaidFrameTimer = 0
        end 
    end 
    if saveRaidFrameXYFlag == true and raidFrame ~= nil then
        saveRaidFrameXYTimer = saveRaidFrameXYTimer + dt
        if saveRaidFrameXYTimer > saveRaidFrameXYTickRate then 
            local settings = api.GetSettings("sticky_ui")
            local raidWindowX, raidWindowY = raidFrame:GetOffset()
            settings.raidFrameX = raidWindowX
            settings.raidFrameY = raidWindowY
            api.SaveSettings()

            saveRaidFrameXYTimer = 0
        end 
    end 
end

local function OnLoad()
    -- Get a reference to UI we want to glue... glue... sticky...
    local abyssalBar = ADDON:GetContent(UIC.BUBBLE_ACTION_BAR)
    
    -- Load settings
	local settings = api.GetSettings("sticky_ui")
    -- initialize abyssal bar X and Y
    local currentAbyssalX, currentAbyssalY = abyssalBar:GetOffset()
    local abyssalX = settings.abyssalX or currentAbyssalX
    local abyssalY = settings.abyssalY or currentAbyssalY
	settings.abyssalX = abyssalX
    settings.abyssalY = abyssalY
    -- initialize raid window X and Y
    local raidFrameX = settings.raidFrameX or 0
    local raidFrameY = settings.raidFrameY or 145
    settings.raidFrameX = raidFrameX
    settings.raidFrameY = raidFrameY

    settings.s_options = {
        abyssalX = {
            titleStr = "Abyssal Bar Position: x",
            controlStr = {"1", "2560"}
        },
        abyssalY = {
            titleStr = "Abyssal Bar Position: y",
            controlStr = {"1", "1440"}
        },
        raidFrameX = {
            titleStr = "Raid Frame Position: x",
            controlStr = {"1", "1440"}
        },
        raidFrameY = {
            titleStr = "Raid Frame Position: y",
            controlStr = {"1", "1440"}
        },
    }
    --- Abyssal Bar
    -- Reposition the abyssal bar when first loading in
    repositionWindow(abyssalBar, settings.abyssalX, settings.abyssalY)
    -- Overwrite the ondragstop to save the last position of the abyssal window to settings
    function abyssalBar.eventWindow:OnDragStop()
        if abyssalBar.moving == true then
            abyssalBar:StopMovingOrSizing()
            abyssalBar.moving = false
            api.Cursor:ClearCursor()

            local currentX, currentY = abyssalBar:GetOffset()
            settings.abyssalX = currentX
            settings.abyssalY = currentY
        end
        -- for key,value in pairs(api.Equipment) do
        --     api.Log:Info("found member " .. key);
        -- end
            -- raidFrame:RemoveAllAnchors()
            -- raidFrame:AddAnchor("TOPLEFT", "UIParent", settings.raidFrameX, settings.raidFrameY)
    end
    abyssalBar.eventWindow:SetHandler("OnDragStop", abyssalBar.eventWindow.OnDragStop)
    -- Listen for BUBBLE_ACTION_BAR_SHOW and reposition the window when it's called
    function abyssalBar.eventWindow:OnEvent(event)
        if event == "BUBBLE_ACTION_BAR_SHOW" then
            repositionWindow(abyssalBar, settings.abyssalX, settings.abyssalY)
        end
    end
    abyssalBar.eventWindow:SetHandler("OnEvent", abyssalBar.eventWindow.OnEvent)
    abyssalBar.eventWindow:RegisterEvent("BUBBLE_ACTION_BAR_SHOW")

    --- Raid Window
    -- raid frame works off an event of when it toggles on or off
    function onRaidFrameToggle(frame, show)
        raidFrame = frame

        local currentX, currentY = frame:GetOffset()

        -- start the timer to reposition the raid frame later
        moveRaidFrameFlag = true
        -- allow raid frame position to be saved to settings
        saveRaidFrameXYFlag = true

        -- Overwrite the ondragstop event to save raid position settings
        -- api.DoIn(500, api.Log:Info("Hello"))

        -- function frame:OnDragStop()
        --     if frame.moving == true then
        --         frame:StopMovingOrSizing()
        --         frame.moving = false
        --         api.Cursor:ClearCursor()
                
        --         --settings.abyssalX = currentX
        --         --settings.abyssalY = currentY
        --     end
        -- end
        -- frame:SetHandler("OnDragStop", frame.OnDragStop)
        -- frame:RegisterForDrag("LeftButton")
    end
    
    api.On("raid_frame_toggle", onRaidFrameToggle)
    api.On("UPDATE", OnUpdate)

	api.SaveSettings()
end

local function OnUnload()
	local settings = api.GetSettings("sticky_ui")
	local abyssalBar = ADDON:GetContent(UIC.BUBBLE_ACTION_BAR)

    local currentX, currentY = abyssalBar:GetOffset()
    settings.abyssalX = currentX
    settings.abyssalY = currentY

    api.SaveSettings()
end

sticky_ui_addon.OnLoad = OnLoad
sticky_ui_addon.OnUnload = OnUnload

return sticky_ui_addon
