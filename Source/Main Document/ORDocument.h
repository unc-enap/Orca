//
//  ORDocument.h
//  Orca
//
//  Created by Mark Howe on Tue Dec 03 2002.
//  Copyright  © 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark ¥¥¥Forward Declarations
@class ORGroup;
@class ORStatusController;
@class ORDocumentController;
@class OrcaObjectController;
@class OrcaObject;


@interface ORDocument : NSDocument
{
    @private
        ORGroup*	    group;
        NSString*	    statusText;
        NSMutableArray* orcaControllers;
        int				scaleFactor;
		SEL				afterSaveSelector;
		id				afterSaveTarget;
        NSMutableDictionary* customRunParameters;
}

#pragma mark ¥¥¥Initializations

#pragma mark ¥¥¥Assessors
- (int)scaleFactor;
- (void)setScaleFactor:(int)aScaleFactor;

- (NSString*) statusText;
- (void) setStatusText:(NSString*)aName;

- (ORGroup*) group;
- (void) setGroup:(ORGroup*)aGroup;

- (NSMutableArray*) orcaControllers;
- (void) setOrcaControllers:(NSMutableArray*)newOrcaControllers;
- (BOOL) documentCanBeChanged;

- (NSArray*) collectObjectsWithClassName:(NSString*)aClassName;
- (NSArray*) collectObjectsOfClass:(Class)aClass;
- (NSArray*) collectObjectsConformingTo:(Protocol*)aProtocol;
- (NSArray*) collectObjectsRespondingTo:(SEL)aSelector;
- (id)       findObjectWithFullID:(NSString*)aFullID;
- (NSMutableDictionary*) fillInHeaderInfo:(NSMutableDictionary*)dictionary;
- (void) assignUniqueIDNumber:(id)anObject;
- (void) resetAlreadyVisitedInChainSearch;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
- (void) addCustomRunParameters:(id)anObject forKey:(NSString*)aKey;

#pragma mark ¥¥¥Orca Dialog Management
- (void)    duplicateDialog:(id)dialog;
- (void)    makeController:(NSString*)className forObject:(id)aModel;
- (void) makeControllerPDF:(NSString*)aClassName forObject:(id)aModel;
- (NSArray*)findControllersWithModel:(id)aModel;

- (void)    objectsRemoved:(NSNotification*)aNote;
- (void)    windowClosing:(NSNotification*)aNote;

- (void)    copyDocumentTo:(NSString*)aPath append:(NSString*)aString;
- (void)    saveDefaultFileName;
- (void)    windowMovedToFront:(NSWindowController*)aController;
- (void)    checkControllers;
- (NSArray*) controllersToSave;
- (void)	saveFinished;
- (void)	afterSaveDo:(SEL)aSelector withTarget:(id)aTarget;
- (void)	closeAllWindows;
- (void) makePDFFromController:(id)aController;

@end

@interface NSObject (ORDocument)
- (void) addObjectInfoToArray:(NSMutableArray*)anArray;
@end

#pragma mark ¥¥¥External Definitions
extern NSString* ORStatusTextChangedNotification;
extern NSString* ORDocumentLoadedNotification;
extern NSString* ORDocumentScaleChangedNotification;
extern NSString* ORDocumentClosedNotification;
extern NSString* ORDocumentLock;

