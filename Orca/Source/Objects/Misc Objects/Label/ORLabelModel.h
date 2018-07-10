//
//  ORContainerModel.h
//  Orca
//
//  Created by Mark Howe on Sat Nov 19 2005.
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
@class TimedWorker;

#define kStaticLabel  0
#define kDynamicLabel 1

@interface ORLabelModel : OrcaObject  
{
	NSString*		label;
	NSMutableArray* displayValues;
	NSString*   displayFormat;
    int			textSize;
	TimedWorker*    poller;
	BOOL scheduledForUpdate;
	int labelType;
	int updateInterval;
    NSString* controllerString;
}

- (void) setUpImage;

#pragma mark ***Accessors
- (NSString*) controllerString;
- (void) setControllerString:(NSString*)aControllerString;
- (int) textSize;
- (void) setTextSize:(int)aTextSize;
- (NSString*) displayFormat;
- (void) setDisplayFormat:(NSString*)aLabel;
- (NSString*) label;
- (void) setLabel:(NSString*)aLabel;
- (int) compareStringTo:(id)anElement usingKey:(NSString*)aKey;
- (void) setLabelNoNotify:(NSString*)aLabel;
- (void) setFormatNoNotify:(NSString*)aFormat;
- (int) labelType;
- (void) setLabelType:(int)aType;
- (int) updateInterval;
- (void) setUpdateInterval:(int) anInterval;
//supplied so that labels can be handled by the process machinery.
- (NSString*) elementName;
- (NSString*) fullHwName;
- (int) state;
- (NSString*) comment;
- (void) setComment:(NSString*)aComment;
- (NSString*) description:(NSString*)prefix;
- (void) openAltDialog:(id)sender;
- (void) openMainDialog:(id)sender;
- (NSAttributedString*) stringToDisplay:(BOOL)highlight;

#pragma mark ***Polling
- (TimedWorker *) poller;
- (void) setPoller: (TimedWorker *) aPoller;
- (void) setPollingInterval:(float)anInterval;
- (void) makePoller:(float)anInterval;
- (void) updateValue;

#pragma mark ¥¥¥Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORLabelModelControllerStringChanged;
extern NSString* ORLabelModelUpdateIntervalChanged;
extern NSString* ORLabelModelTextSizeChanged;
extern NSString* ORLabelModelLabelChangedNotification;
extern NSString* ORLabelLock;
extern NSString* ORLabelPollRateChanged;
extern NSString* ORLabelModelLabelTypeChanged;
extern NSString* ORLabelModelFormatChanged;

