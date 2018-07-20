//
//  ORSecurity.h
//  Orca
//
//  Created by Mark Howe on Thu Feb 19 2004.
//  Copyright (c) 2004 CENPA, University of Washington. All rights reserved.
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





@interface ORSecurity : NSObject {
    NSMutableDictionary* locks;
    uint32_t superUnlockMask;
    NSMutableDictionary* superUnlockMaskRequests;
	id					 passWordPanel;
}
+ (ORSecurity*) sharedSecurity;

- (NSDictionary*)locks;
- (int) numberItemsUnlocked;
- (void) setLocks:(NSMutableDictionary *)aLocks;
- (void) setLock:(NSString*)aLockName to:(BOOL)aState;
- (BOOL) isLocked:(NSString*)aLockName;
- (void) tryToSetLock:(NSString*)aLockName to:(BOOL)aState forWindow:(NSWindow*)aWindow;
- (BOOL) globalSecurityEnabled;
- (BOOL) runInProgressOrIsLocked:(NSString*)aLockName;
- (BOOL) runInProgressButNotType:(uint32_t)aMask orIsLocked:(NSString*)aLockName;
- (void) lockAll;
- (uint32_t)superUnlockMask;
- (void) addSuperUnlockMask:(uint32_t)aMask forObject:(id)anObj;
- (void) removeSuperUnlockMaskForObject:(id)anObj;

@end

extern ORSecurity* gSecurity;
extern NSString*   ORSecurityNumberLockPagesChanged;