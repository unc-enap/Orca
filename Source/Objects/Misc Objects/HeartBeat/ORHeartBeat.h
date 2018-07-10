//
//  ORHeartBeat.h
//  Orca
//
//  Created by Mark Howe on Fri Jan 09 2004.
//  Copyright (c) 2004 CENPA,University of Washington. All rights reserved.
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




@class ORAlarm;

@interface ORHeartBeat : NSObject {
    NSMutableDictionary* clients;
}
+ (ORHeartBeat*) sharedHeartBeat;
- (void)dealloc;
- (NSMutableDictionary *)clients;
- (void)setClients:(NSMutableDictionary *)aClients;
- (void)pulse:(NSString*)client nextTime:(int)aNextTime;
- (NSString*)   commandID;

@end

//------------------------------------------------------------------

@interface ORHeartBeatClient : NSObject {
    NSTimer* watchTimer;
    ORAlarm* timeOutAlarm;
    NSString* name;
}
- (id) initWithTimeOut:(int)aTime name:(NSString*)aName;
- (NSTimer *)watchTimer;
- (void)setWatchTimer:(NSTimer *)aWatchTimer;
- (NSString *)name;
- (void)setName:(NSString *)aName;
- (void) pulse:(int)aNextTime;
- (void) timeOut:(NSTimer*)aTimer;
- (void) runStatusChanged:(NSNotification*)aNotification;
- (void) documentClosed:(NSNotification*)aNotification;


@end
