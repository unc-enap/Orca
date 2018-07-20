//--------------------------------------------------------------------------------
// Class:		LC950Model
// brief:		Oscilloscope data.
// Author:		Jan M. Wouters
// History:		2004-04-12 (jmw) - Original
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nuclear Physics and 
//Astrophysics (CENPA) sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#import "ORGpibEnetModel.h"
#import "ORGpibDeviceModel.h"
#import "ORLC950Model.h"
#import "ORDataTypeAssigner.h"

@implementation ORLC950Model

NSString* ORLC950Lock      = @"ORLC950Lock";
NSString* ORLC950GpibLock  = @"ORLC950GpibLock";

#pragma mark ***initialization

//--------------------------------------------------------------------------------
/*!\method  init
 * \brief	Called first time class is initialized.  Used to set basic
 *			default values first time object is created.
 * \note	
 */
//--------------------------------------------------------------------------------
- (id) init
{
    self = [ super init ];
	
	[[self undoManager] disableUndoRegistration];
	
    mRunInProgress = false;
	
	[[self undoManager] enableUndoRegistration];
	
    return self;
}

//--------------------------------------------------------------------------------
/*!\method  dealloc
 * \brief	Deletes anything on the heap.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) dealloc
{
    short i;
    for ( i = 0; i < kMaxOscChnls; i++ ){
        [ mDataObj[ i ] release ];
    } 	
	
    [ super dealloc ];
}

//--------------------------------------------------------------------------------
/*!\method  setUpImage
 * \brief	Sets the image used by this device.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) setUpImage
{
    [ self setImage: [ NSImage imageNamed: @"LC950Oscilloscope" ]];
}

//--------------------------------------------------------------------------------
/*!\method  makeMainController
 * \brief	Makes the controller object that interfaces between the GUI and
 *			this model.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) makeMainController
{
    [ self linkToController: @"ORLC950Controller" ];
}

- (NSString*) helpURL
{
	return @"GPIB/LC950.html";
}

#pragma mark ***Hardware - General
//--------------------------------------------------------------------------------
/*!\method  oscScopeId
 * \brief	get the scope id and set internal variable.
 * \return	Number indicating which kind of scope is present.
 * \error	Raises error if command fails.
 * \note	
 */
//--------------------------------------------------------------------------------
- (short) oscScopeId
{
    mScopeVersion = 0;
	
    [ self getID ];
	
    if ( [ mIdentifier rangeOfString: @"WP950" ].location != NSNotFound )
    {
        mID = ORLC950;
        mScopeType = 950;
        mScopeVersion = ' ';
    }
    else
    {
        mID = ORLC950;
        mScopeType = 950;
        mScopeVersion = ' '; 
    }
    
    return( mID );
}

//--------------------------------------------------------------------------------
/*!\method  oscBusy
 * \brief	Check if the oscilloscope is busy executing a previous command
 * \error	Raises error if command fails.
 * \note	
 */
//--------------------------------------------------------------------------------
- (bool) oscBusy
{
	int32_t	inr;
    char	theDataOsc[ 8 ];
	
    // Write the command.
    int32_t lengthReturn = [ mController writeReadDevice: mPrimaryAddress 
											  command: @"INR?"
												 data: theDataOsc
											maxLength: 6 ];
	
    // Check the return value. If first bit is set in INR then have data from acquisition.
    if ( lengthReturn > 0 ) 
	{
		inr = [ self convertStringToLong: theDataOsc withLength: lengthReturn ];
		if ( inr & 0x0001 )
			return false;
		else
			return true;
		//        if ( !strncmp( theDataOsc, "1", 1 ) ) 
		//			return true;
		//        else if ( !strncmp( theDataOsc, "0", 1 ) ) 
		//			return false;
		//        else 
		//			return true;
    }
    else 
		return true;
}

//--------------------------------------------------------------------------------
/*!\method  oscGetDateTime
 * \brief	Get the date and time from the oscilloscope
 * \error	Raises error if command fails.
 * \note	1) Format for LeCroy time is day,month, year, hour,minute,second.
 *				day 1 to 31
 *				month = {JAN, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC}
 *				year = 1990 to 2037
 *				hour = 0 to 23
 *				minute = 0 to 59
 *				second = 0 to 59
 */
//--------------------------------------------------------------------------------
- (int32_t) oscGetDateTime
{
	int32_t		returnLength = 0;
    int32_t		timeLong = 0;
	//	NSString*	dateStr;
	//	NSString*  	timeStr;
	//	NSString*	dateTime;
    char		timeBuffer[ 50 ];
	//    short 		i = 0;
	//	bool		haveDate = false;
	//	bool		haveTime = false;
	
	// Get date and time from oscilloscope.
	// Get the channel coupling option.
    returnLength = [ self writeReadGPIBDevice: @"DATE?"
                                         data: mReturnData
                                    maxLength: kMaxGPIBReturn ];
	
	// Translate the date/time
	if ( returnLength > 0 )
	{
		NSString* dateStr = [ NSString stringWithCString: &mReturnData[ 0 ] encoding:NSASCIIStringEncoding];
		NSArray* dateComponents = [ dateStr componentsSeparatedByString: @"," ];
		
		sprintf( timeBuffer, "%s/%s/%s %s:%s:%s", 
                [[ dateComponents objectAtIndex: 2 ] cStringUsingEncoding:NSASCIIStringEncoding ],
				[[ dateComponents objectAtIndex: 1 ] cStringUsingEncoding:NSASCIIStringEncoding ],
				[[ dateComponents objectAtIndex: 0 ] cStringUsingEncoding:NSASCIIStringEncoding ],
				[[ dateComponents objectAtIndex: 3 ] cStringUsingEncoding:NSASCIIStringEncoding ],
				[[ dateComponents objectAtIndex: 4 ] cStringUsingEncoding:NSASCIIStringEncoding ],
				[[ dateComponents objectAtIndex: 5 ] cStringUsingEncoding:NSASCIIStringEncoding ] );
		
		timeLong = convertTimeCharToLong( timeBuffer );		
	}
    
    return( timeLong );
}

//--------------------------------------------------------------------------------
/*!\method  oscResetOscilloscope
 * \brief	Tell the oscilloscope to reconfigure itself.  Then read in the
 *			new parameters into the model.
 * \error	Raises error if command fails.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscResetOscilloscope
{
    NSTimeInterval t0;
    
    [ self writeToGPIBDevice: @"AUTO_SETUP" ];
    t0 = [ NSDate timeIntervalSinceReferenceDate ];
    while ( [NSDate timeIntervalSinceReferenceDate ] - t0 < 15 );
    BOOL savedstate = [ self doFullInit ];
    [ self setDoFullInit: YES ];
    [ self oscSetStandardSettings ];
    [ self setDoFullInit: savedstate ];
}

//--------------------------------------------------------------------------------
/*!\method  oscSetDateTime
 * \brief	Set the date and time of the oscilloscope.
 * \param	aDateTime			- The date/time the oscilloscope will be set to.
 * \error	Raises error if command fails.
 * \note	1) See routine oscGetDateTime for description of date/time format.
 */
//--------------------------------------------------------------------------------
- (void) oscSetDateTime: (time_t) aDateTime
{
	char				sDateTime[ 30 ];
	//	NSMutableString*	dateString;
	//	NSMutableString*	timeString;
	
	// Convert time to struct tm format.
	struct tm* timeStruct = localtime( &aDateTime );
	
	// Build the time string
	sprintf( sDateTime, "%d,%d,%d,%d,%d,%d", timeStruct->tm_mday, timeStruct->tm_mon,
			(timeStruct->tm_year + 1900), 
			timeStruct->tm_hour, timeStruct->tm_min, timeStruct->tm_sec );	
	
	// Set date and time
    [ self writeToGPIBDevice: [ NSString stringWithFormat: @"DATE \"%s\"", sDateTime ]];
}

//--------------------------------------------------------------------------------
/*!\method  oscLockPanel
 * \brief	Lock or unlock the oscilloscope front controls.
 * \param	aFlag			- True - lock the panel otherwise unlock it.
 * \error	Raises error if command fails.
 * \note		
 */
//--------------------------------------------------------------------------------
- (void) oscLockPanel: (bool) aFlag
{
	//    NSString*	command;
    
    if ( aFlag )
    {
		//        command = @"DISPLAY OFF";
    }
    else{
		//        command = @"DISPLAY ON";
    }
    
	//    [ self writeToGPIBDevice: command ];
}

