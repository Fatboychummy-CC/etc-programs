--- Launcher program to launch computers by their IDs.
---
--- Requires my catppuccin library.
--- https://github.com/Fatboychummy-CC/Libraries/blob/main/catppuccin.lua

--- Create a file named `computer_data.lua` in the same directory as this program, then add the following:
--- ```lua
--- return {
---  [computer_id] = "Computer Name",
---  -- ...
--- }
--- ```
--- Of course, replace 'computer_id' and "Computer Name" with your actual computer ID and name.
--- The program will then display these, and allow you to select them as a list.

---@module 'periphemu'

local catppuccin = require "catppuccin"
local pal = catppuccin.set_palette "mocha"

term.setBackgroundColor(pal.base)
term.setTextColor(pal.text)
term.clear()
term.setCursorPos(1, 1)

term.setBackgroundColor(pal.overlay_0)
term.clearLine()
term.write(" Computer Launcher")

local function draw_box(x, y, width, height)
  local txt = (' '):rep(width)

  for i = 0, height - 1 do
    term.setCursorPos(x, y + i)
    term.write(txt)
  end
end

local w, h = term.getSize()

local sw, sh = w - 2, h - 3
term.setBackgroundColor(pal.surface_0)
draw_box(2, 3, sw, sh) -- Main box

local main_win = window.create(term.current(), 3, 4, sw - 2, sh - 2)
main_win.setBackgroundColor(pal.surface_0)
main_win.setTextColor(pal.text)
main_win.clear()

local selector = '>'
local selected = 1
local scroll_index = 0
local computer_data = require "computer_data"

local selections = {}
for id, name in pairs(computer_data) do
  table.insert(selections, { id = id, name = name })
end

table.sort(selections, function(a, b) return a.id < b.id end)

local longest_id = 0
for _, entry in ipairs(selections) do
  local id_length = #tostring(entry.id)
  if id_length > longest_id then
    longest_id = id_length
  end
end



local function select_computer()
  local selection = scroll_index + selected
  if selections[selection] then
    local id = selections[selection].id
    main_win.setBackgroundColor(pal.base)
    main_win.clear()
    main_win.setCursorPos(2, 2)

    if periphemu.create(id, "computer") then
      main_win.setTextColor(pal.blue)
      main_win.write("Launched computer with ID " .. id)
    else
      main_win.setTextColor(pal.red)
      main_win.write("Failed to launch computer with ID " .. id .. ".")
      main_win.setCursorPos(2, 4)
      main_win.write("Is that computer already running?")
    end

    sleep(3)
  end
end



local mww, mwh = main_win.getSize()
local function refresh()
  main_win.setVisible(false) -- Stop updating the screen
  main_win.setBackgroundColor(pal.surface_0)
  main_win.clear()

  local to_display = {}
  for i = scroll_index + 1, mwh + scroll_index do
    if selections[i] then
      table.insert(to_display, selections[i])
    end
  end

  for i = 1, #to_display do
    local entry = to_display[i]
    main_win.setCursorPos(1, i)
    if i == selected then
      main_win.setTextColor(pal.yellow)
      main_win.write(selector)
    else
      main_win.write(' ')
    end

    main_win.setTextColor(pal.text)
    main_win.write((" [%%%ds] : %%s"):format(longest_id):format(entry.id, entry.name))
  end

  main_win.setVisible(true) -- Resume updating the screen

  --[[ Debug information
  term.setBackgroundColor(pal.base)
  term.setCursorPos(1, h)
  term.clearLine()
  term.setTextColor(pal.text)
  term.write(("Sel: %d | Scroll: %d | Total: %d"):format(selected, scroll_index, #selections))--]]
end

while true do
  refresh()
  local _, key = os.pullEvent("key")

  if key == keys.up then
    if selected > 1 then
      selected = selected - 1
    elseif scroll_index > 0 then
      scroll_index = scroll_index - 1
    else
      -- At the top, rotate around.
      scroll_index = math.max(0, #selections - mwh)
      selected = math.min(mwh, #selections)
    end
  elseif key == keys.down then
    if scroll_index + selected < #selections then
      if selected < mwh then
        selected = selected + 1
      else
        scroll_index = scroll_index + 1
      end
    else
      -- At the bottom, rotate around.
      scroll_index = 0
      selected = 1
    end
  elseif key == keys.enter then
    select_computer()
  elseif key == keys.q then
    break
  end
end

catppuccin.reset_palette()
