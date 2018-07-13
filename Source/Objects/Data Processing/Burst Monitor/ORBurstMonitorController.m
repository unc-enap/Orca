//
//  ORBurstMonitorController.m
//  Orca
//
//  Created by Mark Howe on Wed Nov 20 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORBurstMonitorController.h"
#import "ORBurstMonitorModel.h"
#import "ORValueBarGroupView.h"
#import "ORValueBar.h"
#import "ORAxis.h"

@implementation ORBurstMonitorController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"BurstMonitor"];
	return self;
}

- (void) awakeFromNib
{
    int i;
    for(i=0;i<32;i++){
        [[queueLowChannelMatrix cellAtRow:i column:0] setTag:i];
        [[queueHiChannelMatrix cellAtRow:i column:0] setTag:i+32];
        [[channelGroup0Matrix cellAtRow:i column:0] setStringValue:@"-"];
        [[channelGroup1Matrix cellAtRow:i column:0] setStringValue:@"-"];
    }
	[[queue0Holdings xAxis] setRngLimitsLow:0 withHigh:100000 withMinRng:10];
	[[queue1Holdings xAxis] setRngLimitsLow:0 withHigh:100000 withMinRng:10];
 
    [[queue0Holdings xAxis] setDefaultRangeHigh:50];
    [[queue1Holdings xAxis] setDefaultRangeHigh:50];

    
	[queue0Holdings setNumber:32 height:10 spacing:4];
	[queue1Holdings setNumber:32 height:10 spacing:4];
    
    for(id aBar in [queue0Holdings valueBars]){
        [aBar setBackgroundColor:[NSColor lightGrayColor]];
        [aBar setBarColor:[NSColor redColor]];
    }
    for(id aBar in [queue1Holdings valueBars]){
        [aBar setBackgroundColor:[NSColor lightGrayColor]];
        [aBar setBarColor:[NSColor redColor]];
    }
   
	[super awakeFromNib];
}

#pragma mark •••Notifications

- (void) registerNotificationObservers
{
	[super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

	 //we don't want this notification
    [notifyCenter removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(timeWindowChanged:)
                         name : ORBurstMonitorTimeWindowChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(nHitChanged:)
                         name : ORBurstMonitorNHitChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(numBurstsNeededChanged:)
                         name : ORBurstMonitorModelNumBurstsNeededChanged
                       object : model];

    
    [notifyCenter addObserver : self
                     selector : @selector(minimumEnergyAllowedChanged:)
                         name : ORBurstMonitorMinimumEnergyAllowedChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(queueChanged:)
                         name : ORBurstMonitorQueueChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(emailListChanged:)
                         name : ORBurstMonitorEmailListChanged
						object: model];
    
    [notifyCenter addObserver : self
					 selector : @selector(scaleAction:)
						 name : ORAxisRangeChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(miscAttributesChanged:)
						 name : ORMiscAttributesChanged
					   object : model];

}

#pragma mark •••Interface Management

-(void) updateWindow
{
    [super updateWindow];
    [self timeWindowChanged:nil];
    [self nHitChanged:nil];
    [self minimumEnergyAllowedChanged:nil];
    [self queueChanged:nil];
    [self numBurstsNeededChanged:nil];
}

//a fake action from the scale object so we can store the state
- (void) scaleAction:(NSNotification*)aNotification
{
	if(aNotification == nil || [aNotification object] == [queue0Holdings xAxis]){
		[model setMiscAttributes:[[queue0Holdings xAxis]attributes] forKey:@"Queue0XAttributes"];
	//}
	//else if(aNotification == nil || [aNotification object] == [queue1Holdings xAxis]){
		[model setMiscAttributes:[[queue1Holdings xAxis]attributes] forKey:@"Queue1Attributes"];
	}
}

- (void) miscAttributesChanged:(NSNotification*)aNote
{
	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString:@"Queue0XAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"Queue0XAttributes"];
		if(attrib){
			[[queue0Holdings xAxis] setAttributes:attrib];
			[queue0Holdings setNeedsDisplay:YES];
			[[queue0Holdings xAxis] setNeedsDisplay:YES];
		}
	//}
    
    //else if(aNote == nil || [key isEqualToString:@"Queue1Attributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"Queue1Attributes"];
		if(attrib){
			[[queue1Holdings xAxis] setAttributes:attrib];
			[queue1Holdings setNeedsDisplay:YES];
			[[queue1Holdings xAxis] setNeedsDisplay:YES];
		}
	}
}

- (void) timeWindowChanged:(NSNotification*)aNotification
{
	[timeWindowField setDoubleValue: [model timeWindow]]; //CB was setIntValue
}

- (void) numBurstsNeededChanged:(NSNotification*)aNotification
{
	[numBurstsNeededField setIntValue: [model numBurstsNeeded]];
}

