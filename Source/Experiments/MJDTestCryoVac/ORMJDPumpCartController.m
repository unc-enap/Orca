
//
//  ORMJDPumpCartController.m
//  Orca
//
//  Created by Mark Howe on Mon Aug 13, 2012.
//  Copyright ¬© 2012 CENPA, University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


#pragma mark •••Imported Files
#import "ORMJDPumpCartController.h"
#import "ORMJDPumpCartModel.h"
#import "ORMJDPumpCartView.h"
#import "ORVacuumParts.h"
#import "ORMJDTestCryostat.h"

@implementation ORMJDPumpCartController
- (id) init
{
    self = [super initWithWindowNibName:@"MJDPumpCart"];
    return self;
}

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super dealloc];
}

- (void) awakeFromNib
{
	[subComponentsView setGroup:model];
	[testStandView0 setDelegate:(id)[model testCryoStat:0]];
	[testStandView1 setDelegate:(id)[model testCryoStat:1]];
	[testStandView2 setDelegate:(id)[model testCryoStat:2]];
	[testStandView3 setDelegate:(id)[model testCryoStat:3]];
	[testStandView4 setDelegate:(id)[model testCryoStat:4]];
	[testStandView5 setDelegate:(id)[model testCryoStat:5]];
	[testStandView6 setDelegate:(id)[model testCryoStat:6]];
	
	[testStandView0 setTag:0];
	[testStandView1 setTag:1];
	[testStandView2 setTag:2];
	[testStandView3 setTag:3];
	[testStandView4 setTag:4];
	[testStandView5 setTag:5];
	[testStandView6 setTag:6];
	
	testStandView[0] = testStandView0;
	testStandView[1] = testStandView1;
	testStandView[2] = testStandView2;
	testStandView[3] = testStandView3;
	testStandView[4] = testStandView4;
	testStandView[5] = testStandView5;
	testStandView[6] = testStandView6;
	
	[super awakeFromNib];
}

#pragma mark •••Accessors
- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"MJD Vacuum (Cryostat %u)",[model uniqueIdNumber]]];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   
	[notifyCenter addObserver : self
                     selector : @selector(showGridChanged:)
                         name : ORMJDPumpCartModelShowGridChanged
                       object : nil];
		
    [notifyCenter addObserver : self
                     selector : @selector(stateChanged:)
                         name : ORVacuumPartChanged
						object: nil];

	[notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORMJCTestCryoVacLock
                        object: nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupObjectsAdded
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupObjectsRemoved
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupSelectionChanged
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : OROrcaObjectMoved
                       object : nil];

	[notifyCenter addObserver : self
                     selector : @selector(leftSideConnectionChanged:)
                         name : ORMJDPumpCartModelLeftSideConnectionChanged
                       object : nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(rightSideConnectionChanged:)
                         name : ORMJDPumpCartModelRightSideConnectionChanged
                       object : nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(connectionChanged:)
                         name : ORMJDPumpCartModelConnectionChanged
                       object : nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(updatePUButtons:)
                         name : ORMJDTestCryoConnectionChanged
                       object : nil];	
	
}

- (void) updateWindow
{
    [super updateWindow];
	[self showGridChanged:nil];
	[self stateChanged:nil];
	[self leftSideConnectionChanged:nil];
	[self rightSideConnectionChanged:nil];
	[self connectionChanged:nil];
	[self updatePUButtons:nil];
	[self lockChanged:nil];
}

#pragma mark •••Interface Management
- (void) leftSideConnectionChanged:(NSNotification*)aNotification
{
	[leftSideConnectionPU selectItemAtIndex:[model leftSideConnection]];
}

- (void) rightSideConnectionChanged:(NSNotification*)aNotification
{
	[rightSideConnectionPU selectItemAtIndex:[model rightSideConnection]];
}

- (void) updatePUButtons:(NSNotification*)aNotification
{
	BOOL leftSideConnected = NO;
	BOOL rightSideConnected = NO;
	int i;
	for(i=0;i<7;i++){
		ORMJDTestCryostat* aCryostat = [model testCryoStat:i];
		if([aCryostat connectionStatus] == kConnectedToLeftSide)leftSideConnected = YES;
		if([aCryostat connectionStatus] == kConnectedToRightSide)rightSideConnected = YES;
	}
	if(!leftSideConnected)[leftSideConnectionPU selectItemAtIndex:0];
	if(!rightSideConnected)[rightSideConnectionPU selectItemAtIndex:0];
}

- (void) connectionChanged:(NSNotification*)aNotification
{
	NSRect homePosition[7];
	homePosition[0] = NSMakeRect(740,400,200,185);
	homePosition[1] = NSMakeRect(530,400,200,185);
	homePosition[2] = NSMakeRect(740,205,200,185);
	homePosition[3] = NSMakeRect(530,205,200,185);
	homePosition[4] = NSMakeRect(740,5,200,185);
	homePosition[5] = NSMakeRect(530,5,200,185);
	homePosition[6] = NSMakeRect(300,5,200,185);
	int position = 0;
	int i;
	for(i=0;i<7;i++){
		ORMJDTestCryostat* aCryostat = [model testCryoStat:i];
		if([aCryostat connectionStatus] == kNotConnected){
			[[testStandView[i] animator] setFrame:homePosition[position++]];
		}
		else if([aCryostat connectionStatus] == kConnectedToLeftSide){
			NSRect position = NSMakeRect(0,400,200,185);
			[[testStandView[i] animator] setFrame:position];
		}
		else if([aCryostat connectionStatus] == kConnectedToRightSide){
			NSRect position = NSMakeRect(300,400,200,185);
			[[testStandView[i] animator] setFrame:position];
		}
	}	
}

-(void) groupChanged:(NSNotification*)note
{
	if(note == nil || [note object] == model || [[note object] guardian] == model){
		[subComponentsView setNeedsDisplay:YES];
	}
}

- (void) lockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORMJCTestCryoVacLock];
    [lockButton setState: locked];
	[leftSideConnectionPU setEnabled:!locked];
	[rightSideConnectionPU setEnabled:!locked];	
}

- (void) stateChanged:(NSNotification*)aNote
{
	if(!updateScheduled){
		updateScheduled = YES;
		[self performSelector:@selector(delayedRefresh) withObject:nil afterDelay:1];
	}
}
- (void) delayedRefresh
{
	updateScheduled = NO;
	[vacuumView setNeedsDisplay:YES];
	int i;
	for(i=0;i<7;i++){
		[testStandView[i] setNeedsDisplay:YES];
	}
}

- (void) showGridChanged:(NSNotification*)aNote
{
	[setShowGridCB setIntValue:[model showGrid]];
	[vacuumView setNeedsDisplay:YES];
}

- (void) toggleGrid
{
	[model toggleGrid];
}

- (BOOL) showGrid
{
	return [model showGrid];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORMJCTestCryoVacLock to:secure];
    [lockButton setEnabled:secure];
}

#pragma mark •••Actions
- (IBAction) showGridAction:(id)sender
{
	[model setShowGrid:[sender intValue]];
}

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORMJCTestCryoVacLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) leftSideConnectionRequest:(id)sender
{
	[model setLeftSideConnection:(int)[sender indexOfSelectedItem]];
}

- (IBAction) rightSideConnectionRequest:(id)sender
{
	[model setRightSideConnection:(int)[sender indexOfSelectedItem]];
}

@end
