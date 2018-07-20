//
//  ORProcessElementModel.h
//  Orca
//
//  Created by Mark Howe on 11/19/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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
#import <OrcaObject.h>

@class ORProcessResult;

@interface ORProcessElementModel : OrcaObject {
    @protected
        BOOL        alreadyEvaluated;
		int			evaluatedState;

		NSImage* 	altImage;
		NSImage* 	highlightedAltImage;
		NSRect 		altFrame;
		NSRect 		altBounds;
		NSPoint 	altOffset;
		BOOL		useAltView;
		uint32_t processID;
	@private
        int         state;
        NSString*   comment;
		BOOL		partOfRun;
}

#pragma mark ¥¥¥Inialization
- (id) init;
- (void) dealloc;
- (void) setUpNubs;
- (void) awakeAfterDocumentLoaded;
- (BOOL) canBeInAltView;

#pragma mark ¥¥¥Accessors
- (uint32_t) processID;
- (void) setProcessID:(uint32_t)aValue;
- (NSImage*) altImage;
- (BOOL) useAltView;
- (void) setUseAltView:(BOOL)aState;
- (NSString*) description:(NSString*)prefix;
- (NSString*) elementName;
- (NSString*)comment;
- (NSString*) shortName;
- (void) setComment:(NSString*)aComment;
- (id) stateValue;
- (void) setState:(int)value;
- (int) state;
- (void) setEvaluatedState:(int)value;
- (int) evaluatedState;
- (Class) guardianClass ;
- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian;
- (BOOL) canImageChangeWithState;
- (int) compareStringTo:(id)anElement usingKey:(NSString*)aKey;
- (BOOL) partOfRun;
- (NSString*) iconValue;
- (NSString*) iconLabel;
- (NSAttributedString*) iconValueWithSize:(int)theSize color:(NSColor*) textColor;
- (NSAttributedString*) iconLabelWithSize:(int)theSize color:(NSColor*) textColor;
- (NSAttributedString*) idLabelWithSize:(int)theSize color:(NSColor*) textColor;

#pragma mark ¥¥¥Thread Related
- (void) clearAlreadyEvaluatedFlag;
- (BOOL) alreadyEvaluated;
- (void) postStateChange;
- (void) processIsStarting;
- (void) processIsStopping;
- (id) eval;

#pragma mark ¥¥¥Archiving
- (id)initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORProcessElementStateChangedNotification;
extern NSString* ORProcessCommentChangedNotification;
extern NSString* ORProcessElementForceUpdateNotification;

@interface ORProcessResult : NSObject
{
	BOOL boolValue;
	float  analogValue;
}

+ (id) processState:(BOOL)aState value:(float)aValue;
@property (assign) BOOL boolValue;
@property (assign) float analogValue;

@end
