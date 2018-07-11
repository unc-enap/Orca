//
//  NcdTube.m
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


#import "NcdTube.h"
#import "ORShaperModel.h"
#import "ORRateGroup.h"
#import "ORRate.h"
#import "ORColorScale.h"

#import "NcdMuxBoxModel.h"

#define xMargin  20
#define yMargin  20
#define tubesize 20
#define kScaleFactor 1.4
#define kMaxSize 600.

NSString* ORNcdTubeSelectionChangedNotification		= @"ORNcdTubeSelectionChangedNotification";
NSString* ORNcdTubeRateChangedNotification		= @"ORNcdTubeRateChangedNotification";
NSString* ORNcdTubeParamChangedNotification		= @"ORNcdTubeParamChangedNotification";

//sort type
//  0 = int
//  1 = string
//  2 = float
static struct {
    NSString* key;
    int       sortType;
    }tubeParam[kNumKeys] = {
    { @"kStringNum",   0},
    { @"kPositionX",   2},
    { @"kPositionY",   2},
    { @"kLabel",       1},
    { @"kMuxBusNum",   0},
    { @"kMuxBoxNum",   0},
    { @"kMuxChan",     0},
    { @"kHvSupply",    0},
    { @"kAdcSlot",     0},
    { @"kAdcHWAddress",1},
    { @"kAdcChannel",  0},
    { @"kScopeChannel",0},
    { @"kPreampName",  1},
    { @"kPdsBoardNum", 0},
    { @"kPdsChan",     0},
    { @"kNumTubes",    0},
    { @"kName1",       1},
    { @"kName2",       1},
    { @"kName3",       1},
    { @"kName4",       1}
};

@implementation NcdTube

#pragma mark ¥¥¥Initialization
- (id) initNewTube
{
    self = [super init];
    [self decodeString:@"0,0,0,New,0,0,0,0,0,0x0000,0,0,00,0,0,1,NCD-CHECK"];
    return self;
}

- (id) initFromString:(NSString*)aString
{
    self = [super init];
    [self decodeString:aString];
    return self;
}
- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [params release];
    [attributedLabel release];
    [super dealloc];
}

#pragma mark ¥¥¥Accessors

- (BOOL) isValid
{
    return isValid;
}
- (void) setIsValid:(BOOL)newIsValid
{
    isValid=newIsValid;
}

// ----------------------------------------------------------
// - params:
// ----------------------------------------------------------

- (NSMutableDictionary *) params
{
    return params;
}

// ----------------------------------------------------------
// - setParams:
// ----------------------------------------------------------

- (void) setParams: (NSMutableDictionary *) aParams
{
    [params release];
    params = [aParams retain];
}

- (NSPoint) position
{
    return NSMakePoint([[params objectForKey:tubeParam[kPositionX].key] floatValue],[[params objectForKey:tubeParam[kPositionY].key] floatValue]);
}


// ----------------------------------------------------------
// - attributedLabel:
// ----------------------------------------------------------
- (NSAttributedString *) attributedLabel
{
    return attributedLabel;
}
// ----------------------------------------------------------
// - setAttributedLabel:
// ----------------------------------------------------------
- (void) setAttributedLabel: (NSString *) anAttributedLabel
{
    [attributedLabel release];
    if(anAttributedLabel){
        NSFont* theFont = [NSFont fontWithName:@"Geneva" size:9];
        NSDictionary* theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:theFont,NSFontAttributeName,nil];
        attributedLabel = [[NSAttributedString alloc] initWithString:anAttributedLabel attributes:theAttributes];
    }
}

- (BOOL) selected
{
    return selected;
}

- (void) setSelected:(BOOL)state
{
    selected = state;
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORNcdTubeSelectionChangedNotification
                      object:self];
}


- (float) shaperRate
{
    return shaperRate;
}
- (void) setShaperRate:(float)newRate
{
    shaperRate=newRate;
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORNcdTubeRateChangedNotification
                      object:self];
    
}

- (float) muxRate
{
    return muxRate;
}
- (void) setMuxRate:(float)newRate
{
    muxRate=newRate;
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORNcdTubeRateChangedNotification
                      object:self];
    
}

- (BOOL) containsPoint:(NSPoint)localPoint usingView:(NSView*)detectorView
{
    return NSPointInRect(localPoint,NSInsetRect([self frameInRect:[detectorView frame]],-4,-4));
}

- (NSRect) frameInRect:(NSRect)aRect
{
    float w = aRect.size.width/2;
    float h = aRect.size.height/2;
    float xscale = kScaleFactor*w/kMaxSize;
    float yscale = kScaleFactor*h/kMaxSize;
    float xtubeSize = tubesize*xscale;
    float ytubeSize = tubesize*yscale;
    NSPoint position = [self position];
    return NSMakeRect(w+(position.x)*xscale,h+(position.y)*yscale,xtubeSize,ytubeSize);
}

