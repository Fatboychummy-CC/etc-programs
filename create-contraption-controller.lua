--- This simple program is designed to control a contraption from Create.
--- This is designed for a two-way contraption, where the contraption moves back
--- and forth.
---
--- The program will send the contraption down one way, wait for a redstone
--- pulse on one side of the computer, then let the contraption go back the
--- original positon (again waiting for a redstone pulse to confirm this).
--- Finally, it will wait a specific amount of time before repeating the
--- process.

--##############################################
--#                   Config                   #
--# ========================================== #
--#   The user should change these values as   #
--#     needed to match their contraption.     #
--##############################################

-- The name of the contraption, not required, but displayed on the computer.
local contraption_name = "contraption"

-- The side of the computer the gearshift is on, redstone will be outputted here to control the gearshift.
local gearshift_side = "left"

-- The default state of the gearshift, false for off, true for on.
local gearshift_default = false

-- The side of the computer the 'idle' redstone input is on, this is used to detect when the contraption has returned
local idle_redstone_input_side = "right"

-- The side of the computer the 'end' redstone input is on, this is used to detect when the contraption has made it to the end of its run
local end_redstone_input_side = "left"

-- The maximum amount of time the contraption will be allowed to send the contraption forth before timing out and forcing it to return.
local max_run_time = 10

-- The maximum amount of time the contraption will be allowed to send the contraption back before timing out and assuming it has returned.
local max_return_time = 10

-- The amount of time the contraption will wait before sending the contraption back.
local wait_time = 30

--##############################################
--#                 End Config                 #
--##############################################

local current_state = "idle"
local w, h = term.getSize()
local log_win = window.create(term.current(), 1, h - 10, w, 10)
local main_win = window.create(term.current(), 1, 1, w, h - 11)
term.redirect(main_win)

--- Log a message to the log window.
local function log(msg)
  log_win.scroll(1)
  log_win.setCursorPos(1, 10)
  log_win.write(msg)
  main_win.restoreCursor()
end

--- Wait for a redstone pulse on a specific side, or a timeout.
--- @param side string The side to wait for a redstone pulse on.
--- @param timeout number The amount of time to wait before timing out.
--- @return boolean Whether or not a redstone pulse was detected.
local function wait_for_redstone_pulse(side, timeout)
  local timer = os.startTimer(timeout)
  while true do
    local event, _side = os.pullEvent()
    if event == "redstone" and _side == side then
      return true
    elseif event == "timer" and _side == timer then
      return false
    end
  end
end

--- Display stats about the contraption.
local function display_stats()
  term.clear()
  term.setCursorPos(1, 1)
  print("Contraption: " .. contraption_name)
  print("Gearshift Side: " .. gearshift_side)
  print("Gearshift Default: " .. tostring(gearshift_default))
  print("Idle Redstone Input Side: " .. idle_redstone_input_side)
  print("End Redstone Input Side: " .. end_redstone_input_side)
  print("Max Run Time: " .. max_run_time)
  print("Max Return Time: " .. max_return_time)
  print("Wait Time: " .. wait_time)
  print()
end

local function display_state()
  local x, y = term.getCursorPos()
  term.setCursorPos(1, y)
  term.clearLine()
  term.write("Current State: " .. current_state)
end

--- Send the contraption forth.
local function send_forth()
  log("Sending contraption forth.")
  redstone.setOutput(gearshift_side, not gearshift_default)
  current_state = "running"
  display_state()
end

--- Send the contraption back.
local function send_back()
  log("Sending contraption back.")
  redstone.setOutput(gearshift_side, gearshift_default)
  current_state = "returning"
  display_state()
end

--- Wait for the contraption to return.
---@return boolean returned Whether or not the contraption returned.
local function wait_for_return()
  log("Waiting for contraption to return.")
  return wait_for_redstone_pulse(idle_redstone_input_side, max_return_time)
end

--- Wait for the contraption to reach the end.
---@return boolean reached_end Whether or not the contraption reached the end.
local function wait_for_end()
  log("Waiting for contraption to reach the end.")
  return wait_for_redstone_pulse(end_redstone_input_side, max_run_time)
end

-- Main loop
display_stats()
while true do
  send_forth()
  local reached = wait_for_end()
  if not reached then
    log("Contraption did not reach the end in time, assuming it has reached the end.")
  end
  send_back()
  local returned = wait_for_return()
  if not returned then
    log("Contraption did not return in time, assuming it has returned.")
  end

  log(("Waiting %d seconds before repeating."):format(wait_time))
  current_state = "waiting"
  display_state()
  sleep(wait_time)
end