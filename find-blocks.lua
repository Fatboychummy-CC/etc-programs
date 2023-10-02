--[[
  Block finder, by fatboychummy
  Usage: find-blocks.lua <block> [block] [block] ...
  Example: find-blocks.lua minecraft:chest minecraft:ender_chest

  This program will scan the area around the computer for specific blocks, and
  print their locations (if found) to the screen.
]]

local _blocks = table.pack(...)
local blocks = {}
for i = 1, _blocks.n do
  blocks[_blocks[i]] = true
end

local cached_scan
local function scan()
  local result = peripheral.call("back", "scan")
  if result then
    cached_scan = result
  end
  return cached_scan
end

local function find_blocks()
  local data = scan()
  local found_blocks = {}
  for _, block in ipairs(data) do
    if blocks[block.name] then
      table.insert(found_blocks, block)
    end
  end
  return found_blocks
end

while true do
  local positions = find_blocks()
  term.setCursorPos(1, 1)
  term.clear()
  print(("Tracking %d blocks:"):format(#positions))
  table.sort(positions, function(a, b) return a.name < b.name end)
  for _, block in pairs(positions) do
    if blocks[block.name] then
      print(block.name, block.x, block.y, block.z)
    end
  end
  sleep(5)
end