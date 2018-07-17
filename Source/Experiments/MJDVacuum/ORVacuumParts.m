//
//  ORVacuumParts.m
//  Orca
//
//  Created by Mark Howe on Tues Mar 27, 2012.
//  Copyright © 2012 CENPA, University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORVacuumParts.h"
#import "ORAlarm.h"

NSString* ORVacuumPartChanged      = @"ORVacuumPartChanged";
NSString* ORVacuumConstraintChanged = @"ORVacuumConstraintChanged";
//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@implementation ORVacuumPart
@synthesize dataSource,partTag,regionTag,visited;
- (id) initWithDelegate:(id)aDelegate partTag:(int)aTag regionTag:(int)aRegionTag
{
	self = [super init];
	self.partTag   = aTag;
	self.regionTag = aRegionTag;
	if([aDelegate respondsToSelector:@selector(addPart:)] && [aDelegate respondsToSelector:@selector(colorRegions)]){
		self.dataSource = aDelegate;
		self.visited = NO;
		[aDelegate addPart:self];
	}
	return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (void) normalize { /*do nothing subclasses must override*/ }
- (void) draw { }


@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@implementation ORVacuumPipe
@synthesize startPt,endPt,regionColor,rgbString;
- (id) initWithDelegate:(id)aDelegate regionTag:(int)aTag startPt:(NSPoint)aStartPt endPt:(NSPoint)anEndPt
{
	self = [super initWithDelegate:aDelegate partTag:aTag regionTag:aTag];
	self.startPt		 = aStartPt;
	self.endPt			 = anEndPt;
	self.rgbString       = @"eeeeee";
	self.regionColor = [NSColor lightGrayColor]; //default
	[self normalize];
	return self;
}

- (void) dealloc
{
	[regionColor release];
    [rgbString release];
    [super dealloc];
}

- (void) setRegionColor:(NSColor*)aColor
{
	if(![aColor isEqual: regionColor]){
		[aColor retain];
		[regionColor release];
		regionColor = aColor;
        
        //also store as rbg string for couchdb records
        CGFloat red   = 0;
        CGFloat green = 0;
        CGFloat blue  = 0;
        CGFloat alpha = 0;
        NSColor* convertedColor = [aColor colorUsingColorSpaceName:NSDeviceRGBColorSpace];
        [convertedColor getRed:&red green:&green blue:&blue alpha:&alpha];
        self.rgbString = [NSString stringWithFormat:@"#%02x%02x%02x",(int)(red*255),(int)(green*255),(int)(blue*255)];

        
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORVacuumPartChanged object:dataSource];
	}
	
}

- (void) draw 
{ 
	if([dataSource showGrid]){
		NSAttributedString* s = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d",partTag]
																 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																			 [NSColor blackColor],NSForegroundColorAttributeName,
																			 [NSFont fontWithName:@"Geneva" size:9],NSFontAttributeName,
																			 nil]] autorelease]; 
		NSSize size = [s size]; 
		float x_pos = (endPt.x - startPt.x)/2. - size.width/2.;
		float y_pos = (endPt.y - startPt.y)/2. - size.height/2.;
		
		[s drawAtPoint:NSMakePoint(startPt.x + x_pos, startPt.y + y_pos)];
	}
 
}

@end


//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@implementation ORVacuumHPipe
- (void) normalize 
{ 
	NSPoint p1  = NSMakePoint(MIN(startPt.x,endPt.x),startPt.y);
	NSPoint p2  = NSMakePoint(MAX(startPt.x,endPt.x),startPt.y);
	startPt = p1;
	endPt   = p2;
}

- (void) draw 
{
	[PIPECOLOR set];
	float length = endPt.x - startPt.x;
	[NSBezierPath fillRect:NSMakeRect(startPt.x,startPt.y-kPipeRadius,length,kPipeDiameter)];
	[regionColor set];
	[NSBezierPath fillRect:NSMakeRect(startPt.x-kPipeThickness,startPt.y-kPipeRadius+kPipeThickness,length+2*kPipeThickness,kPipeDiameter-2*kPipeThickness)];
	[[NSColor blackColor] set];
	[super draw];
}
@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@implementation ORVacuumBigHPipe
- (void) draw 
{
	[PIPECOLOR set];
	float length = endPt.x - startPt.x;
	[NSBezierPath fillRect:NSMakeRect(startPt.x,startPt.y-3*kPipeRadius,length,3*kPipeDiameter)];
	[regionColor set];
	[NSBezierPath fillRect:NSMakeRect(startPt.x-kPipeThickness,startPt.y-3*kPipeRadius+kPipeThickness,length+2*kPipeThickness,3*kPipeDiameter-2*kPipeThickness)];
	[[NSColor blackColor] set];
	[super draw];
}
@end
//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@implementation ORVacuumVPipe
- (void) normalize 
{ 
	NSPoint p1  = NSMakePoint(startPt.x,MIN(startPt.y,endPt.y));
	NSPoint p2  = NSMakePoint(startPt.x,MAX(startPt.y,endPt.y));
	startPt = p1;
	endPt   = p2;
}

