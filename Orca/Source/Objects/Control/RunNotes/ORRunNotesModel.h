//
//  ORRunNotesModel.h
//  Orca
//
//  Created by Mark Howe on Tues Feb 09 2009.
//  Copyright (c) 2009 University of North Carolina. All rights reserved.
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
#import "ORSafeQueue.h"
#import "ORDataChainObject.h"

#pragma mark •••Forward Declarations
@class ORDataPacket;

@interface ORRunNotesModel : ORDataChainObject  {
	NSMutableArray* items;
	NSString*       comments;
    id              nextObject;     //cache for alittle bit more speed.
    BOOL            ignoreValues;
    BOOL            doNotOpen;
	BOOL            isModal;
	BOOL            modalResult;
    NSString*       definitionsFilePath;
 }

#pragma mark •••Accessors
- (NSString*) definitionsFilePath;
- (void) setDefinitionsFilePath:(NSString*)aDefinitionsFilePath;
- (BOOL) doNotOpen;
- (void) setDoNotOpen:(BOOL)aDoNotOpen;
- (BOOL) ignoreValues;
- (void) setIgnoreValues:(BOOL)aIgnoreValues;
- (void) removeItemAtIndex:(int) anIndex;
- (id) itemAtIndex:(int)anIndex;
- (unsigned long) itemCount;
- (NSString*) comments;
- (void) setComments:(NSString*)aString;
- (void) setCommentsNoNote:(NSString*)aString;
- (BOOL) isModal;
- (void) setIsModal:(BOOL)state;
- (void) cancelRun;
- (void) continueWithRun;

- (void) commonScriptMethodSectionBegin;
- (void) commonScriptMethodSectionEnd;

- (void) change:(id)aKey toValue:(id)aValue;
- (void) addObject:(id)anItem forKey:(id)aKey;
- (void) removeObjectWithKey:(id)aKey;
- (BOOL) readNamesFromFile;

#pragma mark •••Run Management
- (void) runTaskStarted:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(NSDictionary*)userInfo;
- (void) preCloseOut:(NSDictionary*)userInfo;
- (void) closeOutRun:(NSDictionary*)userInfo;
- (void) setRunMode:(int)runMode;

#pragma mark •••Save/Restore
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORRunNotesModelDefinitionsFilePathChanged;
extern NSString* ORRunNotesModelDoNotOpenChanged;
extern NSString* ORRunNotesModelIgnoreValuesChanged;
extern NSString* ORRunNotesListLock;
extern NSString* ORRunNotesCommentsChanged;
extern NSString* ORRunNotesModelModalChanged;
extern NSString* ORRunNotesItemsAdded;
extern NSString* ORRunNotesItemsRemoved;
extern NSString* ORRunNotesItemChanged;


