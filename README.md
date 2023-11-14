# etc-programs

Random programs that I have made throughout my time.

## Current program list:

### Basic Farm ([basic-farm.lua](basic-farm.lua))
A very simple farming program that just spins on the spot and farms the block in
around it. Due to its nature, it does not need fuel to run. Just let it go with
a couple of seeds, and it should be fine. Come back every now and then and
collect your crops.

#### Install
```
wget https://raw.githubusercontent.com/Fatboychummy-CC/etc-programs/main/basic-farm.lua
```

### Find Blocks ([find-blocks.lua](find-blocks.lua))
A program that will find a block around a scanner. It will return the
coordinates of the block.

This program is designed for scanning pocket computers (either geoscanner or
block scanner).

#### Install
```
wget https://raw.githubusercontent.com/Fatboychummy-CC/etc-programs/main/find-blocks.lua
```

### Create Contraption Controller ([create-contraption-controller.lua](create-contraption-controller.lua))
A program that will control a contraption from Create. It will send the
contraption down one way, wait for a redstone pulse on one side of the
computer, then let the contraption go back the original positon (again waiting
for a redstone pulse to confirm this). Finally, it will wait a specific amount
of time before repeating the process.

This program is designed for two-way contraptions, where the contraption moves
back and forth.

#### Install
```
wget https://raw.githubusercontent.com/Fatboychummy-CC/etc-programs/main/create-contraption-controller.lua
```

### RFTools Dimensions Researcher ([rftools-dimensions-researcher.lua](rftools-dimensions-researcher.lua))
A program that will research all the lost knowledge in a Knowledge Holder and
replace the learned knowledge back into the Knowledge Holder.

This program is designed for RFTools Dimensions' Knowledge Holder and Researcher
blocks.

#### Install
```
wget https://raw.githubusercontent.com/Fatboychummy-CC/etc-programs/main/rftools-dimensions-researcher.lua
```

### Safe Bridge ([safe-bridge.lua](safe-bridge.lua))
A quick bridge program to get you across a chasm. It will place blocks in a 'v'
shape in a straight line until it detects a block beneath or in front of it, or
until a specified max distance.

#### Install
```
wget https://raw.githubusercontent.com/Fatboychummy-CC/etc-programs/main/safe-bridge.lua
```