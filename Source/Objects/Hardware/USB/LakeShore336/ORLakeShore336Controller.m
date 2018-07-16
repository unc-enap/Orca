//
//  ORHPLakeShore336Controller.m
//  Orca
//  Created by Mark Howe on Mon, May 6, 2013.
//  Copyright (c) 2013 University of North Carolina. All rights reserved.
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


#import "ORLakeShore336Controller.h"
#import "ORLakeShore336Model.h"
#import "ORUSB.h"
#import "ORUSBInterface.h"
#import "ORLakeShore336Input.h"
#import "ORLakeShore336Heater.h"
#import "ORCompositePlotView.h"
#import "ORTimeAxis.h"
#import "ORTimeLinePlot.h"
#import "ORTimeRate.h"

@implementation ORLakeShore336Controller
- (id) init
{
    self = [ super initWithWindowNibName: @"LakeShore336" ];
    return self;
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
    
    [notifyCenter addObserver : self
                     selector : @selector(connectionProtocolChanged:)
                         name : ORLakeShore336ConnectionProtocolChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(ipAddressChanged:)
                         name : ORLakeShore336IpAddressChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(usbConnectedChanged:)
                         name : ORLakeShore336UsbConnectedChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(ipConnectedChanged:)
                         name : ORLakeShore336IpConnectedChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(canChangeConnectionProtocolChanged:)
                         name : ORLakeShore336CanChangeConnectionProtocolChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(interfacesChanged:)
                         name : ORUSBInterfaceAdded
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(interfacesChanged:)
                         name : ORUSBInterfaceRemoved
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(serialNumberChanged:)
                         name : ORLakeShore336SerialNumberChanged
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(serialNumberChanged:)
                         name : ORLakeShore336USBInterfaceChanged
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(pollTimeChanged:)
                         name : ORLakeShore336PollTimeChanged
						object: model];
    
    [notifyCenter addObserver : self
					 selector : @selector(updateTimePlot:)
						 name : ORRateAverageChangedNotification
					   object : nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(updateLinkView:)
						 name : ORLakeShore336InputChanged
					   object : nil];    

}

- (void) awakeFromNib
{
	[self populateInterfacePopup];
    
    [[plotter yAxis] setRngLow:0. withHigh:350.];
	[[plotter yAxis] setRngLimitsLow:0 withHigh:350 withMinRng:10];
	[plotter setUseGradient:YES];
    
    [[plotter xAxis] setRngLow:0.0 withHigh:10000];
	[[plotter xAxis] setRngLimitsLow:0.0 withHigh:200000. withMinRng:200];
 
    
    int i;
    for(i=0;i<4;i++){
        ORTimeLinePlot* aPlot;
        aPlot= [[ORTimeLinePlot alloc] initWithTag:i andDataSource:self];
        [plotter addPlot: aPlot];
        [aPlot setName:[NSString stringWithFormat:@"Temp %c",'A'+i]];
		[aPlot setLineColor:[self colorForDataSet:i]];
        [aPlot release];
    }
    
    for(i=0;i<2;i++){
        ORTimeLinePlot* aPlot;
        aPlot= [[ORTimeLinePlot alloc] initWithTag:i+4 andDataSource:self];
        [plotter addPlot: aPlot];
        [aPlot setName:[NSString stringWithFormat:@"Heater %d",i]];
		[aPlot setLineColor:[self colorForDataSet:i+4]];
        [aPlot release];
    }

    [plotter   setShowLegend:YES];

	[super awakeFromNib];
}

- (void) updateWindow
{
    [ super updateWindow ];
    
    [self connectionProtocolChanged:nil];
	[self ipAddressChanged:nil];
	[self usbConnectedChanged:nil];
	[self ipConnectedChanged:nil];
	[self canChangeConnectionProtocolChanged:nil];
	[self serialNumberChanged:nil];
	[self pollTimeChanged:nil];
	[self updateTimePlot:nil];
	[self updateLinkView:nil];
}

- (void) updateLinkView:(NSNotification*)aNote
{
    [linkView setNeedsDisplay:YES];
}

- (void) updateTimePlot:(NSNotification*)aNote
{
	if(!aNote || [model anyInputsUsingTimeRate:[aNote object]] || [model anyHeatersUsingTimeRate:[aNote object]]){
		[plotter setNeedsDisplay:YES];
	}
}

- (NSMutableArray*) inputs
{
    return [model inputs];
}
- (NSMutableArray*) heaters
{
    return [model heaters];
}

