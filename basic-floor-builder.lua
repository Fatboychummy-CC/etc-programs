local function get_item()
  for i = 1, 16 do
    if turtle.getItemCount(i) > 0 then
      turtle.select(i)
      return
    end
  end
  error("Out of items", 0)
end

local n = 0
while true do
  while turtle.back() do
    get_item()
    turtle.place()
    n = 0
  end

  turtle.turnRight()
  n = n + 1
  if n >= 4 then
    if ... then
      turtle.down()
      get_item()
      turtle.placeUp()
    else
      turtle.up()
      get_item()
      turtle.placeDown()
    end
    return
  end
end
