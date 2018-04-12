/**
 * Driver Profile
 * BYU CS 462 - Distributed Systems Design
 *
 * This rulesets holds on to profile information about a driver. The entity variables are described
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
                {"domain": "delivery",
                 "type": "accept_request",
                 "attrs": [ "store", "delivery_id" ]
                },
                {"domain": "delivery",
                 "type": "complete",
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

        // Get the location of the driver 
        location = function(){
            ent:location.defaultsTo({"lat": 0, "lng": 0})
        }

        eci = function(){
            ent:eci.defaultsTo(meta:eci)
        }
    }

    // event attributes = {"store": "store_pico_id", "delivery_id": "delivery_request_id"}
    rule accept_request {
        select when delivery accept_request
        pre{
            // get the eci of the store whose request we are accepting
            // we also need the id of the request
            request = get_request(event:attr("store", event:attr("delivery_id")))
            store_eci = request{"store_eci"}
            request_id = request{"id"}
            valid = not store_eci.isnull() && not request_id.isnull()
        }
        if valid then
            event:send({"eci": store_eci, "domain": "driver", "type": "accept_request", "attrs": {
                "delivery_id": request_id,
                "driver": eci()
            }})
        fired {
            // update the request in the store
            raise delivery event "update_request" attributes {"request": request }
        }
    }

    rule complete_request {
        select when delivery complete 
        pre {
            // get the eci of the store whose request we are accepting
            // we also need the id of the request
            request = get_request(event:attr("store", event:attr("delivery_id")))
            store_eci = request{"store_eci"}
            request_id = request{"id"}
            valid = not store_eci.isnull() && not request_id.isnull()
        }
        if valid then
            event:send({"eci": store_eci, "domain": "driver", "type": "finish_delivery", "attrs": {
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

    rule install {
        select when wrangler ruleset_added where rids >< meta:rid
        if ent:location.isnull() || ent:eci.isnull() then noop()
        fired {
            ent:eci := meta:eci
        }
    }

}