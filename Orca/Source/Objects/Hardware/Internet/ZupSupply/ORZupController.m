//
//  ORZupController.m
//  Orca
//
//  Created by Mark Howe on Monday March 16,2009
//  Copyright (c) 2009 Univerisy of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the Univerisy of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the Univerisy of North 
//Carolina reserve all rights in the program. Neither the authors,
//Univerisy of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


#import "ORZupController.h"
#import "ORZupModel.h"
#import "ORSerialPortList.h"
#import "ORSerialPort.h"

@interface ORZupController (private)
- (void) populatePortListPopup;
@end

@implementation ORZupController
- (id) init
{
    self = [ super initWithWindowNibName: @"Zup" ];
    return self;
}

- (void) dealloc
{
	[blankView release];
	[super dealloc];
}

- (void) awakeFromNib
{
    [self populatePortListPopup];


    basicOpsSize	= NSMakeSize(280,280);
    rampOpsSize		= NSMakeSize(570,750);
    blankView		= [[NSView alloc] init];
	
    NSString* key = [NSString stringWithFormat: @"orca.ORZup%lu.selectedtab",[model uniqueIdNumber]];
    int index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
	
	[super awakeFromNib];

}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
    
	[notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORZupLock
						object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(portNameChanged:)
                         name : ORZupModelPortNameChanged
                        object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(portStateChanged:)
                         name : ORSerialPortStateChanged
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(boardAddressChanged:)
                         name : ORZupModelBoardAddressChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(outputStateChanged:)
                         name : ORZupModelOutputStateChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(actualCurrentChanged:)
                         name : ORZupModelActualCurrentChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(currentChanged:)
                         name : ORZupModelCurrentChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(statusRegisterChanged:)
                         name : ORZupModelStatusRegisterChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(faultRegisterChanged:)
                         name : ORZupModelFaultRegisterChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(faultEnableMaskChanged:)
                         name : ORZupModelFaultEnableMaskChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(statusEnableMaskChanged:)
                         name : ORZupModelStatusEnableMaskChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(actualVoltageChanged:)
                         name : ORZupModelActualVoltageChanged
						object: model];

}


- (void) updateWindow
{
    [ super updateWindow ];
    [self lockChanged:nil];
	[self portStateChanged:nil];
    [self portNameChanged:nil];
   
	[self boardAddressChanged:nil];
	[self outputStateChanged:nil];
	[self actualCurrentChanged:nil];
	[self currentChanged:nil];
	[self statusRegisterChanged:nil];
	[self faultRegisterChanged:nil];
	[self faultEnableMaskChanged:nil];
	[self statusEnableMaskChanged:nil];
	[self actualVoltageChanged:nil];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"TDK-Lambda (Address %d)",[model boardAddress]]];
}

- (void) actualVoltageChanged:(NSNotification*)aNote
{
	[actualVoltageField setFloatValue: [model actualVoltage]];
}

- (void) statusEnableMaskChanged:(NSNotification*)aNote
{
	int statusEnableMask = [model statusEnableMask];
	int i;
	for(i=1;i<8;i++){
		[[statusEnableMatrix cellWithTag:i] setIntValue: (statusEnableMask & (1<<i))!=0];
	}
}

- (void) faultEnableMaskChanged:(NSNotification*)aNote
{
	int faultEnableMask = [model faultEnableMask];
	int i;
	for(i=1;i<8;i++){
		[[faultEnableMatrix cellWithTag:i] setIntValue: (faultEnableMask & (1<<i))!=0];
	}
}

