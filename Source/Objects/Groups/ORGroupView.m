//
//  ORGroupView.m
//  Orca
//
//  Created by Mark Howe on Wed Nov 27, 2002.
//  Copyright  © 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORSelectionTask.h"
#import "ORConnectionTask.h"
#import "ORScaleTask.h"
#import "ORReadOutList.h"
#import "ORDataTaker.h"
#import "ORHWWizard.h"



@interface ORGroupView (ExperimentViewPrivateMethods)
- (void)_openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (BOOL) _canTakeValueFromPasteboard:(NSPasteboard *)pb;
- (void) _startDrag:(NSEvent*)event;
- (BOOL) _doDragOp:(NSString *)op atPoint:(NSPoint)aPoint;
@end


@implementation ORGroupView

#pragma mark ¥¥¥Initialization
- (id)initWithFrame:(NSRect)frame {
    NSArray *typeArray;
    self = [super initWithFrame:frame];
    if (self) {       
        typeArray = [NSArray arrayWithObject:ORObjArrayPtrPBType];
        [self registerForDraggedTypes:typeArray];
        dragSessionInProgress = NO;
        goodObjectsInDrag = NO;
    }
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter  defaultCenter] removeObserver:self];
    [self setBackgroundColor:nil];
    [mouseTask release];
    [super dealloc];
}

- (void) awakeFromNib
{
    NSColor* color = colorForData([[NSUserDefaults standardUserDefaults] objectForKey: ORBackgroundColor]);
    [self setBackgroundColor:(color!=nil?color:[NSColor whiteColor])];
    
    NSNotificationCenter* defaultCenter = [NSNotificationCenter  defaultCenter];
    [defaultCenter addObserver:self
                      selector:@selector(backgroundColorChanged:)
                          name:ORBackgroundColorChangedNotification
                        object:nil];
    
    [defaultCenter addObserver:self
                      selector:@selector(lineColorChanged:)
                          name:ORLineColorChangedNotification
                        object:nil];
    
    [defaultCenter addObserver:self
                      selector:@selector(lineTypeChanged:)
                          name:ORLineTypeChangedNotification
                        object:nil];
    
    [defaultCenter addObserver:self
                      selector:@selector(contentSizeChanged:)
                          name:ORGroupObjectsAdded
                        object:group];
    
    [defaultCenter addObserver:self
                      selector:@selector(contentSizeChanged:)
                          name:ORGroupObjectsRemoved
                        object:group];
    
    [defaultCenter addObserver:self
                      selector:@selector(contentSizeChanged:)
                          name:OROrcaObjectMoved
                        object:nil];
    
    [defaultCenter addObserver:self
                      selector:@selector(imageChanged:)
                          name:OROrcaObjectImageChanged
                        object:nil];
  

    
    [self backgroundColorChanged:nil];
    [self setNeedsDisplay:YES];
}

#pragma mark ¥¥¥Accessors
- (void) setDragLocked:(BOOL)aState
{
    dragLocked = aState;
}

- (void) setGroup:(ORGroup*)aModel
{	
    group = aModel;
}

- (ORGroup*) group
{
    return group;
}

- (NSColor*) backgroundColor
{
    return backgroundColor;
}

- (void) setBackgroundColor:(NSColor*)aColor
{
    [aColor retain];
    [backgroundColor release];
    backgroundColor = aColor;
    [self setNeedsDisplay:YES];
}

- (NSEnumerator*) objectEnumerator
{
    return [group objectEnumerator];
}

#pragma mark ¥¥¥Graphics

- (void)drawRect:(NSRect)rect
{
    [self drawBackground:rect];
	[self drawContents:rect];
    [mouseTask drawRect:rect];
}

