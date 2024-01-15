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
* update locale: what connects to what
* is it necessary to have n_tiers many entries in variables like proxies? can we avoid passing tier to almost every function? store the tier like net_id and use a get_tier function?
* make the names lookup better; probably something like `names.nodes[name_string] = true` and then `if names.nodes[entiy.name] then`; maybe even `names.nodes[name_string] = tier`?
* there should be two `get_rx_filter`: one for containers and one of combinators
* setting a filter should trigger an item transport

## Acknowledgement

I would like to thank my friend Patze (aka Ma§endefekt) for all the discussions around the mod
and for being the alpha and beta tester!

## What needs to be tested before a release

The expected result is written in italics.

#### copying and pasting
* build a receiver; set a filter
    * _alt-mode shows the filter_
    * ctrl+c to copy the receiver; paste it; _the pasted receiver has the filter set_
    * ctrl+shift+c to make a blueprint of the receiver; _there is only one entity in the blueprint_
    * build the blueprint; _the built receiver has the filter set_
    * ghost-build the blueprint; use pipette on the ghost and build the receiver; _it has the filter set_
    * change the filter of one of the receivers; copy-paste the new filter with shift+rightclick and shift+leftclick; _new filter is pasted_

#### setting filters
* build a rx-tx-pair; set a filter; build another receiver and also connect it to the transmitter; _the new receiver's filter is set_
    * remove the filter of one of the two receivers; _the other receiver's filter is also removed_
    * set a filter for one of the two receivers; _the other receiver's filter is also set_

#### upgrading

#### triggering item transports

#### connecting entities
* build a cable (cable 1) facing north
    * build a cable (cable 2) directly north of cable 1 also facing north; _it connects to cable 1_
    * build a node (node 1) directly north of cable 2; _it connects to cable 2_
    * build a node (node 2) directly south of cable 1; _it connects to cable 1_
    * build a node (node 3) directly west of cable 1; _it does not connect to cable 1_
    * build a node (node 4) directly south of node 2; _it connects to node 2_
* build a cable (cable 1) facing north
    * build an underground cable (underground 1) directly north of cable 1 also facing north; _it connects to cable 1_
    * build the other end of underground 1 (underground 2) at maximum distance; _it connects to underground 1_
    * build a cable (cable 2) directly north of underground 1; _it does not connect to underground 1_
    * build a cable (cable 3) directly south of underground 2; _it does not connect to underground 2_
    * remove cable 2; remove cable 3
    * build a node (node 1) directly north of underground 1; _it does not connect to underground 1_
    * build a node (node 2) directly south of underground 2; _it does not connect to underground 2_
    * remove node 1; remove node 2
    * repeat the same with receivers and transmitters; _they do not connect to underground 1 or underground 2_
