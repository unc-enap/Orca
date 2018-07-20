//
//  OrcaObjectController.m
//  Orca
//
//  Created by Mark Howe on Sun Dec 08 2002.
//  Copyright © 2002 CENPA, Univsersity of Washington. All rights reserved.
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
#import "ORTimedTextField.h"

NSString* ORModelChangedNotification = @"ORModelChangedNotification";

@implementation OrcaObjectController

#pragma mark ¥¥¥Initialization
- (id) initWithWindowNibName:(NSString*)aNibName
{
    if(self = [super initWithWindowNibName:aNibName]){
		[self setShouldCloseDocument:NO];
        [self setWindowFrameAutosaveName:aNibName];
    }
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [model release];
    model = nil;
	[[self window] close]; //don't know why this line had been commented out.....
    [super dealloc];
}

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void) close
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self setModel:nil];
	[[self window] close];
}

#pragma mark ¥¥¥Undo Management
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow*)window
{
    return [model undoManager];
}

#pragma mark ¥¥¥Accessors
- (id)model
{
	return model;
}

- (void) setModel:(id)aModel
{
    if(aModel != model){
		
		NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
		[nc removeObserver:self];
		[aModel retain];
        [model release];
        model =  aModel;
		
		if(model){
			[self registerNotificationObservers];
			[self updateWindow];
		}
		[nc postNotificationName:ORModelChangedNotification
						  object: self 
						userInfo: nil];
    }
}

#pragma mark ¥¥¥Notifications
- (void) documentClosing:(NSNotification*)aNotification
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];	
	[[self window] close];
}

#pragma mark ¥¥¥Messages From Delegate
- (BOOL)windowShouldClose:(id)sender
{
    return YES;
}

#pragma mark ¥¥¥Interface Management

- (void) isNowKeyWindow:(NSNotification*)aNotification
{
	//do nothing... subclassed can override
}

- (void) endAllEditing:(NSNotification*)aNotification
{
	[self endEditing];
}

- (void) endEditing
{
	//commit all text editing... subclasses should call before doing their work.
	if(![[self window] endEditing]){
		[[self window] forceEndEditing];		
	}
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
	[notifyCenter removeObserver:self];
	
    //-------------------------------------------------------
    //temp for testing... looking for non-thread gui updates.
//    [notifyCenter addObserverForName: nil
//                                object: nil
//                                 queue: nil
//                            usingBlock: ^(NSNotification *notification) {
//                                if(![NSThread isMainThread]){
//                                    if([notification.name rangeOfString:@"WillExit"].location!=NSNotFound)return;
//                                    if([notification.name rangeOfString:@"DidStart"].location!=NSNotFound)return;
//                                    if([notification.name rangeOfString:@"BSNewMetadataAdded"].location!=NSNotFound)return;
//                                    
//                                    if([notification.name rangeOfString:@"WindowTransformAnimation"].location!=NSNotFound)return;
//                                    if([notification.name rangeOfString:@"Extend Time to stop run"].location!=NSNotFound)return;
//                                    
//                                    if([notification.name rangeOfString:@"NSConnectionDidInitializeNotification"].location!=NSNotFound)return;
//                                    if([notification.name rangeOfString:@"NSPortDidBecomeInvalidNotification"].location!=NSNotFound)return;
//                                    if([notification.name rangeOfString:@"NSCalendarDayChangedNotification"].location!=NSNotFound)return;
//                                    
//                                    if(notification.userInfo)NSLog (@"NOTIFICATION %@ -> %@\n",
//                                          notification.name, notification.userInfo);
//                                    else NSLog (@"NOTIFICATION %@\n",
//                                                notification.name);
//                                }
//                            }];
    //-------------------------------------------------------
    
    [notifyCenter addObserver : self
                     selector : @selector(securityStateChanged:)
                         name : ORGlobalSecurityStateChanged
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(documentClosing:)
                         name : ORDocumentClosedNotification
                       object : nil];
	
 //   [notifyCenter addObserver : self
 //                    selector : @selector(endAllEditing:)
 //                        name : NSWindowDidResignKeyNotification
 //                      object : [self window]];
	
    [notifyCenter addObserver : self
                     selector : @selector(isNowKeyWindow:)
                         name : NSWindowDidBecomeKeyNotification
                       object : [self window]];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(uniqueIDChanged:)
                         name : ORIDChangedNotification
                       object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(warningPosted:)
						 name : ORWarningPosted
					   object : model];
}

