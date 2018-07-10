//
//  ORTimeLine.m
//  Orca
//
//  Created by Mark Howe on Tue Sep 09 2003.
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

#import "ORTimeLine.h"

@implementation ORTimeLine

enum {
    SHORT_TICK		= 1,				// length of short tick
    MED_TICK		= 2,				// length of medium tick
    LONG_TICK		= 3				// length of long tick
};

/*
 * Definitions for text size calculations
 */
#define	YLDX				(-LONG_TICK - 3)	// y-label dx (right edge)
#define	YLDY				3			// y-label dy (center)

/* other definitions */
#define	FIRST_POW		-15			// first symbol exponent
static char	symbols[]	= "fpnum\0kMG";		// symbols for exponents

-(id) initWithFrame:(NSRect)aFrame
{
    self = [super initWithFrame:aFrame];
    return self;
}

- (void) drawLogScale
{
    [self setLog:NO];
    [self drawLinScale];
}

-(NSString*) dateFormat
{
    return [attributes objectForKey:@"dateFormat"];
}

- (NSTimeInterval) startTime
{
	return startTime;
}

- (void) setStartTime:(NSTimeInterval)aStartTime
{
	startTime = aStartTime;
}

- (void) setDateFormat:(NSString*) aFormatString
{
    /* set the instance variable */
    if(aFormatString){
		[attributes setObject:aFormatString forKey:@"dateFormat"];
	}
    [self rangingDonePostChange];
}

