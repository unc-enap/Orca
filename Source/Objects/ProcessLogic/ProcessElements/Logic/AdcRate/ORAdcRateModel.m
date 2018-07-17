//-------------------------------------------------------------------------
//  ORAdcRateModel.m
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
#import "ORAdcRateModel.h"
#import "ORProcessOutConnector.h"
#import "ORProcessInConnector.h"
#import "ORProcessNub.h"

NSString* ORAdcRateModelIntegrationTimeChanged  = @"ORAdcRateModelIntegrationTimeChanged";
NSString* ORAdcRateModelValidChanged            = @"ORAdcRateModelValidChanged";
NSString* ORAdcRateModelRateLimitChanged        = @"ORAdcRateModelRateLimitChanged";

NSString* ORAdcRateHighConnection               = @"ORAdcRateHighConnection";
NSString* ORAdcRatePassThruConnection           = @"ORAdcRatePassThruConnection";

@implementation ORAdcRateModel

#pragma mark ***Initialization
-(void) dealloc
{
    [gtOutputNub release];
    [buffer release];
    [super dealloc];
}

- (NSString*) elementName
{
	return @"AdcRate";
}

- (void) makeMainController
{
    [self linkToController:@"ORAdcRateController"];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"AdcRate"]];
}

-(void) makeConnectors
{
	ORProcessInConnector* inConnector = [[ORProcessInConnector alloc] initAt:NSMakePoint(0,[self frame].size.height/2 - kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:inConnector forKey:ORSimpleLogicIn1Connection];
    [ inConnector setConnectorType: 'LP1 ' ];
    [ inConnector addRestrictedConnectionType: 'LP2 ' ]; //can only connect to processor outputs
    [inConnector release];
	
 	
    ORProcessOutConnector* outConnector = [[ORProcessOutConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize, [self frame].size.height-kConnectorSize-2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:outConnector forKey:ORAdcRateHighConnection];
    [ outConnector setConnectorType: 'LP2 ' ];
    [ outConnector addRestrictedConnectionType: 'LP1 ' ]; //can only connect to processor inputs
    [outConnector release];

	outConnector = [[ORProcessOutConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize, [self frame].size.height/2 - kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:outConnector forKey:ORAdcRatePassThruConnection];
    [ outConnector setConnectorType: 'LP2 ' ];
    [ outConnector addRestrictedConnectionType: 'LP1 ' ]; //can only connect to processor inputs
    [outConnector release];

}

- (void) setUpNubs
{
    if(!gtOutputNub)gtOutputNub = [[ORAdcRateGTNub alloc] init];
    [gtOutputNub setGuardian:self];
    ORConnector* aConnector = [[self connectors] objectForKey: ORAdcRateHighConnection];
    [aConnector setObjectLink:gtOutputNub];
	
}

#pragma mark ***Accessors

- (float) integrationTime
{
    return integrationTime;
}

- (void) setIntegrationTime:(float)aIntegrationTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIntegrationTime:integrationTime];
    
    if(aIntegrationTime<1)aIntegrationTime=1;
    
    
    integrationTime = aIntegrationTime;
    
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAdcRateModelIntegrationTimeChanged object:self];
}

- (BOOL) valid
{
    return valid;
}

- (void) setValid:(BOOL)aValid
{
    [[[self undoManager] prepareWithInvocationTarget:self] setValid:valid];
    
    valid = aValid;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAdcRateModelValidChanged object:self];
}

- (float) rateLimit
{
    return rateLimit;
}

- (void) setRateLimit:(float)aRateLimit
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRateLimit:rateLimit];
    
    rateLimit = aRateLimit;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAdcRateModelRateLimitChanged object:self];
}


- (id) eval
{
	if(!alreadyEvaluated){
		alreadyEvaluated = YES;
		float val  = [[self evalInput1] analogValue];
        if(!buffer) buffer = [[NSMutableArray array] retain];
        NSDictionary* pt = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:val],@"val",[NSDate date],@"time", nil];
        [buffer addObject:pt];
        NSDate* firstTime = [[buffer objectAtIndex:0] objectForKey:@"time"];
        if(!valid && [buffer count]<=3){
            rate = 0;
        }
        else {
            NSTimeInterval t1 = -[firstTime timeIntervalSinceNow];
            if(t1>integrationTime) {
                [self adjustBufferLength];
                rate = [self calculateRate];
            }
            valid = YES;
        }
		
		[self setState: valid];
		[self setEvaluatedState: valid];
	}
	return [ORProcessResult processState:valid value:rate];
}

- (void) adjustBufferLength
{
    int n = (int)[buffer count];
    NSTimeInterval tf = [[[buffer objectAtIndex:n-1] objectForKey:@"time"] timeIntervalSince1970];
    while(1) {
        NSTimeInterval dt =  tf - [[[buffer objectAtIndex:0] objectForKey:@"time"] timeIntervalSince1970];
        if(lroundf(dt/integrationTime - floor(dt/integrationTime) == 0)) break;
        else [buffer removeObjectAtIndex:0];
        if([buffer count] == 0) {
            // should not happen; ignore
            break;
        }
    }
}

- (float) rate
{
    return rate;
}

- (float) calculateRate
{
    float sumX = 0;
    float sumY = 0;
    float sumXY = 0;
    float sumXX = 0;
    int n = (int)[buffer count];
    NSTimeInterval t1 = [[[buffer objectAtIndex:0] objectForKey:@"time"] timeIntervalSince1970];

    for(id pt in buffer){
        NSTimeInterval t2 = [[pt objectForKey:@"time"] timeIntervalSince1970];
        float x = t2-t1;
        float  y = [[pt objectForKey:@"val"]  floatValue];
        sumX  += x;
        sumY  += y;
        sumXY += x*y;
        sumXX += x*x;
    }
    float div = (n*sumXX - (sumX*sumX));
    if(div==0)return 0;
    else return (n*sumXY - sumX*sumY)/div;
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setIntegrationTime:   [decoder decodeFloatForKey:@"integrationTime"]];
    [self setRateLimit:         [decoder decodeFloatForKey:@"rateLimit"]];
    [[self undoManager] enableUndoRegistration];    

    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeFloat:integrationTime    forKey:@"integrationTime"];
    [encoder encodeFloat:rateLimit          forKey:@"rateLimit"];
}
- (void) processIsStarting
{
    valid = NO;
    [buffer release];
    buffer = nil;
    [super processIsStarting];
}

@end

@implementation ORAdcRateGTNub
- (id) eval
{
	[guardian eval];
    BOOL rateBad = NO;
	if([(ORAdcRateModel*)guardian valid]){
        if([(ORAdcRateModel*)guardian rateLimit]<0 && [(ORAdcRateModel*)guardian rate]<[(ORAdcRateModel*)guardian rateLimit])      rateBad = YES;
        else if([(ORAdcRateModel*)guardian rateLimit]>0 && [(ORAdcRateModel*)guardian rate]>[(ORAdcRateModel*)guardian rateLimit]) rateBad = YES;
    }
	return [ORProcessResult processState:rateBad value:rateBad];
}

- (int) evaluatedState
{
    BOOL rateBad = NO;
	if([(ORAdcRateModel*)guardian valid]){
        if([(ORAdcRateModel*)guardian rateLimit]<0 && [(ORAdcRateModel*)guardian rate]<[(ORAdcRateModel*)guardian rateLimit])      rateBad = NO;
        else if([(ORAdcRateModel*)guardian rateLimit]>0 && [(ORAdcRateModel*)guardian rate]>[(ORAdcRateModel*)guardian rateLimit]) rateBad = NO;
    }
	return rateBad;
}

@end

