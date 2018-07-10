//
//  NcdDetector.m
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
#import "NcdDetector.h"
#import "NcdTube.h"
#import "ORTimeRate.h"
#import "ORDataPacket.h"
#import "NcdModel.h"
#import "ORShaperModel.h"
#import "NcdMuxBoxModel.h"
#import "ORRateGroup.h"
#import "ORColorScale.h"

#pragma mark ¥¥¥Definitions
#define kTubeMapDataFile @"NcdFiles/TubeMapData.h"
#define kMaxNumStrings 40

NSString* ORNcdTubeMapNameChangedNotification = @"ORNcdTubeMapNameChangedNotification";
NSString* ORNcdTubeMapReadNotification        = @"ORNcdTubeMapReadNotification";
NSString* ORNcdTubeAddedNotification          = @"ORNcdTubeAddedNotification";
NSString* ORNcdTubeRemovedNotification        = @"ORNcdTubeRemovedNotification";

NSInteger sortUpIntFunction(id tube1,id tube2, void* context){ return [tube1 compareIntTo:tube2 usingKey:context];}
NSInteger sortDnIntFunction(id tube1,id tube2, void* context){return [tube2 compareIntTo:tube1 usingKey:context];}
NSInteger sortUpStringFunction(id tube1,id tube2, void* context){ return [tube1 compareStringTo:tube2 usingKey:context];}
NSInteger sortDnStringFunction(id tube1,id tube2, void* context){return [tube2 compareStringTo:tube1 usingKey:context];}
NSInteger sortUpFloatFunction(id tube1,id tube2, void* context){ return [tube1 compareFloatTo:tube2 usingKey:context];}
NSInteger sortDnFloatFunction(id tube1,id tube2, void* context){return [tube2 compareFloatTo:tube1 usingKey:context];}

static NcdDetector *ncdInstance = nil;

@implementation NcdDetector

#pragma mark ¥¥¥Initialization
+(id) sharedInstance
{
    if ( ncdInstance == nil ) {
        ncdInstance = [[self alloc] init];
    }
    
    return ncdInstance;
}

- (id) init
{
    self = [super init];
    [self setTubes:[NSMutableArray arrayWithCapacity:kMaxNumStrings]];
    
    ORTimeRate* r = [[ORTimeRate alloc] init];
    [self setShaperTotalRate:r];
    [r release];
    
    r = [[ORTimeRate alloc] init];
    [self setMuxTotalRate:r];
    [r release];
    
    return self;
}

- (void) dealloc
{
    [mapFileName release];
    [tubes release];
    [shaperCards release];
    [muxBoxes release];
    [shaperTotalRate release];
    [super dealloc];
}


#pragma mark ¥¥¥Accessors
- (NSUndoManager*) undoManager
{
    return [(ORAppDelegate*)[NSApp delegate] undoManager];
}

// ----------------------------------------------------------
// - mapFileName:
// ----------------------------------------------------------

- (NSString *) mapFileName
{
    if(mapFileName)return mapFileName;
    else return kTubeMapDataFile;
}

// ----------------------------------------------------------
// - setMapFileName:
// ----------------------------------------------------------

- (void) setMapFileName: (NSString *) aMapFileName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMapFileName:mapFileName];
    [mapFileName release];
    mapFileName = [aMapFileName copy];
    
    [self readMap];
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORNcdTubeMapNameChangedNotification
                      object:self];
    
}

- (NSMutableArray*) tubes
{
    return tubes;
}
- (void) setTubes:(NSMutableArray*)newTubes
{
    [tubes autorelease];
    tubes=[newTubes retain];
}
- (NSUInteger) numberOfTubes
{
    return [tubes count];
}
- (NcdTube*) tube:(int)index
{
    return [tubes objectAtIndex:index];
}

- (ORTimeRate*) shaperTotalRate
{
    return shaperTotalRate;
}
- (void) setShaperTotalRate:(ORTimeRate*)newShaperTotalRate
{
    [shaperTotalRate autorelease];
    shaperTotalRate=[newShaperTotalRate retain];
}
- (ORTimeRate*) muxTotalRate
{
    return muxTotalRate;
}
- (void) setMuxTotalRate:(ORTimeRate*)newMuxTotalRate
{
    [muxTotalRate autorelease];
    muxTotalRate=[newMuxTotalRate retain];
}

- (float) shaperRate
{
    return shaperRate;
}

- (float) muxRate
{
    return muxRate;
}