-(void)	drawLinScale
{
    
	NSAssert([NSThread mainThread],@"ORTimeLine drawing from non-gui thread");
    short		i, x, y;			// general variables
    double		val;				// true value of scale units
    long		ival;				// integer mantissa of scale units
    short		sep;				// mantissa of label separation
    short		power;				// exponent of label separation
    short		ticks;				// number of ticks per label
    short		sign = 1;			// sign of scale range
    double		order;				// 10^power
    double		step;				// distance between labels (scale units)
    double		tstep;				// distance between ticks (scale units)
    double		tol;				// tolerance for equality (1/2 pixel)
    double		lim;				// limit for loops
    NSBezierPath* 	theAxis = [NSBezierPath bezierPath];
    NSBezierPath* 	theAxisColoredTicks = [NSBezierPath bezierPath];
    [theAxisColoredTicks setLineWidth:3];
    
    NSString* theDateFormat = [self dateFormat];
	if(!theDateFormat)theDateFormat = @"M/d/yy H:m:s";
	gridCount = 0;    
    tstep  = [self getValRel:[self optimalLabelSeparation]];
    
    if (tstep < 0) {
        sign = -1;
        tstep *= sign;
    }
    /*
	 ** Old getSep() Routine:  Determine axis labelling strategies.
	 **
	 ** Input:	tstep = number of units between optimally spaced labels
	 ** Output:	tick  = number of units between ticks
	 **          sep   = number of units between labels
	 */
    power = floor(log10(tstep));					// exponent part of label sep
    
    if ([self integer] && power<0) power = 0;
    
    i     = 10.0*tstep/(order = pow(10.0,power));	// get first two digits
    
    if      (i >= 65) { sep = 1; ticks = 5; ++power; order*=10; }
    else if (i >= 35) { sep = 5; ticks = 5; }
    else if (i >= 15) { sep = 2; ticks = 4; }
    else		 	  { sep = 1; ticks = 5; }
    
    if (!power && [self integer]) ticks = sep;		// no sub-ticks for integer scales
    /*
	 ** End of old getSep() routine
	 */
    step   = sep  * order;
    ival   = floor([self minPad]/step);
    val	   = ival * step;			// value for first label below scale
    tstep  = step/ticks;
    ival  *= sep;
	char suffix = symbols[(power-FIRST_POW)/3];
    
    switch ((power-FIRST_POW)%3) {
        case 0:
			break;
        case 1:
            ival *= 10;
            sep  *= 10;
			break;
        case 2:
            if (suffix) {			// a- (void) extra trailing zeros if suffix
                suffix= symbols[(power-FIRST_POW)/3+1];		// next suffix
            } else {
                ival *= 100;
                sep  *= 100;
            }
			break;
    }
    tol  = [self getValRel:1]/2;
    lim  = -tol;
    val -= [self minPad];						// subtract origin (GetPixRel is relative)
    
    if (val*sign < lim*sign) {
        ival += sep;					// get ival for first label
        for (i=0; val*sign<lim*sign; ++i) {
            val += tstep;				// find first tick on scale
        }
    } 
	else i = ticks;					// first tick is at label
    
    lim  = [self valueRange] + tol;		// upper limit for scale value
	unsigned short nthTick = 0;
    
    if ([self isXAxis]) {

        y = [self frame].size.height;
		
        [theAxis moveToPoint:NSMakePoint(lowOffset-2,y)];						// draw axis line
        [theAxis lineToPoint:NSMakePoint(highOffset+1,y)];
        --y;
		BOOL first = YES;
        for (;;) {
            x = lowOffset + [self getPixRel:val];				// get pixel position
            [theAxis moveToPoint:NSMakePoint(x,y)];
			int dateOffset;
			
            if (i < ticks) {
                if (ticks==4 && i==2) [theAxis lineToPoint:NSMakePoint(x,y-MED_TICK)];			// draw medium tick
				else				  [theAxis lineToPoint:NSMakePoint(x,y-SHORT_TICK)];			// draw short tick
                ++i;
			} 
			else {
                if ((nthTick % 4) == 0) {
					NSString* axisNumberString;
                    [theAxisColoredTicks moveToPoint:NSMakePoint(x,y)];
                    [theAxisColoredTicks lineToPoint:NSMakePoint(x,y-LONG_TICK)];			// draw long tick

					if(suffix == 'k')ival *= 1000;
					else if(suffix == 'M') ival *= 1000000;
					else if(suffix == 'G') ival *= 1000000000;
					NSDate *aDate = [NSDate dateWithTimeIntervalSince1970:ival+startTime];
					axisNumberString = [aDate descriptionFromTemplate:theDateFormat];
					nthTick = 0;
				
					
					NSSize axisNumberSize = [axisNumberString sizeWithAttributes:labelAttributes];
					if(first) {
						dateOffset = axisNumberSize.width/2-10;
						first = NO;
					}
					else     dateOffset = -20;
					
					[axisNumberString drawAtPoint:NSMakePoint(x+YLDX+dateOffset - axisNumberSize.width/2,y-YLDY-axisNumberSize.height) withAttributes:labelAttributes];
                    
				} 
				else [theAxis lineToPoint:NSMakePoint(x,y-LONG_TICK)];			// draw long tick

                if (gridCount<kMaxLongTicks) {
                    gridArray[gridCount++] = x-lowOffset;
                }
                
                nthTick++;
                ival += sep;
                i = 1;
            }
            val += tstep;
            if (sign==1) {
                if (val > lim) break;
			} 
			else {
                if (val < lim) break;
            }
        }
        NSArray* markers = [attributes objectForKey:ORAxisMarkers];
        for(id markerNumber in markers){
            [self drawMarker:[markerNumber floatValue] axisPosition:0];
        }
        if(markerBeingDragged){
            [self drawMarker:[markerBeingDragged floatValue] axisPosition:0];
        }

	}
    else {
        // Do nothing, should not be Y axis.
    }

    [[self color] set];
    [theAxis setLineWidth:1];
    [theAxis stroke];
    [[NSColor blueColor] set];
    [theAxisColoredTicks stroke];
}

- (NSString*) markerLabel:(NSNumber*)markerNumber
{
    NSString* theDateFormat = [self dateFormat];
    if(!theDateFormat)theDateFormat = @"M/d/yy H:m:s";
    float markerValue = [markerNumber floatValue];
    NSDate *aDate = [NSDate dateWithTimeIntervalSince1970:markerValue+startTime];
    return [aDate descriptionFromTemplate:theDateFormat];
}

@end