//-----------------------------------------------------------------------------
/*!\method  oscSendTextMessage
 * \brief 	Write message to screen of oscilloscope. 
 * \error	Raises error if command fails.
 * \note		
 */
//--------------------------------------------------------------------------------
- (void) oscSendTextMessage: (NSString*) aMsg
{
    [ self writeToGPIBDevice: [ NSString stringWithFormat: @"MESSAGE '%s'", [ aMsg cStringUsingEncoding:NSASCIIStringEncoding ]]];
}

//--------------------------------------------------------------------------------
/*!\method  oscSetQueryFormat
 * \brief	Determine the format the oscilloscope will use to return all queries
 * \param	aFormat			- The format to use.
 * \error	Raises error if command fails.
 * \note	1) Possible options for format are:
 *				kNoLabel - Return does not include label, just response.
 *				kShortLabel - Return includes abbreviated version of query command.
 *				kLongLabel - Return includes full query command.
 */
//--------------------------------------------------------------------------------
-(void) oscSetQueryFormat: (short) aFormat
{
    switch ( aFormat){
			
        case kNoLabel:
            [ self writeToGPIBDevice: @"COMM_HEADER OFF" ];
			break;
			
        case kShortLabel:
            [ self writeToGPIBDevice: @"COMM_HEADER SHORT" ];
			break;
			
        case kLongLabel:
            [ self writeToGPIBDevice: @"COMM_HEADER LONG" ];
			break;
			
        default:
            [ self writeToGPIBDevice: @"COMM_HEADER LONG" ];
			break;
    }
	
    NSLog( @"LeCroy: Data query format sent to LeCroy.\n" );
}

//--------------------------------------------------------------------------------
/*!\method  oscSetScreenDisplay
 * \brief	Turn the oscilloscope display on or off.
 * \param	aDisplayOn			- True - turn display on, otherwise turn it off.
 * \error	Raises error if command fails.
 * \note	Turning display off speeds up acquisition.	
 */
//--------------------------------------------------------------------------------
- (void) oscSetScreenDisplay: (bool) aDisplayOn
{
    NSString *command;
    if ( aDisplayOn ) 	
		command = @"DISPLAY ON";
    else 		
		command = @"DISPLAY OFF";
	
    [ self writeToGPIBDevice: command ];
}

#pragma mark ***Hardware - Channel
//--------------------------------------------------------------------------------
/*!\method  oscGetChnlAcquire
 * \brief	Checks if channel has been turned on.
 * \param	aChnl				- The channel to check - 0 based.
 * \error	Raises error if command fails.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscGetChnlAcquire: (short) aChnl
{
	NSString*   acquireOn;
    
	// Make sure that channel is valid
	if ( [ self checkChnlNum: aChnl ] )
	{
		[ self writeReadGPIBDevice: [ NSString stringWithFormat: @"C%d:TRACE?", aChnl + 1 ]
                                             data: mReturnData maxLength: kMaxGPIBReturn ];
        
		acquireOn = [ NSString stringWithCString: mReturnData  encoding:NSASCIIStringEncoding];
		if ( [ acquireOn rangeOfString: @"ON" 
							   options: NSBackwardsSearch ].location != NSNotFound )
        {
            [ self setChnlAcquire: aChnl setting: true ];
        }
        else
        {
            [ self setChnlAcquire: aChnl setting: false ];
        }
    }
}

//--------------------------------------------------------------------------------
/*!\method  oscSetChnlAcquire
 * \brief	Turns on or off a particular channel
 * \param	aChnl				- The channel to check - 0 based.
 * \error	Raises error if command fails.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscSetChnlAcquire
{
    int i;
    for ( i = 0; i < kMaxOscChnls; i++ ) // Select channels on display
	{ 
        if ( [ self checkChnlNum: i ] )
		{
            if ( [ self chnlAcquire: i ] )
			{
				[ self writeToGPIBDevice: [ NSString stringWithFormat: @"C%d:TRACE ON", i + 1 ]];
            }
            else {
                [ self writeToGPIBDevice: [ NSString stringWithFormat: @"C%d:TRACE OFF", i + 1 ]];
            }
        }
    }
}


//--------------------------------------------------------------------------------
/*!\method  oscGetChnlCoupling
 * \brief	Asks LeCroy for channel input coupling.
 * \param	aChnl				- The channel to check - 0 based.
 * \error	Raises error if command fails.
 * \note	1) Options
 *				A1M - AC coupled - 1 Mega Ohm impedance.
 *				D1M - DC coupled - 1 Mega Ohm impedance.
 *				D50 - DC coupled - 50 Ohm impedance.
 *				GND - No coupling.
 */
//--------------------------------------------------------------------------------
- (void) oscGetChnlCoupling: (short) aChnl
{
	//    NSString*	impedanceValue;
    NSString*	couplingValue;
	int32_t		returnLength;
	
	if ( [ self checkChnlNum: aChnl ] ){
		
		// Get the channel coupling option.
		returnLength = [ self writeReadGPIBDevice: [ NSString stringWithFormat: @"C%d:COUPLING?", aChnl + 1 ]
                                             data: mReturnData
                                        maxLength: kMaxGPIBReturn ];
		// Set the correct coupling constant.
        if ( returnLength > 0 )
		{
			couplingValue = [ NSString stringWithCString: mReturnData  encoding:NSASCIIStringEncoding];
			
			if ( [ couplingValue rangeOfString: @"A1M" ].location != NSNotFound )
				[ self setChnlCoupling: aChnl coupling: kChnlCouplingACIndex ];
			
			if ( [ couplingValue rangeOfString: @"D1M" ].location != NSNotFound )
				[ self setChnlCoupling: aChnl coupling: kChnlCouplingDCIndex ];
			
			if ( [ couplingValue rangeOfString: @"D50" ].location != NSNotFound )
				[ self setChnlCoupling: aChnl coupling: kChnlCouplingDC50Index ];
			
			if ( [ couplingValue rangeOfString: @"GND" ].location != NSNotFound )
				[ self setChnlCoupling: aChnl coupling: kChnlCouplingGNDIndex ];
		}
	}
}

//--------------------------------------------------------------------------------
/*!\method  oscSetChnlCoupling
 * \brief	Sets the coupling used by the channel.
 * \param	aChnl				- The channel to check - 0 based.
 * \error	Raises error if command fails.
 * \note	1) See oscGetChnlCoupling for options.
 */
//--------------------------------------------------------------------------------
- (void) oscSetChnlCoupling: (short) aChnl
{
    NSString*	command = nil;
	
    if ( [ self checkChnlNum: aChnl ] ){
        
        // Select the option
        switch ( [ self chnlCoupling: aChnl ] ){
            case kChnlCouplingACIndex:
                command = [ NSString stringWithFormat: @"C%d:COUPLING A1M", aChnl + 1 ];
				break;
				
            case kChnlCouplingDCIndex:
                command = [ NSString stringWithFormat: @"C%d:COUPLING D1M", aChnl + 1 ];
				break;
				
            case kChnlCouplingGNDIndex:
                command = [ NSString stringWithFormat: @"C%d:COUPLING GND", aChnl + 1 ];
				break;
				
            case kChnlCouplingDC50Index:
                command = [ NSString stringWithFormat: @"C%d:COUPLING D50", aChnl + 1 ];
				break;
        }
        
        // Write out the command
        [ self writeToGPIBDevice: command ];
    }
}

