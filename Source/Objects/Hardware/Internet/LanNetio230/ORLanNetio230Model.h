//
//  ORLanNetio230Model.h
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

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Imported Files
@class NetSocket;

#define kLanNetio230OutletNum 4
#define kLanNetioTimeoutInterval 5.0
#define kStatusRequest 0
#define kWriteRequest 1


@interface ORLanNetio230Model :  OrcaObject
{
	NSMutableArray*	connectionHistory;
	unsigned		ipNumberIndex;
	NSString*		IPNumber;
    BOOL			isConnected;
	NetSocket*		socket;
	NSMutableArray* cmdQueue;
	BOOL			outletStatus[kLanNetio230OutletNum+1];//I use index 1...4 (index 0 unused) - I took this from BootBar -tb- 2013
    NSString*		password;
    NSString*		pendingCmd;
	NSMutableArray* outletNames;
    
    //http request
   	NSURLConnection*	theURLConnection;
	NSMutableData*		receivedData;
	int				    requestType;

}

#pragma mark *** Accessors
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

#pragma mark *** Hardware Access
- (void) pollHardware;
- (int) curlSetLanNetIOStatus:(int) i toState:(int) on;
- (void) turnOnOutlet:(int)i;
- (void) turnOffOutlet:(int)i;
- (void) getStatus;

- (void) readStatus;
- (void) sendRequestString:(NSString*)requestString;




#pragma mark *** Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;



#pragma mark ***Delegate Methods for connection
- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void) connection:(NSURLConnection *)connection  didFailWithError:(NSError *)error;
- (void) connectionDidFinishLoading:(NSURLConnection *)connection;



@end


extern NSString* ORLanNetio230ModelPasswordChanged;
extern NSString* ORLanNetio230ModelLock;
extern NSString* LanNetio230IPNumberChanged;
extern NSString* ORLanNetio230ModelIsConnectedChanged;
extern NSString* ORLanNetio230ModelStatusChanged;
extern NSString* ORLanNetio230ModelBusyChanged;
extern NSString* ORLanNetio230ModelOutletNameChanged;

