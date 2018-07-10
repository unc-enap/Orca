//--------------------------------------------------------------------------------
/* Class:		OROscBaseModel
* brief:		Oscilloscope base model.
* Author:		Jan M. Wouters
*/
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
// Imports
#import "OROscBaseModel.h"

#import "ORDataPacket.h"
#import "ORDataTypeAssigner.h"

// Definitions
#pragma mark ***Definitions
#define	kDefaultAcquire			true

// Constants
const float	 kDefaultChnlPos	=	0.0;
const float	 kDefaultChnlScale	=	1.0;
const long	 kDefaultPulseLength = 5000;
const float	 kDefaultHorizScale = 1.0e-6;
const float	 kDefaultHorizPos = 0.5;

const float  kDefaultTriggerLevel = 0.100;

// Notification strings.
#pragma mark ¥¥¥Notification Strings
NSString*	OROscChnlAcqChangedNotification 		= @"Osc Chnl Acquire Changed";
NSString*	OROscChnlCouplingChangedNotification	= @"Osc Chnl Coupling Changed";
NSString*	OROscChnlPosChangedNotification			= @"Osc Chnl Pos Changed";
NSString*	OROscChnlScaleChangedNotification		= @"Osc Chnl Scale Changed";

NSString* 	OROscPulseLengthChangedNotification		= @"Osc Pulse Length Changed";
NSString*	OROscHorizPosChangedNotification		= @"Osc Horiz Pos Changed";
NSString*	OROscHorizScaleChangedNotification		= @"Osc Horiz Scale Changed";

NSString*	OROscTriggerCouplingChangedNotification	= @"Osc Trigger Coupling Changed";
NSString*	OROscTriggerLevelChangedNotification	= @"Osc Trigger Level Changed";
NSString*	OROscTriggerModeChangedNotification		= @"Osc Trigger Mode Changed";
NSString*	OROscTriggerPosChangedNotification		= @"Osc Trigger Pos Changed";
NSString*	OROscTriggerSlopeChangedNotification	= @"Osc Trigger Slope Changed";
NSString*	OROscTriggerSourceChangedNotification	= @"Osc Trigger Source Changed";

NSString* 	OROscModelReflectsHardwareChangedNotification = @"Osc Model Reflects Hardware";

#pragma mark ***Identification Strings
NSString*	OROscChnl								= @"Osc Chnl";

@implementation OROscBaseModel
#pragma mark ***Initialization
//--------------------------------------------------------------------------------
/*!\method  init
* \brief	Called first time class is initialized.  Used to set basic
*			default values first time object is created.
* \note	
*/
//--------------------------------------------------------------------------------
- (id) init
{
    short 	i;
    
    self = [ super init ];
	
    [[ self undoManager ] disableUndoRegistration ];
    
	// Initialize channel parameters.
    for ( i = 0; i < [self numberChannels]; i++ )
    {
        [ self setChnlAcquire: i setting: kDefaultAcquire ];
        [ self setChnlCoupling: i coupling: kChnlCouplingDC50Index ];
        [ self setChnlPos: i position: kDefaultChnlPos ];
        [ self setChnlScale: i scale: kDefaultChnlScale ];
    }
    
	// Initialize horizontal parameters
    [ self setWaveformLength: kDefaultPulseLength ];
    [ self setHorizontalScale: kDefaultHorizScale ];
    [ self setHorizontalPos: kDefaultHorizPos ];
    
	// Initialize trigger parameters
    [ self setTriggerCoupling: kTriggerDC ];
    [ self setTriggerLevel: kDefaultTriggerLevel ];
    [ self setTriggerMode: kTriggerNormal ];
    [ self setTriggerPos: kDefaultHorizPos ];
    [ self setTriggerSlopeIsPos: true ];
    [ self setTriggerSource: kTriggerCH1 ];
	
	[[ self undoManager ] enableUndoRegistration ];
    
	// Model does not reflect hardware at this point.
    mModelReflectsHardware = false;
    mDataThreadRunning = NO;
	
    return self;
}

//--------------------------------------------------------------------------------
/*!\method  dealloc
* \brief	Deallocates all internal storage.
* \note	
*/
//--------------------------------------------------------------------------------
- (void) dealloc
{
    [ super dealloc ];
}

#pragma mark ***Accessors

- (int)     numberChannels
{
	return kMaxOscChnls;
}

//--------------------------------------------------------------------------------
/*!\method  scopeType  
* \brief	Returns the scope type.
* \return	The scope type as unsigned long.  Might be up to 4 character text.
* \note	
*/
//--------------------------------------------------------------------------------
- (unsigned long) scopeType
{
    return( mScopeType );
}

//--------------------------------------------------------------------------------
/*!\method  scopeVersion  
* \brief	Returns the scope version.
* \return	The scope version as unsigned long.  Might be character text.
* \note	
*/
//--------------------------------------------------------------------------------
- (unsigned long) scopeVersion
{
    return( mScopeVersion );
}

//--------------------------------------------------------------------------------
/*!\method  chnlAcquire  
* \brief	Return whether channel is turned on.
* \param	aChnl			- The channel number.
* \error	Throws error if channel number is invalid.
* \note	
*/
//--------------------------------------------------------------------------------
- (bool) chnlAcquire: (short) aChnl
{
    BOOL	bRetVal = false;
    
    if ( [ self checkChnlNum: aChnl ] )
    	bRetVal = mChannels[ aChnl ].chnlAcquire;
	
    return( bRetVal );
}

