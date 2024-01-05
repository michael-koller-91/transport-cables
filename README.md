# Transport Cables (A [Factorio](https://www.factorio.com/) Mod)

Revolutionize your main bus.
With this mod, your main bus needs only one lane per item type.
Further, the items are always distributed evenly among all consumers
which makes balancers unnecessary.

## Try it out

Navigate to the latest [releases](https://github.com/michael-koller-91/transport-cables/releases)
and download the zip folder `transport-cables_v*.zip`.
Copy this zip folder to the mods folder of your Factorio installation.
The mods folder is typically located here:
* for Windows: `C:\Users\user name\AppData\Roaming\Factorio\mods\`
* for Linux: `~/.factorio/mods`
* for Mac OS X: `~/Library/Application Support/factorio/mods`

After starting Factorio, you will find the Transport Cables mod in the mods menu.

## How it works

## TODOs

* write the how it works section
* draw lamp circuit wires only in debug mode
* in debug mode, it should be possible to switch lamps on/off via a command; otherwise, the lamps should always be off
* when mod entities are destroyed, should only the corresponding circuit network id tables be updated (instead of always calling update_network_ids())?
* a cable connected to a provider or node should be able to be a curved cable
* implement receiver either via buffer chest or via assembling machine
* fix desync in multiplayer
* can the collision box of the node be made smaller (such that it is similar to cables)?
* node should connect to neighboring nodes
* underground cables should be placeable onto cables
* curved belts should only connect to neighbors facing in the same direction
* rewrite the item distribution algorithm; for example, 31 receivers with a rate of 30 items / s is a problem
* upgrade planner should work on cables, currently suggests belts

## Acknowledgement

I would like to thank my friend Patze (aka Ma§endefekt) for all the discussions around the mod
and for being the alpha and beta tester!