- (void) drawBackground:(NSRect)aRect
{
	[backgroundImage drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
    
}

- (void) drawContents:(NSRect)aRect
{
    [group drawContents:aRect];	
}


//-------------------------------------------------------------------------------
// backgroundColorChanged
// invoded when the preference panel announces a background color change.
//-------------------------------------------------------------------------------
-(void)backgroundColorChanged:(NSNotification*)note
{
    NSUserDefaults* 	defaults;
    NSData*		colorAsData;
    defaults 	= [NSUserDefaults standardUserDefaults];
    colorAsData = [defaults objectForKey: ORBackgroundColor];
    [self setBackgroundColor:colorForData(colorAsData)];
    NSScrollView*   sv = [self enclosingScrollView];
    [sv setDrawsBackground:NO];
	[sv setBackgroundColor:[self backgroundColor]];
}

- (void)lineColorChanged:(NSNotification*)note
{
    [self setNeedsDisplay:YES];
}

- (void) imageChanged:(NSNotification*)note
{
    if(note == nil || (ORGroup*)[[note object] guardian] == group){
        [self setNeedsDisplay:YES];
    }
}

- (void)lineTypeChanged:(NSNotification*)note
{
    [self setNeedsDisplay:YES];
}

- (void) contentSizeChanged:(NSNotification*)note
{
    if(note == nil || (ORGroup*)[note object] == group || (ORGroup*)[[note object] guardian] == group){
        float scaleFactor = [self scalePercent]/100.;
        NSRect  box = [group rectEnclosingObjects:[group orcaObjects]];
        box.size.width *= scaleFactor;
        box.size.height *= scaleFactor;
        
        NSScrollView*   sv = [self enclosingScrollView];
        NSRect          svRect = [[sv contentView]frame];
        
        int x = box.origin.x;//*scaleFactor;
		int y = box.origin.y;//*scaleFactor;
		
		if(x<0 || y<0){
			//origins must be 0,0 so we have to do a bit of adjustment here
			if(x<0){
				box.origin.x = 0;
				box.size.width += abs(x) * scaleFactor;
			}
			if(y<0){
				box.origin.y = 0;
				box.size.height += abs(y) * scaleFactor;
			}
			NSEnumerator* e = [[group orcaObjects] objectEnumerator];
			OrcaObject* obj;
			while(obj = [e nextObject]){
				NSRect aFrame = [obj frame];
				if(x<0)aFrame.origin.x += abs(x);
				if(y<0)aFrame.origin.y += abs(y);
				[obj setFrame:aFrame];
			}
			
			svRect = [[sv contentView]frame];
			svRect.size.width *= scaleFactor;
			svRect.size.height *= scaleFactor;
			
			box = [group rectEnclosingObjects:[group orcaObjects]];
			box.size.width *= scaleFactor;
			box.size.height *= scaleFactor;
		}
		
		box = NSUnionRect(box,svRect);
		[self setFrame:box];
		
    }
}


- (void)resizeWithOldSuperviewSize:(NSSize)oldSize
{
    [super resizeWithOldSuperviewSize:oldSize];
    [self contentSizeChanged:nil];
}

- (NSRect) resizeView:(NSRect)aNewRect
{
    float dx = aNewRect.origin.x;
    float dy = aNewRect.origin.y;
    NSRect newRect = aNewRect;
    newRect.origin.x = 0;
    newRect.origin.y = 0;
    newRect.size.width += dx;
    newRect.size.height += dy;
    
    return newRect;
}

- (NSRect) normalized
{
    float scaleFactor = [self scalePercent]/100.;
    NSRect  box = [group rectEnclosingObjects:[group orcaObjects]];
	
	NSRect windowFrame = [[self window] frame];
    NSScrollView*   sv = [self enclosingScrollView];
	NSRect viewFrame   = [[sv contentView]  frame];
    
	float verticalSpace   = windowFrame.size.height - viewFrame.size.height;
	float horizontalSpace = windowFrame.size.width - viewFrame.size.width;
	
    int x = box.origin.x - 20;
    int y = box.origin.y - 20;
	
    NSEnumerator* e = [[group orcaObjects] objectEnumerator];
    OrcaObject* obj;
    while(obj = [e nextObject]){
        NSRect aFrame = [obj frame];
        aFrame.origin.x -= abs(x);
        aFrame.origin.y -= abs(y);
        [obj setFrame:aFrame];
    }
    
    box = [group rectEnclosingObjects:[group orcaObjects]];
    box.origin.x = 0;
    box.origin.y = 0;
    box.size.width += 40;
    box.size.height += 40;
    box.size.width *= scaleFactor;
    box.size.height *= scaleFactor;
    
    [self setFrame:box];
    
	NSSize minSize = [[self window] minSize];
	windowFrame.size.width  = MAX(box.size.width+horizontalSpace,minSize.width);
	windowFrame.size.height = MAX(box.size.height+verticalSpace,minSize.height);
	
	[self setNeedsDisplay:YES];
	
	return windowFrame;
}

#pragma mark ¥¥¥Mouse Events
- (void)mouseDown:(NSEvent*)event
{
    [[self window] makeFirstResponder:self];
    
    BOOL shiftKeyDown = ([event modifierFlags] & NSEventModifierFlagShift)!=0;
    BOOL cmdKeyDown   = ([event modifierFlags] & NSEventModifierFlagCommand)!=0;
    BOOL cntrlKeyDown = ([event modifierFlags] & NSEventModifierFlagControl)!=0;
    BOOL optionKeyDown = ([event modifierFlags] & NSEventModifierFlagOption)!=0;
    BOOL shiftCmdKeyDown = cmdKeyDown & shiftKeyDown;
	
    NSPoint localPoint = [self convertPoint:[event locationInWindow] fromView:nil];
    
    NSEnumerator* e  = [[group orcaObjects] reverseObjectEnumerator];
    OrcaObject* obj1;
    OrcaObject* obj2;
    BOOL somethingHit 			= NO;
    ORConnector* connectorRequestingConnection = nil;
    BOOL hitObjectHighlighted;
	while (obj1 = [e nextObject]) {                     //loop thru all icons
		if(![obj1 selectionAllowed]){
			if([event clickCount]>=2){
				[obj1 doDoubleClick:obj1];
			}                
			continue;
		}
		if( [obj1 acceptsClickAtPoint:localPoint]){
            if(cntrlKeyDown){
                [obj1 doCntrlClick:[[self window]contentView]];
                somethingHit = YES;
                break;
            }
            else if(shiftCmdKeyDown){
                [obj1 doShiftCmdClick:obj1 atPoint:localPoint];
                somethingHit = YES;
                break;
            }
            else {
                somethingHit = YES;
                connectorRequestingConnection = [obj1 requestsConnection:localPoint];
                if(connectorRequestingConnection == nil){
                    //obj1 has been clicked on
                    hitObjectHighlighted = [obj1 highlighted];
                    if(shiftKeyDown){ 					//shift key down so..
                        [obj1 setHighlighted:![obj1 highlighted]];		//flip the highlight state
                    }
                    else [obj1 setHighlighted:YES];                         //shift key NOT down so highligth
                    //[self setNeedsDisplayInRect:[obj1 frame]];
                    [self setNeedsDisplay:YES];
                    
                    //next handle the response of the other objects
                    if(!shiftKeyDown){                                      //shift key NOT down
                        e  = [[group orcaObjects] objectEnumerator];
                        while (obj2 = [e nextObject]){			//loop thru all icons
                            if(obj2 != obj1 && !hitObjectHighlighted){	//skip the obj1 and if obj1 was NOT highlighted...
                                [obj2 setHighlighted:NO];			//unhighlight obj2
                            }
                        }
                    }
                    
                    if([event clickCount]>=2){
                        if(cmdKeyDown){
                            [obj1 setHighlighted:NO];
                            [obj1 doCmdDoubleClick:obj1 atPoint:localPoint];
                            somethingHit = YES;
                            break;
                        }
                        else [[group allSelectedObjects] makeObjectsPerformSelector:@selector(doDoubleClick:) withObject:self];
                    }
                    else {
                        if(cmdKeyDown){
                            [obj1 setHighlighted:NO];
                            [obj1 doCmdClick:obj1 atPoint:(NSPoint)localPoint];
                            somethingHit = YES;
                            break;
                        }
                     }

                 }
            }
            break;
        }
	}
	
    //something else must be done..
    if(!somethingHit){
		id theMouseTask=nil;
		if(optionKeyDown ){
			theMouseTask = [ORScaleTask getTaskForEvent:event inView:self];
		}
		else  if(cntrlKeyDown){
			[self doControlClick:self];
			
		}
		else {
			[self clearSelections:shiftKeyDown];
			theMouseTask = [ORSelectionTask getTaskForEvent:event inView:self];
		}
		[self setMouseTask:theMouseTask];
        [[self mouseTask] mouseDown:event];
        
    }
    else if(connectorRequestingConnection != nil && [group changesAllowed]){
        id theTask = [ORConnectionTask getTaskForEvent:event inView:self];
        [self setMouseTask:theTask];
        [[self mouseTask] mouseDown:event];
        if([connectorRequestingConnection connector] != nil) {
            [[self mouseTask] setStartLoc: [[connectorRequestingConnection connector]centerPoint]];
            [[self mouseTask] setCurrentLoc:[self convertPoint:[event locationInWindow] fromView:nil]];
            [connectorRequestingConnection disconnect];
        }
    }
    //[self setNeedsDisplay:YES];
}
- (void) doControlClick:(NSView*)aView
{
	if([group isKindOfClass:NSClassFromString(@"ORContainerModel")]){
		
		NSEvent* theCurrentEvent = [NSApp currentEvent];
		NSEvent *event =  [NSEvent mouseEventWithType:NSEventTypeLeftMouseDown
											 location:[theCurrentEvent locationInWindow]
										modifierFlags:NSEventModifierFlagControl // 0x100
											timestamp:(NSTimeInterval)0
										 windowNumber:[theCurrentEvent windowNumber]
											  context:nil
										  eventNumber:0
										   clickCount:1
											 pressure:1];
		
		NSMenu *menu = [[[NSMenu alloc] init] autorelease];
		[[menu insertItemWithTitle:@"Set Background Image"
							action:@selector(selectBackgroundImage:)
					 keyEquivalent:@""
						   atIndex:0] setTarget:self];
		[[menu insertItemWithTitle:@"Clear Background Image"
							action:@selector(clearBackgroundImage:)
					 keyEquivalent:@""
						   atIndex:0] setTarget:self];
		[menu setDelegate:self];
		[NSMenu popUpContextMenu:menu withEvent:event forView:aView];
	}
}

- (IBAction) clearBackgroundImage:(id)sender
{
	if([group isKindOfClass:NSClassFromString(@"ORContainerModel")]){
		[group setBackgroundImagePath:nil];
	}
}

- (IBAction) selectBackgroundImage:(id)sender
{
    NSString* startDir = NSHomeDirectory(); //default to home
	if([group isKindOfClass:NSClassFromString(@"ORContainerModel")]){
		if([group backgroundImagePath]){
			startDir = [[group backgroundImagePath]stringByDeletingLastPathComponent];
			if([startDir length] == 0){
				startDir = NSHomeDirectory();
			}
		}
	}
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setCanChooseFiles:YES];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanCreateDirectories:NO];
	[openPanel setPrompt:@"Choose Image"];
    
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            NSString* path = [[[openPanel URL]path]stringByAbbreviatingWithTildeInPath];
            if([group isKindOfClass:NSClassFromString(@"ORContainerModel")]){
                [group setBackgroundImagePath:path];
            }
        }
    }];
}

