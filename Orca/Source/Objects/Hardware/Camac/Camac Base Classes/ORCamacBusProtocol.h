/*
 *  ORCamacBusProtocol.h
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

@protocol ORCamacBusProtocol <NSObject>

- (void)            setCrateInhibit:(BOOL)state;
- (unsigned short)  executeCCycle;
- (unsigned short)  executeZCycle;
- (unsigned short)  executeCCycleIOff;
- (unsigned short)  executeZCycleIOn;

- (unsigned short)  readLEDs;
- (unsigned short)  camacStatus;		// get status
- (void)  checkCratePower;				// check crate power
- (void)  checkStatusErrors;			// check controller status


- (unsigned short) camacShortNAF:(unsigned short) n 
							   a:(unsigned short) a 
							   f:(unsigned short) f
							data:(unsigned short*) data;


- (unsigned short) camacShortNAF:(unsigned short) n 
							   a:(unsigned short) a 
							   f:(unsigned short) f;

- (unsigned short) camacLongNAF:(unsigned short) n 
								a:(unsigned short) a 
								f:(unsigned short) f
							 data:(unsigned long*) data;

- (unsigned short) camacShortNAFBlock:(unsigned short)n 
									a:(unsigned short)a 
									f:(unsigned short)f
								 data:(unsigned short*) data 
							   length:(unsigned long) numWords;

- (unsigned short) camacLongNAFBlock:(unsigned short)n 
									a:(unsigned short)a 
									f:(unsigned short)f
								 data:(unsigned long*) data 
							   length:(unsigned long) numWords;


@end