- (void)flagsChanged:(NSEvent*)inEvent
{
	[[self window] resetCursorRects];
}

- (void) warningPosted:(NSNotification*)aNotification
{
	[warningField setStringValue:[[aNotification userInfo] objectForKey:@"WarningMessage"]];
}

- (void) uniqueIDChanged:(NSNotification*)aNotification
{
    //subclasses should override as needed.
}
- (void) securityStateChanged:(NSNotification*)aNotification
{
    [self checkGlobalSecurity];
}

- (void) checkGlobalSecurity
{
    //subclasses should override as needed.
}

- (void) updateWindow
{
    [self securityStateChanged:nil];
}

- (NSUndoManager*) undoManager
{
	return [model undoManager];
}

- (NSArray*) collectObjectsOfClass:(Class)aClass
{
	return [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:aClass];
}

- (NSArray*) collectObjectsConformingTo:(Protocol*)aProtocol
{
	return [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsConformingTo:aProtocol];
}

- (IBAction) printDocument:(id)sender
{
    NSRect cRect = [[self window] contentRectForFrameRect: [[self window] frame]];
    cRect.origin = NSZeroPoint;
    NSView*     borderView   = [[[self window] contentView] superview];
    NSData*     pdfData		 = [borderView dataWithPDFInsideRect: cRect];
    NSImage*    tempImage = [[NSImage alloc] initWithData: pdfData];
	
	NSPrintInfo* printInfo = [NSPrintInfo sharedPrintInfo];
	NSSize imageSize = [tempImage size];
	if(imageSize.width>imageSize.height){
		[printInfo setOrientation:NSPaperOrientationLandscape];
		[printInfo setHorizontalPagination: NSFitPagination];
	}
	else {
		[printInfo setOrientation:NSPaperOrientationPortrait];
		[printInfo setVerticalPagination: NSFitPagination];
	}

	[printInfo setHorizontallyCentered:NO];
	[printInfo setVerticallyCentered:NO];
	[printInfo setLeftMargin:72.0];
	[printInfo setRightMargin:72.0];
	[printInfo setTopMargin:72.0];
	[printInfo setBottomMargin:90.0];
	
	NSImageView* tempView = [[[NSImageView alloc] initWithFrame: NSMakeRect(0.0, 0.0, 8.5 * 72, 11.0 * 72)] autorelease];
	[tempView setImageAlignment:NSImageAlignTopLeft];
	[tempView setImage: tempImage];
	[tempImage release];

	NSPrintOperation* printOp = [NSPrintOperation printOperationWithView:tempView printInfo:printInfo];
#if MAC_OS_X_VERSION_10_5 <= MAC_OS_X_VERSION_MIN_ALLOWED
    [printOp setShowPanels:YES];
#endif
	[printOp runOperation];
}

#pragma mark INTERFACE MANAGEMENT - Generic updaters

