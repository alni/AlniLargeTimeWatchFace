//using Toybox.Background;
//using Toybox.Communications;
using Toybox.System;

//(:background)
class DarkSkyServiceDelegate { // extends System.ServiceDelegate {
    // When a scheduled background event triggers, make a request to
    // a service and handle the response with a callback function
    // within this delegate.
    function onTemporalEvent() {
    	var url = "https://api.darksky.net/forecast/a193138781505820b2e59f74ea3d358a/37.8267,-122.4233";
    	var params = {
    		"exclude" => "minutely,hourly,daily,alerts,flags"
    	};
        /*Communications.makeWebRequest(
            url,
            params,
            {},
            method(:responseCallback)
        );*/
    }

    function responseCallback(responseCode, data) {
        // Do stuff with the response data here and send the data
        // payload back to the app that originated the background
        // process.
        //Background.exit(data["currently"]);
    }
}
