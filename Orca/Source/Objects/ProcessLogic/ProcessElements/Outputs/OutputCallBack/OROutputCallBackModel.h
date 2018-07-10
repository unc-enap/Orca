//
//  OROutputCallBackModel.h
//  Orca
//
//  Created by Mark Howe on Mon April 9.
//  Copyright (c) 2012 University of Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Carolina  sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Carolina reserve all rights in the program. Neither the authors,
//University of Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark •••Imported Files
#import "OROutputRelayModel.h"

@interface OROutputCallBackModel :  OROutputRelayModel 
{
    NSString* callBackName;
    id  callBackObject;
    int callBackChannel;
	NSString* callBackCustomLabel;
	int  callBackLabelType;
}

#pragma mark •••Initialization
- (void) makeMainController;

- (NSString*) callBackName;
- (void) setCallBackName:(NSString*) anObject;
- (id) callBackObject;
- (void) setCallBackObject:(id) anObject;
- (int) callBackChannel;
- (void) setCallBackChannel:(int)aChannel;
- (NSString*) callBackLabel;
- (NSArray*) validCallBackObjects;
- (void) viewCallBackSource;
- (void) useCallBackObjectWithName:(NSString*)aName;
- (NSAttributedString*) callBackLabelWithSize:(int)theSize color:(NSColor*) textColor;
- (int) callBackLabelType;
- (void) setCallBackLabelType:(int)aLabelType;
- (NSString*) callBackCustomLabel;
- (void) setCallBackCustomLabel:(NSString*)aCustomLabel;

@end

extern NSString* ORCallBackNameChangedNotification;
extern NSString* ORCallBackObjectChangedNotification;
extern NSString* ORCallBackChannelChangedNotification;
extern NSString* ORCallBackCustomLabelChanged;
extern NSString* ORCallBackLabelTypeChanged;

