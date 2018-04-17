ruleset google_maps {
	meta {
		shares __testing, getDistanceFrom
		provides getDistanceFrom
	}
	global {
		apiKey = "AIzaSyDD0QzaH-Sxq6GsdsI7L5Qk-RfohHvV-o0"

		getDistanceFrom = function(lat, lng) {
			Lat = lat.as("Number");
			Lng = lng.as("Number");
			url = <<https://maps.googleapis.com/maps/api/distancematrix/json?origins=#{Lat},#{Lng}&destinations=#{ent:lat},#{ent:lng}&key=AIzaSyDD0QzaH-Sxq6GsdsI7L5Qk-RfohHvV-o0>>;

			response = http:get(url, parseJSON = true);
            response{["content","rows"]}[0]{"elements"}[0]{"distance"}
		}

		__testing = {
			"queries": [{
				"name": "getDistanceFrom",
				"args": [ "lat", "lng" ]
			}],
			"events": [{
				"domain": "update",
				"type": "position",
				"attrs": [ "lat", "lng" ]
			}]
		}
	}

	rule start_up {
		select when wrangler ruleset_added where rids >< meta:rid
		fired {
			ent:lat := 40.252524;
			ent:lng := -111.667955;
		}
	}

	rule update_position {
		select when update position
		pre {
			myLat = event:attr("lat")
			myLng = event:attr("lng")
		}
		fired {
			ent:lat := myLat;
			ent:lng := myLng;
		}
	}
	
}