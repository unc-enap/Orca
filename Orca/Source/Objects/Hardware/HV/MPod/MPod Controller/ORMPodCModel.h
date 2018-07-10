//
//  ORMPodCModel.h
//  Orca
//
//  Created by Mark Howe on Thurs Jan 6,2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics 
//sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ¥¥¥Imported Files
#import "ORMPodCard.h"
#import "ORMPodProtocol.h"
@class ORPingTask;

@interface ORMPodCModel :  ORMPodCard <ORMPodProtocol>
{
	NSMutableArray*	connectionHistory;
	unsigned		ipNumberIndex;
	NSString*		IPNumber;
	ORPingTask*		pingTask;
	BOOL			oldPower;
	double			queueCount;
    BOOL			verbose;
	BOOL		    doNotSkipPowerCheck;
	NSDictionary*   parameterDictionary;
    BOOL            firstPowerCheck;
}

#pragma mark ***Accessors
- (BOOL) verbose;
- (void) setVerbose:(BOOL)aVerbose;
- (BOOL) power;
- (void) initConnectionHistory;
- (void) clearHistory;
- (NSUInteger) connectionHistoryCount;
- (id) connectionHistoryItem:(NSUInteger)index;
- (NSUInteger) ipNumberIndex;
- (NSString*) IPNumber;
- (void) setIPNumber:(NSString*)aIPNumber;
- (int) systemParamAsInt:(NSString*)name;
- (id) systemParam:(NSString*)name;
- (void) togglePower;
- (void) setQueCount:(NSNumber*)n;
- (void) writeMaxTerminalVoltage;
- (void) writeMaxTemperature;
- (void) setSNMP:(int)aTag result:(NSString*)theResult;
- (NSDictionary*) parameterDictionary;
- (void) setParameterDictionary:(NSDictionary*)aParameterDictionary;
- (void) decodeWalk:(NSString*)theWalk;
- (void) taskFinished:(ORPingTask*)aTask;

#pragma mark ¥¥¥Hardware Access
- (void) ping;
- (BOOL) pingTaskRunning;
- (void) writeValue:(NSString*)aCmd target:(id)aTarget selector:(SEL)aSelector priority:(NSOperationQueuePriority)aPriority;
- (void) writeValue:(NSString*)aCmd target:(id)aTarget selector:(SEL)aSelector;
- (void) writeValues:(NSArray*)cmds target:(id)aTarget selector:(SEL)aSelector priority:(NSOperationQueuePriority)aPriority;
- (void) pollHardware;
- (void) pollHardwareAfterDelay;
- (void) callBackToTarget:(id)aTarget selector:(SEL)aSelector userInfo:(NSDictionary*)userInfo;

#pragma mark ¥¥¥Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORMPodCModelVerboseChanged;
extern NSString* ORMPodCModelCrateStatusChanged;
extern NSString* ORMPodCModelLock;
extern NSString* ORMPodCPingTask;
extern NSString* MPodCIPNumberChanged;
extern NSString* ORMPodCModelSystemParamsChanged;
extern NSString* MPodPowerFailedNotification;
extern NSString* MPodPowerRestoredNotification;
extern NSString* ORMPodCQueueCountChanged;

@interface NSObject (ORMpodCModel)
- (void) precessReadResponseArray:(NSArray*)response;
- (void) processSystemResponseArray:(NSArray*)response;

@end

//--------------------------------------------------
// ORSNMPWalkDecodeOp
// The decoding of the full SNMP walk is extensive. 
// Let a separate thread handle it.
//--------------------------------------------------
@interface ORSNMPWalkDecodeOp : NSOperation
{
	id					 delegate;
    NSString*			 theWalk;
	NSMutableDictionary* dictionaryFromWalk;
}
- (id) initWithWalk:(NSString*)theWalk delegate:(id)aDelegate;
- (void) main;
- (void)decodeValueArray:(NSArray*)parts;
- (void) decode:(NSString*)aName value:(NSString*)aValue;
- (NSDictionary*) decodeValue:(NSString*)aValue name:(NSString*)aName;
- (NSDictionary*) decodeFloat:(NSString*)aValue;
- (NSDictionary*) decodeInteger:(NSString*)aValue;
- (NSDictionary*) decodeBits:(NSString*)aValue name:(NSString*)aName;
- (NSDictionary*) decodeString:(NSString*)aValue name:(NSString*)aName;
@end

@interface NSObject (ORSNMPOps)
- (void) setSNMP:(int)aTag result:(NSString*)theResult;
- (void) setParameterDictionary:(NSDictionary*)aParameterDictionary;
@end;

