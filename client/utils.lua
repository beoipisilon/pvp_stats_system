-----------------------------------------------------------------------------------------------------------------------------------------
-- FUNCTIONS
-----------------------------------------------------------------------------------------------------------------------------------------
function drawTxt(text,font,x,y,scale,r,g,b,a)
	SetTextFont(font)
	SetTextScale(scale,scale)
	SetTextColour(r,g,b,a)
	SetTextOutline()
	SetTextCentre(1)
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(x,y)
end


function getHitLocation(entity)
    local _, bone = GetPedLastDamageBone(entity)

    -- Map bone IDs to hit location names
    -- Top of the body
    if bone == 31086 or bone == 1356 or bone == 11174 or bone == 29868 or bone == 37193 or 
       bone == 19336 or bone == 21550 or bone == 46240 or bone == 47419 or bone == 49979 or 
       bone == 47495 or bone == 17719 or bone == 20279 or bone == 20178 then
        return "Head"

    -- Middle Body
    elseif bone == 23553 or bone == 24816 or bone == 24817 or bone == 24818 or 
           bone == 11816 or bone == 39317 or bone == 64856 then
        return "Middle"

    -- Bottom Body
    elseif bone == 58271 or bone == 51826 or bone == 14201 or bone == 52301 or 
           bone == 36864 or bone == 64017 or bone == 45509 or bone == 40269 or 
           bone == 61163 or bone == 28252 or bone == 57005 or bone == 6286 or 
           bone == 36029 or bone == 2992 or bone == 22711 or bone == 16335 or 
           bone == 46078 or bone == 2098 or bone == 20781 then
        return "Bottom"
    else
        return "Other"
    end
end


function formatHitLocations(hitLocations)
    local locationCount = {}

    -- Counting locations
    for _, location in ipairs(hitLocations) do
        if locationCount[location] then
            locationCount[location] = locationCount[location] + 1
        else
            locationCount[location] = 1
        end
    end

    local formattedLocations = {}

    -- Formatting of locations
    for location, count in pairs(locationCount) do
        table.insert(formattedLocations, location .. " (" .. count .. ")")
    end

    -- Returning a concatenated string of locations
    return table.concat(formattedLocations, ", ")
end
