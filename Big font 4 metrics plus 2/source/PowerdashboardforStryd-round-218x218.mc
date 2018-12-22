class Bigfont4metricsplus2App extends Toybox.Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    //! Return the initial view of your application here
    function getInitialView() {
        return [ new Bigfont4metricsplusView() ];
    }
}


class Bigfont4metricsplusView extends Toybox.WatchUi.DataField {
	using Toybox.WatchUi as Ui;

	//!Get device info
	var mySettings = System.getDeviceSettings();
	var screenWidth = mySettings.screenWidth;
	var screenShape = mySettings.screenShape;
	var screenHeight = mySettings.screenHeight;
	var distanceUnits = mySettings.distanceUnits;
	var watchType = mySettings.partNumber;
	var is24Hour = mySettings.is24Hour;   //!boolean
	var isTouchScreen = mySettings.isTouchScreen;  //!boolean
	var numberis24Hour = 0;
	var numberisTouchScreen = 0;
	
	hidden var mStoppedTime                 = 0;
	hidden var mStoppedDistance                 = 0;
	hidden var mLastLapStoppedDistMarker                 = 0;

	hidden var mCurrentHeartrate = 0;
	hidden var uTargetPaceMetric = 0;
    hidden var uHrZones                     = [ 93, 111, 130, 148, 167, 185 ];
    hidden var unitP                        = 1000.0;
    hidden var unitD                        = 1000.0;
    var Pace1 								= 0;
    var Pace2 								= 0;
    var Pace3 								= 0;
	var Pace4 								= 0;
    var Pace5 								= 0;
    var mETA								= 0;
    var aaltitude = 0;

    hidden var uTimerDisplay                = 0;
    //! 0 => Timer
    //! 1 => Lap time
    //! 2 => Last lap time
    //! 3 => Average lap time

    hidden var uDistDisplay                 = 0;
    //! 0 => Total distance
    //! 1 => Lap distance
    //! 2 => Last lap distance	

	
	hidden var uAveragedPace                = true;
    //! true     => Show current pace as Averaged Pace (i.e. average of the last 5 seconds)
    //! false    => Show current pace without averaging (i.e. pace at this second\)
	
    hidden var uRoundedPace                 = true;
    //! true     => Show current pace as Rounded Pace (i.e. rounded to 5 second intervals)
    //! false    => Show current pace without rounding (i.e. 1-second resolution)
	
    //! License serial
    hidden var umyNumber                    = 0;
    
    //! Show demoscreen
    hidden var uShowDemo					= false;

	hidden var uBlackBackground             = true;
    //! true     => Use black background
    //! false    => Use white background

    hidden var uBacklight                   = false;
    //! true     => Force the backlight to stay on permanently
    //! false    => Use the defined backlight timeout as normal


    hidden var uBottomLeftMetric            = 0;    //! Data to show in bottom left field
    hidden var uBottomRightMetric           = 1;    //! Data to show in bottom right field
    //! Lower fields enum:
    //! 0 => Current pace
    //! 1 => Lap pace
    //! 2 => Last lap pace
    //! 3 => Average pace
    //! 4 => Heartrate 
    //! 5 => Heartrate zone
	//! 6 => Cadence
    //! 7 => Altitude    
    //! 8 => ETA

	//! Race distance
    hidden var uRacedistance                    = 42195;

    //! Race distance
    hidden var uRacetime							= "04:00:00";

	//! Use timer of last lap to calculate ETA
    hidden var uETAfromLap = true;
	
	hidden var mfillLLColour = Graphics.COLOR_LT_GRAY;
	hidden var mColourPace = Graphics.COLOR_LT_GRAY;
			
    hidden var mTimerRunning                = false;

    hidden var mLaps                        = 1;
    hidden var mLastLapTimeMarker           = 0;
    hidden var mLastLapStoppedTimeMarker    = 0;
    hidden var mLastLapDistMarker           = 0;
	hidden var mLastLapElapsedDistance      = 0;
    
    hidden var mLastLapTimerTime            = 0;
 


