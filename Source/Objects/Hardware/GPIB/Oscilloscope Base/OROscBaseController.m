//--------------------------------------------------------------------------------
// CLASS:		OROscBaseController
// Purpose:		Handles the interaction between the user and the base CAEN module.
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
#import "OROscBaseController.h"
#import "OROscBaseModel.h"

@implementation OROscBaseController

#pragma mark ***Initialization
//--------------------------------------------------------------------------------
/*!\method  initWithWindowNibName
 * \brief	Initialize the window using the nib file.
 * \param	aNibName			- The name of the nib object.
 * \note	
 */
//--------------------------------------------------------------------------------
- (id) initWithWindowNibName: (NSString*) aNibName
{
    self = [ super initWithWindowNibName: aNibName ];
    return self;
}

//--------------------------------------------------------------------------------
/*!\method  dealloc
 * \brief	Just calls super dealloc
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) dealloc
{
    [ super dealloc ];
}

//--------------------------------------------------------------------------------
/*!\method  awakeFromNib
 * \brief	Initializes object after everything is loaded.  Populates the
 *			pulldown menus, registers to receive notifications and updates
 *			the GUI.
 * \note	Since this is a sub class must call base classes awakeFromNib.
 */
//--------------------------------------------------------------------------------
- (void) awakeFromNib
{
    [ self populatePullDownsOscBase ];
    [ super awakeFromNib ];
    //[ mModelReflectsHardware setStringValue: [ NSString stringWithFormat: @"Dialog may not match hardware." ] ];
}

//#pragma mark ***Accessors
//- (NSMatrix*)	chnlAcquire
//{
//    return( mChnlAcquire );
//}

