//
//  ORHWizSelectionController.m
//  SubviewTableViewRuleEditor
//
//  Created by Mark Howe on Tue Dec 02 2003.
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


#import "ORHWizSelectionController.h"
#import "ORHWWizSelection.h"

#pragma mark ***External Strings
NSString* ORSelectionControllerSelectionChangedNotification      = @"ORSelectionControllerSelectionChangedNotification";
NSString* ORSelectionControllerSelectionValueChangedNotification = @"ORSelectionControllerSelectionValueChangedNotification";

@implementation ORHWizSelectionController

+ (id) controller
{
    return [[[self alloc] init] autorelease];
}

- (id) init
{
    self = [super init];
#if !defined(MAC_OS_X_VERSION_10_9)
    [NSBundle loadNibNamed:@"SelectionView" owner:self];
#else
    [[NSBundle mainBundle] loadNibNamed:@"SelectionView" owner:self topLevelObjects:&topLevelObjects];
    [topLevelObjects retain];
#endif

    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [topLevelObjects release];
    [selectionArray release];
    
    [super dealloc];
}

- (void) awakeFromNib
{
    [self registerNotificationObservers];
    
    [self updateWindow];
}


#pragma mark ***Accessors
- (NSArray *)selectionArray
{
    return selectionArray; 
}

- (void)setSelectionArray:(NSArray *)aSelectionArray
{
    [aSelectionArray retain];
    [selectionArray release];
    selectionArray = aSelectionArray;
}

- (NSView *) view
{
    return subview;
}

- (int) logicalTag
{
	return logicalTag;
}
- (void) setLogicalTag:(int)aNewLogicalTag
{
	[[[self undoManager] prepareWithInvocationTarget:self] setLogicalTag:logicalTag];
    
	logicalTag = aNewLogicalTag;
    
	[[NSNotificationCenter defaultCenter] 
			postNotificationName:ORSelectionControllerSelectionChangedNotification 
                          object: self];
}

- (int) objTag
{
	return objTag;
}
- (void) setObjTag:(int)aNewObjTag
{
	[[[self undoManager] prepareWithInvocationTarget:self] setObjTag:objTag];
    
	objTag = aNewObjTag;
    
	[[NSNotificationCenter defaultCenter] 
			postNotificationName:ORSelectionControllerSelectionChangedNotification 
                          object: self];
}

- (int) selectionTag
{
	return selectionTag;
}
- (void) setSelectionTag:(int)aNewSelectionTag
{
	[[[self undoManager] prepareWithInvocationTarget:self] setSelectionTag:selectionTag];
    
	selectionTag = aNewSelectionTag;
    
	[[NSNotificationCenter defaultCenter] 
			postNotificationName:ORSelectionControllerSelectionChangedNotification 
                          object: self];
}

- (int) selectionValue
{
	return selectionValue;
}
- (void) setSelectionValue:(int)aNewSelectionValue
{
	[[[self undoManager] prepareWithInvocationTarget:self] setSelectionValue:selectionValue];
    
	selectionValue = aNewSelectionValue;
    
	[[NSNotificationCenter defaultCenter] 
			postNotificationName:ORSelectionControllerSelectionValueChangedNotification 
                          object: self];
}

- (NSUndoManager *)undoManager
{
    return [[(ORAppDelegate*)[NSApp delegate]document]  undoManager];
}


#pragma mark ***Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter removeObserver:self];
    
    [notifyCenter addObserver : self
                      selector: @selector(selectionChanged:)
                          name: ORSelectionControllerSelectionChangedNotification
                       object : self];
    
    [notifyCenter addObserver : self
                      selector: @selector(setupSelection)
                          name: ORGroupObjectsAdded
                       object : nil];
    
    [notifyCenter addObserver : self
                      selector: @selector(setupSelection)
                          name: ORGroupObjectsRemoved
                       object : nil];
    
    [notifyCenter addObserver : self
                      selector: @selector(selectionValueChanged:)
                          name: ORSelectionControllerSelectionValueChangedNotification
                       object : self];
    

}

- (void) updateWindow
{
    [self selectionChanged:nil];
    [self selectionValueChanged:nil];
}
    