#pragma mark •••Notifications
- (void) serialNumberChanged:(NSNotification*)aNote
{
	if(![model serialNumber] || ![[model serialNumber] length] || ![model usbInterface])[serialNumberPopup selectItemAtIndex:0];
	else [serialNumberPopup selectItemWithTitle:[model serialNumber]];
	if([model connectionProtocol] == kLakeShore336UseUSB){
		[[self window] setTitle:[model title]];
	}
}

- (void) pollTimeChanged:(NSNotification*)aNote
{
	[pollTimePopup selectItemWithTag: [model pollTime]];
}

- (IBAction) pollNowAction:(id)sender
{
    [model queryAll];
}
- (void) interfacesChanged:(NSNotification*)aNote
{
	[self populateInterfacePopup];
}

- (void) canChangeConnectionProtocolChanged:(NSNotification*)aNote
{
	[connectionProtocolMatrix setEnabled:[model canChangeConnectionProtocol]];
	if([model canChangeConnectionProtocol])[connectionNoteTextField setStringValue:@""];
	else [connectionNoteTextField setStringValue:@"Disconnect Icon to Enable"];
	[self populateInterfacePopup];
}

- (void) ipConnectedChanged:(NSNotification*)aNote
{
	[ipConnectedTextField setStringValue: [model ipConnected]?@"Connected":@"Not Connected"];
}

- (void) usbConnectedChanged:(NSNotification*)aNote
{
	[usbConnectedTextField setStringValue: [model usbConnected]?@"Connected":@"Not Connected"];
}

- (void) ipAddressChanged:(NSNotification*)aNote
{
	[ipAddressTextField setStringValue: [model ipAddress]];
}

- (void) lockChanged: (NSNotification*) aNotification
{	
	[self setButtonStates];
}

- (void) connectionProtocolChanged:(NSNotification*)aNote
{
	[connectionProtocolMatrix selectCellWithTag:[model connectionProtocol]];
	[connectionProtocolTabView selectTabViewItemAtIndex:[model connectionProtocol]];
	[[self window] setTitle:[model title]];
	[self populateInterfacePopup];
}

- (void) setButtonStates
{	
    BOOL runInProgress  = [gOrcaGlobals runInProgress];
    BOOL locked			= [gSecurity isLocked:ORLakeShore336Lock];
    	
	[connectionProtocolMatrix setEnabled:!runInProgress || !locked];
	[ipConnectButton setEnabled:!runInProgress || !locked];
	[usbConnectButton setEnabled:!runInProgress || !locked];
	[ipAddressTextField setEnabled:!locked];
	[serialNumberPopup setEnabled:!locked];
	[pollTimePopup		setEnabled:!locked];
}


#pragma mark •••Plot DataSource
- (NSColor*) colorForDataSet:(int)set
{
	if(set==0)      return [NSColor redColor];
	else if(set==1) return [NSColor orangeColor];
	else if(set==2) return [NSColor blueColor];
	else if(set==3) return [NSColor greenColor];
	else if(set==4) return [NSColor blackColor];
	else if(set==5) return [NSColor purpleColor];
	else            return [NSColor blackColor];
}

- (int) numberPointsInPlot:(id)aPlotter
{
	int set = (int)[aPlotter tag];
    if(set>=0 && set<4) return (int)[[[model inputs] objectAtIndex:set] numberPointsInTimeRate];
    else if(set>=4 && set<6)return (int)[[[model heaters] objectAtIndex:set-4] numberPointsInTimeRate];
    else return 0;
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
	int set = (int)[aPlotter tag];
    if(set>=0 && set<4){
        [[[model inputs] objectAtIndex:set] timeRateAtIndex:i x:xValue y:yValue];
    }
    else if(set>=4 && set<6){
        [[[model heaters] objectAtIndex:set-4] timeRateAtIndex:i x:xValue y:yValue];
    }
    else {
        *xValue = 0;
        *yValue = 0;
    }
}

#pragma mark •••Actions
- (IBAction) pollTimeAction:(id)sender
{
	[model setPollTime:(int)[[sender selectedItem] tag]];
}

- (IBAction) connectAction: (id) aSender
{
    if(![model isConnected])[model connect];
}

- (IBAction) sendCommandAction:(id)sender
{
	@try {
		[self endEditing];
		NSString* cmd = [commandField stringValue];
        [model addCmdToQueue:cmd];
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,	// other button
                        [localException reason ]);
	}
	
}
- (IBAction) lockAction:(id)sender
{
    [gSecurity tryToSetLock:ORLakeShore336Lock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) ipAddressTextFieldAction:(id)sender
{
	[model setIpAddress:[sender stringValue]];	
}

-(IBAction) loadParamsAction:(id)sender
{
    [self endEditing];
	@try {
		[model loadHeaterParameters];
		[model loadInputParameters];
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,	// other button
                        [localException reason ]);
	}
}

