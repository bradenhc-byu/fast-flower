ruleset io.picolabs.twilio_v2 {
  meta {
    configure using account_sid = ""
                    auth_token = ""
    provides 
        send_sms, messages
  }
 
  global {
    send_sms = defaction(to, message) {
       base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/>>
       http:post(base_url + "Messages.json", form = {
                "From":"+12674940026",
                "To":to,
                "Body":message
            })
    }

    messages = function(to, from, pagesize) {
    	base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/Messages>>;
	    qs_map = {};

	    qs_map = to => qs_map.put("To", to) | qs_map;
        qs_map = from => qs_map.put("From", from) | qs_map;
	    qs_map = pagesize => qs_map.put("PageSize", pagesize) | qs_map;

        http:get(base_url, qs_map);
    };
  }
}
