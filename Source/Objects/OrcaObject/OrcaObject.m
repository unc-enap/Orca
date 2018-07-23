//
//  OrcaObject.m
//  Orca
//
//  Created by Mark Howe on Fri Nov 29 2002.
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
#import "ORDataTaker.h"
#import "ORHWWizard.h"
#import "ORHelpCenter.h"

#pragma mark ¥¥¥Notification Strings
NSString* OROrcaObjectMoved         = @"OrcaObject Moved Notification";
NSString* OROrcaObjectDeleted       = @"OrcaObject Deleted Notification";
NSString* ORTagChangedNotification  = @"ORTagChangedNotification";
NSString* ORObjPtr                  = @"OrcaObject Pointer";
NSString* ORMovedObject             = @"OrcaObject That Moved";
NSString* ORForceRedraw             = @"ORForceRedraw";
NSString* OROrcaObjectImageChanged  = @"OROrcaObjectImageChanged";
NSString* ORIDChangedNotification   = @"ORIDChangedNotification";
NSString* ORObjArrayPtrPBType       = @"ORObjArrayPtrPBType";
NSString* ORWarningPosted			= @"WarningPosted";
NSString* ORMiscAttributesChanged   = @"ORMiscAttributesChanged";
NSString* ORMiscAttributeKey		= @"ORMiscAttributeKey";

#pragma mark ¥¥¥Inialization
@implementation OrcaObject 

- (id) init //designated initializer
{
    self = [super init];
    [self setConnectors:[NSMutableDictionary dictionary]];
    return self;
}


- (id) copyWithZone:(NSZone*)zone
{
    id obj = [[NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self]] retain];
    [obj setUniqueIdNumber:0];
    return obj;
}

-(void)dealloc
{
	[highlightedImage release];
    [image release];
    [connectors release];
	[miscAttributes release];
    [super dealloc];
}