- (void) setDelegate:(id)aDelegate
{
    delegate = aDelegate;
}

- (NSArray *)shaperCards
{
    return shaperCards;
}

- (void)setShaperCards:(NSArray *)aShaperCards
{
    [shaperCards release];
    shaperCards = [aShaperCards retain];
}

- (NSArray *)muxBoxes
{
    return muxBoxes;
}

- (void)setMuxBoxes:(NSArray *)aMuxBoxes
{
    [muxBoxes release];
    muxBoxes = [aMuxBoxes retain];
}

- (short) getScopeChannelForMux:(short) mux scope:(short) scope
{
    if(mux>=0 && mux<8 && scope>=0 && scope<2)return chanMap[mux][scope];
    else return -1;
}

- (void) drawInRect:(NSRect)aRect withColorBar:(ORColorScale*)rateColorBar
{
    NSBezierPath* path = [NSBezierPath bezierPathWithOvalInRect:aRect];
    [[NSColor colorWithCalibratedRed:0.90 green:0.95 blue:0.95 alpha:1.0] set];
    [path fill];
	[path setLineWidth:.5];
    [[NSColor blackColor] set];
    [path stroke];
	
    NSEnumerator* e = [tubes objectEnumerator];
    NcdTube* tube;
    while(tube = [e nextObject]){
		//int stringNum = [[tube objectForKeyIndex:kStringNum] intValue];
        //if(stringNum <kMaxNumStrings){
        [tube drawInRect:aRect withColorBar:rateColorBar];
        if([delegate drawTubeLabel]){
            [tube drawLabelInRect:aRect];
        }
		//}
    }
}

- (void) unregisterRates
{
    [tubes makeObjectsPerformSelector:@selector(unregisterRates) withObject:nil];
}

- (void) registerForShaperRates:(NSArray*)collectionOfShapers
{
    [tubes makeObjectsPerformSelector:@selector(registerForShaperRates:) withObject:collectionOfShapers];
}

- (void) registerForMuxRates:(NSArray*)collectionOfMuxes
{
    [tubes makeObjectsPerformSelector:@selector(registerForMuxRates:) withObject:collectionOfMuxes];
}

- (void) reloadData:(id)obj
{
    [delegate reloadData:self];
}

- (void) configurationChanged
{
    [self setShaperCards:[[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORShaperModel")]];
    [self setMuxBoxes:[[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"NcdMuxBoxModel")]];
}

- (void) collectTotalShaperRate
{
    float sum = 0;
    NSEnumerator* e = [shaperCards objectEnumerator];
    ORShaperModel* card;
    while(card = [e nextObject]){
        sum += [[card adcRateGroup] totalRate];
    }
    shaperRate = sum;
    [shaperTotalRate addDataToTimeAverage:sum];
}

- (void) collectTotalMuxRate
{
    float sum = 0;
    NSEnumerator* e = [muxBoxes objectEnumerator];
    NcdMuxBoxModel* box;
    while(box = [e nextObject]){
        sum += [[box rateGroup] totalRate];
    }
    muxRate = sum;
    [muxTotalRate addDataToTimeAverage:sum];
}


-(void)setSortColumn:(NSString *)identifier {
    if (![identifier isEqualToString:_sortColumn]) {
        // [[[self undoManager] prepareWithInvocationTarget:self] setSortColumn:_sortColumn];
        [_sortColumn release];
        _sortColumn = [identifier copyWithZone:[self zone]];
        //[[self undoManager] setActionName:@"Column Selection"];
    }
}

- (NSString *)sortColumn
{
    return _sortColumn;
}

- (void)setSortIsDescending:(BOOL)whichWay {
    if (whichWay != _sortIsDescending) {
        //[[[self undoManager] prepareWithInvocationTarget:self] setSortIsDescending:_sortIsDescending];
        _sortIsDescending = whichWay;
        //[[self undoManager] setActionName:@"Sort Direction"];
    }
}

- (BOOL)sortIsDescending
{
    return _sortIsDescending;
}


#pragma mark ¥¥¥Archival
static NSString *ORDetectorTubes        = @"ORDetectorTubes";
static NSString *ORDetectorShaperRate	= @"ORDetectorShaperRate";
static NSString *ORDetectorMuxRate	= @"ORDetectorMuxRate";
static NSString *ORDetectorMapFile	= @"ORDetectorMapFile";

- (id)loadWithCoder:(NSCoder*)decoder
{
    [[self undoManager] disableUndoRegistration];
    [self setTubes:[decoder decodeObjectForKey:ORDetectorTubes]];
    [self setShaperTotalRate:[decoder decodeObjectForKey:ORDetectorShaperRate]];
    [self setMuxTotalRate:[decoder decodeObjectForKey:ORDetectorMuxRate]];
    [self setMapFileName:[decoder decodeObjectForKey:ORDetectorMapFile]];
    
    if(shaperTotalRate==nil){
        ORTimeRate* r = [[ORTimeRate alloc] init];
        [self setShaperTotalRate:r];
        [r release];
    }
    if(muxTotalRate==nil){
        ORTimeRate* r = [[ORTimeRate alloc] init];
        [self setMuxTotalRate:r];
        [r release];
    }
    
    [[self undoManager] enableUndoRegistration];
    ncdInstance = self;
    return self;
}

- (void)saveWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:[self tubes] forKey:ORDetectorTubes];
    [encoder encodeObject:[self shaperTotalRate] forKey:ORDetectorShaperRate];
    [encoder encodeObject:[self muxTotalRate] forKey:ORDetectorMuxRate];
    [encoder encodeObject:[self mapFileName] forKey:ORDetectorMapFile];
    
    [self saveMapFileAs:mapFileName];
}

#pragma mark ¥¥¥Run Data
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
    [objDictionary setObject:NSStringFromClass([self class]) forKey:@"Class Name"];
    
    NSEnumerator* e = [tubes objectEnumerator];
    NcdTube* tube;
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:64];
    while(tube = [e nextObject]){
        [array addObject:[NSString stringWithFormat:@"%@",[tube tubeMapLine]]];
    }
    if([array count])[objDictionary setObject:array forKey:@"Geometry"];
    
    [dictionary setObject:objDictionary forKey:NSStringFromClass([self class])];
    return objDictionary;
}

