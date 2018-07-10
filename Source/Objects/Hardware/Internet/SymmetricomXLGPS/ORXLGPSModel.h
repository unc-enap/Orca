//
//  ORXLGPSModel.h
//  Orca
//
//  Created by Jarek Kaspar on November 2, 2010.
//  Copyright (c) 2010 CENPA, University of Washington. All rights reserved.
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
@class NetSocket;
@class ORPingTask;

@interface ORXLGPSModel : OrcaObject
{
	NSMutableArray*		connectionHistory;
	NSUInteger		IPNumberIndex;
	NSString*		IPNumber;
	NSString*		userName;
	NSString*		password;
	NSUInteger		timeOut;
	ORPingTask*		pingTask;
	NetSocket*		socket;
	NSMutableString*	gpsInBuffer;
	BOOL			isConnected;
	BOOL			isLoggedIn;
	NSDate*			dateToDisconnect;
	NSMutableDictionary*	gpsOpsRunning;
	NSString*		command;
	NSString*		ppoCommand;
	NSDate*			ppoTime;
	NSUInteger		ppoTimeOffset;
	NSUInteger		ppoPulseWidth;
	NSUInteger		ppoPulsePeriod;
	BOOL			ppoRepeats;
	BOOL			isPpo;
	NSString*		ppsCommand;
	NSMutableDictionary*	processDict;
	NSString*		postLoginSel;
	NSString*		postLoginCmd;
	NSTimer*		gpsTimer;
}

#pragma mark •••Initialization
- (id)   init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;
- (void) wakeUp;
- (void) sleep;
- (void) initConnectionHistory;

#pragma mark •••Accessors
@property (copy)	NSString*		IPNumber;
@property (assign)	NSUInteger		IPNumberIndex;
@property (copy)	NSString*		userName;
@property (copy)	NSString*		password;
@property (assign)	NSUInteger		timeOut;
@property (retain)	NetSocket*		socket;
@property (assign)	BOOL			isConnected;
@property (assign)	BOOL			isLoggedIn;
@property (copy)	NSDate*			dateToDisconnect;
@property (copy)	NSString*		command;
@property (copy)	NSString*		ppoCommand;
@property (assign)	BOOL			isPpo;
@property (copy)	NSString*		ppsCommand;
@property (retain)	NSMutableDictionary*	processDict;
@property (copy)	NSString*		postLoginSel;
@property (copy)	NSString*		postLoginCmd;
@property (retain)	NSTimer*		gpsTimer;
@property (retain)	NSDate*			ppoTime;
@property (assign)	NSUInteger		ppoTimeOffset;
@property (assign)	NSUInteger		ppoPulseWidth;
@property (assign)	NSUInteger		ppoPulsePeriod;
@property (assign)	BOOL			ppoRepeats;

- (void) clearConnectionHistory;
- (NSUInteger) connectionHistoryCount;
- (id) connectionHistoryItem:(NSUInteger)index;
- (BOOL) gpsOpsRunningForKey:(id)aKey;
- (void) setGpsOpsRunning:(BOOL)aGpsOpsRunning forKey:(id)aKey;
- (void) updatePpoCommand;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

#pragma mark •••Hardware Access
- (void) connect;
- (void) disconnect;
- (void) test;
- (void) ping;
- (void) taskFinished:(ORPingTask*)aTask;
- (void) send;
- (void) send:(NSString*)aCommand; //ORCAScript helper
- (NSDate*) time;
- (BOOL) isLocked;
- (void) report;
- (void) satellites;
- (void) selfTest;
- (void) getPpo;
- (void) setPpo;
- (void) turnOffPpo;

@end

extern NSString* ORXLGPSModelLock;
extern NSString* ORXLGPSIPNumberChanged;
extern NSString* ORXLGPSModelUserNameChanged;
extern NSString* ORXLGPSModelPasswordChanged;
extern NSString* ORXLGPSModelTimeOutChanged;
extern NSString* ORXLGPSModelOpsRunningChanged;
extern NSString* ORXLGPSModelCommandChanged;
extern NSString* ORXLGPSModelPpoCommandChanged;
extern NSString* ORXLGPSModelPpsCommandChanged;
extern NSString* ORXLGPSModelIsPpoChanged;
extern NSString* ORXLGPSModelPpoTimeChanged;
extern NSString* ORXLGPSModelPpoTimeOffsetChanged;
extern NSString* ORXLGPSModelPpoPulseWidthChanged;
extern NSString* ORXLGPSModelPpoPulsePeriodChanged;
extern NSString* ORXLGPSModelPpoRepeatsChanged;
