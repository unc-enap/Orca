//
//  ORBurstMonitorDecoders.m
//  Orca
//
//  Created by Mark Howe on 08/1/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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


#import "ORBurstMonitorDecoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"


//------------------------------------------------------------------------------------------------
// Data Format
//0 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
// ^^^^ ^^^^ ^^^^ ^^------------------------data id
//                  ^^ ^^^^ ^^^^ ^^^^ ^^^^--length in longs
//1 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  burst count
//2 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  numSecTilBurst
//3 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  float duration encoded as int32_t
//4 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  mult
//5 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  triage
//6 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  Rcm
//7 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  Rrms
//8 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  neutronP
//9 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  gammaP
//10 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  alphaP
//11 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  ut time
//-----------------------------------------------------------------------------------------------

@implementation ORBurstMonitorDecoderForBurst

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr = (uint32_t*)someData;
		
    NSString* valueString = [NSString stringWithFormat:@"%d",ptr[2]];
    
	[aDataSet loadGenericData:valueString sender:self withKeys:@"BurstMonitor",@"BurstCount",nil];
	
     return ExtractLength(ptr[0]); //must return the length
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    NSString* title= @"Burst Info Record\n\n";

    //get the duration
    union {
        int32_t theLong;
        float theFloat;
    }duration;
    duration.theLong = ptr[3];
    union {
        int32_t theLong;
        float theFloat;
    }neutP;
    neutP.theLong = ptr[8];
    union {
        int32_t theLong;
        float theFloat;
    }gamP;
    gamP.theLong = ptr[9];
    union {
        int32_t theLong;
        float theFloat;
    }alpP;
    alpP.theLong = ptr[10];

    NSString* theDuration           = [NSString stringWithFormat:@"Duration = %.6f seconds\n",duration.theFloat];
    NSString* theBurstCount         = [NSString stringWithFormat:@"Burst Count = %d\n",ptr[1]];
    NSString* theNumSecTilBurst     = [NSString stringWithFormat:@"Time of burst(sec) = %d\n",ptr[2]];
    NSString* countsInBurst         = [NSString stringWithFormat:@"Window Multiplicity = %d\n",ptr[4]];
    NSString* Triage                = [NSString stringWithFormat:@"Triage = %d\n",ptr[5]];
    NSString* Rcm                   = [NSString stringWithFormat:@"Center = %d mm\n",ptr[6]];
    NSString* Rrms                  = [NSString stringWithFormat:@"Position rms = %d mm\n",ptr[7]];
    NSString* neutronP              = [NSString stringWithFormat:@"Neutron Likelyhood = %.6f\n",neutP.theFloat];
    NSString* gammaP              = [NSString stringWithFormat:@"Gamma Likelyhood = %.6f\n",gamP.theFloat];
    NSString* alphaP              = [NSString stringWithFormat:@"Alpha Likelyhood = %.6f\n",alpP.theFloat];
    
    return [NSString stringWithFormat:@"%@%s%@%@%@%@%@%@%@%@%@%@",title,ctime((const time_t *)(&ptr[11])),Triage,countsInBurst,neutronP,gammaP,alphaP,theDuration,Rcm,Rrms,theBurstCount,theNumSecTilBurst];
}
@end


