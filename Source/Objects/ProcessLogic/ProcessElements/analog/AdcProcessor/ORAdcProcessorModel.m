//
//  ORAdcProcessorModel.m
//  Orca
//
//  Created by Mark Howe on 04/05/12.
//  Copyright 20012 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina  sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORAdcProcessorModel.h"
#import "ORProcessInConnector.h"
#import "ORProcessOutConnector.h"
#import "ORProcessModel.h"
#import "ORProcessThread.h"
#import "ORAdcProcessing.h"

@interface ORAdcProcessorModel (private)
- (NSImage*) composeIcon;
@end

@implementation ORAdcProcessorModel

- (void) dealloc
{
	[super dealloc];
}

- (void) setUpImage
{
	[self setImage:[self composeIcon]];
}

#pragma mark ***Accessors

- (void) makeConnectors
{
 	ORProcessInConnector* inConnector;      
	inConnector = [[ORProcessInConnector alloc] initAt:NSMakePoint(0,[self frame].size.height/2 - kConnectorSize/2+5) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:inConnector forKey:@"Input"];
    [ inConnector setConnectorType: 'LP1 ' ];
    [ inConnector addRestrictedConnectionType: 'LP2 ' ]; //can only connect to processor outputs
    [inConnector release];
	
  	ORProcessOutConnector* aConnector;      
	aConnector = [[ORProcessOutConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,[self frame].size.height-kConnectorSize) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:@"ValueHigh"];
    [ aConnector setConnectorType: 'LP2 ' ];
    [ aConnector addRestrictedConnectionType: 'LP1 ' ]; //can only connect to processor inputs
    [aConnector release];
	
    aConnector = [[ORProcessOutConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,[self frame].size.height/2 - kConnectorSize/2+5) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:@"ValueOK"];
    [ aConnector setConnectorType: 'LP2 ' ];
    [ aConnector addRestrictedConnectionType: 'LP1 ' ]; //can only connect to processor inputs
    [aConnector release];
	
    aConnector = [[ORProcessOutConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,10) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:@"ValueLow"];
    [ aConnector setConnectorType: 'LP2 ' ];
    [ aConnector addRestrictedConnectionType: 'LP1 ' ]; //can only connect to processor inputs
    [aConnector release];
	
}

- (void) setUpNubs
{
	ORConnector* aConnector;
    if(!lowLimitNub)lowLimitNub = [[ORAdcProcessorLowLimitNub alloc] init];
    [lowLimitNub setGuardian:self];
    aConnector = [[self connectors] objectForKey: @"ValueLow"];
    [aConnector setObjectLink:lowLimitNub];
	
	
    if(!highLimitNub)highLimitNub = [[ORAdcProcessorHighLimitNub alloc] init];
    [highLimitNub setGuardian:self];
    aConnector = [[self connectors] objectForKey: @"ValueHigh"];
    [aConnector setObjectLink:highLimitNub];
}

- (NSString*) elementName
{
	return @"ADC Processor";
}

- (NSArray*) validObjects
{
    return [[self document] collectObjectsConformingTo:@protocol(ORAdcProcessor)];
}

- (void) makeMainController
{
    [self linkToController:@"ORAdcProcessorController"];
}

- (void) viewSource
{
	[[self hwObject] showMainInterface];
}

- (void) processIsStarting
{
    [super processIsStarting];
	id obj = [self objectConnectedTo:@"Input"];
	[obj processIsStarting];
}

- (void) processIsStopping
{
    [super processIsStopping];
	id obj = [self objectConnectedTo:@"Input"];
	[obj processIsStopping];
}

//--------------------------------
//runs in the process logic thread
- (id) eval
{
	if(!alreadyEvaluated){
		alreadyEvaluated = YES;
		if(hwObject!=nil){
			id obj = [self objectConnectedTo:@"Input"];
			ORProcessResult* theResult = [obj eval];
			float theValue = [theResult analogValue];

			BOOL tooLow;
			BOOL tooHigh;
			hwValue = [hwObject setProcessAdc:bit value:theValue isLow:&tooLow isHigh:&tooHigh];
			valueTooLow  = tooLow;
			valueTooHigh = tooHigh;
		}
	}
	return [ORProcessResult processState:(!valueTooLow && !valueTooHigh) value:hwValue];
}

