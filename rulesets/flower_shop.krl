ruleset flower_shop {
	meta {
	  use module io.picolabs.subscription alias Subscriptions
	  use module io.picolabs.wrangler alias Wrangler
	  use module io.picolabs.lesson_keys
    use module io.picolabs.twilio_v2 alias twilio
        with account_sid = keys:twilio{"account_sid"}
             auth_token =  keys:twilio{"auth_token"}
		shares __testing, getAllDeliveries
		provides getAllDeliveries
	}

	global {
        // Store's current latitude and longitude
        store_lat = 40.252524;
        store_lng = -111.667955;

        // Allowed distance in meters from flower shop
        allowed_distance = 10000;   // 6.2 miles
        
        // Flower shop number (static cause it's not important)
        contact_number = "+15098201634"
        
        getAllDeliveries = function() {
          ent:deliveries;
        }
        

		__testing = {
			"queries": [{
			  "name": "getAllDeliveries"
			}],
			"events": [{
				"domain": "delivery",
				"type": "new_request",
				"attrs": [ "id", "reward", "destination" ]
			},
			{
			  "domain": "delivery",
			  "type": "cancel_request",
			  "attrs": [ "delivery_id" ]
			},
			{
			  "domain": "delivery",
			  "type": "accept_request",
			  "attrs": [ "delivery_id", "driver" ]
			},
			{
			  "domain": "delivery",
			  "type": "finish_delivery",
			  "attrs": [ "delivery_id" ]
			}]
		}
	}

  // This when a store makes a new delivery request
	rule new_request {
        select when delivery new_request
        pre {
            // ID is really only used by the store to keep track of their deliveries
            id = event:attr("id")
            delivery = { "id": event:attr("id"), "store_id": meta:picoId,
                         "store_eci": meta:eci,
                         "store_lat": store_lat, "store_lng": store_lng,
                         "allowed_distance": allowed_distance,
                         "reward": event:attr("reward"),
                         "destination": event:attr("destination"),
                         "accepted": false, "driver": null,
                         "completed": false }
            
            exists = ent:deliveries >< id
        }
        if not exists then
          send_directive("shop", {"delivery": delivery})
        fired {
          ent:deliveries := ent:deliveries.defaultsTo({});
          ent:deliveries{[id]} := delivery;
            
          raise delivery event "request_created"
              attributes {"delivery": delivery}
        }
	}
	
	// Can't test yet, because we don't have driver picos
	// Notify the known drivers that a new delivery is ready
	// Assumes that all subscriptions are just with drivers and they are already connected
	rule request_created {
	      select when delivery request_created
	      foreach Subscriptions:established("Tx_role", "driver") setting (subscription)
          pre {
            subs = subscription
            subs_attrs = subs{"attributes"}
            delivery = event:attr("delivery")
          }
          if true then
            event:send({
              "eci": subs_attrs{"outbound_eci"},
              "eid": "delivery",
              "domain": "driver",
              "type": "receive_request",
              "attrs": {"request": delivery}
            })
	}
	
	// Cancel a delivery request, right now I just delete it
	rule cancel_request {
	      select when delivery cancel_request
	      pre {
	        delivery_id = event:attr("delivery_id")
	        exists = ent:deliveries >< delivery_id
	      }
	      if exists then 
	        send_directive("shop", {"Deleting request with ID": delivery_id})
	      fired {
	        clear ent:deliveries{[delivery_id]}
	      }
	}
	
    // Send back the event to the Pico using the event eci
    // Raise the event delivery request_invalid on whoever sent invalid request
	rule accept_request {
	      select when delivery accept_request
	      pre {
	        delivery_id = event:attr("delivery_id")
	        delivery = ent:deliveries{[delivery_id]}
	        driver = event:attr("driver")
	        exists = ent:deliveries >< delivery_id
	      }
	      if not exists then
	       // Message Cancelled
           event:send({
            "eci": driver,
            "eid": "delivery",
            "domain": "delivery",
            "type": "request_invalid",
            "attrs": {"store_id": meta:picoId, "delivery_id": delivery_id}
           })
        notfired {
          raise delivery event "assign_request"
              attributes {"delivery_id": delivery_id, "driver": driver}
        } 
	}
	
	rule assign_delivery {
	      select when delivery assign_request
	      pre {
	        delivery_id = event:attr("delivery_id")
	        delivery = ent:deliveries{[delivery_id]}
	        taken = delivery{"accepted"}
	        driver = event:attr("driver")
	      }
	      if taken then
	       event:send({
            "eci": driver,
            "eid": "delivery",
            "domain": "delivery",
            "type": "request_invalid",
            "attrs": {"store_id": meta:picoId, "delivery_id": delivery_id}
          })
	        
	      notfired {
	        ent:deliveries{[delivery_id, "driver"]} := driver;
	        ent:deliveries{[delivery_id, "accepted"]} := true;
	        // send SMS to the store
	        raise shop event "message"
              attributes {"message": "Driver " + driver + " accepted delivery " + delivery_id}
	      } 
	}
	
	rule finish_delivery {
	     select when delivery finish_delivery
	     pre {
         driver = event:attr("driver")
	       delivery_id = event:attr("delivery_id")
	       exists = ent:deliveries >< delivery_id
	     }
	     if not exists then
	      // Delivery does not exist
          event:send({
            "eci": driver,
            "eid": "delivery",
            "domain": "delivery",
            "type": "request_invalid",
            "attrs": {"store_id": meta:picoId, "delivery_id": delivery_id}
          })
	     notfired {
	       ent:deliveries{[delivery_id, "completed"]} := true;
	       // send SMS to the store
	       raise shop event "message"
              attributes {"message": "Delivery " + delivery_id + " has been delivered!"}
	     }
	}
	
	rule send_sms {
	    select when shop message
	    pre {
	      message = event:attr("message")
	    }
	    twilio:send_sms(contact_number, message)
	}
}
