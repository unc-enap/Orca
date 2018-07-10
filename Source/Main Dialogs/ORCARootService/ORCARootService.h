//
//  ORCARootService.h
//  Orca
//
//  Created by Mark Howe on Thu Nov 06 2003.
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


#pragma mark ¥¥¥Imported Files
#import "ORBaseDecoder.h"

#pragma mark ¥¥¥Forward Declarations
@class NetSocket;

#pragma mark ¥¥¥Definitions
#define kORCARootServicePort 9090
#define kORCARootServiceHost @"crunch4.npl.washington.edu"

@interface ORCARootService : NSObject
{
    int             socketPort;
	NSString*		hostName;
    NSString*		name;
    NetSocket*		socket;
	BOOL			isConnected;
    NSDate*         timeConnected;
    unsigned long	amountInBuffer;
    unsigned long	totalSent;
	unsigned long	dataId;
	int				requestTag;
	NSMutableDictionary* waitingObjects;
	NSMutableData*	dataBuffer;
	BOOL			autoReconnect;
	BOOL			connectAtStart;
	NSMutableArray* connectionHistory;
	NSUInteger 		hostNameIndex;
	BOOL			fitInFlight;
}

+ (ORCARootService*) sharedORCARootService;

- (NSUndoManager *)undoManager;
- (void) connectAtStartUp;
- (void) reConnect;

#pragma mark ¥¥¥Accessors
- (void) clearHistory;
- (NSArray*) connectionHistory;
- (NSString*) hostName;
- (NSUInteger) hostNameIndex;
- (void) setHostName:(NSString*)aName;
- (BOOL) autoReconnect;
- (void) setAutoReconnect:(BOOL)aAutoReconnect;
- (BOOL) connectAtStart;
- (void) setConnectAtStart:(BOOL)aConnectAtStart;
- (int) socketPort;
- (void) setSocketPort:(int)aPort;
- (NetSocket*) socket;
- (void) setSocket:(NetSocket*)aSocket;
- (NSString*) name;
- (void) setName:(NSString*)newName;
- (unsigned long long) totalSent;
- (void) setTotalSent:(unsigned long long)aTotalSent;
- (NSDate*) timeConnected;
- (void) setTimeConnected:(NSDate*)newTimeConnected;
- (unsigned long) amountInBuffer; 
- (void) setAmountInBuffer:(unsigned long)anAmountInBuffer; 
- (void) writeData:(NSData*)inData;
- (void) connectSocket:(BOOL)state;
- (BOOL) isConnected;
- (void) setIsConnected:(BOOL)aNewIsConnected;
- (void) broadcastConnectionStatus;
- (void) clearCounts;
- (void) setDataId: (unsigned long) aDataId;
- (unsigned long) dataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherObj;
- (NSDictionary*) dataRecordDescription;
- (void) cancelRequest:(NSNotification*)aNote;
- (void) requestNotification:(NSNotification*)aNote;
- (void) sendRequest:(NSMutableDictionary*)request fromObject:(id)anObject;
- (NSUInteger) connectionHistoryCount;
- (id) connectionHistoryItem:(NSUInteger)index;
- (void) clearFitInFlight;

#pragma mark ¥¥¥Delegate Methods
- (void) netsocketDisconnected:(NetSocket*)insocket;
- (void) netsocketDataInOutgoingBuffer:(NetSocket*)insocket length:(unsigned long)length;
- (void) netsocketDataSent:(NetSocket*)insocket length:(unsigned long)length;
@end

extern NSString* ORCARootServicePortChanged;
extern NSString* ORCARootServiceTimeConnectedChanged;
extern NSString* ORORCARootServiceLock;
extern NSString* ORORCARootServiceAutoReconnectChanged;
extern NSString* ORCARootServiceConnectAtStartChanged;
extern NSString* ORCARootServiceAutoReconnectChanged;
extern NSString* ORCARootServiceConnectionHistoryChanged;
extern NSString* ORCARootServiceConnectionHistoryIndexChanged;
extern NSString* ORCARootServiceHostNameChanged;


@interface NSObject (ORCARootService)
- (void) processResponse:(NSDictionary*)aResponse;
@end
