using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Application as App;
using Toybox.Time as DateTime;
using Toybox.Time.Gregorian;
using Toybox.ActivityMonitor as ActMon;
using Toybox.Test;

class AlniLargeTimeWatchFaceView extends Ui.WatchFace {

	static hidden const WEEK_DAY_STRINGS_RES_ID = [
		Rez.Strings.WeekDay_1,
		Rez.Strings.WeekDay_2,
		Rez.Strings.WeekDay_3,
		Rez.Strings.WeekDay_4,
		Rez.Strings.WeekDay_5,
		Rez.Strings.WeekDay_6,
		Rez.Strings.WeekDay_7
	];

	static hidden const MONTH_STRINGS_RES_ID = [
		Rez.Strings.Month_1,
		Rez.Strings.Month_2,
		Rez.Strings.Month_3,
		Rez.Strings.Month_4,
		Rez.Strings.Month_5,
		Rez.Strings.Month_6,
		Rez.Strings.Month_7,
		Rez.Strings.Month_8,
		Rez.Strings.Month_9,
		Rez.Strings.Month_10,
		Rez.Strings.Month_11,
		Rez.Strings.Month_12
	];

	static hidden const SHOW_ALL = 0;

	static hidden const STATUS_HIDE_ALL = 1;
	static hidden const STATUS_HIDE_BATTERY = 2;
	static hidden const STATUS_HIDE_CONNECTION = 3;
	static hidden const STATUS_HIDE_BATTERY_PERCENTAGE = 4;
	static hidden const STATUS_HIDE_BATTERY_PERCENTAGE_CONNECTION = 5;

	static hidden const STEPS_HIDE_ALL = 1;
	static hidden const STEPS_HIDE_CURRENT = 2;
	static hidden const STEPS_HIDE_GOAL_PROGRESS = 3;

	static hidden const NOTIFY_ALARM_HIDE_ALL = 1;
	static hidden const NOTIFY_ALARM_HIDE_NOTIFY = 2;
	static hidden const NOTIFY_ALARM_HIDE_ALARM = 3;

	hidden var isInLowPowerMode = false;
	hidden var uiUpdateNeeded = false;

	hidden var backgroundColor = Gfx.COLOR_BLACK;
	hidden var foregroundColor = Gfx.COLOR_RED;
	hidden var secondaryFgColor = Gfx.COLOR_BLUE;
	hidden var useMilitaryFormat = false;
	hidden var blinkTimeSeparator = false;
	hidden var iconColor = Gfx.COLOR_DK_GRAY;

	hidden var stepsLabelStringRes = "";

	hidden var statusState = SHOW_ALL;
	hidden var stepsState = SHOW_ALL;
	hidden var notifyAlarmState = SHOW_ALL;


	hidden var todayInfo = null;
	hidden var batteryPercentage = 0.0;
	hidden var batteryIconValue = null;
	hidden var currentSteps = 0.0f;
	hidden var stepsGoal = 100000.0f; // High default value to prevent dividing by 0

    function initialize() {
        WatchFace.initialize();
        stepsLabelStringRes = Ui.loadResource(Rez.Strings.StepsLabel);
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    	self.updateVariables();
    	self.updateExtraInfoVars();

		// Update Time and Extra Info data and colors on show
		var deviceSettings = Sys.getDeviceSettings();
		self.updateTime(deviceSettings);
		self.updateExtraInfo(deviceSettings);

		self.updateBgDrawable();
    }

    // Update the view
    function onUpdate(dc) {
    	if (AlniLargeTimeWatchFaceApp.settingsChanged) {
	    	self.updateVariables();
	    	self.updateExtraInfoVars();

			self.uiUpdateNeeded = true;

	    	AlniLargeTimeWatchFaceApp.resetSettingsChanged();
    	}
		self.updateBgDrawable();
    	var deviceSettings = Sys.getDeviceSettings();

		// Update the time information
        self.updateTime(deviceSettings);

		if (self.isInLowPowerMode || self.uiUpdateNeeded || Globals.IS_ALWAYS_ACTIVE) {
			// Only update extra information if in Low Power Mode (slow update)
			// OR when the UI needs updating (changed to/from Low Power Mode)
			self.updateExtraInfo(deviceSettings);
        }
		self.uiUpdateNeeded = false;
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
    	self.isInLowPowerMode = false;
    	self.uiUpdateNeeded = true;
		self.updateVariables();
		self.updateBgDrawable();
    	Ui.requestUpdate();
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
    	self.isInLowPowerMode = true;
    	self.uiUpdateNeeded = true;
		self.updateVariables();
		self.updateBgDrawable();
    	Ui.requestUpdate();
    }

