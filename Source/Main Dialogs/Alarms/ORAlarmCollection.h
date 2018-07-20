//
//  ORAlarmCollection.h
//  Orca
//
//  Created by Mark Howe on Fri Jan 17 2003.
//  Copyright © 2003 CENPA, University of Washington. All rights reserved.
//
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

#pragma mark •••Forward Declarations
@class ORAlarmController;
@class ORAlarmEMailDestination;

@interface ORAlarmCollection : NSObject {
	NSMutableArray* alarms;
	NSTimer*		beepTimer;
    NSMutableArray* eMailList;
    BOOL			emailEnabled;
}

+ (ORAlarmCollection*) sharedAlarmCollection;

#pragma mark •••Accessors
- (BOOL) emailEnabled;
- (void) setEmailEnabled:(BOOL)aEmailEnabled;
- (NSMutableArray*) eMailList;
- (void) setEMailList:(NSMutableArray*)aEMailList;
- (NSMutableArray*) alarms;
- (NSUInteger) alarmCount;
- (void) setAlarms:(NSMutableArray*)someAlarms;
- (NSTimer*) beepTimer;
- (void) setBeepTimer:(NSTimer*)aTimer;
- (NSEnumerator*) alarmEnumerator;
- (ORAlarm*) objectAtIndex:(NSUInteger)index;
- (void) drawBadge;

#pragma mark •••Notifications
- (void) registerNotificationObservers;

#pragma mark •••Alarm ManagementB
- (void) postAGlobalNotification;
- (void) alarmWasPosted:(NSNotification*)aNotification;
- (void) alarmWasCleared:(NSNotification*)aNotification;
- (void) alarmWasAcknowledged:(NSNotification*)aNotification;
- (void) beep:(NSTimer*)aTimer;

- (void) addAlarm:(ORAlarm*)anAlarm;
- (void) removeAlarm:(ORAlarm*)anAlarm;
- (void) removeAlarmWithName:(NSString*)aName;

#pragma mark •••EMail Management
- (void) removeAllAddresses;
- (NSUInteger) eMailCount;
- (void) decodeEMailList:(NSCoder*) aDecoder;
- (void) encodeEMailList:(NSCoder*) anEncoder;
- (void) addAddress:(NSString*)anAddress severityMask:(uint32_t)aMask;
- (void) addAddress;
- (void) addAddress:(id)anAddress atIndex:(NSUInteger)anIndex;
- (void) removeAddressAtIndex:(NSUInteger) anIndex;
- (ORAlarmEMailDestination*) addressAtIndex:(NSUInteger)anIndex;
@end

extern NSString* ORAlarmCollectionEmailEnabledChanged;
extern NSString* ORAlarmCollectionAddressAdded;
extern NSString* ORAlarmCollectionAddressRemoved;
extern NSString* ORAlarmCollectionReloadAddressList;

//--------------------------------------------------------------
//--------------------------------------------------------------
//--------------------------------------------------------------

@interface ORAlarmEMailDestination : NSObject
{
	NSString* mailAddress;
	uint32_t severityMask;
	NSMutableArray* alarms;
	BOOL			eMailThreadRunning;
	NSLock*			eMailLock;
	NSString*       hostAddress;
}

- (id) init;
- (void) dealloc;
- (void) setMailAddress:(NSString*)anAddress;
- (NSString*) mailAddress;
- (BOOL) wantsAlarmSeverity:(AlarmSeverityTypes)aType;
- (void) setSeverityMask:(uint32_t)aMask;
- (uint32_t) severityMask;
- (NSMutableArray*) alarms;
- (void) setAlarms:(NSMutableArray*)someAlarms;
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

#pragma mark •••Notifications
- (void) registerNotificationObservers;

#pragma mark •••Alarm Management
- (void) alarmWasPosted:(NSNotification*)aNotification;
- (void) alarmWasCleared:(NSNotification*)aNotification;
- (void) alarmWasChanged:(NSNotification*)aNotification;
- (void) eMailThread;
- (void) mailSent:(NSString*)address;

@end

extern NSString* ORAlarmEMailListEdited;
extern NSString* ORAlarmSeveritySelectionChanged;
extern NSString* ORAlarmAddressChanged;
extern NSString* ORAlarmAddedToCollection;
extern NSString* ORAlarmRemovedFromCollection;
