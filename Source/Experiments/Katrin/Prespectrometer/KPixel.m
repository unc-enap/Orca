//
//  KPixel.m
//  Orca
//
//  Created by Mark Howe on Thu Sep 04 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
//

#import "KPixel.h"
#import "ORShaperModel.h"
#import "ORRateGroup.h"
#import "ORRate.h"
#import "ORColorBar.h"
#import "ORScale.h"

#import <OpenGL/gl.h>
#import <OpenGL/glext.h>
#import <OpenGL/glu.h>

#define xMargin  20
#define yMargin  20
#define pixelsize 20
#define kScaleFactor 1.4
#define kMaxSize 600.

NSString* KPixelSelectionChangedNotification	= @"KPixelSelectionChangedNotification";
NSString* KPixelRateChangedNotification         = @"KPixelRateChangedNotification";
NSString* KPixelParamChangedNotification		= @"KPixelParamChangedNotification";

//sort type
//  0 = int
//  1 = string
//  2 = float
static struct {
    NSString* key;
    int       sortType;
    }kPixelParam[kNumKeys] = {
        { @"kPositionX",   2},
        { @"kPositionY",   2},
        { @"kAdcSlot",     0},
        { @"kAdcChannel",  0},
        { @"kAdcHWAddress",1},
        { @"kAdcName"     ,1},
};

@implementation KPixel

#pragma mark ¥¥¥Initialization
- (id) initNewPixel
{
    self = [super init];
    [self decodeString:@"0,0,0,0,0"];
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
    return NSMakePoint([[params objectForKey:kPixelParam[kPositionX].key] floatValue],[[params objectForKey:kPixelParam[kPositionY].key] floatValue]);
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
        postNotificationName:KPixelSelectionChangedNotification
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
        postNotificationName:KPixelRateChangedNotification
                      object:self];
    
}

- (void)	setReplayMode:(BOOL)aReplayMode
{
	replayMode = aReplayMode;
}

- (BOOL) containsPoint:(NSPoint)localPoint usingView:(NSView*)detectorView
{
    return NSPointInRect(localPoint,NSInsetRect([self frameInRect:[detectorView frame]],-4,-4));
}

- (NSRect) frameInRect:(NSRect)aRect
{
    float w = aRect.size.width;
    float h = aRect.size.height;
    float xpixelSize = w/8.-8;
    float ypixelSize = h/8.-8;
    NSPoint position = [self position];
    return NSMakeRect(5+(position.x*w/8.),5+(position.y*h/8.),xpixelSize,ypixelSize);
}

- (void) drawInRect:(NSRect)aRect withColorBar:(ORColorBar*)aColorBar
{
    NSRect outerRect = [self frameInRect:aRect];

    NSBezierPath* path2 = [NSBezierPath bezierPathWithRect:outerRect];
	NSColor* color;

	color = [aColorBar getColorForValue:shaperRate];

    if(!color)[[NSColor colorWithCalibratedRed:0.90 green:0.95 blue:0.95 alpha:1.0] set];
    else [color set];
    [path2 fill];
    
	if(!hwPresent){
		[[NSColor redColor] set];
		int lineWidth = [NSBezierPath defaultLineWidth];
		[NSBezierPath setDefaultLineWidth:3];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(outerRect.origin.x+2,outerRect.origin.y+2) 
								  toPoint:NSMakePoint(outerRect.origin.x+outerRect.size.width-2,outerRect.origin.y+outerRect.size.height-2)];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(outerRect.origin.x+2,outerRect.origin.y + outerRect.size.height-2) 
								  toPoint:NSMakePoint(outerRect.origin.x+outerRect.size.width-2,outerRect.origin.y+2)];
		[NSBezierPath setDefaultLineWidth:lineWidth];
	}
	else {
		if(!chanOnline){
			NSAttributedString* n = [[NSAttributedString alloc] 
								initWithString:@"OFF"
									attributes:[NSDictionary dictionaryWithObject:[NSFont labelFontOfSize:9] forKey:NSFontAttributeName]];
			NSSize theSize = [n size];
			[n drawInRect:NSMakeRect(outerRect.origin.x + outerRect.size.width/2 - theSize.width/2,
									outerRect.origin.y + outerRect.size.height/2 - theSize.height/2,theSize.width,theSize.height)];
		}
	}

    [[NSColor darkGrayColor] set];
    [path2 setLineWidth:.5];
    [path2 stroke];
    if(selected){
        [[NSColor redColor] set];
		float oldWidth = [NSBezierPath defaultLineWidth];
		[NSBezierPath setDefaultLineWidth:2];
		[NSBezierPath strokeRect:NSInsetRect(outerRect,-1,-1)];
		[NSBezierPath setDefaultLineWidth:oldWidth];
    }
}

// simple cube data
GLint cube_num_vertices = 8;

