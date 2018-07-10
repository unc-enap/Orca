//
//  Prespectrometer.m
//  Orca
//
//  Created by Mark Howe on Tue Jun 28 2005.
//  Copyright (c) 2003 CENPA, Unvsersity of Washington. All rights reserved.
//

#pragma mark ¥¥¥Imported Files
#import "Prespectrometer.h"
#import "KPixel.h"
#import "ORTimeRate.h"
#import "ORDataPacket.h"

#import "NcdModel.h"
#import "ORShaperModel.h"
#import "ORRateGroup.h"
#import "ORColorBar.h"
#import <OpenGL/gl.h>
#import <OpenGL/glext.h>
#import <OpenGL/glu.h>

#pragma mark ¥¥¥Definitions
#define kPixelMapDataFile @"KatrinFiles/PixelMapData.h"
#define kMaxNumStrings 40

NSString* ORKPixelMapNameChangedNotification = @"ORKPixelMapNameChangedNotification";
NSString* ORKPixelMapReadNotification        = @"ORKPixelMapReadNotification";
NSString* ORKPixelAddedNotification          = @"ORKPixelAddedNotification";
NSString* ORKPixelRemovedNotification        = @"ORKPixelRemovedNotification";
NSString* ORPrespectrometerCollectedRates    = @"ORPrespectrometerCollectedRates";


int sortUpIntFunc(id pixel1,id pixel2, void* context){ return [pixel1 compareIntTo:pixel2 usingKey:context];}
int sortDnIntFunc(id pixel1,id pixel2, void* context){return [pixel2 compareIntTo:pixel1 usingKey:context];}
int sortUpStringFunc(id pixel1,id pixel2, void* context){ return [pixel1 compareStringTo:pixel2 usingKey:context];}
int sortDnStringFunc(id pixel1,id pixel2, void* context){return [pixel2 compareStringTo:pixel1 usingKey:context];}
int sortUpFloatFunc(id pixel1,id pixel2, void* context){ return [pixel1 compareFloatTo:pixel2 usingKey:context];}
int sortDnFloatFunc(id pixel1,id pixel2, void* context){return [pixel2 compareFloatTo:pixel1 usingKey:context];}

static Prespectrometer *ncdInstance = nil;

@implementation Prespectrometer

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
    [self setPixels:[NSMutableArray arrayWithCapacity:kMaxNumStrings]];
    
    ORTimeRate* r = [[ORTimeRate alloc] init];
    [self setShaperTotalRate:r];
    [r release];
        
    return self;
}

- (void) dealloc
{
    [mapFileName release];
    [pixels release];
    [shaperCards release];
    [shaperTotalRate release];
    [super dealloc];
}


#pragma mark ¥¥¥Accessors
- (NSUndoManager*) undoManager
{
    return [[NSApp delegate] undoManager];
}

// ----------------------------------------------------------
// - mapFileName:
// ----------------------------------------------------------

- (NSString *) mapFileName
{
    if(mapFileName)return mapFileName;
    else return kPixelMapDataFile;
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
        postNotificationName:ORKPixelMapNameChangedNotification
                      object:self];
    
}

