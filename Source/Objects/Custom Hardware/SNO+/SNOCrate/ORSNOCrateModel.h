//
//  ORSNOCrateModel.h
//  Orca
//
//  Created by Mark Howe on Tue, Apr 30, 2008.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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
#pragma mark •••Imported Files
#import "ORCrate.h"
//#import "Sno_Monitor_Adcs.h"
//#import "ORDataTaker.h"
//#import "VME_eCPU_Config.h"
//#import "SBC_Config.h"

@interface ORSNOCrateModel : ORCrate {
	int slot;
	int workingSlot;
	BOOL working;
	BOOL pauseWork;
}

- (void) setUpImage;
- (void) makeMainController;
- (void) connected;
- (void) disconnected;
- (Class) guardianClass;
- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian;
- (void) setSlot:(int)aSlot;
- (int)  slot;

#pragma mark •••Accessors
- (uint32_t) memoryBaseAddress;
- (uint32_t) registerBaseAddress;
- (NSString*) iPAddress;
- (uint32_t) portNumber;

#pragma mark •••Notifications
- (void) registerNotificationObservers;

#pragma mark •••HW Access
- (void) scanWorkingSlot;
- (short) numberSlotsUsed;
- (void) resetCrate;
- (void) initCrateDone;
- (void) fetchECALSettings;
- (void) loadHardware;

@end

@interface ORSNOCrateModel (OROrderedObjHolding)
- (int) maxNumberOfObjects;
- (int) objWidth;
- (NSUInteger) stationForSlot:(int)aSlot;
@end

extern NSString* ORSNOCrateSlotChanged;