//-------------------------------------------------------------------------------
// mouseDragged
// Handle a mouse dragged event. If a selection drag is in progress, handle the
// selection/deselection of icons as they enter/leave the selection rect. Otherwise
// start a drag of any selected objects.
//-------------------------------------------------------------------------------
- (void)mouseDragged:(NSEvent *)event
{
    if(mouseTask){
        [mouseTask mouseDragged:event];       
    }
    else if([group changesAllowed]){
        [self _startDrag:event];
    }
}

//-------------------------------------------------------------------------------
// mouseUp
// Handle a mouse up event. Just terminate any selection drag in progress and mark
// the display for update.
//-------------------------------------------------------------------------------
- (void)mouseUp:(NSEvent *)event
{
    [mouseTask mouseUp:event];
    [self setMouseTask:nil];        
    //[self setNeedsDisplay:YES];
}


//-------------------------------------------------------------------------------
// setMouseTask
// assign a mouse task. mouse tasks may reassign the task based on what's going on.
//-------------------------------------------------------------------------------
- (void)setMouseTask:(id)aTask
{
    if(![group changesAllowed]){
        [mouseTask release];
        mouseTask = nil;
    }
    else {
        [aTask retain];
        [mouseTask release];
        mouseTask = aTask;		
    }
}

- (id)mouseTask
{
    return mouseTask;
}

