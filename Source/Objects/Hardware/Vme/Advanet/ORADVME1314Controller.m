//
//  ORADVME1314Controller.m
//  Orca
//
//  Created by Michael Marino on Mon 6 Feb 2012 
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


#pragma mark ¥¥¥Imported Files
#import "ORADVME1314Controller.h"
#import "ORADVME1314Model.h"


#pragma mark ¥¥¥Definitions

@implementation ORADVME1314Controller

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"ADVME1314"];
    
    return self;
}


- (void) awakeFromNib
{
	[logicView setGroup:model];
    [super awakeFromNib];
}

- (ORTriggerLogicView *)logicView
{
    return logicView;
}


- (void) setModel:(OrcaObject*)aModel
{
    [super setModel:aModel];
    [logicView setGroup:(ORGroup*)model];
}


#pragma mark ¥¥¥Notifications
-(void)registerNotificationObservers
{
    
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	[super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(writeMaskChanged:)
                         name : ORADVME1314WriteMaskChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(writeValueChanged:)
                         name : ORADVME1314WriteValueChangedNotification
                       object : model];
    
	
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORVmeCardSlotChangedNotification
					   object : model];    
	
    [notifyCenter addObserver : self
                     selector : @selector(baseAddressChanged:)
                         name : ORVmeIOCardBaseAddressChangedNotification
                       object : model];    
	
}

#pragma mark ¥¥¥Interface Management
-(void)updateWindow
{
	[super updateWindow];
    [self writeMaskChanged:nil];
    [self writeValueChanged:nil];
    [self slotChanged:nil];
    [self baseAddressChanged:nil];    
    //[logicView setNeedsDisplay:YES];
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"ADVME1314 (Slot: %d)",[model slot]]];
}

-(void)writeMaskChanged:(NSNotification*)aNotification
{
	ADVME1314ChannelDat value = [model writeMask];
	short i,j;
    int numberOfColumns = (int)[writeMaskBitMatrix numberOfColumns];
    for (j=0; j<sizeof(value)/sizeof(value.channelDat[0]);j++) {
        [[writeMaskHexField cellAtRow:j column:0] setIntValue:value.channelDat[j]];
        for(i=0;i<numberOfColumns;i++){
            [[writeMaskBitMatrix cellAtRow:j column:(numberOfColumns - i - 1)] setIntValue:(value.channelDat[j] & (1L<<i))];
        }        
    }

}

-(void)writeValueChanged:(NSNotification*)aNotification
{
	ADVME1314ChannelDat value = [model writeValue];    
	short i,j;
    int numberOfColumns = (int)[writeMaskBitMatrix numberOfColumns];
    for (j=0; j<sizeof(value)/sizeof(value.channelDat[0]);j++) {
        [[writeHexField cellAtRow:j column:0] setIntValue:value.channelDat[j]];
        for(i=0;i<numberOfColumns;i++){
            [[writeBitMatrix cellAtRow:j column:(numberOfColumns - i - 1)] setIntValue:(value.channelDat[j] & (1L<<i))];
        }        
    }
}

- (void) baseAddressChanged:(NSNotification *)aNotification
{
    [baseAddress setIntegerValue:[model baseAddress]];
}

#pragma mark ¥¥¥Actions

-(IBAction)write:(id)sender
{
    @try {
        [self endEditing];
        [model setOutputWithMask:[model writeMask] value:[model writeValue]];
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

-(IBAction)writeMaskHexAction:(id)sender
{
    ADVME1314ChannelDat dat = [model writeMask];
    if([[sender selectedCell] intValue] != dat.channelDat[[[sender selectedCell] tag]]){
        [[self undoManager] setActionName: @"Set ADVME 1314 Write Mask"];
        dat.channelDat[[[sender selectedCell] tag]] = [[sender selectedCell] intValue];
        [model setWriteMask:dat];
    }
}

-(IBAction)writeMaskBitAction:(id)sender
{
    [[self undoManager] setActionName: @"Set ADVME 1314 Write Mask"];
    int i,j;
    ADVME1314ChannelDat val;
    memset(&val, 0, sizeof(val));
    for (j=0; j<sizeof(val)/sizeof(val.channelDat[0]);j++) {
        [[writeMaskHexField cellAtRow:j column:0] setIntValue:val.channelDat[j]];
        int number = (int)[writeMaskBitMatrix numberOfColumns];
        for(i=0;i<number;i++){
            NSButtonCell* anObj = [writeMaskBitMatrix cellAtRow:j column:(number-i-1)];
            if([anObj intValue]){
                val.channelDat[j] |= (1L<<i);
            }
        }        
    }    
    [model setWriteMask:val];
}

-(IBAction)writeValueHexAction:(id)sender
{
    ADVME1314ChannelDat dat = [model writeValue];
    if([[sender selectedCell] intValue] != dat.channelDat[[[sender selectedCell] tag]]){
        [[self undoManager] setActionName: @"Set ADVME 1314 Write Value"];
        dat.channelDat[[[sender selectedCell] tag]] = [[sender selectedCell] intValue];
        [model setWriteValue:dat];        
    }
}

-(IBAction)writeValueBitAction:(id)sender
{
    [[self undoManager] setActionName: @"Set ADVME 1314 Write Value"];
    ADVME1314ChannelDat val;
    int i,j;
    memset(&val, 0, sizeof(val));
    for (j=0; j<sizeof(val)/sizeof(val.channelDat[0]);j++) {
        [[writeHexField cellAtRow:j column:0] setIntValue:val.channelDat[j]];
        int number = (int)[writeBitMatrix numberOfColumns];        
        for(i=0;i<number;i++){
            NSButtonCell* anObj = [writeBitMatrix cellAtRow:j column:(number-i-1)];
            if([anObj intValue]){
                val.channelDat[j] |= (1L<<i);
            }
        }        
    }          
    [model setWriteValue:val];
}

- (IBAction)baseAddressAction:(id)sender
{
    if ([sender intValue] != [model baseAddress]) {
        [model setBaseAddress:[sender intValue]];
    }
}

@end
