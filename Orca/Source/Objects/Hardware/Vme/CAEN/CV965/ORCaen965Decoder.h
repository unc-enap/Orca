//
//  ORCaen965Decoder.h
//  Orca
//
//  Created by Mark Howe on Wed Dec 9, 2009.
//  Copyright (c) 2009 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Carolina reserve all rights in the program. Neither the authors,
//University of Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORVmeCardDecoder.h"

//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//^^^^ ^^^^ ^^^^ ^^----------------------- ID (from header)
//-----------------^^ ^^^^ ^^^^ ^^^^ ^^^^- length
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//--------^-^^^--------------------------- Crate number
//-------------^-^^^^--------------------- Card number
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//^^^^ ^---------------------------------- Geo
//------^^^------------------------------- data type 0x2=header, 0x0=valid data,  0x4=end of block, 0x6=invalid
//-------------^-^^^---------------------- channel (V965)
//------------------^--------------------- RG (V965)
//-------------^-^^----------------------- channel (V965A)
//-----------------^---------------------- RG (V965A)
//-----------------------^---------------- under flow
//------------------------^--------------- over flow
//-------------------------^^^^ ^^^^ ^^^^- qdc value
//.... may be followed by more qdc words

@interface ORCaen965DecoderForQdc : ORVmeCardDecoder {
}
- (unsigned long) decodeData:(void*) aSomeData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*) aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)ptr;
- (void) printData: (NSString*) pName data:(void*) theData;
- (unsigned short) 	channel: (unsigned long) pDataValue;
- (unsigned short) rg: (unsigned long) pDataValue;
@end

@interface ORCaen965ADecoderForQdc : ORCaen965DecoderForQdc {
}
- (unsigned short) 	channel: (unsigned long) pDataValue;
- (unsigned short) rg: (unsigned long) pDataValue;
@end
