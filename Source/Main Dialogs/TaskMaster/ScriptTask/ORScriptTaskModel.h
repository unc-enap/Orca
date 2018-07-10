//-------------------------------------------------------------------------
//  ORScriptTaskModel.m
//
//  Created by Mark A. Howe on Tuesday 12/26/2006.
//  Copyright (c) 2006 CENPA, University of Washington. All rights reserved.
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

#pragma mark ***Imported Files
#import "ORBaseDecoder.h"
#import "ORScriptIDEModel.h"

@class ORScriptInterface;
@class ORDataPacket;
@class ORDataSet;

@interface ORScriptTaskModel : ORScriptIDEModel
{
	ORScriptInterface*		task;
	NSMutableDictionary*	externVariablePool;
}

#pragma mark ***Initialization
- (void) dealloc;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) runningChanged:(NSNotification*)aNote;

#pragma mark ***Data ID
- (void) taskDidStart:(NSNotification*)aNote;
- (void) taskDidFinish:(NSNotification*)aNote;

#pragma mark ***Script Methods
- (id) nextScriptConnector;
- (void) setMessage:(NSString*)aMessage;
- (void) sendMailTo:(NSString*)receipients cc:(NSString*)cc subject:(NSString*)subject content:(NSString*)theContent;
- (void) mailSent:(NSString*)to;
- (void) sendStatusLogTo:(NSString*)receipients cc:(NSString*)cc subject:(NSString*)subject;
- (void) sendStatusLogTo:(NSString*)receipients cc:(NSString*)cc subject:(NSString*)subject lastSeconds:(unsigned long)aDuration;
- (void) setExternalVariable:(id)aKey to:(id)aValue;
- (id) externalVariable:(id)aKey;

- (void) postNotificationName:(NSString*)aName;
- (void) postNotificationName:(NSString*)aName   fromObject:(id)anObject;
- (void) postNotificationName:(NSString*)aName   fromObject:(id)anObject userInfo:(NSDictionary*)userInfo;
- (void) runOnNotificationName:(NSString*)aName  fromObject:(id)anObject;
- (void) stopOnNotificationName:(NSString*)aName fromObject:(id)anObject;
- (void) cancelNotificationName:(NSString*)aName;
- (void) runFromNotification:(NSNotification*)aNote;
- (void) stopFromNotification:(NSNotification*)aNote;

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORScriptTaskModelShowSuperClassChanged;
extern NSString* ORScriptTaskScriptChanged;
extern NSString* ORScriptTaskNameChanged;
extern NSString* ORScriptTaskArgsChanged;
extern NSString* ORScriptTaskLastFileChangedChanged;