//--------------------------------------------------------------------------------
/*!\method  setModel
 * \brief	overridden to set the title of the scope dialog with the scope type and 
 *			gpid address.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) setModel: (id) aModel
{
	[ super setModel: aModel ];
	[ self  setTitle ];
}


//--------------------------------------------------------------------------------
/*!\method  setTitle
 * \brief	Set the title of the dialog using the identifier from the GPIB unit.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) setTitle
{
	NSMutableString* title = [ NSMutableString stringWithString: @"Oscilloscope" ];
	NSString* s = [model gpibIdentifier ];
	
    // Parse string to get device name.
	if( [ s length ] ) {
		NSScanner* scanner = [ NSScanner scannerWithString: s ];
        
		NSString* theShortName;
		NSCharacterSet* commaSet = [ NSCharacterSet characterSetWithCharactersInString: @"," ];
		[ scanner scanUpToCharactersFromSet: commaSet intoString: nil ];
		[ scanner setScanLocation: [ scanner scanLocation ] +1 ];
		if( [ scanner scanUpToCharactersFromSet: commaSet intoString: &theShortName ] ){
			[ title appendFormat: @" %@", theShortName ];
		}
	}
    
    // Determine if device is connected.  If yes add address to name.	
	if( [model connected ] )[ title appendFormat: @" (GPIB %d)", [model primaryAddress ]];
	else [ title appendString:@" (Not Connected)"];
	[[ self window ] setTitle: title ];
}


#pragma mark ***Notifications
//--------------------------------------------------------------------------------
/*!\method  registerNotificationObservers
 * \brief	Register notices that we want to receive.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];
    
    // Register for the acquisition mode of a channel being changed.
    [super registerNotificationObservers];
    [ notifyCenter addObserver: self
                      selector: @selector( oscChnlAcquireChanged: )
                          name: OROscChnlAcqChangedNotification
                        object: model];
    
    [ notifyCenter addObserver: self
                      selector: @selector( oscChnlCouplingChanged: )
                          name: OROscChnlCouplingChangedNotification
                        object: model];
    
    [ notifyCenter addObserver: self
                      selector: @selector( oscChnlPosChanged: )
                          name: OROscChnlPosChangedNotification
                        object: model];
    
    [ notifyCenter addObserver: self
                      selector: @selector( oscChnlScaleChanged: )
                          name: OROscChnlScaleChangedNotification
                        object: model];
    
    // Register for horizontal parameters changing.
    [ notifyCenter addObserver: self
                      selector: @selector( oscHorizPosChanged: )
                          name: OROscHorizPosChangedNotification
                        object: model];
    
    [ notifyCenter addObserver: self
                      selector: @selector( oscHorizRecordLengthChanged: )
                          name: OROscPulseLengthChangedNotification
                        object: model];
    
    [ notifyCenter addObserver: self
                      selector: @selector( oscHorizScaleChanged: )
                          name: OROscHorizScaleChangedNotification
                        object: model];
    
    
    // Register for trigger parameters changing.
    [ notifyCenter addObserver: self
                      selector: @selector( oscTriggerCouplingChanged: )
                          name: OROscTriggerCouplingChangedNotification
                        object: model];
    
    [ notifyCenter addObserver: self
                      selector: @selector( oscTriggerLevelChanged: )
                          name: OROscTriggerLevelChangedNotification
                        object: model];
    
    [ notifyCenter addObserver: self
                      selector: @selector( oscTriggerModeChanged: )
                          name: OROscTriggerModeChangedNotification
                        object: model];
    
    [ notifyCenter addObserver: self
                      selector: @selector( oscTriggerPolarityChanged: )
                          name: OROscTriggerSlopeChangedNotification
                        object: model];
    
    [ notifyCenter addObserver: self
                      selector: @selector( oscTriggerPosChanged: )
                          name: OROscTriggerPosChangedNotification
                        object: model];
    
    [ notifyCenter addObserver: self
                      selector: @selector( oscTriggerSourceChanged: )
                          name: OROscTriggerSourceChangedNotification
                        object: model];
    
    // Register for messsage that model reflects oscilloscope hardware.
    [ notifyCenter addObserver: self
                      selector: @selector( oscModelReflectsHardwareChanged: )
                          name: OROscModelReflectsHardwareChangedNotification
                        object: model];
    
    
    [ notifyCenter addObserver: self
                      selector: @selector( settingsLockChanged: )
                          name: ORRunStatusChangedNotification
                        object: nil];
    
    [ notifyCenter addObserver: self
                      selector: @selector( gpibLockChanged: )
                          name: ORRunStatusChangedNotification
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : [self settingsLockName]
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(gpibLockChanged:)
                         name : [self gpibLockName]
                        object: nil];
    
    
}

- (NSString*) settingsLockName
{
    //subclasses should override and use their own lock
    return @"OROscGenericLock";
}

- (NSString*) gpibLockName
{
    //subclasses should override and use their own lock
    return @"OROscGenericGpibLock";
}


#pragma mark ***Interface Management
//--------------------------------------------------------------------------------
/*!\method  updateWindow
 * \brief	Sets all GUI values to current model values.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) updateWindow
{
    short		i;
    
    // Do initialization of message indicating whether dialog reflects hardware    
    [ super updateWindow ];
    
    // Loop through all vertical scale parameters and reset them.
    for ( i = 0; i < [model numberChannels]; i++ ){
        
        // Create dictionary item with channel number.
        NSMutableDictionary* userInfo = [ NSMutableDictionary dictionary ];
        [ userInfo setObject: [ NSNumber numberWithInt: i ] forKey: OROscChnl ]; 
        // Send out notification for each channel parameter.
        [[ NSNotificationCenter defaultCenter ]
		 postNotificationName: OROscChnlAcqChangedNotification
		 object: model
		 userInfo: userInfo ];
        
        [[ NSNotificationCenter defaultCenter ]
		 postNotificationName: OROscChnlCouplingChangedNotification
		 object: model
		 userInfo: userInfo ];
        
        [[ NSNotificationCenter defaultCenter ]
		 postNotificationName: OROscChnlPosChangedNotification
		 object: model
		 userInfo: userInfo ];
        
        [[ NSNotificationCenter defaultCenter ]
		 postNotificationName: OROscChnlScaleChangedNotification
		 object: model
		 userInfo: userInfo ];
    }
    
    // Do initialization of Horizontal parameters
    [ self oscHorizPosChanged: nil ];
    [ self oscHorizRecordLengthChanged: nil ];
    [ self oscHorizScaleChanged: nil ];
    
    // Do initialization of trigger parameters
    [ self oscTriggerCouplingChanged: nil ];
    [ self oscTriggerLevelChanged: nil ];
    [ self oscTriggerModeChanged: nil ];
    [ self oscTriggerPolarityChanged: nil ];
    [ self oscTriggerPosChanged: nil ];
    [ self oscTriggerSourceChanged: nil ];
    
    // Initialize message about model reflecting hardware
    //    [ self oscModelReflectsHardwareChanged: nil ];
    
    [self settingsLockChanged:nil];
    [self gpibLockChanged:nil];
}

#pragma mark ***Interface Management - Channels
//--------------------------------------------------------------------------------
/*!\method  oscChnlAcquireChanged
 * \brief	Have received notification that acquire value has changed.  Update
 *			the interface.
 * \param	aNotification			- The notification object.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscChnlAcquireChanged: (NSNotification*) aNotification
{
	// Get the channel that changed and then set the GUI value using the model value.
	int chnl = [[[ aNotification userInfo ] objectForKey: OROscChnl ] intValue ];
	[[ mChnlAcquire cellWithTag: chnl ] setIntValue: [model chnlAcquire: chnl ]];
}


//--------------------------------------------------------------------------------
/*!\method  oscChnlCouplingChanged
 * \brief	Have received notification that coupling value has changed.  Update
 *			the interface.
 * \param	aNotification			- The notification object.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscChnlCouplingChanged: (NSNotification*) aNotification
{    
	// Get the channel that changed and then set the GUI value using the model value.
	int chnl = [[[ aNotification userInfo ] objectForKey: OROscChnl ] intValue ];
	switch( chnl )
	{
		case 0:
			[ mChnlCoupling0 selectItemAtIndex: [model chnlCoupling: chnl ]];
			break;
			
		case 1:
			[ mChnlCoupling1 selectItemAtIndex: [model chnlCoupling: chnl ]];
			break;
			
		case 2:
			[ mChnlCoupling2 selectItemAtIndex: [model chnlCoupling: chnl ]];
			break;
			
		case 3:
			[ mChnlCoupling3 selectItemAtIndex: [model chnlCoupling: chnl ]];
			break;                
	}
}

//--------------------------------------------------------------------------------
/*!\method  connectionChanged
 * \brief	Reacts to connection established message and updates GUI.
 * \param	aNotification		- The message that was sent out.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) connectionChanged: (NSNotification*) aNotification
{
	[super connectionChanged:aNotification];
	[self setTitle];
}


//--------------------------------------------------------------------------------
/*!\method  oscChnlPosChanged
 * \brief	Have received notification that vertical position has changed.  Update
 *			the interface.
 * \param	aNotification			- The notification object.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscChnlPosChanged: (NSNotification*) aNotification
{
	// Get the channel that changed and then set the GUI value using the model value.
	int chnl = [[[ aNotification userInfo ] objectForKey: OROscChnl ] intValue ];
	[[ mChnlPos cellWithTag: chnl ] setFloatValue: [model chnlPos: chnl ]];
	[[ mChnlPosSteppers cellWithTag: chnl ] setFloatValue: [model chnlPos: chnl ]];
}

//--------------------------------------------------------------------------------
/*!\method  oscChnlScaleChanged
 * \brief	Have received notification that vertical scale has changed.  Update
 *			the interface.
 * \param	aNotification			- The notification object.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscChnlScaleChanged: (NSNotification*) aNotification
{
	// Get the channel that changed and then set the GUI value using the model value.
	int chnl = [[[ aNotification userInfo ] objectForKey: OROscChnl ] intValue ];
	[[ mChnlScale cellWithTag: chnl ] setFloatValue: [model chnlScale: chnl ]];
	[[ mChnlScaleSteppers cellWithTag: chnl ] setFloatValue: [model chnlScale: chnl ]];
}

#pragma mark ***Interface Management - Horizontal parameters
//--------------------------------------------------------------------------------
/*!\method  oscHorizPosChanged
 * \brief	Have received notification that horizontal position has changed.  Update
 *			the interface.
 * \param	aNotification			- The notification object.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscHorizPosChanged: (NSNotification*) aNotification
{
	// Now the value of the interface.
	[ mHorizPos setFloatValue: [model horizontalPos ]];
	[ mHorizPosStepper setFloatValue: [model horizontalPos ]];
}

//--------------------------------------------------------------------------------
/*!\method  oscHorizRecordLengthChanged
 * \brief	Have received notification record length has changed.  Update
 *			the interface.
 * \param	aNotification			- The notification object.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscHorizRecordLengthChanged: (NSNotification*) aNotification
{
	int32_t value = [model waveformLength ];
	if(value == 0)value = 500;
	[mRecordLength selectItemWithTitle:[NSString stringWithFormat:@"%d",value]];
}

//--------------------------------------------------------------------------------
/*!\method  oscHorizScaleChanged
 * \brief	Have received notification that the horizontal scale or units have changed.
 *			Update the interface for both the units and the number.
 * \param	aNotification			- The notification object.
 * \note	We must split the value obtained from the model into a number and exponent
 *			where the exponential part is seconds, millisecs., microsecs., or
 *			nanosecs. 
 */