    function initialize() {
    	 DataField.initialize();

         uHrZones = UserProfile.getHeartRateZones(UserProfile.getCurrentSport());

		 var mApp = Application.getApp();
         uTimerDisplay       = mApp.getProperty("pTimerDisplay");
         uBottomLeftMetric   = mApp.getProperty("pBottomLeftMetric");
         uBottomRightMetric  = mApp.getProperty("pBottomRightMetric");
         uBlackBackground    = mApp.getProperty("pBlackBackground");
         uBacklight          = mApp.getProperty("pBacklight");
         umyNumber			 = mApp.getProperty("myNumber");
         uShowDemo			 = mApp.getProperty("pShowDemo");
         uRoundedPace        = mApp.getProperty("pRoundedPace");
         uAveragedPace       = mApp.getProperty("pAveragedPace");	
         uRacedistance		 = mApp.getProperty("pRacedistance");		 
         uDistDisplay        = mApp.getProperty("pDistDisplay");
                  
        if (uRacedistance < 1) { 
			uRacedistance 		= 42195;
		}


        if (System.getDeviceSettings().paceUnits == System.UNIT_STATUTE) {
            unitP = 1609.344;
        }

        if (System.getDeviceSettings().distanceUnits == System.UNIT_STATUTE) {
            unitD = 1609.344;
        }
	}


    //! Calculations we need to do every second even when the data field is not visible
    function compute(info) {
		//! If enabled, switch the backlight on in order to make it stay on
        if (uBacklight) {
             Attention.backlight(true);
        }
		var mCurrentPower;
		var mPowerTime;
		var mElapsedPower;
        var mElapsedDistance    = (info.elapsedDistance != null) ? info.elapsedDistance : 0.0;
        var mLapElapsedDistance = mElapsedDistance - mLastLapDistMarker;
        if (mTimerRunning) {  //! We only do some calculations if the timer is running
            mCurrentPower    = (info.currentPower != null) ? info.currentPower : 0;
            mPowerTime		 = (info.currentPower != null) ? mPowerTime+1 : 0;
            mElapsedPower    = mElapsedPower + mCurrentPower;  
        var mLapElapsedDistance = (mElapsedDistance != null and mLastLapDistMarker != null) ? mElapsedDistance - mLastLapDistMarker : 0;
            mCurrentHeartrate    = (info.currentHeartRate != null) ? info.currentHeartRate : 0;
        }
    }

    //! Store last lap quantities and set lap markers
    function onTimerLap() {
        var info = Activity.getActivityInfo();

        mLastLapTimerTime        = (info.timerTime - mLastLapTimeMarker) / 1000;
        mLastLapElapsedDistance  = (info.elapsedDistance != null) ? info.elapsedDistance - mLastLapDistMarker : 0;


        mLaps++;
        mLastLapDistMarker           = info.elapsedDistance;
        mLastLapTimeMarker           = info.timerTime;
        mLastLapStoppedTimeMarker    = mStoppedTime;
        mLastLapStoppedDistMarker    = mStoppedDistance;

    }
    
    //! Current activity is ended
    function onTimerReset() {
        mLaps                       = 1;
        mLastLapDistMarker          = 0;
        mLastLapTimeMarker          = 0;

        mLastLapTimerTime           = 0;
        mLastLapElapsedDistance     = 0;

    }


