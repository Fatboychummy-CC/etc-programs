--- This program is designed to run a very specific miner made with Create.
--- 
--- Redstone inputs are expected to be as follows:
--- Left: Miner arm at start position
--- Right: Miner arm at end position
--- Front: Miner arm at bottom position
--- Bottom: Miner arm at top position
--- Rear: OUTPUT: Redstone signal to toggle which arm is powered.
--- 
--- When ready to mine, the program will first wait until the arm is in the
--- start position. After that, it will repeat the following steps:
--- 1. Output redstone signal to toggle the active arm to the drills.
--- 2. Toggle on the motor until the arm reaches the end position.
--- 3. Reverse the motor until the arm reaches the start position.
--- 4. Stop the motor, toggle the active arm to the vertical arm, and rotate 180
---    degrees (this moves a gantry exactly one block), then shut down the motor.
--- 5. Repeat from step 1 until the arm reaches the bottom position.


-- Find the electric motor.
local motor = peripheral.find("electric_motor") --[[@as ElectricMotor]]

--- The speed that the drills should be run at. Higher speeds will mine faster
--- but consume significantly more power.
local drill_speed = 256

--- The speed that the drills should be run at when calibrating. The speed
--- should be fast enough to break through one block, in case there's something
--- in the way.
local calibration_drill_speed = 256

--- The speed that the vertical arm should be run at.
local vertical_speed = 32

--- The speed that the vertical arm should be run at when calibrating. Recommend
--- higher speeds just to make this process faster.
local calibration_vertical_speed = 64

--- The speed that the drill arm should retract at.
local retract_speed = 128

--- The speed that the vertical arm should retract at.
local vertical_retract_speed = 16

--- Whether or not the drill direction is inverted. Set this to -1 if the drills
--- are facing the wrong way.
local drills_inverted = 1

--- Whether or not the vertical direction is inverted. Set this to -1 if the
--- vertical arm is facing the wrong way.
local vertical_inverted = 1

local RS_SIDES = {
  OUTPUT = "back",
  START = "left",
  FINISH = "right",
  BOTTOM = "front",
  TOP = "bottom"
}

if not motor then
  error("No electric motor found.", 0)
end

--- Write a line to the terminal, clearing the line first.
---@param y integer The y position to write to.
---@param text string The value to write to the terminal.
local function wroite(y, text)
  term.setCursorPos(1, y)
  term.clearLine()
  write(text)
end

--- Activate the drill arm.
local function activate_drills()
  redstone.setOutput(RS_SIDES.OUTPUT, true)
end

--- Activate the vertical arm.
local function activate_vertical()
  redstone.setOutput(RS_SIDES.OUTPUT, false)
end

--- Sets the active arm to the vertical arm and moves it down a block.
local function go_down()
  activate_vertical()
  sleep(motor.translate(1, vertical_speed * vertical_inverted))
  motor.stop()

  sleep(0.5) -- Prevent too many movement commands being sent at once breaking the machine.
end

--- Run the motor until any of the given sides are triggered.
---@param speed integer The speed to run the motor at. (-256 to 256)
---@param ... string The sides to check for input.
local function run_motor_until_input(speed, ...)
  local sides = table.pack(...)

  local function _check()
    for i = 1, sides.n do
      if redstone.getInput(sides[i]) then
        return true
      end
    end

    return false
  end

  motor.setSpeed(speed)
  while not _check() do
    os.pullEvent("redstone")
  end
  motor.stop()
  sleep(0.5) -- Prevent too many movement commands being sent at once breaking the machine.
end

--- Returns both the vertical and drill arms to the start position.
local function return_home()
  -- Return the drill arm to the start position.
  activate_drills()
  run_motor_until_input(-retract_speed * drills_inverted, RS_SIDES.START)

  sleep(0.5) -- Prevent too many movement commands being sent at once breaking the machine.

  -- Return the vertical arm to the top position.
  activate_vertical()
  run_motor_until_input(-vertical_retract_speed * vertical_inverted, RS_SIDES.TOP)

  motor.stop()

  sleep(0.5) -- Prevent too many movement commands being sent at once breaking the machine.
end

--- Mines a row of blocks.
local function mine_row()
  local _, y = term.getCursorPos()

  -- Toggle the active arm to the drills.
  activate_drills()

  -- Drill until the arm reaches the finish position.
  wroite(y, "Status: Mining")
  run_motor_until_input(drill_speed * drills_inverted, RS_SIDES.FINISH)

  -- Retract the drills.
  wroite(y, "Status: Retracting")
  run_motor_until_input(-retract_speed * drills_inverted, RS_SIDES.START)
