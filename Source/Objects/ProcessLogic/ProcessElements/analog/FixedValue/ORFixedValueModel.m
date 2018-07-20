//
//  ORFixedValueModel.m
//  Orca
//
//  Created by Mark Howe on Jan 29 2013.
//  Copyright (c) 2013  University of North Carolina. All rights reserved.
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


#import "ORFixedValueModel.h"
#import "ORProcessOutConnector.h"

NSString* ORFixedValueFixedValueChanged = @"ORFixedValueFixedValueChanged";
NSString* ORFixedValueLock              = @"ORFixedValueLock";

@interface ORFixedValueModel (private)
- (NSImage*) composeIcon;
@end

@implementation ORFixedValueModel

- (void) dealloc
{
    [fixedValue release];
	[super dealloc];
}

#pragma mark ***Accessors
- (NSString*) fixedValue
{
    if([fixedValue length]==0)return @"0";
    else return fixedValue;
}
- (void) setFloatValue:(float)aValue
{
    [self setFixedValue:[NSString stringWithFormat:@"%f",aValue]];
}
- (void) setFixedValue:(NSString*)aFixedValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFixedValue:fixedValue];
    
    if([aFixedValue length]==0)aFixedValue = @"0";
    
    [fixedValue autorelease];
    fixedValue = [aFixedValue copy];    

    [self setUpImage];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORFixedValueFixedValueChanged object:self];
}

- (void) makeConnectors
{  
    ORProcessOutConnector* aConnector;      
    aConnector = [[ORProcessOutConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,[self frame].size.height/2-kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:@"FixedValueInputConnection"];
    [ aConnector setConnectorType: 'LP2 ' ];
    [ aConnector addRestrictedConnectionType: 'LP1 ' ]; //can only connect to processor inputs
    [aConnector release];
}

- (NSString*) elementName   { return @"Fixed Value"; }
- (void) makeMainController { [self linkToController:@"ORFixedValueController"]; }
- (void) setUpImage         { [self setImage:[self composeIcon]]; }
- (double) hwValue          { return [fixedValue doubleValue]; }
- (NSString*) iconValue     { return [self fixedValue]; }

//--------------------------------
//runs in the process logic thread
- (id) eval
{
	if(!alreadyEvaluated){
		alreadyEvaluated = YES;
        hwValue = [fixedValue doubleValue];
		[self setState: ((int)hwValue)==1];
		[self setEvaluatedState: ((int)hwValue)==1];
	}
	return [ORProcessResult processState:evaluatedState value:hwValue];
}
//--------------------------------
- (NSString*) report
{	
	NSString* s = @"";
	@synchronized(self){
        return [NSString stringWithFormat:@"FixedValue,%d: %@ ", [self uniqueIdNumber],[self iconValue]];
	}
	return s;
}

- (id) description
{
    return [NSString stringWithFormat:@"%@: %@ ", [self fullID],[self iconValue]];
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setFixedValue:	[decoder decodeObjectForKey:@"fixedValue"]];
    [[self undoManager] enableUndoRegistration];

    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:fixedValue		forKey:@"fixedValue"];
}
@end

@implementation ORFixedValueModel (private)

- (NSImage*) composeIcon
{
	NSImage* anImage = [NSImage imageNamed:@"fixedValue"];
	
	NSSize theIconSize = [anImage size];
    NSImage* finalImage = [[NSImage alloc] initWithSize:theIconSize];
    [finalImage lockFocus];
    [anImage drawAtPoint:NSZeroPoint fromRect:[anImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
    
	NSAttributedString* iconValue = [self iconValueWithSize:9 color:[NSColor blackColor]];
    NSSize textSize = [iconValue size];
    float x = (theIconSize.width-kConnectorSize)/2 - textSize.width/2;
    [iconValue drawInRect:NSMakeRect(x,[self frame].size.height/2-textSize.height/2,textSize.width,textSize.height)];
	
    
	[finalImage unlockFocus];
	return [finalImage autorelease];
}

@end