- (void) draw 
{
	[PIPECOLOR set];
	float length = endPt.y - startPt.y;
	[NSBezierPath fillRect:NSMakeRect(startPt.x-kPipeRadius,startPt.y,kPipeDiameter,length)];
	[regionColor set];
	[NSBezierPath fillRect:NSMakeRect(startPt.x-kPipeRadius+kPipeThickness,startPt.y-kPipeThickness,kPipeDiameter-2*kPipeThickness,length+2*kPipeThickness)];
	[[NSColor blackColor] set];
	[super draw];
}
@end


//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@implementation ORVacuumCPipe
@synthesize location;
- (id) initWithDelegate:(id)aDelegate regionTag:(int)aTag at:(NSPoint)aPoint
{
	self = [super initWithDelegate:aDelegate partTag:aTag regionTag:aTag];
	self.location = aPoint;
	self.regionColor = [NSColor lightGrayColor]; //default
	return self;			
}

- (void) draw 
{
	[PIPECOLOR set];
	[NSBezierPath fillRect:NSMakeRect(location.x-kPipeRadius,location.y-kPipeRadius,kPipeDiameter,kPipeDiameter)];
	[regionColor set];
	[NSBezierPath fillRect:NSMakeRect(location.x-kPipeRadius+kPipeThickness,location.y-kPipeRadius+kPipeThickness,kPipeDiameter-2*kPipeThickness,kPipeDiameter-2*kPipeThickness)];
	[[NSColor blackColor] set];
	[super draw];
}
@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@implementation ORVacuumBox
@synthesize bounds;
- (id) initWithDelegate:(id)aDelegate regionTag:(int)aTag bounds:(NSRect)aRect
{
	self = [super initWithDelegate:aDelegate partTag:aTag regionTag:aTag];
	self.bounds = aRect;
	self.regionColor = [NSColor lightGrayColor]; //default
	return self;			
}

- (void) draw 
{
	[PIPECOLOR set];
	[NSBezierPath fillRect:bounds];
	[regionColor set];
	[NSBezierPath fillRect:NSInsetRect(bounds, kPipeThickness, kPipeThickness)];
	[[NSColor blackColor] set];
	[super draw];
}
@end


//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@implementation ORVacuumGateValve
@synthesize state,location,connectingRegion1,connectingRegion2,controlPreference,label,controlType,valveAlarm;
@synthesize controlObj,controlChannel,vetoed,commandedState;

- (id) initWithDelegate:(id)aDelegate partTag:(int)aTag label:(NSString*)aLabel controlType:(int)aControlType at:(NSPoint)aPoint connectingRegion1:(int)aRegion1 connectingRegion2:(int)aRegion2
{
	self = [super initWithDelegate:aDelegate partTag:aTag regionTag:-1];
	self.location			= aPoint;
	self.connectingRegion1	= aRegion1;
	self.connectingRegion2	= aRegion2;
	self.label				= aLabel;
	self.controlType		= aControlType;
	self.state				= kGVChanging;
	logState                = NO;
	return self;
}
		
- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	self.label		= nil;
	[valveAlarm clearAlarm];
	self.valveAlarm = nil;
	[constraints release];
    [controlObj release];
	[super dealloc];
}

- (NSDictionary*) constraints
{
	return constraints;
}

- (void) addConstraintName:(NSString*)aName reason:(NSString*)aReason
{
	if(!constraints)constraints = [[NSMutableDictionary dictionary] retain];
	[constraints setObject:aReason forKey:aName];
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORVacuumConstraintChanged object:dataSource];
}

- (void) removeConstraintName:(NSString*)aName
{
	[constraints removeObjectForKey:aName];
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORVacuumConstraintChanged object:dataSource];
}