//--------------------------------------------------------------------------------
/*!\method  setChnlAcquire
* \brief	Set whether this channel will acquire data.
* \param	aChnl			- The channel number.
* \param	aState			- True of false to set the channel on or off.
* \error	Throws error if channel number is invalid.
* \note	
*/
//--------------------------------------------------------------------------------
- (void) setChnlAcquire: (short) aChnl setting: (bool) aState
{
    if ( [ self checkChnlNum: aChnl ] )
    {
		
		// Set the undo manager action.  The label has already been set by the controller calling this method.
        [[[ self undoManager ] prepareWithInvocationTarget: self ] 
                               setChnlAcquire: aChnl setting: [ self chnlAcquire: aChnl  ]];
        
		// Set the new value in the model.
        mChannels[ aChnl ].chnlAcquire = aState;
        
		// Create a dictionary object that stores a pointer to this object and the channel that was changed.
        NSMutableDictionary* userInfo = [ NSMutableDictionary dictionary ];
        [ userInfo setObject: [ NSNumber numberWithInt: aChnl ] forKey: OROscChnl ]; 
		
		// Send out notification that the value has changed.  The dictionary object just created is sent
		// so that objects receiving the notification know what has happened.
        [[ NSNotificationCenter defaultCenter ]
            postNotificationName: OROscChnlAcqChangedNotification
                          object: self
                        userInfo: userInfo ];
    }
}

//--------------------------------------------------------------------------------
/*!\method  chnlCoupling 
* \brief	Return the coupling mode for the specified channel.
* \param	aChnl			- The channel number.
* \error	Throws error if channel number is invalid.
* \note	
*/
//--------------------------------------------------------------------------------
- (short) chnlCoupling: (short) aChnl
{
    short	retVal = kChnlCouplingGNDIndex;
    if ( [ self checkChnlNum: aChnl ] )
    	retVal = mChannels[ aChnl ].chnlCoupling;
	
    return( retVal );
}

//--------------------------------------------------------------------------------
/*!\method  setChnlCoupling
* \brief	Set the coupling for the specified channel.
* \param	aChnl			- The channel number.
* \param	aValue			- The coupling option.
* \error	Throws error if channel number is invalid.
* \note	
*/
//--------------------------------------------------------------------------------
- (void) setChnlCoupling: (short) aChnl coupling: (short) aValue
{
    if ( [ self checkChnlNum: aChnl ] )
    {
		
		// Set the undo manager action.  The label has already been set by the controller calling this method.
        [[[ self undoManager ] prepareWithInvocationTarget: self ] 
                               setChnlCoupling: aChnl coupling: [ self chnlCoupling: aChnl  ]];
        
		// Set the new value in the model.
        mChannels[ aChnl ].chnlCoupling = aValue;
        
		// Create a dictionary object that stores a pointer to this object and the channel that was changed.
        NSMutableDictionary* userInfo = [ NSMutableDictionary dictionary ];
        [ userInfo setObject: [ NSNumber numberWithInt: aChnl ] forKey: OROscChnl ]; 
		
		// Send out notification that the value has changed.  The dictionary object just created is sent
		// so that objects receiving the notification know what has happened.
        [[ NSNotificationCenter defaultCenter ]
            postNotificationName: OROscChnlCouplingChangedNotification
                          object: self
                        userInfo: userInfo ];
    }
}

//--------------------------------------------------------------------------------
/*!\method  chnlPos 
* \brief	Return the position of the trace.
* \param	aChnl			- The channel number.
* \error	Throws error if channel number is invalid.
* \note	
*/
//--------------------------------------------------------------------------------
- (float) chnlPos: (short) aChnl
{
    float	retVal = 0.0;
    if ( [ self checkChnlNum: aChnl ] )
    	retVal = mChannels[ aChnl ].chnlPos;
	
    return( retVal );
}


//--------------------------------------------------------------------------------
/*!\method  setChnlPos
* \brief	Set the coupling for the specified channel.
* \param	aChnl			- The channel number.
* \param	aValue			- Value for the position in volts.
* \error	Throws error if channel number is invalid.
* \note	
*/
//--------------------------------------------------------------------------------
- (void) setChnlPos: (short) aChnl position: (float) aValue
{
    if ( [ self checkChnlNum: aChnl ] )
    {
		
		// Set the undo manager action.  The label has already been set by the controller calling this method.
        [[[ self undoManager ] prepareWithInvocationTarget: self ] 
                               setChnlPos: aChnl position: [ self chnlPos: aChnl  ]];
        
		// Set the new value in the model.
        mChannels[ aChnl ].chnlPos = aValue;
        
		// Create a dictionary object that stores a pointer to this object and the channel that was changed.
        NSMutableDictionary* userInfo = [ NSMutableDictionary dictionary ];
        [ userInfo setObject: [ NSNumber numberWithInt: aChnl ] forKey: OROscChnl ]; 
		
		// Send out notification that the value has changed.  The dictionary object just created is sent
		// so that objects receiving the notification know what has happened.
        [[ NSNotificationCenter defaultCenter ]
            postNotificationName: OROscChnlPosChangedNotification
                          object: self
                        userInfo: userInfo ];
    }
}


//--------------------------------------------------------------------------------
/*!\method  chnlScale 
* \brief	Return the vertical scale used for the trace.
* \param	aChnl			- The channel number.
* \error	Throws error if channel number is invalid.
* \note	
*/
//--------------------------------------------------------------------------------
- (float) chnlScale: (short) aChnl
{
    float	retVal = 0.0;
    if ( [ self checkChnlNum: aChnl ] )
    	retVal = mChannels[ aChnl ].chnlScale;
	
    return( retVal );
}