//--------------------------------------------------------------------------------
- (void) oscHorizScaleChanged: (NSNotification*) aNotification
{
    float	origScaleValue;
    int		exponent;
    int		units;
    
	
	// convert value to units plus modified scale value in those units.
	origScaleValue = [model horizontalScale ];
	exponent = floor( log10( origScaleValue ) );
	units = ( abs( exponent ) + 2 ) / 3;
	
	// Set the GUI
	[ mHorizScale setFloatValue:  origScaleValue * pow( 10.000, (units) * 3 ) ];
	[ mHorizUnits selectCellWithTag: units ];	                
    
}

#pragma mark ***Interface Management - Trigger parameters
//--------------------------------------------------------------------------------
/*!\method  oscTriggerCouplingChanged
 * \brief	Have received notification that the trigger coupling has changed.
 *			Update the interface for both the units and the number.
 * \param	aNotification			- The notification object.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscTriggerCouplingChanged: (NSNotification*) aNotification
{
	
	[ mTriggerCoupling selectItemAtIndex: [model triggerCoupling ]];
}

//--------------------------------------------------------------------------------
/*!\method  oscTriggerLevelChanged
 * \brief	Have received notification that the trigger level has changed.
 *			Update the interface.
 * \param	aNotification			- The notification object.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscTriggerLevelChanged: (NSNotification*) aNotification
{
	[ mTriggerLevel setFloatValue: [model triggerLevel ]];
}

//--------------------------------------------------------------------------------
/*!\method  oscTriggerModeChanged
 * \brief	Have received notification that the trigger mode has changed.
 *			Update the interface.
 * \param	aNotification			- The notification object.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscTriggerModeChanged: (NSNotification*) aNotification
{
	[ mTriggerMode selectItemAtIndex: [model triggerMode ]];
}

//--------------------------------------------------------------------------------
/*!\method  oscTriggerPolarityChanged
 * \brief	Have received notification that the trigger polarity has changed.
 *			Update the interface.
 * \param	aNotification			- The notification object.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscTriggerPolarityChanged: (NSNotification*) aNotification
{
	if ( [model triggerSlopeIsPos ] )
		[ mTriggerPolarity selectCellWithTag: 1 ];	  
	else 
		[ mTriggerPolarity selectCellWithTag: 0 ];	          
}


//--------------------------------------------------------------------------------
/*!\method  oscTriggerPosChanged
 * \brief	Have received notification that the trigger position has changed.
 *			Update the interface.
 * \param	aNotification			- The notification object.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscTriggerPosChanged: (NSNotification*) aNotification
{
	[ mTriggerPos setFloatValue: [model triggerPos ]];
	[ mTriggerPosStepper setFloatValue: [model triggerPos ]];
}

//--------------------------------------------------------------------------------
/*!\method  oscTriggerSourceChanged
 * \brief	Have received notification that the trigger source has changed.
 *			Update the interface.
 * \param	aNotification			- The notification object.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscTriggerSourceChanged: (NSNotification*) aNotification
{
	[ mTriggerSource selectItemAtIndex: [model triggerSource ]];
}

//--------------------------------------------------------------------------------
/*!\method  oscModelReflectsHardwareChange
 * \brief	Have received notification that model may reflect hardware
 * \param	aNotification			- The notification object.
 * \note	
 */
