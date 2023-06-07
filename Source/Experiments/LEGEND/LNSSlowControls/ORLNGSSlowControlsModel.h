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

@class ORSafeQueue;

@interface ORLNGSSlowControlsModel : OrcaObject
{
    NSString*           lastRequest;
    NSString*           ipAddress;
    NSString*           userName;
    NSString*           cmdPath;
	int					pollTime;
    
    int32_t             errorCount;
    
    //----queue thread--------
    bool                canceled;
    NSThread*           processThread;
    ORSafeQueue*        cmdQueue;
}

#pragma mark ***Accessors
- (BOOL) allDataIsValid:(unsigned short)aChan;

- (int) pollTime;
- (void) setPollTime:(int)aPollTime;
- (NSString*) ipAddress;
- (void) setIPAddress:(NSString*)anIP;
- (NSString*) userName;
- (void) setUserName:(NSString*)aName;
- (NSString*) cmdPath;
- (void) setCmdPath:(NSString*)aPath;

#pragma mark •••HW Commands
- (void) dataReceived:(NSNotification*)note;
- (void) pollHardware;

#pragma mark ***Thread
- (void) putRequestInQueue:(NSString*)aCmd;
- (void) processQueue;

- (void) timeout;
- (void) setDataValid:(unsigned short)aChan bit:(BOOL)aValue;
- (void) resetDataValid;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORLNGSSlowControlsPollTimeChanged;
extern NSString* ORLNGSSlowControlsModelDataIsValidChanged;
extern NSString* ORL200SlowControlsIPAddressChanged;
extern NSString* ORL200SlowControlsUserNameChanged;
extern NSString* ORL200SlowControlsCmdPathChanged;
extern NSString* ORLNGSSlowControlsLock;