- (IBAction) connectionProtocolAction:(id)sender
{
	[model setConnectionProtocol:(int)[[connectionProtocolMatrix selectedCell] tag]];
	
	BOOL undoWasEnabled = [[model undoManager] isUndoRegistrationEnabled];
    if(undoWasEnabled)[[model undoManager] disableUndoRegistration];
	[model adjustConnectors:NO];
	if(undoWasEnabled)[[model undoManager] enableUndoRegistration];
	
}

- (void) populateInterfacePopup
{
	NSArray* interfaces = [model usbInterfaces];
	[serialNumberPopup removeAllItems];
	[serialNumberPopup addItemWithTitle:@"N/A"];
	NSEnumerator* e = [interfaces objectEnumerator];
	ORUSBInterface* anInterface;
	while(anInterface = [e nextObject]){
		NSString* serialNumber = [anInterface serialNumber];
		if([serialNumber length]){
			[serialNumberPopup addItemWithTitle:serialNumber];
		}
	}
	[self validateInterfacePopup];
	if([[model serialNumber] length] > 0){
		if([serialNumberPopup indexOfItemWithTitle:[model serialNumber]]>=0){
			[serialNumberPopup selectItemWithTitle:[model serialNumber]];
		}
		else [serialNumberPopup selectItemAtIndex:0];
	}
	else [serialNumberPopup selectItemAtIndex:0];
}

- (void) validateInterfacePopup
{
	NSArray* interfaces = [[model getUSBController] interfacesForVender:[model vendorID] product:[model productID]];
	NSEnumerator* e = [interfaces objectEnumerator];
	ORUSBInterface* anInterface;
	while(anInterface = [e nextObject]){
		NSString* serialNumber = [anInterface serialNumber];
		if([anInterface registeredObject] == nil || [serialNumber isEqualToString:[model serialNumber]]){
			[[serialNumberPopup itemWithTitle:serialNumber] setEnabled:YES];
		}
		else [[serialNumberPopup itemWithTitle:serialNumber] setEnabled:NO];
	}
}

- (IBAction) serialNumberAction:(id)sender
{
	if([serialNumberPopup indexOfSelectedItem] == 0){
		[model setSerialNumber:nil];
	}
	else {
		[model setSerialNumber:[serialNumberPopup titleOfSelectedItem]];
	}
}

-(IBAction) readIdAction:(id)sender
{
	@try {
		[model readIDString];
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,	// other button
                        [localException reason ]);
	}
}

-(IBAction) testAction:(id)sender
{
	NSLog(@"Testing LakeShore 336 (takes a few seconds...).\n");
	[self performSelector:@selector(systemTest) withObject:nil afterDelay:0];
}
- (void) systemTest
{
	@try {
	    [model systemTest];
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,	// other button
                        [localException reason ]);
	}
}
-(IBAction) resetAction:(id)sender
{
	@try {
	    [model resetAndClear];
	    NSLog(@"LakeShore336 Reset and Clear successful.\n");
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,	// other button
                        [localException reason ]);
	}
}
@end

@implementation ORLakeShore336LinkView

- (void) drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    id model = [[[self window] windowController] model];
    if([[model heaters] count]>1){
        
        [[NSColor redColor]set];
        
        float height     = [self bounds].size.height;
        float cellHeight = 19;
        int heater1Input = [[[model heaters] objectAtIndex:0] input];
        
        [NSBezierPath strokeLineFromPoint:NSMakePoint( 0,cellHeight + cellHeight/2.) toPoint:NSMakePoint(15,cellHeight + cellHeight/2.)];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(15,cellHeight + cellHeight/2.) toPoint:NSMakePoint(15,height - cellHeight/2. - heater1Input*cellHeight- 2)];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(0,height - cellHeight/2. - heater1Input*cellHeight- 2) toPoint:NSMakePoint(15,height -  cellHeight/2. - heater1Input*cellHeight - 2)];
    
        
        int heater2Input = [[[model heaters] objectAtIndex:1] input];
        [NSBezierPath strokeLineFromPoint:NSMakePoint( 0,cellHeight/2.) toPoint:NSMakePoint(25,cellHeight/2.)];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(25,cellHeight/2.) toPoint:NSMakePoint(25,height - cellHeight/2. - heater2Input*cellHeight - 2)];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(0,height - cellHeight/2. - heater2Input*cellHeight - 2) toPoint:NSMakePoint(25,height - cellHeight/2. - heater2Input*cellHeight - 2)];
    }
}
@end