//--------------------------------------------------------------------------------
/*!\method  oscGetChnlPos
 * \brief	Get the offset of the channel in volts.
 * \param	aChnl				- The channel to check - 0 based.
 * \error	Raises error if command fails.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscGetChnlPos: (short) aChnl
{
    int32_t	returnLength;
    
	if ( [ self checkChnlNum: aChnl ] )
	{
		returnLength = [ self writeReadGPIBDevice: [ NSString stringWithFormat: @"C%d:OFFSET?", aChnl + 1 ]
                                             data: mReturnData
                                        maxLength: kMaxGPIBReturn ];
		if ( returnLength > 0 )
		{
			[ self setChnlPos: aChnl position: [ self convertStringToFloat: mReturnData withLength: returnLength ]];
		}
	}
}

//--------------------------------------------------------------------------------
/*!\method  oscSetChnlPos
 * \brief	This routine sets the vertical position of the specified trace.
 * \param	aChnl				- The channel to check - 0 based.
 * \error	Raises error if command fails.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscSetChnlPos: (short) aChnl
{
	if ( [ self checkChnlNum: aChnl ] )
	{
		[ self writeToGPIBDevice: [ NSString stringWithFormat: @"C%d:OFFSET %e", aChnl + 1, [ self chnlPos: aChnl ]]];	
    }
}

//--------------------------------------------------------------------------------
/*!\method  oscGetChnlScale
 * \brief	Get the vertical scale for the specified channel.  Volts / division.
 * \param	aChnl				- The channel to check - 0 based.
 * \error	Raises error if command fails.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscGetChnlScale: (short) aChnl
{
    int32_t	returnLength = 0;
    
	if ( [ self checkChnlNum: aChnl ] )
	{
		returnLength = [ self writeReadGPIBDevice: [ NSString stringWithFormat: @"C%d:VOLT_DIV?", aChnl + 1 ]
                                             data: mReturnData
                                        maxLength: kMaxGPIBReturn ];
		if ( returnLength > 0 )
			[ self setChnlScale: aChnl scale: [ self convertStringToFloat: mReturnData withLength: returnLength ]];
	}
}

//--------------------------------------------------------------------------------
/*!\method  oscSetChnlScale
 * \brief	This routine gets the vertical scale.  Units are volts / division.
 * \param	aChnl				- The channel to check - 0 based.
 * \error	Raises error if command fails.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscSetChnlScale: (short) aChnl
{
	if ( [ self checkChnlNum: aChnl ] )
	{
		[ self writeToGPIBDevice: [ NSString stringWithFormat: @"C%d:VOLT_DIV %e", aChnl + 1, [ self chnlScale: aChnl ]]];	
    }
}

#pragma mark ***Hardware - Horizontal settings
//-----------------------------------------------------------------------------
/*!\method	oscGetHorizontalPos
 * \brief	Get the horizontal position from the oscilloscope.
 * \error	Raises error if command fails.
 */
//-----------------------------------------------------------------------------
- (void) oscGetHorizontalPos
{
	int32_t	returnLength;
	
    returnLength = [ self writeReadGPIBDevice: @"TRIG_DELAY?" 
                                         data: mReturnData
                                    maxLength: kMaxGPIBReturn ];
    if ( returnLength > 0 )
        [ self setHorizontalPos: [ self convertStringToFloat: mReturnData withLength: returnLength ] ];
}

//-----------------------------------------------------------------------------
/*!\method	oscSetHorizontalPos
 * \brief	Set the horizontal position for the oscilloscope
 * \error	Raises error if command fails.
 */
//-----------------------------------------------------------------------------
- (void) oscSetHorizontalPos
{
    [ self writeToGPIBDevice: [ NSString stringWithFormat: @"TRIG_DELAY %e", [ self horizontalPos ]]];
}

//-----------------------------------------------------------------------------
/*!\method	oscGetHorizontalScale
 * \brief	Get the horizontal scale from the oscilloscope.  Returned number
 *			is always in seconds and represents seconds / division.
 * \error	Raises error if command fails.
 */
//-----------------------------------------------------------------------------
- (void) oscGetHorizontalScale
{
	int32_t	returnLength;
	
    returnLength = [ self writeReadGPIBDevice: @"TIME_DIV?" 
                                         data: mReturnData
                                    maxLength: kMaxGPIBReturn ];
    if ( returnLength > 0 )
        [ self setHorizontalScale: [ self convertStringToFloat: mReturnData withLength: returnLength ]]; 
}

//-----------------------------------------------------------------------------
/*!\method	oscSetHorizontalScale
 * \brief	Set the horizontal scale for the sweep of the oscilloscope.  Note
 *			that we first have to convert value from internally stored units
 *			to seconds.
 * \error	Raises error if command fails.
 */
//-----------------------------------------------------------------------------
- (void) oscSetHorizontalScale
{
    [ self writeToGPIBDevice: [ NSString stringWithFormat: @"TIME_DIV %e", [ self horizontalScale ]]];
}


//-----------------------------------------------------------------------------
/*!\method	oscGetWaveformRecordLength
 * \brief	Gets the record length of the waveform from the oscilloscope.  
 * \error	Raises error if command fails.
 * \note	1) Format of return from WAVEFORM_SETUP command is:
 *				SP,<sp>,NP,<np>,FP,<fp>,SN,<sn>
 *			   where
 *				SP - Sparsing parameter - each ith wave point is returned.
 *				NP - Number of wavepointers to return.
 *				FP - First data point returned. 0 is first data point in waveform.
 *				SN - Segment to return.
 */
//-----------------------------------------------------------------------------
- (void) oscGetWaveformRecordLength
{
	NSString*   waveformParams;
	NSString*   recordLengthStr;
    int32_t		returnLength;
	
    returnLength = [ self writeReadGPIBDevice: @"WAVEFORM_SETUP?"
                                         data: mReturnData
                                    maxLength: kMaxGPIBReturn ];
	
	// Have to parse the return
    if ( returnLength > 0 )
	{
		waveformParams = [ NSString stringWithCString: &mReturnData[ 0 ]  encoding:NSASCIIStringEncoding];
		NSArray* waveformValues = [ waveformParams componentsSeparatedByString: @"," ];
		
		recordLengthStr = [ waveformValues objectAtIndex: 3 ];		
		strcpy( &mReturnData[ 0 ], [ recordLengthStr cStringUsingEncoding:NSASCIIStringEncoding ] );
		
		[ self setWaveformLength: [ self convertStringToLong: mReturnData withLength: returnLength ]];;
	}
}


//--------------------------------------------------------------------------------
/*!\method  oscSetWaveformRecordLength
 * \brief	Sets the record length used to acquire the data.
 * \error	Raises error if command fails.
 * \note	The oscilloscope always acquires ORLCMaxRecSize internally.  If we acquire
 *			less then to acquire full display we have to acquire only a subset of
 *			the data points - the sparsing factor.  
 */
//--------------------------------------------------------------------------------
- (void) oscSetWaveformRecordLength
{
	//	float captureInt;
	//	float memoryUsed;
	int32_t waveformLength;
	waveformLength = [ self waveformLength ];
	//	captureInt = 10 * [ self horizontalScale ];
	//	memoryUsed = captureInt / 1.25e-10 + 0.5;
	//	printf( "Rec size 1 %f\n", memoryUsed );
	//	if ( memoryUsed > ORLCMaxRecSize ) memoryUsed = ORLCMaxRecSize;
	//	printf( "Rec size 2 %f\n", memoryUsed );
	//	int32_t sparsing = memoryUsed / [ self waveformLength ];
	int32_t sparsing = 1;
	
	
	NSLog(@"Record length: %d Sparsing factor: %d  scale factor: %e\n", waveformLength, sparsing, [ self horizontalScale ] );
	[ self writeToGPIBDevice: [ NSString stringWithFormat: @"WAVEFORM_SETUP NP,%d,SP,%d", waveformLength, sparsing ]];
	//if ( waveformLength == 15000 ) waveformLength = 25000;	
	[ self writeToGPIBDevice: [ NSString stringWithFormat: @"MEMORY_SIZE %d", waveformLength ] ];
}

#pragma mark ***Hardware - Trigger
//-----------------------------------------------------------------------------
/*!\method	oscGetTriggerCoupling
 * \brief	Get the trigger coupling from the oscilloscope.   Converts oscilloscope
 *			value to index.
 * \error	Raises error if command fails.
 */
//-----------------------------------------------------------------------------
- (void)	oscGetTriggerCoupling
{
    NSString*	couplingValue;
	int32_t		returnLength = 0;
	
	// Get coupling value.
	returnLength = [ self writeReadGPIBDevice: @"TRIG_COUPLING?"
                                         data: mReturnData
                                    maxLength: kMaxGPIBReturn ];
	
	// Convert coupling value to index
	if ( returnLength > 0 )
	{
        couplingValue = [ NSString stringWithCString: mReturnData  encoding:NSASCIIStringEncoding];
        
        if ( [ couplingValue rangeOfString: @"AC"
                                   options: NSBackwardsSearch ].location != NSNotFound  )
        {
			[ self setTriggerCoupling: kTriggerAC ];
        }
		else if ( [ couplingValue rangeOfString: @"DC"
										options: NSBackwardsSearch ].location != NSNotFound )
		{
			[ self setTriggerCoupling: kTriggerDC ];
		}
		else if ( [ couplingValue rangeOfString: @"HFREJ"
                                        options: NSBackwardsSearch ].location != NSNotFound )
		{
			[ self setTriggerCoupling: kTriggerHFRej ];
		}
		else if ( [ couplingValue rangeOfString: @"LFREJ"
                                        options: NSBackwardsSearch ].location != NSNotFound )
		{
			[ self setTriggerCoupling: kTriggerLFRej ];
		}
    }
}