- (void) setVetoed:(BOOL)aState
{
	vetoed = aState;
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORVacuumPartChanged object:dataSource];
}

- (void) setCommandedState:(int)aState
{
	commandedState = aState;
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	[self checkState];
}

- (void) checkState
{
	if(commandedState == kGVNoCommandedState){
		[self performSelectorOnMainThread:@selector(clearAlarmState) withObject:nil waitUntilDone:NO];
	}
	else {
		if(commandedState == kGVCommandOpen && state == kGVOpen){
			[self performSelectorOnMainThread:@selector(clearAlarmState) withObject:nil waitUntilDone:NO];
		}
		else if(commandedState == kGVCommandClosed && state == kGVClosed){
			[self performSelectorOnMainThread:@selector(clearAlarmState) withObject:nil waitUntilDone:NO];
		}
		else {
			[self performSelectorOnMainThread:@selector(startStuckValveTimer) withObject:nil waitUntilDone:NO];
		}
	}
}

- (void) setState:(int)aState
{
	if(aState != state){
        
        if(logState)NSLog(@"Value %@ state is now %@\n",[self label],[self stateName:aState]);
        
		state = aState;
		
		[dataSource colorRegions];
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORVacuumPartChanged object:dataSource];
        [self performSelectorOnMainThread:@selector(cancelStuckValveTimer) withObject:nil waitUntilDone:YES];
		
		logState = YES;
	}
}

- (NSString*) stateName:(int)aValue
{
    if([self controlType] == k1BitReadBack){
        if(aValue==1)return @"Closed";
        else		  return @"Open";
    }
    else {
        if(aValue==3)		return @"Changing";
        else if(aValue==1)	return @"Open";
        else if(aValue==2)	return @"Closed";
        else                return @"Impossible";
    }
}

- (void) cancelStuckValveTimer
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
    [self checkState];
}

- (void) startStuckValveTimer
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	[self performSelector:@selector(timeout) withObject:nil afterDelay:20];
}

- (void) clearAlarmState
{
	[valveAlarm clearAlarm];
	self.valveAlarm = nil;
}

- (void) timeout
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	if(!valveAlarm){
		NSString* s = [NSString stringWithFormat:@"%@ Valve Alarm",self.label];
		ORAlarm* anAlarm = [[ORAlarm alloc] initWithName:s severity:kHardwareAlarm];
		self.valveAlarm = anAlarm;
		[anAlarm release];
		[valveAlarm setSticky:NO];
		[valveAlarm setHelpString:@"This valve is either stuck or the command state does not match the actual state."];
	}
	[valveAlarm postAlarm];
}

- (BOOL) isClosed
{
	return state == kGVClosed;
}

- (BOOL) isOpen
{
	//assume worst case for the other states 
	return state != kGVClosed;
}
- (NSUInteger) constraintCount
{
	return [constraints count];
}

@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@implementation ORVacuumVGateValve

