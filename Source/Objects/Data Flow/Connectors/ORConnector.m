//
//  ORConnector.m
//  Orca
//
//  Created by Mark Howe on Thu Dec 12 2002.
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
#import "ORDotImage.h"

NSString* ORConnectionChanged = @"OR Connection Changed";


@implementation ORConnector

#pragma mark ¥Initialization
- (id) initAt:(NSPoint)aPoint withGuardian:(id)aGuardian withObjectLink:(id)anObjectLink
{
    if(self = [super init]){
		[self setConnectorImageType:kDefaultImage]; 	//default
		[self setConnectorType:0]; 		//default- non-restricted
		[self setLocalFrame: NSMakeRect(aPoint.x,aPoint.y,kConnectorSize,kConnectorSize)];
		[self setGuardian:aGuardian];
		[self setObjectLink:anObjectLink];
        [self loadDefaults];
		[self loadImages];
        [self setOnColor: [NSColor greenColor]];
        [self setOffColor: [NSColor redColor]];
        [self registerNotificationObservers];        
    }
    return self;
}

- (id) initAt:(NSPoint)aPoint withGuardian:(id)aGuardian
{
    self = [self initAt:aPoint withGuardian:aGuardian withObjectLink:aGuardian];
    return self;
}

- (void) loadImages
{
    switch([self connectorImageType] ){
		
		case kHorizontalRect:
			[self setOnImage:[ORDotImage hRectWithColor:onColor]];
			[self setOffImage:[ORDotImage hRectWithColor:offColor]];
			break;
			
		case kVerticalRect:
		case kSmallVerticalRect:
			[self setOnImage:[ORDotImage vRectWithColor:onColor]];
			[self setOffImage:[ORDotImage vRectWithColor:offColor]];
			break;
			

		case kSmallDot:
			[self setOnImage:[ORDotImage smallDotWithColor:onColor]];
			[self setOffImage:[ORDotImage smallDotWithColor:offColor]];
			break;

		case kDefaultImage:
		default:
			[self setOnImage:[ORDotImage dotWithColor:onColor]];
			[self setOffImage:[ORDotImage dotWithColor:offColor]];
			break;
			
    }
    
    //assumes that setLocalFrame has been called before to set the local origin
    [self setLocalFrame: NSMakeRect(localFrame.origin.x,localFrame.origin.y,[onImage size].width,[onImage size].height)];
}

- (void) loadDefaults
{
    NSColor* color = colorForData([[NSUserDefaults standardUserDefaults] objectForKey: ORLineColor]);
    [self setLineColor:(color!=nil?color:[NSColor blackColor])];
    [self setLineType:[[[NSUserDefaults standardUserDefaults] objectForKey: ORLineType] intValue]];
    //[self setOnColor: [NSColor greenColor]];
    //[self setOffColor: [NSColor redColor]];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];	
    [restrictedList release];
    [lineColor release];
    [onImage release];
    [offImage release];
    [connector release];
    [onColor release];
    [offColor release];
	
    [super dealloc];
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(lineColorChanged:)
                         name : ORLineColorChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(lineTypeChanged:)
                         name : ORLineTypeChangedNotification
                       object : nil];  
}

- (void) lineColorChanged:(NSNotification*)aNotification
{
    NSUserDefaults*  defaults 	 = [NSUserDefaults standardUserDefaults];
    NSData*			 colorAsData = [defaults objectForKey: ORLineColor];
    [self setLineColor:[NSUnarchiver unarchiveObjectWithData:colorAsData]];    
}

- (void) lineTypeChanged:(NSNotification*)aNotification
{
    NSUserDefaults* defaults 	= [NSUserDefaults standardUserDefaults];
    [self setLineType:[[defaults objectForKey: ORLineType] intValue]];
}

#pragma mark ¥¥¥Accessors
- (id) guardian
{
    return guardian;
}

- (void) setGuardian:(id)aGuardian
{
    guardian = aGuardian; //don't retain guardian. avoids a retain cycle.
}
- (void) setSameGuardianIsOK: (BOOL)aFlag
{
    sameGuardianIsOK = aFlag;
}

- (id) objectLink
{
    return objectLink;
}
- (void) setObjectLink:(id)aLink;
{
    objectLink = aLink; //don't retain guardian. avoids a retain cycle.    
}

- (BOOL) hidden
{
	return hidden;
}

- (void) setHidden:(BOOL)state
{
	hidden = state;
}