//--------------------------------------------------------------------------------
/*!\method  setChnlScale
* \brief	Set the vertical scale used for the trace.
* \param	aChnl			- The channel number.
* \param	aValue			- Value for the position in volts.
* \error	Throws error if channel number is invalid.
* \note	
*/
//--------------------------------------------------------------------------------
- (void) setChnlScale: (short) aChnl scale: (float) aValue
{
    if ( [ self checkChnlNum: aChnl ] )
    {
		
		// Set the undo manager action.  The label has already been set by the controller calling this method.
        [[[ self undoManager ] prepareWithInvocationTarget: self ]
                               setChnlScale: aChnl scale: [ self chnlScale: aChnl  ]];
        
		// Set the new value in the model.
        mChannels[ aChnl ].chnlScale = aValue;
        
		// Create a dictionary object that stores a pointer to this object and the channel that was changed.
        NSMutableDictionary* userInfo = [ NSMutableDictionary dictionary ];
        [ userInfo setObject: [ NSNumber numberWithInt: aChnl ] forKey: OROscChnl ]; 
		
		// Send out notification that the value has changed.  The dictionary object just created is sent
		// so that objects receiving the notification know what has happened.
        [[ NSNotificationCenter defaultCenter ]
            postNotificationName: OROscChnlScaleChangedNotification
                          object: self
                        userInfo: userInfo ];
    }
}

//--------------------------------------------------------------------------------
/*!\method  horizontalPos
* \brief	Get the offset of the horizontal scale
* \return	Horizontal offset.
* \note	
*/
//--------------------------------------------------------------------------------
- (float) horizontalPos
{
    return mHorizPos;
}

//--------------------------------------------------------------------------------
/*!\method  setHorizontalPos
* \brief	Set the offset of the horizontal scale
* \param	aHorizontalPos		- Horizontal offset.
* \note	
*/
//--------------------------------------------------------------------------------
- (void) setHorizontalPos: (float) aHorizontalPos
{
	// Set the undo manager action.  The label has already been set by the controller calling this method.
	[[[ self undoManager ] prepareWithInvocationTarget: self ]
                               setHorizontalPos: [ self horizontalPos  ]];
	
	// Set the new value in the model.
    mHorizPos = aHorizontalPos;
	
	// Send out notification that the value has changed.  
    [[ NSNotificationCenter defaultCenter ]
            postNotificationName: OROscHorizPosChangedNotification
                          object: self];
}

//--------------------------------------------------------------------------------
/*!\method  horizontalScale
* \brief	Get the scale value in seconds / division for the horizontal scale.
* \return	Horizontal scale in seconds / division.
* \note	
*/
//--------------------------------------------------------------------------------
- (float) horizontalScale
{
    return mHorizScale;
}

//--------------------------------------------------------------------------------
/*!\method  setHorizontalScale
* \brief	Set the horizontal scale value in seconds / division.
* \param	Horizontal scale.
* \note	
*/
//--------------------------------------------------------------------------------
- (void) setHorizontalScale: (float) aHorizontalScale
{
	// Set the undo manager action.  The label has already been set by the controller calling this method.
	[[[ self undoManager ] prepareWithInvocationTarget: self ]
                               setHorizontalScale: [ self horizontalScale ]];
	
	// Set the new value in the model.
    mHorizScale = aHorizontalScale;
	
	// Send out notification that the value has changed. 
    [[ NSNotificationCenter defaultCenter ]
            postNotificationName: OROscHorizScaleChangedNotification
                          object: self];
}

//--------------------------------------------------------------------------------
/*!\method  waveformLength
* \brief	Get the length of the waveform stored by the oscilloscope
* \return	Length of the waveform in points.
* \note	
*/
//--------------------------------------------------------------------------------
- (long) waveformLength
{
    return mWaveformLength;
}

//--------------------------------------------------------------------------------
/*!\method  setWaveformLength
* \brief	Set the waveform length in points recorded by the oscilloscope.
* \param	aWaveformLength			- The number of points to record.
* \note	
*/
//--------------------------------------------------------------------------------
- (void) setWaveformLength: (long) aWaveformLength
{
	// Set the undo manager action.  The label has already been set by the controller calling this method.
    [[[ self undoManager ] prepareWithInvocationTarget: self ]
                        setWaveformLength: [ self waveformLength ]];
	
	// Set the model value.
    mWaveformLength = aWaveformLength;
	
	// Send out notification that the value has changed. 
    [[ NSNotificationCenter defaultCenter ]
            postNotificationName: OROscPulseLengthChangedNotification
                          object: self];
}        


//--------------------------------------------------------------------------------
/*!\method  triggerCoupling
* \brief	Get the coupling of the trigger
* \return	Trigger coupling index.
* \note	
*/
//--------------------------------------------------------------------------------
- (short) triggerCoupling
{
    return mTriggerCoupling;
}

//--------------------------------------------------------------------------------
/*!\method  setTriggerCoupling
* \brief	Set the appropriate index for the desired trigger coupling.  See .h file
*			for constants.
* \param	aTriggerCoupling		- The triggering coupling index.
* \note	
*/
//--------------------------------------------------------------------------------
- (void) setTriggerCoupling: (short) aTriggerCoupling
{
	// Set the undo manager action.  The label has already been set by the controller calling this method.
	[[[ self undoManager ] prepareWithInvocationTarget: self ]
                               setTriggerCoupling: [ self triggerCoupling  ]];
	
	// Set the new value in the model.
    mTriggerCoupling = aTriggerCoupling;
	
	// Send out notification that the value has changed.  
    [[ NSNotificationCenter defaultCenter ]
            postNotificationName: OROscTriggerCouplingChangedNotification
                          object: self];
}

//--------------------------------------------------------------------------------
/*!\method  triggerLevel
* \brief	Get the level for the trigger
* \return	Trigger level in volts.
* \note	
*/
//--------------------------------------------------------------------------------
- (float) triggerLevel
{
    return mTriggerLevel;
}

//--------------------------------------------------------------------------------
/*!\method  setTriggerLevel
* \brief	Set the trigger level in volts.
* \param	aTriggerLevel			- The trigger level.
* \note	
*/
//--------------------------------------------------------------------------------
- (void) setTriggerLevel: (float) aTriggerLevel
{
	// Set the undo manager action.  The label has already been set by the controller calling this method.
	[[[ self undoManager ] prepareWithInvocationTarget: self ]
                               setTriggerLevel: [ self triggerLevel  ]];
	
	// Set the new value in the model.
    mTriggerLevel = aTriggerLevel;
	
	// Send out notification that the value has changed.  
    [[ NSNotificationCenter defaultCenter ]
            postNotificationName: OROscTriggerLevelChangedNotification
                          object: self];
}

