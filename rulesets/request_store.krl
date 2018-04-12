/**
 *  ent:requests = {
 *      "store id": {
 *          "request id": {
 *              ... // request object from store
 *          }
 *      }
 *  }
 */
ruleset request_store {

    global {
        requests = function(){
            ent:requests
        }
    }

    rule create_request {
        select when delivery new_request
        pre {
            // make sure we don't already have that request
            request = event:attr("request")
            has_request = not ent:requests{[request{"store_id"}, request{"id"}]}
        }
        if not has_request then noop()
        fired {
            ent:requests{request{"store_id"}} := {};
            ent:requests{request{"store_id"}} := ent:requests{request{"store_id"}}.put(request{"id"}, request);
            // now we need to start gossiping about it 
            raise gossip event "heartbeat" attributes {
                "request": request
            }
        } 
    }

    rule create_gossip_request {
        select when delivery new_gossip_request
        pre {
            // make sure we don't already have that request
            request = event:attr("request")
            has_request = not ent:requests{[request{"store_id"}, request{"id"}]}
        }
        if not has_request then noop()
        fired {
            ent:requests{request{"store_id"}} := {};
            ent:requests{request{"store_id"}} := ent:requests{request{"store_id"}}.put(request{"id"}, request);
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

    rule install {
        select when wrangler ruleset_added where rids >< meta:rid
        if ent:requests.isnull() then noop()
        fired {
            ent:requests := {}
        }
    }
}