/*
    
    File:		ORFifoModel.h
    
    Usage:		Class Definition for a Fifo Module For a
                            Greenspring IP Board - VME Bus Resident
 
                                    SUPERCLASS = CVmeIO
                                    
    Author:		FM
    
    Copyright:		Copyright 2001-2002 F. McGirt.  All rights reserved.
    
    Change History:	1/22/02, 2/2/02, 2/12/02
                        2/13/02 MAH CENPA. converted to Objective-C
   
-----------------------------------------------------------
This program was prepared for the Regents of the University of 
Washington at the Center for Experimental Nuclear Physics and 
Astrophysics (CENPA) sponsored in part by the United States 
Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
The University has certain rights in the program pursuant to 
the contract and the program should not be copied or distributed 
outside your organization.  The DOE and the University of 
Washington reserve all rights in the program. Neither the authors,
University of Washington, or U.S. Government make any warranty, 
express or implied, or assume any liability or responsibility 
for the use of this software.
-------------------------------------------------------------

        
*/

 
//	Note:	Fifo Buffer States and CSR Status:
//
//			1.	No data in Fifo (and after Fifo reset), status = 0x10, Fifo Empty Bit Set
//			2.	For Fifo word count >= 1 and Fifo word count <= 2048, status = 0x00
//			3.	For Fifo word count > 2048 and Fifo word count < 4095, status = 0x20,
//					Fifo Half Full Bit Set
//			4.	For Fifo word count = 4095, status = 0x60, Fifo Half Full and Full-1 Bit Set
//			5.  For Fifo word count = 4096, status = 0xe0, Fifo Full, Full-1, and Half Full
//					Bits Set

#pragma mark ¥¥¥Imported Files
#import "ORVmeIPCard.h"

#define OExceptionFifoTestError @"Fifo Test Error"

@interface ORFifoModel :  ORVmeIPCard
{
    @private
	short interruptLevel;
}


#pragma mark ¥¥¥Initialization

#pragma mark ¥¥¥Accessors
- (void) setInterruptLevel:(short) anInterruptLevel;
- (short) interruptLevel;
- (void) resetFifo;

#pragma mark ¥¥¥Hardware Access
- (void) readFifo:(short) xregister
					  atPtr:(unsigned short *)value;
- (void) writeFifo:(short) xregister
         withValue:(unsigned short) value;


#pragma mark ¥¥¥Tests
- (void) blockLoadUnloadTest;
- (void) unloadFifo:(unsigned short *)value
         withLength:(unsigned int) length;
- (void) loadFifo:(unsigned short *)value
       withLength:(unsigned int) length;

- (void) setupTestMode;
- (void) readLocationTest:(unsigned short) j;
- (void) writeLocationTest:(unsigned short) j;

- (BOOL) checkLevel:(int)level status:(unsigned short)fifo_status;


@end