//--------------------------------------------------------------------------------
/*!\method  triggerMode
* \brief	Get the mode for the oscilloscope
* \return	trigger mode as index.
* \note	
*/
//--------------------------------------------------------------------------------
- (short) triggerMode
{
    return mTriggerMode;
}

//--------------------------------------------------------------------------------
/*!\method  setTriggerMode
* \brief	Set the index for the trigger mode.  See .h file for list of trigger
*			mode constants.
* \param	aTriggerMode		- Index of trigger mode.
* \note	
*/
//--------------------------------------------------------------------------------
- (void) setTriggerMode: (short) aTriggerMode
{
	// Set the undo manager action.  The label has already been set by the controller calling this method.
	[[[ self undoManager ] prepareWithInvocationTarget: self ]
                               setTriggerMode: [ self triggerMode  ]];
	
	// Set the new value in the model.
    mTriggerMode = aTriggerMode;
	
	// Send out notification that the value has changed.  
    [[ NSNotificationCenter defaultCenter ]
            postNotificationName: OROscTriggerModeChangedNotification
                          object: self];
}

//--------------------------------------------------------------------------------
/*!\method  triggerPos
* \brief	Get the trigger position for the scope traice.
* \return	trigger position as value between 0 and 100%..
* \note	
*/
//--------------------------------------------------------------------------------
- (float) triggerPos
{
    return( mTriggerPos );
}


//--------------------------------------------------------------------------------
/*!\method  setTriggerPos
* \brief	Set the trigger position from 0 to 100%.
* \note	
*/
//--------------------------------------------------------------------------------
- (void) setTriggerPos: (float) aTriggerPos
{
	// Set the undo manager action.  The label has already been set by the controller calling this method.
    [[[ self undoManager ] prepareWithInvocationTarget: self ]
                               setTriggerPos: [ self triggerPos  ]];
	
	// Set the new value in the model.
    mTriggerPos = aTriggerPos;
	
	// Send out notification that the value has changed.  
    [[ NSNotificationCenter defaultCenter ]
            postNotificationName: OROscTriggerPosChangedNotification
                          object: self];
}

//--------------------------------------------------------------------------------
/*!\method  triggerSlopeIsPos
* \brief	Returns true if the trigger slope is pos, false if negative.
* \return	True - trigger slope is positive.
* \note	
*/
//--------------------------------------------------------------------------------
- (bool) triggerSlopeIsPos
{
    return mTriggerSlopeIsPos;
}

//--------------------------------------------------------------------------------
/*!\method  setHorizontalPos
* \brief	Set the offset of the horizontal scale
* \param	Horizontal offset.
* \note	
*/
//--------------------------------------------------------------------------------
- (void) setTriggerSlopeIsPos: (bool) aTriggerSlope
{
	// Set the undo manager action.  The label has already been set by the controller calling this method.
	[[[ self undoManager ] prepareWithInvocationTarget: self ]
                               setTriggerSlopeIsPos: [ self triggerSlopeIsPos  ]];
	
	// Set the new value in the model.
    mTriggerSlopeIsPos = aTriggerSlope;
	
	// Send out notification that the value has changed.  
    [[ NSNotificationCenter defaultCenter ]
            postNotificationName: OROscTriggerSlopeChangedNotification
                          object: self];
}

//--------------------------------------------------------------------------------
/*!\method  triggerSource
* \brief	Get index indicating the trigger source
* \return	trigger source.
* \note	
*/
//--------------------------------------------------------------------------------
- (short) triggerSource
{
    return mTriggerSource;
}

//--------------------------------------------------------------------------------
/*!\method  setTriggerSource
* \brief	Set the index for the trigger source.  See the .h file for a list
*			of possible trigger indecies.
* \param	aTriggerSource 			- Index corresponding to trigger source.
* \note	
*/
//--------------------------------------------------------------------------------
- (void) setTriggerSource: (short) aTriggerSource
{
	// Set the undo manager action.  The label has already been set by the controller calling this method.
	[[[ self undoManager ] prepareWithInvocationTarget: self ]
                               setTriggerSource: [ self triggerSource  ]];
	
	// Set the new value in the model.
    mTriggerSource = aTriggerSource;
	
	// Send out notification that the value has changed.  
    [[ NSNotificationCenter defaultCenter ]
            postNotificationName: OROscTriggerSourceChangedNotification
                          object: self];
}

//--------------------------------------------------------------------------------
/*!\method  modelReflectsHardware
* \brief	Get whether model reflects oscilloscope hardware
* \return	True - model reflects hardware or false - model does not reflect hardware.
* \note	
*/
//--------------------------------------------------------------------------------
- (bool) modelReflectsHardware
{
    return mModelReflectsHardware;
}

//--------------------------------------------------------------------------------
/*!\method  setModelReflectsHardware
* \brief	Set whether model reflects the oscilloscope hardware.
* \param	aState		- True model reflect hardware or false.
* \note	This routine cannot be undone.
*/
//--------------------------------------------------------------------------------
- (void) setModelReflectsHardware: (bool) aState
{
	// Set the new value in the model.
    mModelReflectsHardware = aState; 
	
	// Send out notification that the value has changed.  
    [[ NSNotificationCenter defaultCenter ]
            postNotificationName: OROscModelReflectsHardwareChangedNotification
                          object: self];
	
}


//--------------------------------------------------------------------------------
/*!\method  doFullInit
* \brief	Get whether model will do a full init of the scope at run start
* \return	True - will do full init.
* \note	
*/
//--------------------------------------------------------------------------------
- (BOOL)	doFullInit
{
    return mDoFullInit;
}

