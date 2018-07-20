//--------------------------------------------------------------------------------
// CLASS:		ORCaen785Controller
// Purpose:		Handles the interaction between the user and the VC785 module.
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
#import "ORCaen785Controller.h"
#import "ORCaenDataDecoder.h"
#import "ORCaen785Model.h"


@implementation ORCaen785Controller
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
    self = [ super initWithWindowNibName: @"Caen785" ];
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
#pragma mark ¥¥¥Notifications
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
                         name : ORCaen785ModelModelTypeChanged
						object: model];
	
	[notifyCenter addObserver : self
					 selector : @selector(onlineMaskChanged:)
						 name : ORCaen785ModelOnlineMaskChanged
					   object : model];
}

#pragma mark ***Interface Management
- (void) updateWindow
{
	[super updateWindow];
	[self modelTypeChanged:nil];
    [self onlineMaskChanged:nil];
}

- (void) thresholdLockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL locked = [gSecurity isLocked:[self thresholdLockName]];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[self thresholdLockName]];
  	[modelTypePU setEnabled:!runInProgress];
  
    [resetButton setEnabled:!locked && !runInProgress];
	if([model modelType] == kModel785){
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
    
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
		if(runInProgress && ![gSecurity isLocked:[self thresholdLockName]])s = @"Not in Maintenance Run.";
    }
    [thresholdLockDocField setStringValue:s];
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

- (void) modelTypeChanged:(NSNotification*)aNote
{
	[modelTypePU selectItemAtIndex: [model modelType]];
	if([model modelType] == kModel785){
		[thresholdB setEnabled:YES];
		[onlineMaskMatrixB setEnabled:YES];
	}
	else {
		[thresholdB setEnabled:NO];
		[onlineMaskMatrixB setEnabled:NO];
	}
	[[self window] setTitle:[NSString stringWithFormat:@"%@",[model identifier]]];
}

#pragma mark ***Interface Management - Module specific
- (NSString*) thresholdLockName {return @"ORCaen785ThresholdLock";}
- (NSString*) basicLockName     {return @"ORCaen785BasicLock";}

- (NSSize) thresholdDialogSize
{
	return NSMakeSize(370,607);
}
#pragma mark ¥¥¥Actions
- (void) modelTypePUAction:(id)sender
{
	[model setModelType:(int)[sender indexOfSelectedItem]];
}

- (IBAction) onlineAction:(id)sender
{
	[model setOnlineMaskBit:(int)[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) resetAction:(id)sender
{
	@try {
		[model reset];
	}
	@catch (NSException* localException){
        NSLog(@"Reset of CV785 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed CV785 Reset", @"OK", nil, nil,
                        localException);
	}
}

@end
