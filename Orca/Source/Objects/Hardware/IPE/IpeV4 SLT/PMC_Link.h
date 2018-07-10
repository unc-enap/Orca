//
//  PMC_Link.h
//  
//
//  Created by Andreas Kopmann on 18.3.08.
//  Copyright 2007 CENPA, University of Washington. All rights reserved.
//
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

#import "SBC_Link.h"

@interface PMC_Link : SBC_Link {
}

#pragma mark •••Accessors
- (void) readLongBlockPmc:(unsigned long *) buffer
			 atAddress:(unsigned int) aPmcAddress
			 numToRead:(unsigned int) numberLongs;

- (void) writeLongBlockPmc:(unsigned long*) buffer
			 atAddress:(unsigned int) aPmcAddress
			 numToWrite:(unsigned int)  numberLongs;
@end


