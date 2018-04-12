# Fast Flower Delivery Rulesets
Below are brief descriptions of the various rulesets and the events that they respond to/generate.

## `gossip` 
Implementation of a simple gossip protocol, similar to what was done in Lab 9,  where 
Delivery request messages are passed among Peers and Stores, allowing all nodes in the system to 
reach consensus on the status of delivery requests.

#### Events
| Domain | Type | Attrs | Description |
|--------|------|-------|-------------|
| `gossip` | `heartbeat` | | Generate a new message to gossip about with peers |
| `gossip` | `create_message` | | After every hearbeat, we attempt to create a new gossip message about the requests we keep track of |
| `gossip` | `message_created` | `message` | The successfuly created message from the `create_message` event is stored in the gossip messages |
| `gossip` | `rumor` |  | Rumor message about delivery request status |
| `gossip` | `seen` | | Gossip current node state to peers to help reach consensus |
| `gossip` | `update_interval` | `interval` | Sets the internal interval for scheduling heartbeats to the new value |
| `gossip` | `introduce_peer` | `peer_id`, `eci` | creates a new `node` subscription between two peers in the network |


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
| `delivery` | `accept_request` | "id", "driver" | Assigns driver to request, notifies shop by SMS. Returns error if taken or non-existant |
| `delivery` | `finish_delivery` | "id" | Marks delivery request as completed. Notifies the shop by SMS |


## `driver`

#### Events
| Domain | Type | Attrs | Description |
|--------|------|-------|-------------|
| `driver` | `receive_request` | `request` | Fired when a store sends a new request to the driver |
| `driver` | `accept_request` | `store`, `delivery_id` | Sends an event to the store accepting the request |
| `driver` | `complete_request` | `store`, `delivery_id` | Notifies the store the request has been completed |
| `driver` | `update_eci` | `eci` | Updates the publically available ECI given by the driver |
| `driver` | `update_location` | `lat`, `lng` | Updates the location values used by `google_maps` to determine distance |

#### Queries
| Name | args | Description | Example |
|--------|------|-------------|------|
| `requests` | | Returns the store's current list of delivery objects | |
| `get_request` | `store_id`, `delivery_id` | Returns a specific delivery object | |
| `eci` | | Returns the publically available ECI used to communicate with stores | |


## `request_store`

#### Events
| Domain | Type | Attrs | Description |
|--------|------|-------|-------------|
| `delivery` | `new_request` | `request` | Stores a new delivery request if the driver is within the allowed distance from the store |
| `delivery` | `update_request` | `request` | Updates an existing request entry in storage |
| `delivery` | `request_invalid` | `store_id`, `delivery_id` | When a request has been cancelled or already taken, remove it from storage |
| `delivery` | `remove_request` | `store_id`, `delivery_id` | Removes a delivery request from storage |
| `delivery` | `dequeue_unsent_request` | | Removes the head element of the unsent messages array used by the gossip protocol |

#### Queries
| Name | args | Description | Example |
|--------|------|-------------|------|
| `requests` | | Returns the store's current list of delivery objects | |
| `next_unsent_request` | | Gets the head of the unsent messages array used by the gossip protocol | |