- (BOOL) isConnected
{
	return connector!=nil;
}

- (NSColor *) onColor
{
    return onColor; 
}

- (void) setOnColor: (NSColor *) anOnColor
{
    [anOnColor retain];
    [onColor release];
    onColor = anOnColor;
    [self loadImages];
}


- (NSColor *) offColor
{
    return offColor; 
}

- (void) setOffColor: (NSColor *) anOffColor
{
    [anOffColor retain];
    [offColor release];
    offColor = anOffColor;
    [self loadImages];
}


- (NSImage*) onImage
{
    return onImage;
}

- (void) setOnImage:(NSImage *)anImage
{
    [anImage retain];
    [onImage release];
    onImage = anImage;
	
	onImage_Highlighted = [[NSImage alloc] initWithSize:[onImage size]];
	[onImage_Highlighted lockFocus];
	[onImage drawAtPoint:NSZeroPoint fromRect:[onImage imageRect] operation:NSCompositingOperationCopy fraction:1.0];
	[[NSColor colorWithCalibratedWhite:0.0 alpha:0.5] set];
	NSRect sourceRect = NSMakeRect(0,0,[onImage size].width,[onImage size].height);
	NSRectFillUsingOperation(sourceRect, NSCompositingOperationSourceAtop);
	[onImage_Highlighted unlockFocus];
	
}

- (NSImage*) offImage
{
    return offImage;
}

- (void) setOffImage:(NSImage *)anImage
{
    [anImage retain];
    [offImage release];
    offImage = anImage;
	
	offImage_Highlighted = [[NSImage alloc] initWithSize:[offImage size]];
	[offImage_Highlighted lockFocus];
	[offImage drawAtPoint:NSZeroPoint fromRect:[offImage imageRect] operation:NSCompositingOperationCopy fraction:1.0];
	[[NSColor colorWithCalibratedWhite:0.0 alpha:0.5] set];
	NSRect sourceRect = NSMakeRect(0,0,[offImage size].width,[offImage size].height);
	NSRectFillUsingOperation(sourceRect, NSCompositingOperationSourceAtop);
	[offImage_Highlighted unlockFocus];
	
}


- (NSRect) localFrame
{
    return localFrame;
}

- (void) setLocalFrame:(NSRect)aRect
{
    localFrame = aRect;
}

- (NSColor*) lineColor
{
    return lineColor;
}

- (void) setLineColor:(NSColor*)aColor
{
    [aColor retain];
    [lineColor release];
    lineColor = aColor;
}

- (int) lineType;
{
    return lineType;
}

- (void) setLineType:(int)aType
{
    lineType = aType;
}

- (uint32_t) connectorType
{
    return connectorType;
}

- (uint32_t) ioType
{
	return ioType;
}

- (void) setIoType: (uint32_t)aType
{
	if(aType > kOutputConnector){
		aType = kInOutConnector; //just default it...
	}
	ioType = aType;
}

- (void) setConnectorType:(uint32_t) type
{
    //a non-zero connector type restricts the connection to others of that type
    connectorType = type;
}

- (void) addRestrictedConnectionType:(uint32_t)type
{
    if(!restrictedList){
		[self setRestrictedList:[NSMutableArray array]];
    }
    [restrictedList addObject:[NSNumber numberWithLong:type]];
}

- (BOOL) acceptsConnectionType:(uint32_t)aType
{
    if([restrictedList count]){
		for(id n in restrictedList){
			if(aType == (uint32_t)[n longValue])return YES;
		}
		return NO;
    }
    else return aType == [self connectorType];
}

- (BOOL) acceptsIoType:(uint32_t)aType
{
	if( aType == kInOutConnector || ioType == kInOutConnector)return YES;
	else {
		if(aType == kInputConnector && ioType == kOutputConnector)return YES;
		else if(aType == kOutputConnector && ioType == kInputConnector)return YES;
		else return NO;
	}
}


- (int) connectorImageType
{
    return connectorImageType;
}

- (void) setConnectorImageType:(int) type
{
    connectorImageType = type;
    [self loadImages];
}

- (int) identifer
{
    return identifer;
}

- (void) setIdentifer:(int) anIdentifer
{
    identifer = anIdentifer;
}


- (NSMutableArray*) restrictedList
{
    return restrictedList;
}

- (void) setRestrictedList:(NSMutableArray*)newRestrictedList
{
    [restrictedList autorelease];
    restrictedList=[newRestrictedList retain];
}


