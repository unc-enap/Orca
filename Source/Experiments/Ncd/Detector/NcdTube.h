//
//  NcdTube.h
//  Orca
//
//  Created by Mark Howe on Thu Sep 04 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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




@class ORColorScale;
 
typedef  enum  tubeNameConstants { //don't change the order
    kStringNum = 0,
    kPositionX,
    kPositionY,
    kLabel,      
    kMuxBusNum,      
    kMuxBoxNum,       
    kMuxChan,        
    kHvSupply,        
    kAdcSlot,         
    kAdcHWAddress,    
    kAdcChannel,      
    kScopeChannel,    
    kPreampName,      
    kPdsBoardNum,     
    kPdsChan,         
    kNumTubes,        
    kName1,           
    kName2,           
    kName3,           
    kName4,
    kNumKeys //must be last
}tubeNameConstants;

@interface NcdTube : NSObject {
    BOOL        isValid;
    BOOL        selected;
    NSMutableDictionary* params;
    float       shaperRate;
    float       muxRate;
    
    NSAttributedString* attributedLabel;
}

#pragma mark ¥¥¥Initialization
- (id) initFromString:(NSString*)aString;
- (id) initNewTube;
- (void) unregisterRates;
- (void) registerForShaperRates:(NSArray*)collectionOfShapers;
- (void) registerForMuxRates:(NSArray*)collectionOfMuxes;

#pragma mark ¥¥¥Accessors
- (BOOL)    isValid;
- (BOOL)    selected;
- (void)    setSelected:(BOOL)state;
- (void)    setIsValid:(BOOL)newIsValid;
- (float)   shaperRate;
- (void)    setShaperRate:(float)newRate;
- (float)   muxRate;
- (void)    setMuxRate:(float)newRate;
- (NSAttributedString *) attributedLabel;
- (void) setAttributedLabel: (NSString *) anAttributedLabel;
- (NSRect) frameInRect:(NSRect)aRect;
- (BOOL) containsPoint:(NSPoint)localPoint usingView:(NSView*)detectorView;

- (NSMutableString*) tubeMapLine;

- (void) drawInRect:(NSRect)aRect withColorBar:(ORColorScale*)aColorBar;
- (void) drawLabelInRect:(NSRect)aRect;
- (void) decodeString:(NSString*)aString;
-(id) objectForKey:(id)key;
-(id) objectForKeyIndex:(int)keyIndex;
-(void) setObject:(id)obj forKey:(id)key;
- (NSUndoManager*) undoManager;
- (int) compareIntTo:(id)aTube usingKey:(NSString*)aKey;
- (int) compareStringTo:(id)aTube usingKey:(NSString*)aKey;
- (int) compareFloatTo:(id)aTube usingKey:(NSString*)aKey;
- (int) sortTypeFor:(NSString*)aKey;

#pragma mark ¥¥¥Notifications
- (void) shaperRateChanged:(NSNotification*)note;
- (void) muxRateChanged:(NSNotification*)note;

@end

extern NSString* ORNcdTubeRateChangedNotification;
extern NSString* ORNcdTubeParamChangedNotification;
extern NSString* ORNcdTubeSelectionChangedNotification;

extern NSString* tubeParamKey[kNumKeys];