//--------------------------------------------------------------------------------
#pragma mark ***Interface Management - Misc
- (void) oscModelReflectsHardwareChanged: (NSNotification*) aNotification
{
	if ( [model modelReflectsHardware ] )
	{
		[ mModelReflectsHardware setStringValue: [ NSString stringWithFormat: @"" ] ];
	}
	else
	{
		[ mModelReflectsHardware setStringValue: [ NSString stringWithFormat: @"Dialog does not reflect oscilloscope hardware." ] ];
	}
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:[self settingsLockName] to:secure];
    [gSecurity setLock:[self gpibLockName] to:secure];
    
    [settingsLockButton setEnabled:secure];
    [gpibLockButton setEnabled:secure];
}

- (void) gpibLockChanged: (NSNotification*) aNotification
{
    BOOL locked		= [gSecurity isLocked:[self gpibLockName]];
    BOOL runInProgress  = [gOrcaGlobals runInProgress];
    
    [gpibLockButton setState: locked];
    
    [mConnectButton setEnabled: !locked && !runInProgress];
    [mPrimaryAddress setEnabled: !locked && !runInProgress];
    [mSecondaryAddress setEnabled: !locked && !runInProgress];
}

- (void) settingsLockChanged: (NSNotification*) aNotification
{
    BOOL runInProgress  = [gOrcaGlobals runInProgress];
    BOOL locked		= [gSecurity isLocked:[self settingsLockName]];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[self settingsLockName]];
    
    [settingsLockButton setState: locked];
    
    
    [mSetOscFromDialog setEnabled:!lockedOrRunningMaintenance];
    [mSetDialogFromOsc setEnabled:!lockedOrRunningMaintenance];
    [mAutoReset setEnabled:!lockedOrRunningMaintenance];
    
    [mChnlAcquire setEnabled:!locked];
    [mChnlCoupling0 setEnabled:!locked];
    [mChnlCoupling1 setEnabled:!locked];
    [mChnlCoupling2 setEnabled:!locked];
    [mChnlCoupling3 setEnabled:!locked];
    [mChnlPos setEnabled:!locked];
    [mChnlPosSteppers setEnabled:!locked];
    [mChnlScale setEnabled:!locked];   
    [mChnlScaleSteppers setEnabled:!locked];
    
    [mHorizUnits setEnabled:!locked];
    [mHorizScale setEnabled:!locked];
    [mHorizPos setEnabled:!locked];
    [mHorizPosStepper setEnabled:!locked];
    [mRecordLength setEnabled:!locked];
    
    [mTriggerCoupling setEnabled:!locked];
    [mTriggerLevel setEnabled:!locked];
    [mTriggerMode setEnabled:!locked];
    [mTriggerPolarity setEnabled:!locked];
    [mTriggerPos setEnabled:!locked];
    [mTriggerPosStepper setEnabled:!locked];
    [mTriggerSource setEnabled:!locked];
    
    
    
    
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
        if(runInProgress && ![gSecurity isLocked:[self settingsLockName]])s = @"Not in Maintenance Run.";
    }
    [settingsLockDocField setStringValue:s];
    
    
    [self setTitle];
    
}