//--------------------------------------------------------------------------------
/*!\method  setDoFullInit
* \brief	Sets whether model will do a full init of the scope at run start
* \param	aState		- True model will init scope.
* \note	this is for internal use only
*/
//--------------------------------------------------------------------------------
- (void)	setDoFullInit: (BOOL) aState
{
    mDoFullInit = aState;
}

#pragma mark ***Commands
//--------------------------------------------------------------------------------
/*!\method  setModelFromOsc
* \brief	Sets the internal parameters of the model from the oscilloscope and
*			notifies the controller of the change.
* \note	
*/
//--------------------------------------------------------------------------------
- (void) setModelFromOsc
{
    [ self oscGetStandardSettings ];
}

//--------------------------------------------------------------------------------
/*!\method  setOscFromModel
* \brief	Given the parameters in the model loads the oscilloscope from those
*			parameters.
* \note	
*/
//--------------------------------------------------------------------------------
- (void) setOscFromModel
{
    BOOL savedstate = [ self doFullInit ];
	[ self setDoFullInit: YES ];
    [ self oscSetStandardSettings ];
    [ self setDoFullInit: savedstate ];
}

- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}


- (unsigned long) gtidDataId { return gtidDataId; }
- (void) setGtidDataId: (unsigned long) GtidDataId
{
    gtidDataId = GtidDataId;
}


- (unsigned long) clockDataId { return clockDataId; }
- (void) setClockDataId: (unsigned long) ClockDataId
{
    clockDataId = ClockDataId; 
}

