//
//  ORAugerCardDecoder.h
//  Orca
//
//  Created by Mark Howe on 10/18/05.
//  Copyright 2004 CENPA, University of Washington. All rights reserved.
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



#import "ORAugerCardDecoder.h"

@class ORDataPacket;
@class ORDataSet;

/** Decoder for the event data stream. 
  * These objects are generated in Flt energy mode.
  */
@interface ORAugerFLTDecoderForEnergy : ORAugerStationDecoder {
}
// Documentation in m-file
- (unsigned long) decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)dataPtr;
@end


/** Decoder for the extended event data stream. 
  * These objects are generated in Flt trace mode.
  */
@interface ORAugerFLTDecoderForWaveForm : ORAugerStationDecoder {
}
// Documentation in m-file
- (unsigned long) decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)dataPtr;
@end


/** Decoder for the threshold scan stream. 
  * This objects are generated in Flt measure mode.
  */
@interface ORAugerFLTDecoderForHitRate : ORAugerStationDecoder {
  int lastEnergy[22];		//!< Energy of the last sample. Used to calculate the difference per sample
  int lastHitrate[22];		//!< Trigger rate of the last sample. Used to calculate the difference per sample
}
// Documentation in m-file
- (unsigned long) decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)dataPtr;
@end
