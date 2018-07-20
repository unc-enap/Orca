/*
 *  ORPollingTimeStampModel.cpp
 *  Orca
 *
 *  Created by Mark Howe on Sat Nov 16 2002.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
 *
 */
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
#pragma mark •••Imported Files
#import "ORPollingTimeStampModel.h"
#import "ORDataTypeAssigner.h"
#include "VME_HW_Definitions.h"

@implementation ORPollingTimeStampModel

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"PollingTimeStamp"]];
}


- (void) makeMainController
{
    NSLog(@"The Timestamp object has no dialog\n");
}

#pragma mark •••Accessors
- (void) setDataIds:(id)assigner
{
	dataId       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherPollingTimeStamp
{
    [self setDataId:[anotherPollingTimeStamp dataId]];
}

- (uint32_t) dataId { return dataId; }
- (void) setDataId: (uint32_t) DataId
{
    dataId = DataId;
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    //----------------------------------------------------------------------------------------
    //add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORPollingTimeStampModel"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORPollingTimeStampDecoder",               @"decoder",
								 [NSNumber numberWithLong:dataId],          @"dataId",
								 [NSNumber numberWithBool:NO],              @"variable",
								 [NSNumber numberWithLong:3],				@"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"PollingTimeStamp"];
    return dataDictionary;
}



- (void) reset {}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
}

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    //nothing to do.. only works with the SBC
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
}

//this is the data structure for the new SBCs (i.e. VX704 from Concurrent)
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id = kPollingTimeStamp; //should be unique
	configStruct->card_info[index].hw_mask[0] = dataId; //better be unique
	configStruct->card_info[index].num_Trigger_Indexes = 0;
	configStruct->card_info[index].next_Card_Index 	= index+1;	
	
	return index+1;
}



@end