- (void) setDataIds:(id)assigner
{
    dataId = [assigner assignDataIds:kLongForm];
    gtidDataId = [assigner assignDataIds:kShortForm];
    clockDataId = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherScope
{
    [self setDataId:[anotherScope dataId]];
    [self setGtidDataId:[anotherScope gtidDataId]];
    [self setClockDataId:[anotherScope clockDataId]];
}


#pragma mark ***Oscilloscope Methods
//--------------------------------------------------------------------------------
/*!\method  oscGetStandardSettings 
* \brief	This routine gets the standard settings from the oscilloscope
* \error	Throws error if any command fails.
* \note	
*/
//--------------------------------------------------------------------------------
- (void) oscGetStandardSettings
{
    int 	i;
    
	[ self clearStatusReg ];
	[ self oscSetQueryFormat: kLongLabel ]; 
    
	//	Get channel settings
	for ( i = 0; i < [self numberChannels]; i++ )
	{
		[ self oscGetChnlAcquire: i ];
		//		if ( [ self chnlAcquire: i ] )
		//		{
		[ self oscGetChnlCoupling: i ];
		[ self oscGetChnlScale: i ];
		[ self oscGetChnlPos: i ];
		//		}
	}
	
	// Get Horizontal settings
	[ self oscGetHorizontalPos ];
	[ self oscGetHorizontalScale ];
	[ self oscGetWaveformRecordLength ];
	
	// Get trigger settings
	[ self oscGetTriggerCoupling ];
	[ self oscGetTriggerLevel ];
	[ self oscGetTriggerMode ];
    [ self oscGetTriggerPos ];
	[ self oscGetTriggerSlopeIsPos ];
	[ self oscGetTriggerSource ];
    
	// Get oscilloscope specific settings.
    [ self oscGetOscSpecificSettings ];
    
	// Send out notification that model now reflects oscilloscope settings
    [ self setModelReflectsHardware: true ];    
	
}


//--------------------------------------------------------------------------------
/*!\method  oscSetStandardSettings 
* \brief	This routine sets the oscilloscope up using the model settings.
* \error	Throws error if any command fails.
* \note	1) This routine stops any acquisition that is currently in progress
*				sets the settings and then restarts the acquisition either
*				as a true run or as free running.
*/
//--------------------------------------------------------------------------------
- (void) oscSetStandardSettings
{
    time_t	theTime;
    struct tm*	theTimeGMTAsStruct;
    char	theMsg[ 45 ];
    short	i;	
    
    //[ self oscStopAcquisition ];
    //[ self clearStatusReg ];
    //[ self oscSetQueryFormat: kLongLabel ]; 
    
    if ( mDoFullInit ) {
		[ self oscStopAcquisition ];
		[ self clearStatusReg ];
		[ self oscSetQueryFormat: kLongLabel ]; 
		// Set date time    
		time( &theTime );
		theTimeGMTAsStruct = gmtime( &theTime );
		//	theTimeAsStruct = localtime( &theTimeGMT );
		strftime( theMsg, 45, "Parameters changed: %a %b %d %Y, %H:%M:%S  GMT", theTimeGMTAsStruct );
		
        //	Set channel settings
        [ self oscSetChnlAcquire];
        for ( i = 0; i < [self numberChannels]; i++ )
		{
            if ( [ self chnlAcquire: i ] )
			{
                [ self oscSetChnlCoupling: i ];
                [ self oscSetChnlScale: i ];
                [ self oscSetChnlPos: i ];
            }
        }
        
        // Set Horizontal settings
        [ self oscSetHorizontalPos ];
        [ self oscSetHorizontalScale ];
        [ self oscSetWaveformRecordLength ];
        
        // Set trigger settings
        [ self oscSetTriggerCoupling ];
        [ self oscSetTriggerLevel ];
        [ self oscSetTriggerMode ];
        [ self oscSetTriggerPos ];
        [ self oscSetTriggerSlopeIsPos ];
        [ self oscSetTriggerSource ];
		
		//Set oscilloscope specific settings.
		// [ self oscSetOscSpecificSettings ];
		
		// Restart the acquisition either in a true run, or normal triggering.	
		[ self oscRunOsc: [ NSString stringWithCString: theMsg encoding:NSASCIIStringEncoding]];
    }
    
    
    // Send out notification that model now reflects oscilloscope settings
    [ self setModelReflectsHardware: true ];    
}

//--------------------------------------------------------------------------------
/*!\method  oscInitializeForDataTaking 
* \brief	This routine setups up the scope so that it can acquire data using
*			the computer.
* \param	aStartMsg			A starting message to write out to the screen.
* \error	Throws error if any command fails.
* \note	
*/
//--------------------------------------------------------------------------------
- (void) oscInitializeForDataTaking: (NSString*) aStartMsg
{
	
    //if(!mDoFullInit) return;
    
    //removed MAH 01/14/04  now load Osc from dialog at run start instead of dialog.
    //[ self oscGetStandardSettings ];			// Get the standard settings 
	
	// [ self oscSetScreenDisplay: true ];			// Display message box.
    //[ self oscLockPanel: true ];			// Lock front panel of oscilloscope.
    //[ self oscSetQueryFormat: kLongLabel ];		// Set label format to long.
    //[ self oscSendTextMessage: aStartMsg ];		// Writes start message
    //[ self clearStatusReg ];				// Resets GPIB device status registers
    if(mDoFullInit){
        [ self oscSetChnlAcquire ];
        [ self oscSetWaveformRecordLength ];
    }
	
    [ self oscSetDataReturnMode ];			// Sets data format between scope and computer
    [ self oscSetQueryFormat: kNoLabel ];		// Set response to no labels.	
												//[ self oscSetScreenDisplay: false ];		// Turn off screen to improve response.
    [ self oscSetOscSpecificSettings ];			// Set scope specific settings
}

#pragma mark ¥¥¥DataTaker
//--------------------------------------------------------------------------------
/*!\method  takeData
* \brief	Routine that is repeatedly called to actually acquire the data.  This
*			routine spawns a separate thread which actually runs the takeDataTask
*			in this class.
* \param	aDataPacket				- Object where data is written.
* \param	userInfo				- Information that is passed as dictionary to 
*									   this routine from other hardware objects.
* \note	This routine just calls the takeData packet using the channel mask
*			set to ff.
*								       
*/
//--------------------------------------------------------------------------------
- (void) takeData: (ORDataPacket*) aDataPacket userInfo: (id) userInfo
{
    //we do all this crap to avoid the 800uS start up cost of launching the thread. 
    //the thread is created only once and it is allowed to run only when the -okToGo lock
    //condition is YES. But it takes 200uS to set the -okToGo condition lock.
    if( !mDataThreadRunning ) {
		mDataThreadRunning = YES;
        // Launch the thread.
		[ NSThread detachNewThreadSelector: @selector( takeDataTask: ) 
                                  toTarget: self withObject:nil ];
		
		
		
    } 
	
    if(![_okToGo condition]){
		// Create the data dictionary with data to pass to thread.
        [threadParams addEntriesFromDictionary:userInfo];
		
        [_okToGo unlockWithCondition:YES]; //let the thread go
    }
	
}

- (void)	takeDataTask:(NSDictionary*)userInfo
{
	//subclass responsibility
}

#pragma mark ***Overridden methods
//--------------------------------------------------------------------------------
// Routines which must be overridden in derived class.
//--------------------------------------------------------------------------------
/*!\method  runTaskStarted
* \brief   Initializes the thread lock parameter used to indicate if this
*			thread should exit.  Sets thread conditional lock to NO.
*/
//--------------------------------------------------------------------------------
- (void) runTaskStarted: (ORDataPacket*) aDataPacket userInfo: (id) userInfo 
{
    int i;
    for(i=0;i<[self numberChannels];i++){
        eventCount[i]= 0;
    }
  
	if(!threadParams){
		threadParams = [[ NSMutableDictionary dictionaryWithObjectsAndKeys: 
			self,        @"Model", 
			aDataPacket, @"ThreadData", 
			nil ] retain];
	}	
	    
    if( _cancelled ) [ _cancelled release ];
    _cancelled  = [[ NSConditionLock alloc ] initWithCondition: NO ];
    if( _okToGo ) [ _okToGo release ];
    _okToGo  = [[ NSConditionLock alloc ] initWithCondition: NO ];
	

}

- (void) reset {};

- (int) tag
{
    return [self primaryAddress];
}

- (void) incEventCount:(int)aChannel
{
    eventCount[aChannel]++;
}

- (unsigned long) eventCount:(int)aChannel
{
    return eventCount[aChannel];
}


//--------------------------------------------------------------------------------
/*!\method  markAsCancelled
* \brief	Marks thread as cancelled but cannot actually cause thread to quit.
*/
//--------------------------------------------------------------------------------
-(void) markAsCancelled
{
    // Get lock if we're currently NOT cancelled
    if( [ _cancelled tryLockWhenCondition: NO ] ){
        [ _cancelled unlockWithCondition: YES ];
        [ _okToGo unlockWithCondition: YES ];
    }
}

//--------------------------------------------------------------------------------
/*!\method  cancelled
* \brief	returns YES if the thread is marked to be cancelled.
*/
//--------------------------------------------------------------------------------
-(BOOL)cancelled
{
    return [_cancelled condition];
}

//--------------------------------------------------------------------------------
/*!\method  runTaskStopped
* \brief	Sets cancelled flag so thread will stop.    
* \param	aDataPacket			- Data from most recent event.
* \note	
*/
//--------------------------------------------------------------------------------
- (void) runTaskStopped: (ORDataPacket*) aDataPacket  userInfo: (id) anUserInfo
{     
    
	int timeCount = 0;
    while( mDataThreadRunning ){
		[ self markAsCancelled ];
		//[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
        //                     beforeDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
		[NSThread sleepUntilDate:[[NSDate date] dateByAddingTimeInterval:.1]];
		timeCount++;
		if(timeCount >= 100){
            NSLog( @"time out waiting for scope thread to exit\n" );
            break;
        }
    }
	
    if(threadParams){
        [threadParams release];
        threadParams = nil;
    }
}

- (void) 	oscGetOscSpecificSettings {}
- (void)	oscSetOscSpecificSettings {}

#pragma mark ***Support
	//--------------------------------------------------------------------------------
	/*!\method  checkChnlNum 
	* \brief	Checks that the oscilloscope channel is a valid number.
	* \param	aChnl			- The channel number to check.
	* \return	True - Channel number is valid
	* \error	Throws error if channel number is bad.
	* \note	
	*/
	//--------------------------------------------------------------------------------
- (bool) checkChnlNum: (short) aChnl
{
    NSString*		errorMsg;    
    bool			bRetVal = false;
    
    if ( aChnl > -1 && aChnl < [self numberChannels] ) 
        bRetVal = true;
	
	// Raise error if channel number is bad.
    else
    {
        errorMsg = [ NSString stringWithFormat: @"Bad oscilloscope channel number: %d", aChnl ];
        [ NSException raise: OExceptionOscError format: @"%@",errorMsg ];
    }
	
	
    return bRetVal;
}


#pragma mark ¥¥¥Archival
// Encode decode strings.
static NSString*	OROscAcqChnl			= @"OROscAcq%d";
static NSString*	OROscCouplingChnl		= @"OROscCoupling%d";
static NSString*	OROscPosChnl			= @"OROscPos%d";
static NSString*	OROscScaleChnl			= @"OROscScale%d";

static NSString*	OROscHorizPos			= @"OROscHorizPos";
static NSString*	OROscHorizScale			= @"OROscHorizScale";
static NSString*	OROscPulseLength		= @"ORPulseLength";

static NSString*	OROscTriggerCoupling	= @"ORTriggerCoupling";
static NSString*	OROscTriggerLevel		= @"ORTriggerLevel";
static NSString*	OROscTriggerMode		= @"ORTriggerMode";
static NSString*	OROscTriggerPos			= @"ORTriggerPos";
static NSString*	OROscTriggerSlopeIsPos	= @"ORTriggerSlopeIsPos";
static NSString*	OROscTriggerSource		= @"ORTriggerSource";

//--------------------------------------------------------------------------------
/*!\method  initWithCoder  
* \brief	Initialize object using archived settings.
* \param	aDecoder			- Object used for getting archived internal parameters.
* \note	
*/
//--------------------------------------------------------------------------------
- (id) initWithCoder: (NSCoder*) aDecoder
{
    short		i;
    
    self = [ super initWithCoder: aDecoder ];
	
    [[ self undoManager ] disableUndoRegistration ];
	
	// Retrieve the parameters
	// Retrieve channel parameters.
    for ( i = 0; i < [self numberChannels]; i++ ){
        [self setChnlAcquire:i setting:[aDecoder decodeBoolForKey:[NSString stringWithFormat: OROscAcqChnl, i]]];
        [self setChnlCoupling:i coupling:[aDecoder decodeIntForKey:[NSString stringWithFormat: OROscCouplingChnl, i]]];
        [self setChnlPos:i position:[aDecoder decodeFloatForKey:[NSString stringWithFormat: OROscPosChnl, i]]];
        [self setChnlScale:i scale:[aDecoder decodeFloatForKey:[NSString stringWithFormat: OROscScaleChnl, i]]];
    }
    
	// Retrieve horizontal parameters
    [ self setHorizontalPos:    [aDecoder decodeFloatForKey: OROscHorizPos]];
    [ self setHorizontalScale:  [aDecoder decodeFloatForKey: OROscHorizScale]];
    [ self setWaveformLength:   [aDecoder decodeInt32ForKey: OROscPulseLength]];
    
	// Retrieve trigger parameters
    [ self setTriggerCoupling:  [aDecoder decodeIntForKey:  OROscTriggerCoupling]];
    [ self setTriggerLevel:     [aDecoder decodeFloatForKey:OROscTriggerLevel]];
    [ self setTriggerMode:      [aDecoder decodeIntForKey:  OROscTriggerMode]];
    [ self setTriggerPos:       [aDecoder decodeFloatForKey:OROscTriggerPos]];
    [ self setTriggerSlopeIsPos:[aDecoder decodeBoolForKey: OROscTriggerSlopeIsPos]];
    [ self setTriggerSource:    [aDecoder decodeIntForKey:  OROscTriggerSource]];
	
    [[ self undoManager ] enableUndoRegistration];
    
	// Model does not reflect hardware at this point.
    [ self setModelReflectsHardware: false ];
	
    return self;
}


//--------------------------------------------------------------------------------
/*!\method  encodeWithCoder  
* \brief	Save the internal settings to the archive.
* \param	anEncoder			- Object used for encoding.
* \note	
*/
//--------------------------------------------------------------------------------
- (void) encodeWithCoder: (NSCoder*) anEncoder
{
    short		i;
    
    [ super encodeWithCoder: anEncoder ];
    
	// Save the channel parameters
    for ( i = 0; i < [self numberChannels]; i++ ){
        [anEncoder encodeBool: [self chnlAcquire: i]    forKey: [ NSString stringWithFormat: OROscAcqChnl, i ]];
        [anEncoder encodeInt: [self chnlCoupling: i]    forKey: [ NSString stringWithFormat: OROscCouplingChnl, i ]];
        [anEncoder encodeFloat: [self chnlPos: i]       forKey: [ NSString stringWithFormat: OROscPosChnl, i ]];
        [anEncoder encodeFloat: [self chnlScale: i]     forKey: [ NSString stringWithFormat: OROscScaleChnl, i ]];
    }
    
	// Save horizontal parameters
    [ anEncoder encodeFloat: [self horizontalPos]      forKey: OROscHorizPos];
    [ anEncoder encodeFloat: [self horizontalScale]     forKey: OROscHorizScale];
    [ anEncoder encodeInt32: [self waveformLength]      forKey: OROscPulseLength];
	
	// Save trigger parameters
    [anEncoder encodeInt: [self triggerCoupling]	forKey: OROscTriggerCoupling ];
    [anEncoder encodeFloat: [self triggerLevel]		forKey: OROscTriggerLevel];
    [anEncoder encodeInt: [self triggerMode]		forKey: OROscTriggerMode];
    [anEncoder encodeFloat: [self triggerPos ]		forKey: OROscTriggerPos];
    [anEncoder encodeBool: [self triggerSlopeIsPos ]    forKey: OROscTriggerSlopeIsPos];
    [anEncoder encodeInt: [self triggerSource]		forKey: OROscTriggerSource];
}


- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableArray* array;
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    int i;
    array = [NSMutableArray arrayWithCapacity:[self numberChannels]];
    for ( i = 0; i < [self numberChannels]; i++ ) [array addObject:[NSNumber numberWithBool:[self chnlAcquire: i]]];
    [objDictionary setObject:array forKey:@"chnlAcquire"];
    
    array = [NSMutableArray arrayWithCapacity:[self numberChannels]];
    for ( i = 0; i < [self numberChannels]; i++ ) [array addObject:[NSNumber numberWithInt:[self chnlCoupling: i]]];
    [objDictionary setObject:array forKey:@"chnlCoupling"];
    
    array = [NSMutableArray arrayWithCapacity:[self numberChannels]];
	for ( i = 0; i < [self numberChannels]; i++ ) [array addObject:[NSNumber numberWithFloat:[self chnlPos: i]]];
    [objDictionary setObject:array forKey:@"chnlPos"];
	
    array = [NSMutableArray arrayWithCapacity:[self numberChannels]];
	for ( i = 0; i < [self numberChannels]; i++ ) [array addObject:[NSNumber numberWithFloat:[self chnlScale: i]]];
    [objDictionary setObject:array forKey:@"chnlScale"];
	
    [objDictionary setObject:[NSNumber numberWithFloat:[self horizontalPos]] forKey:@"horizontalPos"];
    [objDictionary setObject:[NSNumber numberWithFloat:[self horizontalScale]] forKey:@"horizontalScale"];
    [objDictionary setObject:[NSNumber numberWithLong:[self waveformLength]] forKey:@"waveformLength"];
    [objDictionary setObject:[NSNumber numberWithInt:[self triggerCoupling]] forKey:@"triggerCoupling"];
    [objDictionary setObject:[NSNumber numberWithFloat:[self triggerLevel]] forKey:@"triggerLevel"];
    [objDictionary setObject:[NSNumber numberWithInt:[self triggerMode]] forKey:@"triggerMode"];
    [objDictionary setObject:[NSNumber numberWithFloat:[self triggerPos]] forKey:@"triggerPos"];
    [objDictionary setObject:[NSNumber numberWithBool:[self triggerSlopeIsPos]] forKey:@"triggerSlopeIsPos"];
    [objDictionary setObject:[NSNumber numberWithInt:[self triggerSource]] forKey:@"triggerSource"];
    [objDictionary setObject:[NSNumber numberWithLong:[self scopeType]] forKey:@"oscModel"];
    [objDictionary setObject:[NSNumber numberWithLong:[self scopeVersion]] forKey:@"oscVersion"];
	
    return objDictionary;
}