- (void) drawInRect:(NSRect)aRect withColorBar:(ORColorScale*)aColorBar
{
    NSRect outerRect = [self frameInRect:aRect];
    NSRect innerRect = NSInsetRect(outerRect,8,8);
    NSBezierPath* path1 = [NSBezierPath bezierPathWithOvalInRect:innerRect];
    NSColor* color = [aColorBar getColorForValue:muxRate];
    if(!color)[[NSColor colorWithCalibratedRed:0.90 green:0.95 blue:0.95 alpha:1.0] set];
    else [color set];
    [path1 fill];
    
    NSBezierPath* path2 = [NSBezierPath bezierPathWithOvalInRect:outerRect];
    color = [aColorBar getColorForValue:shaperRate];
    if(!color)[[NSColor colorWithCalibratedRed:0.90 green:0.95 blue:0.95 alpha:1.0] set];
    else [color set];
    [path2 fill];
    
    [[NSColor darkGrayColor] set];
    [path1 setLineWidth:.5];
    [path1 stroke];
    [path2 setLineWidth:.5];
    [path2 stroke];
    if(selected){
        [[NSColor redColor] set];
		float oldWidth = [NSBezierPath defaultLineWidth];
		[NSBezierPath setDefaultLineWidth:.5];
		[NSBezierPath strokeRect:NSInsetRect(outerRect,-4,-4)];
		[NSBezierPath setDefaultLineWidth:oldWidth];
    }
}


- (void) drawLabelInRect:(NSRect)aRect
{
    float w = aRect.size.width/2;
    float h = aRect.size.height/2;
    float xscale = kScaleFactor*w/kMaxSize;
    float yscale = kScaleFactor*h/kMaxSize;
    NSPoint position = [self position];
    
    [attributedLabel drawAtPoint:NSMakePoint(w+(position.x)*xscale+10,h+(position.y)*yscale - 5)];
}



- (void) decodeString:(NSString*)aString
{
    if(!params){
        [self setParams:[NSMutableDictionary dictionary]];
    }
    NSArray* items = [aString componentsSeparatedByString:@","];
    int i;
    NSUInteger count = [items count];
    if(count<=kNumKeys){
        for(i=0;i<count;i++){
            [params setObject:[items objectAtIndex:i] forKey:tubeParam[i].key];
        }
        //params NOT in the tub map
        [params setObject:[NSNumber numberWithBool:YES] forKey:@"kCableCheck"];

        isValid = YES;
    }
    [self setAttributedLabel:[params objectForKey:tubeParam[kLabel].key]];
    
}

- (void) registerForShaperRates:(NSArray*)collectionOfShapers
{
    NSEnumerator* e = [collectionOfShapers objectEnumerator];
    ORShaperModel* shaper;
    while(shaper = [e nextObject]){
        if([[params objectForKey: tubeParam[kAdcSlot].key]intValue] == [shaper slot]){
            id rateObj = [[shaper adcRateGroup] rateObject:[[params objectForKey: tubeParam[kAdcChannel].key]intValue]];
            NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
            [notifyCenter addObserver : self
                             selector : @selector(shaperRateChanged:)
                                 name : ORRateChangedNotification
                               object : rateObj];
            break;
            
        }
    }
}


- (void) registerForMuxRates:(NSArray*)collectionOfMuxes
{
    NSEnumerator* e = [collectionOfMuxes objectEnumerator];
    NcdMuxBoxModel* mux;
    while(mux = [e nextObject]){
        if([[params objectForKey: tubeParam[kMuxBusNum].key]intValue] == [mux muxID]){
            id rateObj = [[mux rateGroup] rateObject:[[params objectForKey: tubeParam[kMuxChan].key]intValue]];
            NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
            [notifyCenter addObserver : self
                             selector : @selector(muxRateChanged:)
                                 name : ORRateChangedNotification
                               object : rateObj];
            break;
            
        }
    }
    
}

- (NSMutableString*) tubeMapLine
{
    
    NSMutableString* s = [NSMutableString string];
    int i;
    for(i=0;i<kNumKeys;i++){
        NSString* item = [params objectForKey:tubeParam[i].key];
        if(item!=nil){
            if(i>0)[s appendString:@","];
            [s appendString:item];
        }
    }
    return s;
}

-(id) objectForKey:(id)key
{
    return [params objectForKey:key];
}