- (void) faultRegisterChanged:(NSNotification*)aNote
{
	int faultReg = [model faultRegister];
	[[faultRegMatrix cellAtRow:0 column:0] setObjectValue: (faultReg & 0x2)?@"FAILED":@"OK"];
	[[faultRegMatrix cellAtRow:1 column:0] setObjectValue: (faultReg & 0x4)?@"OverTemp":@"OK"];
	[[faultRegMatrix cellAtRow:2 column:0] setObjectValue: (faultReg & 0x8)?@"Shutdown":@"OK"];
	[[faultRegMatrix cellAtRow:3 column:0] setObjectValue: (faultReg & 0x10)?@"Shutdown":@"OK"];
	[[faultRegMatrix cellAtRow:4 column:0] setObjectValue: (faultReg & 0x20)?@"Shutoff":@"OK"];
	[[faultRegMatrix cellAtRow:5 column:0] setObjectValue: (faultReg & 0x40)?@"OFF":@"ON"];
	[[faultRegMatrix cellAtRow:6 column:0] setObjectValue: (faultReg & 0x40)?@"OPEN":@"OK"];
	int i;
	for(i=1;i<8;i++){
		NSTextFieldCell* aCell = [faultRegMatrix cellAtRow:i-1 column:0];
		[aCell setTextColor:(faultReg & (1<<i))?[NSColor redColor]:[NSColor blackColor]];
	}
}

- (void) statusRegisterChanged:(NSNotification*)aNote
{
	int statusReg = [model statusRegister];
	[[statusRegMatrix cellAtRow:0 column:0] setObjectValue: (statusReg & 0x2)?@"YES":@"No"];
	[[statusRegMatrix cellAtRow:1 column:0] setObjectValue: (statusReg & 0x4)?@"YES":@"NO"];
	[[statusRegMatrix cellAtRow:2 column:0] setObjectValue: (statusReg & 0x8)?@"OK":@"Fault"];
	[[statusRegMatrix cellAtRow:3 column:0] setObjectValue: (statusReg & 0x10)?@"OK":@"Faults"];
	[[statusRegMatrix cellAtRow:4 column:0] setObjectValue: (statusReg & 0x20)?@"Enabled":@"OFF"];
	[[statusRegMatrix cellAtRow:5 column:0] setObjectValue: (statusReg & 0x40)?@"Enabled":@"OFF"];
	[[statusRegMatrix cellAtRow:6 column:0] setObjectValue: (statusReg & 0x40)?@"Local":@"Remote"];
	int i;
	for(i=2;i<8;i++){
		if(i==6)continue;
		NSTextFieldCell* aCell = [statusRegMatrix cellAtRow:i column:0];
		[aCell setTextColor:(statusReg & (1<<i))?[NSColor redColor]:[NSColor blackColor]];
	}
	
}

- (void) currentChanged:(NSNotification*)aNote
{
	[currentTextField setFloatValue: [model current]];
}

- (void) actualCurrentChanged:(NSNotification*)aNote
{
	[actualCurrentTextField setFloatValue: [model actualCurrent]];
}

- (void) outputStateChanged:(NSNotification*)aNote
{
	if([model sentAddress]){
		[outputStateField setObjectValue: [model outputState]?@"ON":@"OFF"];
		[onOffButton setTitle:![model outputState]?@"TURN ON":@"TURN OFF"];
	}
	else {
		[outputStateField setObjectValue: @"--"];
		[onOffButton setTitle:@"--"];
	}
}

- (void) boardAddressChanged:(NSNotification*)aNote
{
	[boardAddressField setIntValue: [model boardAddress]];
	[[self window] setTitle:[NSString stringWithFormat:@"TDK-Lambda (Address %d)",[model boardAddress]]];
}

- (void) portStateChanged:(NSNotification*)aNotification
{
    if(aNotification == nil || [aNotification object] == [model serialPort]){
        if([model serialPort]){
            [openPortButton setEnabled:YES];
			
            if([[model serialPort] isOpen]){
                [openPortButton setTitle:@"Close"];
                [portStateField setTextColor:[NSColor colorWithCalibratedRed:0.0 green:.8 blue:0.0 alpha:1.0]];
                [portStateField setStringValue:@"Open"];
				
            }
            else {
                [openPortButton setTitle:@"Open"];
                [portStateField setStringValue:@"Closed"];
                [portStateField setTextColor:[NSColor redColor]];
            }
        }
        else {
            [openPortButton setEnabled:NO];
            [portStateField setTextColor:[NSColor blackColor]];
            [portStateField setStringValue:@"---"];
            [openPortButton setTitle:@"---"];
        }
    }
}

