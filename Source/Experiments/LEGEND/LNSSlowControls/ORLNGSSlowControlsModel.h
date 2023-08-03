//
//  ORLNGSSlowControlsModel.h
//  Orca
//
//  Created by Mark Howe on Thursday, Aug 20,2009
//  Copyright (c) 2009 Univerisy of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the Univerisy of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the Univerisy of North 
//Carolina reserve all rights in the program. Neither the authors,
//Univerisy of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#pragma mark •••Imported Files

#import "OrcaObject.h"
#import "ORInFluxDBModel.h"

@class ORSafeQueue;

#define kCmdStatus     @"status"
#define kCmdTime       @"time"
#define kNumArgs       @"numArgs"
#define kCmdData       @"data"

@interface ORLNGSSlowControlsModel : OrcaObject
{
    NSString*           ipAddress;
    NSString*           userName;
    NSString*           cmdPath;
	int					pollTime;
    NSMutableDictionary* cmdStatus;
    NSArray*            cmdList;
    ORInFluxDBModel*    inFluxDB;

    //----queue thread--------
    bool                canceled;
    NSThread*           processThread;
    ORSafeQueue*        cmdQueue;
}

#pragma mark ***Accessors
- (int) pollTime;
- (void) setPollTime:(int)aPollTime;
- (NSString*) ipAddress;
- (void) setIPAddress:(NSString*)anIP;
- (NSString*) userName;
- (void) setUserName:(NSString*)aName;
- (NSString*) cmdPath;
- (void) setCmdPath:(NSString*)aPath;
- (bool) inFluxDBAvailable;

#pragma mark •••HW Commands
- (void) pollHardware;
- (NSInteger) cmdListCount;
- (NSString*) cmdAtIndex:(NSInteger)i;
- (id) cmdValue:(id)aCmd key:(id)aKey;
- (id) cmd:(id)aCmd dataAtRow:(int)row column:(int)col;

#pragma mark ***Thread
- (void) putRequestInQueue:(NSString*)aCmd;
- (void) processQueue;
- (void) handle:(NSString*)aCmd data:(NSString*)result;
- (void) sendToInFlux:(NSString*)aCmd;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORLNGSSlowControlsPollTimeChanged;
extern NSString* ORL200SlowControlsIPAddressChanged;
extern NSString* ORL200SlowControlsUserNameChanged;
extern NSString* ORL200SlowControlsCmdPathChanged;
extern NSString* ORL200SlowControlsStatusChanged;
extern NSString* ORL200SlowControlsInFluxChanged;
extern NSString* ORL200SlowControlsDataChanged;
extern NSString* ORLNGSSlowControlsLock;