- (NSMutableArray*) pixels
{
    return pixels;
}
- (void) setPixels:(NSMutableArray*)newPixels
{
    [pixels autorelease];
    pixels=[newPixels retain];
}
- (int) numberOfPixels
{
    return [pixels count];
}
- (KPixel*) pixel:(int)index
{
    return [pixels objectAtIndex:index];
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

- (float) shaperRate
{
    return shaperRate;
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

- (void) setReplayMode:(BOOL)aReplayMode
{
    NSEnumerator* e = [pixels objectEnumerator];
    KPixel* pixel;
    while(pixel = [e nextObject]){
		[pixel setReplayMode:aReplayMode];
	}
}

- (void) drawInRect:(NSRect)aRect withColorBar:(ORColorBar*)rateColorBar
{
    NSBezierPath* path = [NSBezierPath bezierPathWithRect:aRect];
    [[NSColor colorWithCalibratedRed:0.90 green:0.95 blue:0.95 alpha:1.0] set];
    [path fill];
	[path setLineWidth:.5];
    [[NSColor blackColor] set];
    [path stroke];
	
    NSEnumerator* e = [pixels objectEnumerator];
    KPixel* pixel;
    while(pixel = [e nextObject]){
        [pixel drawInRect:aRect withColorBar:rateColorBar];
    }
}

- (void) drawIn3DView:(NSRect)aRect withColorBar:(ORColorBar*)rateColorBar;
{

    NSEnumerator* e = [pixels objectEnumerator];
    KPixel* pixel;
    while(pixel = [e nextObject]){
        [pixel drawIn3DView:aRect withColorBar:rateColorBar];
    }
	
	if(1){
		float x1 = aRect.origin.x;
		float y1 = aRect.origin.y;
		float x2 = x1 + aRect.size.width/2 + 4;
		float y2 = y1 + aRect.size.height/2 + 4;
		float z  = -aRect.size.height/2;

		glColor3f (0.7, 0.7, 0.7);
		glBegin (GL_LINE_LOOP);
		glVertex3f(x1,0,y1);
		glVertex3f(x2,0,y1);
		glVertex3f(x2,0,y2);
		glVertex3f(x1,0,y2);
		glEnd ();
		
		//back
		glBegin (GL_LINE_LOOP);
		glVertex3f(x1,0,y2);
		glVertex3f(x2,0,y2);
		glVertex3f(x2,z,y2);
		glVertex3f(x1,z,y2);
		glEnd ();
		

		//right
		glBegin (GL_LINE_LOOP);
		glVertex3f(x2,0,y2);
		glVertex3f(x2,0,y1);
		glVertex3f(x2,z,y1);
		glVertex3f(x2,z,y2);
		glEnd ();
		
		//front
		glBegin (GL_LINE_LOOP);
		glVertex3f(x2,0,y1);
		glVertex3f(x1,0,y1);
		glVertex3f(x1,z,y1);
		glVertex3f(x2,z,y1);
		glEnd ();

		//front
		glBegin (GL_LINE_LOOP);
		glVertex3f(x1,0,y1);
		glVertex3f(x1,0,y2);
		glVertex3f(x1,z,y2);
		glVertex3f(x1,z,y1);
		glEnd ();


		//top
		glBegin (GL_LINE_LOOP);
		glVertex3f(x1,z,y1);
		glVertex3f(x1,z,y2);
		glVertex3f(x2,z,y2);
		glVertex3f(x2,z,y1);
		glEnd ();
	}
}


- (void) clearAdcCounts
{
	[shaperCards makeObjectsPerformSelector:@selector(clearAdcCounts) withObject:nil];
}

- (void) loadTotalCounts
{
    [pixels makeObjectsPerformSelector:@selector(loadTotalCounts:) withObject:shaperCards];
}

- (void) unregisterRates
{
    [pixels makeObjectsPerformSelector:@selector(unregisterRates) withObject:nil];
}

- (void) registerForShaperRates:(NSArray*)collectionOfShapers
{
    [pixels makeObjectsPerformSelector:@selector(registerForShaperRates:) withObject:collectionOfShapers];
}

- (void) reloadData:(id)obj
{
    [delegate reloadData:self];
}

- (void) configurationChanged
{
    [self setShaperCards:[[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORShaperModel")]];
    [pixels makeObjectsPerformSelector:@selector(checkHWStatus:) withObject:shaperCards];
	
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
	
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORPrespectrometerCollectedRates
                      object:self];
	
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
static NSString *ORDetectorPixels        = @"ORDetectorPixels";
static NSString *ORDetectorShaperRate	= @"ORDetectorShaperRate";
static NSString *ORDetectorMapFile	= @"ORDetectorMapFile";

- (id)loadWithCoder:(NSCoder*)decoder
{
    [[self undoManager] disableUndoRegistration];
    [self setPixels:[decoder decodeObjectForKey:ORDetectorPixels]];
    [self setShaperTotalRate:[decoder decodeObjectForKey:ORDetectorShaperRate]];
    [self setMapFileName:[decoder decodeObjectForKey:ORDetectorMapFile]];
    
    if(shaperTotalRate==nil){
        ORTimeRate* r = [[ORTimeRate alloc] init];
        [self setShaperTotalRate:r];
        [r release];
    }
    
    [[self undoManager] enableUndoRegistration];
    ncdInstance = self;
    return self;
}

- (void)saveWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:[self pixels] forKey:ORDetectorPixels];
    [encoder encodeObject:[self shaperTotalRate] forKey:ORDetectorShaperRate];
    [encoder encodeObject:[self mapFileName] forKey:ORDetectorMapFile];
    [self saveMapFileAs:mapFileName];
}

#pragma mark ¥¥¥Run Data
- (NSMutableDictionary*) captureCurrentState:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
    [objDictionary setObject:NSStringFromClass([self class]) forKey:@"Class Name"];
    
    NSEnumerator* e = [pixels objectEnumerator];
    KPixel* pixel;
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:64];
    while(pixel = [e nextObject]){
        [array addObject:[NSString stringWithFormat:@"%@",[pixel pixelMapLine]]];
    }
    if([array count])[objDictionary setObject:array forKey:@"Geometry"];
    
    [dictionary setObject:objDictionary forKey:NSStringFromClass([self class])];
    return objDictionary;
}



- (void) readMap
{
    if(!pixels){
        [self setPixels:[NSMutableArray array]];
    }
    [pixels removeAllObjects];
    
    NSString* mapFilePath;
    if(mapFileName == nil){
        mapFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:kPixelMapDataFile];
    }
    else {
        mapFilePath = mapFileName;
    }
    NSString* contents = [NSString stringWithContentsOfFile:mapFilePath];
    NSArray*  lines = [contents componentsSeparatedByString:@"\n"];
    NSEnumerator* e = [lines objectEnumerator];
    NSString* aLine;
        
    while(aLine = [e nextObject]){
        aLine = [aLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        aLine = [aLine stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
        if([aLine length] && [aLine characterAtIndex:0] != '#'){
            KPixel* aPixel = [[KPixel alloc] initFromString:aLine];
            if([aPixel isValid]) {
                [pixels addObject:aPixel];
            }
            [aPixel release];
        }
    }

    [pixels makeObjectsPerformSelector:@selector(checkHWStatus:) withObject:shaperCards];
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORKPixelMapReadNotification
                      object:self];
    
}

- (void) saveMapFileAs:(NSString*)newFileName
{
    NSMutableData* theContents = [NSMutableData data];
    NSEnumerator* e = [pixels objectEnumerator];
    KPixel* pixel;
    while(pixel = [e nextObject]){
        [theContents appendData:[[pixel pixelMapLine] dataUsingEncoding:NSASCIIStringEncoding]];
        [theContents appendData:[@"\n" dataUsingEncoding:NSASCIIStringEncoding]];
    }
    
    NSFileManager* theFileManager = [NSFileManager defaultManager];
    if([theFileManager fileExistsAtPath:newFileName]){
        [theFileManager removeFileAtPath:newFileName handler:nil];
    }
    [theFileManager createFileAtPath:newFileName contents:theContents attributes:nil];
}

- (void) removePixelAtIndex:(int)index
{
    if(index>=0 && index<[pixels count]){
        [[[self undoManager] prepareWithInvocationTarget:self] addPixel:[pixels objectAtIndex:index] atIndex:index];
        [pixels removeObjectAtIndex:index];
        [[NSNotificationCenter defaultCenter]
            postNotificationName:ORKPixelRemovedNotification
                          object:self];
        
    }
}

- (void) addPixel:(KPixel*)aPixel atIndex:(int)index
{
    if(aPixel){
        [[[self undoManager] prepareWithInvocationTarget:self] removePixelAtIndex:index];
        [pixels insertObject:aPixel atIndex:index];
    }
    else {
        aPixel = [[KPixel alloc] initNewPixel];
        index = [pixels count];
        [[[self undoManager] prepareWithInvocationTarget:self] removePixelAtIndex:index];
        [pixels insertObject:aPixel atIndex:index];
        
    }
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORKPixelAddedNotification
                      object:self];
}