//-----------------------------------------------------------------------------
/*!\method	oscSetTriggerCoupling
 * \brief	Set the trigger coupling for the oscilloscope using model parameter. 
 * \error	Raises error if command fails.
 * \note	1) Most oscilloscopes set the coupling for all channels at once.
 *				The LeCroy sets the coupling for only the specified source.
 *				Thus this command must use the specified source as part
 *				of the coupling command.
 */
//-----------------------------------------------------------------------------
- (void) oscSetTriggerCoupling
{
	// Determine the trigger source.
	NSString* source = [ self triggerSourceAsString ];
	
	// Now set the coupling for the trigger source channel.
	switch ( [ self triggerCoupling ] )
	{
		case kTriggerAC:
			[ self writeToGPIBDevice: [ NSString stringWithFormat: @"%s:TRIG_COUPLING AC", [ source cStringUsingEncoding:NSASCIIStringEncoding ]]];
			break;
			
		case kTriggerDC:
			[ self writeToGPIBDevice: [ NSString stringWithFormat: @"%s:TRIG_COUPLING DC", [ source cStringUsingEncoding:NSASCIIStringEncoding ]]];
			break;
			
		case kTriggerHFRej:
			[ self writeToGPIBDevice: [ NSString stringWithFormat: @"%s:TRIG_COUPLING HFREJ", [ source cStringUsingEncoding:NSASCIIStringEncoding ]]];
			break;
			
		case kTriggerLFRej:
			[ self writeToGPIBDevice: [ NSString stringWithFormat: @"%s:TRIG_COUPLING LFREJ", [ source cStringUsingEncoding:NSASCIIStringEncoding ]]];
			break;
			
		default:
			[ self writeToGPIBDevice: [ NSString stringWithFormat: @"%s:TRIG_COUPLING AC", [ source cStringUsingEncoding:NSASCIIStringEncoding ]]];
			break;	
	}
	
	//	[ source release ];
}

//-----------------------------------------------------------------------------
/*!\method	oscGetTriggerLevel
 * \brief	Get the trigger level from the oscilloscope.   
 * \error	Raises error if command fails.
 */
//-----------------------------------------------------------------------------
- (void)	oscGetTriggerLevel
{
	int32_t	returnLength = 0;
	
	// Determine the trigger source.
	NSString* source = [ self triggerSourceAsString ];
	
	// Get trigger level.
	returnLength = [ self writeReadGPIBDevice: [ NSString stringWithFormat: @"%s:TRIG_LEVEL?", [ source cStringUsingEncoding:NSASCIIStringEncoding ]]
                                         data: mReturnData
                                    maxLength: kMaxGPIBReturn ];
	
	// Save the trigger level.
	if ( returnLength > 0 )
	{
		[ self setTriggerLevel: [ self convertStringToFloat: mReturnData withLength: returnLength ]];		
	}
}

//-----------------------------------------------------------------------------
/*!\method	oscSetTriggerLevel
 * \brief	Set the trigger level for the oscilloscope using model parameter. 
 * \error	Raises error if command fails.
 */
//-----------------------------------------------------------------------------
- (void)	oscSetTriggerLevel
{
	// Determine the trigger source.
	NSString* source = [ self triggerSourceAsString ];
	
	// Set the trigger level.
	[ self writeToGPIBDevice: [ NSString stringWithFormat: @"%s:TRIG_LEVEL %e", 
							   [ source cStringUsingEncoding:NSASCIIStringEncoding ],
							   [ self triggerLevel ]]];	
}

//-----------------------------------------------------------------------------
/*!\method	oscGetTriggerMode
 * \brief	Get the trigger mode from the oscilloscope.  Converts oscilloscope
 *			value to index.   
 * \error	Raises error if command fails.
 */
//-----------------------------------------------------------------------------
- (void)	oscGetTriggerMode
{
    NSString*	triggerMode;
	int32_t		returnLength = 0;
	
	// Get trigger mode.
	returnLength = [ self writeReadGPIBDevice: @"TRIG_MODE?"
                                         data: mReturnData
                                    maxLength: kMaxGPIBReturn ];
	
	// Convert trigger mode to index
	if ( returnLength > 0 )
	{
        triggerMode = [ NSString stringWithCString: mReturnData  encoding:NSASCIIStringEncoding];
        
        if ( [ triggerMode rangeOfString: @"AUTO" 
								 options: NSBackwardsSearch ].location != NSNotFound  )
		{
			[ self setTriggerMode: kTriggerAuto ];
		} 
        else if ( [ triggerMode rangeOfString: @"NORM"
                                      options: NSBackwardsSearch ].location != NSNotFound )
        {
            [ self setTriggerMode: kTriggerNormal ];
        }
		else if ( [ triggerMode rangeOfString: @"SINGLE"
								      options: NSBackwardsSearch ].location != NSNotFound )
		{
			[ self setTriggerMode: kTriggerSingle ];
		}
		else if ( [ triggerMode rangeOfString: @"STOP"
								      options: NSBackwardsSearch ].location != NSNotFound )
		{
			[ self setTriggerMode: kTriggerStop ];
		}
        else
        {
            [ self setTriggerMode: kTriggerNormal ];
        }
	}
}

//-----------------------------------------------------------------------------
/*!\method	oscSetTriggerMode
 * \brief	Set the trigger Mode for the oscilloscope using model parameter. 
 * \error	Raises error if command fails.
 */
//-----------------------------------------------------------------------------
- (void) oscSetTriggerMode
{
    switch ( [ self triggerMode ] ){
			
        case kTriggerAuto:
            [ self writeToGPIBDevice: @"TRIG_MODE AUTO" ];
			break;
		case kTriggerNormal:
			[ self writeToGPIBDevice: @"TRIG_MODE NORM" ];
			break;
		case kTriggerSingle:
			[ self writeToGPIBDevice: @"TRIG_MODE SINGLE" ];
			break;
		case kTriggerStop:
			[ self writeToGPIBDevice: @"TRIG_MODE STOP" ];
			break;
		default:
			[ self writeToGPIBDevice: @"TRIG_MODE NORM" ];
    }
}

//-----------------------------------------------------------------------------
/*!\method	oscGetTriggerPos
 * \brief	Get the trigger position from the oscilloscope.  This value
 *			is a number from 0 to 100%. 
 * \error	Raises error if command fails.
 */
//-----------------------------------------------------------------------------
- (void) oscGetTriggerPos
{
    int32_t		returnLength = 0;
    
	// Get value
	//    returnLength = [ self writeReadGPIBDevice: @"HORIZONTAL:TRIGGER:POSITION?"
	//                                         data: mReturnData
	//                                    maxLength: kMaxGPIBReturn ];
	mReturnData[ 0 ] = '5';
	mReturnData[ 0 ] = '0';
	mReturnData[ 0 ] = '\0';
	returnLength = 3;
	
	// Save the trigger position.
	if ( returnLength > 0 )
	{
		[ self setTriggerPos: [ self convertStringToFloat: mReturnData withLength: returnLength ]];	
	}
}

//-----------------------------------------------------------------------------
/*!\method	oscSetTriggerPos
 * \brief	Set the trigger position as a value between 0 and 100%.   
 * \error	Raises error if command fails.
 */
//-----------------------------------------------------------------------------
- (void) oscSetTriggerPos
{
	//    [ self writeToGPIBDevice:  [ NSString stringWithFormat: @"HORIZONTAL:TRIGGER:POSITION %e", [ self triggerPos ]]];
}


//-----------------------------------------------------------------------------
/*!\method	oscGetTriggerSlopeIsPos
 * \brief	Get the trigger slope from the oscilloscope.  Converts oscilloscope
 *			value to bool which is true for positive slope.   
 * \error	Raises error if command fails.
 */
