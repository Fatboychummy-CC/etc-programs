---@meta

--#region Base Classes

---@class CreateAdditionBase
local create_addition_base = {}

--- Get the type of the Create addition.
---@return string type The type of the Create addition.
function create_addition_base.getType() end


---@class CreateAdditionEnergyIO
local create_addition_energy = {}

--- Get the maximum amount of energy that can be inserted into the motor per tick.
---@return integer energy The maximum energy input rate of the motor, in FE/t.
function create_addition_energy.getMaxInsert() end

--- Get the maximum amount of energy that can be extracted from the motor per tick (always 0).
---@return 0 energy The maximum energy output rate of the motor, in FE/t.
function create_addition_energy.getMaxExtract() return 0 end


---@class CreateAdditionEnergyStorage
local create_addition_energy_storage = {}

--- Get the current energy stored in the motor.
---@return integer energy The current energy stored in the motor, in FE.
function create_addition_energy_storage.getEnergy() end

--- Get the maximum amount of energy that can be stored in the motor.
---@return integer energy The maximum energy capacity of the motor, in FE.
function create_addition_energy_storage.getCapacity() end

--#endregion Base Classes

--#region Electric Motor

---@class ElectricMotor : CreateAdditionBase, CreateAdditionEnergyIO
local electric_motor = {}

--- Sets the speed of the electric motor to the given RPM.
---@param rpm integer The speed to set the motor to, in RPM (-256 to 256).
function electric_motor.setSpeed(rpm) end

--- Stops the electric motor, a shorthand for `setSpeed(0)`.
function electric_motor.stop() end

--- Returns the time it will take to rotate the motor the given number of degrees at the given speed.
---@param degrees integer The number of degrees to rotate the motor.
---@param rpm integer? The speed to rotate the motor at, in RPM (-256 to 256). If not given, the motor will rotate at the last set speed.
---@return number turn_time The number of seconds the motor will take to rotate the given number of degrees.
function electric_motor.rotate(degrees, rpm) end

--- Returns the time it will take to translate a gantry shaft (or push a piston) a specific amount of blocks at the given speed.
---@param blocks integer The number of blocks to translate the gantry shaft.
---@param rpm integer? The speed to translate the gantry shaft at, in RPM (-256 to 256). If not given, the motor will translate at the last set speed.
---@return number move_time The number of seconds the motor will take to translate the given number of blocks.
function electric_motor.translate(blocks, rpm) end

--- Get the current speed of the electric motor.
---@return integer rpm The current speed of the motor, in RPM (-256 to 256).
function electric_motor.getSpeed() end

--- Get the stress capacity of the electric motor.
---@return integer stress The maximum stress the motor can handle, in Stress Units (SU).
function electric_motor.getStressCapacity() end

--- Get the energy consumption of the motor.
---@return integer energy The energy consumption of the motor, in FE/t.
function electric_motor.getEnergyConsumption() end

--- Get the type of the Create addition.
---@return "electric_motor" type The type of the Create addition.
function create_addition_base.getType() return "electric_motor" end

--#endregion Electric Motor

--#region Accumulator

---@class Accumulator : CreateAdditionBase, CreateAdditionEnergyStorage, CreateAdditionEnergyIO
local accumulator = {}

--- Returns the percentage total charge of the accumulator.
---@return number charge The percentage of the accumulator's total charge.
function accumulator.getPercent() end

--- Get the height of the accumulator.
---@return integer height The height of the accumulator, in blocks.
function accumulator.getHeight() end

--- Get the width of the accumulator.
---@return integer width The width of the accumulator, in blocks.
function accumulator.getWidth() end

--- Get the type of the Create addition.
---@return "modular_accumulator" type The type of the Create addition.
function create_addition_base.getType() return "modular_accumulator" end

--#endregion Accumulator

--#region Portable Energy Interface

---@class PortableEnergyInterface : CreateAdditionBase, CreateAdditionEnergyStorage, CreateAdditionEnergyIO
local portable_energy_interface = {}

--- Check if a contraption is connected.
---@return boolean connected Whether a contraption is connected to the portable energy interface.
function portable_energy_interface.isConnected() end

--- Get the type of the Create addition.
---@return "portable_energy_interface" type The type of the Create addition.
function create_addition_base.getType() return "portable_energy_interface" end

--#endregion Portable Energy Interface

--#region Redstone Relay

---@class RedstoneRelay : CreateAdditionBase, CreateAdditionEnergyIO
local redstone_relay = {}

--- Get the current energy throughput in FE/t.
---@return integer energy The current energy throughput of the redstone relay, in FE/t.
function redstone_relay.getThroughput() end

--- Check if the relay is powered.
---@return boolean powered Whether the redstone relay is powered.
function redstone_relay.isPowered() end

--- Get the type of the Create addition.
---@return "redstone_relay" type The type of the Create addition.
function create_addition_base.getType() return "redstone_relay" end

--#endregion Redstone Relay