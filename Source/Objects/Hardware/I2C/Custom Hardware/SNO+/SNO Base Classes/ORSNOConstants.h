/*
 *  ORSNOConstants.h
 *  Orca
 *
 *  Created by Mark Howe on 11/17/08.
 *  Copyright 2008 University of North Carolina. All rights reserved.
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
#define kChannelsPerBoard 	32
#define kCardsPerCrate		16
#define kChannelsPerCrate  512
#define kMaxNumberPMTs	  9685

#define kMaxSNOMotherBoards     304 //total number of mother boards in SNO+
#define kMaxSNOCrates			20
#define kNumSNOCards			16
#define kNumSNOCrateSlots		18
#define kNumSNOPmts				32
#define kNumSNODaughterCards	4

// Board Id Register Definitions
#define MC_BOARD_ID_INDEX		1
#define DC_BOARD0_ID_INDEX		2
#define DC_BOARD1_ID_INDEX		3
#define DC_BOARD2_ID_INDEX		4
#define DC_BOARD3_ID_INDEX		5