//-----------------------------------------------------------------------------
- (void) oscGetTriggerSlopeIsPos
{
    NSString*	slope;
    int32_t		returnLength = 0;
	
	// Get trigger source    
	NSString* source = [ self triggerSourceAsString ];
	
	// Get trigger slope.
	returnLength = [ self writeReadGPIBDevice: [ NSString stringWithFormat: @"%s:TRIG_SLOPE?", [ source cStringUsingEncoding:NSASCIIStringEncoding ]]
                                         data: mReturnData
                                    maxLength: kMaxGPIBReturn ];
	
	if ( returnLength > 0 )
	{
        slope = [ NSString stringWithCString: mReturnData encoding:NSASCIIStringEncoding ];
        
        if ( [ slope rangeOfString: @"NEG"
						   options: NSBackwardsSearch ].location != NSNotFound  )
		{
			[ self setTriggerSlopeIsPos: false ];
		}
        else if ( [ slope rangeOfString: @"POS"
								options: NSBackwardsSearch ].location != NSNotFound  )
        {
            [ self setTriggerSlopeIsPos: true ];
        }
    }
}

//-----------------------------------------------------------------------------
/*!\method	oscSetTriggerSlopeIsPos
 * \brief	Set the trigger slope for the oscilloscope using model parameter. 
 * \error	Raises error if command fails.
 */
//-----------------------------------------------------------------------------
- (void)	oscSetTriggerSlopeIsPos
{    
	// Determine the trigger source.
	NSString* source = [ self triggerSourceAsString ];
	
	// Set the trigger polarity
    if ( [ self triggerSlopeIsPos ] ){
        [ self writeToGPIBDevice: [ NSString stringWithFormat: @"%s:TRIG_SLOPE POS", [ source cStringUsingEncoding:NSASCIIStringEncoding ]]];
    }
    else{
        [ self writeToGPIBDevice: [ NSString stringWithFormat: @"%s:TRIG_SLOPE NEG", [ source cStringUsingEncoding:NSASCIIStringEncoding ]]];
    }
}

//-----------------------------------------------------------------------------
/*!\method	oscGetTriggerSource
 * \brief	Get the trigger source from the oscilloscope.  Converts oscilloscope
 *			value to index.
 * \error	Raises error if command fails.
 */
//-----------------------------------------------------------------------------
- (void)	oscGetTriggerSource
{
    NSString*	triggerSource;
	int32_t		returnLength = 0;
	
	// Get trigger source.
	returnLength = [ self writeReadGPIBDevice: @"TRIG_SELECT?"
                                         data: mReturnData
                                    maxLength: kMaxGPIBReturn ];
	
	// Convert response from oscilloscope to index.
	if ( returnLength > 0 )
	{
        triggerSource = [ NSString stringWithCString: mReturnData  encoding:NSASCIIStringEncoding];
        
        if ( [ triggerSource rangeOfString: @"SR,EX"
                                   options: NSBackwardsSearch ].location != NSNotFound  )
		{
            [ self setTriggerSource: kTriggerAuxilary ];
        }
		else if ( [ triggerSource rangeOfString: @"SR,LINE"
										options: NSBackwardsSearch ].location != NSNotFound  )
        {
            [ self setTriggerSource: kTriggerLine ];
        }
        else if ( [ triggerSource rangeOfString: @"SR,C1"
										options: NSBackwardsSearch ].location != NSNotFound  )
        {
            [ self setTriggerSource: kTriggerCH1 ];
        }
        else if ( [ triggerSource rangeOfString: @"SR,C2"
										options: NSBackwardsSearch ].location != NSNotFound  )
        {
            [ self setTriggerSource: kTriggerCH2 ];
        }
        else if ( [ triggerSource rangeOfString: @"SR,C3"
										options: NSBackwardsSearch ].location != NSNotFound  )
        {
            [ self setTriggerSource: kTriggerCH3 ];
        }
        else if ( [ triggerSource rangeOfString: @"SR,C4"
										options: NSBackwardsSearch ].location != NSNotFound  )
        {
            [ self setTriggerSource: kTriggerCH4 ];
        }
	}
}

//-----------------------------------------------------------------------------
/*!\method	oscSetTriggerSource
 * \brief	Set the trigger source for the oscilloscope using model parameter. 
 * \error	Raises error if command fails.
 * \note	1) LeCroy sets trigger settings for each individual trigger source
 *				we have to make sure that when the source changes all its settings
 *				are set to that of the previous source.  This program does not
 *				provide individual trigger source parameters.
 */
//-----------------------------------------------------------------------------
- (void)	oscSetTriggerSource
{
	switch ( [ self triggerSource ] ){
		case kTriggerAuxilary:
			[ self writeToGPIBDevice: @"TRIG_SELECT EDGE,SR,EX"];
			break;
			
		case kTriggerLine:
			[ self writeToGPIBDevice: @"TRIG_SELECT EDGE,SR,LINE"];
			break;
			
		case kTriggerCH1:
			[ self writeToGPIBDevice: @"TRIG_SELECT EDGE,SR,C1"];
			break;
			
		case kTriggerCH2:
			[ self writeToGPIBDevice: @"TRIG_SELECT EDGE,SR,C2"];
			break;
			
		case kTriggerCH3:
			[ self writeToGPIBDevice: @"TRIG_SELECT EDGE,SR,C3"];
			break;
			
		case kTriggerCH4:
			[ self writeToGPIBDevice: @"TRIG_SELECT EDGE,SR,C4"];
			break;
			
		default:
			[ self writeToGPIBDevice: @"TRIG_SELECT EDGE,SR,C1"];
			break;	
			
	}
    // Since trigger source is reset make sure it has the correct parameters.
    [ self oscSetTriggerCoupling ];
    [ self oscSetTriggerSlopeIsPos ];
    [ self oscSetTriggerLevel ];

}

#pragma mark ***Hardware - Get and Set specific settings.
//--------------------------------------------------------------------------------
/*!\method  oscGetOscSpecificSettings
 * \brief	Get any oscilloscope specific settings.
 * \error	Raises error if command fails.
 * \note	1) Called by oscGetStandardSettings in base class.
 */
//--------------------------------------------------------------------------------
- (void) oscGetOscSpecificSettings
{
}

//--------------------------------------------------------------------------------
/*!\method  oscSetOscSpecificSettings
 * \brief	Set any oscilloscope specific settings.
 * \error	Raises error if command fails.
 * \note	1) Called by oscSetStandardSettings in base class.
 */
//--------------------------------------------------------------------------------
- (void) oscSetOscSpecificSettings
{
}


#pragma mark ***Hardware - Data Acquisition
//--------------------------------------------------------------------------------
/*!\method  oscArmScope
 * \brief	Arm the oscilloscope so that it can handle the next waveform.
 * \error	Raises error if command fails.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscArmScope
{
    [ self writeToGPIBDevice: @"ARM" ];
}

//--------------------------------------------------------------------------------
/*!\method  oscGetHeader
 * \brief	This routine gets the header data associated with the waveform from the oscilloscope.
 * \param	aDataObj			- Object holding data for scope.
 * \error	Raises error if command fails.
 * \note    See the object T754OscData.h which gives a complete breakdown of what is in the data header for a waveform.
 * \note   	This routine then calls the oscGetWaveform method to return the waveform.
 */
//--------------------------------------------------------------------------------
- (void) oscGetHeader
{
	static L950IDefHeaderStruct	headerInfo;
	char						*theHeader;
	//	size_t						theLength;
	int32_t						numBytes;
	short						i;
	
    @try {
        if( [ self isConnected ] )
        {
            for ( i = 0; i < kMaxOscChnls; i++)
            {
                if ( mChannels[ i ].chnlAcquire )
                {
                    theHeader = [ mDataObj[ i ] rawHeader ];
					
                    // Send command to retrieve header information.
                    [ self writeToGPIBDevice:
					 [ NSString stringWithFormat: @"C%d:WAVEFORM? DESC", i + 1 ]];
					
                    // Read header information
					[ mController readFromDevice: mPrimaryAddress data: (char*)&headerInfo maxLength: sizeof( headerInfo ) ];
					numBytes = atoi( headerInfo.mDataLength );							// length of pulse in chnls	
					//					 printf( "Header length: %d\n", numBytes );
					
                    memset( theHeader, 0, sizeof( struct L950Header ) );
                    [ self readFromGPIBDevice: theHeader maxLength: sizeof( struct L950Header ) ];
					
					//					printf( "Header: %s\n", theHeader );
					//					printf( "Channels: %d vGain %e\n", ((struct L950Header*)theHeader)->mWaveArrayCount,
					//					        ((struct L950Header*)theHeader)->mVerticalGain );
                }
            }
        }
		
	}
	@catch(NSException* localException) {
    }
}


