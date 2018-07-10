//
//  NcdDetector.h
//  Orca
//
//  Created by Mark Howe on Thu Sep 04 2003.
//  Copyright (c) 2003 CENPA, Unvsersity of Washington. All rights reserved.
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


@class ORColorScale;
@class ORTimeRate;
@class ORDataPacket;
@class NcdTube;

@interface NcdDetector : NSObject 
{
    NSMutableArray* tubes;
    NSArray*	    shaperCards;
    NSArray*	    muxBoxes;
    ORTimeRate*     shaperTotalRate;
    ORTimeRate*     muxTotalRate;
    NSString*       mapFileName;

    id              delegate;
    short           chanMap[8][2]; //[numMux][numScopes]

    NSString *_sortColumn;
    BOOL _sortIsDescending;
    float shaperRate;
    float muxRate;
    NSMutableArray* muxMementos;
}

#pragma mark ¥¥¥Initialization
+ (id) 		sharedInstance;
- (id) 		init;
- (void) unregisterRates;
- (void) collectTotalShaperRate;
- (void) collectTotalMuxRate;
- (void) readMap;

#pragma mark ¥¥¥Accessors
- (NSUndoManager*) undoManager;
- (NSString *) mapFileName;
- (void) setMapFileName: (NSString *) aMapFileName;
- (NSMutableArray*) tubes;
- (void) setTubes:(NSMutableArray*)newTubes;
- (NcdTube*) tube:(int)index;
- (int) numberOfTubes;
- (ORTimeRate*) shaperTotalRate;
- (void) setShaperTotalRate:(ORTimeRate*)newShaperTotalRate;
- (ORTimeRate*) muxTotalRate;
- (void) setMuxTotalRate:(ORTimeRate*)newMuxTotalRate;
- (void) setDelegate:(id)aDelegate;
- (NSArray *)shaperCards;
- (void)setShaperCards:(NSArray *)aShaperCards;
- (NSArray *)muxBoxes;
- (void)setMuxBoxes:(NSArray *)aMuxBoxes;

- (void) drawInRect:(NSRect)aRect withColorBar:(ORColorScale*)rateColorBar;
- (void) registerForShaperRates:(NSArray*)collectionOfShapers;
- (void) registerForMuxRates:(NSArray*)collectionOfMuxes;
- (void) reloadData:(id)obj;
- (short) getScopeChannelForMux:(short) mux scope:(short) scope;
- (void) saveMapFileAs:(NSString*)newFileName;

- (id)loadWithCoder:(NSCoder*)decoder;
- (void)saveWithCoder:(NSCoder*)encoder;

- (void) removeTubeAtIndex:(int)index;
- (void) addTube:(NcdTube*)aTube atIndex:(int)index;
- (float) shaperRate;
- (float) muxRate;

- (void)setSortColumn:(NSString *)identifier;
- (NSString *)sortColumn;
- (void)setSortIsDescending:(BOOL)whichWay;
- (BOOL)sortIsDescending;
- (void) sort;
- (void) configurationChanged;
- (void) handleMouseDownAt:(NSPoint)localPoint inView:(NSView*)detectorView;

#pragma mark ¥¥¥Run Data
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
- (void) replaceMuxThresholdsUsingFile:(NSString*)path;
- (void) restoreMuxMementos;
- (void) saveMuxMementos;
- (void) saveMuxMementos:(NSMutableArray*)anArray;
- (void) restoreMuxMementos:(NSArray*)anArray;
- (void) setMuxEfficiency:(float)efficiency;
- (void) saveShaperGainMementos:(NSMutableArray*)anArray;
- (void) restoreShaperGainMementos:(NSArray*)anArray;
- (void) saveShaperThresholdMementos:(NSMutableArray*)anArray;
- (void) restoreShaperThresholdMementos:(NSArray*)anArray;


@end

extern NSString* ORNcdTubeMapNameChangedNotification;
extern NSString* ORNcdTubeMapReadNotification;
extern NSString* ORNcdTubeAddedNotification;
extern NSString* ORNcdTubeRemovedNotification;


@interface NSObject (NcdDetector)
- (void) reloadData:(id)obj;
@end;