- (void) draw 
{
	if(controlType == kSpareValve)return;

	[PIPECOLOR set];
	[NSBezierPath fillRect:NSMakeRect(location.x-kGateValveHousingWidth/2.,location.y+kPipeRadius,kGateValveHousingWidth,2*kPipeThickness)]; //above pipe part
	[NSBezierPath fillRect:NSMakeRect(location.x-kGateValveHousingWidth/2.,location.y-kPipeRadius-2*kPipeThickness,kGateValveHousingWidth,2*kPipeThickness)]; //below pipe part
	
	if(controlPreference!=kControlNone && (controlType == k2BitReadBack || controlType == k1BitReadBack)){
		if([constraints count]!=0){
			NSImage* lockImage = [[NSImage imageNamed:@"smallLock"] copy];
			NSSize lockSize = [lockImage size];
			float dx = lockSize.width/2.;
			float dy = lockSize.height+5;
			NSPoint lockPoint;
			if(controlPreference == kControlAbove)lockPoint = NSMakePoint(location.x-dx,location.y - kPipeRadius-kPipeThickness - dy);
			else								  lockPoint = NSMakePoint(location.x-dx,location.y + kPipeRadius+kPipeThickness+5);
            [lockImage drawAtPoint:lockPoint fromRect:[lockImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
            if([dataSource disableConstraints]){
                [[NSColor redColor] set];
                [NSBezierPath setDefaultLineWidth:2];
                [NSBezierPath strokeLineFromPoint:NSMakePoint(lockPoint.x,lockPoint.y) toPoint:NSMakePoint(lockPoint.x+lockSize.width,lockPoint.y+lockSize.height)];
                [NSBezierPath strokeLineFromPoint:NSMakePoint(lockPoint.x,lockPoint.y+lockSize.height) toPoint:NSMakePoint(lockPoint.x+lockSize.width,lockPoint.y)];
            }
            [lockImage release];
		}
	}
	
	int theState;
	if(controlType == kManualOnlyShowClosed)	  theState   = kGVClosed;
	else if(controlType == kManualOnlyShowChanging) theState = kGVChanging;
	else {
		if(self.vetoed)[[NSColor redColor] set];
		theState = state;
	}
	
	[NSBezierPath fillRect:NSMakeRect(location.x-kPipeThickness,location.y-kPipeRadius-kPipeThickness,2*kPipeThickness,2*kPipeThickness)];
	[NSBezierPath fillRect:NSMakeRect(location.x-kPipeThickness,location.y+kPipeRadius-kPipeThickness,2*kPipeThickness,2*kPipeThickness)];
	
	switch(theState){
		case kGVOpen: break; //open
		case kGVClosed: //closed
			[NSBezierPath setDefaultLineWidth:2*kPipeThickness];
			[NSBezierPath strokeLineFromPoint:NSMakePoint(location.x,location.y-kPipeRadius) toPoint:NSMakePoint(location.x,location.y+kPipeRadius)];
			[NSBezierPath setDefaultLineWidth:0];
			break;
		default:
			{
				NSBezierPath* aPath = [NSBezierPath bezierPath];
				const CGFloat pattern[2] = {1.0,1.0};
				[aPath setLineWidth:2*kPipeThickness];
				[aPath setLineDash:pattern count:2 phase:0];
				[aPath moveToPoint:NSMakePoint(location.x,location.y-kPipeRadius)];
				[aPath lineToPoint:NSMakePoint(location.x,location.y+kPipeRadius)];
				[aPath stroke];
			}
			break;
	}
	if([dataSource showGrid]){
		NSAttributedString* s = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d",partTag]
																 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																			 [NSColor blackColor],NSForegroundColorAttributeName,
																			 [NSFont fontWithName:@"Geneva" size:9],NSFontAttributeName,
																			 nil]] autorelease]; 
		float x_pos = kGateValveHousingWidth/2.;
		float y_pos = kPipeRadius + 2*kPipeThickness;
		
		[s drawAtPoint:NSMakePoint(location.x + x_pos+2, location.y + y_pos - 3)];
	}
	[[NSColor blackColor] set];
}

