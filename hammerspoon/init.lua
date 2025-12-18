-- WIP: Does not work, need to map to the right colors in hs.color
-- Dump a table into console
function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

--- Gets the current macOS accent color.
--
-- @return {table} A Hammerspoon color table (e.g., hs.drawing.color.red).
function getAccentColor()
    -- This map translates the system's integer value to a color name.
    -- 'Black'
    -- 'Brown'
    -- 'Cyan'
    -- 'White'

    local accentColorMap = {
        ["-1"] = "White",
        ["0"] = "Red",
        ["1"] = "Orange",
        ["2"] = "Yellow",
        ["3"] = "Green",
        ["4"] = "Blue", -- Default
        ["5"] = "Purple",
        ["6"] = "Magenta"
    }

    local status, stdout = hs.execute('defaults read -g AppleAccentColor')

    print(status, stdout)
    -- If the command fails, the accent color is the default blue.
    if not status or not stdout then
        return hs.drawing.color.colorsFor('Apple').Blue
    end

    local accentValue = stdout:match("%d+") or "4"
    local colorName = accentColorMap[accentValue]

    if colorName and hs.drawing.color.colorsFor('Apple')[colorName] then
        return hs.drawing.color.colorsFor('Apple')[colorName]
    else
        -- Fallback to blue if the color is somehow unknown.
        return hs.drawing.color.colorsFor('Apple').Blue
    end
end

--- Gets the current macOS accent color as an AARRGGBB hex string.
--
-- @return {string} The accent color in AARRGGBB format (e.g., "ffff0000" for red).
function getAccentColorHex()
    -- Get the color table from the function in Step 1.
    local colorTable = getAccentColor()

    print(dump(colorTable))

    -- Convert each RGBA component from 0.0-1.0 to an integer from 0-255.
    -- Defaults alpha to 1.0 (fully opaque) if it's missing.
    local a = math.floor((colorTable.alpha or 1.0) * 255)
    local r = math.floor(colorTable.red * 255)
    local g = math.floor(colorTable.green * 255)
    local b = math.floor(colorTable.blue * 255)

    -- Format the integers into two-digit hex values and concatenate them.
    return string.format("%02x%02x%02x%02x", a, r, g, b)
end

function updateBordersColor()
    -- ❗️ Important: You may need to provide the full path to your `borders` tool.
    -- For example, use "/usr/local/bin/borders" or wherever it is installed.
    local bordersPath = "borders"
    local accentHex = getAccentColorHex()

    -- Remove the alpha component for the command, as it expects RRGGBB


    local command = string.format(
        '%s active_color=0x%s inactive_color=0xff494d64 width=7.0',
        bordersPath,
        accentHex
    )

    hs.alert.show(command, 5)
    hs.execute(command)
end

-- ===============================================================
-- Event listener for theme changes
-- ===============================================================

hs.distributednotifications.new(
    function()
        -- Wait a fraction of a second for the system setting to settle
        hs.timer.doAfter(0.1, updateBordersColor)
    end,
    "AppleInterfaceThemeChangedNotification" -- This is the event for accent color/theme changes
):start()

-- Run the function once on startup to set the initial color
updateBordersColor()