//--------------------------------
- (NSString*) iconValue 
{ 
    if(hwName)	{
		NSString* theFormat = @"%.1f";
		if([displayFormat length] != 0)									theFormat = displayFormat;
		if([theFormat rangeOfString:@"%@"].location !=NSNotFound)		theFormat = @"%.1f";
		else if([theFormat rangeOfString:@"%d"].location !=NSNotFound)	theFormat = @"%.0f";
		return [NSString stringWithFormat:theFormat,[self hwValue]];
	}
	else return @"";
}

- (NSString*) report
{	
	return [NSString stringWithFormat:@"%@: %@ ", [self iconLabel],[self iconValue]];
}

- (id) description
{
	NSString* s = [self iconLabel];
	return [s stringByAppendingFormat:@" Value: %@ ",[self iconValue]];
}

- (double) hwValue
{
	return hwValue;
}
- (BOOL) valueTooLow
{
	return valueTooLow;
}

- (BOOL) valueTooHigh
{
	return valueTooHigh;
}

- (id) hwObject
{
	return hwObject;
}
 
- (void) setHwObject:(id) anObject
{
	[[[self undoManager] prepareWithInvocationTarget:self] setHwObject:hwObject];
	
	hwObject = anObject;
	
	[self postStateChange];
	
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:ORProcessHWAccessorHwObjectChangedNotification
	 object:self];
	
}
 
- (int) bit
{
	return bit;
}

- (void) setBit:(int)aBit
{
	[[[self undoManager] prepareWithInvocationTarget:self] setBit:bit];
	
	bit = aBit;
	
	[self postStateChange];
	
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:ORProcessHWAccessorBitChangedNotification
	 object:self];
}
			 
- (NSString*) iconLabel
{
	if(hwName)	{
		if(labelType ==2) return [self customLabel];
		else              return [NSString stringWithFormat:@"%@,%d",hwName,bit];
	}
	else		return @""; 
}

- (NSDictionary*) valueDictionary
{
    BOOL isValid = YES;
    if([hwObject respondsToSelector:@selector(dataForChannelValid:)]){
        isValid = [hwObject dataForChannelValid:[self bit]];
    }
    if(isValid)	return [NSDictionary dictionaryWithObject:[NSNumber numberWithDouble:[self hwValue]] forKey:[self iconLabel]];

    else return nil;

    
}
@end

@implementation ORAdcProcessorModel (private)

- (NSImage*) composeIcon
{
	NSImage* anImage = [NSImage imageNamed:@"adcProcessor"];
	
	NSSize theIconSize = [anImage size];
    NSImage* finalImage = [[NSImage alloc] initWithSize:theIconSize];
    [finalImage lockFocus];
    [anImage drawAtPoint:NSZeroPoint fromRect:[anImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
	
	NSAttributedString* idLabel   = [self idLabelWithSize:9 color:[NSColor blackColor]];
	NSAttributedString* iconLabel = [self iconLabelWithSize:9 color:[NSColor blackColor]];
		
	if(iconLabel){
		NSSize textSize = [iconLabel size];
		float x = theIconSize.width/2 - textSize.width/2;
		[iconLabel drawInRect:NSMakeRect(x,0,textSize.width,textSize.height)];
	}
	
	if(idLabel){
		NSSize textSize = [idLabel size];
		[idLabel drawInRect:NSMakeRect(theIconSize.width-textSize.width-10,theIconSize.height-textSize.height,textSize.width,textSize.height)];
	}
	
	[finalImage unlockFocus];
	return [finalImage autorelease];
}
@end

//the 'Low' nub
@implementation ORAdcProcessorLowLimitNub
- (id) eval
{
	[guardian eval];
	BOOL aValue = [guardian valueTooLow];
	return [ORProcessResult processState:aValue value:aValue];
}

- (int) evaluatedState
{
	return [guardian valueTooLow];
}

@end

//the 'High' nub
@implementation ORAdcProcessorHighLimitNub
- (id) eval
{
	[guardian eval];
	BOOL aValue = [guardian valueTooHigh];
	return [ORProcessResult processState:aValue value:aValue];
	
}
- (int) evaluatedState
{
	return [guardian valueTooHigh];
}

@end


