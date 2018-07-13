//
//  ORHWizActionController.m
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


#import "ORHWizActionController.h"
#import "ORHWWizParam.h"

#pragma mark ***External Strings
NSString* ORActionControllerActionChanged = @"ORActionControllerActionChanged";
NSString* ORActionControllerParameterValueChanged = @"ORActionControllerParameterValueChanged";


static NSString* valueChangeString[kNumActions] = {
    @"to:",
    @"by:",
    @"by:",
    @"by:",
    @"",
    @""
};

@implementation ORHWizActionController

+ (id) controller
{
    return [[[self alloc] init] autorelease];
}

- (id) init
{
    self = [super init];
#if !defined(MAC_OS_X_VERSION_10_9)
    [NSBundle loadNibNamed:@"ActionView" owner:self];
#else
    [[NSBundle mainBundle] loadNibNamed:@"ActionView" owner:self topLevelObjects:&topLevelObjects];
    [topLevelObjects retain];
#endif
    [self setParameterValue:[NSNumber numberWithInt:0]];
    
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [topLevelObjects release];
    [paramArray release];
    [parameterValue release];
    [super dealloc];
}

- (void) awakeFromNib
{
    [self registerNotificationObservers];
    //    [self installParamArray:a];
    [self updateWindow];
}


- (NSView*) view
{
    return subview;
}

- (int) actionTag
{
    return actionTag;
}
- (void) setActionTag:(int)aNewActionTag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setActionTag:actionTag];
    
    actionTag = aNewActionTag;
    
    [[NSNotificationCenter defaultCenter] 
		    postNotificationName:ORActionControllerActionChanged 
                          object: self];
}

- (int) parameterTag
{
	return parameterTag;
}
- (void) setParameterTag:(int)aNewParameterTag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setParameterTag:parameterTag];
    
    parameterTag = aNewParameterTag;
    
    [[NSNotificationCenter defaultCenter] 
		    postNotificationName:ORActionControllerActionChanged 
                          object: self];
}

- (NSNumber*) parameterValue
{
	return parameterValue;
}
- (void) setParameterValue:(NSNumber*)aNewParameterValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setParameterValue:parameterValue];
    
    [parameterValue autorelease];
    parameterValue = [aNewParameterValue copy];
    
    [[NSNotificationCenter defaultCenter] 
		    postNotificationName:ORActionControllerParameterValueChanged 
                          object: self];
}

- (NSArray*)paramArray
{
    return paramArray; 
}

- (void)setParamArray:(NSArray*)aParamArray
{
    [aParamArray retain];
    [paramArray release];
    paramArray = aParamArray;
}


#pragma mark ***Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                      selector: @selector(actionChanged:)
                          name: ORActionControllerActionChanged
                       object : self];
    
    [notifyCenter addObserver : self
                      selector: @selector(parameterValueChanged:)
                          name: ORActionControllerActionChanged
                       object : self];
    
    
    [notifyCenter addObserver : self
                      selector: @selector(parameterValueChanged:)
                          name: ORActionControllerParameterValueChanged
                       object : self];
    
}

- (BOOL)validateMenuItem:(NSMenuItem*)anItem 
{
    if([anItem action] == @selector(parameterPopupButtonAction:)){
        NSUInteger tag = [anItem tag];
        id param = [paramArray objectAtIndex:tag];
        if(![param enabledWhileRunning] && [gOrcaGlobals runInProgress])return NO;
    }
    else {
        if([anItem action] == @selector(actionPopupButtonAction:)){  
            id param = [paramArray objectAtIndex:[[parameterPopupButton selectedItem] tag]];
            NSUInteger tag = [actionPopupButton indexOfItem:anItem];
            if([param actionMask] == 0)return YES;
            else {
                if([param actionMask]&(1<<tag))return YES;
                else return NO;
            }
            
        }  
    }
    return YES;
}


- (void) updateWindow
{
    [self actionChanged:nil];
    [self parameterValueChanged:nil];
}


