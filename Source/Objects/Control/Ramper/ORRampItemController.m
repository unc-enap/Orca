//
//  ORRampItemController.m
//  Orca
//
//  Created by Mark Howe on 5/23/07.
//  Copyright 2007 CENPA, University of Washington. All rights reserved.
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


#import "ORRampItemController.h"
#import "ORRamperController.h"
#import "ORRampItem.h"
#import "ORRamperModel.h"
#import "ORAxis.h"
#import "ORHWWizard.h"
#import "ORCompositePlotView.h"

#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
@interface ORRamperController (private)
- (void) sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
@end
#endif

@implementation ORRampItemController
- (id) initWithNib:(NSString*)aNibName
{
    if( self = [super init] ){
#if !defined(MAC_OS_X_VERSION_10_9)
        [NSBundle loadNibNamed:aNibName owner:self];
#else
        [[NSBundle mainBundle] loadNibNamed:aNibName owner:self topLevelObjects:&topLevelObjects];
#endif
        
        [topLevelObjects retain];

    }
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [topLevelObjects release];

	[super dealloc];
}

- (NSView*) view
{
	return view;
}

- (void) setOwner:(ORRamperController*)anOwner
{
	owner = anOwner;
}

- (void) setModel:(id)aModel
{
	model = aModel;
	[self registerNotificationObservers];
	[self updateWindow];
	[self populatePopups];
}

- (id) model
{	
	return model;
}

#pragma mark •••Interface Management
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	[notifyCenter removeObserver:self];
		
	[notifyCenter addObserver:self
					 selector:@selector(ramperRunningChanged:) 
						 name:ORRampItemRunningChanged 
					   object:model];

    [notifyCenter addObserver : self
                     selector : @selector(reloadObjects:)
                         name : ORGroupObjectsAdded
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(reloadObjects:)
                         name : ORGroupObjectsRemoved
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(visibleChanged:)
                         name : ORRampItemVisibleChanged
                       object : model];

    [notifyCenter addObserver : self
					 selector : @selector(scaleAction:)
						 name : ORAxisRangeChangedNotification
					   object : nil];

    [notifyCenter addObserver : self
					 selector : @selector(miscAttributesChanged:)
						 name : ORRampItemMiscAttributesChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(targetNameChanged:)
						 name : ORRampItemTargetNameChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(parameterNameChanged:)
						 name : ORRampItemParameterNameChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(channelNumberChanged:)
						 name : ORRampItemChannelNumberChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(cardNumberChanged:)
						 name : ORRampItemCardNumberChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(crateNumberChanged:)
						 name : ORRampItemCrateNumberChanged
					   object : model];

    [notifyCenter addObserver : self
                     selector : @selector(parametersChanged:)
                         name : ORRamperModelParametersChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(globalEnabledChanged:)
                         name : ORRampItemGlobalEnabledChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(rampTargetChanged:)
                         name : ORRampItemRampTargetChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(currentValueChanged:)
                         name : ORRampItemCurrentValueChanged
                       object : model];
}

- (void) awakeFromNib
{
	[self updateWindow];
}

- (void) updateWindow
{
	[model setXAxisIgnoreMouse:NO];
    [self scaleAction:nil];
    [self miscAttributesChanged:nil];
	[self parametersChanged:nil];
	[self crateNumberChanged:nil];
	[self cardNumberChanged:nil];
	[self channelNumberChanged:nil];
	[self targetNameChanged:nil];
	[self parameterNameChanged:nil];
	[self globalEnabledChanged:nil];
	[self rampTargetChanged:nil];
	[self currentValueChanged:nil];
	[self visibleChanged:nil];
}

- (void) populatePopups
{
	if([owner respondsToSelector:@selector(collectObjectsConformingTo:)]){
		[targetNamePU removeAllItems];
		NSArray* wizObjects = [owner collectObjectsConformingTo:@protocol(ORHWWizard)];
		OrcaObject* obj;
		NSEnumerator* objEnumy = [wizObjects objectEnumerator];
		while(obj = [objEnumy nextObject]){
			NSArray* parameters = [model rampableParametersForTarget:obj];
			if([parameters count]){
				NSString* theName = [obj className];
				int index = (int)[targetNamePU indexOfItemWithTitle:theName];
				if(index<0)[targetNamePU addItemWithTitle:theName];
			}
		}
		if([model targetName])[targetNamePU selectItemWithTitle:[model targetName]];
	}
}

- (NSMutableDictionary*) miscAttributesForKey:(NSString*)aKey
{
	return [model miscAttributesForKey:aKey];
}

- (void) currentValueChanged:(NSNotification*)aNote
{
	[currentValueField setFloatValue:[[model  currentWayPoint] xyPosition].y];
}

- (void) targetNameChanged:(NSNotification*)aNote
{
	[targetNamePU selectItemWithTitle:[model targetName]];
}

- (void) parameterNameChanged:(NSNotification*)aNote
{
	[selectorPU selectItemWithTitle:[model parameterName]];
}

- (void) visibleChanged:(NSNotification*)aNote
{
	[visibleButton setState:[model visible]]; 
	if([model visible]){
		[self miscAttributesChanged:nil];
        [self scaleAction:nil];
		[model  checkTargetObject];
	}
}
- (void) globalEnabledChanged:(NSNotification*)aNote
{
	[globalEnableButton setIntValue:[model globalEnabled]];
}

- (void) crateNumberChanged:(NSNotification*)aNote
{
	[crateNumberField setIntValue:[model crateNumber]];
}

- (void) cardNumberChanged:(NSNotification*)aNote
{
	[cardNumberField setIntValue:[model cardNumber]];
}

- (void) channelNumberChanged:(NSNotification*)aNote
{
	[channelNumberField setIntValue:[model channelNumber]];
}

