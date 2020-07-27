--[[
    GD50
    Super Mario Bros. Remake

    -- LevelMaker Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

LevelMaker = Class{}

function LevelMaker.generate(width, height)
    local tiles = {}
    local entities = {}
    local objects = {}
    local tileID = TILE_ID_GROUND
    
    -- whether we should draw our tiles with toppers
    local topper = true
    local tileset = math.random(20)
    local topperset = math.random(20)

    local keyBlock = false
    local key = false
    local keyProb = 0
    local colorKey = math.random(#KEYS)
    local pillarFlag = false

    -- insert blank tables into tiles for later access
    for x = 1, height do
        table.insert(tiles, {})
    end

    -- column by column generation instead of row; sometimes better for platformers
    for x = 1, width - 3 do
        local tileID = TILE_ID_EMPTY
        -- lay out the empty space
        for y = 1, 6 do
            table.insert(tiles[y],
                Tile(x, y, tileID, nil, tileset, topperset))
        end

        -- chance to just be emptiness
        if (math.random(7) == 1 and x ~= 1) then
            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, nil, tileset, topperset))
            end
        else
            tileID = TILE_ID_GROUND

            local blockHeight = 4

            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end

            pillarFlag = false
            -- chance to generate a pillar
            if (math.random(8) == 1 and x ~= 1) then
                pillarFlag = true
                blockHeight = 2
                
                -- chance to generate bush on pillar
                if math.random(8) == 1 then
                    table.insert(objects,
                        GameObject {
                            texture = 'bushes',
                            x = (x - 1) * TILE_SIZE,
                            y = (4 - 1) * TILE_SIZE,
                            width = 16,
                            height = 16,
                            
                            -- select random frame from bush_ids whitelist, then random row for variance
                            frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7
                        }
                    )
                end
                
                -- pillar tiles
                tiles[5][x] = Tile(x, 5, tileID, topper, tileset, topperset)
                tiles[6][x] = Tile(x, 6, tileID, nil, tileset, topperset)
                tiles[7][x].topper = nil
            
            -- chance to generate bushes
            elseif math.random(8) == 1 then
                table.insert(objects,
                    GameObject {
                        texture = 'bushes',
                        x = (x - 1) * TILE_SIZE,
                        y = (6 - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                        collidable = false
                    }
                )
            end

            if (not keyBlock and math.random() <= keyProb and not pillarFlag) then
                keyBlock = true
                blocker = GameObject{
                    texture = 'keys',
                    x = (x - 1) * TILE_SIZE,
                    y = 2 * TILE_SIZE,
                    width = 16,
                    height = 16,
                    frame = colorKey + 4,
                    collidable = true,
                    hit = false,
                    solid = true,
                    onCollide = function(player, object)
                        if player.key then
                            gSounds['pickup']:play()
                            player.key = false
                            player.canFinish = true
                            return true
                        end
                        return false
                    end                    
                }
                table.insert(objects, blocker)
            -- chance to spawn a block
            elseif (math.random(10) == 1 and x ~= 1 and x ~= 2) then
                table.insert(objects,

                    -- jump block
                    GameObject {
                        texture = 'jump-blocks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,

                        -- make it a random variant
                        frame = math.random(#JUMP_BLOCKS),
                        collidable = true,
                        hit = false,
                        solid = true,

                        -- collision function takes itself
                        onCollide = function(player, obj)
                            print('entre')
                            -- spawn a gem if we haven't already hit the block
                            if not obj.hit then
                                print('dsbsbfsk')

                                -- chance to spawn gem, not guaranteed
                                if math.random(5) <= 1 then

                                    -- maintain reference so we can set it to nil
                                    local gem = GameObject {
                                        texture = 'gems',
                                        x = (x - 1) * TILE_SIZE,
                                        y = (blockHeight - 1) * TILE_SIZE - 4,
                                        width = 16,
                                        height = 16,
                                        frame = math.random(#GEMS),
                                        collidable = true,
                                        consumable = true,
                                        solid = false,

                                        -- gem has its own function to add to the player's score
                                        onConsume = function(player, object)
                                            gSounds['pickup']:play()
                                            player.score = player.score + 100
                                        end
                                    }
                                    
                                    -- make the gem move up from the block and play a sound
                                    Timer.tween(0.1, {
                                        [gem] = {y = (blockHeight - 2) * TILE_SIZE}
                                    })
                                    gSounds['powerup-reveal']:play()

                                    table.insert(objects, gem)
                                end

                                obj.hit = true
                            end

                            gSounds['empty-block']:play()
                        end
                    }
                )
            end
        end

        -- inserting a key per level
        if (not key and math.random() <= keyProb) then
            key = true
            local key = GameObject{
                texture = 'keys',
                x = (x - 1) * TILE_SIZE,
                y = 2 * TILE_SIZE,
                width = 16,
                height = 16,
                frame = colorKey,
                collidable = true,
                consumable = true,
                solid = false,
                onConsume = function(player, object)
                    gSounds['pickup']:play()
                    player.key = true
                end
            }
            table.insert(objects, key)
        end

        -- this way, there always going to be a 100% of spawning a block and key on a map
        if x <= width / 2 then
            keyProb = keyProb + 0.0005
        else
            keyProb = keyProb + (1 / width) + 0.0095
        end
    end

    for x = width - 2, width do
        for y = 1, 6 do
            table.insert(tiles[y], Tile(x, y, TILE_ID_EMPTY, nil, tileset, topperset))
        end
        for y = 7, height do
            table.insert(tiles[y], Tile(x, y, TILE_ID_GROUND, y == 7 and topper or nil, tileset, topperset))
        end
    end

    -- adding the pole and flag at the end of the level
    local pole = GameObject{
        texture = 'poles',
        x = (width - 2) * TILE_SIZE,
        y = 3 * TILE_SIZE,
        width = 8,
        height = 30,
        frame = math.random(#POLES),
        collidable = true, 
        hit = false,
        solid = false
    }
    table.insert(objects, pole)

    local flag = GameObject{
        texture = 'flags',
        x = (width - 2) * TILE_SIZE,
        y = 3 * TILE_SIZE,
        width = 16,
        height = 16,
        frame = 1,
        collidable = true,
        hit = false,
        solid = true,
        onCollide = function(player, object)
            if player.canFinish then
                gStateMachine:change('play', {
                    score = player.score,
                    width = width + 20
                })
            end
        end
    }
    table.insert(objects, flag)

    local map = TileMap(width, height)
    map.tiles = tiles
    return GameLevel(entities, objects, map)
end