-(void) setObject:(id)obj forKey:(id)key
{
    [[[self undoManager] prepareWithInvocationTarget:self] setObject:[params objectForKey:key] forKey:key];
    
    [params setObject:obj forKey:key];
    if([key isEqualToString:tubeParam[kLabel].key]){
        [self setAttributedLabel:[params objectForKey:key]];
    }
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORNcdTubeParamChangedNotification
                      object:self];
    
}


-(id) objectForKeyIndex:(int)keyIndex
{
    return [self objectForKey:tubeParam[keyIndex].key];
}

- (NSUndoManager*) undoManager
{
    return [(ORAppDelegate*)[NSApp delegate] undoManager];
}

#pragma mark ¥¥¥Notifications

- (void) unregisterRates
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) shaperRateChanged:(NSNotification*)note
{
    float r = [[note object] rate];
    if(r!=shaperRate){
        [self setShaperRate:r];
    }
}

- (void) muxRateChanged:(NSNotification*)note
{
    float r = [[note object] rate];
    if(r!=muxRate){
        [self setMuxRate:r];
    }
}

//note - there is some bad jargon.. Tube = String... There are multiple NCD counters per string
static NSString* NcdTubeIsValid     = @"NcdTubeIsValid";
static NSString* NcdTubeParams      = @"NcdTubeParams";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    [self setIsValid:[decoder decodeBoolForKey:NcdTubeIsValid]];
    [self setParams:[decoder decodeObjectForKey:NcdTubeParams]];
    if(!params){
        [self setParams:[NSMutableDictionary dictionary]];
    }
    [self setAttributedLabel:[params objectForKey:tubeParam[kLabel].key]];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeBool:isValid forKey:NcdTubeIsValid];
    [encoder encodeObject:params forKey:NcdTubeParams];
}

- (int) compareIntTo:(id)aTube usingKey:(NSString*)aKey
{
    return [[self objectForKey:aKey] intValue] - [[aTube objectForKey:aKey] intValue];
}

- (int) compareFloatTo:(id)aTube usingKey:(NSString*)aKey
{
    float val = ([[self objectForKey:aKey] floatValue] - [[aTube objectForKey:aKey] floatValue]);
    if(val>0)return 1;
    else if(val<0)return -1;
    else return 0;
}

- (int) compareStringTo:(id)aTube usingKey:(NSString*)aKey
{
    NSString* ourKey = [self objectForKey:aKey];
    NSString* theirKey = [aTube objectForKey:aKey];
    if(!ourKey && theirKey)         return 1;
    else if(ourKey && !theirKey)    return -1;
    else if(!ourKey || !theirKey)   return 0;
    return [ourKey compare:theirKey];
}

- (int) sortTypeFor:(NSString*)aKey
{
    int i;
    for(i=0;i<kNumKeys;i++){
        if([tubeParam[i].key isEqualToString:aKey]){
            return tubeParam[i].sortType;
        }
    }
    return 0;
}

- (NSString*) description
{
    NSString* string = [NSString string];
    string = [string stringByAppendingFormat:@"Name     : %@\n",[params objectForKey:tubeParam[kLabel].key]];
    string = [string stringByAppendingFormat:@"Mux Box  : %@\n",[params objectForKey:tubeParam[kMuxBusNum].key]];
    string = [string stringByAppendingFormat:@"Mux Addr : %@\n",[params objectForKey:tubeParam[kMuxBoxNum].key]];
    string = [string stringByAppendingFormat:@"Mux Chan : %@\n",[params objectForKey:tubeParam[kMuxChan].key]];
    string = [string stringByAppendingFormat:@"HV Supply: %@\n",[params objectForKey:tubeParam[kHvSupply].key]];
    string = [string stringByAppendingFormat:@"Adc Addr : %@\n",[params objectForKey:tubeParam[kAdcHWAddress].key]];
    string = [string stringByAppendingFormat:@"Adc Slot : %@\n",[params objectForKey:tubeParam[kAdcSlot].key]];
    string = [string stringByAppendingFormat:@"Adc Chan : %@\n",[params objectForKey:tubeParam[kAdcChannel].key]];
    string = [string stringByAppendingFormat:@"Osc Chan : %@\n",[params objectForKey:tubeParam[kScopeChannel].key]];
    string = [string stringByAppendingFormat:@"PreAmp   : %@\n",[params objectForKey:tubeParam[kPreampName].key]];
    string = [string stringByAppendingFormat:@"PDS Board: %@\n",[params objectForKey:tubeParam[kPdsBoardNum].key]];
    string = [string stringByAppendingFormat:@"PDS Chan : %@\n",[params objectForKey:tubeParam[kPdsChan].key]];
    string = [string stringByAppendingFormat:@"Num Tubes: %@\n",[params objectForKey:tubeParam[kNumTubes].key]];
    return string;
}


@end