#pragma mark ***Actions

- (IBAction) settingsLockAction:(id)sender
{
    [gSecurity tryToSetLock:[self settingsLockName] to:[sender intValue] forWindow:[self window]];
}

- (IBAction) gpibLockAction:(id)sender
{
    [gSecurity tryToSetLock:[self gpibLockName] to:[sender intValue] forWindow:[self window]];
}

//--------------------------------------------------------------------------------
/*!\method  chnlAcquireAction
 * \brief	One of the channels has changed value because user changed it.  This
 *			routine is called by user interface when the value changes.
 * \param	aSender			- The GUI element (in this case an NSMatrix object).
 * \note	
 */
//--------------------------------------------------------------------------------
- (IBAction) chnlAcquireAction: (id) aSender
{
    // NSMatrix which is aSender knows the intValue of the selected cell in the NSMatrix.
    if ( [ aSender intValue ] != [model chnlAcquire: [[ aSender selectedCell ] tag ]] ) 	
    {
        [[self undoManager] setActionName: @"Set Channel Acquire" ]; 			// set name of undo
        [model setChnlAcquire: [[ aSender selectedCell ] tag ] setting: [ aSender intValue ]];// Set new value.
    }    
}


//--------------------------------------------------------------------------------
/*!\method  chnlCouplingAction0
 * \brief	Channel 0 coupling has changed because user changed it.  This
 *			routine is called by user interface when the value changes.
 * \param	aSender			- The GUI element (in this case an NSMatrix object).
 * \note	
 */
//--------------------------------------------------------------------------------
- (IBAction) chnlCouplingAction0: (id) aSender
{
    [[ self undoManager ] setActionName: @"Set Channel Coupling0" ]; 			// set name of undo
    [model setChnlCoupling: 0 coupling: [ aSender indexOfSelectedItem ]];// Set new value.
}


//--------------------------------------------------------------------------------
/*!\method  chnlCouplingAction1
 * \brief	Channel 1 coupling has changed because user changed it.  This
 *			routine is called by user interface when the value changes.
 * \param	aSender			- The GUI element (in this case an NSMatrix object).
 * \note	
 */
//--------------------------------------------------------------------------------
- (IBAction) chnlCouplingAction1: (id) aSender
{
    [[ self undoManager ] setActionName: @"Set Channel Coupling0" ]; 			// set name of undo
    [model setChnlCoupling: 1 coupling: [ aSender indexOfSelectedItem ]];// Set new value.
}


//--------------------------------------------------------------------------------
/*!\method  chnlCouplingAction2
 * \brief	Channel 2 coupling has changed because user changed it.  This
 *			routine is called by user interface when the value changes.
 * \param	aSender			- The GUI element (in this case an NSMatrix object).
 * \note	
 */
//--------------------------------------------------------------------------------
- (IBAction) chnlCouplingAction2: (id) aSender
{
    [[ self undoManager ] setActionName: @"Set Channel Coupling0" ]; 			// set name of undo
    [model setChnlCoupling: 2 coupling: [ aSender indexOfSelectedItem ]];// Set new value.
}


//--------------------------------------------------------------------------------
/*!\method  chnlCouplingAction3
 * \brief	Channel 3 coupling has changed because user changed it.  This
 *			routine is called by user interface when the value changes.
 * \param	aSender			- The GUI element (in this case an NSMatrix object).
 * \note	
 */
//--------------------------------------------------------------------------------
- (IBAction) chnlCouplingAction3: (id) aSender
{
    [[ self undoManager ] setActionName: @"Set Channel Coupling0" ]; 			// set name of undo
    [model setChnlCoupling: 3 coupling: [ aSender indexOfSelectedItem ]];// Set new value.
}