- (void) actionChanged:(NSNotification*)aNote
{
    if((aNote == nil || [aNote object] == self )){
        
        [parameterPopupButton selectItemAtIndex:parameterTag];
        [actionPopupButton selectItemAtIndex:actionTag];
        
        id param = [paramArray objectAtIndex:parameterTag];
        
        //set the units string
        if(actionTag == kAction_Scale){
            [unitsField setStringValue:@"%"];
            //set the limits and step sizes
            [parameterValueStepper setMaxValue:500];
            [parameterValueStepper setMinValue:-500];
            [parameterValueStepper setIncrement:1];
            NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
            [numberFormatter setFormat:@"#0"];
            [parameterValueTextField setFormatter:numberFormatter];
        }
        else {
            if(parameterTag < [paramArray count]){
                NSString* units = [param units];
                if(units) [unitsField setStringValue:units];
                else      [unitsField setStringValue:@""];
            }
            else [unitsField setStringValue:@""];
            //set the limits and step sizes
            [parameterValueStepper setMaxValue:[param upperLimit]];
            [parameterValueStepper setMinValue:[param lowerLimit]];
            [parameterValueStepper setIncrement:[param stepSize]];
            //set the textfield format
            if([param formatter]){
                [parameterValueTextField setFormatter:[param formatter]];
            }
            else if([param format]){
                NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
                [numberFormatter setFormat:[param format]];
                [parameterValueTextField setFormatter:numberFormatter];
            }
        }
        
        
        
        //set the changeString 'by', 'to' ,etc...
        if(actionTag < kNumActions){
            id param = [paramArray objectAtIndex:parameterTag];
			int numberOfSettableArguments = 0;
			SEL paramMethodSelector = [param setMethodSelector];
            if(paramMethodSelector) numberOfSettableArguments = (int)[[param methodSignatureForSelector:paramMethodSelector] numberOfArguments]-2;
            if(numberOfSettableArguments == 0){
                [valueChangeField setStringValue:@""];
            }
            else {
                [valueChangeField setStringValue:valueChangeString[actionTag]];
            }
        }
        else {
            [valueChangeField setStringValue:@""];
        }
        
        if(actionTag==kAction_Restore || actionTag==kAction_Restore_All){
            [unitsField setStringValue:@""];
        }

			          
        //enable/disable things
        BOOL useValue = [param useValue] && (actionTag!=kAction_Restore) && (actionTag!=kAction_Restore_All);
		[actionPopupButton setHidden:![param useValue]];
        [parameterValueStepper setHidden:!useValue];
        [parameterValueTextField setHidden:!useValue];
        [valueChangeField setHidden:!useValue];
        [unitsField setHidden:!useValue];

        BOOL useParameter = (actionTag!=kAction_Restore_All);
		[parameterPopupButton setHidden:!useParameter];

        
        //refresh
        [unitsField setNeedsDisplay:YES];
        [valueChangeField setNeedsDisplay:YES];
        [parameterValueTextField setNeedsDisplay:YES];
    }
}

- (void) parameterValueChanged:(NSNotification*)aNote
{
    if((aNote == nil || [aNote object] == self )){
        [parameterValueTextField setObjectValue:[self parameterValue]];
        [parameterValueStepper setObjectValue:[self parameterValue]];
    }
}

#pragma mark ***Actions

- (IBAction) actionPopupButtonAction:(id)sender
{
    [self setActionTag:(int)[sender indexOfSelectedItem]];
    
}

- (IBAction) parameterPopupButtonAction:(id)sender
{
    [self setParameterTag:(int)[sender indexOfSelectedItem]];
}

- (IBAction) parameterValueTextFieldAction:(id)sender
{
    [self setParameterValue:[sender objectValue]];
}


- (NSUndoManager*) undoManager
{
    return [[(ORAppDelegate*)[NSApp delegate]document]  undoManager];
}

- (void) installParamArray:(NSArray*)anArray
{
    [self setActionTag:0];
    [self setParameterTag:0];
    [self setParamArray:anArray];
    
    NSEnumerator* e = [paramArray objectEnumerator];
    ORHWWizParam* param;
    [parameterPopupButton removeAllItems];
    int i=0;
    while(param = [e nextObject]){
        [parameterPopupButton insertItemWithTitle:[param name] atIndex:i];
        [[parameterPopupButton itemAtIndex:i] setTag:i];
        ++i;
        
    }
    [self actionChanged:nil];
}




#pragma mark ***Archival

static NSString* ORActionControllerActionTag        = @"ORActionControllerActionTag";
static NSString* ORActionControllerParameterTag     = @"ORActionControllerParameterTag";
static NSString* ORActionControllerParameter	    = @"ORActionControllerParameter";

- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super init];
	[[self undoManager] disableUndoRegistration];
	[self setActionTag:[decoder decodeIntForKey:ORActionControllerActionTag]];
	[self setParameterTag:[decoder decodeIntForKey:ORActionControllerParameterTag]];
	[self setParameterValue:[decoder decodeObjectForKey:ORActionControllerParameter]];
	[[self undoManager] enableUndoRegistration];
	[self registerNotificationObservers];
	[self updateWindow];
	return self;
}
- (void) encodeWithCoder:(NSCoder*)encoder
{
	[encoder encodeInteger:actionTag forKey:ORActionControllerActionTag];
	[encoder encodeInteger:parameterTag forKey:ORActionControllerParameterTag];
	[encoder encodeObject:parameterValue forKey:ORActionControllerParameter];
}



@end