- (void) nHitChanged:(NSNotification*)aNotification
{
	[nHitField setIntValue: [model nHit]];
}

- (void) minimumEnergyAllowedChanged:(NSNotification *)aNotification
{
    [minimumEnergyAllowedField setIntValue: [model minimumEnergyAllowed]];
}

- (void) queueChanged:(NSNotification*)aNotification
{
	if(!updateScheduled){
		updateScheduled = YES;
		[self performSelector:@selector(delayedQueueUpdate) withObject:nil afterDelay:1];
	}
}

- (void) delayedQueueUpdate
{
    [model lockArray];
	updateScheduled = NO;
    NSArray* allKeys = [[[model queueMap] allKeys]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] ;
    NSDictionary* queueMap = [model queueMap];
    if([allKeys count]){
        for(id aKey in allKeys){
            int i  =[[queueMap objectForKey:aKey]intValue];
            unsigned int theCount = (unsigned int)[[[model queueArray]objectAtIndex:i] count];
            if(i<32){
                [[channelGroup0Matrix cellAtRow:i column:0] setStringValue:aKey];
                [[queueLowChannelMatrix cellAtRow:i column:0] setIntValue:theCount];
            }
            else {
                [[channelGroup1Matrix cellAtRow:i-32 column:0] setStringValue:aKey];
                [[queueHiChannelMatrix cellAtRow:i-32 column:0] setIntValue:theCount];
            }
        }
    }
    else {
        int i;
        for(i=0;i<32;i++){
            [[channelGroup0Matrix cellAtRow:i column:0] setStringValue:@"-"];
            [[queueLowChannelMatrix cellAtRow:i column:0] setIntValue:0];
            [[channelGroup1Matrix cellAtRow:i column:0] setStringValue:@"-"];
            [[queueHiChannelMatrix cellAtRow:i column:0] setIntValue:0];
            
        }
    }
    [model unlockArray];

    [queue0Holdings setNeedsDisplay:YES];
    [queue1Holdings setNeedsDisplay:YES];

}

- (void) emailListChanged:(NSNotification*)aNotification
{
	[emailListTable reloadData];
}

#pragma mark •••Actions
- (IBAction) timeWindowAction:(id)sender
{
	if([sender doubleValue] != [model timeWindow]){
		[[self undoManager] setActionName: @"Set Time Window"];
		[model setTimeWindow:[sender doubleValue]];
	}
}

- (IBAction) nHitAction:(id)sender
{
	if([sender intValue] != [model nHit]){
		[[self undoManager] setActionName: @"Set N Hit"];
		[model setNHit:[sender intValue]];
	}
}

- (IBAction) numBurstsNeededAction:(id)sender
{
	if([sender intValue] != [model nHit]){
		[[self undoManager] setActionName: @"Set Num Bursts Needed"];
		[model setNumBurstsNeeded:[sender intValue]];
	}
}

- (IBAction) minimumEnergyAllowedAction:(id)sender
{
    if([sender intValue] != [model minimumEnergyAllowed]){
        [[self undoManager] setActionName: @"Set Minimum Energy Allowed"];
        [model setMinimumEnergyAllowed:[sender intValue]];
    }
}

- (IBAction) addAddress:(id)sender
{
	int index = (int)[[model emailList] count];
	[model addAddress:@"<eMail>" atIndex:index];
	NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:index];
	[emailListTable selectRowIndexes:indexSet byExtendingSelection:NO];
	[emailListTable reloadData];
}

- (IBAction) removeAddress:(id)sender
{
	//only one can be selected at a time. If that restriction is lifted then the following will have to be changed
	//to something a lot more complicated.
	NSIndexSet* theSet = [emailListTable selectedRowIndexes];
	int current_index = (int)[theSet firstIndex];
    if(current_index != NSNotFound){
		[model removeAddressAtIndex:current_index];
	}
	[emailListTable reloadData];
}

- (IBAction) lockAction:(id)sender
{
    [gSecurity tryToSetLock:ORBurstMonitorLock to:[sender intValue] forWindow:[self window]];
}

#pragma mark •••Table Data Source
- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
    if(aTableView == emailListTable){
		return [[model emailList] count];
    }
    return 0;
}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if(aTableView == emailListTable){
		if(rowIndex < [[model emailList] count]){
			id addressObj = [[model emailList] objectAtIndex:rowIndex];
			return addressObj;
		}
		else{
            return @"";
        }
	}
    return @"";
}

- (void) tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if(aTableView == emailListTable){
		if(rowIndex < [[model emailList] count]){
			[[model emailList] replaceObjectAtIndex:rowIndex withObject:anObject];
		}
	}
}

- (void) tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if([aNotification object] == emailListTable || aNotification == nil){
		NSInteger selectedIndex = [emailListTable selectedRow];
		[removeAddressButton setEnabled:selectedIndex>=0];
	}
}
@end