@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@implementation ORVacuumHGateValve
- (void) draw 
{
	if(controlType == kSpareValve)return;
	[PIPECOLOR set];
	[NSBezierPath fillRect:NSMakeRect(location.x-kPipeRadius - 2*kPipeThickness,location.y-kGateValveHousingWidth/2.,2*kPipeThickness,kGateValveHousingWidth)]; //left of pipe part
	[NSBezierPath fillRect:NSMakeRect(location.x+kPipeRadius,location.y-kGateValveHousingWidth/2.,2*kPipeThickness,kGateValveHousingWidth)]; //below pipe part

	if(controlPreference!=kControlNone && (controlType == k2BitReadBack || controlType == k1BitReadBack)){
		if([constraints count]!=0){
			NSImage* lockImage = [[NSImage imageNamed:@"smallLock"] copy];
			NSSize lockSize = [lockImage size];
			float dx = lockSize.width+5;
			float dy = lockSize.height/2.;
			NSPoint lockPoint;
			if(controlPreference == kControlRight)lockPoint  = NSMakePoint(location.x-kPipeRadius-kPipeThickness-dx,location.y - dy);
			else								  lockPoint = NSMakePoint(location.x+kPipeRadius+kPipeThickness+5,  location.y - dy);
            [lockImage drawAtPoint:lockPoint fromRect:[lockImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
            if([dataSource disableConstraints]){
                [[NSColor redColor] set];
                [NSBezierPath setDefaultLineWidth:2];
                [NSBezierPath strokeLineFromPoint:NSMakePoint(lockPoint.x,lockPoint.y) toPoint:NSMakePoint(lockPoint.x+lockSize.width,lockPoint.y+lockSize.height)];
                [NSBezierPath strokeLineFromPoint:NSMakePoint(lockPoint.x,lockPoint.y+lockSize.height) toPoint:NSMakePoint(lockPoint.x+lockSize.width,lockPoint.y)];
            }
            [lockImage release];
		}
	}
	
	
	int theState;
	[[NSColor blackColor] set];	
	if(controlType == kManualOnlyShowClosed)	  theState = kGVClosed;
	else if(controlType == kManualOnlyShowChanging) theState = kGVChanging;
	else {
		if(self.vetoed)[[NSColor redColor] set];
		theState = state;
	}
	
	[NSBezierPath fillRect:NSMakeRect(location.x-kPipeRadius-kPipeThickness,location.y-kPipeThickness,2*kPipeThickness,2*kPipeThickness)];
	[NSBezierPath fillRect:NSMakeRect(location.x+kPipeRadius-kPipeThickness,location.y-kPipeThickness,2*kPipeThickness,2*kPipeThickness)];

	switch(theState){
		case kGVOpen: break; //open
		case kGVClosed: //closed
			[NSBezierPath setDefaultLineWidth:2*kPipeThickness];
			[NSBezierPath strokeLineFromPoint:NSMakePoint(location.x-kPipeRadius,location.y) toPoint:NSMakePoint(location.x+kPipeRadius,location.y)];
			[NSBezierPath setDefaultLineWidth:0];
			break;
		default:
		{
			NSBezierPath* aPath = [NSBezierPath bezierPath];
			const CGFloat pattern[2] = {1.0,1.0};
			[aPath setLineWidth:2*kPipeThickness];
			[aPath setLineDash:pattern count:2 phase:0];
			[aPath moveToPoint:NSMakePoint(location.x-kPipeRadius,location.y)];
			[aPath lineToPoint:NSMakePoint(location.x+kPipeRadius,location.y)];
			[aPath stroke];
		}
			break;
	}
	if([dataSource showGrid]){
		NSAttributedString* s = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d",partTag]
																 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																			 [NSColor blackColor],NSForegroundColorAttributeName,
																			 [NSFont fontWithName:@"Geneva" size:9],NSFontAttributeName,
																			 nil]] autorelease]; 
		float x_pos = kPipeRadius + 2*kPipeThickness;
		float y_pos = kGateValveHousingWidth/2.;
		
		[s drawAtPoint:NSMakePoint(location.x + x_pos, location.y + y_pos)];
	}
	[[NSColor blackColor] set];
}
@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@implementation ORVacuumStaticLabel
@synthesize label,bounds,gradient,controlColor;
- (id) initWithDelegate:(id)aDelegate regionTag:(int)aRegionTag label:(NSString*)aLabel bounds:(NSRect)aRect
{
	self = [super initWithDelegate:aDelegate partTag:aRegionTag regionTag:aRegionTag];
	self.bounds       = aRect;
	self.label        = aLabel;
	self.controlColor = [NSColor colorWithCalibratedRed:.75 green:.75 blue:.75 alpha:1];
	return self;
}

- (void) dealloc
{
	self.label			= nil;
	self.gradient		= nil;
	self.controlColor	= nil;
	[super dealloc];
}


- (void) setControlColor:(NSColor*)aColor
{
	self.gradient		= nil;
	[aColor retain];
	[controlColor release];
	controlColor = aColor;

	CGFloat red=0,green=0,blue=0,alpha=0;
		
	[controlColor getRed:&red green:&green blue:&blue alpha:&alpha];
	red = MIN(1.0,red*1.5);
	green = MIN(1.0,green*1.5);
	blue = MIN(1.0,blue*1.5);
	NSColor* endingColor = [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:1];
	self.gradient = [[[NSGradient alloc] initWithStartingColor:controlColor endingColor:endingColor]autorelease];
	
}

- (void) draw 
{
	[[NSColor blackColor] set];
	[NSBezierPath strokeRect:bounds];
	[gradient drawInRect:bounds angle:90.];

	
	if([label length]){
		NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSColor blackColor],NSForegroundColorAttributeName,
										[NSFont fontWithName:@"Geneva" size:10],NSFontAttributeName,
										nil];
		[[NSColor blackColor] set];
		NSAttributedString* s = [[[NSAttributedString alloc] initWithString:label attributes:attributes] autorelease]; 
		NSSize size = [s size];   
		float x_pos = (bounds.size.width - size.width) / 2; 
		float y_pos;
		y_pos = (bounds.size.height - size.height) /2;
		[s drawAtPoint:NSMakePoint(bounds.origin.x + x_pos, bounds.origin.y + y_pos)];
	}
}