- (void) setImage:(NSImage*)anImage
{
	NSAssert([NSThread mainThread],@"OrcaObject drawing from non-gui thread");
    [anImage retain];
    [image release];
    image = anImage;
    
    if(image){
        NSSize aSize = [image size];
        frame.size.width = aSize.width;
        frame.size.height = aSize.height;
        bounds.size.width = aSize.width;
        bounds.size.height = aSize.height;
    }
    else {
        frame.size.width 	= 50;
        frame.size.height 	= 50;
        bounds.size.width 	= 50;
        bounds.size.height 	= 50;
    }  
	
	if(image){
		NSRect sourceRect = NSMakeRect(0,0,[image size].width,[image size].height);
		[highlightedImage release];
		highlightedImage = [[NSImage alloc] initWithSize:[image size]];
		[highlightedImage lockFocus];
		[image drawAtPoint:NSZeroPoint fromRect:[image imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
		[[NSColor colorWithCalibratedWhite:0.0 alpha:0.5] set];
		NSRectFillUsingOperation(sourceRect, NSCompositingOperationSourceAtop);
		[highlightedImage unlockFocus];
	}
	else {
		[highlightedImage release];
		highlightedImage = nil;
	}
}


#pragma mark ¥¥¥Accessors
- (NSString*) description
{
    NSString* base =  [NSString stringWithFormat: @"(%@)",[self fullID]];
	if([self conformsToProtocol:NSProtocolFromString(@"ORDataTaker")]){
		base = [base stringByAppendingString:@"\nData Taker"];
	}
	if([self respondsToSelector:@selector(dataRecordDescription)]){
		NSDictionary* dict = [self dataRecordDescription];
		NSDictionary* recDict;
		NSString* decoders = @"";
		NSEnumerator* e = [dict objectEnumerator];
		while(recDict = [e nextObject]){
			id decoder = [recDict objectForKey:@"decoder"];
			if(decoder){
				decoders = [decoders stringByAppendingString:decoder];
				decoders = [decoders stringByAppendingString:@"\n"];
			}
		}
		if([decoders length])base = [base stringByAppendingFormat:@"\nDecoders:\n%@",decoders];
	}
	if([connectors count]){
		base = [base stringByAppendingString:@"\nConnectors:\n"];
		for(id aName in [connectors allKeys]){
			base = [base stringByAppendingFormat:@"\"%@\"\n",aName];
		}
	}
	
	return base;
}

- (int)	x
{
    return [self frame].origin.x;
}

- (int) y
{
    return [self frame].origin.y;
}

- (id) guardian
{
    return guardian;
}

- (void) setGuardian:(id)aGuardian
{
    //note the children do NOT retain their guardians to avoid retain cycles.
    guardian = aGuardian;
}

- (NSComparisonResult)sortCompare:(OrcaObject*)anObj
{
    return [[self className] caseInsensitiveCompare:[anObj className]];
}

- (id)document;
{
    return [(ORAppDelegate*)[NSApp delegate]document];
}

- (void) wakeUp {aWake = YES;}
- (void) sleep 	{aWake = NO;}
- (BOOL) aWake	{return aWake;}

- (void) setConnectors:(NSMutableDictionary*)someConnectors;
{
    [someConnectors retain];
    [connectors release];
    connectors = someConnectors;
}

- (NSMutableDictionary*) connectors;
{
    return connectors;
}


- (NSUndoManager *)undoManager
{
    return [[self document] undoManager];
}


- (NSRect) defaultFrame
{
    return NSMakeRect(0,0,50,50);
}

- (void) setFrame:(NSRect)aValue
{
    frame = aValue;
    bounds.size = frame.size;
}

- (NSRect) frame
{
    return frame;
}

- (void) setBounds:(NSRect)aValue
{
    bounds = aValue;
}

- (NSRect) bounds
{
    return bounds;
}

- (void) setFrameOrigin:(NSPoint)aPoint
{
    [self moveTo:aPoint];
}


- (void) setOffset:(NSPoint)aPoint
{
    offset = aPoint;
}

- (NSPoint)offset
{
    return offset;
}

- (BOOL) highlighted
{
    return highlighted;
}

- (void) setHighlighted:(BOOL)state
{
    if([self selectionAllowed])highlighted = state;
    else highlighted = NO;
}

- (BOOL) insideSelectionRect;
{
    return insideSelectionRect;
}

- (BOOL) intersectsRect:(NSRect) aRect
{
	return NSIntersectsRect(aRect,[self frame]);
}

- (BOOL) skipConnectionDraw
{
    return skipConnectionDraw;
}

- (void) setSkipConnectionDraw:(BOOL)state
{
    skipConnectionDraw = state;
}

- (void) setInsideSelectionRect:(BOOL)state
{
    insideSelectionRect = state;
}

- (BOOL) rectIntersectsIcon:(NSRect)aRect
{
    return NSIntersectsRect(aRect,frame);
}

- (void) makeMainController
{
    //subclasses will override
}

- (BOOL) hasDialog
{
	//by default objects have dialogs. subclasses can override. 
	//used to validate the popup contextual menu
	return YES;
}

- (NSString*) helpURL
{
	return nil;
}

- (id) calibration
{
	return nil;
}

- ( NSMutableArray*)children
{
    return nil;
}

- (NSMutableArray*) familyList
{
    return [NSMutableArray arrayWithObject:self];
}

- (int) stationNumber
{
    //some objects use stationNumber. they can override for special situations.
    //hardware wizard uses this instead of a slot or tag number.
    return (int)[self tag] + [self tagBase];
}

- (NSUInteger) tag
{
    return tag;
}

- (void) setTag:(NSUInteger)aTag
{
    tag = aTag;
    
    [[NSNotificationCenter defaultCenter]
         postNotificationName:ORTagChangedNotification
                       object:self];
}

- (int) tagBase
{
    //some objects, i.e. CAMAC start at 1 instead of 0. those object will override this method.
    return 0;
}

- (NSString*) fullID
{
    return [NSString stringWithFormat:@"%@,%u",NSStringFromClass([self class]),[self uniqueIdNumber]];
}

- (void) askForUniqueIDNumber
{
    [[self document] assignUniqueIDNumber:self];
}

- (void) setUniqueIdNumber:(uint32_t)anIdNumber
{
    uniqueIdNumber = anIdNumber;
    
    [[NSNotificationCenter defaultCenter]
         postNotificationName:ORIDChangedNotification
                       object:self];
}
- (uint32_t) uniqueIdNumber
{
    return uniqueIdNumber;
}

- (BOOL) selectionAllowed
{
    //default is to allow selection. subclasses can override.
    return YES;
}

- (BOOL) changesAllowed
{
    //default is to allow changes. subclasses can override.
    return YES;
}


- (int) compareStringTo:(id)anElement usingKey:(NSString*)aKey
{
    NSString* ourKey   = [self valueForKey:aKey];
    NSString* theirKey = [anElement valueForKey:aKey];
    if(!ourKey && theirKey)         return 1;
    else if(ourKey && !theirKey)    return -1;
    else if(!ourKey || !theirKey)   return 0;
    return [ourKey compare:theirKey];
}

#pragma mark ¥¥¥ID Helpers
//----++++----++++----++++----++++----++++----++++----++++----++++
//  These methods are used when objects are displayed in tables
//----++++----++++----++++----++++----++++----++++----++++----++++
- (NSString*) objectName
{
    NSString* theName =  NSStringFromClass([self class]);
	if([theName hasPrefix:@"OR"])theName = [theName substringFromIndex:2];
	if([theName hasSuffix:@"Model"])theName = [theName substringToIndex:[theName length]-5];
	return theName;
}
- (NSString*) isDataTaker
{
    return [self conformsToProtocol:@protocol(ORDataTaker)]?@"YES":@" NO";
}

- (NSString*) supportsHardwareWizard
{
    return [self conformsToProtocol:@protocol(ORHWWizard)]?@"YES":@" NO";
}

- (NSString*) identifier
{
    return @"";
}
//----++++----++++----++++----++++----++++----++++----++++----++++


#pragma mark ¥¥¥Undoable Actions
-(void)moveTo:(NSPoint)aPoint
{
    [[[self undoManager] prepareWithInvocationTarget:self] moveTo:[self frame].origin];
    frame.origin = aPoint;
    
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:self forKey: ORMovedObject];
    
    [[NSNotificationCenter defaultCenter]
                        postNotificationName:OROrcaObjectMoved
                                      object:self
                                    userInfo: userInfo];
}

-(void)move:(NSPoint)aPoint
{
    [self moveTo:NSMakePoint(frame.origin.x+aPoint.x,frame.origin.y+aPoint.y)];
}

-(void)showMainInterface
{
    [self makeMainController];
}

-(void)linkToController:(NSString*)controllerClassName
{
    [[self document] makeController:controllerClassName forObject:self];
}


#pragma mark ¥¥¥Drawing

- (void) drawSelf:(NSRect)aRect
{
    [self drawSelf:aRect withTransparency:1.0];
}


- (void) drawSelf:(NSRect)aRect withTransparency:(float)aTransparency
{
	[self drawIcon:aRect withTransparency:aTransparency];
	[self drawConnections:aRect withTransparency:aTransparency];
}

- (void) drawIcon:(NSRect)aRect withTransparency:(float)aTransparency
{
	//a workaround for a case where image hasn't been made yet.. don't worry--it will get made below if need be.
	if(aRect.size.height == 0)aRect.size.height = 1;
	if(aRect.size.width == 0)aRect.size.width = 1;
	NSShadow* theShadow = nil;
	
    if(NSIntersectsRect(aRect,[self frame])){
		
		if([self guardian]){
			[NSGraphicsContext saveGraphicsState]; 
			
			// Create the shadow below and to the right of the shape.
			theShadow = [[NSShadow alloc] init]; 
			[theShadow setShadowOffset:NSMakeSize(3.0, -3.0)]; 
			[theShadow setShadowBlurRadius:3.0]; 
			
			// Use a partially transparent color for shapes that overlap.
			[theShadow setShadowColor:[[NSColor blackColor]
				 colorWithAlphaComponent:0.3]]; 
			
			[theShadow set];
		}
		// Draw.
		
		
        if(!image){
            [self setUpImage];
        }
        if(image){
			NSImage* imageToDraw;
			if([self highlighted])imageToDraw = highlightedImage;
			else imageToDraw = image;
			
			NSRect sourceRect = NSMakeRect(0,0,[imageToDraw size].width,[imageToDraw size].height);
			[imageToDraw drawAtPoint:frame.origin fromRect:sourceRect operation:NSCompositingOperationSourceOver fraction:aTransparency];
            
        }
        else {
            //no icon so fake it with just a square
            if([self highlighted]){
                [[NSColor redColor]set];
            }
            else {
                [[NSColor blueColor]set];
            }
            NSFrameRect(frame);
            NSAttributedString* s = [[NSAttributedString alloc] initWithString:@"No Icon"];
            [s drawAtPoint:frame.origin];
            [s release];
        }
        
		if([self guardian]){
			[NSGraphicsContext restoreGraphicsState];
		}        
   }
	[theShadow release]; 
}

- (void) drawConnections:(NSRect)aRect withTransparency:(float)aTransparency
{
    for (id key in connectors) {
        id aConnector = [connectors objectForKey:key];
        [aConnector drawSelf:aRect withTransparency:aTransparency];
        if(![self skipConnectionDraw]){
            [aConnector drawConnection:aRect];
        }
    }
}



- (void) drawImageAtOffset:(NSPoint)anOffset withTransparency:(float)aTransparency
{
    BOOL saveState = [self highlighted];
    NSRect oldFrame = frame;
    NSRect aFrame = frame;
    aFrame.origin.x += anOffset.x;
    aFrame.origin.y += anOffset.y;
    [self setFrame:aFrame];
    [self setHighlighted:NO];
    [self setSkipConnectionDraw:YES];
    [self drawSelf:frame withTransparency:aTransparency];
    [self setSkipConnectionDraw:NO];
    [self setOffset:NSMakePoint(frame.origin.x,frame.origin.y)];
    [self setFrame:oldFrame];
    
    [self setHighlighted:saveState];
}


#pragma mark ¥¥¥Mouse Events
- (BOOL) acceptsClickAtPoint:(NSPoint)aPoint
{
	return NSPointInRect(aPoint,[self frame]);
}

- (void) openHelp:(id)sender
{
	[[(ORAppDelegate*)[NSApp delegate] helpCenter] showHelpCenterPage:[self helpURL]];
}

- (void) doDoubleClick:(id)sender
{
    [self showMainInterface];
}

- (void) flagsChanged:(NSEvent *)theEvent
{
    BOOL shiftKeyDown = ([[NSApp currentEvent] modifierFlags] & NSEventModifierFlagShift) != 0 ;
    BOOL cmdKeyDown = ([[NSApp currentEvent] modifierFlags] & NSEventModifierFlagCommand) != 0;
    [self setEnableIconControls:shiftKeyDown && cmdKeyDown];
}
- (void) setEnableIconControls:(BOOL) aState
{
    BOOL redraw = enableIconControls!=aState;
    enableIconControls = aState;
    if(redraw)[self setUpImage];
}

- (void) doCmdClick:(id)sender atPoint:(NSPoint)aPoint
{
	//subclasses can use as needed.
}
- (void) doShiftCmdClick:(id)sender atPoint:(NSPoint)aPoint
{
	//subclasses can use as needed.
}
- (void) doCmdDoubleClick:(id)sender atPoint:(NSPoint)aPoint
{
	//subclasses can use as needed.
}
- (void) doCntrlClick:(NSView*)aView
{
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
	
    NSMenu *menu = [[NSMenu alloc] init];
     [[menu insertItemWithTitle:@"Open"
                       action:@selector(doDoubleClick:)
                keyEquivalent:@""
					   atIndex:0] setTarget:self];
	[[menu insertItemWithTitle:@"Help"
						action:@selector(openHelp:)
				 keyEquivalent:@""
					   atIndex:1] setTarget:self];
	[menu setDelegate:self];
    [NSMenu popUpContextMenu:menu withEvent:event forView:aView];
    [menu release];
}

- (BOOL) validateMenuItem:(NSMenuItem *)anItem
{
    if ([anItem action] == @selector(doDoubleClick:)) {
        return [self hasDialog];
    }
    else if ([anItem action] == @selector(openHelp:)) {
        return [[self helpURL] length];
    }
	else return YES;
}

- (ORConnector*) requestsConnection: (NSPoint)aPoint
{
	ORConnector* theConnector = [self connectorAt:aPoint];
    if(![theConnector hidden])return theConnector;
	else return nil;
}


- (NSImage*)image
{
    return image;
}


#pragma mark ¥¥¥Archival
static NSString *OROrcaObjectFrame		= @"OROrcaObject Frame";
static NSString *OROrcaObjectOffset 		= @"OROrcaObject Offset";
static NSString *OROrcaObjectBounds 		= @"OROrcaObject Bounds";
static NSString *OROrcaObjectConnectors		= @"OROrcaOjbect Connectors";
static NSString *OROrcaObjectTag            = @"OROrcaOjbect Tag";
static NSString* OROrcaObjectUniqueIDNumber = @"OROrcaObjectUniqueIDNumber";
//static NSString *OROrcaObjectLocks		= @"OROrcaObject Locks";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
 
	int newVersion = [decoder decodeIntForKey:@"newVersion"];
	if(newVersion)	{
		frame  = [decoder decodeRectForKey:@"localFrame"];
		offset = [decoder decodePointForKey:@"offset"];
		bounds = [decoder decodeRectForKey:@"bounds"];
	}
	else {
		[self setFrame:[[decoder decodeObjectForKey:OROrcaObjectFrame] rectValue]];
		[self setOffset:[[decoder decodeObjectForKey:OROrcaObjectOffset] pointValue]];
		[self setBounds:[[decoder decodeObjectForKey:OROrcaObjectBounds] rectValue]];
	}
	      

    [self setConnectors:[decoder decodeObjectForKey:OROrcaObjectConnectors]];
    [self setTag:[decoder decodeIntegerForKey:OROrcaObjectTag]];
    [self setUniqueIdNumber:[decoder decodeIntForKey:OROrcaObjectUniqueIDNumber]];
    miscAttributes = [[decoder decodeObjectForKey:@"miscAttributes"] retain];
	
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
	[encoder encodeInteger:1 forKey:@"newVersion"];

    [encoder encodeRect:frame forKey:@"localFrame"];
    [encoder encodePoint:offset forKey:@"offset"];
    [encoder encodeRect: bounds forKey:@"bounds"];
    [encoder encodeObject:connectors forKey:OROrcaObjectConnectors];
    [encoder encodeInteger:[self tag] forKey:OROrcaObjectTag];
    [encoder encodeInt:uniqueIdNumber forKey:OROrcaObjectUniqueIDNumber];
	[encoder encodeObject:miscAttributes forKey:@"miscAttributes"];
}

