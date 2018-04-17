/**
 * Driver
 * BYU CS 462 - Distributed Systems Design
 *
 * This rulesets holds on to profile information about a driver. It also contains rules that select
 * on events that require a driver's attention. The entity variables for the ruleset are described
 * below:
 *
 * ent:eci = "aheugiadsfhaejd" // eci identifying this driver
 *
 * 
 */
ruleset driver {
    meta {
        name"Driver Profile"
        author "Blaine Backman, Braden Hitchcock, Jon Meng"
        description <<
            Contains profile information and event handlers for driver picos in the fast flower
            delivery problem
        >>
        logging on
        use module google_maps alias maps
        use module request_store alias requests
        shares __testing, requests, get_request, location, eci
    }

    global {
        // Testing
        __testing = {
            "queries": [
                {"name": "requests",
                 "args": [ ]
                },
                { "name": "get_request",
                  "args": [ "store", "id"]
                }
            ],
            "events": [
                {"domain": "driver",
                 "type": "accept_request",
                 "attrs": [ "store", "delivery_id" ]
                },
                {"domain": "driver",
                 "type": "complete_request",
                 "attrs": [ "delivery_id" ]
                },
                {"domain": "driver",
                 "type": "update_location",
                 "attrs": [ "lat", "lng" ]
                },
                {"domain": "driver",
                 "type": "update_eci",
                 "attrs": [ "eci" ]
                }
            ]
        }

        // Function to view all the requests
        requests = function(){
            requests:requests()
        }

        // Function to get a specific request by the store and request ids
        get_request = function(store, id){
            requests:requests(){[store, id]}
        }

        // Get the available eci of the driver (identifier)
        eci = function(){
            ent:eci.defaultsTo(meta:eci)
        }
    }

    /**
     * When a store generates a new request, it will send a "driver/receive_request" event to all
     * of the drivers attached to it via subscriptions. This rule selects on that event and
     * stores the new request.
     */
    rule receive_request {
        select when driver receive_request
        pre {
            request = event:attr("request")
        }
        if not request.isnull() then noop()
        fired {
            raise delivery event "new_request" attributes { "request": request }
        }
    }

    /**
     * If a driver decides to accept a request, this event will be raised, which will send the
     * response back to the store who issued the request.
     */
    rule accept_request {
        select when driver accept_request
        pre{
            // get the eci of the store whose request we are accepting
            // we also need the id of the request
            request = get_request(event:attr("store"), event:attr("delivery_id")).klog("request")
            store_eci = request{"store_eci"}.klog("store eci")
            request_id = request{"id"}.klog("request id")
            valid = not store_eci.isnull() && not request_id.isnull()
        }
        if valid.klog("valid") then
            event:send({"eci": store_eci, "domain": "driver", "type": "accept_request", "attrs": {
                "delivery_id": request_id,
                "driver": eci()
            }})
        fired {
            // update the request in the store
            raise delivery event "update_request" attributes {"request": request }
        }
    }

    /**
     * When a driver completes a request they have been assigned, they need to notify the store
     * so the store can notify its owners with an SMS message.
     */
    rule complete_request {
        select when driver complete_request
        pre {
            // get the eci of the store whose request we are accepting
            // we also need the id of the request
            request = get_request(event:attr("store"), event:attr("delivery_id"))
            store_eci = request{"store_eci"}
            request_id = request{"id"}
            valid = not store_eci.isnull() && not request_id.isnull()
        }
        if valid then
            event:send({"eci": store_eci, "domain": "delivery", "type": "finish_delivery", "attrs": {
                "delivery_id": request_id
            }})
        fired {
            // remove the request from the internal store 
            raise delivery event "remove_request" attributes {
                "store_id": request{"store_id"},
                "delivery_id": request_id
            }
        }
    }

    /**
     * This allows us to update the available ECI of the driver (not that we need to normally, but
     * it gives us access for debugging)
     */
    rule update_eci {
        select when driver update_eci
        pre {
            valid = not event:attr("eci").isnull()
        }
        if valid then noop()
        fired {
            ent:eci := event:attr("eci")
        }
    }

    /** 
     * This allows us to update the location of the driver, which is stored inside of the 
     * "google_maps" ruleset. Essentially this just reroutes the event to the "google_maps"
     * ruleset.
     */
    rule update_location {
        select when driver update_location
        pre {
            lat = event:attr("lat")
            lng = event:attr("lng")
            valid = not lat.isnull() && not lng.isnull()
        }
        if valid then noop()
        fired {
            raise update event "position" attributes event:attrs
        }
    }

    /**
     * This initializes the internal entity variables for the ruleset when it is first installed
     * inside of the engine.
     */
    rule install {
        select when wrangler ruleset_added where rids >< meta:rid
        if ent:location.isnull() || ent:eci.isnull() then noop()
        fired {
            ent:eci := meta:eci
        }
    }

}