- (void)sort
{
    if([[pixels objectAtIndex:0] sortTypeFor:_sortColumn] == 0){
        if(_sortIsDescending)[pixels sortUsingFunction:sortDnIntFunc context: _sortColumn];
        else [pixels sortUsingFunction:sortUpIntFunc context: _sortColumn];
    }
    else if([[pixels objectAtIndex:0] sortTypeFor:_sortColumn] == 1){
        if(_sortIsDescending)[pixels sortUsingFunction:sortDnStringFunc context: _sortColumn];
        else [pixels sortUsingFunction:sortUpStringFunc context: _sortColumn];
    }
    else if([[pixels objectAtIndex:0] sortTypeFor:_sortColumn] == 2){
        if(_sortIsDescending)[pixels sortUsingFunction:sortDnFloatFunc context: _sortColumn];
        else [pixels sortUsingFunction:sortUpFloatFunc context: _sortColumn];
    }
}

- (void) handleMouseDownAt:(NSPoint)localPoint inView:(NSView*)detectorView
{
    NSEnumerator* e = [pixels objectEnumerator];
    KPixel* pixel;
    while(pixel = [e nextObject]){
        [pixel setSelected:[pixel containsPoint:localPoint usingView:detectorView]];
    }
}

- (void) handleDoubleClickAt:(NSPoint)localPoint inView:(NSView*)detectorView
{
    NSEnumerator* e = [pixels objectEnumerator];
    KPixel* pixel;
    while(pixel = [e nextObject]){
        if([pixel containsPoint:localPoint usingView:detectorView]){
            [pixel openDialog];
        }
        [pixel setSelected:[pixel containsPoint:localPoint usingView:detectorView]];
    }
}

@end