-(BOOL) acceptsFirstMouse:(NSEvent*)event
{
    return YES;
}

- (BOOL) shouldDelayWindowOrderingforEvent:(NSEvent*)theEvent
{
    return YES;
}

- (BOOL) validateMenuItem:(NSMenuItem*)menuItem
{
    NSUInteger selectedCount = [[group selectedObjects]count];
    BOOL changesAllowed = [group changesAllowed];
    if ([menuItem action] == @selector(paste:)) {
        NSPasteboard *pb = [NSPasteboard pasteboardWithName:NSGeneralPboard];
        if(!changesAllowed)return NO;
        else return [self _canTakeValueFromPasteboard:pb];
    }
    else if ([menuItem action] == @selector(copy:)) {
        if(!changesAllowed)return NO;
        else return selectedCount>0;
    }
    else if ([menuItem action] == @selector(cut:)) {
        if(!changesAllowed)return NO;
        else return selectedCount>0;
    }
    else if ([menuItem action] == @selector(delete:)) {
        if(!changesAllowed)return NO;
        else return selectedCount>0;
    }
	else if ([menuItem action] == @selector(selectAll:)){
		return changesAllowed;
	}
	
    else if ([menuItem action] == @selector(getInfo:))			return (selectedCount>0);
    else if ([menuItem action] == @selector(arrangeInCircle:))	return changesAllowed & (selectedCount>0);
    else if ([menuItem action] == @selector(alignLeft:))		return changesAllowed & (selectedCount>0);
    else if ([menuItem action] == @selector(alignRight:))		return changesAllowed & (selectedCount>0);
    else if ([menuItem action] == @selector(alignVerticalCenters:))		return changesAllowed & (selectedCount>0);
    else if ([menuItem action] == @selector(alignHorizontalCenters:))	return changesAllowed & (selectedCount>0);
    else if ([menuItem action] == @selector(alignTop:))			return changesAllowed & (selectedCount>0);
    else if ([menuItem action] == @selector(bringToFront:))		return changesAllowed & (selectedCount>0);
    else if ([menuItem action] == @selector(sendToBack:))		return changesAllowed & (selectedCount>0);
    else if ([menuItem action] == @selector(alignBottom:))		return changesAllowed & (selectedCount>0);
	else return  [(ORAppDelegate*)[NSApp delegate] validateMenuItem:menuItem];
}

- (void) clearSelections:(BOOL)shiftKeyDown
{
    [group clearSelections:shiftKeyDown];
    [self setNeedsDisplay:YES];
}

- (void) checkSelectionRect:(NSRect)aRect inView:(NSView*)aView
{
    [group checkSelectionRect:aRect inView:aView];
}

- (void) checkRedrawRect:(NSRect)aRect inView:(NSView*)aView
{
    [group checkRedrawRect:aRect inView:aView];
}


#pragma mark ¥¥¥Actions
- (IBAction) getInfo:(id)sender
{
	NSArray* objects = [group selectedObjects];
	id obj;
	NSEnumerator* e = [objects objectEnumerator];
	while(obj = [e nextObject]){
		NSLog(@"%@\n",obj);
	}
}
- (IBAction) alignBottom:(id)sender
{
	NSArray* items = [group selectedObjects];
	NSEnumerator* e = [items objectEnumerator];
	id obj = [e nextObject];
	float y = [(OrcaObject*)obj frame].origin.y;
	while(obj = [e nextObject]){
		[obj moveTo:NSMakePoint([(OrcaObject*)obj frame].origin.x,y)];
	}
}

- (IBAction) alignTop:(id)sender
{
	NSArray* items = [group selectedObjects];
	NSEnumerator* e = [items objectEnumerator];
	OrcaObject* obj = [e nextObject];
	float y = [obj frame].origin.y + [obj frame].size.height;
	while(obj = [e nextObject]){
		[obj moveTo:NSMakePoint([obj frame].origin.x,y - [obj frame].size.height)];
	}	
}

