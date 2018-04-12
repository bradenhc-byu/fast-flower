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


## `google_maps` 
Used to get the distance between incoming position and the rulesets current position.

#### Events 
| Domain | Type | Attrs | Description |
|--------|------|-------|-------------|
| `update` | `position` | "lat", "lng" | Change the lat,lng position for the entity |

#### Queries
| Name | args | Description | Example |
|--------|------|-------------|------|
| `getDistanceFrom` | "lat", "lng" | Returns an object with information about how far the passed in position is from the entity's current position | { "text": "34.1 km", "value": 34100 }

## `flower_shop` 
Used to get manage the lifecycle of a delivery request.

#### Queries
| Name | args | Description | Example |
|--------|------|-------------|------|
| `getAllDelivers` | "None" | Returns the store's current list of delivery objects

#### Events 
| Domain | Type | Attrs | Description |
|--------|------|-------|-------------|
| `delivery` | `new_request` | "id", "reward", "destination" | Creates a new delivery request |
| `delivery` | `cancel_request` | "id" | Cancels delivery request, removes from list of requests |
| `delivery` | `accept_request` | "id", "driver" | Assigns driver to request, notifies shop by SMS. Error is taken or non-existant |
| `delivery` | `finish_delivery` | "id" | Marks delivery request as completed. Notifies the shop by SMS |