@end
//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@implementation ORVacuumDynamicLabel
@synthesize channel,component,isValid,value;
- (id) initWithDelegate:(id)aDelegate regionTag:(int)aRegionTag component:(int)aComponent channel:(int)aChannel label:(NSString*)aLabel bounds:(NSRect)aRect
{
	self = [super initWithDelegate:aDelegate regionTag:aRegionTag label:aLabel bounds:aRect];
	self.controlColor = [NSColor colorWithCalibratedRed:.5 green:.75 blue:.5 alpha:1];
	self.component = aComponent;
	self.channel = aChannel;
	return self;
}
- (NSString*) displayString
{
	return @"?";
}
- (BOOL) valueHigherThan:(double)aValue
{
    if(!self.isValid) return YES; //assume worst case
    else return self.value > aValue;
}

- (void) draw 
{
	[[NSColor blackColor] set];
	[NSBezierPath strokeRect:bounds];
 	[gradient drawInRect:bounds angle:90.];
	
	if([label length]){
		
		NSAttributedString* s1 = [[[NSAttributedString alloc] initWithString:label
																  attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																			  [NSColor blackColor],NSForegroundColorAttributeName,
																			  [NSFont fontWithName:@"Geneva" size:10],NSFontAttributeName,
																			  nil]] autorelease]; 
		NSSize size1 = [s1 size];   
		float x_pos = (bounds.size.width - size1.width) / 2; 
		float y_pos = bounds.size.height/2;
		[s1 drawAtPoint:NSMakePoint(bounds.origin.x + x_pos, bounds.origin.y + y_pos)];

		NSString* s = [self displayString];
		if([s length] == 0)s = @"?";
		NSAttributedString* s2 = [[[NSAttributedString alloc] initWithString:s
																  attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																			  [NSColor blackColor],NSForegroundColorAttributeName,
																			  [NSFont fontWithName:@"Geneva" size:10],NSFontAttributeName,
																			  nil]] autorelease]; 
		
		NSSize size2 = [s2 size];   
		x_pos = (bounds.size.width - size2.width) / 2; 
		y_pos = (bounds.size.height/2 - size2.height); 
		[s2 drawAtPoint:NSMakePoint(bounds.origin.x + x_pos, bounds.origin.y + y_pos)];
		
	}
	
	if([dataSource showGrid]){
		NSAttributedString* s = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d",partTag]
																 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																			 [NSColor blackColor],NSForegroundColorAttributeName,
																			 [NSFont fontWithName:@"Geneva" size:9],NSFontAttributeName,
																			 nil]] autorelease]; 
		float x_pos = bounds.origin.x;
		float y_pos = bounds.origin.y + bounds.size.height;
		
		[s drawAtPoint:NSMakePoint(x_pos, y_pos)];
	}
	
	[[NSColor blackColor] set];
}
@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@implementation ORVacuumValueLabel

- (void) setValue:(double)aValue
{
	if(fabs(aValue-value) > 1.0E-8){
		value = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORVacuumPartChanged object:dataSource];
	}
}

- (NSString*) displayString
{
	if(self.isValid) return [NSString stringWithFormat:@"%.2E",[self value]];
	else return @"?";
}

@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@implementation ORVacuumTempGroup

- (NSString*) displayTemp:(int)chan
{
    if(self.isValid)return [NSString stringWithFormat:@"%d: %.2f",chan,[self temp:chan]];
    else return @"?";
}

- (double) temp:(int)chan
{
    if(chan>=0 && chan<8)return temp[chan];
    else return 0;
}

- (void) setTemp:(int)chan value:(double)aValue
{
    if(fabs(aValue-temp[chan]) > 0.1){
        temp[chan] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORVacuumPartChanged object:dataSource];
    }
}

