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
* replace the helper lamps' circuit wire connector sprites with empty sprites
* use custom circuit wire sprites for the helper lamps
* when mod entities are destroyed, should only the corresponding circuit network id tables be updated (instead of always calling update_network_ids())?
* is the requester rotatable even if the future container tile is occupied?
* a receiver should not be placeable if its container tile is occupied
* a cable connected to a provider or node should be able to be a curved cable

## Acknowledgement

I would like to thank my friend Patze (aka Ma§endefekt) for all the discussions around the mod
and for being the alpha and beta tester!