	function onDisplayModeChanged() {
		self.uiUpdateNeeded = true;
    	Ui.requestUpdate();
	}

	function updateBgDrawable() {
		var bgDrawable = View.findDrawableById("Background") as Background;

		if (bgDrawable == null) {
			return;
		}

		var bgColor = self.isInLowPowerMode ? Gfx.COLOR_BLACK : self.backgroundColor;
		bgDrawable.setBgColor(bgColor);
	}

    function updateTime(deviceSettings) {
    	// Get the current time and format it correctly
        var timeFormat = "$1$:$2$";
        var clockTime = Sys.getClockTime();
        var hours = clockTime.hour;
        var minutes = clockTime.min;
        // Always format minutes with leading zero
        minutes = minutes.format("%02d");

        if (clockTime.min == 0 && (clockTime.sec == 0 || self.isInLowPowerMode)) {

        }
        // Update the AM/PM labels
        // The first character label of "am/pm" ("a/p").
        var timeAmPmLabel = View.findDrawableById("TimeAmPmLabel") as Ui.Text;
        // The last character label of "am/pm" ("m").
        var timeAmPmMLabel = View.findDrawableById("TimeAmPmMLabel") as Ui.Text;
        if (!deviceSettings.is24Hour) {
        	// We should display a 12-hour clock
        	// Set the AM/PM labels to the current secondary text colour
        	timeAmPmLabel.setColor(self.secondaryFgColor);
        	timeAmPmMLabel.setColor(self.secondaryFgColor);
        	if (hours > 11) {
        		// The hours is greater than 11 for 24-hours. Use PM
        		timeAmPmLabel.setText("p");
        	} else {
        		// Otherwise use AM
        		timeAmPmLabel.setText("a");
        	}
        	// Set the "m" part of "AM/PM"
        	timeAmPmMLabel.setText("m");
            if (hours > 12) {
            	// The 24-hours time is greater than 12. Subtract by 12
                hours = hours - 12;
            }
            if (hours == 0) {
            	// Fix Zero hours by setting it to 12.
            	hours = 12;
            }
            // Format the hours without leading zeros.
            hours = hours.format("%d");
            // Only use Military Format in 24 hour clock mode (if enabled)
            self.useMilitaryFormat = false; // Disable Military Format
        } else {
        	// We should display a 24-hour clock

        	// Hide the "AM/PM" labels used with the 12-hour clock
        	timeAmPmLabel.setText(""); // Set to empty string
        	timeAmPmMLabel.setText(""); // Set to empty string
        	//hours = hours.format("%02d");
            if (useMilitaryFormat) {
            	// If using military format, format the time as "HHMM"
                timeFormat = "$1$$2$";
                // Format the hours with leading zero
                hours = hours.format("%02d");
            } else {
            	// Otherwise format the hours without leading zero
            	hours = hours.format("%d");
            }
        }
        var timeString = Lang.format(timeFormat, [hours, minutes]);
        // Update the Time views
        var timeViewLabel = View.findDrawableById("TimeLabel") as Ui.Text;
        var timeHourView = View.findDrawableById("TimeHourLabel") as Ui.Text;
        var timeMinuteView = View.findDrawableById("TimeMinuteLabel") as Ui.Text;
        timeViewLabel.setColor(foregroundColor);
        Sys.println(self.useMilitaryFormat);
		if (!self.useMilitaryFormat) {
			// If not using Military Format then separate the hours and minutes
			// into two labels and use the default Time Label as Time Separator
			timeHourView.setColor(self.foregroundColor);
			timeMinuteView.setColor(self.foregroundColor);
			// Set the Hours label to the current hours
			timeHourView.setText(hours);
			// Set the Minutes label to the current minutes
			timeMinuteView.setText(minutes);
			// Set the default Time label as the hours and minutes separator
			if (self.blinkTimeSeparator && (!self.isInLowPowerMode || Globals.IS_ALWAYS_ACTIVE)) {
				// Only blink the Time Separator when not in Low Power Mode (OR
				// when the watch supports an Always Active watchface)
        		timeViewLabel.setText((clockTime.sec % 2) == 0 ? ":" : "");
        	} else {
        		// If the Time Separator should not blink OR we are in Low Power
        		// Mode, then always show the Time Separator
        		timeViewLabel.setText(":"); // Use colon as Time Separator
        	}
        } else {
        	// Otherwise, if using Military time format then do NOT separate the
        	// hours and the minutes
        	timeHourView.setText(""); // Hide the hours label
			timeMinuteView.setText(""); // Hide the minutes label
			// Set the default time label to the time string contaning both the
			// hours and the minutes (0945)
			timeString = Lang.format("$1$$2$", [hours, minutes]);
	        timeViewLabel.setText(timeString);
        }
    }

