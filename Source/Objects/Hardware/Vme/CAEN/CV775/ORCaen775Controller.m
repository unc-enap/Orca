//--------------------------------------------------------------------------------
// CLASS:		ORCaen775Controller
// Purpose:		Handles the interaction between the user and the VC775 module.
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
#import "ORCaen775Controller.h"
#import "ORCaenDataDecoder.h"
#import "ORCaen775Model.h"


@implementation ORCaen775Controller
#pragma mark ***Initialization
//--------------------------------------------------------------------------------
/*!
 * \method	init
 * \brief	Initialize interface with hardware object.
 * \note	
 */
//--------------------------------------------------------------------------------
- (id) init
{
    self = [ super initWithWindowNibName: @"Caen775" ];
    return self;
}

- (void) awakeFromNib 
{
	int i;
	for(i=0;i<16;i++){
		[[onlineMaskMatrixA cellAtRow:i column:0] setTag:i];
		[[onlineMaskMatrixB cellAtRow:i column:0] setTag:i+16];
		[[thresholdA cellAtRow:i column:0] setTag:i];
		[[thresholdB cellAtRow:i column:0] setTag:i+16];
	}
	[super awakeFromNib];
}
#pragma mark •••Notifications
//--------------------------------------------------------------------------------
/*!\method  registerNotificationObservers
 * \brief	Register notices that we want to receive.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) registerNotificationObservers
{
    [ super registerNotificationObservers ];
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver : self
                     selector : @selector(modelTypeChanged:)
                         name : ORCaen775ModelModelTypeChanged
						object: model];

	[notifyCenter addObserver : self
					 selector : @selector(onlineMaskChanged:)
						 name : ORCaen775ModelOnlineMaskChanged
					   object : model];
    [notifyCenter addObserver : self
                     selector : @selector(commonStopModeChanged:)
                         name : ORCaen775ModelCommonStopModeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(fullScaleRangeChanged:)
                         name : ORCaen775ModelFullScaleRangeChanged
						object: model];

}

#pragma mark ***Interface Management

- (void) fullScaleRangeChanged:(NSNotification*)aNote
{
	[fullScaleRangeTextField setIntValue: [model fullScaleRange]];
}
- (void) commonStopModeChanged:(NSNotification*)aNote
{
	[commonStopModeMatrix selectCellWithTag: [model commonStopMode]];
}

- (void) updateWindow
{
	[ super updateWindow ];
	[self modelTypeChanged:nil];
	[self commonStopModeChanged:nil];
	[self onlineMaskChanged:nil];
	[[self window] setTitle:[NSString stringWithFormat:@"%@",[model identifier]]];
	[self fullScaleRangeChanged:nil];
}

- (void) modelTypeChanged:(NSNotification*)aNote
{
	[modelTypePU selectItemAtIndex: [model modelType]];
	if([model modelType] == kModel775){
		[thresholdB setEnabled:YES];
		[stepperB setEnabled:YES];
		[onlineMaskMatrixB setEnabled:YES];
	}
	else {
		[thresholdB setEnabled:NO];
		[stepperB setEnabled:NO];
		[onlineMaskMatrixB setEnabled:NO];
	}
	[[self window] setTitle:[NSString stringWithFormat:@"%@",[model identifier]]];
}

- (void) onlineMaskChanged:(NSNotification*)aNotification
{
	short i;
	uint32_t theMask = [model onlineMask];
	for(i=0;i<16;i++){
		[[onlineMaskMatrixA cellWithTag:i] setIntValue:(theMask&(1<<i))!=0];
		[[onlineMaskMatrixB cellWithTag:i+16] setIntValue:(theMask&(1<<(i+16)))!=0];
	}
}

- (void) thresholdLockChanged:(NSNotification*)aNotification
{    
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[self thresholdLockName]];
    BOOL locked = [gSecurity isLocked:[self thresholdLockName]];

	[modelTypePU setEnabled:!runInProgress];
	[commonStopModeMatrix setEnabled:!runInProgress];
    [thresholdLockButton setState: locked];
    
	if([model modelType] == kModel775){
		[onlineMaskMatrixB setEnabled:!lockedOrRunningMaintenance];
		[thresholdB setEnabled:!lockedOrRunningMaintenance];
		[stepperB setEnabled:!lockedOrRunningMaintenance];
	}
	else {
		[onlineMaskMatrixB setEnabled:NO];
		[thresholdB setEnabled:NO];
		[stepperB setEnabled:NO];
	}
	[onlineMaskMatrixA setEnabled:!lockedOrRunningMaintenance];
	[thresholdA setEnabled:!lockedOrRunningMaintenance];
	[stepperA setEnabled:!lockedOrRunningMaintenance];
	
    [thresholdWriteButton setEnabled:!lockedOrRunningMaintenance];
    [thresholdReadButton setEnabled:!lockedOrRunningMaintenance]; 
    [initBoardButton setEnabled:!lockedOrRunningMaintenance]; 
	[fullScaleRangeTextField setEnabled:!lockedOrRunningMaintenance]; 
	
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
		if(runInProgress && ![gSecurity isLocked:[self thresholdLockName]])s = @"Not in Maintenance Run.";
    }
    [thresholdLockDocField setStringValue:s];
}

- (NSSize) thresholdDialogSize
{
	return NSMakeSize(310,640);
}
#pragma mark ***Interface Management - Module specific
- (NSString*) thresholdLockName {return @"ORCaen775ThresholdLock";}
- (NSString*) basicLockName     {return @"ORCaen775BasicLock";}

#pragma mark •••Actions

- (void) fullScaleRangeTextFieldAction:(id)sender
{
	[model setFullScaleRange:[sender intValue]];	
}
- (void) commonStopModeAction:(id)sender
{
	[model setCommonStopMode:[[sender selectedCell] tag]];	
}

- (void) modelTypePUAction:(id)sender
{
	[model setModelType:(int)[sender indexOfSelectedItem]];
}

- (IBAction) onlineAction:(id)sender
{
	[model setOnlineMaskBit:(int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) initBoardAction:(id)sender
{
	@try {
		[self endEditing];
		[model initBoard];
	}
	@catch(NSException* localException) {
		ORRunAlertPanel([localException name], @"%@\nInit of %@ failed", @"OK", nil, nil,
                        localException,[model identifier]);

	}
}

@end