static GLfloat cube_vertices [8][3] = {
{1.0, 1.0, 1.0}, {1.0, -1.0, 1.0}, {-1.0, -1.0, 1.0}, {-1.0, 1.0, 1.0},
{1.0, 1.0, -1.0}, {1.0, -1.0, -1.0}, {-1.0, -1.0, -1.0}, {-1.0, 1.0, -1.0} };

GLint num_faces = 6;

static short cube_faces [6][4] = {
{3, 2, 1, 0}, {2, 3, 7, 6}, {0, 1, 5, 4}, {3, 0, 4, 7}, {1, 2, 6, 5}, {4, 5, 6, 7} };


- (void) drawIn3DView:(NSRect)aRect withColorBar:(ORColorBar*)rateColorBar
{
    float w = aRect.size.width/2;
    float h = aRect.size.height/2;
    float xpixelSize = w/4.-8;
    float ypixelSize = h/4.-8;
    NSPoint position = [self position];
	long f, i;
	
	float z = -[[rateColorBar colorAxis] getPixAbs:shaperRate]/2;
	if(z < -aRect.size.height/2)z = -aRect.size.height/2;
	float x = 8+(position.x*w/8.);
	float y = 8+(position.y*h/8.);
		cube_vertices[0][0] = x + xpixelSize/4.;
		cube_vertices[0][2] = y + ypixelSize/4.;
		cube_vertices[0][1] = 0;
		
		cube_vertices[1][0] = x + xpixelSize/4.;
		cube_vertices[1][2] = y - ypixelSize/4.;
		cube_vertices[3][1] = 0;
		
		cube_vertices[2][0] = x - xpixelSize/4.;
		cube_vertices[2][2] = y - ypixelSize/4.;
		cube_vertices[3][1] = 0;
		
		cube_vertices[3][0] = x - xpixelSize/4.;
		cube_vertices[3][2] = y + ypixelSize/4.;
		cube_vertices[3][1] = 0;
		
		cube_vertices[4][0] = x + xpixelSize/4.;
		cube_vertices[4][2] = y + ypixelSize/4.;
		cube_vertices[4][1] = z;
		
		cube_vertices[5][0] = x + xpixelSize/4.;
		cube_vertices[5][2] = y - ypixelSize/4.;
		cube_vertices[5][1] = z;
		
		cube_vertices[6][0] = x - xpixelSize/4.;
		cube_vertices[6][2] = y - ypixelSize/4.;
		cube_vertices[6][1] = z;
		
		cube_vertices[7][0] = x - xpixelSize/4.;
		cube_vertices[7][2] = y + ypixelSize/4.;
		cube_vertices[7][1] = z;

	if (1) {
		NSColor* color = [rateColorBar getColorForValue:shaperRate];
		if(!color) glColor3f (0.9, 0.95, 0.95);
		else	   glColor3f ([color redComponent], [color greenComponent], [color blueComponent]);
		glBegin (GL_QUADS);
		for (f = 0; f < num_faces; f++) {
			for (i = 0; i < 4; i++) {
				//glColor3f ([color redComponent], [color greenComponent], [color blueComponent]);
				glVertex3f(cube_vertices[cube_faces[f][i]][0], cube_vertices[cube_faces[f][i]][1], cube_vertices[cube_faces[f][i]][2]);
			}
		}
		glEnd ();
	}
	if (1) {
		glColor3f (0.0, 0.0, 0.0);
		for (f = 0; f < num_faces; f++) {
			glBegin (GL_LINE_LOOP);
			for (i = 0; i < 4; i++){
				glVertex3f(cube_vertices[cube_faces[f][i]][0], cube_vertices[cube_faces[f][i]][1], cube_vertices[cube_faces[f][i]][2]);
			}
			glEnd ();
		}
	}

}


- (void) decodeString:(NSString*)aString
{
    if(!params){
        [self setParams:[NSMutableDictionary dictionary]];
    }
    NSArray* items = [aString componentsSeparatedByString:@","];
    int i;
    int count = [items count];
    if(count<=kNumKeys){
        for(i=0;i<count;i++){
            [params setObject:[items objectAtIndex:i] forKey:kPixelParam[i].key];
        }
		
        //params NOT in the tub map
        [params setObject:[NSNumber numberWithBool:YES] forKey:@"kCableCheck"];

        isValid = YES;
    }
    
}

- (void) registerForShaperRates:(NSArray*)collectionOfShapers
{
    NSEnumerator* e = [collectionOfShapers objectEnumerator];
    ORShaperModel* shaper;
    while(shaper = [e nextObject]){
        if([[params objectForKey: kPixelParam[kAdcSlot].key]intValue] == [shaper slot]){
            id rateObj = [[shaper adcRateGroup] rateObject:[[params objectForKey: kPixelParam[kAdcChannel].key]intValue]];
            NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
            [notifyCenter addObserver : self
                             selector : @selector(shaperRateChanged:)
                                 name : ORRateChangedNotification
                               object : rateObj];
            break;
            
        }
    }
}