- (void) rampTargetChanged:(NSNotification*)aNote
{
	[rampTargetField setFloatValue:[model rampTarget]];
}

- (void) parametersChanged:(NSNotification*)aNotification
{
	[selectorPU removeAllItems];
	NSArray* p = [model parameterList];
	NSEnumerator* e = [p objectEnumerator];
	id item;
	while(item = [e nextObject]){
		[selectorPU addItemWithTitle:[item name]];
	}
	[model setParameterName:[selectorPU titleOfSelectedItem]];
}

- (void) setButtonStates
{
	BOOL lockedOrRunning = [model isRunning];
	[startStopButton setTitle:[model isRunning]?@"Stop":@"Start"];
	[selectorPU  setEnabled:!lockedOrRunning];
	[targetNamePU  setEnabled:!lockedOrRunning];
	[crateNumberField  setEnabled:!lockedOrRunning];
	[cardNumberField  setEnabled:!lockedOrRunning];
	[channelNumberField  setEnabled:!lockedOrRunning];
	[minusButton  setEnabled:!lockedOrRunning];
	[rampTargetField  setEnabled:!lockedOrRunning];

	if([model isRunning])[progressIndicator startAnimation:self];
	else [progressIndicator stopAnimation:self];
	[model setXAxisIgnoreMouse:lockedOrRunning];
}


- (void) reloadObjects:(NSNotification*)aNote
{
	[self populatePopups];
	[model checkTargetObject];
    [self setButtonStates];
}

- (void) ramperRunningChanged:(NSNotification*)aNote
{
    [self setButtonStates];
}

- (void) scaleAction:(NSNotification*)aNotification
{
	if(![model visible])return;
	
	if(aNotification == nil || [aNotification object] == [owner xAxis]){
		[model setMiscAttributes:[[owner xAxis] attributes] forKey:@"xAxis"];
		[model  scaleToMaxTime:[[owner xAxis] maxValue]];
		[[owner ramperView] setXLabel:@"Time (sec)"];
	}
	
	if(aNotification == nil || [aNotification object] == [owner yAxis]){
		[model setMiscAttributes:[[owner yAxis] attributes] forKey:@"yAxis"];
		[[owner ramperView] setYLabel:[model parameterName]];
	}
}


- (void) miscAttributesChanged:(NSNotification*)aNote
{
	if(![model visible])return;
	
	NSString*				key = [[aNote userInfo] objectForKey:ORRampItemMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString:@"xAxis"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"xAxis"];
		if(attrib){
			[[owner xAxis] setAttributes:attrib];
			[[owner xAxis] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"yAxis"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"yAxis"];
		if(attrib){
			[[owner yAxis] setAttributes:attrib];
			[[owner yAxis] setNeedsDisplay:YES];
		}
	}
}



- (IBAction) globalEnabledAction:(id)sender
{
	[model setGlobalEnabled:[sender intValue]];
}

- (IBAction) crateNumberAction:(id)sender
{
	[model setCrateNumber:[sender intValue]];
}

- (IBAction) cardNumberAction:(id)sender
{
	[model setCardNumber:[sender intValue]];
}

- (IBAction) channelNumberAction:(id)sender
{
	[model setChannelNumber:[sender intValue]];
}


- (IBAction) startStop:(id)sender
{
	[self endEditing];
	if([model isRunning]){
		[model stopRamper];
	}
	else {
		//[self endEditing];
		//[model scaleToMaxTime:[xAxis maxValue]];
		[model startRamper];
	}
}

- (IBAction) stop:(id)sender
{
	[model stopRamper];
}

- (IBAction) panic:(id)sender
{
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"Panic!"];
    [alert setInformativeText:@"REALLY Panic this parameter to zero?\nIs this really what you want?"];
    [alert addButtonWithTitle:@"Yes, Do Panic"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[owner window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            [model panic];
       }
    }];
#else
    NSBeginAlertSheet(@"Panic!",@"Cancel",@"YES/Do Panic",nil,[owner window],self,@selector(sheetDidEnd:returnCode:contextInfo:),nil,nil, @"REALLY Panic this parameter to zero?\nIs this really what you want?");
#endif
}

- (IBAction) targetSelectionAction:(id)sender
{
	[model setTargetName:[sender titleOfSelectedItem]];
	[model loadProxyObjects];
	[self miscAttributesChanged:nil];
    [self scaleAction:nil];
	[model  checkTargetObject];
}


- (IBAction) paramSelectionAction:(id)sender
{
	NSString* pName = [sender titleOfSelectedItem];
	[model loadProxyObjects];
	[model setParameterName:pName];
	[model prepareForScaleChange];
	[model loadParameterObject];
	[self miscAttributesChanged:nil];
    [self scaleAction:nil];
}

- (IBAction) insertRampItem:(id)sender
{
	ORRampItem* anItem = [model copy];
	[[model owner] addRampItem:anItem afterItem:model];
	[[model owner] setSelectedRampItem:anItem];	
	[anItem release];
}

- (IBAction) removeRampItem:(id)sender
{
	[model removeSelf];
}

- (IBAction) selectItem:(id)sender
{
	[self endEditing];
	[[model owner] setSelectedRampItem:model];	
	[self miscAttributesChanged:nil];
    [self scaleAction:nil];
	[model  checkTargetObject];
}

- (IBAction) rampTargetAction:(id)sender
{
	[model setRampTarget:[sender floatValue]];
}

- (void) endEditing
{
	//commit all text editing... subclasses should call before doing their work.
	if(![[owner window] makeFirstResponder:[owner window]]){
		[[owner window] endEditingFor:nil];		
	}
}
@end

#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
@implementation ORRampItemController (private)
- (void) sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode == NSAlertAlternateReturn){
		[model panic];
	}
}
@end
#endif