    //! Do necessary calculations and draw fields.
    //! This will be called once a second when the data field is visible.
    function onUpdate(dc) {
       var info = Activity.getActivityInfo();
       var mColour;
	   var mColourFont;
		var mColourFont1;
        var mColourLine;
        var mColourBackGround;

		if (uBlackBackground == true ){
			mColourFont = Graphics.COLOR_WHITE;
			mColourFont1 = Graphics.COLOR_WHITE;
			mColourLine = Graphics.COLOR_YELLOW;
			mColourBackGround = Graphics.COLOR_BLACK;
		} else {
			mColourFont = Graphics.COLOR_BLACK;
			mColourFont1 = Graphics.COLOR_BLACK;
			mColourLine = Graphics.COLOR_RED;
			mColourBackGround = Graphics.COLOR_WHITE;
		}
		
		//! Set background color
        dc.setColor(mColourBackGround, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle (0, 0, 218, 218);		
        	
    	//! Check license
		if (is24Hour == false) {
        	numberis24Hour = 81;
    	} else {
    		numberis24Hour = 23;
    	}
    	if (isTouchScreen == false) {
        	numberisTouchScreen = 97;
    	} else {
    		numberisTouchScreen = 9;
    	}
		var deviceID1 = (screenWidth+screenShape-3)*(screenHeight-distanceUnits+8)-numberis24Hour-numberisTouchScreen+15;
		var deviceID2 = numberis24Hour+numberisTouchScreen;
		var mtest = (numberisTouchScreen+distanceUnits+13)*screenWidth-(screenHeight+numberis24Hour-11)*screenShape;
	   	   
        //! Calculate lap distance
        var mLapElapsedDistance = 0.0;
        if (info.elapsedDistance != null) {
            mLapElapsedDistance = info.elapsedDistance - mLastLapDistMarker;
        }
        
        //! Calculate lap time and convert timers from milliseconds to seconds
        var mTimerTime      = 0;
        var mLapTimerTime   = 0;

        if (info.timerTime != null) {
            mTimerTime = info.timerTime / 1000;
            mLapTimerTime = (info.timerTime - mLastLapTimeMarker) / 1000;
        }
        
        //! Calculate lap speeds
        var mLapSpeed = 0.0;
        var mLastLapSpeed = 0.0;
        if (mLapTimerTime > 0 && mLapElapsedDistance > 0) {
            mLapSpeed = mLapElapsedDistance / mLapTimerTime;
        }
        if (mLastLapTimerTime > 0 && mLastLapElapsedDistance > 0) {
            mLastLapSpeed = mLastLapElapsedDistance / mLastLapTimerTime;
        }

        //! Calculate ETA
        if (info.elapsedDistance != null && info.timerTime != null) {
            	if (info.elapsedDistance > 5) {
            		mETA = uRacedistance / (info.elapsedDistance/info.timerTime);
            	}
        }
		
        //! Calculate elevation differences and rounding altitude
        var aaltitude = 0;
        if (info.altitude != null) {        
          aaltitude = Math.round(info.altitude).toNumber();
		}

        //! Colouring heartrate zone		
        var mColourHR = Graphics.COLOR_LT_GRAY; //! No zone default light grey
        var  mCurrentHeartZone = 1;
        if (info.currentHeartRate != null) {
            var mCurrentHeartRate = info.currentHeartRate;
            if (uHrZones != null) {
                if (mCurrentHeartRate >= uHrZones[4]) {
                    mColourHR = Graphics.COLOR_RED;        //! Maximum (Z5)
                    mCurrentHeartZone = 5;
                } else if (mCurrentHeartRate >= uHrZones[3]) {
                    mColourHR = Graphics.COLOR_ORANGE;    //! Threshold (Z4)
                    mCurrentHeartZone = 4;
                } else if (mCurrentHeartRate >= uHrZones[2]) {
                    mColourHR = Graphics.COLOR_GREEN;        //! Aerobic (Z3)
                    mCurrentHeartZone = 3;
                } else if (mCurrentHeartRate >= uHrZones[1]) {
                    mColourHR = Graphics.COLOR_BLUE;        //! Easy (Z2)
                    mCurrentHeartZone = 2;
                } //! Else Warm-up (Z1) and no zone both inherit default light grey here
            }

        }		

        //! Colouring cadence zone (fixed thresholds and colours to match Garmin Connect)
        var mColourCAD = Graphics.COLOR_LT_GRAY;
        if (info.currentCadence != null) {
            if (info.currentCadence > 183) {
                mColourCAD = Graphics.COLOR_PURPLE;
            } else if (info.currentCadence >= 174) {
                mColourCAD = Graphics.COLOR_BLUE;
            } else if (info.currentCadence >= 164) {
                mColourCAD = Graphics.COLOR_GREEN;
            } else if (info.currentCadence >= 153) {
                mColourCAD = Graphics.COLOR_ORANGE;
            } else if (info.currentCadence >= 120) {
                mColourCAD = Graphics.COLOR_RED;
            } //! Else no cadence or walking/stopped inherits default light grey here
        }

        //! Top row left: time
        var mTime = mTimerTime;
        var lTime = "Timer";
        if (uTimerDisplay == 1) {
            mTime = mLapTimerTime;
            lTime = "LapTime";
        } else if (uTimerDisplay == 2) {
            mTime = mLastLapTimerTime;
            lTime = "L-1 Time";
        } else if (uTimerDisplay == 3) {
            mTime = mTimerTime / mLaps;
            lTime = "Avg LapT";
        }

        //! Top row right: distance
        var mDistance = (info.elapsedDistance != null) ? info.elapsedDistance / unitD : 0;
        var lDistance = "Distance";
        if (uDistDisplay == 1) {
            mDistance = mLapElapsedDistance / unitD;
            lDistance = "Lap Dist.";
        } else if (uDistDisplay == 2) {
            mDistance = mLastLapElapsedDistance / unitD;
            lDistance = "L-1 Dist.";
        }
        var DistanceString = "%.2f";
        if (mDistance > 100) {
             DistanceString = "%.1f";
        }		
		
        //! Calculate current pace
        var Averagespeedinmpersec 			= 0;
        var fCurrentPace 					= 0;
        var currentSpeedtest				= 0;
        if (info.currentSpeed != null) {
        	currentSpeedtest = info.currentSpeed; 
        }
        if (currentSpeedtest > 0) {
            if (uAveragedPace == true) {
            	//! Calculate average pace
				if (info.currentSpeed != null) {
        		Pace5 								= Pace4;
        		Pace4 								= Pace3;
        		Pace3 								= Pace2;
        		Pace2 								= Pace1;
        		Pace1								= info.currentSpeed; 
        		} else {
					Pace5 								= Pace4;
    	    		Pace4 								= Pace3;
        			Pace3 								= Pace2;
        			Pace2 								= Pace1;
        			Pace1								= 0;
				}
				Averagespeedinmpersec= (Pace1+Pace2+Pace3+Pace4+Pace5)/5;
				if (uRoundedPace) {
                	fCurrentPace 					= unitP/(Math.round( (unitP/Averagespeedinmpersec) / 5 ) * 5);
                } else {
                	fCurrentPace 					= Averagespeedinmpersec;
                }
			} else {
				if (uRoundedPace) {
                	fCurrentPace = unitP/(Math.round( (unitP/info.currentSpeed) / 5 ) * 5);
                } else {
                	fCurrentPace = info.currentSpeed;
                }
			}
		}
		

		//! Coloring of pacefield
        if (info.averageSpeed != null and info.averageSpeed > 0.1) {
        		uTargetPaceMetric = 1000/info.averageSpeed;
        }

        if ( uTargetPaceMetric > 2 ) {
        	mColourPace = Graphics.COLOR_LT_GRAY;
        	if (info.currentSpeed != null) { 
       	     var uTargetSpeed = unitP/uTargetPaceMetric;
        	    if (uTargetSpeed > 0) {
            	    var paceDeviation = (fCurrentPace / uTargetSpeed);
            	    if (paceDeviation < 0.95) {    //! More than 5% slower
            	    		mColourPace = Graphics.COLOR_RED;
            	    } else if (paceDeviation > 1.05) {
            	    		mColourPace = Graphics.COLOR_PURPLE;
            	    } else { 
            	    		mColourPace = Graphics.COLOR_GREEN;
            	    }            	    
          	    }
        	}    
        } else {
        mColourPace = Graphics.COLOR_LT_GRAY;
		}


		//! Determine required finish time and calculate required pace 	
        var mRacehour = uRacetime.substring(0, 2);
        var mRacemin = uRacetime.substring(3, 5);
        var mRacesec = uRacetime.substring(6, 8);
        mRacehour = mRacehour.toNumber();
        mRacemin = mRacemin.toNumber();
        mRacesec = mRacesec.toNumber();
        var mRacetime = mRacehour*3600 + mRacemin*60 + mRacesec;
        var RequiredPace = 0;		
		if (info.elapsedDistance != null and info.timerTime != null and mRacetime != info.timerTime/1000 and mRacetime > info.timerTime/1000) {
        	RequiredPace = (uRacedistance - info.elapsedDistance) / (mRacetime - info.timerTime/1000); 
        } 
		
		var mColourETA = Graphics.COLOR_LT_GRAY;
        if (mETA > mRacetime) {
        	mColourETA = Graphics.COLOR_GREEN;
        } else if (mETA < mRacetime) {
        	mColourETA = Graphics.COLOR_RED;
        }	
        		
		var mfillulColour = Graphics.COLOR_LT_GRAY;
		var mfillurColour = Graphics.COLOR_LT_GRAY;
		var mfillblColour = Graphics.COLOR_LT_GRAY;
		var mfillbrColour = Graphics.COLOR_LT_GRAY;
		var mfillColour = Graphics.COLOR_LT_GRAY;

		//!Determine whether demofield should be displayed
        if (uShowDemo == false) {
        	if (umyNumber != mtest && mTimerTime > 900)  {
        		uShowDemo = true;        		
        	}
        }


//!===============================Device specific code hereunder==============================================================
        
       if (uShowDemo == true ) {       
		//! Show demofield
		dc.setColor(mColourFont, Graphics.COLOR_TRANSPARENT);

		if (umyNumber == mtest) {
			dc.drawText(107, 110, Graphics.FONT_XTINY, "Registered !!", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
			dc.drawText(80, 150, Graphics.FONT_XTINY, "License code: ", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
			dc.drawText(150, 150, Graphics.FONT_XTINY, mtest, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
		} else {
      		dc.drawText(110, 80, Graphics.FONT_XTINY, "License needed !!", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
      		dc.drawText(110, 100, Graphics.FONT_XTINY, "Run is recorded though", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
			dc.drawText(80, 142, Graphics.FONT_MEDIUM, "ID 1: ", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
			dc.drawText(152, 135, Graphics.FONT_NUMBER_MEDIUM, deviceID1, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
			dc.drawText(80, 187, Graphics.FONT_MEDIUM, "ID 2: " , Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
			dc.drawText(137, 180, Graphics.FONT_NUMBER_MEDIUM, deviceID2, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
      	}
      	
	  } else {
        //! Show datafield instead of demofield        
        //! Coordinates of colour indicators
		var xful = 0;
		var yful = 0;
		var wful = 108;
		var hful = 58;
		
		var xfur = 110;
		var yfur = 0;
		var wfur = 107;
		var hfur = 58;

		var xfbl = 0;
		var yfbl = 160;
		var wfbl = 108;
		var hfbl = 58;
		
		var xfbr = 110;
		var yfbr = 160;
		var wfbr = 107;
		var hfbr = 58;

//! Draw separator lines
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(0,   109,  218, 109);
        dc.drawLine(109, 0,  109, 218);
        
        //! Set text colour and font
		dc.setColor(mColourFont, Graphics.COLOR_TRANSPARENT);
		var Garminfont2;
	    var Garminfont3;

 	    var Garminfont1 = Graphics.FONT_NUMBER_MEDIUM;
    	Garminfont2 = Ui.loadResource(Rez.Fonts.Garmin2);
		Garminfont3 = Ui.loadResource(Rez.Fonts.Garmin3);	

        //!
		//! Coordinates of labels and metrics
        //!
        var xul=56;
        var yul=79;
        var xtul=66;
        var ytul=40;

        var xur=162;
        var yur=79;
        var xtur=153;
        var ytur=40;

        var xbl=56;
        var ybl=132;
        var xtbl=66;
        var ytbl=172;

        var xbr=162;
        var ybr=132;
        var xtbr=153;
        var ytbr=172;

		var zero = 0;
		var xTimer = 14;
		var xseconds = 82;
		var yseconds = 75;



//!===============================Device specific code hereabove==============================================================		
		
		//! Drawing upper colour indicators
        mColour = Graphics.COLOR_LT_GRAY; 
        dc.setColor(mfillulColour, Graphics.COLOR_TRANSPARENT);		
		dc.fillRectangle(xful, yful, wful, hful);
        dc.setColor(mfillurColour, Graphics.COLOR_TRANSPARENT);		
        dc.fillRectangle(xfur, yfur, wfur, hfur);

        //! Top row left: timer 
        dc.setColor(mColourFont, Graphics.COLOR_TRANSPARENT);
        var fTimerSecs = (mTime % 60).format("%02d");
        var fTimer = (mTime / 60).format("%d") + ":" + fTimerSecs;  //! Format time as m:ss
        if (mTime > 3599) {
            //! (Re-)format time as h:mm(ss) if more than an hour
            fTimer = (mTime / 3600).format("%d") + ":" + (mTime / 60 % 60).format("%02d");
            dc.drawText(xseconds, yseconds, Graphics.FONT_NUMBER_MILD, fTimerSecs, Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
        	xTimer = 0;
        }

        dc.drawText(xul-xTimer, yul, Garminfont2, fTimer, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(xtul, ytul, Garminfont3, lTime, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);

        //! Top row right: distance
        dc.drawText(xur, yur, Garminfont2, mDistance.format(DistanceString), Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(xtur, ytur, Garminfont3,  lDistance, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
		
		var fieldValue = 0;
		var fieldLabel = "Error";
		var fieldformat = "0decimal";
		mfillblColour = Graphics.COLOR_LT_GRAY;

        //! Bottom left: current pace is default
        if (uBottomLeftMetric == 0) {
            fieldValue = fCurrentPace;
            fieldLabel = "Pace";
            fieldformat = "pace";
            mfillblColour = mColourPace;
        } else if (uBottomLeftMetric == 1) {
            fieldValue = mLapSpeed;
            fieldLabel = "L Pace";
            fieldformat = "pace";
        } else if (uBottomLeftMetric == 2) {
            fieldValue = mLastLapSpeed;
            fieldLabel = "LL Pace";
            fieldformat = "pace";
        } else if (uBottomLeftMetric == 3) {
            fieldValue = (info.averageSpeed != null) ? info.averageSpeed : 0;
            fieldLabel = "A pace";
            fieldformat = "pace";
        } else if (uBottomLeftMetric == 4) {
            fieldValue = (info.currentSpeed != null) ? 3.6*info.currentSpeed*1000/unitP : 0;
            fieldLabel = "Speed";
            fieldformat = "1decimal";
            mfillblColour = mColourPace;
        } else if (uBottomLeftMetric == 5) {
        var mCurrentHeartRate=0;
            fieldValue = (info.currentHeartRate != null) ? mCurrentHeartRate : 0;
            fieldLabel = "HR";
            fieldformat = "0decimal";
            mfillblColour = mColourHR;
        } else if (uBottomLeftMetric == 6) {
            fieldValue = mCurrentHeartZone;
            fieldLabel = "HR zone";
            fieldformat = "0decimal";
        } else if (uBottomLeftMetric == 7) {
            fieldValue = (info.currentCadence != null) ? info.currentCadence : 0;
            fieldLabel = "Cadence";
            fieldformat = "0decimal";
            mfillblColour = mColourCAD;
        } else if (uBottomLeftMetric == 8) {
            fieldValue = aaltitude;
            fieldLabel = "Altitude";
            fieldformat = "0decimal";
        } else if (uBottomLeftMetric == 9) {
            fieldValue = mETA;
            fieldLabel = "ETA";
            fieldformat = "time";
            mfillblColour = mColourETA;
        } else if (uBottomLeftMetric == 10) {
            fieldValue = RequiredPace;
            fieldLabel = "Req pac";
            fieldformat = "pace";
            mfillblColour = mColourETA;
        }


		//! Drawing lower left colour indicator
        dc.setColor(mfillblColour, Graphics.COLOR_TRANSPARENT);        
        dc.fillRectangle(xfbl, yfbl, wfbl, hfbl);        
        
		dc.setColor(mColourFont, Graphics.COLOR_TRANSPARENT);
        if (fieldformat.equals("0decimal" ) == true ) {
           dc.drawText(xbl, ybl, Garminfont2, fieldValue.format("%d"), Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        } else if ( fieldformat.equals("1decimal" ) == true ) {
        	dc.drawText(xbl, ybl, Garminfont2, fieldValue.format("%.1f"), Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        } else if ( fieldformat.equals("2decimal" ) == true ) {
        	dc.drawText(xbl, ybl, Garminfont2, fieldValue.format("%.2f"), Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        } else if ( fieldformat.equals("pace" ) == true ) {
        	dc.drawText(xbl, ybl, Garminfont2, (fieldValue != 0) ? fmtPace(fieldValue) : "0:00", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        } else if ( fieldformat.equals("time" ) == true ) {
        	dc.drawText(xbl, ybl, Garminfont1, EstimatedTime(fieldValue), Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        }
        dc.drawText(xtbl, ytbl, Garminfont3, fieldLabel, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);

        //! Bottom right: Last lap power is default
        if (uBottomRightMetric == 0) {
            fieldValue = fCurrentPace;
            fieldLabel = "Pace";
            fieldformat = "pace";
            mfillbrColour = mColourPace;
        } else if (uBottomRightMetric == 1) {
            fieldValue = mLapSpeed;
            fieldLabel = "L Pace";
            fieldformat = "pace";
        } else if (uBottomRightMetric == 2) {
            fieldValue = mLastLapSpeed;
            fieldLabel = "LL Pace";
            fieldformat = "pace";
        } else if (uBottomRightMetric == 3) {
            fieldValue = (info.averageSpeed != null) ? info.averageSpeed : 0;
            fieldLabel = "A pace";
            fieldformat = "pace";
        } else if (uBottomRightMetric == 4) {
            fieldValue = (info.currentSpeed != null) ? 3.6*info.currentSpeed*1000/unitP : 0;
            fieldLabel = "Speed";
            fieldformat = "1decimal";
            mfillbrColour = mColourPace;
        } else if (uBottomRightMetric == 5) {
            fieldValue = (info.currentHeartRate != null) ? info.currentHeartRate : 0;
            fieldLabel = "HR";
            fieldformat = "0decimal";
            mfillbrColour = mColourHR;
        } else if (uBottomRightMetric == 6) {
            fieldValue = mCurrentHeartZone;
            fieldLabel = "HR zone";
            fieldformat = "0decimal";
        } else if (uBottomRightMetric == 7) {
            fieldValue = (info.currentCadence != null) ? info.currentCadence : 0;
            fieldLabel = "Cadence";
            fieldformat = "0decimal";
            mfillbrColour = mColourCAD;
        } else if (uBottomRightMetric == 8) {
            fieldValue = aaltitude;
            fieldLabel = "Altitude";
            fieldformat = "0decimal";
        } else if (uBottomRightMetric == 9) {
            fieldValue = mETA;
            fieldLabel = "ETA";
            fieldformat = "time";
            mfillbrColour = mColourETA;
        } else if (uBottomRightMetric == 10) {
            fieldValue = RequiredPace;
            fieldLabel = "Req pac";
            fieldformat = "pace";
            mfillbrColour = mColourETA;
        }


		//! Drawing lower right colour indicator        
        dc.setColor(mfillbrColour, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(xfbr, yfbr, wfbr, hfbr);

        dc.setColor(mColourFont, Graphics.COLOR_TRANSPARENT);
        if (fieldformat.equals("0decimal" ) == true ) {
           dc.drawText(xbr, ybr, Garminfont2, fieldValue.format("%d"), Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);        
        } else if ( fieldformat.equals("1decimal" ) == true ) {
        	dc.drawText(xbr, ybr, Garminfont2, fieldValue.format("%.1f"), Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        } else if ( fieldformat.equals("2decimal" ) == true ) {
        	dc.drawText(xbr, ybr, Garminfont2, fieldValue.format("%.2f"), Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        }  else if ( fieldformat.equals("pace" ) == true ) {
        	dc.drawText(xbr, ybr, Garminfont2, (fieldValue != 0) ? fmtPace(fieldValue) : "0:00", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        } else if ( fieldformat.equals("time" ) == true ) {
        	dc.drawText(xbr, ybr, Garminfont1, EstimatedTime(fieldValue), Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        }
		dc.drawText(xtbr, ytbr, Garminfont3, fieldLabel, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
		
		
	   } 
	}   
	
    function EstimatedTime(secs) {
        var s = (secs).toLong();
        return (s / 3600000).format("%0d") + ":" + (s /60000 % 60).format("%02d") + ":" + (s /1000 % 60).format("%02d");
    }

    function EstimatedTimeSmall(secs) {
        var s = (secs).toLong();
        return (s /60000 % 60).format("%02d") + ":" + (s /1000 % 60).format("%02d");
    }

    function fmtPace(secs) {
        var s = (unitP/secs).toLong();
        return (s / 60).format("%0d") + ":" + (s % 60).format("%02d");
    }		
}
