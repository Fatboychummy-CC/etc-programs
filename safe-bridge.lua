--[[
  Safe Bridge: Build a bridge to the other side of the chasm.

  This program is designed to be run on a turtle that is on the same level as
  the chasm, and will build a bridge across the chasm. It will build the bridge
  out of any block that it has in its inventory, and will stop when it runs out
  of blocks, or it reaches the other end (if it detects blocks below it), or it
  reaches the max distance.

  It builds a bridge in the v-shaped pattern below:

  # #
   #
  
  This prevents players from getting knocked off at the slightest touch.
]]

local length = ...
if length then
  length = tonumber(length) or error("Invalid length")
else
  print("No length specified, the turtle will travel until it runs out of blocks or it reaches the end of the chasm.")
  length = math.huge
end


--- Find any block in the inventory, and return the slot number. Returns nil if no blocks are found.
---@return integer? slot The slot number of the block, or nil if no blocks are found.
local function find_any_block()
  for i = 1, 16 do
    if turtle.getItemCount(i) > 0 then
      return i
    end
  end

  return nil
end

--- Place a block in the specified direction, first finding a block in the inventory to use.
---@param direction "forward"|"down"|"up" The direction to place the block in.
---@return boolean true if a block was placed, false otherwise.
local function placement_wrapper(direction)
  local slot = find_any_block()

  if not slot then
    return false
  end

  turtle.select(slot)
  if direction == "forward" then
    turtle.place()
    return true
  elseif direction == "down" then
    turtle.placeDown()
    return true
  elseif direction == "up" then
    turtle.placeUp()
    return true
  end

  error("Invalid placement direction: " .. direction, 2)
end

--- Check if the inventory is full.
local function set_bridge_piece()
  local slot = find_any_block()

  if not slot then
    return false
  end

  local a = placement_wrapper "down"

  -- place on the right side
  turtle.turnRight()
  local b = placement_wrapper "forward"

  -- place on the left side
  turtle.turnRight()
  turtle.turnRight()
  local c = placement_wrapper "forward"

  -- return to the original direction
  turtle.turnRight()
  return a and b and c
end

--- Build a bridge across the chasm.
local function build_bridge()
  for i = 1, length do
    if not set_bridge_piece() then
      print("Out of blocks, stopping.")
      return
    end

    if i % 10 == 0 then
      if length == math.huge then
        print(("Distance: %d"):format(i))
      else
        print(("Distance: %d/%d"):format(i, length))
      end
    end

    if not turtle.forward() then
      print("Hit a wall, stopping.")
      return
    end
    if turtle.detectDown() then
      print("Reached the end of the chasm, stopping.")
      return
    end
  end

  print("Reached the end of the bridge, stopping.")
end

build_bridge()