/**
 * Request Store
 * BYU CS 462 - Distributed Systems Deisgn
 *
 * Stores requests that are available to this driver. "Available" requests are determined using
 * this driver's location and the allowed_distance away from the store issuing the delivery request.
 *
 * The internal entity variables are summarized below: 
 *
 *  ent:requests = {
 *      "store id": {
 *          "request id": {
 *              ... // request object from store
 *          }
 *      }
 *  }
 *
 *  ent:unsent_requests = []
 *
 * The ent:unsent_requests variable is used by the gossip protocol to determine which messages
 * this node int he gossip network still needs to send.
 */
ruleset request_store {
    meta {
        name "Request Storage"
        author "Blaine Backman, Braden Hitchcock, Jon Meng"
        logging on
        use module google_maps alias maps
        provides requests, next_unsent_request
        shares __testing, requests, next_unsent_request
    }

    global {
        // Testing
        __testing = {
            "queries": [
                {"name": "requests",
                 "args": [ ]
                },
                { "name": "next_unsent_request",
                  "args": [ ]
                }
            ],
            "events": [
                
            ]
        }

        // Get the requests entity variable to view all requests available to this user
        requests = function(){
            ent:requests
        }

        // The unsent requests entity variable is used by the gossip protocol to get the next 
        // message to send. It essentially functions like a queue. This function gets the next
        // available message for the protocol to send.
        next_unsent_request = function(){
            ent:unsent_requests.head()
        }
    }

    /**
     * Creates a new request entry in the internal storage IF the driver is within the allowed
     * distance.
     */
    rule create_request {
        select when delivery new_request
        pre {
            // make sure we don't already have that request
            request = event:attr("request")
            has_request = not ent:requests{[request{"store_id"}, request{"id"}]}
            distance = maps:getDistanceFrom(request{"store_lat"}, request{"store_long"})
            valid = distance{"value"} <= request{"allowed_distance"}.as("Number")
        }
        if not has_request && valid then noop()
        fired {
            ent:requests{request{"store_id"}} := {};
            ent:requests{request{"store_id"}} := ent:requests{request{"store_id"}}.put(request{"id"}, request);
            ent:unsent_requests := ent:unsent_requests.append([request])
        } 
    }

    /**
     * Allows a request already present in storage to be updated. Not currently used by our system,
     * but it is available.
     */
    rule update_request {
        select when delivery update_request
        pre {
            // make sure we have the request 
            request = event:attr("request")
            has_request = not ent:requests{[request{"store_id"}, request{"id"}]}
        }
        if has_request then noop()
        fired {
            ent:requests{[request{"store_id"}, request{"id"}]} := request
        }
    }

    /**
     * If a driver attempts to accept a request from a store that is invalid (i.e. it has been
     * cancelled or another driver already got the job) then the store will respond with an
     * "delivery/request_invalid" event. We should remove the event from our storage in response
     * to this so we don't make the same mistake.
     */
    rule remove_invalid_request {
        select when delivery request_invalid
        pre {
            // get the id of the request to remove 
            store_id = event:attr("store_id")
            delivery_id = event:attr("delivery_id")
        }
        if not store_id.isnull() && not delivery_id.isull() then noop()
        fired {
            raise delivery event "remove_request" attributes event:attrs
        }
    }

    /**
     * Removes a request with the associated store pico id and request id from storage.
     */
    rule remove_request {
        select when delivery remove_request
        pre {
            // get the id of the request to remove 
            store_id = event:attr("store_id")
            delivery_id = event:attr("delivery_id")
        }
        if not store_id.isnull() && not delivery_id.isull() then noop()
        fired {
            clear ent:requests{[store_id, delivery_id]}
        }
    }

    /**
     * After the gossip protocol sends the next message, it needs to remove it from the
     * "queue" in this ruleset. This event gives the gossip protocol the ability to do that.
     */
    rule dequeue_unsent {
        select when delivery dequeue_unsent_request
        pre {
            request_to_dequeue = ent:unsent_requests.length() != 0
        }
        if request_to_dequeue then noop()
        fired {
            ent:unsent_requests := ent:unsent_requests.tail()
        }

    }

    /**
     * When the ruleset is first installed, we need to initialize the entity variables.
     */
    rule install {
        select when wrangler ruleset_added where rids >< meta:rid
        if ent:requests.isnull() || ent:unsent_requests.isnull() then noop()
        fired {
            ent:requests := {};
            ent:unsent_requests := []
        }
    }
}