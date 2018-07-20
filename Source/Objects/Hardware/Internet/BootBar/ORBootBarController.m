//
//  ORBootBarController.h
//  Orca
//
//  Created by Mark Howe on Thurs Jan 6,2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics 
//sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORBootBarController.h"
#import "ORBootBarModel.h"
#import "ORDotImage.h"

@implementation ORBootBarController
- (id) init
{
    self = [ super initWithWindowNibName: @"BootBar" ];
    return self;
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"Boot Bar %u (%@)",[model uniqueIdNumber],[model IPNumber]]];
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
						 name : ORBootBarModelLock
						object: nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(ipNumberChanged:)
						 name : BootBarIPNumberChanged
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(outletStatusChanged:)
                         name : ORBootBarModelStatusChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(passwordChanged:)
                         name : ORBootBarModelPasswordChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(busyStateChanged:)
                         name : ORBootBarModelBusyChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(outletNameChanged:)
                         name : ORBootBarModelOutletNameChanged
						object: model];	
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	[ipNumberComboBox reloadData];
}

- (void) updateWindow
{
    [ super updateWindow ];
	[self ipNumberChanged:nil];
    [self lockChanged:nil];
	[self outletStatusChanged:nil];
	[self passwordChanged:nil];
	[self busyStateChanged:nil];
	[self outletNameChanged:nil];
}

#pragma mark •••Notifications
- (void) outletNameChanged:(NSNotification*)aNotification
{
	short i;
	for(i=0;i<9;i++){
		[[outletNameMatrix cellWithTag:i] setStringValue: [model outletName:i]];
	}	
}

- (void) busyStateChanged:(NSNotification*)aNote
{
	[self updateButtons];
	[busyField setStringValue: [model isBusy]?@"Busy":@""];
}

- (void) passwordChanged:(NSNotification*)aNote
{
	[passwordField setStringValue: [model password]];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORBootBarModelLock to:secure];
    [lockButton setEnabled:secure];
	[self updateButtons];
}

- (void) outletStatusChanged:(NSNotification*)aNote
{
	unsigned char aMask = 0x0;
	int i;
	for(i=0;i<8;i++){
		BOOL theState = [model outletStatus:i+1];
		if(theState) aMask |= (1<<i);
		[[stateMatrix cellWithTag:i+1] setStringValue:theState?@" ON":@"OFF"];
		if(theState){
			[[stateMatrix cellWithTag:i+1] setTextColor:[NSColor colorWithCalibratedRed:0. green:.7 blue:0. alpha:1.0]];
			[[turnOnOffMatrix cellWithTag:i+1] setTitle:[NSString stringWithFormat:@"Turn %d OFF...",i+1]];
		}
		else {
			[[stateMatrix cellWithTag:i+1] setTextColor:[NSColor colorWithCalibratedRed:.7 green:0. blue:0. alpha:1.0]];
			[[turnOnOffMatrix cellWithTag:i+1] setTitle:[NSString stringWithFormat:@"Turn %d ON...",i+1]];
		}
		
	}
	[stateView setStateMask:aMask];
}

- (void) updateButtons
{
    BOOL locked	= [gSecurity isLocked:ORBootBarModelLock];
	BOOL busy	= [model isBusy];
	[passwordField setEnabled: !locked];
	[ipNumberComboBox setEnabled: !locked];
	[clrHistoryButton setEnabled: !locked];
	[turnOnOffMatrix setEnabled: !locked && !busy];
}

- (void) lockChanged:(NSNotification*)aNote
{   
    BOOL locked = [gSecurity isLocked:ORBootBarModelLock];
    [lockButton setState: locked];
    [outletNameMatrix setEnabled:!locked];
    [ipNumberComboBox setEnabled:!locked];
	[self updateButtons];
}