//--------------------------------------------------------------------------------
/*!\method  chnlPosAction
 * \brief	One of the channels has changed value because user changed it.  This
 *			routine is called by user interface when the value changes.
 * \param	aSender			- The GUI element (in this case an NSMatrix object).
 * \note	
 */
//--------------------------------------------------------------------------------
- (IBAction) chnlPosAction: (id) aSender
{
    // NSMatrix which is aSender knows the intValue of the selected cell in the NSMatrix.
    if ( [ aSender floatValue ] != [model chnlPos: [[ aSender selectedCell ] tag ]] ) 	
    {
        [[self undoManager] setActionName: @"Set Channel Position" ]; 			// set name of undo
        [model setChnlPos: [[ aSender selectedCell ] tag ] position: [ aSender floatValue ]];// Set new value.
    }    
}

//--------------------------------------------------------------------------------
/*!\method  chnlScaleAction
 * \brief	One of the channels has changed value because user changed it.  This
 *			routine is called by user interface when the value changes.
 * \param	aSender			- The GUI element (in this case an NSMatrix object).
 * \note	
 */
//--------------------------------------------------------------------------------
- (IBAction) chnlScaleAction: (id) aSender
{
    // NSMatrix which is aSender knows the intValue of the selected cell in the NSMatrix.
    if ( [ aSender floatValue ] != [model chnlScale: [[ aSender selectedCell ] tag ]] ) 	
    {
        [[self undoManager] setActionName: @"Set Channel Acquire" ]; 			// set name of undo
        [model setChnlScale: [[ aSender selectedCell ] tag ] scale: [ aSender floatValue ]];// Set new value.
    }    
}

#pragma mark ***Actions - Horizontal
//--------------------------------------------------------------------------------
/*!\method  horizPosAction
 * \brief	The horizontal position of the scope trace has changed.
 * \param	aSender			- The GUI element (in this case an text field object or
 *							  stepper field.).
 * \note	
 */
//--------------------------------------------------------------------------------
- (IBAction) horizPosAction: (id) aSender
{
    if ( [ aSender floatValue ] != [model horizontalPos ] )
    {
        [[self undoManager] setActionName: @"Set horiz pos." ]; // set name of undo
        
        [model setHorizontalPos: [ aSender floatValue ]];
    }
}

//--------------------------------------------------------------------------------
/*!\method  horizScaleAction
 * \brief	The scale factor has changed so the the factor, combine it with the
 *			existing units reading and change the model with the actual scale
 *			factor in seconds (seconds / division).
 * \param	aSender			- The GUI element which is a text field.
 * \note	
 */
//--------------------------------------------------------------------------------
- (IBAction) horizScaleAction: (id) aSender
{
    int		exponent;
    float	value;
    
    [[self undoManager] setActionName: @"Set horiz scale " ]; // set name of undo
    
    // We have to calculate the seconds/division based on the units and the number in the GUI.
	exponent = -1.0 * ( [[ mHorizUnits selectedCell ] tag ] ) * 3;
    value = [ aSender floatValue ] * pow( 10.000, exponent );
    
    // Set the new value.
    [model setHorizontalScale: value ];
}

//--------------------------------------------------------------------------------
/*!\method  horizUnitsAction
 * \brief	The units have changed so get the new units, combine it with the
 *			existing scale reading and change the model with the actual scale
 *			factor in seconds (seconds / division).
 * \param	aSender			- The GUI element (in this case an NSMatrix object).
 * \note	
 */
//--------------------------------------------------------------------------------
- (IBAction) horizUnitsAction: (id) aSender
{
    float 	value;
    float	exponent;
    
    [[self undoManager] setActionName: @"Set horiz scale " ]; // set name of undo
    
    // We have to calculate the seconds/division based on the units and the number in the GUI.
    exponent = -1.0 * [[ aSender selectedCell ] tag ] * 3;
    value = [ mHorizScale floatValue ] * pow( 10.000, exponent );
    
    // Set new value    
    [model setHorizontalScale: value ];
}


//--------------------------------------------------------------------------------
/*!\method  horizRecordLengthAction
 * \brief	The record length has changed.  This routine is called by the user 
 * 			interface when the value changes.
 * \param	aSender			- The GUI element - in this case the NSPopUpButton.
 * \note	
 */
//--------------------------------------------------------------------------------
- (IBAction) horizRecordLengthAction: (id) aSender
{
    int32_t	value = 1000;
    
    [[self undoManager] setActionName: @"Set Record Length" ]; // set name of undo
    
    // Get the actual value of the record length and pass it to model.
	value = [[ aSender titleOfSelectedItem ] intValue];
	if(value == 0)value = 500;
    
    [model setWaveformLength: value ]; // Set new value.
}