- (void) awakeAfterDocumentLoaded
{
}

#pragma mark ¥¥¥General

- (void) setHighlightedYES
{
    [self setHighlighted:YES];
}

- (void) setHighlightedNO
{
    [self setHighlighted:NO];
}

- (void) resetAlreadyVisitedInChainSearch
{
	alreadyVisitedInChainSearch = NO;
}

- (BOOL) isObjectInConnectionChain:(id)anObject
{
	if(alreadyVisitedInChainSearch) return NO;
	else alreadyVisitedInChainSearch = YES;
	
	BOOL result = NO;
    for (id key in connectors) {
        ORConnector* aConnector = [connectors objectForKey:key];
		result |= [[aConnector objectLink] isObjectInConnectionChain:anObject];
    }
	
	return result;
}

- (NSArray*) collectObjectsOfClass:(Class)aClass
{
    if([self isKindOfClass:aClass]){
        return [NSArray arrayWithObject:self];
    }
    else return nil;
}

- (BOOL) loopChecked
{
	return loopChecked;
}

- (void) setLoopChecked:(BOOL)aFlag
{
	loopChecked = aFlag;
}
- (void) clearLoopChecked
{
	loopChecked = NO;
}

- (NSArray*) collectConnectedObjectsOfClass:(Class)aClass
{
    NSMutableArray* collection = [NSMutableArray arrayWithCapacity:256];
	[self setLoopChecked:YES];
	NSEnumerator* e = [connectors objectEnumerator];
	id obj;
	while(obj = [e nextObject]){
		id connectedObject = [obj connectedObject];
		if(![connectedObject loopChecked]){
			[connectedObject setLoopChecked:YES];
			if([self isKindOfClass:aClass]){
				[collection addObject:self];
			}
			[collection addObjectsFromArray:[connectedObject collectConnectedObjectsOfClass:aClass]];
		}
	}
	return collection;
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    //subclass responsibility
    return nil;
}

