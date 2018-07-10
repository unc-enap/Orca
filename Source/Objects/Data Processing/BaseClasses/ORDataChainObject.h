//
//  ORDataChainObject.h
//  OrcaIntel
//
//  Created by Mark Howe on 12/18/07.
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

@interface ORDataChainObject : OrcaObject {
	BOOL involvedInCurrentRun;
}
- (BOOL) involvedInCurrentRun;
- (void) setInvolvedInCurrentRun:(BOOL)state;
- (void) addObjectInfoToArray:(NSMutableArray*)anArray;
- (void) endOfRunCleanup:(NSDictionary*)userInfo;
- (void) setRunMode:(int)aMode;
- (void) runIsStopping:(NSDictionary*)userInfo;
- (BOOL) runModals;
- (void) runTaskStarted:(NSDictionary*)userInfo;
- (void) runTaskStopped:(NSDictionary*)userInfo;
- (void) closeOutRun:(NSDictionary*)userInfo;
- (void) subRunTaskStarted:(NSDictionary*)userInfo;
@end

@interface ORDataChainObjectWithGroup : ORGroup {
	BOOL involvedInCurrentRun;
}
- (BOOL) involvedInCurrentRun;
- (void) setInvolvedInCurrentRun:(BOOL)state;
- (void) addObjectInfoToArray:(NSMutableArray*)anArray;
- (void) endOfRunCleanup:(NSDictionary*)userInfo;
- (void) setRunMode:(int)aMode;
- (void) runIsStopping:(NSDictionary*)userInfo;
- (BOOL) runModals;
@end


extern NSString* ORDataChainObjectInvolvedInCurrentRun;
