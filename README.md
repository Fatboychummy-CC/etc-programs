# etc-programs

Random programs that I have made throughout my time.

## Current program list:

### Basic Farm ([basic-farm.lua](basic-farm.lua))
A very simple farming program that just spins on the spot and farms the block in
around it. Due to its nature, it does not need fuel to run. Just let it go with
a couple of seeds, and it should be fine. Come back every now and then and
collect your crops.

#### Install
[![Install from PineStore!](https://raster.shields.io/badge/dynamic/json?url=https%3A%2F%2Fpinestore.cc%2Fapi%2Fproject%2F25&query=%24.project.downloads&suffix=%20downloads&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHN2ZyB3aWR0aD0iNzYuOTA0IiBoZWlnaHQ9Ijg5LjI5NSIgcHJlc2VydmVBc3BlY3RSYXRpbz0ieE1pZFlNaWQiIHZlcnNpb249IjEuMSIgdmlld0JveD0iMCAwIDc2OS4wNCA4OTIuOTUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI%2BCiA8ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgtMTQuNzQgLTQuNjgyNikiIGZpbGw9IiM5YWIyZjIiPgogIDxwYXRoIGQ9Im00MTAgODUxYzAtMTIgMjYtMjEgNTgtMjEgMTUgMCAyMiA0IDE3IDktMTQgMTItNzUgMjItNzUgMTJ6Ii8%2BCiAgPHBhdGggZD0ibTU4NSA3NDJjLTEtNDkgNC03MiAxNi04NSAyMi0yNCAzMC02OCAxNi04Ni0xMi0xNC0yNy0zOS00OC03OC0xMC0xOS05LTI2IDQtNDEgMjItMjQgMjEtNjctMi0xNDQtMjEtNjktMzktMTQ0LTQ4LTE5NS00LTI2LTItMzMgMTEtMzMgMzEgMCAxMTIgMzMgMTQxIDU4IDI4IDIzIDgxIDkyIDcxIDkyLTIgMCA1IDI2IDE2IDU3IDI4IDc5IDI5IDIyNCAzIDMwOC0xMCAzMy0xOSA2Mi0xOSA2NS00IDI2LTEzMiAxNTAtMTU1IDE1MC0zIDAtNi0zMC02LTY4eiIvPgogIDxwYXRoIGQ9Im02OCA2NzNjLTcyLTEwOS03MS0yNzggMy00MjMgMzYtNzEgNjItMTAwIDEyOC0xNDAgNDMtMjcgNjUtMzQgMTE4LTM2IDEwMC00IDk4IDExLTE5IDEzNi0zNCAzNy03OCA4OC05NiAxMTMtMjggMzktMzEgNDgtMjEgNjUgMTEgMTcgNiAyNy0zMyA3OS00MCA1My00NCA2Mi0zMiA3OCAxNyAyMyAxOCA1NyAyIDczLTYgNi0xNCAzMS0xNyA1NC02IDQyLTYgNDItMzMgMXoiLz4KIDwvZz4KIDxnIHRyYW5zZm9ybT0idHJhbnNsYXRlKC0xNC43NCAtNC42ODI2KSIgZmlsbD0iIzU5YTY0ZiI%2BCiAgPHBhdGggZD0ibTM2NSA4MTNjLTUzLTYtMTM5LTMzLTE5Mi02MS02OC0zNS04My02Ny01OC0xMjIgMjYtNTkgNDAtNjcgNzgtNDkgNjggMzMgMTY3IDU4IDI2NiA2OSA1OCA1IDEwNiAxMiAxMDkgMTQgMiAzIDYgMzIgOSA2NSA4IDg1IDAgOTEtMTAxIDkwLTQ0LTEtOTQtNC0xMTEtNnoiLz4KICA8cGF0aCBkPSJtNDEwIDQ1OWMtNjctNy0xNjAtMjktMTk5LTQ4LTI3LTE0LTM0LTM2LTIwLTYzIDIxLTM4IDk3LTEzNiAxNTAtMTkzIDI1LTI3IDU4LTcxIDczLTk3IDI1LTQzIDMxLTQ3IDU0LTQyIDQwIDEwIDQyIDEyIDQyIDUyIDAgMjAgNiA1NyAxNCA4MiAyNCA3MyA1NCAxOTIgNjIgMjM2IDUgMzUgMyA0NS0xNSA2My0yMyAyMy0zNiAyNC0xNjEgMTB6Ii8%2BCiA8L2c%2BCiA8ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgtMTQuNzQgLTQuNjgyNikiIGZpbGw9IiM3ZWNiMjUiPgogIDxwYXRoIGQ9Im01NTggNjc0Yy0yLTItNTEtOS0xMDktMTQtMTAyLTExLTIwNC0zNy0yNjQtNjktMTYtOC0zMi0xNC0zNC0xMi00IDMtMzEtNDgtMzEtNjEgMC01IDIxLTMxIDQ2LTU4IDUxLTU0IDcxLTYwIDEzMC0zNSAxOSA4IDgzIDE5IDE0MiAyNSA1OCA2IDEwNyAxMiAxMDcgMTNzMTUgMjYgMzMgNTZjMjcgNDMgMzIgNjMgMzAgOTktMiAzNS04IDQ3LTI1IDUzLTExIDQtMjMgNi0yNSAzeiIvPgogPC9nPgogPGcgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoLTE0Ljc0IC00LjY4MjYpIiBmaWxsPSIjZWNlZGVmIj4KICA8cGF0aCBkPSJtMjYwIDg5MGMtMzQtOC03MC00MS03MC02NSAwLTYtOS0yMC0yMC0zMHMtMjAtMjItMjAtMjctMTMtMjEtMzAtMzVjLTM1LTI5LTQxLTgzLTEzLTEyMiAxNS0yMiAxNS0yNi0xLTU2LTE4LTMzLTE4LTMzIDI3LTkxIDI4LTM2IDQyLTYzIDM2LTY4LTIzLTI1IDktNzggMTIwLTE5NyAzNi0zOCA3Mi04MSA4Mi05NiAxMC0xNCAyNS0zMCAzMy0zNSAzNi0yMCA3IDMyLTUzIDk3LTQ4IDUxLTEyNiAxNTAtMTQ5IDE4OS0xMCAxOC05IDI0IDEwIDQwIDIzIDE5IDIzIDE5LTI5IDcxLTUzIDUyLTUzIDUyLTM4IDgyIDE0IDI4IDE0IDMzLTEwIDc2LTMyIDU3LTIzIDgxIDQ2IDEyMCAzNCAxOSA0OSAzMyA0NSA0Mi0xNCAzNyAzNiA3NSA5OCA3NSAyNSAwIDQwLTcgNTQtMjUgMTgtMjMgMjctMjUgOTUtMjUgOTQgMCAxMDItOCA5My04OS02LTUzLTUtNTkgMTQtNjQgMzItOCAyNi02NC0xNS0xMzItMzUtNTgtMzUtNTgtOS04MiAyMS0xOSAyNC0yOSAxOS01Ni0xMC00Ny00NC0xNzUtNjEtMjI3LTgtMjUtMTQtNjItMTQtODMgMC0yNy01LTM5LTE3LTQzLTEwLTMtMjUtOC0zMy0xMC0xMi00LTEyLTYtMS0xNCAyNy0xNiA1NiA1IDY5IDUxIDM1IDExNyA0MyAxNDggNDYgMTcwIDIgMTMgMTEgNTEgMjEgODQgMjEgNzEgMjEgMTIxIDAgMTQ1LTE0IDE1LTEzIDE5IDUgNDMgMTEgMTQgMjAgMzAgMjAgMzVzNyAxNSAxNSAyMmMyMSAxNyAxNiA3NS0xMCAxMDItMTggMTktMjAgMzItMTcgNzkgNCA1MCAyIDU4LTE5IDcyLTEyIDktNTAgMTktODMgMjMtNDUgNS02NSAxMy04MyAzMi0yNiAyOC05MiAzOC0xNTMgMjJ6Ii8%2BCiA8L2c%2BCiA8ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgtMTQuNzQgLTQuNjgyNikiIGZpbGw9IiM3ZTY3NGQiPgogIDxwYXRoIGQ9Im0yNDggODU0Yy0zMC0xNi00Ny01OS0zMC03NiA4LTggMjMtNyA1NCAyIDI0IDcgNjEgMTQgODMgMTcgNTQgNyA1OSAxNSAzNSA0Ni0xOCAyMy0yOSAyNy02OCAyNy0yNi0xLTU5LTctNzQtMTZ6Ii8%2BCiA8L2c%2BCjwvc3ZnPgo%3D&label=PineStore)](https://pinestore.cc/projects/25/basic-farm)
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

### Basic Floor Builder ([basic-floor-builder.lua](basic-floor-builder.lua))
A simple program which builds a square floor for a room. 

Place the turtle in any corner of the room so its right and front sides are
facing the wall, fill it with items, then run the program. The turtle will then
spiral towards the center of the room while building the floor.

Once the turtle reaches the center, it will move up a block and place a block
below it. To make it go down instead, provide any argument to the program.

#### Install

```
wget https://raw.githubusercontent.com/Fatboychummy-CC/etc-programs/main/basic-floor-builder.lua
```

### Safe Bridge ([safe-bridge.lua](safe-bridge.lua))
A quick bridge program to get you across a chasm. It will place blocks in a 'v'
shape in a straight line until it detects a block beneath or in front of it, or
until a specified max distance.

#### Install
```
wget https://raw.githubusercontent.com/Fatboychummy-CC/etc-programs/main/safe-bridge.lua
```

### Cubic Miner Controller ([cubic-miner-controller.lua](cubic-miner-controller.lua))
This program is designed for a very specific Create contraption, so it is
unlikely that anyone else will ever need to use it, but uploading to this repo
anyways.

This program will control a Create contraption that is designed to mine an
"ore cube", which is just a giant cube of random (or specific) ores. The idea
is mainly that these cubes will be generated within an RFTools dimension, and
then this program can be used to get tons of ores. It is not very energy
efficient to do this, but if you have a mining dimension like this, I assume you
have power figured out.

<details> <summary>Screenshots and Setup</summary>

TODO: add screenshots and setup instructions

</details>

#### Install
```
wget https://raw.githubusercontent.com/Fatboychummy-CC/etc-programs/main/cubic-miner-controller.lua
```

### Wheat Dough Crafter ([wheat-dough-crafter.lua](wheat-dough-crafter.lua))
This program is designed to craft Wheat Dough from the Farmer's Delight mod.
It requires a bucket and an infinite water source below itself, as well as
an input inventory (filled with wheat), and an output inventory (or 
inventor*ies* -- if multiple are given, the turtle will fill them
round-robin).

It will continuously craft wheat dough for its lifetime, making this tedious
recipe a little bit easier to deal with.

<details> <summary>Screenshots and Setup</summary>

TODO: add screenshots and setup instructions

</details>

#### Install
```
wget https://raw.githubusercontent.com/Fatboychummy-CC/etc-programs/main/wheat-dough-crafter.lua
```
