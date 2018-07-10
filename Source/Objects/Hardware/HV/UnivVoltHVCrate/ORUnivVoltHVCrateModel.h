//
//  ORUnivVoltHVCrateModel.h
//  Orca
//
//  Created by Mark Howe on Fri Nov 22 2002.
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
#define kUnivVoltHVCratePort 1090
#define kUnivVoltHVAddress "192.168.1.10\0"

// Commands
enum hveCommands {eUVNoCommand = 0, eHVStatus, eUVConfig, eUVEnet};
typedef enum hveCommands hveCommands;

#pragma mark •••Forward Declarations
@class ORConnector;
@class NetSocket;
@class ORQueue;

@interface ORUnivVoltHVCrateModel : ORCrate  {
	NSLock*			localLock;
    NSString*		ipAddress;
	NSString*		mLastError;
    BOOL			mIsConnected;
	BOOL			mCmdQueueBlocked; // Prevents execution of two multi-cmd tasks simultaineously.
	NetSocket*		mSocket;
	ORQueue*		mCmdCmdQueue;
	ORQueue*		mRetQueue;
	NSDictionary*	mLastCmdIssued;
	NSDictionary*	mReturnToCrate;
	NSString*		mMostRecentConfig;
	NSString*		mMostRecentHVStatus;
	NSString*		mMostRecentEnetConfig;
	int				mCmdsToProcess;
	int				mRetsToProcess;
	int				mTotalCmds;
}

#pragma mark •••Accessors
- (NSString*) ipAddress;
- (NSString*) hvStatus;
//- (NSString*) hvOn;
//- (NSString*) hvOff;
//- (NSString*) hvPanic;
- (NSString*) ethernetConfig;
- (NSString*) config;
- (NetSocket*) socket;
//- (NSDictionary*) returnDataToHVUnit;

#pragma mark •••Notifications
//- (void) registerNotificationObservers;
- (void) setIpAddress: (NSString *) anIpAddress;
- (void) setSocket: (NetSocket*) aSocket;
- (BOOL) isConnected;
- (void) setIsConnected: (BOOL) aFlag;

#pragma mark ***Crate actions
- (void) handleDataReturn: (NSData*) someData;
- (void) handleCrateReturn: (NSString*) aCrateCmd retString: aRetString retTokens: aRetTokens;
- (void) obtainHVStatus;
- (void) obtainEthernetConfig;
- (void) obtainConfig;
- (void) turnHVOn;
- (void) turnHVOff;
- (void) hvPanic;
- (void) connect;
- (BOOL) queueCommand: (int) aCmdId 
			totalCmds: (int) aTotalCmds
				 slot: (int) aCurrentUnit 
			  channel: (int) aCurrentChnl
			  command: (NSString*) aCommand;
			  
- (void) sendCrateCommand: (NSString*) aCommand;


#pragma mark •••Utilities
- (void) dequeueAllReturns;
- (NSString*) interpretDataFromSocket: (NSData*) aDataObject returnCode: (int*) aReturnCode;
- (NSDictionary*) setupReturnDict: (NSNumber*) aSlotNum 
                          channel: (NSNumber*) aChnlNum 
				          command: (NSString*) aCommand 
			         returnString: (NSArray*) aRetTokens;

- (void) handleUnitReturn: (NSNumber *) aCmdId
				     slot: (NSNumber *) aRetSlot 
                  channel: (NSNumber *) aRetChnl 
				  command: (NSString *) aCommand 
				retTokens: (NSArray *) aTokens;
				
- (void) sendSingleCommand;
				
#pragma mark ***Archival
- (id)   initWithCoder: (NSCoder*) aDecoder;
- (void) encodeWithCoder: (NSCoder*) anEncoder;

@end



#pragma mark •••Notification string definitions.
extern NSString* HVCrateIsConnectedChangedNotification;
extern NSString* HVCrateIpAddressChangedNotification;
//extern NSString* ORUnivVoltHVCrateHVStatusChangedNotification;
extern NSString* HVCrateHVStatusAvailableNotification;
extern NSString* HVCrateConfigAvailableNotification;
extern NSString* HVCrateEnetAvailableNotification;
extern NSString* HVUnitInfoAvailableNotification ;
extern NSString* HVSocketNotConnectedNotification;
extern NSString* HVShortErrorNotification;
extern NSString* HVLongErrorNotification;

#pragma mark •••Constants for command queue dictionary entry and data return dictionary.
// Data return dictionary extern definitions.
extern NSString* UVkSlot;
extern NSString* UVkChnl;
extern NSString* UVkCommand;
extern NSString* UVkReturn;

extern NSString* HVkErrorMsg;