- (void) saveMuxMementos
{
    int i;
    NSUInteger n = [muxBoxes count];
    if(!muxMementos){
        muxMementos = [[NSMutableArray alloc] init];
        for(i=0;i<n;i++){
            [muxMementos addObject:[NSNull null]];
        }
    }
    for(i=0;i<n;i++){
        id mux = [muxBoxes objectAtIndex:i];
        [muxMementos replaceObjectAtIndex:i withObject:[mux memento]];
    }
}

- (void) restoreMuxMementos
{
    
    int i;
    NSUInteger n = [muxBoxes count];
    for(i=0;i<n;i++){
        id mux = [muxBoxes objectAtIndex:i];
        [mux restoreFromMemento:[muxMementos objectAtIndex:i]];
    }
 
    [muxMementos release];
    muxMementos = nil;
}

- (void) saveMuxMementos:(NSMutableArray*)anArray
{
    int i;
    NSUInteger n = [muxBoxes count];
	[anArray removeAllObjects];
	for(i=0;i<n;i++){
		[anArray addObject:[NSNull null]];
	}
    
    for(i=0;i<n;i++){
        id mux = [muxBoxes objectAtIndex:i];
        [anArray replaceObjectAtIndex:i withObject:[mux memento]];
    }
}

- (void) restoreMuxMementos:(NSArray*)anArray
{
    int i;
    NSUInteger n = [muxBoxes count];
    for(i=0;i<n;i++){
        id mux = [muxBoxes objectAtIndex:i];
        [mux restoreFromMemento:[anArray objectAtIndex:i]];
    }
}

- (void) saveShaperGainMementos:(NSMutableArray*)anArray
{
    int i;
    NSUInteger n = [shaperCards count];
	[anArray removeAllObjects];
	for(i=0;i<n;i++){
		[anArray addObject:[NSNull null]];
	}
     
    for(i=0;i<n;i++){
        id shaper = [shaperCards objectAtIndex:i];
        [anArray replaceObjectAtIndex:i withObject:[shaper gainMemento]];
    }
}

- (void) restoreShaperGainMementos:(NSArray*)anArray
{
    int i;
    NSUInteger n = [shaperCards count];
    for(i=0;i<n;i++){
        id shaper = [shaperCards objectAtIndex:i];
        [shaper restoreGainsFromMemento:[anArray objectAtIndex:i]];
    }
}

