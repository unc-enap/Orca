//
//  ORICS8065Controller.m
//  Orca
//
//  Created by Mark Howe on Friday, June 20, 2008.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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

#import "ORICS8065Controller.h"
#import "ORICS8065Model.h"

@implementation ORICS8065Controller
#pragma mark •••Initialization
- (id) init
{
    self = [super initWithWindowNibName: @"ORICS8065"];
    return self;
}

- (void) awakeFromNib
{
	[self populatePullDowns];
	
	[super awakeFromNib];
    if(![model isEnabled]) {
        [self disableAll];
    } 
	else {
        [self setTestButtonsEnabled: false];
        [self testLockChanged: nil];
        [self updateWindow];
    }
}


- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [super registerNotificationObservers];
	
	[notifyCenter addObserver : self
                     selector : @selector(ipAddressChanged:)
                         name : ORICS8065ModelIpAddressChanged
						object: model];
	
	[notifyCenter addObserver : self
					 selector : @selector(isConnectedChanged:)
						 name : ORICS8065ModelIsConnectedChanged
						object: model];
	
	[notifyCenter addObserver: self
					 selector: @selector( testLockChanged: )
						 name: ORRunStatusChangedNotification
					   object: nil];
	
    [notifyCenter addObserver: self
					 selector: @selector( testLockChanged: )
						 name: ORICS8065TestLock
					   object: nil];
	
    [notifyCenter addObserver: self
					 selector: @selector( writeToMonitor: )
						 name: ORGpib1MonitorNotification
					   object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(primaryAddressChanged:)
                         name : ORICS8065PrimaryAddressChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(commandChanged:)
                         name : ORICS8065ModelCommandChanged
						object: model];
	
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORICS8065TestLock to:secure];
    
    [testLockButton setEnabled:secure];
}


- (void) testLockChanged: (NSNotification*) aNotification
{
    BOOL locked		= [gSecurity isLocked:ORICS8065TestLock];
    BOOL runInProgress  = [gOrcaGlobals runInProgress];
    
    [testLockButton setState: locked];
    
    [connectButton setEnabled: !locked && !runInProgress];
    [ipConnectButton setEnabled: !locked && !runInProgress];
    [primaryAddressPU setEnabled: !locked && !runInProgress];
    [commandTextField setEnabled: !locked && !runInProgress];
    [mQuery setEnabled: !locked && !runInProgress];
    [mWrite setEnabled: !locked && !runInProgress];
    [mRead setEnabled: !locked && !runInProgress];
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


- (void) writeToMonitor: (NSNotification*) aNotification
{
    uint32_t maxTextSize = 100000;
	@try {
		NSString* command = [[aNotification userInfo] objectForKey: ORGpib1Monitor];
		[monitorView replaceCharactersInRange:NSMakeRange([[monitorView textStorage] length], 0) withString:command];
		if([[monitorView textStorage] length] > maxTextSize){
			[[monitorView textStorage] deleteCharactersInRange:NSMakeRange(0,maxTextSize/3)];
		}
		[monitorView scrollRangeToVisible: NSMakeRange([[monitorView textStorage] length], 0)];
		
	}
	@catch(NSException* localException) {
	}
	
}

#pragma mark •••Actions
- (void) commandTextFieldAction:(id)sender
{
	[model setCommand:[sender stringValue]];	
}

- (IBAction) ipAddressTextFieldAction:(id)sender
{
	[model setIpAddress:[sender stringValue]];	
}

- (IBAction) connectAction:(id)sender
{
	[self endEditing];
	[model connect];
}

- (IBAction) testLockAction: (id) sender
{
    [gSecurity tryToSetLock:ORICS8065TestLock to:[sender intValue] forWindow: [self window]];
}

- (IBAction) query: (id) aSender
{
    char	data[2048];
    int32_t	returnLen;
    int32_t	maxLength = sizeof( data ) - 1;
    
    @try {
		[self endEditing];
        returnLen =  [[self model] writeReadDevice:[primaryAddressPU indexOfSelectedItem] 
										   command:[model command]
											  data:&data[0]
										 maxLength:maxLength];
		
        if ( returnLen > 0 ){
            data[returnLen] = '\0';
            [mResult insertText: [NSString stringWithCString: data encoding:NSASCIIStringEncoding]replacementRange:NSMakeRange(0,0)];
        }
	}
	@catch(NSException* localException) {
        NSLog(@"%@\n",[localException reason]);
 		ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,    // other button
                        [localException reason ]);
    }
}