    function updateExtraInfo(deviceSettings) {
    	// Set the current Date information to view
        var today = DateTime.today(); // Get todays date
        // Use short (numeric) format for the todays info
	    var todayInfo = Gregorian.info(today, DateTime.FORMAT_SHORT);
	    var weekDayView = View.findDrawableById("WeekDayLabel") as Ui.Text; // Weekday view
	    var dateView = View.findDrawableById("DateLabel") as Ui.Text; // Day of Month view
	    var monthView = View.findDrawableById("MonthLabel") as Ui.Text; // Month name view

	    weekDayView.setColor(self.secondaryFgColor);
	    monthView.setColor(self.secondaryFgColor);

	    // Set the day of week to a localized string
	    weekDayView.setText(WEEK_DAY_STRINGS_RES_ID[todayInfo.day_of_week-1]);
	    // Set the current day of month to a "0" padded number
	    dateView.setText(todayInfo.day.format("%02d"));
	    // Set the day of month label to the foreground color
	    dateView.setColor(self.foregroundColor);
	    // Set the current month to a localized string
	    monthView.setText(MONTH_STRINGS_RES_ID[todayInfo.month-1]);
	    //monthView.setText(MONTH_STRINGS_RES_ID[11-1]);



        //var batteryImageView = View.findDrawableById("BatteryImage"); // Icon
        var batteryImageView = View.findDrawableById("BatteryImageLabel") as Ui.Text; // Icon
        var batteryLabelView = View.findDrawableById("BatteryLabel") as Ui.Text; // Label
        var phoneConnectedView = View.findDrawableById("PhoneConnectedImageLabel") as Ui.Text;
        Sys.println(self.statusState);
        if (self.isInLowPowerMode || self.uiUpdateNeeded) {
    		self.updateExtraInfoVars();
    	}
        if (self.statusState != STATUS_HIDE_ALL) {
	        // Update the Top status bar information views
	        if (self.statusState != STATUS_HIDE_BATTERY) {
		        // Get the current battery percentage
		        /*if (self.isInLowPowerMode || self.uiUpdateNeeded) {
		        	self.batteryPercentage = Sys.getSystemStats().battery.toNumber();
		        }*/
		        //var batteryPercentage = Sys.getSystemStats().battery.toNumber();
		        if (self.statusState != STATUS_HIDE_BATTERY_PERCENTAGE && self.statusState != STATUS_HIDE_BATTERY_PERCENTAGE_CONNECTION) {
			        // Update the Battery Label view with the current percentage as an
			        // numeric integer (no decimals)
			        batteryLabelView.setText(Lang.format("$1$%", [self.batteryPercentage.format("%d")]));
		        } else {
		        	batteryLabelView.setText("");
		        }
		        // Update the Battery Level icon based on the current battery level
		        var batteryIconValue = self.batteryIconValue; // Default Battery Icon value
		        batteryImageView.setColor(self.iconColor);
		        batteryLabelView.setColor(self.iconColor);
		        if (self.batteryPercentage >= 95) {
		        	// The battery is between 95 - 100% (full)
		        	batteryIconValue = Rez.Strings.ic_battery;
		        } else if (self.batteryPercentage >= 67) {
		        	// The battery is between 67 - 95% (above half full)
		        	batteryIconValue = Rez.Strings.ic_battery_3;
		        } else if (self.batteryPercentage > 33) {
		        	// The battery is between 33 - 67% (half full)
		        	batteryIconValue = Rez.Strings.ic_battery_2;
		        } else if (self.batteryPercentage > 5) {
		        	// The battery is between 5 - 33% (below half full)
		        	batteryIconValue = Rez.Strings.ic_battery_1;
		        } else {
		        	// The battery is between 0 - 5% (empty)
		        	batteryIconValue = Rez.Strings.ic_battery_0;
		        }
		        if (batteryIconValue != null) {
		        	batteryImageView.setText(batteryIconValue);
		        }
	        } else {
		        batteryImageView.setText("");
	        	batteryLabelView.setText("");
	        }

			if (self.statusState != STATUS_HIDE_CONNECTION && self.statusState != STATUS_HIDE_BATTERY_PERCENTAGE_CONNECTION) {
		        // Update the Phone Connected Icon view
		        phoneConnectedView.setText(Rez.Strings.ic_bluetooth_b);
		        if (deviceSettings.phoneConnected) {
		        	// Phone connected! Show the Bluetooth ON Icon
		        	phoneConnectedView.setColor(getInfoTextColor([Gfx.COLOR_DK_BLUE, Gfx.COLOR_BLUE]));
		        } else {
		        	// Phone NOT connected! Show the Bluetooth OFF Icon
		        	phoneConnectedView.setColor(self.iconColor);
		        }
	        } else {
	        	phoneConnectedView.setText("");
	        }
        } else {
        	batteryImageView.setText("");
        	batteryLabelView.setText("");
        	phoneConnectedView.setText("");
        }


        // Update the bottom information status region
        var notificationImageView = View.findDrawableById("NotificationImageLabel") as Ui.Text;
        var notificationView = View.findDrawableById("NotificationLabel") as Ui.Text;
        var alarmImageView = View.findDrawableById("AlarmImageLabel") as Ui.Text;
        var alarmView = View.findDrawableById("AlarmLabel") as Ui.Text;
        if (self.notifyAlarmState != NOTIFY_ALARM_HIDE_ALL) {
	        var notificationCount = deviceSettings.notificationCount;
	        var alarmCount = deviceSettings.alarmCount;

			if (self.notifyAlarmState != NOTIFY_ALARM_HIDE_NOTIFY) {
				notificationImageView.setText(Rez.Strings.ic_chat_bubble);
				notificationImageView.setColor(self.iconColor);
		        notificationView.setColor(self.iconColor);
		        if (notificationCount > 0) {
		        	// There are unread Phone Notifications. Show how many!
		        	notificationView.setText(notificationCount.format("%d"));
		        } else {
		        	// There are NO unread Phone Notifications. Hide the label.
		        	notificationView.setText("");
		        }
	        } else {
	        	notificationImageView.setText("");
	        	notificationView.setText("");
	        }

	        if (self.notifyAlarmState != NOTIFY_ALARM_HIDE_ALARM) {
	        	alarmImageView.setText(Rez.Strings.ic_alarm);
				alarmImageView.setColor(self.iconColor);
	    		alarmView.setColor(self.iconColor);
		        if (alarmCount > 0) {
		        	// There are active alarms! Show how many!
		        	alarmView.setText(alarmCount.format("%d"));
		        } else {
		        	// There are NO active alarms! Hide the label.
		        	alarmView.setText("");
		        }
	        } else {
	        	alarmImageView.setText("");
	        	alarmView.setText("");
	        }
        } else {
        	notificationImageView.setText("");
        	notificationView.setText("");
        	alarmImageView.setText("");
        	alarmView.setText("");
        }


        // Activity Information
        var stepsView = View.findDrawableById("StepsLabel") as Ui.Text;
	    var stepsGoalView = View.findDrawableById("StepsGoal") as ProgressBar;
	    var stepsImageView = View.findDrawableById("StepsImage") as Ui.Bitmap;
	    var stepsImageBitmap = Rez.Drawables.RunBitmap;
        if (self.stepsState != STEPS_HIDE_ALL) {
        	/*if (self.isInLowPowerMode || self.uiUpdateNeeded) {
	        	var activityInfo = ActMon.getInfo();
	        	self.currentSteps = activityInfo.steps.toFloat();
	        	self.stepsGoal = activityInfo.stepGoal.toFloat();
	        }*/
	        var stepsFromGoalPercentage = 0;
	        var stepsText = "";
	        if (self.stepsState != STEPS_HIDE_CURRENT) {
	        	stepsText = self.currentSteps.format("%d");
	        }
	        if (self.stepsState != STEPS_HIDE_GOAL_PROGRESS) {
	        	stepsFromGoalPercentage = (self.currentSteps / self.stepsGoal)* 100.0f;
	        }
	        /*var stepsText = Lang.format(stepsLabelStringRes, [
	        	currentSteps.format("%d"), stepsFromGoalPercentage.format("%d")
	        ]);*/
			stepsGoalView.setPercent(stepsFromGoalPercentage / 100.0f);
			stepsGoalView.setColor(getInfoTextColor([Gfx.COLOR_DK_GRAY, Gfx.COLOR_LT_GRAY]));
	        stepsView.setText(stepsText);
	        //stepsView.setText(stepsText);
	        // Check if the current steps are equal or greater than the step goal
	        if (self.currentSteps >= self.stepsGoal) {
	        	// We have reached the Step Goal for today! Change the color to show
	        	// this!
	        	stepsView.setColor(getInfoTextColor([Gfx.COLOR_DK_GREEN, Gfx.COLOR_GREEN]));
	        } else {
	        	// Use the default supplementary color for this Watch Face.
	        	//stepsView.setColor(self.secondaryFgColor);
	        	stepsView.setColor(getInfoTextColor([Gfx.COLOR_BLACK, Gfx.COLOR_WHITE]));
	        }
        } else {
        	stepsView.setText("");
        	stepsGoalView.setPercent(0);
        	stepsImageBitmap = Rez.Drawables.EmptyBitmap;
        }
        if (stepsImageView != null) {
        	stepsImageView.setBitmap(stepsImageBitmap);
        }


        /*var weatherView = View.findDrawableById("WeatherLabel");
        if (weatherView != null) {
	        var weatherData = AlniLargeTimeWatchFaceApp.weatherData;
	        if (weatherData != null) {
				weatherView.setText(weatherData["temperature"] + "\u00B0 " + weatherData["summary"]);
	        }
        }*/
    }


