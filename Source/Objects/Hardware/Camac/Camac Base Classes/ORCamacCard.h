//
//  ORCamacCard.h
//  Orca
//
//  Created by Mark Howe on Wed Dec 29 2004.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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



#import "ORCard.h"
#import "ORCamacCrateModel.h"

#define kCamacWriteAccess  0x1
#define kCamacReadAccess   0x0

#define isQbitSet(a) (((a)>>3) & 0x0001)
#define isXbitSet(a) (((a)>>2) & 0x0001)
#define isIbitSet(a) (((a)>>1) & 0x0001)
#define isLAMbitSet(a)    ((a) & 0x0001)

#define nafGen(n,a,f)  ((f) | ((a)<<5) | ((n)<<9))

/* object definition */
@interface ORCamacCard : ORCard
{
    @protected
        BOOL 	cmdResponse; //Q
        BOOL 	cmdAccepted; //X
        BOOL 	inhibit;
        BOOL 	lookAtMe;
}

#pragma mark ¥¥¥initialization

#pragma mark ¥¥¥accessors
- (Class) guardianClass;
- (int) tagBase;
- (NSString*) cardSlotChangedNotification;
- (NSString*) identifier;
- (int)  stationNumber;
- (BOOL) cmdResponse;
- (void) setCmdResponse:(BOOL)aValue;
- (BOOL) cmdAccepted;
- (void) setCmdAccepted:(BOOL)aValue;
- (BOOL) inhibit;
- (void) setInhibit:(BOOL)aValue;
- (BOOL) lookAtMe;
- (void) setLookAtMe:(BOOL)aValue;
- (void) decodeStatus:(unsigned short)aStatusWord;

#pragma mark ¥¥¥archival
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;

@end

#pragma mark ¥¥¥Extern Definitions
extern NSString* ORCamacCardSlotChangedNotification;

