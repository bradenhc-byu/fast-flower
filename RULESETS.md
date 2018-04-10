# Fast Flower Delivery Rulesets
Below are brief descriptions of the various rulesets and the events that they respond to/generate.

## `gossip` 
Implementation of a simple gossip protocol, similar to what was done in Lab 9,  where 
`DriverRequest` messages are passed among Peers and Stores, allowing all nodes in the system to 
reach consensus on the status of `DriverRequest`s.

#### Events Generated
| Domain | Type | Description |
|--------|------|-------------|
| `gossip` | `heartbeat` | Generate a new message to gossip about with peers |
| `gossip` | `rumor` | Rumor message about `DriverRequest` status |
| `gossip` | `seen` | Gossip current node state to peers to help reach consensus |

#### Events Responded To
| Domain | Type | Description |
|--------|------|-------------|
| `gossip` | `heartbeat` | Generate a new message to gossip about with peers |
| `gossip` | `rumor` | Store rumor message internally |
| `gossip` | `seen` | Find messages the sending peer may not have and respond with them |