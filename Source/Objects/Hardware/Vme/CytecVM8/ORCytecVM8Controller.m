//
//  ORCytecVM8Controller.m
//  Created by Mark Howe on Mon 22 Aug 2016
//  Copyright © 2016, University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina  sponsored in part by the United States
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
#import "ORCytecVM8Controller.h"
#import "ORCytecVM8Model.h"

@implementation ORCytecVM8Controller

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"CytecVM8"];
    return self;
}
- (void) awakeFromNib
{
    int i;
    for(i=0;i<32;i++){
        [[writeBitMatrix cellAtRow:0 column:31 - i] setTag:i];
    }
    [super awakeFromNib];
}
#pragma mark •••Notifications
-(void)registerNotificationObservers
{
    
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	[super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(writeValueChanged:)
                         name : ORCytecVM8WriteValueChanged
                       object : model];
    
	
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORVmeCardSlotChangedNotification
					   object : model];    
	
    [notifyCenter addObserver : self
                     selector : @selector(baseAddressChanged:)
                         name : ORVmeIOCardBaseAddressChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(boardIdChanged:)
                         name : ORCytectVM8BoardIdChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(deviceTypeChanged:)
                         name : ORCytectVM8DeviceTypeChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(formCChanged:)
                         name : ORCytectVM8FormCChanged
                       object : model];
    

}

#pragma mark •••Interface Management
-(void)updateWindow
{
	[super updateWindow];
    [self writeValueChanged:nil];
    [self slotChanged:nil];
    [self baseAddressChanged:nil];
    [self boardIdChanged:nil];
    [self deviceTypeChanged:nil];
    [self formCChanged:nil];
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"CytecVM8 (Slot: %d)",[model slot]]];
}

- (void) boardIdChanged:(NSNotification*)aNotification
{
    [boardIdField setStringValue:[NSString stringWithFormat:@"0x%0x",[model boardId]]];
}

- (void) formCChanged:(NSNotification*)aNotification
{
    [formCCB setIntValue:[model formC]];
}

- (void) deviceTypeChanged:(NSNotification*)aNotification
{
    [deviceTypeField setStringValue:[NSString stringWithFormat:@"0x%0x",[model deviceType]]];
}

- (void) writeValueChanged:(NSNotification*)aNotification
{
	uint32_t value = [model writeValue];
	short i;
    for(i=0;i<32;i++){
        [[writeBitMatrix cellAtRow:0 column:31 - i] setIntegerValue:(value & (1L<<i))];
    }
    [writeHexField setIntegerValue:value];
}

- (void) baseAddressChanged:(NSNotification *)aNotification
{
    [baseAddress setIntegerValue:[model baseAddress]];
}

#pragma mark •••Actions
- (IBAction)write:(id)sender
{
    @try {
        [self endEditing];
        [model writeRelays:[model writeValue]];
    }
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@", @"OK", nil, nil,
						localException);
    }
}

- (IBAction) dump:(id)sender
{
    @try {
        [model dump];
    }
    @catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) sync:(id)sender
{
    @try {    
        [model syncWithHardware];
    }
    @catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) reset:(id)sender
{
    @try {
        [model reset];
    }
    @catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) probeBoardAction:(id)sender
{
    @try {
        [model readBoardId];
        [model readDeviceType];
    }
    @catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) writeValueHexAction:(id)sender
{
    [model setWriteValue:[sender intValue]];
}

- (IBAction) writeValueBitAction:(id)sender
{
    uint32_t value = [model writeValue];
    int bit      = (int)[[sender selectedCell] tag];
    int bitValue = [sender intValue];
    
    if(bitValue) value |=  (0x1<<bit);
    else         value &=  ~(0x1<<bit);
        
    [model setWriteValue:value];
}

- (IBAction) formCAction:(id)sender
{
    [model setFormC:[sender intValue]];
}

- (IBAction) baseAddressAction:(id)sender
{
    if ([sender intValue] != [model baseAddress]) {
        [model setBaseAddress:[sender intValue]];
    }
}
@end