- (id) findController
{
	NSArray* controllers = [[self document] findControllersWithModel:self];
	if([controllers count])return [controllers objectAtIndex:0];
	else return nil;
}

- (NSArray*) collectObjectsConformingTo:(Protocol*)aProtocol
{
    if([self conformsToProtocol:aProtocol]){
        return [NSArray arrayWithObject:self];
    }
    else return nil;
}

- (NSArray*) collectObjectsRespondingTo:(SEL)aSelector
{
    if([self respondsToSelector:aSelector]){
        return [NSArray arrayWithObject:self];
    }
    else return nil;
}

- (NSArray*) subObjectsThatMayHaveDialogs
{
	//subclasses can override as needed.
	return nil;
}


- (id) findObjectWithFullID:(NSString*)aFullID;
{
    if([aFullID isEqualToString:[self fullID]])return self;
    else return nil;
}


#pragma mark ¥¥¥Methods To Override
- (void) setUpImage
{
    [self setImage:nil];
    //subclasses will override. DON'T call super
}

- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian
{
    return  [aGuardian isMemberOfClass:NSClassFromString(@"ORGroup")]           || 
	[aGuardian isMemberOfClass:NSClassFromString(@"ORContainerModel")];
}


- (BOOL) solitaryObject
{
    return NO;
}

