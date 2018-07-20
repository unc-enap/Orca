/*
 *  ORVmeBusProtocol.h
 *  Orca
 *
 *  Created by Mark Howe on Sun Nov 17 2002.
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

#include <Cocoa/Cocoa.h>

@protocol ORVmeBusProtocol <NSObject>

- (void) resetContrl;
- (void) checkStatusErrors;

- (void) readLongBlock:(uint32_t *) readAddress
			 atAddress:(uint32_t) vmeAddress
			 numToRead:(uint32_t) numberLongs
			withAddMod:(unsigned short) addressModifier
		 usingAddSpace:(unsigned short) addressSpace;

- (void) readLong:(uint32_t *) readAddress
		atAddress:(uint32_t) vmeAddress
	  timesToRead:(uint32_t) numberLongs
	   withAddMod:(unsigned short) addModifier
	usingAddSpace:(unsigned short) addressSpace;


- (void) writeLongBlock:(uint32_t *) writeAddress
			  atAddress:(uint32_t) vmeAddress
			 numToWrite:(uint32_t) numberLongs
			 withAddMod:(unsigned short) addressModifier
		  usingAddSpace:(unsigned short) addressSpace;

- (void) readByteBlock:(unsigned char *) readAddress
			 atAddress:(uint32_t) vmeAddress
			 numToRead:(uint32_t) numberBytes
			withAddMod:(unsigned short) addressModifier
		 usingAddSpace:(unsigned short) addressSpace;

- (void) writeByteBlock:(unsigned char *) writeAddress
			  atAddress:(uint32_t) vmeAddress
			 numToWrite:(uint32_t) numberBytes
			 withAddMod:(unsigned short) addressModifier
		  usingAddSpace:(unsigned short) addressSpace;


- (void) readWordBlock:(unsigned short *) readAddress
			 atAddress:(uint32_t) vmeAddress
			 numToRead:(uint32_t) numberWords
			withAddMod:(unsigned short) addressModifier
		 usingAddSpace:(unsigned short) addressSpace;

- (void) writeWordBlock:(unsigned short *) writeAddress
			  atAddress:(uint32_t) vmeAddress
			 numToWrite:(uint32_t) numberWords
			 withAddMod:(unsigned short) addressModifier
		  usingAddSpace:(unsigned short) addressSpace;


@end
