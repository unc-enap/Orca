
//
//  ORUnivVoltHVCrateController.m
//  Orca
//
//  Created by Mark Howe on Fri Nov 22 2002.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORUnivVoltHVCrateController.h"
#import "ORUnivVoltHVCrateModel.h"
#import "ORUnivVoltHVCrateExceptions.h"


@implementation ORUnivVoltHVCrateController

- (id) init
{
    self = [super initWithWindowNibName:@"UnivVoltHVCrate"];
	if ( self ) {
		[model setIpAddress: @"192.168.1.10"];
	}
    return self;	
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	
	NSString* testString = @"See if anything appears in text view.\n";
	NSLog( @"UnivVoltHVCrateController - IPAddress: %@\n", [model ipAddress] );
	[ipAddressTextField setStringValue: [model ipAddress]];
//	[mReturnStringFromSocket setString: testString];
//	[mReturnStringFromSocket appendString: testString1];
	[outputArea setString: testString];	
}


- (void) setCrateTitle
{
	[[self window] setTitle:[NSString stringWithFormat:@"CAMAC crate %u",[model uniqueIdNumber]]];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   
    [notifyCenter addObserver : self
                     selector : @selector( isConnectedChanged: )
                         name : HVCrateIsConnectedChangedNotification
                       object : model];
					   					
    [notifyCenter addObserver : self
                     selector : @selector( ipAddressChanged: )
                         name : HVCrateIpAddressChangedNotification
                       object : model];
					   
    [notifyCenter addObserver : self
                     selector : @selector( displayHVStatus: )
                         name : HVCrateHVStatusAvailableNotification
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector( displayConfig: )
                         name : HVCrateConfigAvailableNotification
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector( displayEnet: )
                         name : HVCrateEnetAvailableNotification
                       object : model];
					   
    [notifyCenter addObserver : self
                     selector : @selector( writeErrorMsg: )
                         name : HVSocketNotConnectedNotification
                       object : model];	

    [notifyCenter addObserver : self
                     selector : @selector( writeErrorMsg: )
                         name : HVLongErrorNotification
                       object : model];	
}

- (void) updateWindow
{
    [ super updateWindow ];
    
//    [self settingsLockChanged:nil];
	[self ipAddressChanged: nil];
	[self isConnectedChanged: nil];
}

- (void) ipAddressChanged: (NSNotification*) aNote
{
	[ipAddressTextField setStringValue: [model ipAddress]];
}

- (void) isConnectedChanged: (NSNotification *) aNote
{
	[ipConnectedTextField setStringValue: [model isConnected] ? @"Connected" : @"Disconnected"];
	[ethernetConnectButton setTitle: [model isConnected] ? @"Disconnect" : @"Connect"];
//	[model isConnected] ? [model disconnect] : [model connect];
}

- (void) writeErrorMsg: (NSNotification*) aNote
{
	NSDictionary* errorDict = [aNote userInfo];
	NSLog( @"UnivVoltHVCrateController - error: %@", [errorDict objectForKey: HVkErrorMsg] );
	[outputArea setString: [errorDict objectForKey: HVkErrorMsg]];
}


#pragma mark •••Actions
- (IBAction) ipAddressTextFieldAction: (id) aSender
{
	[model setIpAddress: [aSender stringValue]];	
}

- (IBAction) connectAction: (id) aSender
{
	if ( [model isConnected] ) {
		[model disconnect];
	}
	else {	
		[model setIpAddress: [ipAddressTextField stringValue]];
		[model connect];
	}
}

- (IBAction) getEthernetParamAction: (id) aSender
{
//	NSLog( @"getEthernetParamAction\n" );
//	if ( [model isConnected] ) {
		[model obtainEthernetConfig];
//	}
}

- (IBAction) getConfigParamAction: (id) aSender
{
//	NSLog( @"getConfigParamAction\n" );
	//if ( [model isConnected] ) {
		[model obtainConfig];
	//}
}

- (IBAction) hvOnAction: (id) aSender
{
	[model turnHVOn];
}

- (IBAction) hvOffAction: (id) aSender
{
	[model turnHVOff];
}

- (IBAction) panicAction: (id) aSender
{
	[model hvPanic];
}


- (void) showError: (NSException*)anException name: (NSString*)name
{
    NSLog( @"UnivVoltHVCrateController - Failed Cmd: %@ \n",name );
    if([[anException name] isEqualToString: OExceptionNoUnivVoltHVCratePower]) {
        [model  doNoPowerAlert:anException action:[NSString stringWithFormat:@"%@",name]];
    }
    else {
        ORRunAlertPanel([anException name], @"%@\n%@", @"OK", nil, nil,
                        [anException name],name);
    }
}

- (IBAction) showHVStatusAction: (id) aSender
{
	[model obtainHVStatus];
}

#pragma mark ***Respond to notifications actions from model handleDataReturn
- (void) displayHVStatus: (NSNotification *) aNotes

{
	NSLog( @"UnivVoltHVCrateController - HVStatus display: %@", [model hvStatus] );
	[hvStatusField setStringValue: [model hvStatus]];
}

- (void) displayConfig: (NSNotification *) aNotes
{
	NSString* returnData = [model config];	
	NSLog( @"UnivVoltHVCrateController - Config display: %@", returnData );
	[outputArea setString: returnData];
}

- (void) displayEnet: (NSNotification *) aNotes

{
	NSLog( @"UnivVoltHVCrateController - Ethernet display: %@", [model ethernetConfig] );
	[outputArea setString: [model ethernetConfig]];
}

@end