- (void) ipNumberChanged:(NSNotification*)aNote
{
	[ipNumberComboBox setStringValue:[model IPNumber]];
	[[self window] setTitle:[NSString stringWithFormat:@"Boot Bar %u (%@)",[model uniqueIdNumber],[model IPNumber]]];
}

#pragma mark •••Actions
-(IBAction) outletNameAction:(id)sender
{
	int tag = (int)[[sender selectedCell] tag];
	[model setOutlet:tag name:[[sender selectedCell]stringValue]];
}

- (IBAction) passwordFieldAction:(id)sender
{
	[model setPassword:[sender stringValue]];	
}

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORBootBarModelLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) ipNumberAction:(id)sender
{
	[model setIPNumber:[sender stringValue]];
}

- (IBAction) clearHistoryAction:(id)sender
{
	[model clearHistory];
}

- (IBAction) turnOnOffAction:(id)sender
{
    [self endEditing];
    int chan  = (int)[[turnOnOffMatrix selectedCell] tag];
	int state = [model outletStatus:chan];
    NSString* s1 = [NSString stringWithFormat:@"Really turn %@ Outlet #%d?",state?@"OFF":@"ON",chan];
    NSString* name = [model outletName:chan];
    if([name length]!=0)s1 = [s1 stringByAppendingFormat:@"\n\n(Description: %@)",name];
    
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:s1];
    [alert addButtonWithTitle:[NSString stringWithFormat:@"YES/Turn %@ #%d",state?@"OFF":@"ON",chan]];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            if(state)[model turnOffOutlet:chan];
            else     [model turnOnOutlet:chan];
       }
    }];
#else
    NSDictionary* context = [[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:chan],@"chan", nil] retain]; //release in confirmDidFinish()
    
    NSBeginAlertSheet(s1,
                      [NSString stringWithFormat:@"YES/Turn %@ #%d",state?@"OFF":@"ON",chan],
					  @"Cancel",
					  nil,[self window],
					  self,
					  @selector(confirmDidFinish:returnCode:contextInfo:),
					  nil,
					  context, 
					  @"");
#endif
}


#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) confirmDidFinish:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
    int chan  = [[userInfo objectForKey:@"chan"] intValue];
    int state = [model outletStatus:chan];
	if(returnCode == NSAlertFirstButtonReturn){
        if(state)[model turnOffOutlet:chan];
        else [model turnOnOutlet:chan];
    }
    [userInfo release];
}
#endif

#pragma mark •••Data Source
- (NSInteger ) numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
	return  [model connectionHistoryCount];
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
	return [model connectionHistoryItem:index];
}

@end

@implementation BootBarStateView
- (id) initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		onLight = [[ORDotImage bigDotWithColor:[NSColor greenColor]] retain];
		[onLight setSize:NSMakeSize(15,15)];
		offLight = [[ORDotImage bigDotWithColor:[NSColor redColor]] retain];
		 [offLight setSize:NSMakeSize(15,15)];
   }
    return self;
}

- (void) dealloc
{
    [offLight release];
    [onLight release];
    [super dealloc];
}

- (void) setStateMask:(unsigned char)aMask
{
    stateMask = aMask;
    [self setNeedsDisplay:YES];
}

- (void) drawRect:(NSRect)rect 
{    
    [super drawRect:rect];
    NSRect frame = [self bounds];
    NSRect sourceRect = NSMakeRect(0,0,[onLight size].width,[onLight size].height);
	int i;
	for(i=0;i<8;i++){
		BOOL state = stateMask & (1<<i);
		if(state){
			[onLight drawAtPoint:frame.origin fromRect:sourceRect operation:NSCompositingOperationSourceOver fraction:1];
		}
		else {
			[offLight drawAtPoint:frame.origin fromRect:sourceRect operation:NSCompositingOperationSourceOver fraction:1];
		}
		if(i<5)frame.origin.x += 22;
		else frame.origin.x += 21;
		if(i == 3)frame.origin.x += 64;
	}
}

@end