//--------------------------------------------------------------------------------
/*!\method  oscGetWaveform
 * \brief	This routine gets the actual data from the oscilloscope.
 * \error	Raises error if command fails.
 * \note	1) The Tektronix does not use a communication header that is read in
 *             as one item.  Instead it has 3 pieces, where the first describes
 *            the second and the second describes the third.  The structure
 *            of this header is as follows.
 * 
 *            #<x><yyy...><data><newline>
 *            x: number of bytes in y
 *            y: number of data in data.
 */
//--------------------------------------------------------------------------------
- (void) oscGetWaveform: (unsigned short) aMask
{
	char*							theData;			// Temporary pointer to data storage location.
	static struct L950IDefHeader	headerInfo;
	int								i;
	int32_t							numBytes;
	//	int32_t							j, l;
	
    @try {
        if( [ self isConnected ] )
		{
			
            // Read in all the data at once.
            for ( i = 0; i < kMaxOscChnls; i++ ) 
			{
                if ( mChannels[ i ].chnlAcquire && ( aMask & ( 1 << i ) ) ) 
				{
                    theData = [ mDataObj[ i ] createDataStorage ];
					
					// Issue command to read data for a single channel.
					[ mController writeToDevice: mPrimaryAddress command: [ NSString stringWithFormat: @"C%d:WAVEFORM? DAT1", i + 1 ]];
					
                    // Read header information
					[ mController readFromDevice: mPrimaryAddress data: (char*)&headerInfo maxLength: sizeof( headerInfo ) ];
					numBytes = atoi( headerInfo.mDataLength );							// length of pulse in chnls	
					NSLog(@"Waveform points: %d\n", numBytes );					
					
                    // read the actual data.
                    [ mDataObj[ i ] setActualWaveformSize: ( numBytes >= [ mDataObj[ i ] maxWaveformSize ] ) ? 
					 [ mDataObj[ i ] maxWaveformSize ] : numBytes ];  // Read in the smaller size
					
                    [ mDataObj[ i ] setActualWaveformSize: [ mController readFromDevice: mPrimaryAddress 
                                                                                   data: theData 
                                                                              maxLength: [ mDataObj[ i ] actualWaveformSize ] ] ];
					
					
					//					for ( j = 0; j < numBytes; j += 10 )
					//					{
					//						printf( "\nWave: %d -", j );
					//						for ( l = 0; l < 10; l++ )
					//							printf( " %d", theData[ j + l ] );
					//					}
				}
            }
        }
        
		// Bad connection so don't execute instruction
        else
        {
            NSString *errorMsg = @"Must establish GPIB connection prior to issuing command\n";
            [ NSException raise: OExceptionGPIBConnectionError format: @"%@",errorMsg ];
        }
        
	}
	@catch(NSException* localException) {
    }
	
}

//--------------------------------------------------------------------------------
/*!\method  oscGetWaveformTime
 * \brief	This routine gets the time associated with the waveform.
 * \error	Raises error if command fails.
 */
//--------------------------------------------------------------------------------
- (void) oscGetWaveformTime: (unsigned short) aMask
{
    uint64_t	timeInSecs;
	char				*theTimeData;				// Temporary pointer to data storage location.
	char				timeRaw[ 64 ];
	bool				fNoTime = true;
    
	// Initialize memory.
	//    memset( &theTimeStr[ 0 ], '\0', 128 );
    
    theTimeData = [ mDataObj[ 0 ] createTimeStorage ];
	
	// Get time from oscilloscope for last waveform.
    if ( mID == ORLC950 )
    {
		unsigned short i = 0;
		while( fNoTime )
		{
			if ( mChannels[ i ].chnlAcquire && ( aMask & (1<<i) ) ) 
			{
				[ mController writeReadDevice: mPrimaryAddress 
                                      command: [ NSString stringWithFormat: @"C%d:INSPECT? 'TRIGGER_TIME'", i + 1 ]
                                         data: timeRaw
									maxLength: sizeof( timeRaw ) ];
				
				fNoTime = false; 
			}
			i++;
		}
    }
	
	// Convert the time
    [ self osc950ConvertTime: &timeInSecs timeToConvert: &timeRaw[ 0 ] ];
    memcpy( theTimeData, &timeInSecs, 2*sizeof(int32_t) );
}


//--------------------------------------------------------------------------------
/*!\method  oscRunOsc
 * \brief	Starts the oscilloscope up.
 * \param	aStartMsg			- A starting message to write out to the screen.
 * \error	Throws error if any command fails.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscRunOsc: (NSString*) aStartMsg
{
	//    NSRange		range = { NSNotFound, 0 };
    
	// Get scope ready.
    [ self clearStatusReg ];
    [ self oscScopeId ];
    
	// Acquire data.  Places scope in single waveform acquisition mode.
	if ( mRunInProgress ){
		// time_t	theTime;
		//  struct tm	*theTimeGMTAsStruct;
		//  time( &theTime );
		//  theTimeGMTAsStruct = gmtime( &theTime );
		// [ self oscSetDateTime: mktime( theTimeGMTAsStruct ) ];
	    [ self oscInitializeForDataTaking: aStartMsg ];
	    [ self oscArmScope ];
	}
	
	// Place oscilloscope in free running mode.
	else{
	    [ self oscSetAcqMode: kNormalTrigger ];
		//	    [ self writeToGPIBDevice: @"ACQUIRE:STATE RUN"];
	    [ self oscLockPanel: false ];
	}
}


//--------------------------------------------------------------------------------
/*!\method  oscSetAcqMode
 * \brief	Sets the acquisition mode for the oscilloscope. Either free running
 *			or one event at a time.
 * \param	aMode		- Either kNormalTrigger or kSingleWaveform.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscSetAcqMode: (short) aMode
{
    
	switch( aMode )
	{
		case kNormalTrigger:
			[ self setTriggerMode: kTriggerNormal ];
			//			command = @"TRIG_MODE NORM";
			break;
		case kSingleWaveform:
			[ self setTriggerMode: kTriggerSingle ];
			//			command = @"TRIG_MODE SINGLE";
			break;
	 	default:
			[ self setTriggerMode: kTriggerNormal ];
			//			command = @"TRIG_MODE NORM";
	}
	
	[ self oscSetTriggerMode ];
	//	[ self writeToGPIBDevice: command ];
}

//--------------------------------------------------------------------------------
/*!\method  oscSetDataReturnMode
 * \brief	Sets the parameters for how the data is retrieved from the oscilloscope
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscSetDataReturnMode
{
    [ self writeToGPIBDevice: @"COMM_FORMAT DEF9,BYTE,BIN" ]; // DEF9 - include 9 byte record stating size of following data.
	// Byte data
	// Binary encoding.
    [ self writeToGPIBDevice: [ NSString stringWithFormat: @"WAVEFORM_SETUP NP,%d", mWaveformLength ]];  // Waveform size
    [ self oscSetAcqMode: kSingleWaveform ];  // Set to single waveform acquisition.
}

//--------------------------------------------------------------------------------
/*!\method  oscStopAcquisition
 * \brief	Stops the oscilloscope from taking data.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscStopAcquisition
{
    [ self writeToGPIBDevice: @"STOP"];
    NSLog( @"LC950: Data acquisition stopped.\n" );
}



#pragma mark ***DataTaker

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORLC950DecoderForScopeData",             @"decoder",
								 [NSNumber numberWithLong:dataId],           @"dataId",
								 [NSNumber numberWithBool:YES],              @"variable",
								 [NSNumber numberWithLong:-1],               @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"ScopeData"];
	
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORLC950DecoderForScopeGTID",             @"decoder",
				   [NSNumber numberWithLong:gtidDataId],       @"dataId",
				   [NSNumber numberWithBool:NO],               @"variable",
				   [NSNumber numberWithLong:IsShortForm(gtidDataId)?1:2],   @"length",
				   nil];
    [dataDictionary setObject:aDictionary forKey:@"ScopeGTID"];
	
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORLC950DecoderForScopeTime",             @"decoder",
				   [NSNumber numberWithLong:clockDataId],      @"dataId",
				   [NSNumber numberWithBool:NO],               @"variable",
				   [NSNumber numberWithLong:3],   @"length",
				   nil];
    [dataDictionary setObject:aDictionary forKey:@"ScopeTime"];
	
    return dataDictionary;
}

//--------------------------------------------------------------------------------
/*!\method  runTaskStarted
 * \brief	Beginning of run.  Prepare this object to take data.  Write out hardware settings
 *			to data stream.
 * \param	aDataPacket				- Object where data is written.
 * \param   anUserInfo				- Data from other objects that are needed by oscilloscope.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) runTaskStarted: (ORDataPacket*) aDataPacket userInfo: (id) anUserInfo
{
    short		i;
    bool		bRetVal = false;
	
	// Call base class method that initializes _cancelled conditional lock.
    [ super runTaskStarted: aDataPacket userInfo: anUserInfo ];
    
	// Handle case where device is not connected.
    if( ![ self isConnected ] ){
	    [ NSException raise: @"Not Connected" format: @"You must connect to a GPIB Controller." ];
    }
    
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORLC950Model"]; 
	
	
	
	// Get the controller so that it is cached
    bRetVal = [ self cacheTheController ];
    if ( !bRetVal )
    {
        [ NSException raise: @"Not connected" format: @"Could not cache the controller." ];
    }
    
	// Initialize the scope correctly.
    firstEvent = YES;
    
	// Set up memory structures for data
    for ( i = 0; i < kMaxOscChnls; i++ )
    {
        mDataObj[ i ] = [[ ORLC950Data alloc ] initWithWaveformModel: self channel: i ];
    } 
    
	// Start the oscilloscope
    NSNumber* initValue = [ anUserInfo objectForKey: @"doinit" ];
    if ( initValue ) [ self setDoFullInit: [ initValue intValue ]];
    else [ self setDoFullInit: YES ];
	
	// Initialize the oscilloscope settings and start acquisition using a run configuration.
    mRunInProgress = true;
	[ self oscSetStandardSettings ];	
}

//--------------------------------------------------------------------------------
/*!\method  takeDataTask
 * \brief	Thread that is repeatedly called to actually acquire the data. 
 * \param	anUserInfo				- Dictionary holding information from
 *										outside this task that is needed by
 *										this task.
 * \note	first 32 bits data		- 5 bits data type - deviceIndex -> deviceType	
 *									  4 bits oscilloscope number
 *									  4 bits channel
 *									  3 bits spare
 *									 16 bits size of following waveform
 * \note	first 32 bits time		- 5 bits data type - deviceIndex -> deviceType
 *									  3 bits channel number
 *									 24 bits high portion of time.
 * \history	2003-11-12 (jmw)	- Fixed output record when multiple channels fire.
 *								  Only one GTID written at beginning of record.
 */
