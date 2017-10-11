using Toybox.Application as App;
using Toybox.System as Sys;
using Toybox.WatchUi as Ui;

class AlniLargeTimeWatchFaceApp extends App.AppBase {
	static const WEATHER_KEY = "WeatherData";

	static var settingsChanged = false;
	static var canDoBG = false;
	//static var weatherData = null;

	static function resetSettingsChanged() {
		self.settingsChanged = false;
	}

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
    	//register for temporal events if they are supported
    	/*if(Toybox.System has :ServiceDelegate) {
    		canDoBG=true;
    		weatherData = App.getApp().getProperty(WEATHER_KEY);
    		//Background.registerForTemporalEvent(new Time.Duration(5 * 60));
    	} else {
    		Sys.println("****background not available on this device****");
    	}*/
        return [ new AlniLargeTimeWatchFaceView() ];
    }

    // New app settings have been received so trigger a UI update
    function onSettingsChanged() {
    	self.settingsChanged = true;
        Ui.requestUpdate();
    }

    function onBackgroundData(data) {
	    if(data instanceof Number) {
	        //indicates there was an error, and “data” is the error code
	    } else {
	        //got good “data”
	        weatherData = data;
	        App.getApp().setProperty(WEATHER_KEY, weatherData);
	        Ui.requestUpdate();
	    }
	}

}