- (BOOL) solitaryInViewObject
{
    return NO;
}


- (NSMutableDictionary*) miscAttributesForKey:(NSString*)aKey
{
	return [miscAttributes objectForKey:aKey];
}

- (void) setMiscAttributes:(NSMutableDictionary*)someAttributes forKey:(NSString*)aKey
{

	if(!miscAttributes)  miscAttributes = [[NSMutableDictionary alloc] init];
	
	NSMutableDictionary* oldAttrib = [miscAttributes objectForKey:aKey];
	if(oldAttrib){
		[[[self undoManager] prepareWithInvocationTarget:self] setMiscAttributes:[[oldAttrib copy] autorelease] forKey:aKey];
	}
	[miscAttributes setObject:someAttributes forKey:aKey];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMiscAttributesChanged 
														object:self
														userInfo:[NSDictionary dictionaryWithObject:aKey forKey:ORMiscAttributeKey]];    
}


#pragma mark ¥¥¥Connection Management

- (id) objectConnectedTo:(id)aConnectorName
{
    return [[[connectors objectForKey:aConnectorName] connector] objectLink];
}

- (id) connectorOn:(id)aConnectorName
{
    return [[connectors objectForKey:aConnectorName] connector];
}

- (id) connectorWithName:(id)aConnectorName
{
    return [connectors objectForKey:aConnectorName];
}

