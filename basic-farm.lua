-- CHANGE DEPENDING ON YOUR CROP
local SEED_NAME = "minecraft:wheat_seeds" -- Set this to nil to select any item with the word "seed" in its name
local GROWN_AGE = 7

--- Find any seed in the inventory, and return the slot number. Returns nil if no seeds are found.
---@return number|nil slot number of the seed, or nil if no seeds are found 
local function find_any_seed()
  for i = 1, 16 do
    local item = turtle.getItemDetail(i)
    if item and (SEED_NAME and item.name == SEED_NAME or item.name:find("seed")) then
      return i
    end
  end
  return nil
end

--- Check if the inventory is full. We only need to check if the last slot contains items, as we only ever add items to the first slot available.
---@return boolean true if the inventory is full, false otherwise
local function inv_full()
  return turtle.getItemCount(16) > 0
end

turtle.select(1) -- ensure we start with the first slot selected

-- Main loop: spin around and harvest crops
while true do
  while inv_full() do
    printError("Inventory is full! Waiting to be emptied...")
    sleep(30)
  end

  repeat
    print("Checking...")
    local is_block, block = turtle.inspect()
    if not is_block or block.state.age == GROWN_AGE then
      print(is_block and "Harvesting..." or "Hoeing...")
      -- ensure there is farmland (requires hoe!), or dig the finished crop
      turtle.dig()

      -- plant a seed if we have one
      print("Planting...")
      local seed_slot = find_any_seed()
      if seed_slot then
        turtle.select(seed_slot)
        turtle.place()
        print("Done.")
      else
        printError("No seeds found!")
      end
    end

    -- Turn to the next crop
    turtle.turnRight()
  until is_block and block.state.age ~= GROWN_AGE -- continue spinning and digging until nothing is left to harvest, and there is a crop in front of us.

  print("Waiting...")
  sleep(30) -- wait a bit for the crops to grow back
end
