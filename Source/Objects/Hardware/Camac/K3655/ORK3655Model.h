/*
 *  ORK3655Model.h
 *  Orca
 *
 *  Created by Mark Howe on Sat Nov 16 2002.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
 *
 */
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
#import "ORCamacIOCard.h"
#import "ORDataTaker.h"
#import "ORHWWizard.h"

#pragma mark ¥¥¥Forward Declarations
@class ORDataPacket;

@interface ORK3655Model : ORCamacIOCard <ORHWWizard>{
    @private
		NSMutableArray* setPoints;
		BOOL continous;
		int numChansToUse;
		int clockFreq;
		int pulseNumberToClear;
		int pulseNumberToSet;
		BOOL useExtClock;
		BOOL inhibitEnabled;
}

#pragma mark ¥¥¥Initialization
- (id) init;
- (void) dealloc;

#pragma mark ¥¥¥Notifications
- (void)registerNotificationObservers;
- (void) runStopped:(NSNotification*)aNote;
- (void) runStarted:(NSNotification*)aNote;
- (void) runAboutToStart:(NSNotification*)aNote;
       
#pragma mark ¥¥¥Accessors
- (BOOL) inhibitEnabled;
- (void) setInhibitEnabled:(BOOL)aUseExtClock;
- (BOOL) useExtClock;
- (void) setUseExtClock:(BOOL)aUseExtClock;
- (int) pulseNumberToSet;
- (void) setPulseNumberToSet:(int)aPulseNumberToSet;
- (int) pulseNumberToClear;
- (void) setPulseNumberToClear:(int)aPulseNumberToClear;
- (int) clockFreq;
- (void) setClockFreq:(int)aClockFreq;
- (int) numChansToUse;
- (void) setNumChansToUse:(int)aNumChansToUse;
- (BOOL) continous;
- (void) setContinous:(BOOL)aContinous;
- (NSMutableArray*) setPoints;
- (void) setSetPoints:(NSMutableArray*)aSetPoints;
- (void) setSetPoint:(unsigned short) aChan withValue:(unsigned short) aValue;
- (unsigned short) setPoint:(unsigned short) aChan;

#pragma mark ¥¥¥Hardware functions
- (void) initBoard;
- (void) testLAM;
- (void) clearLAM;
- (void) readSetPoints;

#pragma mark ¥¥¥HW Wizard
- (NSArray*) wizardSelections;
- (NSArray*) wizardParameters;
- (int) numberOfChannels;
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel;

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;

@end

extern NSString* ORK3655UseExtClockChanged;
extern NSString* ORK3655PulseNumberToSetChanged;
extern NSString* ORK3655PulseNumberToClearChanged;
extern NSString* ORK3655ClockFreqChanged;
extern NSString* ORK3655NumChansToUseChanged;
extern NSString* ORK3655ContinousChanged;
extern NSString* ORK3655SettingsLock;
extern NSString* ORK3655SetPointChangedNotification;
extern NSString* ORK3655SetPointsChangedNotification;
extern NSString* ORK3655InhibitEnabledChanged;
extern NSString* ORK3655Chan;