- (id) connectorAt:(NSPoint)aPoint
{
    for (id key in connectors) {
        ORConnector* aConnector = [connectors objectForKey:key];
        if([aConnector pointInRect:aPoint])return aConnector;
    }
    return nil;
}

- (void) disconnect
{
    for (id key in connectors) {
        ORConnector* aConnector = [connectors objectForKey:key];
        [aConnector disconnect];
    }
}


- (void) removeConnectorForKey:(NSString*)key
{
    if(key){
        [[connectors objectForKey:key] disconnect];
        [connectors removeObjectForKey:key];
    }
}


- (void) connectionChanged
{
    //do nothing , subclasses can override
}

- (void) assumeDisplayOf:(ORConnector*)aConnector
{
    //remove all entries of aConnector and add aConnector back in under a new key.
    NSEnumerator *e = [[connectors allKeys] objectEnumerator];
    id key;
    while ((key = [e nextObject])) {
        if([connectors objectForKey:key] == aConnector)return;
    }
    if(aConnector){
        //find name not being used
        int index = 0;
        NSString* unusedKey;
        for(;;){
            unusedKey = [NSString stringWithFormat:@"OwnedConnection_%d",index];
            if([connectors objectForKey:unusedKey]){
                index++;
            }
            else break;
        }
        [connectors setObject: aConnector forKey:unusedKey];
        [aConnector setGuardian:self];
    }
}

