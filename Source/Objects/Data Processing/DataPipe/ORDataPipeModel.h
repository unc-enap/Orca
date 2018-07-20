//
//  ORDataPipeModel.h
//  Orca
//
//  Created by Mark Howe on Wed Feb 15, 2017.
//  Copyright (c) 2017 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


#pragma mark •••Imported Files
#import "ORDataChainObject.h"
#import "ORDataProcessing.h"

#pragma mark •••Forward Declarations
@class ORDataPipeClient;
@class ORDecoder;
@class ORRunModel;

@interface ORDataPipeModel :  ORDataChainObject <ORDataProcessing>  
{
    @private
	BOOL            validRunType;
	BOOL            runInProgress;
	int             runMode;
    int             fifoFD;
    
    NSString*       readerPath;
    pid_t           readerPid;
    NSString*       pipeName;
    BOOL            readerIsRunning;
    int32_t            numberBytesSent;
    float           sendRate;
    ORRunModel*     runModel;
    uint32_t	runType;
  
}
#pragma mark •••Init Stuff
- (void) getRunModel;

#pragma mark •••Accessors
- (void) startUpdates;
- (void) postUpdate;
- (NSString*) readerPath;
- (void) setReaderPath:(NSString*)aPath;
- (NSString*) pipeName;
- (void) setPipeName:(NSString*)aName;
- (float) sendRate;
- (int32_t) numberBytesSent;
- (BOOL) readerIsRunning;
- (BOOL) runInProgress;
- (ORRunModel*)runModel;
- (uint32_t)runType;
- (void)	setRunType:(uint32_t)aMask;
- (BOOL) validRunType;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) runAboutToStop:(NSNotification*) aNote;

#pragma mark •••Data Handling
- (BOOL) checkReader;
- (void) processData:(NSArray*)dataArray decoder:(ORDecoder*)aDecoder;
- (void) runTaskStarted:(NSDictionary*)userInfo;
- (void) runTaskStopped:(NSDictionary*)userInfo;
- (void) preCloseOut:(NSDictionary*)userInfo;
- (void) closeOutRun:(NSDictionary*)userInfo;

#pragma mark •••Delegate Methods
- (void) setRunMode:(int)aMode;

@end

extern NSString* ORDataPipeLock;

extern NSString* ORDataPipeReaderPathChanged;
extern NSString* ORDataPipeNameChanged;
extern NSString* ORDataPipeUpdate;
extern NSString* ORDataPipeLoadRunTypeNames;
extern NSString* ORDataPipeTypeChangedNotification;
