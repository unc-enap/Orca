/*
 *  ORC111CController.m
 *  Orca
 *
 *  Created by Mark Howe on Mon Dec 10, 2007.
 *  Copyright (c) 2007 CENPA, University of Washington. All rights reserved.
 *
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


#pragma mark •••Imported Files
#import "ORC111CController.h"
#import "ORPlotView.h"
#import "ORPlot.h"
#import "ORC111CModel.h"
#import "ORCmdHistory.h"
#import "ORCompositePlotView.h"

@implementation ORC111CController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"C111C"];
    
    return self;
}

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super dealloc];
}

- (void) awakeFromNib
{
	ORPlot* aPlot = [[ORPlot alloc] initWithTag:0 andDataSource:self];
	[plotter addPlot: aPlot];
	[aPlot release];
	[plotter setXLabel:@"Transactions/second"];
	[super awakeFromNib];
	
	if([model trackTransactions]){
		[self performSelector:@selector(updatePlot) withObject:nil afterDelay:1.0];
	}
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    

   [notifyCenter addObserver : self
                     selector : @selector(ipAddressChanged:)
                         name : ORC111CIpAddressChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(isConnectedChanged:)
                         name : ORC111CConnectionChanged
						object: model];
						
    [notifyCenter addObserver : self
                     selector : @selector(stationToTestChanged:)
                         name : ORC111CModelStationToTestChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(trackTransactionsChanged:)
                         name : ORC111CModelTrackTransactionsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(commandChanged:)
                         name : ORCmdHistoryChangedNotification
                       object : [model cmdHistory]];
}

#pragma mark •••Interface Management

- (void) commandChanged:(NSNotification*)aNote
{
	NSString* aCommand = [[aNote userInfo] objectForKey:ORCmdHistoryChangedNotification];
	if(aCommand){
		[asciiCmdTextField setStringValue:aCommand];
	}
}

- (void) trackTransactionsChanged:(NSNotification*)aNote
{
	[trackTransactionsCB setIntValue: [model trackTransactions]];
}

- (void) stationToTestChanged:(NSNotification*)aNote
{
	[stationToTestTextField setIntValue: [model stationToTest]];
}

- (void) updateWindow
{
    [super updateWindow];
	[self ipAddressChanged:nil];
	[self isConnectedChanged:nil];
	[self stationToTestChanged:nil];
	[self trackTransactionsChanged:nil];
}

- (void) setButtonStates
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    //BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[model settingsLock]];
    BOOL locked = [gSecurity isLocked:[model settingsLock]];
    
	[super setButtonStates];

    [ipConnectButton setEnabled:!locked && !runInProgress];
    [ipAddressTextField setEnabled:!locked && !runInProgress];
    [stationToTestTextField setEnabled:!locked];
    [asciiCmdTextField setEnabled:!locked && !runInProgress];
    [sendAsciiCmdButton setEnabled:!locked && !runInProgress];

}

- (void) isConnectedChanged:(NSNotification*)aNote
{
	[ipConnectedTextField setStringValue: [model isConnected]?@"Connected":@"Not Connected"];
	[ipConnectButton setTitle:[model isConnected]?@"Disconnect":@"Connect"];
}

- (void) ipAddressChanged:(NSNotification*)aNote
{
	[ipAddressTextField setStringValue: [model ipAddress]];
}

- (void) updatePlot
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updatePlot) object:nil];
	[plotter setNeedsDisplay:YES];
	if([model trackTransactions]){
		[self performSelector:@selector(updatePlot) withObject:nil afterDelay:1.0];
	}
}

#pragma mark •••Actions

- (IBAction) trackTransactionsAction:(id)sender
{
	[model setTrackTransactions:[sender intValue]];	
	if([model trackTransactions]){
		[self performSelector:@selector(updatePlot) withObject:nil afterDelay:1.0];
	}
}

- (IBAction) testLAMForStationAction:(id)sender
{
	char result;
	if([model testLAMForStation:[model stationToTest] value:&result] == 0){
		NSLog(@"LAM is %@ on %@\n",result==1?@"SET":@"CLEAR",result==1 ? ([model stationToTest] == -1?@"at least one station":[NSString stringWithFormat:@"on station %d",[model stationToTest]]) : 
																		 ([model stationToTest] == -1?@"on all stations":[NSString stringWithFormat:@"on station %d",[model stationToTest]]));
	}	
}

- (IBAction) stationToTestTextFieldAction:(id)sender
{
	[model setStationToTest:[sender intValue]];	
}

- (IBAction) ipAddressTextFieldAction:(id)sender
{
	[model setIpAddress:[sender stringValue]];	
}

- (IBAction) connectAction:(id)sender
{
	@try {
		[self endEditing];
		if([model isConnected])[model disconnect];
		else [model connect];
	    }
	@catch(NSException* localException) {
		NSLog(@"%@\n",localException);
	}
}

- (IBAction) sendAsciiCmd:(id)sender
{
	[self endEditing];
	[model sendCmd:[asciiCmdTextField stringValue] verbose:YES];
	[[model cmdHistory] addCommandToHistory:[asciiCmdTextField stringValue]];
	[asciiCmdTextField becomeFirstResponder];
}

- (IBAction) clearTransactions:(id)sender
{
	[model clearTransactions];
	[plotter setNeedsDisplay:YES];
}

- (BOOL) control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
{
	if (command == @selector(moveDown:)) {
		[[model cmdHistory] moveInHistoryDown];
		return YES;
	}
	if (command == @selector(moveUp:)) {
		[[model cmdHistory] moveInHistoryUp];	
		return YES;
	}
	return NO;
}


#pragma mark •••Plotter Datasource
- (int) numberPointsInPlot:(id)aPlotter
{
    return kMaxNumberC111CTransactionsPerSecond;
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;
{
	*yValue =  [model transactionsPerSecondHistogram:i];
 	*xValue = i;
}


@end



