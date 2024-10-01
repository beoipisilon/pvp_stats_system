Games = {}
Games.data = {
    ['matchmaking-01'] = {
        players = {
            data = {
                attackers = {
                    [10] = { nick = 'MidnightWolf', group = 'group:10', leader = true, source = 3}, -- Implemented source
                    -- ...
                },
                defenders = {
                    [6] = { nick = 'ThunderBolt', group = 'group:6', leader = true, source = 4 }, -- Implemented source
                    -- ...
                }
            }
        },
        rounds = {
            current = 1,
            data = {
                [1] = { 
                    combatStats = {}  -- Will store combat data for this round
                }
            }
        }
    }
}

local inGame = true 
local openTab = false 

-- Update damage event functions and handlers
AddEventHandler("gameEventTriggered", function(eventName, args)
    if eventName == 'CEventNetworkEntityDamage' then
        local victim, attacker, _, weaponHash, isMelee = args[1], args[2], args[4], args[5], args[10]
        if IsEntityAPed(victim) and IsEntityAPed(attacker) then
            local attackSource = GetPlayerServerId(NetworkGetPlayerIndexFromPed(attacker))
            local victimSource = GetPlayerServerId(NetworkGetPlayerIndexFromPed(victim))
            if attackSource and victimSource then
                local weapon = ({GetCurrentPedWeapon(attacker)})[2]
                local weaponName = Config.Weapons[GetHashKey(weapon)] or "Unknown"
                local damageDealt = 10
                local damageReceived = damageDealt
                local victimDied = IsEntityDead(victim)

                -- Get hit locations
                local hitLocations = getHitLocation(victim)
                local hitsLanded = #hitLocations

                registerCombatStats(
                    Games.data['matchmaking-01'].rounds.current,
                    attackSource,
                    victimSource,
                    damageDealt,
                    damageReceived,
                    hitsLanded,
                    hitLocations,
                    weaponName,
                    victimDied  -- Passes victim death status
                )
            end
        end
    end
end)

--- Registers combat statistics between two players during a round.
---@param round number: The current round number.
---@param attacker number: The source ID of the player who dealt damage.
---@param defender number: The source ID of the player who received damage.
---@param damageDealt number: The damage dealt by the attacker.
---@param damageReceived number: The damage received by the defender.
---@param hitsLanded number: The number of hits landed by the attacker.
---@param hitLocations table: Locations of the hits on the defender (e.g., {"Head", "Torso"}).
---@param weaponUsed string: The model of the weapon used by the attacker.
---@param victimDied boolean: If the victim died after the attack.
function registerCombatStats(round, attacker, defender, damageDealt, damageReceived, hitsLanded, hitLocations, weaponUsed, victimDied)
    local gamesData = Games.data['matchmaking-01']
    
    if not gamesData then 
        print('_game not found')
        return false 
    end

    local attackerName, defenderName = 'Unknown', 'Unknown'
    local damageReceveid = hitLocations == "Head" and 100 or (damageDealt * hitsLanded)

    -- Find attacker and defender names
    for k,v in pairs(gamesData.players.data.attackers) do
        if v.source == attacker then
            attackerName = v.nick
        end  
    end

    for k,v in pairs(gamesData.players.data.defenders) do 
        if v.source == defender then
            defenderName = v.nick
        end  
    end

    local roundData = gamesData.rounds.data[round].combatStats

    -- Initialize if it doesn't exist
    if not roundData[attacker] then
        roundData[attacker] = {}
    end

    if not roundData[defender] then
        roundData[defender] = {}
    end

    -- Register or update attacker data
    local attackerCombat = nil
    for _, combat in pairs(roundData[attacker]) do
        if combat.playerName == defenderName then
            attackerCombat = combat
            break
        end
    end

    if not attackerCombat then
        attackerCombat = {
            totalHits = 1,
            hitLocations = {hitLocations},
            hitLocationsReceveid = {},
            weaponUsed = weaponUsed,
            playerName = defenderName,
            damage = damageReceveid,
            damageReceived = 0,
            kill = false
        }
        table.insert(roundData[attacker], attackerCombat)
    else
        attackerCombat.totalHits = attackerCombat.totalHits + 1
        attackerCombat.damage = attackerCombat.damage + damageReceveid
        table.insert(attackerCombat.hitLocations, hitLocations)
    end


    -- Register or update defender data
    local defenderCombat = nil
    for _, combat in pairs(roundData[defender]) do
        if combat.playerName == attackerName then
            defenderCombat = combat
            break
        end
    end

    if not defenderCombat then
        defenderCombat = {
            totalHits = 1,
            hitLocations = {},
            hitLocationsReceveid = {hitLocations},
            weaponUsed = weaponUsed,
            playerName = attackerName,
            damage = 0,
            damageReceived = damageReceveid,
            killer = nil
        }
        table.insert(roundData[defender], defenderCombat)
    else
        defenderCombat.totalHits = defenderCombat.totalHits + 1
        defenderCombat.damageReceived = defenderCombat.damageReceived + damageReceveid
        table.insert(defenderCombat.hitLocationsReceveid, hitLocations)
    end

    if victimDied then
        attackerCombat.kill = true
        defenderCombat.killer = attackerName
    end
