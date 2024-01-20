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
* if a pair of underground cables is placed on cables, can the cables between the undergrounds be deleted?
* allow container bar and store its status in combinator slot
* what happens when a node is placed next to a (curved) cable?
* update locale: what connects to what
* is it necessary to have n_tiers many entries in variables like proxies? can we avoid passing tier to almost every function? store the tier like net_id and use a get_tier function?
* make the names lookup better; probably something like `names.nodes[name_string] = true` and then `if names.nodes[entiy.name] then`; maybe even `names.nodes[name_string] = tier`?
* there should be two `get_rx_filter`: one for containers and one of combinators
* can receivers be made pastable onto other receivers?
* rewrite all `if entity and ...` back to `if entity then`
* should cable_connection_update be an array to which updates are appended? multiple tiers for example or simultaneous updates?

## Acknowledgement

I would like to thank my friend Patze (aka Ma§endefekt) for all the discussions around the mod
and for being the alpha and beta tester!

## What needs to be tested before a release

The following subsections describe tests.
The expected result is written in italics.
A rx-tx-pair is a receiver connected to a transmitter and in addition the transmitter has an infinite source of iron plates
and the receiver has an infinite sink and no filter set yet.

#### connecting entities
Place entities next to one another and observe whether they are connected.

* a cable
    * build cables in various orientations and positions around the cable; _the cable only connects to the other cables when it makes sense_
    * build five cables facing north in positions 1, 4, 2, 5, 8 (imagine a num pad); rotate the cable in position 4; _it never connects to the cable in position 5 but stays connected to the cable in position 1_
    * build a zig-zag; _the cable connect to one another_
    * a node in front of it; _the cable is connected to it_
    * a node behind it; _the cable is connected to it_
    * a receiver in front of it; _the cable is connected to it_
    * a receiver behind it; _the cable is not connected to it_
    * a transmitter in front of it; _the cable is not connected to it_
    * a transmitter behind it; _the cable is connected to it_
    * an underground cable pair; _the cable only connects to an underground cable when it makes sense_
* a node
    * a cable facing away; _the node is connected to it_
    * a cable facing toward it; _the node is connected to it_
    * a node; _the node is connected to it_
    * a receiver; _the node is connected to it_
    * a transmitter; _the node is connected to it_
    * an underground cable (going underground) facing away; _the node is connected to it_
    * rotate the underground cable; _the receiver is not connected to it_
    * an underground cable (coming out) facing toward it; _the receiver is connected to it_
    * rotate the underground cable; _the receiver is not connected to it_
* a receiver
    * a cable facing away; _the receiver is not connected to it_
    * a cable facing toward it; _the receiver is connected to it_
    * a node; _the receiver is connected to it_
    * a receiver; _the receiver is not connected to it_
    * a transmitter; _the receiver is not connected to it_
    * an underground cable (going underground) facing away; _the receiver is not connected to it_
    * rotate the underground cable; _the receiver is not connected to it_
    * an underground cable (coming out) facing toward it; _the receiver is connected to it_
    * rotate the underground cable; _the receiver is not connected to it_
* a transmitter
    * a cable facing away; _the transmitter is connected to it_
    * a cable facing toward it; _the transmitter is not connected to it_
    * a node; _the transmitter is connected to it_
    * a receiver; _the transmitter is not connected to it_
    * an underground cable (going underground) facing away; _the transmitter is connected to it_
    * rotate the underground cable; _the receiver is not connected to it_
    * an underground cable (coming out) facing toward it; _the transmitter is not connected to it_
    * rotate the underground cable; _the transmitter is not connected to it_
* an underground cable pair
    * _the underground cables are connected_
    * build cables in various orientations and positions around the cable; _the underground cable only connects to the other cables when it makes sense_
    * build underground cables in various orientations and positions around the cable; _the underground cable only connects to the other underground cables when it makes sense_

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

#### triggering item transports
* build a rx-tx-pair; set the item transport rate to 4
    * _there is no item transport_
    * set the receiver filter to copper plates; _there is no item transport_
    * set the receiver filter to iron plates; _4 iron plates are transported per second_
    * set the receiver filter to no filter; _there is no item transport_
    * set the receiver filter to iron plates; _4 iron plates are transported per second_
    * connect another receiver; _each receiver receives 2 iron plates per second_
    * set one receiver filter to no filter; _there is no item transport_
    * set one receiver filter to copper plates; _there is no item transport_
    * set one receiver filter to iron plates; _each receiver receives 2 iron plates per second_
    * connect two more receivers; set the receiver filter to no filter; _there is no item transport
    * build another not connected receiver; set its filter to iron plates; _there is no item transport_
    * use shift+rightclick and shift+leftclick to copy the filter setting to one of the four connected receivers; _each receiver receives 1 iron plate per second_
    * connect another receiver; _4 of the 5 receivers receiver 1 iron plate per second, one receiver receives nothing; the role of each receiver changes every second such that all receivers on average receive the same amount of iron plates_

#### upgrading
* build a tier-1-receiver
    * upgrade it via the upgrade planner; _it becomes a tier-2-receiver_
    * upgrade it via the upgrade planner; _it becomes a tier-3-receiver_
* build a tier-1-receiver; set the receiver filter to iron plates
    * upgrade it via the upgrade planner; _it becomes a tier-2-receiver and the filter is still iron plates_
    * upgrade it via the upgrade planner; _it becomes a tier-3-receiver and the filter is still iron plates_
* build a tier-1-receiver; put some items in it
    * upgrade it via the upgrade planner; _it becomes a tier-2-receiver and the items are still in it_
    * upgrade it via the upgrade planner; _it becomes a tier-3-receiver and the items are still in it_