- (void) configChanged:(NSNotification*)aNote
{
    [self setupSelection];
}
    
- (void) selectionChanged:(NSNotification*)aNote
{
    if((aNote == nil || [aNote object] == self )){
        [self setupSelection];
    }
}
    
- (void) setupSelection
{
    [logicalPopUpButton selectItemAtIndex:[self logicalTag]];
    [objPopUpButton selectItemAtIndex:[self objTag]];
    [selectionPopUpButton selectItemAtIndex:[self selectionTag]];
    
    ORHWWizSelection* obj = [selectionArray objectAtIndex:objTag];
    [obj scanConfiguration];
    
    int theMaxValue = [obj maxValue];
    
    [selectionStepper setMinValue:0];
    [selectionStepper setMaxValue:theMaxValue];
    [selectionStepper setIncrement:1];
    
    if([selectionTextField intValue]>theMaxValue){
        [selectionTextField setIntValue:theMaxValue];
    }
    
    [selectionTextField setEnabled:selectionTag!=0];
    [selectionStepper setEnabled:selectionTag!=0];
    
}
    
- (void) selectionValueChanged:(NSNotification*)aNote
{
    if((aNote == nil || [aNote object] == self )){
        [selectionTextField setIntValue:[self selectionValue]];
        [selectionStepper setIntValue:[self selectionValue]];
    }
}

- (void) enableForRow:(int)row
{
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_3
    [logicalPopUpButton setHidden:row == 0];
#else
    [logicalPopUpButton setEnabled:row != 0];
#endif
}


#pragma mark ***Actions

- (IBAction) logicalPopUpButtonAction:(id)sender
{
    [self setLogicalTag:(int)[sender indexOfSelectedItem]];
}

- (IBAction) objPopUpButtonAction:(id)sender
{
    [self setObjTag:(int)[sender indexOfSelectedItem]];
}

- (IBAction) selectionPopUpButtonAction:(id)sender
{
    [self setSelectionTag:(int)[sender indexOfSelectedItem]];
}

- (IBAction) selectionTextFieldAction:(id)sender
{
    [self setSelectionValue:[sender floatValue]];
}


- (void) installSelectionArray:(NSArray*)anArray
{
    [self setSelectionArray:anArray];
    NSEnumerator* e = [selectionArray objectEnumerator];
    ORHWWizSelection* selection;
    [objPopUpButton removeAllItems];
    int i=0;
    while(selection = [e nextObject]){
        [objPopUpButton insertItemWithTitle:[selection name] atIndex:i];
        [[objPopUpButton itemAtIndex:i] setTag:i];
        ++i;
    }
}

#pragma mark ***Archival

static NSString* ORSelectionControllerLogicalTag = @"ORSelectionControllerLogicalTag";
static NSString* ORSelectionControllerObjTag = @"ORSelectionControllerObjTag";
static NSString* ORSelectionControllerSelectionTag = @"ORSelectionControllerSelectionTag";
static NSString* ORSelectionControllerSelectionValue = @"ORSelectionControllerSelectionValue";

- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super init];
	[[self undoManager] disableUndoRegistration];
	[self setLogicalTag:[decoder decodeIntForKey:ORSelectionControllerLogicalTag]];
	[self setObjTag:[decoder decodeIntForKey:ORSelectionControllerObjTag]];
	[self setSelectionTag:[decoder decodeIntForKey:ORSelectionControllerSelectionTag]];
	[self setSelectionValue:[decoder decodeIntForKey:ORSelectionControllerSelectionValue]];
	[self registerNotificationObservers];
	[[self undoManager] enableUndoRegistration];
	return self;
}
- (void) encodeWithCoder:(NSCoder*)encoder
{
	[encoder encodeInteger:logicalTag forKey:ORSelectionControllerLogicalTag];
	[encoder encodeInteger:objTag forKey:ORSelectionControllerObjTag];
	[encoder encodeInteger:selectionTag forKey:ORSelectionControllerSelectionTag];
	[encoder encodeInteger:selectionValue forKey:ORSelectionControllerSelectionValue];
}
@end
