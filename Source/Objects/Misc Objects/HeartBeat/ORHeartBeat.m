//
//  ORHeartBeat.m
//  Orca
//
//  Created by Mark Howe on Fri Jan 09 2004.
//  Copyright (c) 2004  CENPA,University of Washington. All rights reserved.
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

#import "ORHeartBeat.h"
#import "SynthesizeSingleton.h"

@implementation ORHeartBeat

SYNTHESIZE_SINGLETON_FOR_ORCLASS(HeartBeat);

// ===========================================================
//  - dealloc:
// ===========================================================
- (void)dealloc
{
    [self setClients: nil];
	
    [super dealloc];
}

// ===========================================================
// - clients:
// ===========================================================
- (NSMutableDictionary *)clients
{
    return clients; 
}

// ===========================================================
// - setClients:
// ===========================================================
- (void)setClients:(NSMutableDictionary *)aClients
{
    [aClients retain];
    [clients release];
    clients = aClients;
}

- (void)pulse:(NSString*)aClient nextTime:(int)aNextTime
{
    
    if(!aClient)return;
    
    if(!clients){
		[self setClients:[NSMutableDictionary dictionary]];
    }
    aNextTime = aNextTime+(aNextTime*1.90);
    ORHeartBeatClient* theClient = [clients objectForKey:aClient];
    if(theClient){
		[theClient pulse:aNextTime];
		if(aNextTime == 0)[clients removeObjectForKey:aClient];
    }
    else {
		if(aNextTime != 0)[clients setObject:[[[ORHeartBeatClient alloc] initWithTimeOut:aNextTime name:aClient]autorelease] forKey:aClient];
    }
    
}
- (NSString*) commandID
{
    return @"HeartBeat";
}
@end


@implementation ORHeartBeatClient

- (id) initWithTimeOut:(int)aTime name:(NSString*)aName
{
    self = [super init];
    [self setWatchTimer: [NSTimer scheduledTimerWithTimeInterval:(float)aTime target:self selector:@selector(timeOut:) userInfo:nil repeats:NO]];
    if(!aName || ![aName length]){
		[self setName:@"Unknown client"];
    }
    else [self setName:aName];
	
    [[NSNotificationCenter defaultCenter] addObserver : self
											 selector : @selector(runStatusChanged:)
												 name : ORRunStatusChangedNotification
											   object : nil];
	
	
    [[NSNotificationCenter defaultCenter] addObserver : self
											 selector : @selector(documentClosed:)
												 name : ORDocumentClosedNotification
											   object : nil];
	
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [name release];
    
    [watchTimer invalidate];
    [watchTimer release];
	
    [timeOutAlarm clearAlarm];
    [timeOutAlarm release];
	
    [super dealloc];
}

// ===========================================================
// - name:
// ===========================================================
- (NSString *)name
{
    return name; 
}

// ===========================================================
// - setName:
// ===========================================================
- (void)setName:(NSString *)aName
{
    [name autorelease];
    name = [aName copy];
}

// ===========================================================
// - watchTimer:
// ===========================================================
- (NSTimer *)watchTimer
{
    return watchTimer; 
}

// ===========================================================
// - setWatchTimer:
// ===========================================================
- (void)setWatchTimer:(NSTimer *)aWatchTimer
{
    [aWatchTimer retain];
    [watchTimer release];
    watchTimer = aWatchTimer;
}

- (void) pulse:(int)aNextTime
{
    [watchTimer invalidate];
    [watchTimer release];
    watchTimer = nil;
    
    if(aNextTime){
		[self setWatchTimer: [NSTimer scheduledTimerWithTimeInterval:(float)aNextTime target:self selector:@selector(timeOut:) userInfo:nil repeats:NO]];
    }
    if(timeOutAlarm){
		[timeOutAlarm clearAlarm];
		[timeOutAlarm release];
		timeOutAlarm = nil;
		NSLog(@"%@ alive again!\n",name);
    }
}

- (void) timeOut:(NSTimer*)aTimer
{
    if(!timeOutAlarm && [[ORGlobal sharedGlobal] runInProgress]){
		timeOutAlarm = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"%@ dead!",name] severity:kInformationAlarm];
		[timeOutAlarm setSticky:YES];
		[timeOutAlarm setAcknowledged:NO];
		[timeOutAlarm postAlarm];
		NSLog(@"%@ not sending heartbeat, assumed dead!\n",name);
	} 
}

- (void) documentClosed:(NSNotification*)aNotification
{
    [watchTimer invalidate];
    [watchTimer release];
    watchTimer = nil;
	
    [timeOutAlarm clearAlarm];
    [timeOutAlarm release];
    timeOutAlarm = nil;
}

- (void) runStatusChanged:(NSNotification*)aNotification
{
    if(![[ORGlobal sharedGlobal] runInProgress]){
		[watchTimer invalidate];
		[watchTimer release];
		watchTimer = nil;
		
		if(timeOutAlarm){
			[timeOutAlarm clearAlarm];
			[timeOutAlarm release];
			timeOutAlarm = nil;
		}
    }
}


@end