- (IBAction) alignLeft:(id)sender
{
	NSArray* items = [group selectedObjects];
	NSEnumerator* e = [items objectEnumerator];
	OrcaObject* obj = [e nextObject];
	float x = [obj frame].origin.x;
	while(obj = [e nextObject]){
		[obj moveTo:NSMakePoint(x,[obj frame].origin.y)];
	}
}

- (IBAction) alignRight:(id)sender
{
	NSArray* items = [group selectedObjects];
	NSEnumerator* e = [items objectEnumerator];
	OrcaObject* obj = [e nextObject];
	float x = [obj frame].origin.x + [obj frame].size.width;
	while(obj = [e nextObject]){
		[obj moveTo:NSMakePoint(x - [obj frame].size.width,[obj frame].origin.y)];
	}	
}

- (IBAction) alignVerticalCenters:(id)sender
{
	NSArray* items = [group selectedObjects];
	NSEnumerator* e = [items objectEnumerator];
	OrcaObject* obj = [e nextObject];
	float xc = [obj frame].origin.x + [obj frame].size.width/2.;
	while(obj = [e nextObject]){
		[obj moveTo:NSMakePoint(xc - [obj frame].size.width/2.,[obj frame].origin.y)];
	}	
}

- (IBAction) alignHorizontalCenters:(id)sender
{
	NSArray* items = [group selectedObjects];
	NSEnumerator* e = [items objectEnumerator];
	OrcaObject* obj = [e nextObject];
	float yc = [obj frame].origin.y + [obj frame].size.height/2.;
	while(obj = [e nextObject]){
		[obj moveTo:NSMakePoint([obj frame].origin.x,yc - [obj frame].size.height/2.)];
	}	
}

- (IBAction) arrangeInCircle:(id)sender
{
	NSUInteger count = [[group selectedObjects] count];
	NSArray* sortedArray = [[group selectedObjects] sortedArrayUsingSelector:@selector(sortCompare:)];
	//first find ranges
	float xMin = 9.99E100;
	float xMax = -9.99E100;
	float yMin = 9.99E100;
	float yMax = -9.99E100;
	for(OrcaObject* obj in sortedArray){
	
		float midX = [obj frame].origin.x;
		if(midX > xMax)xMax = midX;
		if(midX < xMin)xMin = midX;
		
		float midY = [obj frame].origin.y;
		if(midY > yMax)yMax = midY;
		if(midY < yMin)yMin = midY;
	}
	
	float radius = MAX((xMax - xMin),(xMax - xMin))/2.;
	NSPoint center = NSMakePoint(xMin + radius,yMin + radius);
	float deltaAngle = 2.*3.14159/(float)count;
	float a = 0;
    for(OrcaObject* obj in sortedArray){
		float newX = center.x  + radius*cosf(a);
		float newY = center.y + radius*sinf(a);
		[obj moveTo:NSMakePoint(newX,newY)];
		a += deltaAngle;
	}
}

- (IBAction) sendToBack:(id)sender
{
    [group sendSelectedObjectsToBack];
    [self setNeedsDisplay:YES];
}

- (IBAction) bringToFront:(id)sender
{
    [group bringSelectedObjectsToFront];
    [self setNeedsDisplay:YES];
}

- (IBAction)copy:(id)sender
{
    [savedObjects release];
    savedObjects = nil;
    savedObjects = [[group selectedObjects] retain];
    
    //declare our custom type.
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
    [pboard declareTypes:[NSArray arrayWithObjects:ORGroupPasteBoardItem, nil] owner:self];
    
    // the actual data doesn't matter since We're not really putting anything on the pasteboard. We are
    //using it to control the process. We save the objects locally and will provide them on request.
    [pboard setData:[NSData data] forType:ORObjArrayPtrPBType]; 
}

- (IBAction)delete:(id)sender
{
    [group removeSelectedObjects];
    [self setNeedsDisplay:YES];
}

- (IBAction)cut:(id)sender
{
    [self copy:nil];
    [group removeSelectedObjects];
    
    [self setNeedsDisplay:YES];
}

- (IBAction)paste:(id)sender
{
    NSPasteboard *pb = [NSPasteboard pasteboardWithName:NSGeneralPboard];
    
    NSData* data = [pb dataForType:ORGroupPasteBoardItem];
    if(data) {
        [group unHighlightAll];
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        id objectList = [unarchiver decodeObjectForKey:ORObjArrayPtrPBType];
        [unarchiver finishDecoding];
        [unarchiver release];
        
        for(NSNumber* aPointer in objectList){
			BOOL okToPaste = YES;
            OrcaObject* anObject = (OrcaObject*)[aPointer longValue];
			if([anObject solitaryObject]){
				NSArray* existingObjects = [[(ORAppDelegate*)[NSApp delegate]document] collectObjectsOfClass:[anObject class]];
				if([existingObjects count]){
					okToPaste = NO;
					NSBeep();
					NSLog(@"Ooops, you can not have two %@ objects in the configuration\n",NSStringFromClass([anObject class]));
				}
			} 
			if([anObject solitaryInViewObject]){
				NSArray* existingObjects = [group collectObjectsOfClass:[anObject class]];
				if([existingObjects count]){
					okToPaste = NO;
					NSBeep();
					NSLog(@"Ooops, you can not have two %@ objects in that container object\n",NSStringFromClass([anObject class]));
				}
			} 
			if(okToPaste){
				OrcaObject* newObject = [anObject copy]; 
				NSPoint newLocation =   [self suggestPasteLocationFor:newObject];
				if(newLocation.x != -1 && newLocation.y != -1){
					[self moveObject:newObject to:newLocation];
					[newObject setHighlightedYES]; 
					NSMutableArray* newObjects = [NSMutableArray array];
					[newObjects addObject:newObject];
					[group addObjects:newObjects];
				}
				[newObject release];
			}
        }
        
        [self  copy:nil];
    }
    [self setNeedsDisplay:YES];
}


