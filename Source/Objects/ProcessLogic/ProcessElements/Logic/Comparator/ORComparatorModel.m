//-------------------------------------------------------------------------
//  ORComparatorModel.m
//
//  Created by Mark A. Howe on Thursday 05/12/2011.
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//
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
#pragma mark ***Imported Files
#import "ORComparatorModel.h"
#import "ORProcessOutConnector.h"
#import "ORProcessInConnector.h"
#import "ORProcessNub.h"
#import "ORComparatorModel.h"

NSString* ORComparatorRangeForEqualChanged = @"ORComparatorRangeForEqualChanged";

NSString* ORComparatorAGTBConnection = @"ORComparatorAGTBConnection";
NSString* ORComparatorAEQBConnection = @"ORComparatorAEQBConnection";
NSString* ORComparatorALTBConnection = @"ORComparatorALTBConnection";

@implementation ORComparatorModel

#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    return self;
}

-(void) dealloc
{
    [gtOutputNub release];
    [ltOutputNub release];
    [super dealloc];
}

- (NSString*) elementName
{
	return @"Comparator";
}

- (void) makeMainController
{
    [self linkToController:@"ORComparatorController"];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"Comparator"]];
}

-(void) makeConnectors
{
	ORProcessInConnector* inConnector = [[ORProcessInConnector alloc] initAt:NSMakePoint(0,2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:inConnector forKey:ORSimpleLogicIn1Connection];
    [ inConnector setConnectorType: 'LP1 ' ];
    [ inConnector addRestrictedConnectionType: 'LP2 ' ]; //can only connect to processor outputs
    [inConnector release];
	
    inConnector = [[ORProcessInConnector alloc] initAt:NSMakePoint(0,[self frame].size.height-kConnectorSize-2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:inConnector forKey:ORSimpleLogicIn2Connection];
    [ inConnector setConnectorType: 'LP1 ' ];
    [ inConnector addRestrictedConnectionType: 'LP2 ' ]; //can only connect to processor outputs
    [inConnector release];
	
    ORProcessOutConnector* outConnector = [[ORProcessOutConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize, [self frame].size.height-kConnectorSize-2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:outConnector forKey:ORComparatorAGTBConnection];
    [ outConnector setConnectorType: 'LP2 ' ];
    [ outConnector addRestrictedConnectionType: 'LP1 ' ]; //can only connect to processor inputs
    [outConnector release];

	outConnector = [[ORProcessOutConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize, [self frame].size.height/2 - kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:outConnector forKey:ORComparatorAEQBConnection];
    [ outConnector setConnectorType: 'LP2 ' ];
    [ outConnector addRestrictedConnectionType: 'LP1 ' ]; //can only connect to processor inputs
    [outConnector release];

	outConnector = [[ORProcessOutConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize, 2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:outConnector forKey:ORComparatorALTBConnection];
    [ outConnector setConnectorType: 'LP2 ' ];
    [ outConnector addRestrictedConnectionType: 'LP1 ' ]; //can only connect to processor inputs
    [outConnector release];
}

- (void) setUpNubs
{
    if(!gtOutputNub)gtOutputNub = [[ORComparatorGTNub alloc] init];
    [gtOutputNub setGuardian:self];
    ORConnector* aConnector = [[self connectors] objectForKey: ORComparatorAGTBConnection];
    [aConnector setObjectLink:gtOutputNub];
	
	if(!ltOutputNub)ltOutputNub = [[ORComparatorLTNub alloc] init];
    [ltOutputNub setGuardian:self];
    aConnector = [[self connectors] objectForKey: ORComparatorALTBConnection];
    [aConnector setObjectLink:ltOutputNub];
}

#pragma mark ***Accessors

- (float) rangeForEqual
{
    return rangeForEqual;
}

- (void) setRangeForEqual:(float)aRangeForEqual
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRangeForEqual:rangeForEqual];
    
    rangeForEqual = aRangeForEqual;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORComparatorRangeForEqualChanged object:self];
}

- (BOOL) abEqual
{
	return abEqual;
}

- (float) abDifference
{
	return abDifference;
}

- (id) eval
{
	if(!alreadyEvaluated){
		alreadyEvaluated = YES;
		float a  = [[self evalInput1] analogValue];
		float b  = [[self evalInput2] analogValue];
			
		abDifference = a-b;
		abEqual   = (fabs(abDifference) < (rangeForEqual+1E-8));
		
		[self setState: abEqual];
		[self setEvaluatedState: abEqual];
	}
	return [ORProcessResult processState:evaluatedState value:evaluatedState];
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setRangeForEqual:[decoder decodeFloatForKey:@"rangeForEqual"]];
    [[self undoManager] enableUndoRegistration];    

    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeFloat:rangeForEqual forKey:@"rangeForEqual"];
}

@end

@implementation ORComparatorLTNub
- (id) eval
{
	[guardian eval];
	BOOL abLT = NO;
	if(![(ORComparatorModel*)guardian abEqual]){
		if([(ORComparatorModel*)guardian abDifference]>0)abLT = YES;
	}
	return [ORProcessResult processState:abLT value:abLT];
}

- (int) evaluatedState
{
	BOOL abLT = NO;
	float diff = [(ORComparatorModel*)guardian abDifference];
	if(![(ORComparatorModel*)guardian abEqual]){
		if(diff>0)abLT = YES;
	}
	return abLT;
}

@end

@implementation ORComparatorGTNub
- (id) eval
{
	[guardian eval];
	BOOL abGT = NO;
	if(![(ORComparatorModel*)guardian abEqual]){
		if([(ORComparatorModel*)guardian abDifference]<0)abGT = YES;
	}
	return [ORProcessResult processState:abGT value:abGT];
}
- (int) evaluatedState
{
	BOOL abGT = NO;
	float diff = [(ORComparatorModel*)guardian abDifference];
	if(![(ORComparatorModel*)guardian abEqual]){
		if(diff<0)abGT = YES;
	}
	return abGT;
}
@end

