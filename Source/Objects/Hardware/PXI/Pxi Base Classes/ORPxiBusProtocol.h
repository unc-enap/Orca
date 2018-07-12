//
//  ORPxiBusProtocol.h
//  Orca
//
//  Created by Mark Howe on Thurs Aug 26 2010
//  Copyright (c) 2010 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics 
//sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

@protocol ORPxiBusProtocol <NSObject>

- (void) resetContrl;
- (void) checkStatusErrors;

- (void) readLongBlock:(unsigned long *) readAddress
			 atAddress:(unsigned long) pxiAddress
			 numToRead:(unsigned long) numberLongs;

- (void) readLong:(unsigned long *) readAddress
		atAddress:(unsigned long) pxiAddress
	  timesToRead:(unsigned long) numberLongs;


- (void) writeLongBlock:(unsigned long *) writeAddress
			  atAddress:(unsigned long) pxiAddress
			 numToWrite:(unsigned long) numberLongs;

- (void) readByteBlock:(unsigned char *) readAddress
			 atAddress:(unsigned long) pxiAddress
			 numToRead:(unsigned long) numberBytes;

- (void) writeByteBlock:(unsigned char *) writeAddress
			  atAddress:(unsigned long) pxiAddress
			 numToWrite:(unsigned long) numberBytes;


- (void) readWordBlock:(unsigned short *) readAddress
			 atAddress:(unsigned long) pxiAddress
			 numToRead:(unsigned long) numberWords;

- (void) writeWordBlock:(unsigned short *) writeAddress
			  atAddress:(unsigned long) pxiAddress
			 numToWrite:(unsigned long) numberWords;

@end