- (id) connectedObject
{
    return [connector objectLink];
}

#pragma mark ¥¥¥Events
- (BOOL) pointInRect: (NSPoint)aLocalPoint
{
    NSRect guardianRect  = [guardian frame];
    NSRect convertedRect = NSOffsetRect([self localFrame],guardianRect.origin.x,guardianRect.origin.y);
    if( NSPointInRect(aLocalPoint,convertedRect))return YES;
    return NO;
}

- (void) connectTo:(ORConnector*)aConnector
{

    if(aConnector!=nil                       &&
       aConnector != self                    &&
       [aConnector objectLink] != objectLink &&
       (([self guardian] != [aConnector guardian]) || sameGuardianIsOK)){
        
		if( [self acceptsConnectionType:[aConnector connectorType]] &&
            [aConnector acceptsConnectionType:connectorType]        &&
			[self acceptsIoType:[aConnector ioType]]                &&
            [aConnector acceptsIoType:ioType] ){
			//first disconnect if needed
			if(connector!=nil)[self disconnect];
			if([aConnector connector]!=nil)[aConnector disconnect];
			[self setConnection:aConnector];
			[aConnector setConnection:self];
		}
		else{
			ORRunAlertPanel(@"Illegal Connection",@"Connection refused!",nil,nil,nil);
		}
    }
    else if(aConnector!=nil && aConnector != self)ORRunAlertPanel(@"Illegal Connection",@"Connection refused!",nil,nil,nil);
}

- (void) disconnect
{
    [connector setConnection:nil];
    [self setConnection:nil];	
}

- (ORConnector*) connector
{
    return connector;
}

#pragma mark ¥¥¥Drawing
- (NSPoint) centerPoint
{
    NSRect guardianRect      = [guardian frame];
    NSRect convertedDrawRect = NSOffsetRect([self localFrame],guardianRect.origin.x,guardianRect.origin.y);
    return NSMakePoint(NSMidX(convertedDrawRect),NSMidY(convertedDrawRect));
}

- (NSRect) lineBounds
{
	return NSUnionRect([guardian frame],[[connector guardian] frame]);
}

- (void) drawSelf:(NSRect)aRect
{
    [self drawSelf:aRect withTransparency:1.0];
}

- (void) drawSelf:(NSRect)aRect withTransparency:(float)aTransparency
{
	if(hidden)return;
	
    NSRect guardianRect      = [guardian frame];
    NSRect convertedDrawRect = NSOffsetRect([self localFrame],guardianRect.origin.x,guardianRect.origin.y);
    
    if(!NSIntersectsRect(aRect,convertedDrawRect))return;
    
    NSImage *imageToDraw;
	NSRect frame = convertedDrawRect;
	if([guardian highlighted]){
		if([self connector] == nil)	imageToDraw = offImage_Highlighted;
		else						imageToDraw = onImage_Highlighted;
	}
	else {
		if([self connector] == nil)	imageToDraw = offImage;
		else						imageToDraw = onImage;
	}
	if(imageToDraw){
		NSRect sourceRect = NSMakeRect(0,0,[imageToDraw size].width,[imageToDraw size].height);
		[imageToDraw drawAtPoint:frame.origin fromRect:sourceRect operation:NSCompositingOperationSourceOver fraction:aTransparency];
	}
}

- (void) drawConnection:(NSRect)aRect
{
    if(hidden)			 return;
    if(connector == nil) return;
	
	NSShadow* theShadow = nil;
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
    NSBezierPath* path = [NSBezierPath bezierPath];
    [path moveToPoint:[self centerPoint]];
    int x;
    NSPoint halfWayPoint1;
    NSPoint halfWayPoint2;
    switch ([self lineType]){
		case straightLines:
			[path lineToPoint:[[self connector] centerPoint]];
			break;
			
		case squareLines:
			x = [self centerPoint].x + ([[self connector] centerPoint].x - [self centerPoint].x)/2;
			halfWayPoint1 = NSMakePoint(x,[self centerPoint].y);
			halfWayPoint2 = NSMakePoint(x,[[self connector] centerPoint].y);
			[path lineToPoint:halfWayPoint1];
			[path lineToPoint:halfWayPoint2];
			[path lineToPoint:[[self connector] centerPoint]];
			break;
			
		case curvedLines:
			x = [self centerPoint].x + ([[self connector] centerPoint].x - [self centerPoint].x)/2;
			halfWayPoint1 = NSMakePoint(x,[self centerPoint].y);
			halfWayPoint2 = NSMakePoint(x,[[self connector] centerPoint].y);
			
			//			halfWayPoint1 = NSMakePoint([self centerPoint].x,[self centerPoint].y-50);
			//			halfWayPoint2 = NSMakePoint([[self connector] centerPoint].x,[[self connector] centerPoint].y-50);
			
			
			[path curveToPoint:[[self connector] centerPoint] controlPoint1:halfWayPoint1 controlPoint2:halfWayPoint2];
			break;
    }
    if(NSIntersectsRect(aRect,NSInsetRect([path bounds],-20,-20))){
		[self strokeLine:path];
    }	
	if([self guardian]){
		[NSGraphicsContext restoreGraphicsState];
	}
	[theShadow release]; 
}