//--------------------------------------------------------------------------------
// Abstract methods that must be overridden in derived class.  
//--------------------------------------------------------------------------------

#pragma mark ***Abstract - General;
- (short)	oscScopeId { return( -1 ); }
- (bool) 	oscBusy { return true; }
- (long)	oscGetDateTime { return( 0 ); }
- (void)	oscSetDateTime: (long) aTime {}
- (void)	oscLockPanel: (bool) aFlag {}
- (void)	oscResetOscilloscope {}
- (void)	oscSendTextMessage: (NSString*) aMessage {}
- (void)	oscSetQueryFormat: (short) aFormat {}
- (void)	oscSetScreenDisplay: (bool) aDisplayOn {}

#pragma mark ***Abstract - Channel
- (void) 	oscGetChnlAcquire: (short) aChnl {}
- (void) 	oscSetChnlAcquire {} 
- (void)	oscGetChnlCoupling: (short) aChnl {}
- (void)	oscSetChnlCoupling: (short) aChnl {}
- (void)	oscGetChnlPos: (short) aChnl {}
- (void)	oscSetChnlPos: (short) aChnl {}
- (void)	oscGetChnlScale: (short) aChnl {}
- (void)	oscSetChnlScale: (short) aChnl {}

#pragma mark ***Abstract Methods - Horizontal settings
- (void)	oscGetHorizontalPos {}
- (void)	oscSetHorizontalPos {}
- (void)	oscGetHorizontalScale {}
- (void)	oscSetHorizontalScale {}
- (void)	oscGetWaveformRecordLength {}
- (void)	oscSetWaveformRecordLength {}

#pragma mark ***Abstract Methods - Trigger
- (void)	oscGetTriggerCoupling {}
- (void)	oscSetTriggerCoupling {}
- (void)	oscGetTriggerLevel {}
- (void)	oscSetTriggerLevel {}
- (void)	oscGetTriggerMode {}
- (void)	oscSetTriggerMode {}
- (void)	oscGetTriggerPos {}
- (void)	oscSetTriggerPos {}
- (void)	oscGetTriggerSlopeIsPos {}
- (void)	oscSetTriggerSlopeIsPos {}
- (void)	oscGetTriggerSource {}
- (void)	oscSetTriggerSource {}

#pragma mark ***Abstract Methods - Data Acquisition
- (void)	oscArmScope {}
- (void)	oscRunOsc: (NSString*) aMsg {}
- (void)	oscSetAcqMode: (short) aMode {}
- (void)	oscSetDataReturnMode {}
- (void)	oscStopAcquisition {}

@end
