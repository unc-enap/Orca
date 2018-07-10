//
//  ORTcpIpProtocol.h
//  Orca
//
//  Created by Michael Marino on Thurs Nov 10 2011.
//  Copyright � 2002 CENPA, University of Washington. All rights reserved.
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


//------------------------------------------------------------
// a formal protocol for objects that communicate via TCP/IP 
//------------------------------------------------------------
@class NetSocket;
@protocol ORTcpIpProtocol
@property (retain) NetSocket* socket;
@property (retain) NSString* ipAddress;
@property NSUInteger port;
- (BOOL) isConnected;
- (void) connect;
- (void) write:(NSString*)data;
- (int) read:(void*)data maxLengthInBytes:(NSUInteger)len;
//- (void) setDelegate:(id)delegate;
@end