- (void) strokeLine:(NSBezierPath*) path
{
	[lineColor set];
	[path setLineWidth:.5];
	[path stroke];
}

#pragma mark ¥¥¥Undoable Actions
- (void) setConnection:(ORConnector*)aConnection
{
    [[[guardian undoManager] prepareWithInvocationTarget:self] setConnection:connector];
    [aConnection retain];
    [connector release];
    connector = aConnection;
    
    [guardian connectionChanged];
	if(guardian!=objectLink){
		[objectLink connectionChanged];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName: ORConnectionChanged object:guardian];
    
}



#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    
    self = [super init];
	int newVersion = [decoder decodeIntForKey:@"newVersion"];
	if(newVersion)	[self setLocalFrame:[decoder decodeRectForKey:@"LocalFrame"]];
	else			[self setLocalFrame:[[decoder decodeObjectForKey:@"ORConnector Frame"] rectValue]];
    [self setGuardian:[decoder decodeObjectForKey:@"ORConnector Parent"]];
    [[guardian undoManager] disableUndoRegistration];
    
    [self setOnColor:           [decoder decodeObjectForKey:@"ORConnectorOnColor"]];
    [self setOffColor:          [decoder decodeObjectForKey:@"ORConnectorOffColor"]];
    [self setObjectLink:        [decoder decodeObjectForKey:@"ORConnector ObjectLink"]];
    [self setConnection:        [decoder decodeObjectForKey:@"ORConnector Connection"]];
    [self setConnectorImageType:[decoder decodeIntForKey:   @"ORConnectorImageType"]];
    [self setConnectorType:     [decoder decodeIntForKey:   @"ORConnector Type"]];
    [self setIoType:            (uint32_t)[decoder decodeIntegerForKey:   @"ORConnector IO Type"]];
    [self setIdentifer:         [decoder decodeIntForKey:   @"ORConnectorID"]];
    [self setRestrictedList:    [decoder decodeObjectForKey:@"ORConnectorRestrictedList"]];
    [self setHidden:            [decoder decodeBoolForKey:  @"Hidden"]];
    [self setSameGuardianIsOK:  [decoder decodeBoolForKey:  @"sameGuardianIsOK"]];
    if(!onColor)                [self setOnColor:[NSColor greenColor]];
    if(!offColor)               [self setOffColor:[NSColor redColor]];
    [connector setConnection:self];
    [self loadImages];
    [self loadDefaults];
    [self registerNotificationObservers];
    
    [[guardian undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
	[encoder encodeInteger:1                    forKey:@"newVersion"];
    [encoder encodeObject:onColor               forKey:@"ORConnectorOnColor"];
    [encoder encodeObject:offColor              forKey:@"ORConnectorOffColor"];
    [encoder encodeRect:[self localFrame]       forKey:@"LocalFrame"];
    [encoder encodeConditionalObject:guardian   forKey:@"ORConnector Parent"];
    [encoder encodeConditionalObject:objectLink forKey:@"ORConnector ObjectLink"];
    [encoder encodeConditionalObject:connector  forKey:@"ORConnector Connection"];
    [encoder encodeInt:connectorImageType       forKey:@"ORConnectorImageType"];
    [encoder encodeInteger:connectorType            forKey:@"ORConnector Type"];
    [encoder encodeInt:ioType                   forKey:@"ORConnector IO Type"];
    [encoder encodeInt:identifer                forKey:@"ORConnectorID"];
    [encoder encodeObject:restrictedList        forKey:@"ORConnectorRestrictedList"];
    [encoder encodeBool:hidden                  forKey:@"Hidden"];
    [encoder encodeBool:sameGuardianIsOK        forKey:@"sameGuardianIsOK"];
}


@end
