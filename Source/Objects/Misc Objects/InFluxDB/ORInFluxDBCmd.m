//-------------------------------------------------------------------------
//  ORInFluxDBCommand.m
//  Created by Mark Howe on 12/30/2022.
//  Copyright (c) 2022 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//Washington reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import "ORInFluxDBCmd.h"
#import "ORInFluxDBModel.h"
@implementation ORInFluxDBCmd

- (id) initWithCmdType:(int)aType;
{
    self = [super init];
    cmdType = aType;
    return self;
}

- (void) dealloc
{
    [outputBuffer release];
    [super dealloc];
}
- (int) cmdType
{
    return cmdType;
}
- (void) start:(NSString*)section withTags:(NSString*)someTags
{
    if(!outputBuffer) outputBuffer = [[NSMutableString alloc]init];
    if(!someTags){someTags = @"";}
    [outputBuffer appendFormat:@"%@,%@ ",section,someTags];
 }

- (void) removeEndingComma
{
    NSRange lastComma = [outputBuffer rangeOfString:@"," options:NSBackwardsSearch];

    if(lastComma.location == [outputBuffer length]-1) {
        [outputBuffer replaceCharactersInRange:lastComma
                                           withString: @""];
    }
}

- (void) addLong:(NSString*)aValueName withValue:(long)aValue
{
    [outputBuffer appendFormat:@"%@=%ld,",aValueName,aValue];
}

- (void) addDouble:(NSString*)aValueName withValue:(double)aValue
{
    [outputBuffer appendFormat:@"%@=%f,",aValueName,aValue];
}

- (void) addString:(NSString*)aValueName withValue:(NSString*)aValue
{
    [outputBuffer appendFormat:@"%@=\"%@\",",aValueName,aValue];
}
- (void) end:(ORInFluxDBModel*)aSender
{
    [self removeEndingComma];
    [outputBuffer appendFormat:@"   \n"];
    [aSender sendCmd:self];
}
- (NSData*) payload
{
    return [outputBuffer dataUsingEncoding:NSASCIIStringEncoding];
}
- (NSString*) outputBuffer
{
    return outputBuffer;
}


@end
