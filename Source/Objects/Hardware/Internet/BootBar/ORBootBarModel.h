//
//  ORBootBarModel.h
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

#pragma mark •••Imported Files
@class NetSocket;

@interface ORBootBarModel :  OrcaObject
{
	NSMutableArray*	connectionHistory;
	unsigned		ipNumberIndex;
	NSString*		IPNumber;
    BOOL			isConnected;
	NetSocket*		socket;
	NSMutableArray* cmdQueue;
	BOOL			outletStatus[9];
    NSString*		password;
    NSString*		pendingCmd;
	NSMutableArray* outletNames;
}

#pragma mark ***Accessors
- (NSString*) password;
- (void) setPassword:(NSString*)aPassword;
- (void) initConnectionHistory;
- (void) clearHistory;
- (NSUInteger) connectionHistoryCount;
- (id) connectionHistoryItem:(NSUInteger)index;
- (NSUInteger) ipNumberIndex;
- (NSString*) IPNumber;
- (void) setIPNumber:(NSString*)aIPNumber;
- (NetSocket*) socket;
- (void) setSocket:(NetSocket*)aSocket;
- (BOOL) isConnected;
- (void) setIsConnected:(BOOL)aFlag;
- (void) connect;
- (BOOL) outletStatus:(int)i;
- (void) setOutlet:(int)i status:(BOOL)aValue;
- (BOOL) isBusy;
- (NSString*) outletName:(int)index;
- (void) setOutlet:(int)index name:(NSString*)aName;

#pragma mark •••Hardware Access
- (void) pollHardware;
- (void) turnOnOutlet:(int)i;
- (void) turnOffOutlet:(int)i;
- (void) getStatus;

- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end


extern NSString* ORBootBarModelPasswordChanged;
extern NSString* ORBootBarModelLock;
extern NSString* BootBarIPNumberChanged;
extern NSString* ORBootBarModelIsConnectedChanged;
extern NSString* ORBootBarModelStatusChanged;
extern NSString* ORBootBarModelBusyChanged;
extern NSString* ORBootBarModelOutletNameChanged;