- (void) incModelSortedBy:(SEL)aSelector
{
	[self endEditing];
	NSMutableArray* allModels = [[[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:[model class]] mutableCopy];
	[allModels sortUsingSelector:aSelector];
	uint32_t index = (uint32_t)[allModels indexOfObject:model] + 1;
	if(index>[allModels count]-1) index = 0;
	[self setModel:[allModels objectAtIndex:index]];
 	[allModels release];
}

- (void) decModelSortedBy:(SEL)aSelector
{
	[self endEditing];
	NSMutableArray* allModels = [[[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:[model class]] mutableCopy];
	[allModels sortUsingSelector:aSelector];
	uint32_t index = (uint32_t)[allModels indexOfObject:model] - 1;
	//if(index<0) index = [allModels count]-1;
	[self setModel:[allModels objectAtIndex:index]];
 	[allModels release];
}

- (void)updateTwoStateCheckbox:(NSButton *)control setting:(BOOL)value
{ 
    if (value != [control state]) {
        [control setState:(value ? NSOnState : NSOffState)];
    }
}

- (void)updateMixedStateCheckbox:(NSButton *)control setting:(int)inValue
{ 
	// The inValue parameter must be one of NSOnState, NSOffState, or NSMixedState.
    if (inValue != [control state]) {
        [control setState:inValue];
    }
}

- (void)updateRadioCluster:(NSMatrix *)control setting:(int)inValue
{ 
	// The inValue parameter must be an integer.
    if (inValue != [control selectedTag]) {
        [control selectCellWithTag:inValue];
    }
}

- (void)updatePopUpButton:(NSPopUpButton *)control setting:(int)inValue
{
	// Updates a pop-up button. The inValue parameter must be an integer.
    if (inValue != [control indexOfSelectedItem]) {
        [control selectItemAtIndex:inValue];
    }
}

- (void)updateSlider:(NSSlider *)control setting:(NSInteger)inValue
{ 
	// Updates a slider. The inValue parameter must be a int.
    if (inValue != [control intValue]) {
        [control setIntegerValue:inValue];
    }
}

- (void)updateStepper:(NSStepper *)control setting:(NSInteger)inValue
{
	// Updates a slider. The inValue parameter must be a int.
    if (inValue != [control intValue]) {
        [control setIntegerValue:inValue];
    }
}
- (void)updateIntText:(NSTextField *)control setting:(NSInteger)inValue
{
	// Updates a slider. The inValue parameter must be a int.
    if (inValue != [control intValue]) {
        [control setIntegerValue:inValue];
    }
}

- (void)resizeWindowToSize:(NSSize)newSize
{
    NSRect aFrame;
    
    float newHeight = newSize.height;
    float newWidth = newSize.width;
    
    aFrame = [NSWindow contentRectForFrameRect:[[self window] frame] 
                                     styleMask:[[self window] styleMask]];
    
    aFrame.origin.y += aFrame.size.height;
    aFrame.origin.y -= newHeight;
    aFrame.size.height = newHeight;
    aFrame.size.width = newWidth;
    
    aFrame = [NSWindow frameRectForContentRect:aFrame 
                                     styleMask:[[self window] styleMask]];
    
    [[self window] setFrame:aFrame display:YES animate:YES];
}

- (NSMutableDictionary*) miscAttributesForKey:(NSString*)aKey
{
	return [model miscAttributesForKey:aKey];
}

- (void) setMiscAttributes:(NSMutableDictionary*)someAttributes forKey:(NSString*)aKey
{
	[model setMiscAttributes:someAttributes forKey:aKey];
}


#pragma mark ¥¥¥Archival

static NSString *OROrcaObjectControllerFrame 	= @"OROrcaObjectControllerFrame";
static NSString *OROrcaObjectControllerModel	= @"OROrcaObjectControllerModel";
static NSString *OROrcaObjectControllerNibName	= @"OROrcaObjectControllerNibName";

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"

- (id)initWithCoder:(NSCoder*)decoder
{
    NSString* nibName = @"??";
    @try {
        nibName = [decoder decodeObjectForKey:OROrcaObjectControllerNibName];
        self = [super initWithWindowNibName:nibName];
        [self setModel:[decoder decodeObjectForKey:OROrcaObjectControllerModel]];
		NSString* s = [decoder decodeObjectForKey:OROrcaObjectControllerFrame];
		[[self window] orderFront:self];
        [[self window] setFrameFromString:s];
	}
	@catch(NSException* localException) {
        NSLogColor([NSColor redColor], @"Failed loading: %@. Reason: %@\n", nibName, [localException reason]);
    }
    return self;
}
#pragma clang diagnostic pop

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:[self windowNibName] forKey:OROrcaObjectControllerNibName];
    [super encodeWithCoder:encoder];
    [encoder encodeObject:model forKey:OROrcaObjectControllerModel];
    [encoder encodeObject:[[self window] stringWithSavedFrame] forKey:OROrcaObjectControllerFrame];
}

