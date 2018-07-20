//
//  NcdMuxModel.h
//  Orca
//
//  Created by Mark Howe on Thurs Feb 20 2003.
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


#pragma mark ¥¥¥Imported Files
#import "ORDataTaker.h"

#pragma mark ¥¥¥Forward Declarations
@class NcdMuxHWModel;
@class ORReadOutList;
@class ORDataPacket;
@class NcdDetector;

#define kNumNcdSupplies 8
#define kMuxBusNumberDataRecordShift 23

@interface NcdMuxModel :  OrcaObject <ORDataTaker>  
{
    @private
        NcdMuxHWModel* 	muxBoxHw;
        NcdMuxHWModel* 	hvHw;
        ORReadOutList* 	trigger1Group;
        ORReadOutList* 	trigger2Group;

        NSArray* 		dataTakers1;			//cache of data takers.
        NSArray* 		dataTakers2;			//cache of data takers.

        NcdDetector*	detector;	

        //errors 
        uint32_t 	eventReadError;
        uint32_t 	armError;
        int				badCount;
        
        BOOL		timingEvent[2];
        NSTimeInterval	timeOfLastScopeEvent[2];

        uint32_t muxEventDataId;
        uint32_t muxDataId;
        NSLock* muxLock;

}

#pragma mark ¥¥¥Notification
- (void) registerNotificationObservers;
- (void) disableScopes:(NSNotification*)aNote;
- (void) reArmScopes:(NSNotification*)aNote;

#pragma mark ¥¥¥Accessors
- (NcdMuxHWModel*) 	muxBoxHw;
- (void)		setMuxBoxHw:(NcdMuxHWModel*)hw;
- (NcdMuxHWModel*) 	hvHw;
- (void) 		setHvHw:(NcdMuxHWModel*)hw;
- (int) 		scopeSelection;
- (void) 		setScopeSelection:(int)newScopeSelection;
- (int) 		numberOfSupplies;
- (void) 		resetAdcs;
- (ORReadOutList*) trigger1Group;
- (void) 			setTrigger1Group:(ORReadOutList*)newTrigger1Group;
- (ORReadOutList*) 	trigger2Group;
- (void) 			setTrigger2Group:(ORReadOutList*)newTrigger2Group;
- (NSMutableArray*) children;
- (NcdDetector*) detector;
- (void) setDetector:(NcdDetector*)newDetector;
- (uint32_t) eventReadError;
- (uint32_t) armError;
- (uint32_t) muxEventDataId;
- (void) setMuxEventDataId: (uint32_t) MuxEventDataId;
- (uint32_t) muxDataId;
- (void) setMuxDataId: (uint32_t) MuxDataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherMux;

#pragma mark ¥¥¥HV Hardware Access
- (void) turnOnSupplies:(NSArray*)someSupplies state:(BOOL)aState;
- (void) writeDac:(int)aValue supply:(id)aSupply;
- (void) readCurrent:(id)aSupply;
- (uint32_t) readRelayMask;
- (uint32_t) lowPowerOn;
- (void) readAdc:(id)aSupply;
- (void) readDac:(id)aSupply;
- (void) reArm;
- (void) readAndDumpEvent; //for testing

#pragma mark ¥¥¥DataTaker
- (NSDictionary*) dataRecordDescription;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) saveReadOutList:(NSFileHandle*)aFile;
- (void) loadReadOutList:(NSFileHandle*)aFile;

- (BOOL) getScopeMask:(unsigned char*)aMask forScope:(short)scope eventReg:(unsigned short) aMuxEventRegister;
- (void) takeScopeData:(ORDataPacket*)aDataPacket onScope:(id)scope userInfo:(NSDictionary*)userInfo;
- (void) readOutScope:(int)scope usingPacket:(ORDataPacket*)aDataPacket hitDR:(unsigned short)aHitDR userInfo:(NSDictionary*)userInfo;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
@end


@interface NSObject (ScopeCatagory)
	-(BOOL) dataAvailable;
@end

#pragma mark ¥¥¥Notification Strings
extern NSString* NcdMuxScopeSelectionChangedNotification;
extern NSString* NcdMuxErrorCountChangedNotification;