- (void) saveShaperThresholdMementos:(NSMutableArray*)anArray
{
    int i;
    NSUInteger n = [shaperCards count];
	[anArray removeAllObjects];
	for(i=0;i<n;i++){
		[anArray addObject:[NSNull null]];
	}
    
    for(i=0;i<n;i++){
        id shaper = [shaperCards objectAtIndex:i];
        [anArray replaceObjectAtIndex:i withObject:[shaper thresholdMemento]];
    }
}

- (void) restoreShaperThresholdMementos:(NSArray*)anArray
{
    int i;
    NSUInteger n = [shaperCards count];
    for(i=0;i<n;i++){
        id shaper = [shaperCards objectAtIndex:i];
        [shaper restoreThresholdsFromMemento:[anArray objectAtIndex:i]];
    }
}

- (void) setMuxEfficiency:(float)efficiency
{
    int i;
    NSUInteger n = [muxBoxes count];
    for(i=0;i<n;i++){
        id mux = [muxBoxes objectAtIndex:i];
		
		//constants for calculating the mux efficiency
		float a =  0.000769;
		float b = -0.00853;
		float c =  0.988;
		float newEff = efficiency/100.;
		int threshold_change = (int)(roundf((b+sqrt(b*b + 4*a*(c-newEff)))/(2*a)));

		int chan;
		//skip the log amp (last one in list)
		for(chan=0;chan<kNumMuxChannels-1;chan++){
			int newThres = [mux thresholdDac:chan] + threshold_change;
			if(newThres > 0xff)newThres = 0xff;
			if(newThres < 0)newThres = 0;
			[mux setThresholdDac:chan withValue:newThres];
		}
		[mux initMux];
    }
}

- (void) replaceMuxThresholdsUsingFile:(NSString*)path
{
    NSString* contents = [NSString stringWithContentsOfFile:[path stringByExpandingTildeInPath] encoding:NSASCIIStringEncoding error:nil];
    if(contents){
        NSArray* theLines = [contents lines];
        NSUInteger numLines = [theLines count];
        int chan;
        [[self undoManager] disableUndoRegistration];
        NSCharacterSet* delimiters = [NSCharacterSet whitespaceAndNewlineCharacterSet]; 
        //[delimiters addCharactersInString:@","];
        for(chan=0;chan<numLines;chan++){
            if(chan<13){
                NSArray* theValues = [[theLines objectAtIndex:chan] tokensSeparatedByCharactersFromSet:delimiters];
                int box;
                NSUInteger numBoxes = [muxBoxes count];
                for(box=0;box<numBoxes;box++){
                    id mux = [muxBoxes objectAtIndex:box];
                    int boxIndex = [mux muxID];
                    unsigned short val;
                    if(boxIndex>=0 && boxIndex<numBoxes){
                        NSString* valAsString = [theValues objectAtIndex:boxIndex];
                        if( [valAsString rangeOfString:@"x"].location != NSNotFound ||
                            [valAsString rangeOfString:@"X"].location != NSNotFound){
                            //it's hex..convert as to decimal
                            val = (unsigned short)strtoul([valAsString cStringUsingEncoding:NSASCIIStringEncoding], 0, 16);
                            
                        }
                        else {
                            val = [valAsString intValue];
                        }
                        
                        [mux setThresholdDac:chan withValue:val];
						[mux initMux];
					}
                }
            }
        }
        [[self undoManager] enableUndoRegistration];
        [muxBoxes makeObjectsPerformSelector:@selector(initMux)];
        //[delimiters release];
    }
    else {
        NSLog(@"Unable to open mux threshold file: <%@>\n",[path stringByAbbreviatingWithTildeInPath]);
        NSLog(@"Mux thresholds NOT modified\n");
    }
}


