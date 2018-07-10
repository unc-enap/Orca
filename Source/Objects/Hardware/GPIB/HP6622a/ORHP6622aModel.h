//
//  ORHP6622aModel.h
//  Orca
//
//  Created by Mark Howe on Tue May 13 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#pragma mark ¥¥¥Imported Files
#import "ORGpibDeviceModel.h"

#define kHP6622aNumberSupplies 2

@interface ORHP6622aModel : ORGpibDeviceModel {
	BOOL	powerOn[kHP6622aNumberSupplies];
	BOOL    ocProtectionOn[kHP6622aNumberSupplies];
	BOOL	outputOn[kHP6622aNumberSupplies];
	float   setVoltage[kHP6622aNumberSupplies];
	float   setCurrent[kHP6622aNumberSupplies];
	float   actCurrent[kHP6622aNumberSupplies];
	float   actVoltage[kHP6622aNumberSupplies];
	float   overVoltage[kHP6622aNumberSupplies];
}

#pragma mark ***Initialization
- (id) 		init;
- (void) 	dealloc;
- (void)	setUpImage;
- (void)	makeMainController;

#pragma mark ¥¥¥Accessors
- (BOOL) powerOn:(int)index;
- (void) setPowerOn:(int)index withValue:(BOOL)aState;
- (BOOL) ocProtectionOn:(int)index ;
- (void) setOcProtectionOn:(int)index withValue:(BOOL)aState;
- (BOOL) outputOn:(int)index; 
- (void) setOutputOn:(int)index withValue:(BOOL)aState;
- (float) setVoltage:(int)index; 
- (void) setSetVoltage:(int)index withValue:(float)aState;
- (float) actVoltage:(int)index; 
- (void) setActVoltage:(int)index withValue:(float)aState;
- (float) overVoltage:(int)index;
- (void) setOverVoltage:(int)index withValue:(float)aState;
- (float) setCurrent:(int)index; 
- (void) setSetCurrent:(int)index withValue:(float)aState;
- (float) actCurrent:(int)index; 
- (void) setActCurrent:(int)index withValue:(float)aState;

- (void) readVoltages;
- (void) readCurrents;
- (void) readOverVoltages;

- (NSString*) decodeErrorNumber:(int)errorNum;

#pragma mark ¥¥¥Hardware Access
- (void) readIDString;
- (void) doSelfTest;
- (void) writeVoltages;
- (void) writeOutputOn;
- (void) writeVoltages;
- (void) writeCurrents;
- (void) writeOverVoltage;
- (void) writeOCProtection;
- (void) resetOverVoltage:(int)index;
- (void) resetOcProtection:(int)index;
- (void) logSystemResponse;
- (void) sendAllToHW;
- (void) readAllHW;
- (void) sendClear;

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)aDecoder;
- (void)encodeWithCoder:(NSCoder*)anEncoder;

@end

extern NSString* ORHP6622aPowerOnChanged;
extern NSString* ORHP6622aOcProtectionOnChanged;
extern NSString* ORHP6622aOutputOnChanged;
extern NSString* ORHP6622aSetVolageChanged;
extern NSString* ORHP6622aActVolageChanged;
extern NSString* ORHP6622aOverVolageChanged;
extern NSString* ORHP6622aSetCurrentChanged;
extern NSString* ORHP6622aActCurrentChanged;

extern NSString* ORHP6622aModelLockGUIChanged;
extern NSString* ORHP6622aLock;