    function updateVariables() {
		self.backgroundColor = App.Properties.getValue("BackgroundColor");
		self.foregroundColor = App.Properties.getValue("ForegroundColor");
	    self.secondaryFgColor = App.Properties.getValue("SecondaryForegroundColor");
	    Sys.println(App.Properties.getValue("UseMilitaryFormat"));
	    self.useMilitaryFormat = App.Properties.getValue("UseMilitaryFormat");
	    self.blinkTimeSeparator = App.Properties.getValue("BlinkTimeSeparator");

	    self.iconColor = getInfoTextColor(null);

	    self.statusState = App.Properties.getValue("StatusVisibility");
	    self.stepsState = App.Properties.getValue("StepsVisibility");
	    self.notifyAlarmState = App.Properties.getValue("NotifyAlarmVisibility");
    }

    function updateExtraInfoVars() {
    	if (self.statusState != STATUS_HIDE_ALL) {
	        if (self.statusState != STATUS_HIDE_BATTERY) {
		        // Get the current battery percentage
	        	self.batteryPercentage = Sys.getSystemStats().battery.toNumber();
	        }

	        if (self.stepsState != STEPS_HIDE_ALL) {
	        	var activityInfo = ActMon.getInfo();
	        	self.currentSteps = activityInfo.steps.toFloat();
	        	self.stepsGoal = activityInfo.stepGoal.toFloat();
	        }
        }
    }

    function getInfoTextColor(colors) {
    	if (colors == null or !(colors instanceof Toybox.Lang.Array)) {
    		colors = [Gfx.COLOR_DK_GRAY, Gfx.COLOR_LT_GRAY];
    	}
		colors = colors as Toybox.Lang.Array;
    	if (self.backgroundColor >= Gfx.COLOR_LT_GRAY) {
    		return colors[0];
    	} else {
    		return colors[1];
    	}
    }

}