- (IBAction) read: (id) aSender
{
    char	data[10*1048];
    int32_t	returnLen;
    
    @try {
        returnLen = [[self model] readFromDevice: [primaryAddressPU indexOfSelectedItem]
											data: data
									   maxLength: 10*1048];
		
        if ( returnLen > 0 )
            [mResult insertText: [NSString stringWithCString: data encoding:NSASCIIStringEncoding]replacementRange:NSMakeRange(0,0)];
		
	}
	@catch(NSException* localException) {
        NSLog(@"%@\n",[localException reason]);
 		ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,    // other button
                        [localException reason ]);
    }
}


- (IBAction) write: (id) aSender
{
    @try {
		[self endEditing];
        [[self model] writeToDevice: [primaryAddressPU indexOfSelectedItem]
							command: [model command]];
		
    }
	@catch(NSException* localException) {
        NSLog(@"%@\n",[localException reason]);
		ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,    // other button
                        [localException reason ]);
    }
}


- (IBAction) connect:(id) aSender
{
    short primaryAddress;
    
    @try {
        primaryAddress = [primaryAddressPU indexOfSelectedItem];
        if ( primaryAddress  > -1 && primaryAddress < kMaxGpibAddresses ) {
			
            [[self model] setupDevice:primaryAddress];
            [mConfigured setStringValue:[NSString stringWithFormat:
										 @"Configured:%d\n", primaryAddress]];
            [self setTestButtonsEnabled:true];
        }
		
	}
	@catch(NSException* localException) {
        NSLog(@"%@\n",[localException reason]);
 		ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,    // other button
                        [localException reason ]);
    }
}

- (IBAction) primaryAddressAction: (id) aSender
{
	// Make sure that value has changed.
    if ( [aSender indexOfSelectedItem] != [model primaryAddress]){
		
        [model setPrimaryAddress: (int)[aSender indexOfSelectedItem]];
		[model setupDevice:[model primaryAddress]];
        NSLog ( [NSString stringWithFormat: @"New Address %d\n", [model primaryAddress]] );
        
		// Check if address is configured.
        if ( [[self model] checkAddress:[model primaryAddress]] ){
            NSLog ( @"Configured\n" );
            [mConfigured setStringValue:[NSString stringWithFormat:
										 @"Configured:%d\n", [model primaryAddress]]];
            [self setTestButtonsEnabled: true];
        }
        else {
            NSLog ( @"Not Configured\n" );
            [mConfigured setStringValue: [NSString stringWithFormat:
										  @"Not configured:%d", [model primaryAddress]]];
            [self setTestButtonsEnabled: false];
        }
    }
}

#pragma mark ***Actions - Monitor
- (IBAction) changeMonitorRead: (id) aSender
{
    bool	tmpValue = false;
    if ( [aSender state] == 1 ) tmpValue = true;
	
	[[self model] setGPIBMonitorRead: tmpValue];
}

- (IBAction) changeMonitorWrite: (id) aSender
{
    bool	tmpValue = false;
    if ( [aSender state] == 1 ) tmpValue = true;
	
	[[self model] setGPIBMonitorWrite: tmpValue];
}

#pragma mark ***Support
- (void) updateWindow
{
    [super updateWindow];
	[self ipAddressChanged:nil];
	[self isConnectedChanged:nil];
	[self primaryAddressChanged:nil];
	[self commandChanged:nil];
}

- (void) commandChanged:(NSNotification*)aNote
{
	[commandTextField setStringValue: [model command]];
}

- (void) primaryAddressChanged:(NSNotification*)aNote
{
	[primaryAddressPU selectItemAtIndex: [model primaryAddress]];
}

- (void) populatePullDowns
{
    short	i;
    
	// Remove all items from popup menus
    [primaryAddressPU removeAllItems];
	
	// Repopulate Primary GPIB address
    for ( i = 0; i <  kMaxGpibAddresses; i++ ) {
        [primaryAddressPU insertItemWithTitle:[NSString stringWithFormat:@"%d", i]
                                      atIndex:i];
    } 
}

- (void) setTestButtonsEnabled:(BOOL) aValue
{
    aValue = (aValue && [model isEnabled] );
    [mQuery setEnabled:aValue];
    [mWrite setEnabled:aValue];
    [mRead setEnabled:aValue];            
}

- (void) disableAll
{
    [primaryAddressPU setEnabled:NO];
    [commandTextField setEnabled:NO];
    [mConfigured setEnabled:NO];
    [mQuery setEnabled:NO];
    [mWrite setEnabled:NO];
    [mRead setEnabled:NO];
}

@end
