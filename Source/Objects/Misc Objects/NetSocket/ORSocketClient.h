//
//  ORSocketClient.h
//  Orca
//
//  Created by Mark Howe on 11/10/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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

@class NetSocket;

@interface ORSocketClient : NSObject {
    NSString*		name;
    id				delegate;
    NetSocket*		socket;
    NSDate*			timeConnected;
    uint32_t	amountInBuffer;
    uint64_t	totalSent;
    int             socketStatus;
}

#pragma mark •••Inialization
- (id) initWithNetSocket:(NetSocket*)insocket;
- (void) dealloc;
- (id) delegate;
- (void) setDelegate:(id)newDelegate;
- (NSString*) name;
- (void) setName:(NSString*)newName;
- (uint64_t) totalSent;
- (void) setTotalSent:(uint64_t)aTotalSent;
- (NetSocket*) socket;
- (NSDate*) timeConnected;
- (void) setTimeConnected:(NSDate*)newTimeConnected;
- (uint32_t) amountInBuffer; 
- (void) setAmountInBuffer:(uint32_t)anAmountInBuffer; 
- (void) writeData:(NSData*)inData;
- (void) netsocketDisconnected:(NetSocket*)insocket;
- (void) netsocketDataInOutgoingBuffer:(NetSocket*)insocket length:(uint32_t)length;
- (BOOL) isConnected;
- (void) clearCounts;
- (void) netsocketDataSent:(NetSocket*)insocket length:(uint32_t)length;
- (int) socketStatus;
@end

@interface NSObject (ORSocketClient_Catagory)
- (void) clientDisconnected:(id)aClient;
- (void) clientChanged:(id)aClient;
- (void) clientDataChanged:(id)aClient;

@end
