//
//  ORIP408Controller.m
//  Orca
//
//  Created by Mark Howe on Mon Feb 10 2003.
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
#import "ORIP408Controller.h"
#import "ORIP408Model.h"


#pragma mark ¥¥¥Definitions

@implementation ORIP408Controller

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"IP408"];
    
    return self;
}

#pragma mark ¥¥¥Notifications
-(void)registerNotificationObservers
{
    
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	[super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(writeMaskChanged:)
                         name : ORIP408WriteMaskChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(writeValueChanged:)
                         name : ORIP408WriteValueChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(readMaskChanged:)
                         name : ORIP408ReadMaskChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(readValueChanged:)
                         name : ORIP408ReadValueChangedNotification
                       object : model];
    
	
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORVmeCardSlotChangedNotification
					   object : model];
	
}

#pragma mark ¥¥¥Interface Management
-(void)updateWindow
{
	[super updateWindow];
    [self writeMaskChanged:nil];
    [self writeValueChanged:nil];
    [self readMaskChanged:nil];
    [self readValueChanged:nil];
    [self slotChanged:nil];
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"IP408 (%@)",[model identifier]]];
}

-(void)writeMaskChanged:(NSNotification*)aNotification
{
	uint32_t value = [model writeMask];
	[writeMaskDecimalField setIntegerValue: value];
	[writeMaskHexField setIntegerValue: value];
	short i;
	for(i=0;i<[writeMaskBitMatrix numberOfColumns];i++){
		[[writeMaskBitMatrix cellWithTag:i] setIntegerValue:(value & 1L<<i)];
	}
}

-(void)writeValueChanged:(NSNotification*)aNotification
{
	uint32_t value = [model writeValue];
	[writeDecimalField setIntegerValue: value];
	[writeHexField setIntegerValue: value];
	short i;
	for(i=0;i<[writeBitMatrix numberOfColumns];i++){
		[[writeBitMatrix cellWithTag:i] setIntegerValue:(value & 1L<<i)];
	}
}

-(void)readMaskChanged:(NSNotification*)aNotification
{
	uint32_t value = [model readMask];
	[readMaskDecimalField setIntegerValue: value];
	[readMaskHexField setIntegerValue: value];
	short i;
	for(i=0;i<[readMaskBitMatrix numberOfColumns];i++){
		[[readMaskBitMatrix cellWithTag:i] setIntegerValue:(value & 1L<<i)];
	}
	
}

-(void)readValueChanged:(NSNotification*)aNotification
{
	uint32_t value = [model readValue];
	[readDecimalField setIntegerValue: value];
	[readHexField setIntegerValue: value];
	short i;
	for(i=0;i<[readBitMatrix numberOfColumns];i++){
		[[readBitMatrix cellWithTag:i] setIntegerValue:(value & 1L<<i)];
	}    
}



#pragma mark ¥¥¥Actions
-(IBAction)read:(id)sender
{
    @try {
        [self endEditing];
        uint32_t value = [model getInputWithMask:[model readMask]];
        [model setReadValue:value];
    }
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@", @"OK", nil, nil,
						localException);
    }
}

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


-(IBAction)writeMaskDecimalAction:(id)sender
{
    if([sender intValue] != [model writeMask]){
        [[self undoManager] setActionName: @"Set 408 Write Mask"];
        [model setWriteMask:[sender intValue]];
    }
}

-(IBAction)writeMaskHexAction:(id)sender
{
    if([sender intValue] != [model writeMask]){
        [[self undoManager] setActionName: @"Set 408 Write Mask"];
        [model setWriteMask:[sender intValue]];
    }
}

-(IBAction)writeMaskBitAction:(id)sender
{
    if([sender intValue] != [model writeMask]){
        [[self undoManager] setActionName: @"Set 408 Write Mask"];
        int i;
        NSInteger number = [writeMaskBitMatrix numberOfColumns];
        NSButtonCell* anObj;
        int32_t val = 0;
        NSUInteger tag;
        for(i=0;i<number;i++){
            anObj = [writeMaskBitMatrix cellAtRow:0 column:i];
            tag = [anObj tag];
            if([anObj intValue]){
                val |= 1L<<tag;
            }
        }
        [model setWriteMask:val];
    }
}

-(IBAction)writeValueDecimalAction:(id)sender
{
    if([sender intValue] != [model writeValue]){
        [[self undoManager] setActionName: @"Set 408 Write Value"];
        [model setWriteValue:[sender intValue]];
    }
}

-(IBAction)writeValueHexAction:(id)sender
{
    if([sender intValue] != [model writeValue]){
        [[self undoManager] setActionName: @"Set 408 Write Value"];
        [model setWriteValue:[sender intValue]];
    }
}

-(IBAction)writeValueBitAction:(id)sender
{
    if([sender intValue] != [model writeValue]){
        [[self undoManager] setActionName: @"Set 408 Value Mask"];
        int i;
        NSInteger number = [writeBitMatrix numberOfColumns];
        NSButtonCell* anObj;
        int32_t val = 0;
        NSUInteger tag;
        for(i=0;i<number;i++){
            anObj = [writeBitMatrix cellAtRow:0 column:i];
            tag = [anObj tag];
            if([anObj intValue]){
                val |= 1L<<tag;
            }
        }
        [model setWriteValue:val];
    }
    
}

-(IBAction)readMaskDecimalAction:(id)sender
{
    if([sender intValue] != [model readMask]){
        [[self undoManager] setActionName: @"Set 408 Read Mask"];
        [model setReadMask:[sender intValue]];
    }
}

-(IBAction)readMaskHexAction:(id)sender
{
    if([sender intValue] != [model readMask]){
        [[self undoManager] setActionName: @"Set 408 Read Mask"];
        [model setReadMask:[sender intValue]];
    }
}

-(IBAction)readMaskBitAction:(id)sender
{
    if([sender intValue] != [model readMask]){
        [[self undoManager] setActionName: @"Set 408 Read Mask"];
        int i;
        NSInteger number = [readMaskBitMatrix numberOfColumns];
        NSButtonCell* anObj;
        int32_t val = 0;
        NSUInteger tag;
        for(i=0;i<number;i++){
            anObj = [readMaskBitMatrix cellAtRow:0 column:i];
            tag = [anObj tag];
            if([anObj intValue]){
                val |= 1L<<tag;
            }
        }
        [model setReadMask:val];
    }
}




@end