- (void) draw
{
    [[NSColor blackColor] set];
    [NSBezierPath strokeRect:bounds];
    [gradient drawInRect:bounds angle:90.];
    
    if([label length]){
        
        NSAttributedString* s1 = [[[NSAttributedString alloc] initWithString:label
                                                                  attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                              [NSColor blackColor],NSForegroundColorAttributeName,
                                                                              [NSFont fontWithName:@"Geneva" size:10],NSFontAttributeName,
                                                                              nil]] autorelease];
        NSSize size1 = [s1 size];
        float x_pos = (bounds.size.width - size1.width)/2;
        float y_pos = bounds.size.height-size1.height;
        [s1 drawAtPoint:NSMakePoint(bounds.origin.x + x_pos, bounds.origin.y + y_pos)];
        
        
        int i;
        for(i=0;i<8;i++){
            NSString* s = [self displayTemp:i];
            if([s length] == 0)s = @"?";
            NSAttributedString* s2 = [[[NSAttributedString alloc] initWithString:s
                                                                      attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                  [NSColor blackColor],NSForegroundColorAttributeName,
                                                                                  [NSFont fontWithName:@"Geneva" size:10],NSFontAttributeName,
                                                                                  nil]] autorelease];
            
            NSSize size2 = [s2 size];
            y_pos = (bounds.size.height - size2.height);
            [s2 drawAtPoint:NSMakePoint(bounds.origin.x + x_pos, bounds.origin.y + y_pos-size2.height-(size2.height*i))];
        }
        
    }
    
    [[NSColor blackColor] set];
}

@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@implementation ORTemperatureValueLabel

- (void) setValue:(double)aValue
{
    if(fabs(aValue-value) > .1){
        value = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORVacuumPartChanged object:dataSource];
    }
}


- (NSString*) displayString
{
    if(self.isValid) return [NSString stringWithFormat:@"%.1f",[self value]];
    else return @"?";
}

@end


//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@implementation ORVacuumStatusLabel
@synthesize statusLabel;
- (void) dealloc
{
	[statusLabel release];
	[constraints release];
	[super dealloc];
}

- (NSString*) displayString
{
	if(self.isValid) return statusLabel;
	else return @"?";
}

- (void) setStatusLabel:(NSString*)aLabel
{
	if(![aLabel isEqualToString:statusLabel]){
		[statusLabel autorelease];
		statusLabel = [aLabel copy];
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORVacuumPartChanged object:dataSource];
	}
}
- (NSDictionary*) constraints
{
	return constraints;
}

- (void) addConstraintName:(NSString*)aName reason:(NSString*)aReason
{
	if(!constraints)constraints = [[NSMutableDictionary dictionary] retain];
	[constraints setObject:aReason forKey:aName];
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORVacuumConstraintChanged object:dataSource];
}

- (void) removeConstraintName:(NSString*)aName
{
	[constraints removeObjectForKey:aName];
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORVacuumConstraintChanged object:dataSource];
}
- (void) draw 
{
	[super draw];
	if([constraints count]!=0){
		NSImage* lockImage = [[NSImage imageNamed:@"smallLock"] copy];
		NSSize lockSize = [lockImage size];
		NSPoint lockPoint = NSMakePoint(bounds.origin.x + bounds.size.width - lockSize.width, bounds.origin.y + bounds.size.height + 5);
        [lockImage drawAtPoint:lockPoint fromRect:[lockImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
        if([dataSource disableConstraints]){
            [[NSColor redColor] set];
            [NSBezierPath setDefaultLineWidth:2];
            [NSBezierPath strokeLineFromPoint:NSMakePoint(lockPoint.x,lockPoint.y) toPoint:NSMakePoint(lockPoint.x+lockSize.width,lockPoint.y+lockSize.height)];
            [NSBezierPath strokeLineFromPoint:NSMakePoint(lockPoint.x,lockPoint.y+lockSize.height) toPoint:NSMakePoint(lockPoint.x+lockSize.width,lockPoint.y)];
        }
		[lockImage release];
	}
}
@end


//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@implementation ORVacuumLine
@synthesize startPt,endPt;
- (id) initWithDelegate:(id)aDelegate startPt:(NSPoint)aStartPt endPt:(NSPoint)anEndPt
{
	self = [super initWithDelegate:aDelegate partTag:-1 regionTag:-1];
	self.startPt	= aStartPt;
	self.endPt		= anEndPt;
	return self;
}

- (void) draw 
{
	[[NSColor blackColor] set];
	[NSBezierPath strokeLineFromPoint:startPt toPoint:endPt];
}	
@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@implementation ORGateValveControl
@synthesize location;
- (id) initWithDelegate:(id)aDelegate partTag:(int)aTag at:(NSPoint)aPoint; 
{
	self = [super initWithDelegate:aDelegate partTag:aTag regionTag:aTag];
	self.location = aPoint;
	return self;
}

@end