end

--- Mine the entire cube.
local function mine()
  local _, y = term.getCursorPos()

  wroite(y, "Status: Ensure Start Position")

  -- Step 1: Ensure the arm is in the start position.
  activate_drills()
  run_motor_until_input(-retract_speed * drills_inverted, RS_SIDES.START)


  -- Step 2: Mine the cube.
  while not redstone.getInput(RS_SIDES.BOTTOM) do
    mine_row()
    wroite(y, "Status: Next Row")
    go_down()
  end

  -- When we're at the bottom, there may still be one more row to mine.
  mine_row()

  -- Step 3: Return the arms to the start position.
  wroite(y, "Status: Returning Home")
  return_home()

  wroite(y, "Status: Done")
end

--- Calibrate the vertical and drill arms. We do this by moving the vertical arm
--- up, then checking if the vertical arm is in the correct position. If it is
--- not, then we invert the vertical direction and move the arm down. We then
--- check the same thing for the drill arm.
local function calibrate()
  print("Running calibration...")

  local drill_ok, vertical_ok = false, false

  -- Stage 1: Calibrate the drill arm.
  activate_drills()

  -- Check 1: Check if drill arm arm is in-between start and finish.
  print("Calibration check 1 (drill arm)")
  if not rs.getInput(RS_SIDES.START) and not rs.getInput(RS_SIDES.FINISH) then
    print(" Drill arm is in-between somewhere.")

    -- Wait for the start OR finish to be triggered.
    run_motor_until_input(calibration_drill_speed, RS_SIDES.START, RS_SIDES.FINISH)

    if rs.getInput(RS_SIDES.FINISH) then
      print("  Drill arm is not inverted.")
    elseif rs.getInput(RS_SIDES.START) then
      print("  Drill arm is inverted.")
      drills_inverted = -1
    end
    drill_ok = true

    -- Retract the drill arm.
    run_motor_until_input(-calibration_drill_speed * drills_inverted, RS_SIDES.START)
  else
    print(" Drill arm is not in-between positions.")
  end

  sleep(0.5) -- Prevent too many movement commands being sent at once breaking the machine.

  -- Check 2: If the drill arm is at the start position, move it
  -- positive. If, after a second, the arm has not moved, then it likely needs
  -- to be inverted. However, for the drill arm we also need to actually confirm
  -- this, as the drill arm could be stuck on a block it is trying to drill.
  print("Calibration check 2 (drill arm)")
  if not drill_ok and rs.getInput(RS_SIDES.START) then
    print(" Drill arm is at start position, moving positive.")
    motor.setSpeed(calibration_drill_speed)

    sleep(1)

    if rs.getInput(RS_SIDES.START) then
      print("  Drill arm might be inverted.")

      -- Confirm by running the drill backwards.
      motor.setSpeed(-calibration_drill_speed)
      sleep(1)

      if rs.getInput(RS_SIDES.START) then
        error("Drill arm is stuck and cannot be calibrated.")
      else
        print("  Drill arm is inverted.")
        drills_inverted = -1
        drill_ok = true
      end

      -- Retract the drill arm.
      run_motor_until_input(-calibration_drill_speed * drills_inverted, RS_SIDES.START)
    else
      print("  Drill arm is not inverted.")
      drill_ok = true

      -- Retract the drill arm.
      run_motor_until_input(-calibration_drill_speed * drills_inverted, RS_SIDES.START)
    end
  elseif not drill_ok then
    print(" Drill arm is not at start position.")
  end

  sleep(0.5) -- Prevent too many movement commands being sent at once breaking the machine.

  -- Check 3: If the drill arm is at the finish position, move it
  -- negative. If, after a second, the arm has not moved, then it likely needs
  -- to be inverted.
  -- Like the previous check, this check will also need to be confirmed by
  -- running the drill backwards.
  print("Calibration check 3 (drill arm)")
  if not drill_ok and rs.getInput(RS_SIDES.FINISH) then
    print(" Drill arm is at finish position, moving negative.")
    motor.setSpeed(-calibration_drill_speed)

    sleep(1)

    if rs.getInput(RS_SIDES.FINISH) then
      print("  Drill arm might be inverted.")

      -- Confirm by running the drill forwards.
      motor.setSpeed(calibration_drill_speed)
      sleep(1)

      if rs.getInput(RS_SIDES.FINISH) then
        error("Drill arm is stuck and cannot be calibrated.")
      else
        print("  Drill arm is inverted.")
        drills_inverted = -1
        drill_ok = true
      end

      -- Retract the drill arm.
      run_motor_until_input(-calibration_drill_speed * drills_inverted, RS_SIDES.START)
    else
      print("  Drill arm is not inverted.")
      drill_ok = true

      -- Retract the drill arm.
      run_motor_until_input(-calibration_drill_speed * drills_inverted, RS_SIDES.START)
    end
  elseif not drill_ok then
    print(" Drill arm is not at finish position.")
  end

  sleep(0.5) -- Prevent too many movement commands being sent at once breaking the machine.

  -- Stage 2: Calibrate the vertical arm.
  activate_vertical()

  -- Check 1: Check if vertical arm arm is in-between top and bottom.
  print("Calibration check 1 (vertical arm)")
  if not rs.getInput(RS_SIDES.TOP) and not rs.getInput(RS_SIDES.BOTTOM) then
    print(" Vertical arm is in-between somewhere.")

    -- Wait for the top OR bottom to be triggered.
    run_motor_until_input(calibration_vertical_speed, RS_SIDES.TOP, RS_SIDES.BOTTOM)

    if rs.getInput(RS_SIDES.BOTTOM) then
      print("  Vertical arm is not inverted.")
    elseif rs.getInput(RS_SIDES.TOP) then
      print("  Vertical arm is inverted.")
      vertical_inverted = -1
    else
      error("Vertical arm is in an unknown position.")
    end
    vertical_ok = true

    -- Retract the vertical arm.
    run_motor_until_input(-calibration_vertical_speed * vertical_inverted, RS_SIDES.TOP)
  else
    print(" Vertical arm is not in-between positions.")
  end

  print("Calibration check 2 (vertical arm)")
  if not vertical_ok and rs.getInput(RS_SIDES.TOP) then
    print(" Vertical arm is at top position, moving positive.")
    motor.setSpeed(calibration_vertical_speed)

    sleep(1)

    if rs.getInput(RS_SIDES.TOP) then
      print("  Vertical arm is inverted.")
      vertical_inverted = -1
    else
      print("  Vertical arm is not inverted.")
    end
    vertical_ok = true

    -- Retract the vertical arm.
    run_motor_until_input(-calibration_vertical_speed * vertical_inverted, RS_SIDES.TOP)
  elseif not vertical_ok then
    print(" Vertical arm is not at top position.")
  end

  print("Calibration check 3 (vertical arm)")
  if not vertical_ok and rs.getInput(RS_SIDES.BOTTOM) then
    print(" Vertical arm is at bottom position, moving negative.")
    motor.setSpeed(-calibration_vertical_speed)

    sleep(1)

    if rs.getInput(RS_SIDES.BOTTOM) then
      print("  Vertical arm is inverted.")
      vertical_inverted = -1
    else
      print("  Vertical arm is not inverted.")
    end
    vertical_ok = true

    -- Retract the vertical arm.
    run_motor_until_input(-calibration_vertical_speed * vertical_inverted, RS_SIDES.TOP)
  elseif not vertical_ok then
    print(" Vertical arm is not at bottom position.")
  end

  return drill_ok, vertical_ok
