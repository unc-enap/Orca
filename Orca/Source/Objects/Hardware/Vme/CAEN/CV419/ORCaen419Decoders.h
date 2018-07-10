//
//  ORCaen419AdcDecoders.h
//  Orca
//
//  Created by Mark Howe on 2/23.
//  Copyright 2009 CENPA, University of Washington. All rights reserved.
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
#import "ORVmeCardDecoder.h"
@class ORDataPacket;
@class ORDataSet;

//ADC record short form:
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//^^^^ ^^--------------------------------- ID (from header)
//--------^-^^^--------------------------- Crate number
//-------------^-^^^^--------------------- Card number
//--------------------^^^^---------------- Channel number
//-------------------------^^^^ ^^^^ ^^^^- adc value
//
//ADC record long form:
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//^^^^ ^^^^ ^^^^ ^^----------------------- ID (from header)
//-----------------^^ ^^^^ ^^^^ ^^^^ ^^^^- length (always 2 longs)
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//--------^-^^^--------------------------- Crate number
//-------------^-^^^^--------------------- Card number
//--------------------^^^^---------------- Channel number
//-------------------------^^^^ ^^^^ ^^^^- adc value

@interface ORCaen419DecoderForAdc : ORVmeCardDecoder {
	@private 
		BOOL getRatesFromDecodeStage;
		NSMutableDictionary* actual419s;
}
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)dataPtr;
@end
