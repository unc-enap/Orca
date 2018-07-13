//
//  ORTask.m
//  Orca
//
//  Created by Mark Howe on Wed Nov 26 2003.
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


#import "ORiTransGasSensorController.h"
#import "ORiTransGasSensorModel.h"
#import "ORModBusModel.h"

@implementation ORiTransGasSensorController

#pragma mark •••Initializers
+ (id) sensorPanel
{
    return [[[ORiTransGasSensorController alloc] init] autorelease];
}

-(id)	init
{
    if( self = [super init] ){
#if !defined(MAC_OS_X_VERSION_10_9)
        [NSBundle loadNibNamed:@"iTransGasSensor" owner:self];
#else
        [[NSBundle mainBundle] loadNibNamed:@"iTransGasSensor" owner:self topLevelObjects:&topLevelObjects];
#endif
        
        [topLevelObjects retain];

    }
    return self;
}

-(void)	dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [view removeFromSuperview]; 
	[okColor release];
	[badColor release];
    [topLevelObjects release];

    [super dealloc];
}

- (void) setModel:(id)aModel
{
	if(aModel!=model){
		model = aModel;
		[self updateWindow];
		[[NSNotificationCenter defaultCenter] removeObserver:self];
		[self registerNotificationObservers];
	}
}

- (void) awakeFromNib
{
	alarmed = NO;
	okColor = [[NSColor colorWithCalibratedRed:.0 green:.8 blue:.0 alpha:1] retain];
	badColor = [[NSColor colorWithCalibratedRed:.8 green:.0 blue:.0 alpha:1] retain];
	
	[self updateWindow];
    [self registerNotificationObservers];
}

- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
	[notifyCenter removeObserver:self];
	
	[notifyCenter addObserver : self
					 selector : @selector(baseAddressChanged:)
						 name : ORiTransGasSensorBaseAddressChanged
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(gasTypeChanged:)
						 name : ORiTransGasSensorGasTypeChanged
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(sensorTypeChanged:)
						 name : ORiTransGasSensorGasSensorTypeChanged
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(statusChanged:)
						 name : ORiTransGasSensorStatusBitsChanged
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(gasReadingChanged:)
						 name : ORiTransGasSensorGasReadingChanged
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(nameChanged:)
                         name : ORiTransGasSensorModelNameChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(stateChanged:)
                         name : ORModBusLock
                        object: nil];
    [notifyCenter addObserver : self
                     selector : @selector(channelChanged:)
                         name : ORiTransGasSensorModelChannelChanged
						object: model];

}

- (void) updateWindow
{
	[self baseAddressChanged:nil];
	[self gasTypeChanged:nil];
	[self sensorTypeChanged:nil];
	[self gasReadingChanged:nil];
	[self statusChanged:nil];
	[self nameChanged:nil];
	[self channelChanged:nil];
}

- (void) channelChanged:(NSNotification*)aNote
{
	[channelPU selectItemAtIndex: [model channel]];
}


- (void) stateChanged:(NSNotification*)aNotification
{

    BOOL locked = [gSecurity isLocked:ORModBusLock];
	
    [removeSelfButton setEnabled:!locked];
    [nameField setEnabled:!locked];
    [baseAddressField setEnabled:!locked];
	
}


- (void) nameChanged:(NSNotification*)aNote
{
	if(model){
		[nameField setStringValue: [model sensorName]];
	}
}

- (void) baseAddressChanged:(NSNotification*)aNote;
{
	if(model){
		[baseAddressField setIntValue:[model baseAddress]];
	}
}

- (void) gasTypeChanged:(NSNotification*)aNote
{
	if(model){
		int theType = [model gasType];
		[gasTypeField setStringValue:[model gasType:theType fullName:NO]];
	}
}

- (void) sensorTypeChanged:(NSNotification*)aNote
{
	if(model){
		int theType = [model sensorType];
		[sensorTypeField setStringValue:[model sensorType:theType fullName:NO]];
	}
}

- (void) gasReadingChanged:(NSNotification*)aNote
{
	if(model){
		if(failedSensor || missingSensor){
			if(failedSensor)[gasReadingField setStringValue:@"FAILED"];
			else			[gasReadingField setStringValue:@"MISSING"];
			[gasReadingField setTextColor:badColor];
		}
		else {
			[gasReadingField setTextColor:alarmed?badColor:[NSColor blackColor]];
			[gasReadingField setStringValue:[model formattedGasReading]];
		}
	}
}



- (void) statusChanged:(NSNotification*)aNote;
{
	if(model){
		unsigned short statusWord = [model statusBits];

		//-------------------------------------
		int currentLoopOpen    = statusWord & 0x8000;
		int currentLoopShorted = statusWord & 0x4000;
				
		if(currentLoopOpen || currentLoopShorted){
			if(currentLoopOpen)	[currentLoopField setStringValue:@"OPEN"];
			else				[currentLoopField setStringValue:@"SHORTED"];
		}
		else [currentLoopField setStringValue:@""];
	
		//-------------------------------------
		int powerFault			= statusWord & 0x2000;
		int fiveVoltFault		= statusWord & 0x1000;
		if(powerFault || fiveVoltFault){
			if(powerFault)[powerField setStringValue:@"Power"];
			else [powerField setStringValue:@"5 Volt"];
		}
		else [powerField setStringValue:@""];

		//-------------------------------------
		int highAlarm	= statusWord & 0x0002;
		int lowAlarm	= statusWord & 0x0001;
		failedSensor	= statusWord & 0x0004;
		alarmed			= highAlarm || lowAlarm;
		missingSensor	= (statusWord & 0x0800)!=0;
		[self gasReadingChanged:nil];

		//-------------------------------------
		int calibrationFault	= statusWord & 0x0010;
		[calibrationField setStringValue:calibrationFault?@"Calibration":@""];
		
		//-------------------------------------
		int zeroFault			= statusWord & 0x0020;
		[zeroFaultField setStringValue:zeroFault?@"ZeroFault":@""];
		
		//-------------------------------------
		int overRange			= statusWord & 0x0008;
		[overRangeField setStringValue:overRange?@"OverRange":@""];
		
	}
}

#pragma mark •••Accessors
-(NSView*) view
{
    return view;
}

- (NSUndoManager*) undoManager
{
    return [(ORAppDelegate*)[NSApp delegate] undoManager];
}

- (void) updateButtons
{
	
}

#pragma mark •••Actions

- (void) channelAction:(id)sender
{
	[model setChannel:(int)[sender indexOfSelectedItem]];	
}

- (void) nameAction:(id)sender
{
	[model setSensorName:[sender stringValue]];	
}
- (IBAction) baseAddressAction:(id)sender
{
	[model setBaseAddress:[sender intValue]];
}

- (IBAction) removeSelf:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:ORiTransRemoveGasSensor object:model];
}

@end

