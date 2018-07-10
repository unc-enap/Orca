//
//  ORBitProcessorModel.m
//  Orca
//
//  Created by Mark Howe on Mon April 9.
//  Copyright (c) 2012 University of Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Carolina  sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Carolina reserve all rights in the program. Neither the authors,
//University of Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


#pragma mark •••Imported Files
#import "ORBitProcessorModel.h"
#import "ORProcessInConnector.h"
#import "ORProcessOutConnector.h"
#import "ORBitProcessing.h"

@interface ORBitProcessorModel (private)
- (NSImage*) composeIcon;
@end

@implementation ORBitProcessorModel

#pragma mark •••Initialization
- (void) makeMainController
{
    [self linkToController:@"ORBitProcessorController"];
}

- (NSString*) elementName
{
	return @"Bit Processor";
}
- (NSArray*) validObjects
{
    return [[self document] collectObjectsConformingTo:@protocol(ORBitProcessor)];
}

- (void) setUpImage
{
	[self setImage:[self composeIcon]];
}

- (void) makeConnectors
{
	ORProcessInConnector* inConnector = [[ORProcessInConnector alloc] initAt:NSMakePoint(0,[self frame].size.height/2 - kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:inConnector forKey:@"Input"];
    [ inConnector setConnectorType: 'LP1 ' ];
    [ inConnector addRestrictedConnectionType: 'LP2 ' ]; //can only connect to processor outputs
    [inConnector release];
 	
    ORProcessOutConnector* outConnector = [[ORProcessOutConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,[self frame].size.height/2 - kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:outConnector forKey:@"Output"];
    [ outConnector setConnectorType: 'LP2 ' ];
    [ outConnector addRestrictedConnectionType: 'LP1 ' ]; //can only connect to processor inputs
    [outConnector release];
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
- (NSString*) report
{	
	return [NSString stringWithFormat:@"%@: %@ ", [self iconLabel],[self iconValue]];
}

- (id) description
{
	NSString* s = [self iconLabel];
	return [s stringByAppendingFormat:@" Value: %@ ",[self iconValue]];
}

- (BOOL) hwValue
{
	return hwValue;
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

//--------------------------------
//runs in the process logic thread
- (id) eval
{
	if(!alreadyEvaluated){
		alreadyEvaluated = YES;
		if(hwObject!=nil){
			id obj = [self objectConnectedTo:@"Input"];
			ORProcessResult* theResult = [obj eval];			
			hwValue = [hwObject setProcessBit:bit value:[theResult boolValue]];
		}
	}
	return [ORProcessResult processState:hwValue value:(double)hwValue];
}

- (NSString*) iconLabel
{
	if(hwName)	{
		if(labelType ==2) return [self customLabel];
		else              return [NSString stringWithFormat:@"%@,%d",hwName,bit];
	}
	else		return @""; 
}

@end

@implementation ORBitProcessorModel (private)
- (NSImage*) composeIcon
{
	NSImage* anImage = [NSImage imageNamed:@"BitProcessor"];
	
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