//--------------------------------------------------------------------------------
- (void) 	takeDataTask: (id) notUsed 
{
	ORDataPacket* aDataPacket = nil;
    do {
        
        mDataThreadRunning = YES;
        
		[_okToGo lockWhenCondition:YES];
		
		// -- Do some basic initialization prior to acquiring data ------------------
		// Threads are responsible to manage their own autorelease pools
		NSAutoreleasePool *thePool = [[ NSAutoreleasePool alloc ] init ];
		
		BOOL processedAnEvent = NO;
		BOOL readOutError      = NO;
		
		//extract the data packet to use.
		if(aDataPacket)[aDataPacket release];
		aDataPacket 	= [ threadParams objectForKey: @"ThreadData" ];
		
		// Set which channels to read based on the mask - If not available read all channels.
		unsigned char mask;
		NSNumber* theMask = [ threadParams objectForKey: @"ChannelMask" ];
		if ( theMask ) 
			mask  = [ theMask charValue ];
		else 
			mask = 0xff;
		
		// Get the GTID
		NSNumber* gtidNumber    = [ threadParams objectForKey: @"GTID" ];
		NSTimeInterval t0       = [ NSDate timeIntervalSinceReferenceDate ];
		NSString* errorLocation = @"?"; // Used to determine at what point code stops if it stops.
		
		// -- Basic loop that reads the data -----------------------------------
		while ( ![self cancelled])
		{   
			// If we are not in standalone mode then gtid will be set.
			// In that case break out of this loop in a reasonable amount of time.
			if( gtidNumber && ( [ NSDate timeIntervalSinceReferenceDate ] - t0 > 1.0 ) )
			{
				NSLogError( @"", @"Scope Error", [ NSString stringWithFormat: @"Thread timeout, no data for scope (%d)", 
												  [ self primaryAddress ]], nil );
				readOutError = YES;
				break;
			}
			
			// Start section that reads data.
			@try {
				short i;
				
				// Scope is not busy so read it out
				errorLocation = @"oscBusy";
				if ( ![ self oscBusy ] )
				{
					
					// Read the header only for the first event.  We assume that scope settings will not change.
					if ( firstEvent ) 
					{
						//set the channel mask temporarily to read the headers for all channels.
						//                    errorLocation = @"oscSetWaveformAcq";
						//                    [ self oscSetWaveformAcq: 0xff ];
						errorLocation = @"oscGetHeader";
						[ self oscGetHeader ];
						
						for ( i = 0; i<kMaxOscChnls; i++ ){
							if ( mChannels[ i ].chnlAcquire ) [ mDataObj[ i ] convertHeader ];
						}
					}
					
					// Get data
					errorLocation = @"oscGetWaveform";
					[ self oscGetWaveform: mask ];			// Get the actual waveform data.
					
					errorLocation = @"oscGetWaveformTime";
					[ self oscGetWaveformTime: mask ];		// Get the time.
					
					// Rearm the oscilloscope.
					// [self clearStatusReg];
					errorLocation = @"oscArmScope";
					[ self oscArmScope ];   
					
					// Place data in array where other parts of ORCA can grab it.
					for ( i = 0; i < kMaxOscChnls; i++ )
					{
						if ( mChannels[ i ].chnlAcquire && ( mask & ( 1 << i ) ))
						{
							[ mDataObj[ i ] setGtid: (uint32_t)(gtidNumber ? [ gtidNumber longValue ] : 0) ];
							
							//Note only mDataObj[ 0 ] has the timeData.
							NSData* theTimeData = [ mDataObj[ 0 ] timePacketData: aDataPacket channel: i ];
							
							//note that the gtid is shipped only with the first data set.
							[ mDataObj[ i ] setDataPacketData: aDataPacket timeData: theTimeData includeGTID: !processedAnEvent ];
							processedAnEvent = YES;                    
                            [self incEventCount:i];                   
						}
					}
				}
				
				// Oscilloscope was busy - Loop for a short while and then try again.
				else 
				{
					NSTimeInterval t1 = [ NSDate timeIntervalSinceReferenceDate ];
					while([ NSDate timeIntervalSinceReferenceDate ] - t1 < .1 );
				}
				
			}
			@catch(NSException* localException) {
				readOutError = YES;
			}
			
			// Indicate that we have processed our first event.
			if( processedAnEvent )
				firstEvent = NO;
			
			// If we have the data or encountered an error break out of while.
			if( processedAnEvent || readOutError )
				break;
		}
		
		// -- Handle any errors encountered during read -------------------------------
		if( readOutError )
		{
			NSLogError( @"", @"Scope Error", [ NSString stringWithFormat: @"Exception: %@ (%d)", 
											  errorLocation, [ self primaryAddress ] ], nil );
			
			//we must rearm the scope. Since there was an error we will try a rearm again just to be sure.
			int errorCount = 0;
			while( 1 )
			{
				@try {
					[ self clearStatusReg ];
					[ self oscArmScope ];
				}
				@catch(NSException* localException) {
					errorCount++;
				}
				
				if( errorCount == 0 ) 
					break;
				else if( errorCount > 2 ) {
					NSLogError( @"", @"Scope Error", [NSString stringWithFormat: @"Rearm failed (%d)", [ self primaryAddress ] ], nil );
					break;
				}
			}
		}
		
		if(aDataPacket)[aDataPacket release];
		aDataPacket = nil;
		
		[_okToGo unlockWithCondition:NO];
		[ thePool release ];
		
	} while(![self cancelled]);
    mDataThreadRunning = NO;
	
    // Exit this thread
    [ NSThread exit ];
}