end

local argument = ...
local drill_ok, vertical_ok

local ok, err = pcall(function()
  drill_ok, vertical_ok = calibrate()

  if argument and argument:lower() == "calibrate" then
    return
  end

  if drill_ok and vertical_ok then
    print("Calibration successful, mining...\n\n")
    write("Status: Initializing...")
    mine()
  else
    error("Calibration failed.", 0)
  end
end)

if not ok then
  printError(err)

  print("Attempting to return arms to start position...")
  pcall(return_home)
end

sleep(0.5)
motor.stop()
rs.setOutput(RS_SIDES.OUTPUT, false)
print("Motor stopped.")

if argument and argument:lower() == "calibrate" then
  print()
  term.setTextColor(colors.white)
  write("Drill arm can ")
  term.setTextColor(drill_ok and colors.green or colors.red)
  print(drill_ok and "be calibrated" or "not be calibrated")

  term.setTextColor(colors.white)
  write("Vertical arm can ")
  term.setTextColor(vertical_ok and colors.green or colors.red)
  print(vertical_ok and "be calibrated" or "not be calibrated")

  term.setTextColor(colors.white)
  write("Drill inversion is ")
  term.setTextColor(drills_inverted == 1 and colors.white or colors.yellow)
  print(drills_inverted == 1 and "not required" or "required")

  term.setTextColor(colors.white)
  write("Vertical inversion is ")
  term.setTextColor(vertical_inverted == 1 and colors.white or colors.yellow)
  print(vertical_inverted == 1 and "not required" or "required")

  term.setTextColor(colors.white)
end