- (IBAction)selectAll:(id)sender
{
    [group highlightAll];
    [self setNeedsDisplay:YES];
}

#pragma mark ¥¥¥Drap and Drop

- (NSPoint) suggestPasteLocationFor:(id)anObject
{
    NSPoint aPoint = [(OrcaObject*)anObject frame].origin;
    aPoint.x += 5;
    aPoint.y += 5;
    return aPoint;
}

- (BOOL) dropPositionOK:(NSPoint)aPoint
{
    return YES;
}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)flag
{	// return bitwise OR of all operations we support
    return NSDragOperationCopy | NSDragOperationMove;
}

- (BOOL)ignoreModifierKeysWhileDragging
{
    return NO;
}

- (void)pasteboard:(NSPasteboard *)sender provideDataForType:(NSString *)type
{
    
    
    NSEnumerator* e = nil;
    BOOL ok = YES;
    if([type isEqualToString:ORGroupPasteBoardItem])e = [savedObjects objectEnumerator];
    else if([type isEqualToString:ORGroupDragBoardItem])e = [draggedObjects objectEnumerator];
    else ok = NO;
    
    if(ok){
        //load the saved objects pointers into the paste board.
        NSMutableArray* pointerArray = [NSMutableArray array];
        id obj;
        while(obj = [e nextObject]){
            [pointerArray addObject:[NSNumber numberWithUnsignedInteger:(NSUInteger)obj]];
        }
        
        NSMutableData *itemData = [NSMutableData data];
        NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:itemData];
        [archiver setOutputFormat:NSPropertyListXMLFormat_v1_0];
        [archiver encodeObject:pointerArray forKey:ORObjArrayPtrPBType];
        [archiver finishEncoding];
        [archiver release];
        
        [sender setData:itemData forType:type];
    }
    
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    //check with the object(s) to make sure it can be dropped here.
    NSPasteboard *pb = [sender draggingPasteboard];
    NSData* data = [pb dataForType:ORGroupDragBoardItem];
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    id obj = [unarchiver decodeObjectForKey:ORObjArrayPtrPBType];
    [unarchiver finishDecoding];
    [unarchiver release];
    
    goodObjectsInDrag = YES;
    NSEnumerator* e = [(ORGroup*)obj objectEnumerator];
    NSNumber* aPointer;
    while(aPointer = [e nextObject]){
        OrcaObject* anObject = (OrcaObject*)[aPointer unsignedIntegerValue];
        if(![anObject acceptsGuardian:group]){
            goodObjectsInDrag = NO;
            break;
        }
    }
    
    if(!goodObjectsInDrag) return NO;
    else return [self draggingUpdated:sender];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    // make sure we can accept the drag.  If so, then turn on the highlight.
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSDragOperation mask = [sender draggingSourceOperationMask];
    unsigned int ret = NSDragOperationNone;
    
    if(goodObjectsInDrag){
        
        if([sender draggingSource] != self){
            ret = NSDragOperationCopy;
        }
        else {
            if(mask == NSDragOperationCopy){ 			//option key down so..
                if ([[pboard types] indexOfObject:ORGroupDragBoardItem] != NSNotFound) {
                    ret = NSDragOperationCopy;
                }
            }
            else {
                if ([[pboard types] indexOfObject:ORGroupDragBoardItem] != NSNotFound) {
                    ret = NSDragOperationMove;
                }
            }
            if (ret != NSDragOperationNone) {
                dragSessionInProgress = YES;
            }
            
        }
    }
    return ret;
    
}


- (void)draggingExited:(id <NSDraggingInfo>)sender
{	// turn off highlight if mouse not overhead anymore
    dragSessionInProgress = NO;
    goodObjectsInDrag = NO;
    [self setNeedsDisplay:YES];
}