- (void) loadTotalCounts:(NSArray*)collectionOfShapers
{
    NSEnumerator* e = [collectionOfShapers objectEnumerator];
    ORShaperModel* shaper;
    while(shaper = [e nextObject]){
        if([[params objectForKey: kPixelParam[kAdcSlot].key]intValue] == [shaper slot]){
			int channel = [[params objectForKey: kPixelParam[kAdcChannel].key]intValue];
			[self setShaperRate:[shaper adcCount:channel]];
		}
	}
}

- (NSMutableString*) pixelMapLine
{
    
    NSMutableString* s = [NSMutableString string];
    int i;
    for(i=0;i<kNumKeys;i++){
        NSString* item = [params objectForKey:kPixelParam[i].key];
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
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:KPixelParamChangedNotification
                      object:self];
    
}


-(id) objectForKeyIndex:(int)keyIndex
{
    return [self objectForKey:kPixelParam[keyIndex].key];
}

- (NSUndoManager*) undoManager
{
    return [[NSApp delegate] undoManager];
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

- (void) checkHWStatus:(NSArray*)someShapers
{
	int card;

	//assume the worst
	hwPresent = NO;
	chanOnline = NO;
	
	for(card = 0;card<[someShapers count];card++){
		id shaper = [someShapers objectAtIndex:card];
		if([shaper slot] == [[params objectForKey: kPixelParam[kAdcSlot].key]intValue]){
			hwPresent = YES;
			int chan = [[params objectForKey: kPixelParam[kAdcChannel].key]intValue];
			if([shaper onlineMaskBit:chan])chanOnline = YES;
			break;
		}
	}
}

static NSString* KPixelIsValid     = @"KPixelIsValid";
static NSString* KPixelParams      = @"KPixelParams";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    [self setIsValid:[decoder decodeBoolForKey:KPixelIsValid]];
    [self setParams:[decoder decodeObjectForKey:KPixelParams]];
    if(!params){
        [self setParams:[NSMutableDictionary dictionary]];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeBool:isValid forKey:KPixelIsValid];
    [encoder encodeObject:params forKey:KPixelParams];
}

- (int) compareIntTo:(id)aPixel usingKey:(NSString*)aKey
{
    return [[self objectForKey:aKey] intValue] - [[aPixel objectForKey:aKey] intValue];
}

- (int) compareFloatTo:(id)aPixel usingKey:(NSString*)aKey
{
    float val = ([[self objectForKey:aKey] floatValue] - [[aPixel objectForKey:aKey] floatValue]);
    if(val>0)return 1;
    else if(val<0)return -1;
    else return 0;
}

- (int) compareStringTo:(id)aPixel usingKey:(NSString*)aKey
{
    NSString* ourKey = [self objectForKey:aKey];
    NSString* theirKey = [aPixel objectForKey:aKey];
    if(!ourKey && theirKey)         return 1;
    else if(ourKey && !theirKey)    return -1;
    else if(!ourKey || !theirKey)   return 0;
    return [ourKey compare:theirKey];
}

- (int) sortTypeFor:(NSString*)aKey
{
    int i;
    for(i=0;i<kNumKeys;i++){
        if([kPixelParam[i].key isEqualToString:aKey]){
            return kPixelParam[i].sortType;
        }
    }
    return 0;
}

- (NSString*) description
{
    NSString* string = [NSString string];
    string = [string stringByAppendingFormat:@"Adc Addr : %@\n",[params objectForKey:kPixelParam[kAdcHWAddress].key]];
    string = [string stringByAppendingFormat:@"Adc Slot : %@\n",[params objectForKey:kPixelParam[kAdcSlot].key]];
    string = [string stringByAppendingFormat:@"Adc Chan : %@\n",[params objectForKey:kPixelParam[kAdcChannel].key]];
	NSString* theName = [params objectForKey:kPixelParam[kAdcName].key];
    if(theName && [theName length]){
		string = [string stringByAppendingFormat:@"Name     : %@\n",theName];
	}
    return string;
}

- (void) openDialog
{
    NSArray* allShapers = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORShaperModel")];
    ORShaperModel* aShaper;
    NSEnumerator* shaperEnummy = [allShapers objectEnumerator];
    while(aShaper = [shaperEnummy nextObject]){
        const char* addressString = [[params objectForKey:kPixelParam[kAdcHWAddress].key] UTF8String];
        int addressValue = strtol(addressString,nil,16);
        if([aShaper baseAddress] == addressValue){
            [aShaper showMainInterface];
            break;
        }
    }
}



@end
