//
//ORCaen1724Decoder.h
//Orca
//
//Created by Mark Howe on Mon Mar 14, 2011.
//Copyright (c) 2011 University of North Carolina. All rights reserved.
//
//-------------------------------------------------------------
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

#import "ORVmeCardDecoder.h"
@class ORDataPacket;

//--------------------------------------------------------------------------------
// Class ORCaen1724Decoder
//--------------------------------------------------------------------------------
@interface ORCaen1724WaveformDecoder : ORVmeCardDecoder 
{
    @private 
        BOOL getRatesFromDecodeStage;
        NSMutableDictionary* actualCards;
        time_t lastTime;
}

@end
