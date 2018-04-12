/**
 *  ent:requests = {
 *      "store id": {
 *          "request id": {
 *              ... // request object from store
 *          }
 *      }
 *  }
 *
 *  ent:unsent_requests = []
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
        requests = function(){
            ent:requests
        }

        next_unsent_request = function(){
            ent:unsent_requests.head()
        }
    }

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

    rule install {
        select when wrangler ruleset_added where rids >< meta:rid
        if ent:requests.isnull() || ent:unsent_requests.isnull() then noop()
        fired {
            ent:requests := {};
            ent:unsent_requests := []
        }
    }
}