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

- (void) readLongBlock:(unsigned long *) readAddress
			 atAddress:(unsigned int) vmeAddress
			 numToRead:(unsigned int) numberLongs
			withAddMod:(unsigned short) addressModifier
		 usingAddSpace:(unsigned short) addressSpace;

- (void) readLong:(unsigned long *) readAddress
		atAddress:(unsigned long) vmeAddress
	  timesToRead:(unsigned int) numberLongs
	   withAddMod:(unsigned short) addModifier
	usingAddSpace:(unsigned short) addressSpace;


- (void) writeLongBlock:(unsigned long *) writeAddress
			  atAddress:(unsigned int) vmeAddress
			 numToWrite:(unsigned int) numberLongs
			 withAddMod:(unsigned short) addressModifier
		  usingAddSpace:(unsigned short) addressSpace;

- (void) readByteBlock:(unsigned char *) readAddress
			 atAddress:(unsigned int) vmeAddress
			 numToRead:(unsigned int) numberBytes
			withAddMod:(unsigned short) addressModifier
		 usingAddSpace:(unsigned short) addressSpace;

- (void) writeByteBlock:(unsigned char *) writeAddress
			  atAddress:(unsigned int) vmeAddress
			 numToWrite:(unsigned int) numberBytes
			 withAddMod:(unsigned short) addressModifier
		  usingAddSpace:(unsigned short) addressSpace;


- (void) readWordBlock:(unsigned short *) readAddress
			 atAddress:(unsigned int) vmeAddress
			 numToRead:(unsigned int) numberWords
			withAddMod:(unsigned short) addressModifier
		 usingAddSpace:(unsigned short) addressSpace;

- (void) writeWordBlock:(unsigned short *) writeAddress
			  atAddress:(unsigned int) vmeAddress
			 numToWrite:(unsigned int) numberWords
			 withAddMod:(unsigned short) addressModifier
		  usingAddSpace:(unsigned short) addressSpace;


@end