- (void) readMap
{
    if(!tubes){
        [self setTubes:[NSMutableArray array]];
    }
    [tubes removeAllObjects];
    
    NSString* mapFilePath;
    if(mapFileName == nil){
        mapFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:kTubeMapDataFile];
    }
    else {
        mapFilePath = mapFileName;
    }
    NSString* contents = [NSString stringWithContentsOfFile:mapFilePath encoding:NSASCIIStringEncoding error:nil];
    NSArray*  lines = [contents componentsSeparatedByString:@"\n"];
    NSEnumerator* e = [lines objectEnumerator];
    NSString* aLine;
    
    short i;
    for( i=0;i<8;i++){
        //init to -1 which means not connected.
        chanMap[i][0]= -1;
        chanMap[i][1]= -1;
    }
    
    while(aLine = [e nextObject]){
        aLine = [aLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if([aLine length] && [aLine characterAtIndex:0] != '#'){
            NcdTube* aTube = [[NcdTube alloc] initFromString:aLine];
            if([aTube isValid]) {
                [tubes addObject:aTube];
                int muxBusNum = [[aTube objectForKeyIndex:kMuxBusNum] intValue];
                int muxBoxNum = [[aTube objectForKeyIndex:kMuxBoxNum] intValue];
                int scopeChannel = [[aTube objectForKeyIndex:kScopeChannel] intValue];
                if(chanMap[muxBusNum][0] == -1 && chanMap[muxBusNum][1] == -1){
                    chanMap[muxBusNum][0] = chanMap[muxBusNum][1] = scopeChannel;
                    NSLog(@"NcdDetector: Mapped Mux Bus %d, Box %d, to Scope Channel %d\n",muxBusNum,muxBoxNum,scopeChannel);
                }
                else if(chanMap[muxBusNum][0] != scopeChannel || chanMap[muxBusNum][1] != scopeChannel){
                    //need to send an error and prohibit a run from starting
                    NSLog(@"NcdDetector: TubeMap Mux to Scope mapping inconsistent!\n");
                    NSLog(@"Check TubeMapData.h entry for NCD string %@\n",[aTube objectForKeyIndex:kLabel]);
                }
            }
            [aTube release];
        }
    }
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORNcdTubeMapReadNotification
                      object:self];
    
}

- (void) saveMapFileAs:(NSString*)newFileName
{
    NSMutableData* theContents = [NSMutableData data];
    NSEnumerator* e = [tubes objectEnumerator];
    NcdTube* tube;
    while(tube = [e nextObject]){
        [theContents appendData:[[tube tubeMapLine] dataUsingEncoding:NSASCIIStringEncoding]];
        [theContents appendData:[@"\n" dataUsingEncoding:NSASCIIStringEncoding]];
    }
    
    NSFileManager* theFileManager = [NSFileManager defaultManager];
    if([theFileManager fileExistsAtPath:newFileName]){
        [theFileManager removeItemAtPath:newFileName error:nil];
    }
    [theFileManager createFileAtPath:newFileName contents:theContents attributes:nil];
}

- (void) removeTubeAtIndex:(NSUInteger)index
{
    if(index<[tubes count]){
        [[[self undoManager] prepareWithInvocationTarget:self] addTube:[tubes objectAtIndex:index] atIndex:index];
        [tubes removeObjectAtIndex:index];
        [[NSNotificationCenter defaultCenter]
            postNotificationName:ORNcdTubeRemovedNotification
                          object:self];
        
    }
}

- (void) addTube:(NcdTube*)aTube atIndex:(NSUInteger)index
{
    if(aTube){
        [[[self undoManager] prepareWithInvocationTarget:self] removeTubeAtIndex:index];
        [tubes insertObject:aTube atIndex:index];
    }
    else {
        aTube = [[NcdTube alloc] initNewTube];
        index = [tubes count];
        [[[self undoManager] prepareWithInvocationTarget:self] removeTubeAtIndex:index];
        [tubes insertObject:aTube atIndex:index];
		[aTube release];
        
    }
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORNcdTubeAddedNotification
                      object:self];
}

- (void)sort
{
    if([[tubes objectAtIndex:0] sortTypeFor:_sortColumn] == 0){
        if(_sortIsDescending)[tubes sortUsingFunction:sortDnIntFunction context: _sortColumn];
        else [tubes sortUsingFunction:sortUpIntFunction context: _sortColumn];
    }
    else if([[tubes objectAtIndex:0] sortTypeFor:_sortColumn] == 1){
        if(_sortIsDescending)[tubes sortUsingFunction:sortDnStringFunction context: _sortColumn];
        else [tubes sortUsingFunction:sortUpStringFunction context: _sortColumn];
    }
    else if([[tubes objectAtIndex:0] sortTypeFor:_sortColumn] == 2){
        if(_sortIsDescending)[tubes sortUsingFunction:sortDnFloatFunction context: _sortColumn];
        else [tubes sortUsingFunction:sortUpFloatFunction context: _sortColumn];
    }
}

- (void) handleMouseDownAt:(NSPoint)localPoint inView:(NSView*)detectorView
{
    NSEnumerator* e = [tubes objectEnumerator];
    NcdTube* tube;
    while(tube = [e nextObject]){
        [tube setSelected:[tube containsPoint:localPoint usingView:detectorView]];
    }
}

@end


