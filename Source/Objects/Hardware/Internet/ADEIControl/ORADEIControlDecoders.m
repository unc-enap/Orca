//--------------------------------------------------------
// ORADEIControlDecoders
// Created by A. Kopmann on Feb 8, 2019
// Copyright (c) 2019, University of North Carolina. All rights reserved.
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


#import "ORADEIControlDecoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORADEIControlModel.h"
//------------------------------------------------------------------------------------------------
// Data Format
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
// ^^^^ ^^^^ ^^^^ ^^------------------------data id
//                  ^^ ^^^^ ^^^^ ^^^^ ^^^^--length in longs
//
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//                          ^^^^ ^^^^ ^^^^--device id
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  time measured
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc index
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc low
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc high
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  spare
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  spare
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  spare
//-----------------------------------------------------------------------------------------------

@implementation ORADEIControlDecoderForAdc

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	uint32_t *dataPtr  = (uint32_t*)someData;
    int objId               = dataPtr[1] & 0xfffff;
    uint32_t timeStamp = dataPtr[2];
    uint32_t dataIndex = dataPtr[3];
    union {
        double asDouble;
        uint32_t asLong[2];
    } theData;
    theData.asLong[0] = dataPtr[4];
    theData.asLong[1] = dataPtr[5];
    double theValue = theData.asDouble;
    
    NSString* aKey = [@"ORADEIControlModel," stringByAppendingFormat:@"%d",objId];
    if(!actualHVObjs)actualHVObjs = [[NSMutableDictionary alloc] init];
    ORADEIControlModel* obj = [actualHVObjs objectForKey:aKey];
    if(!obj){
        NSArray* listOfCards = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORADEIControlModel")];
        for(ORADEIControlModel* anObj in listOfCards){
            if([anObj uniqueIdNumber] == objId){
                [actualHVObjs setObject:anObj forKey:aKey];
                obj = anObj;
                break;
            }
        }
    }
    NSString* nameString = [obj measuredValueName:dataIndex];

    [aDataSet loadTimeSeries:theValue
                      atTime:timeStamp
                      sender:self
                    withKeys:@"ADEIControl TimeSeries",
                    nameString,
                nil];
    
	return ExtractLength(dataPtr[0]);
}

- (NSString*) dataRecordDescription:(uint32_t*)dataPtr
{
    NSString* title= @"ADEIControl\n\n";
    NSString* theString =  [NSString stringWithFormat:@"%@\n",title];               
	int ident = dataPtr[1] & 0xfff;
	theString = [theString stringByAppendingFormat:@"Unit %d\n",ident];
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)dataPtr[2]];
    int objId               = dataPtr[1] & 0xfffff;
    uint32_t dataIndex = dataPtr[3];
    union {
        double asDouble;
        uint32_t asLong[2];
    } theData;
    theData.asLong[0] = dataPtr[4];
    theData.asLong[1] = dataPtr[5];
    double theValue = theData.asDouble;
    
    NSString* aKey = [@"ORADEIControlModel," stringByAppendingFormat:@"%d",objId];
    if(!actualHVObjs)actualHVObjs = [[NSMutableDictionary alloc] init];
    ORADEIControlModel* obj = [actualHVObjs objectForKey:aKey];
    if(!obj){
        NSArray* listOfCards = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORADEIControlModel")];
        for(ORADEIControlModel* anObj in listOfCards){
            if([anObj uniqueIdNumber] == objId){
                [actualHVObjs setObject:anObj forKey:aKey];
                obj = anObj;
                break;
            }
        }
    }
    NSString* nameString = [obj measuredValueName:dataIndex];

    
    
    theString = [theString stringByAppendingFormat:@"%@: %lf\n time: %@\n",nameString,theValue,[date stdDescription]];

	return theString;
}
@end