#pragma mark ***Actions - Trigger
//--------------------------------------------------------------------------------
/*!\method  triggerCouplingAction
 * \brief	The trigger coupling has changed because user changed it.  This
 *			routine is called by user interface when the value changes.
 * \param	aSender			- The GUI element - in this case the NSPopUpButton.
 * \note	
 */
//--------------------------------------------------------------------------------
- (IBAction) triggerCouplingAction: (id) aSender
{
    if ( [ aSender indexOfSelectedItem ] != [model triggerCoupling ] )
    {
        // set name of undo        
        [[self undoManager] setActionName: @"Set trigger Coupling" ]; 
        [model setTriggerCoupling: [ aSender indexOfSelectedItem ]];// Set new value. 
    }
}

//--------------------------------------------------------------------------------
/*!\method  triggerLevelAction
 * \brief	The trigger level has changed because user changed it.  This
 *			routine is called by user interface when the value changes.
 * \param	aSender			- The GUI element - in this case the NSTextField.
 * \note	
 */
//--------------------------------------------------------------------------------
- (IBAction) triggerLevelAction: (id) aSender
{
    if ( [ aSender floatValue ] != [model triggerLevel ] )
    {
        [[self undoManager] setActionName: @"Set trigger level" ]; // set name of undo
        [model setTriggerLevel: [ aSender floatValue ]];// Set new value.         
    }
}

//--------------------------------------------------------------------------------
/*!\method  triggerModeAction
 * \brief	The trigger mode has changed because user changed it.  This
 *			routine is called by user interface when the value changes.
 * \param	aSender			- The GUI element - in this case the NSPopUpButton.
 * \note	
 */
//--------------------------------------------------------------------------------
- (IBAction) triggerModeAction: (id) aSender
{
    if ( [ aSender indexOfSelectedItem ] != [model triggerMode ] )
    {
        [[self undoManager] setActionName: @"Set trigger Mode" ]; // set name of undo
        [model setTriggerMode: [ aSender indexOfSelectedItem ]];// Set new value. 
    }
}

//--------------------------------------------------------------------------------
/*!\method  triggerPolarityAction
 * \brief	The trigger polarity has changed because user changed it.  This
 *			routine is called by user interface when the value changes.
 * \param	aSender			- The GUI element - in this case the NSMatrix.
 * \note	
 */
//--------------------------------------------------------------------------------
- (IBAction) triggerPolarityAction: (id) aSender
{
    bool	tmpValue = false;
    if ( [[ aSender selectedCell ] tag ] == 1 ) tmpValue = true;
    
    if ( tmpValue != [model triggerSlopeIsPos ] )
    {
        [[self undoManager] setActionName: @"Set trigger Mode" ]; // set name of undo
        [model setTriggerSlopeIsPos: tmpValue ];
    }
}

//--------------------------------------------------------------------------------
/*!\method  triggerPosAction
 * \brief	The trigger position has changed because user changed it.  This
 *			routine is called by user interface when the value changes.
 * \param	aSender			- The GUI element - in this case the NSPopUpButton.
 * \note	
 */
//--------------------------------------------------------------------------------
- (IBAction) triggerPosAction: (id) aSender
{
    if ( [ aSender floatValue ] != [model triggerPos ] )
    {
        [[self undoManager] setActionName: @"Set trigger Pos" ]; // set name of undo
        [model setTriggerPos: [ aSender floatValue ]];// Set new value.         
    }
}

//--------------------------------------------------------------------------------
/*!\method  triggerSourceAction
 * \brief	The trigger source has changed because user changed it.  This
 *			routine is called by user interface when the value changes.
 * \param	aSender			- The GUI element - in this case the NSPopUpButton.
 * \note	
 */
//--------------------------------------------------------------------------------
- (IBAction) triggerSourceAction: (id) aSender
{
    if ( [ aSender indexOfSelectedItem ] != [model triggerSource ] )
    {
        [[self undoManager] setActionName: @"Set trigger Source" ]; // set name of undo
        [model setTriggerSource: [ aSender indexOfSelectedItem ]];// Set new value. 
    }
}

#pragma mark ***Commands
//--------------------------------------------------------------------------------
/*!\method  autoReset
 * \brief	Do an autoreset of the oscilloscope.
 * \param	aSender			- The auto reset button.
 * \note	
 */
//--------------------------------------------------------------------------------
- (IBAction) autoReset: (id) aSender
{
    [model oscResetOscilloscope ];
}

//--------------------------------------------------------------------------------
/*!\method  setDialogFromOsc
 * \brief	Read all standard parameters from the osc and set the dialog from the
 *			returned results.
 * \param	aSender			- The set dialog from Osc button.
 * \note	
 */