- (BOOL) prepareForDragOperation:(id <NSDraggingInfo>)sender
{	// no prep needed, but we do want to proceed...
    return !dragLocked;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPoint localImagePoint = [self convertPoint:[sender draggedImageLocation] fromView:nil];
    if([sender draggingSourceOperationMask] == NSDragOperationCopy){
        return [self _doDragOp:@"drop" atPoint:localImagePoint];
    }
    else return [self _doDragOp:@"move" atPoint:localImagePoint];
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{	// clean up from drag
    dragSessionInProgress = NO;
    goodObjectsInDrag = NO;
    [self setNeedsDisplay:YES];
}

- (void) moveObject:(id)obj to:(NSPoint)aPoint
{
    [obj moveTo:aPoint];
}

#pragma mark ¥¥¥Connection Management
-(void)doConnectionFrom:(NSPoint)pt1 to:(NSPoint)pt2
{
    ORConnector* c1 = nil;
    ORConnector* c2 = nil;
    
    //get connector at pt1
    NSEnumerator* e  = [[group orcaObjects] reverseObjectEnumerator];
    OrcaObject* anObject;
    while ((anObject = [e nextObject])) {
        if((c1 = [anObject connectorAt:pt1]))break;
    }
    
    if(c1!= nil){
        e  = [[group orcaObjects] reverseObjectEnumerator];
        while ((anObject = [e nextObject])) {
            if((c2 = [anObject connectorAt:pt2]))break;
        }
    }
    
    [c1 connectTo:c2];
    
}

- (BOOL) canAddObject:(id) obj atPoint:(NSPoint)aPoint
{
    return [[(ORAppDelegate*)[NSApp delegate]document] documentCanBeChanged];
}

- (id) dataSource
{
    return self;
}

- (NSArray*)draggedNodes
{ 
    return draggedNodes; 
}
- (void) dragDone
{
    [draggedNodes release];
    draggedNodes = nil;
}

- (void) flagsChanged:(NSEvent *)theEvent 
{
    for(id anObj in [group orcaObjects]){
        [anObj flagsChanged:theEvent];
    }
}

- (void) setEnableIconControls:(BOOL) aState
{
    for(id anObj in [group orcaObjects]){
        [anObj setEnableIconControls:aState];
    }
}

- (void)keyDown:(NSEvent *)event
{
    if(dragLocked)return;
    
    int keyCode = [event keyCode];
	if(keyCode == 126){
		[self moveSelectedObjectsUp:event];
	}
	else if(keyCode == 125){
		[self moveSelectedObjectsDown:event];
	}
	else if(keyCode == 123){
		[self moveSelectedObjectsLeft:event];
	}
	else if(keyCode == 124){
		[self moveSelectedObjectsRight:event];
	}
	else if(keyCode == 24){
		[group changeSelectedObjectsLevel:NO];
		[self setNeedsDisplay:YES];
	}
	else if(keyCode == 27){
		[group changeSelectedObjectsLevel:YES];
		[self setNeedsDisplay:YES];
	}	
	else [super keyDown:event];
}


- (void) moveSelectedObjectsUp:(NSEvent*)event
{
    BOOL shiftKeyDown = ([event modifierFlags] & NSEventModifierFlagShift)!=0;
	float delta = shiftKeyDown?1:5;
	[self moveSelectedObjects:NSMakePoint(0,delta)];
}


- (void) moveSelectedObjectsDown:(NSEvent*)event
{
    BOOL shiftKeyDown = ([event modifierFlags] & NSEventModifierFlagShift)!=0;
	float delta = shiftKeyDown?1:5;
	[self moveSelectedObjects:NSMakePoint(0,-delta)];
}

- (void) moveSelectedObjectsLeft:(NSEvent*)event
{
    BOOL shiftKeyDown = ([event modifierFlags] & NSEventModifierFlagShift)!=0;
	float delta = shiftKeyDown?1:5;
	[self moveSelectedObjects:NSMakePoint(-delta,0)];
}

- (void) moveSelectedObjectsRight:(NSEvent*)event
{
    BOOL shiftKeyDown = ([event modifierFlags] & NSEventModifierFlagShift)!=0;
	float delta = shiftKeyDown?1:5;
	[self moveSelectedObjects:NSMakePoint(delta,0)];
}

- (void) moveSelectedObjects:(NSPoint)delta
{
	NSArray* objects = [group selectedObjects];
	id obj;
	NSEnumerator* e = [objects objectEnumerator];
	while(obj = [e nextObject]){
		NSPoint p = [(OrcaObject*)obj frame].origin;
		[obj moveTo:NSMakePoint(p.x+delta.x,p.y+delta.y)];
	}
}

- (void) setBackgroundImage:(NSImage *)newImage
{ 
    [newImage retain];
    [backgroundImage release];
    backgroundImage = newImage;
	
    [self setNeedsDisplay:YES];
}



@end

@implementation ORGroupView (private)

- (BOOL)_canTakeValueFromPasteboard:(NSPasteboard *)pb
{
    NSArray *typeArray = [NSArray arrayWithObjects:ORObjArrayPtrPBType,ORGroupPasteBoardItem,ORGroupDragBoardItem,nil];
    NSString *type = [pb availableTypeFromArray:typeArray];
    if (!type) {
        return NO;
    }
    return YES;
}


-(void)_startDrag:(NSEvent*)event
{
    NSPoint localPoint = [self convertPoint:[event locationInWindow] fromView:nil];
    
    NSEnumerator* e  = [[group orcaObjects] reverseObjectEnumerator];
    OrcaObject* anObject;
    while (anObject = [e nextObject]) {								//loop thru all icons
        if( NSPointInRect(localPoint,[anObject frame])){				//icon is hit?
                        
            [NSApp preventWindowOrdering];
            
            [draggedObjects release];
            draggedObjects = nil;
            draggedObjects = [[group selectedObjects] retain];
			
		
            if([draggedObjects count]){
                				
				//declare our custom type.
                NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
                [pboard declareTypes:[NSArray arrayWithObjects:ORGroupDragBoardItem, @"ORDataTaker Drag Item",NSStringPboardType,nil] owner:self];
                
                // the actual data doesn't matter since We're not really putting anything on the pasteboard. We are
                //using it to control the process. We save the objects locally and will provide them on request.
                [pboard setData:[NSData data] forType:ORObjArrayPtrPBType]; 
                
                
                //also add the objects as readoutobjects on a per object basis so that they can be 
                //dragged into a readoutlist or a ramperlist view.
                draggedNodes = [[NSMutableArray array] retain]; 
                NSEnumerator* ee = [draggedObjects objectEnumerator];
                id o;
                while(o=[ee nextObject]){
                    if([o conformsToProtocol:@protocol(ORDataTaker)] || [o conformsToProtocol:@protocol(ORHWWizard)]){
                        ORReadOutObject* itemWrapper = [[ORReadOutObject alloc] initWithObject:o];
                        [draggedNodes addObject:itemWrapper];
                        [itemWrapper release];
                    }
					if([draggedObjects count] == 1){
						[pboard setString:[o fullID]  forType:NSStringPboardType];
					}
                }

                if([draggedNodes count] == 0){
                    [draggedNodes release];
                    draggedNodes = nil;
                }
                else {
                    [pboard setData:[NSData data] forType:@"ORDataTaker Drag Item"]; 
                    [pboard setData:[NSData data] forType:@"ORHardwareWizardItem"]; 
                }
                
                //create the image to drag and start the process.
                NSImage* theImage = [[group imageOfObjects:draggedObjects withTransparency:0.4] retain];
                NSSize theSize = [theImage size];
                if([self scalePercent] == 0) [self setScalePercent:100];
                theSize.width  *= [self scalePercent]/100.;
                theSize.height *= [self scalePercent]/100.;
                [theImage setSize:theSize];
                [self dragImage : theImage
                             at : [group originOfObjects:draggedObjects]
                         offset : NSMakeSize(0.0, 0.0)
                          event : event
                     pasteboard : pboard
                         source : self
                      slideBack : YES];
                
                [theImage release];
            }
            break;
        }
    }
}




- (BOOL)_doDragOp:(NSString *)op atPoint:(NSPoint)aPoint
{
    NSPasteboard *pb = [NSPasteboard pasteboardWithName:NSDragPboard];
    NSData* data = [pb dataForType:ORGroupDragBoardItem];
	BOOL result = YES;
    if(data){
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        id objectList = [unarchiver decodeObjectForKey:ORObjArrayPtrPBType];
		
        if([op isEqual: @"drop"]){
            [group unHighlightAll];
            NSMutableArray* newObjects = [NSMutableArray array];
            for(NSNumber* aPointer in objectList){
                OrcaObject* anObject  = (OrcaObject*)[aPointer longValue];
                NSPoint     anOffset  = [anObject offset];
                NSPoint		newPoint  = NSMakePoint(aPoint.x + anOffset.x,aPoint.y + anOffset.y);
                BOOL okToDrop = YES;
                if([anObject solitaryObject]){
                    NSArray* existingObjects = [[(ORAppDelegate*)[NSApp delegate]document] collectObjectsOfClass:[anObject class]];
                    if([existingObjects count]){
                        okToDrop = NO;
                        NSBeep();
                        NSLog(@"Ooops, you can not have two %@ objects in the configuration\n",NSStringFromClass([anObject class]));
                    }
                } 
				if([anObject solitaryInViewObject]){
                    NSArray* existingObjects = [group collectObjectsOfClass:[anObject class]];
                    if([existingObjects count]){
                        okToDrop = NO;
                        NSBeep();
                        NSLog(@"Ooops, you can not have two %@ objects in that container object\n",NSStringFromClass([anObject class]));
                    }
                } 

				if([self canAddObject:anObject atPoint:newPoint] && okToDrop){
                    OrcaObject* newObject = [anObject copy];
                    [self moveObject:newObject to:newPoint];
                    [newObject setHighlighted:YES]; 
                    [newObjects addObject:newObject];
                    [newObject release];
                }
                else {
					result = NO;
					break;
				}
            }
            if(result)[group addObjects:newObjects];            
        }
        else if([op isEqual: @"move"]){	
            for(NSNumber* aPointer in objectList){
                OrcaObject* anObject = (OrcaObject*)[aPointer longValue];
                NSPoint     anOffset = [anObject offset];
                NSPoint		newPoint  = NSMakePoint(aPoint.x + anOffset.x,aPoint.y + anOffset.y);
                if([self canAddObject:anObject atPoint:newPoint]){
                    if([anObject guardian]!=group){
                        [[anObject retain] autorelease];
                        [[anObject guardian] removeObject:anObject];
                        [group addObject:anObject];
                        [anObject setGuardian:group];
                    }
                    [self moveObject:anObject to:NSMakePoint(aPoint.x + anOffset.x,aPoint.y + anOffset.y)];
                }
                else {					
					result = NO;
					break;
				}
			}
		}
		
		[unarchiver finishDecoding];
		[unarchiver release];
		
    }
    return result;
}
@end