end

-- Displays combat report when the player dies
function drawCombatReport(playerSource)
    local roundData = Games.data['matchmaking-01'].rounds.data[Games.data['matchmaking-01'].rounds.current].combatStats
    if not roundData[playerSource] then 
        return
    end

    openTab = true

    for _,combat in pairs(roundData[playerSource]) do
        local totalHitsTaken = combat.totalHits
        local hitLocations = combat.hitLocations or {}
        local hitLocationsReceive = combat.hitLocationsReceveid or {}
        local formattedHitLocations = formatHitLocations(hitLocations)
        local formattedHitLocationsReceived = formatHitLocations(hitLocationsReceive)
        while openTab do 
            drawTxt("Total Hits Taken: ~y~" .. totalHitsTaken, 4, 0.10, 0.81, 0.40, 255, 255, 255, 180)
            drawTxt("Hit Locations: " .. formattedHitLocations, 4, 0.10, 0.83, 0.40, 255, 255, 255, 180)
            drawTxt("Damage Caused: ~r~" .. combat.damage, 4, 0.10, 0.85, 0.40, 255, 255, 255, 180)
            drawTxt("Player: ~p~" .. (combat.playerName or "Unknown"), 4, 0.10, 0.87, 0.40, 255, 255, 255, 180)
            if (combat.killer) then 
                drawTxt("Killer: " .. (combat.killer or "Unknown"), 4, 0.10, 0.89, 0.40, 255, 255, 255, 180)
            else 
                drawTxt("Kill: "..(combat.kill and "~g~ Yes" or "~r~ No" ), 4, 0.10, 0.89, 0.40, 255, 255, 255, 180)
            end

            drawTxt("Hit Locations Received:" .. formattedHitLocationsReceived, 4, 0.10, 0.91, 0.40, 255, 255, 255, 180)
            drawTxt("Damage Received: ~r~" .. combat.damageReceived, 4, 0.10, 0.93, 0.40, 255, 255, 255, 180)


            if IsControlJustPressed(0, 177) then
                openTab = false
            end
    
            Citizen.Wait(4)
        end
    end
end

-- Thread to check and open the combat report
Citizen.CreateThread(function()
    local playerSource = GetPlayerServerId(PlayerId())
    print('Player Source: ' .. playerSource)
    while true do
        local waitTime = 500
        if inGame then 
            waitTime = 5
            if IsControlJustPressed(0, 38) and not openTab then
                drawCombatReport(playerSource)
            end
        end 
        
        Citizen.Wait(waitTime)
    end
end)
