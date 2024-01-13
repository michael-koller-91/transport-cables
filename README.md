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
* when mod entities are destroyed, should only the corresponding circuit network id tables be updated (instead of always calling update_network_ids())?
* can cables connected to a provider or node be curved cables?
* if a pair of underground cables is placed on cables, can the cables between the undergrounds be deleted?
* save item transport is active in global?
* allow container bar and store its status in combinator slot
* node should connect to (almost) everything
* what happens when a node is placed next to a (curved) cable?
* player vs player-creation
* update locale: what connects to what
* is it necessary to have n_tiers many entries in variables like proxies? can we avoid passing tier to almost every function? store the tier like net_id and use a get_tier function?
* make the names lookup better; probably something like `names.nodes[name_string] = true` and then `if names.nodes[entiy.name] then`; maybe even `names.nodes[name_string] = tier`?

## Acknowledgement

I would like to thank my friend Patze (aka Ma§endefekt) for all the discussions around the mod
and for being the alpha and beta tester!