//--------------------------------------------------------------------------------
/*!\method  runInProgress
 * \brief	Informs calling routine whether task is running.
 * \return	True - task is running.				
 * \note	
 */
//--------------------------------------------------------------------------------
- (BOOL) runInProgress
{
    return mDataThreadRunning && [_okToGo condition];
}



//--------------------------------------------------------------------------------
/*!\method  runTaskStopped
 * \brief	Resets the oscilloscope so that it is in continuous acquisition mode.
 * \param	aDataPacket			- Data from most recent event.
 * \param   anUserInfo			- Data from other objects that are needed by oscilloscope.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) runTaskStopped: (ORDataPacket*) aDataPacket userInfo: (id) anUserInfo
{
    short i;
    
	// Cancel the task.
    [ super runTaskStopped: aDataPacket userInfo: anUserInfo ];
	
	// Stop running and place oscilloscope in free running mode.
    mRunInProgress = false;
    [ self oscRunOsc: nil ];
    
    
	// Release memory structures used for data taking
    for ( i = 0; i < kMaxOscChnls; i++ )
    {
        [ mDataObj[ i ] release ];
        mDataObj[ i ] = nil;
    } 	
}

#pragma mark ¥¥¥Archival
//--------------------------------------------------------------------------------
/*!\method  initWithCoder  
 * \brief	Initialize object using archived settings.
 * \param	aDecoder			- Object used for getting archived internal parameters.
 * \note	
 */
//--------------------------------------------------------------------------------
- (id) initWithCoder: (NSCoder*) aDecoder
{
    self = [ super initWithCoder: aDecoder ];
	
    [[ self undoManager ] disableUndoRegistration ];
    
    [[ self undoManager ] enableUndoRegistration];
    return self;
}

//--------------------------------------------------------------------------------
/*!\method  encodeWithCoder  
 * \brief	Save the internal settings to the archive.  OscBase saves most
 *			of the settings.
 * \param	anEncoder			- Object used for encoding.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) encodeWithCoder: (NSCoder*) anEncoder
{
    [ super encodeWithCoder: anEncoder ];
}

#pragma mark ***Support
//-----------------------------------------------------------------------------
/*!\method	triggerSourceAsString
 * \brief	Based on internal setting returns the trigger source as string
 *			for GPIB command.
 * \return	The trigger source as string.  Since created in autorelease pool
 *			string will be deleted after event.
 */
//-----------------------------------------------------------------------------
- (NSString*) triggerSourceAsString
{
	NSString* source = nil;
	
	// Get the trigger source first.
	switch( [ self triggerSource ] )
	{
		case kTriggerAuxilary:
			source = [ NSString stringWithFormat: @"EX" ];
			break;
		case kTriggerCH1:
			source = [ NSString stringWithFormat: @"C1" ];
			break;
		case kTriggerCH2:
			source = [ NSString stringWithFormat: @"C2" ];
			break;
		case kTriggerCH3:
			source = [ NSString stringWithFormat: @"C3" ];
			break;
		case kTriggerCH4:
			source = [ NSString stringWithFormat: @"C4" ];
			break;		
	}
	return( source );
}

//--------------------------------------------------------------------------------
/*!\method  osc950ConvertTime  
 * \brief	Convert the LeCroy time to an equivalent 10MHz clock starting at
 *			1/1/1970.
 * \param	a10MHzTime			- int64_t that stores 10 MHz time.
 * \param	aCharTime			- Tektronix time.
 * \note	Time is returned as follows:
 *				"TRIGGER_TIME       : Date = MAY 27, 2004, Time = 11:22:25.1401"
 */
//--------------------------------------------------------------------------------
- (void) osc950ConvertTime: (uint64_t*) a10MHzTime timeToConvert: (char*) aCharTime
{
    const char*					stdMonths[] = { "JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", 
	"OCT", "NOV", "DEC" };
    struct tm					unixTime;
	//    struct tm*					tmpStruct;
    time_t				baseTime;
	uint64_t			fracSecs;
    const uint64_t	mult = 10000000;
	const uint64_t	mult1 = 1000;
	//    char*						dateString;
	short						i;
	
	NSCharacterSet* equalSet = [ NSCharacterSet characterSetWithCharactersInString: @"=" ];
	NSCharacterSet* spaceSet = [ NSCharacterSet characterSetWithCharactersInString: @" " ];
	NSCharacterSet* commaSet = [ NSCharacterSet characterSetWithCharactersInString: @"," ];
	
	// Set date/time reference to Greenwich time zone - no daylight savings time.
    unixTime.tm_isdst = 0;
    unixTime.tm_gmtoff = 0;
	
	//	printf( "Raw time: %s\n", aCharTime );
	
	// Get the month
	for ( i = 0; i < 12; i++ )
    {
        if ( strstr( aCharTime, stdMonths[ i ] ) )
        {
            unixTime.tm_mon = i;
            break;
        }
    }
	
    NSString* dateAsString = [ NSString stringWithFormat: @"%s", aCharTime ];
	NSScanner* scanner = [ NSScanner scannerWithString: dateAsString ];
	
	// Get date
	NSString*   tmpString;
	[ scanner scanUpToCharactersFromSet: equalSet intoString: nil ]; // find =
	[ scanner setScanLocation: [ scanner scanLocation ] +2 ];		
	[ scanner scanUpToCharactersFromSet: spaceSet intoString: nil ];  // find space
	[ scanner setScanLocation: [ scanner scanLocation ] +1 ];
	if ( [ scanner scanUpToCharactersFromSet: commaSet intoString: &tmpString ] )
	{
		unixTime.tm_mday = [ tmpString intValue ];
	}
	
	// Get year
	[ scanner setScanLocation: [ scanner scanLocation ] +2 ];
	[ scanner scanInt: &(unixTime.tm_year) ];
	unixTime.tm_year -= 1900;
	
	// Get time
	[ scanner scanUpToCharactersFromSet: equalSet intoString: nil ]; // find =
	[ scanner setScanLocation: [ scanner scanLocation ] +2 ];	
	[ scanner scanInt: &(unixTime.tm_hour) ];	
	
	[ scanner setScanLocation: [ scanner scanLocation ] +1 ];		
	[ scanner scanInt: &(unixTime.tm_min) ];	
	
	[ scanner setScanLocation: [ scanner scanLocation ] +1 ];		
	[ scanner scanInt: &(unixTime.tm_sec) ];	
	
	[ scanner setScanLocation: [ scanner scanLocation ] +1 ];
	int fracSecsInt;
	[ scanner scanInt: &fracSecsInt ];
	
	// convert fractions seconds to MHz.
	fracSecs = ( uint64_t )(fracSecsInt * mult1);
	
	//	printf( "Fraction: %d\n", fracSecsInt );	
	//	printf( "Year: %d, mon: %d, day %d\n", unixTime.tm_year, unixTime.tm_mon, unixTime.tm_mday );
	//	printf( "Hour: %d, min: %d, sec %d\n", unixTime.tm_hour, unixTime.tm_min, unixTime.tm_sec );
	
	// Get base time in seconds
    baseTime = timegm( &unixTime ); // Have to use timegm because mktime forces the time to
	// local time and then does conversion to gmtime    
	
	// Convert to 10 Mhz Clock
    *a10MHzTime = (uint64_t)baseTime * mult + fracSecs;
	//	printf( "LC950 - converted: %lld\n", *a10MHzTime );	
}
@end

@implementation ORLC950DecoderForScopeData
//just use the base class decodedata
@end

@implementation ORLC950DecoderForScopeGTID
- (uint32_t) decodeData: (void*) aSomeData fromDecoder:(ORDecoder*)aDecoder intoDataSet: (ORDataSet*) aDataSet
{
    return [self decodeGtId:aSomeData fromDecoder:aDecoder intoDataSet:aDataSet];
} 
- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    return [self dataGtIdDescription:ptr];
}
@end

@implementation ORLC950DecoderForScopeTime
- (uint32_t) decodeData: (void*) aSomeData fromDecoder:(ORDecoder*)aDecoder intoDataSet: (ORDataSet*) aDataSet
{
    return [self decodeClock:aSomeData fromDecoder:aDecoder intoDataSet:aDataSet];
} 
- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    return [self dataClockDescription:ptr];
}
@end