- (void) portNameChanged:(NSNotification*)aNotification
{
    NSString* portName = [model portName];
    
	NSEnumerator *enumerator = [ORSerialPortList portEnumerator];
	ORSerialPort *aPort;
	
    [portListPopup selectItemAtIndex:0]; //the default
    while (aPort = [enumerator nextObject]) {
        if([portName isEqualToString:[aPort name]]){
            [portListPopup selectItemWithTitle:portName];
            break;
        }
	}  
    [self portStateChanged:nil];
}


- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [[self window] setContentView:blankView];
    switch([tabView indexOfTabViewItem:tabViewItem]){
        case  0: [self resizeWindowToSize:basicOpsSize];    break;
		case  1: [self resizeWindowToSize:rampOpsSize];	    break;
    }
    [[self window] setContentView:totalView];
            
    NSString* key = [NSString stringWithFormat: @"orca.ORZup%lu.selectedtab",[model uniqueIdNumber]];
    int index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
    
}


- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORZupLock to:secure];
    [lockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNotification
{
	[self setButtonStates];
}

- (void) updateButtons
{
}

#pragma mark •••Notifications

- (void) setButtonStates
{
    //BOOL runInProgress  = [gOrcaGlobals runInProgress];
    BOOL locked			= [gSecurity isLocked:ORZupLock];
	int  ramping		= [model runningCount]>0;

    [lockButton setState: locked];
	[sendButton setEnabled:!locked && !ramping];
	[super setButtonStates];
}

- (NSString*) windowNibName
{
	return @"Zup";
}

- (NSString*) rampItemNibFileName
{
	//subclasses can specify a differant RampItem nib file if needed.
	return @"ZupRampItem";
}

#pragma mark •••Actions
- (IBAction) sendEnableSRQAction:(id)sender;
{
	[model sendStatusEnableMask];
	[model sendFailEnableMask];
}


- (IBAction) statusEnableMaskAction:(id)sender
{
	int aMask = 0;
	int i;
	for(i=1;i<8;i++){
		if([[sender cellWithTag:i] intValue]) aMask |= (1<<i);
	}
	[model setStatusEnableMask:aMask];	
}

- (IBAction) faultEnableMaskAction:(id)sender
{
	int aMask = 0;
	int i;
	for(i=1;i<8;i++){
		if([[sender cellWithTag:i] intValue]) aMask |= (1<<i);
	}
	[model setFaultEnableMask:aMask];	
}

- (IBAction) currentTextFieldAction:(id)sender
{
	[model setCurrent:[sender floatValue]];	
}

- (void) actualCurrentTextFieldAction:(id)sender
{
	[model setActualCurrent:[sender floatValue]];	
}

- (IBAction) boardAddressAction:(id)sender
{
	[model setBoardAddress:[sender intValue]];	
}

- (IBAction) getStatusAction:(id)sender
{
	[model getStatus];	
}
- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORZupLock to:[sender intValue] forWindow:[self window]];
}


- (IBAction) initBoard:(id) sender
{
	[model initBoard];
}

- (IBAction) portListAction:(id) sender
{
    [model setPortName: [portListPopup titleOfSelectedItem]];
}

- (IBAction) openPortAction:(id)sender
{
    [model openPort:![[model serialPort] isOpen]];
}

- (IBAction) onOffAction:(id)sender
{
	[model togglePower];
}

@end

@implementation ORZupController (private)

- (void) populatePortListPopup
{
	NSEnumerator *enumerator = [ORSerialPortList portEnumerator];
	ORSerialPort *aPort;
    [portListPopup removeAllItems];
    [portListPopup addItemWithTitle:@"--"];
	
	while (aPort = [enumerator nextObject]) {
        [portListPopup addItemWithTitle:[aPort name]];
	}    
}
@end


