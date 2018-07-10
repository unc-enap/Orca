//
//  Prespectrometer.h
//  Orca
//
//  Created by Mark Howe on Thu Sep 04 2003.
//  Copyright (c) 2003 CENPA, Unvsersity of Washington. All rights reserved.
//
#pragma mark ¥¥¥Imported Files


@class ORColorBar;
@class ORTimeRate;
@class ORDataPacket;
@class KPixel;

@interface Prespectrometer : NSObject 
{
    NSMutableArray* pixels;
    NSArray*	    shaperCards;
    ORTimeRate*     shaperTotalRate;
    NSString*       mapFileName;

    id              delegate;

    NSString *_sortColumn;
    BOOL _sortIsDescending;
    float shaperRate;
}

#pragma mark ¥¥¥Initialization
+ (id) 		sharedInstance;
- (id) 		init;
- (void) unregisterRates;
- (void) collectTotalShaperRate;
- (void) readMap;

#pragma mark ¥¥¥Accessors
- (NSUndoManager*) undoManager;
- (NSString *) mapFileName;
- (void) setMapFileName: (NSString *) aMapFileName;
- (NSMutableArray*) pixels;
- (void) setPixels:(NSMutableArray*)newPixels;
- (KPixel*) pixel:(int)index;
- (int) numberOfPixels;
- (ORTimeRate*) shaperTotalRate;
- (void) setShaperTotalRate:(ORTimeRate*)newShaperTotalRate;
- (void) setDelegate:(id)aDelegate;
- (NSArray *)shaperCards;
- (void)setShaperCards:(NSArray *)aShaperCards;

- (void) drawInRect:(NSRect)aRect withColorBar:(ORColorBar*)rateColorBar;
- (void) drawIn3DView:(NSRect)aRect withColorBar:(ORColorBar*)rateColorBar;
- (void) registerForShaperRates:(NSArray*)collectionOfShapers;
- (void) reloadData:(id)obj;
- (void) saveMapFileAs:(NSString*)newFileName;

- (id)loadWithCoder:(NSCoder*)decoder;
- (void)saveWithCoder:(NSCoder*)encoder;

- (void) removePixelAtIndex:(int)index;
- (void) addPixel:(KPixel*)aPixel atIndex:(int)index;
- (float) shaperRate;

- (void)setSortColumn:(NSString *)identifier;
- (NSString *)sortColumn;
- (void)setSortIsDescending:(BOOL)whichWay;
- (BOOL)sortIsDescending;
- (void) sort;
- (void) configurationChanged;
- (void) handleMouseDownAt:(NSPoint)localPoint inView:(NSView*)detectorView;
- (void) handleDoubleClickAt:(NSPoint)localPoint inView:(NSView*)detectorView;
- (void) setReplayMode:(BOOL)aReplayMode;
- (void) loadTotalCounts;
- (void) clearAdcCounts;

#pragma mark ¥¥¥Run Data
- (NSMutableDictionary*) captureCurrentState:(NSMutableDictionary*)dictionary;

@end

extern NSString* ORKPixelMapNameChangedNotification;
extern NSString* ORKPixelMapReadNotification;
extern NSString* ORKPixelAddedNotification;
extern NSString* ORKPixelRemovedNotification;
extern NSString* ORPrespectrometerCollectedRates;


@interface NSObject (Prespectrometer)
- (void) reloadData:(id)obj;
@end;