#pragma mark ¥¥¥Actions
- (IBAction) copy:(id)sender
{
	[[(ORAppDelegate*)[NSApp delegate] document] duplicateDialog:self];
}


- (IBAction) incDialog:(id)sender
{
	NSArray* models = [[model guardian] collectObjectsOfClass:[model class]];
	if([models count]>1){
		NSEnumerator* e = [models objectEnumerator];
		id obj;
		while(obj = [e nextObject]){
			if(obj == model){
				obj = [e nextObject];
				if(obj)[self setModel:obj];
				else [self setModel:[models objectAtIndex:0]];
			}
		}
	}
}

- (IBAction) decDialog:(id)sender
{
	NSArray* models = [[model guardian] collectObjectsOfClass:[model class]];
	if([models count]>1){
		NSEnumerator* e = [models reverseObjectEnumerator];
		id obj;
		while(obj = [e nextObject]){
			if(obj == model){
				obj = [e nextObject];
				if(obj)[self setModel:obj];
				else [self setModel:[models lastObject]];
			}
		}
	}
}



- (IBAction) saveDocument:(id)sender
{
    [[model document] saveDocument:sender];
}

- (IBAction) saveDocumentAs:(id)sender
{
    [[model document] saveDocumentAs:sender];
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	NSArray* models = [self collectObjectsOfClass:[model class]];
    if ([menuItem action] == @selector(decDialog:)) {
		return [models count] > 1;
	}
    else if ([menuItem action] == @selector(incDialog:)) {
		return [models count] > 1;
    }
	else return YES;
}

- (void) setUpdatedOnce
{
    updatedOnce = YES;
}
- (void) resetUpdatedOnce
{
    updatedOnce = NO;
}

- (void) updateValueMatrix:(NSMatrix*)aMatrix getter:(SEL)aGetter
{
    NSInteger numItems = [aMatrix numberOfRows];
    NSInteger i;
    for(i=0;i<numItems;i++){
        
        NSMethodSignature* signature = [[model class] instanceMethodSignatureForSelector:aGetter];
        NSInvocation* invocation     = [NSInvocation invocationWithMethodSignature: signature];
        [invocation setTarget:   model];
        [invocation setSelector: aGetter];
        [invocation setArgument: &i atIndex: 2];
        [invocation invoke];
        NSCell* aCell   = [aMatrix cellWithTag:i];
        
        const char* returnType = [signature methodReturnType];
        switch(*returnType){
            case 'f':
            {
                float aValue;
                [invocation getReturnValue:&aValue];
                if(!updatedOnce || ([aCell floatValue] != aValue))[aCell setFloatValue:aValue];
            }
                break;
            case 's':
            {
                short aValue;
                [invocation getReturnValue:&aValue];
                if(!updatedOnce || ([aCell intValue] != aValue))[aCell setIntValue:aValue];
            }
                break;
            case 'S':
            {
                unsigned short aValue;
                [invocation getReturnValue:&aValue];
                if(!updatedOnce || ([aCell intValue] != aValue))[aCell setIntValue:aValue];
            }
                break;
           case 'l':
            {
                int32_t aValue;
                [invocation getReturnValue:&aValue];
                if(!updatedOnce || ([aCell intValue] != aValue))[aCell setIntegerValue:aValue];
            }
                break;
            case 'L':
            {
                uint32_t aValue;
                [invocation getReturnValue:&aValue];
                if(!updatedOnce || ([aCell intValue] != aValue))[aCell setIntegerValue:aValue];
            }
                break;
       }
        
    }
}

@end