- (void) removeDisplayOf:(ORConnector*)aConnector
{
    NSEnumerator *e = [[connectors allKeys] objectEnumerator];
    id key;
    while ((key = [e nextObject])) {
        if([connectors objectForKey:key] == aConnector){
            [aConnector disconnect];
            [connectors removeObjectForKey:key];
            [aConnector setGuardian:nil];
            break;
        }
    }    
}

- (void) postWarning:(NSString*)warningString
{
    [[NSNotificationCenter defaultCenter] 
		postNotificationName:ORWarningPosted 
					object:self 
					userInfo:[NSDictionary dictionaryWithObjectsAndKeys:warningString,@"WarningMessage",nil]];
}

#pragma mark ¥¥¥Access for RunControl Stuff
- (void) addRunWaitWithReason:(NSString*)aReason
{
    NSNotification* aNote = [NSNotification notificationWithName:ORAddRunStateChangeWait object:self userInfo:[NSDictionary dictionaryWithObject:aReason forKey:@"Reason"]];
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThread:aNote waitUntilDone:YES];
}

- (void) releaseRunWait
{
    NSNotification* aNote = [NSNotification notificationWithName:ORReleaseRunStateChangeWait object:self];
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThread:aNote waitUntilDone:YES];
}
- (void) addRunWaitFor:(id)anObject reason:(NSString*)aReason
{
    NSNotification* aNote = [NSNotification notificationWithName:ORAddRunStateChangeWait object:anObject userInfo:[NSDictionary dictionaryWithObject:aReason forKey:@"Reason"]];
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThread:aNote waitUntilDone:YES];
}

- (void) releaseRunWaitFor:(id)anObject
{
    NSNotification* aNote = [NSNotification notificationWithName:ORReleaseRunStateChangeWait object:anObject];
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThread:aNote waitUntilDone:YES];
}

- (uint32_t) processID{return 0;}
- (void) setProcessID:(uint32_t)aValue
{
    //subclasses should override
}

@end

@implementation OrcaObject (cardSupport)
- (short) numberSlotsUsed
{
	return 0;
}

- (BOOL) acceptsObject:(id) anObject
{
	return NO;
}
@end

@implementation OrcaObject (scriptingAdditions)
//this is just to help with the scriting stuff
- (long) longValue
{
	return 1;
}

- (NSInteger) second
{
	return [[NSDate date] secondOfMinute];
}

- (NSInteger) minute
{
	return [[NSDate date] minuteOfHour];
}

- (NSInteger) hour
{
	return [[NSDate date] hourOfDay];
}

- (NSInteger) day
{
	return [[NSDate date] dayOfMonth];
}

- (NSInteger) month
{
	return [[NSDate date] monthOfYear];
}

- (NSInteger) year
{
	return [[NSDate date] yearOfCommonEra];
}

@end

@implementation NSObject (OrcaObject_Catagory)
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)aDataPacket forChannel:(int)aChannel
{
    //subclasses will override.
    return nil;
}


- (void) runTaskBoundary
{
}


- (void) makeConnectors
{
    //subclasses will override.
}
- (void) appendEventDictionary:(NSMutableDictionary*)anEventDictionary topLevel:(NSMutableDictionary*)topLevel
{
    //subclasses will override.
}
@end