//--------------------------------------------------------------------------------
- (IBAction) setDialogFromOsc: (id) aSender
{
    @try {
        
        // Make sure that we are connected.
        if ( [model isConnected ] )
        {
            [ self endEditing ];
            [model setModelFromOsc ];
        }
        else
        {
            ORRunAlertPanel( @"GPIB Connection Fault", 
							@"Must first establish connection to GPIB device.", 
							@"OK", nil, nil );
        }
	}
	@catch(NSException* localException) {
		NSLog( @"Loading of oscilloscope parameters FAILED.\n" );
		ORRunAlertPanel( [ localException name ], @"Failed to load oscilloscope parameters.",
						@"OK", nil, nil );
	}
}


//--------------------------------------------------------------------------------
/*!\method  setOscFromDialog
 * \brief	Send current settings out to the oscilloscope.
 * \param	aSender			- The set Osc From Dialog button..
 * \note	
 */
//--------------------------------------------------------------------------------
- (IBAction) setOscFromDialog: (id) aSender
{
    @try {
        
        // Make sure that we are connected.
        if ( [model isConnected ] )
        {
            [ self endEditing ];
            [model setOscFromModel ];
        }
        else
        {
            ORRunAlertPanel( @"GPIB Connection Fault",
							@"Must first establish connection to GPIB device.", 
							@"OK", nil, nil );
        }
        
	}
	@catch(NSException* localException) {
		NSLog( @"Setting of oscilloscope parameters FAILED.\n" );
		ORRunAlertPanel( [ localException name ], @"Failed to set oscilloscope parameters.",
						@"OK", nil, nil );
	}
}

#pragma mark ***Support
//--------------------------------------------------------------------------------
/*!
 * \method  populatePullDownsOscBase
 * \brief	Populate the GPIB board pulldown and the primary address pulldown
 *			items.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) populatePullDownsOscBase
{
    
    // Remove all items from popup menus
    [ mChnlCoupling0 removeAllItems ];        
    [ mChnlCoupling1 removeAllItems ];        
    [ mChnlCoupling2 removeAllItems ];        
    [ mChnlCoupling3 removeAllItems ];        
    
    // Repopulate coupling options - Note that these must be inserted in sequence starting with 0.
    [ mChnlCoupling0 insertItemWithTitle: kCouplingChnlAC atIndex: kChnlCouplingACIndex ];
    [ mChnlCoupling0 insertItemWithTitle: kCouplingChnlDC atIndex: kChnlCouplingDCIndex ];
    [ mChnlCoupling0 insertItemWithTitle: kCouplingChnlGND atIndex: kChnlCouplingGNDIndex ];
    [ mChnlCoupling0 insertItemWithTitle: kCouplingChnlDC50 atIndex: kChnlCouplingDC50Index ];
    
    // Repopulate coupling options - Note that these must be inserted in sequence starting with 0.
    [ mChnlCoupling1 insertItemWithTitle: kCouplingChnlAC atIndex: kChnlCouplingACIndex ];
    [ mChnlCoupling1 insertItemWithTitle: kCouplingChnlDC atIndex: kChnlCouplingDCIndex ];
    [ mChnlCoupling1 insertItemWithTitle: kCouplingChnlGND atIndex: kChnlCouplingGNDIndex ];
    [ mChnlCoupling1 insertItemWithTitle: kCouplingChnlDC50 atIndex: kChnlCouplingDC50Index ];
    
    // Repopulate coupling options - Note that these must be inserted in sequence starting with 0.
    [ mChnlCoupling2 insertItemWithTitle: kCouplingChnlAC atIndex: kChnlCouplingACIndex ];
    [ mChnlCoupling2 insertItemWithTitle: kCouplingChnlDC atIndex: kChnlCouplingDCIndex ];
    [ mChnlCoupling2 insertItemWithTitle: kCouplingChnlGND atIndex: kChnlCouplingGNDIndex ];
    [ mChnlCoupling2 insertItemWithTitle: kCouplingChnlDC50 atIndex: kChnlCouplingDC50Index ];
    
    // Repopulate coupling options - Note that these must be inserted in sequence starting with 0.
    [ mChnlCoupling3 insertItemWithTitle: kCouplingChnlAC atIndex: kChnlCouplingACIndex ];
    [ mChnlCoupling3 insertItemWithTitle: kCouplingChnlDC atIndex: kChnlCouplingDCIndex ];
    [ mChnlCoupling3 insertItemWithTitle: kCouplingChnlGND atIndex: kChnlCouplingGNDIndex ];
    [ mChnlCoupling3 insertItemWithTitle: kCouplingChnlDC50 atIndex: kChnlCouplingDC50Index ];
}

@end
