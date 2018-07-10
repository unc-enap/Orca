//
//  ORAlarm.h
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
#import <Foundation/Foundation.h>

//alarm types arranged roughly in order of serverity. 
//they will be sorted according to serverity in the alarm window.
typedef enum {
	kInformationAlarm,		//generally minor. default
	kSetupAlarm,			//hardware not setup 
	kRangeAlarm,			//out of range 
	kHardwareAlarm,			//i.e. power failure, unable to reach hw, etc.
	kRunInhibitorAlarm,		//run will be inhibited or halted
	kDataFlowAlarm,			//something wrong with data flow
	kImportantAlarm,		//requires intervention
	kEmergencyAlarm,		//serious problem
	kNumAlarmSeverityTypes	//must be last
} AlarmSeverityTypes;

typedef enum AlarmEmailDelayTime {
    k10SecDelay = 10,
    k30SecDelay = 30,
    k60SecDelay = 60,
}AlarmEmailDelayTime;

@interface ORAlarm : NSObject {
	NSDate*         timePosted;
	NSString*		name;
	int				severity;
	NSString*		helpString;
	BOOL 			acknowledged;
	BOOL			sticky;
	BOOL			isPosted;
	NSString*		additionalInfoString;
    AlarmEmailDelayTime             mailDelay;
}

#pragma mark •••Initialization
+ (NSString*) alarmSeverityName:(int) i;
- (id) initWithName:(NSString*)aName severity:(AlarmSeverityTypes)aSeverity;

#pragma mark •••Accessors
- (void) setIsPosted:(BOOL)state;
- (BOOL) isPosted;
- (NSString*) genericHelpString;

- (NSString*) additionalInfoString;
- (void) setAdditionalInfoString:(NSString*)aName;
- (int) mailDelay;
- (void) setMailDelay:(int)aTime;

- (NSString*) timePosted;
- (NSString*) timePostedUTC;
- (void) setTimePosted:(NSDate*)aDate;
- (NSTimeInterval) timeSincePosted;
- (NSString*) name;
- (void) setName:(NSString*)aName;
- (NSString*) severityName;
- (int) severity;
- (void) setSeverity:(int)aValue;
- (void) setHelpString:(NSString*)aString;
- (NSString*) helpString;
- (NSString*) acknowledgedString;
- (BOOL) acknowledged;
- (void) setAcknowledged:(BOOL)aState;
- (void) setSticky:(BOOL)aState;
- (BOOL) sticky;
- (NSString*) alarmWasAcknowledged;

- (void) setHelpStringFromFile:(NSString*)fileName;
- (NSDictionary*) alarmInfo;

#pragma mark •••Alarm Management
- (void) postAlarm;
- (void) clearAlarm;
- (void) acknowledge;

@end

extern NSString* ORAlarmWasPostedNotification;
extern NSString* ORAlarmWasClearedNotification;
extern NSString* ORAlarmWasAcknowledgedNotification;
extern NSString* ORAlarmWasChangedNotification;

