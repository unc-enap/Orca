//
//  ORHP3458aModel.h
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


#pragma mark •••Imported Files
#import "ORGpibDeviceModel.h"

typedef struct  {
	NSString*   name;
	float		fullScale;
} HP3458aNamesStruct;
 
@interface ORHP3458aModel : ORGpibDeviceModel 
{
    int functionDef;
    int maxInput;
}

#pragma mark ***Initialization
- (id) 		init;
- (void) 	dealloc;
- (void)	setUpImage;
- (void)	makeMainController;

#pragma mark •••Accessors
- (int) maxInput;
- (void) setMaxInput:(int)aMaxInput;
- (int) functionDef;
- (void) setFunctionDef:(int)aFunction;
- (void) readVoltages;
- (int) getNumberItemsForMaxInput;
- (NSString*) getMaxInputName:(int)i;
- (NSString*) trucateToCR:(char*)cString;

#pragma mark •••Hardware Access
- (void) readIDString;
- (void) doSelfTest;
- (void) logSystemResponse;
- (void) sendAllToHW;
- (void) readAllHW;
- (void) sendFuncDef;
- (void) resetHW;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)aDecoder;
- (void)encodeWithCoder:(NSCoder*)anEncoder;

@end

extern NSString* ORHP3458aModelMaxInputChanged;
extern NSString* ORHP3458aModelFunctionDefChanged;
extern NSString* ORHP3458aModelLockGUIChanged;
extern NSString* ORHP3458aLock;