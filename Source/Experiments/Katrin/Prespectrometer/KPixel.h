//
//  KPixel.h
//  Orca
//
//  Created by Mark Howe on Thu Sep 04 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
//



@class ORColorBar;
 
typedef  enum  kPixelNameConstants { //don't change the order
    kPositionX,
    kPositionY,
    kAdcSlot,         
    kAdcChannel,      
    kAdcHWAddress, 
	kAdcName,   
    kNumKeys //must be last
}kPixelNameConstants;

@interface KPixel : NSObject {
		BOOL        isValid;
		BOOL        selected;
		NSMutableDictionary* params;
		float       shaperRate;
		
		NSAttributedString* attributedLabel;
		
	@private
		BOOL hwPresent;
		BOOL chanOnline;
		BOOL replayMode;
		BOOL cubeInited;
}

#pragma mark ¥¥¥Initialization
- (id) initFromString:(NSString*)aString;
- (id) initNewPixel;
- (void) unregisterRates;
- (void) registerForShaperRates:(NSArray*)collectionOfShapers;
- (void) loadTotalCounts:(NSArray*)collectionOfShapers;

#pragma mark ¥¥¥Accessors
- (void)	setReplayMode:(BOOL)aReplayMode;
- (BOOL)    isValid;
- (BOOL)    selected;
- (void)    setSelected:(BOOL)state;
- (void)    setIsValid:(BOOL)newIsValid;
- (float)   shaperRate;
- (void)    setShaperRate:(float)newRate;
- (NSAttributedString *) attributedLabel;
- (void) setAttributedLabel: (NSString *) anAttributedLabel;
- (NSRect) frameInRect:(NSRect)aRect;
- (BOOL) containsPoint:(NSPoint)localPoint usingView:(NSView*)detectorView;

- (NSMutableString*) pixelMapLine;

- (void) drawInRect:(NSRect)aRect withColorBar:(ORColorBar*)aColorBar;
- (void) drawIn3DView:(NSRect)aRect withColorBar:(ORColorBar*)rateColorBar;
- (void) decodeString:(NSString*)aString;
- (id) objectForKey:(id)key;
- (id) objectForKeyIndex:(int)keyIndex;
- (void) setObject:(id)obj forKey:(id)key;
- (NSUndoManager*) undoManager;
- (int) compareIntTo:(id)aPixel usingKey:(NSString*)aKey;
- (int) compareStringTo:(id)aPixel usingKey:(NSString*)aKey;
- (int) compareFloatTo:(id)aPixel usingKey:(NSString*)aKey;
- (int) sortTypeFor:(NSString*)aKey;
- (void) openDialog;

#pragma mark ¥¥¥Notifications
- (void) shaperRateChanged:(NSNotification*)note;
- (void) checkHWStatus:(NSArray*)someShapers;

@end

extern NSString* KPixelRateChangedNotification;
extern NSString* KPixelParamChangedNotification;
extern NSString* KPixelSelectionChangedNotification;

extern NSString* kPixelParamKey[kNumKeys];


