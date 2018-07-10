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

#import "nTPCPadPlaneView.h"
#import "ORColorScale.h"
#import "nTPCConstants.h"
#import "ORExperimentModel.h"
#import "ORDetectorView.h"
#import "ORSegmentGroup.h"
#import "ORAxis.h"
#import "nTPCModel.h"

#define highlightLineWidth 2

@implementation nTPCPadPlaneView
- (void) awakeFromNib
{
	[colorScale setExcludeZero:YES];
	[super awakeFromNib];
	[self performSelector:@selector(delayedSetup) withObject:nil afterDelay:.1];
}
- (void) delayedSetup
{
	[xScale setRngLimitsLow:-150 withHigh:150 withMinRng:300];
	[yScale setRngLimitsLow:-130 withHigh:130 withMinRng:2600];

    [xScale setRngDefaultsLow:-150 withHigh:150];
    [yScale setRngDefaultsLow:-130 withHigh:130];
	[xScale setNeedsDisplay:YES];
	[yScale setNeedsDisplay:YES];
	[self makeAllSegmentsLocal];
	selectedSet		= -1;
	selectedPath    = -1;
}

- (void) loadPixelCoords
{
	NSBundle* mainBundle = [NSBundle mainBundle];
	NSString* path       = [mainBundle pathForResource: @"nTPCPadPositions" ofType: @"txt"];
	int i,j,k;
	for(i=0;i<3;i++){
		for(j=0;j<55;j++){
			for(k=0;k<100;k++){
				pixel[i][j][k] = NSMakePoint(-999,-999);
			}
		}
	}
		
	if([[NSFileManager defaultManager] fileExistsAtPath:path]){
		NSString* contents = [NSString stringWithContentsOfFile:path encoding:NSASCIIStringEncoding error:nil];
		NSArray* lines = [contents componentsSeparatedByString:@"\n"];
		int lastWire = -1;
		int k = 0;
		for(id aLine in lines){
			NSArray* parts = [aLine componentsSeparatedByString:@","];
			if([parts count] ==4) {
				int group	= [[parts objectAtIndex:0] intValue];
				int wire	= [[parts objectAtIndex:1] intValue];
				float x		= [[parts objectAtIndex:2] floatValue];
				float y		= [[parts objectAtIndex:3] floatValue];
				if(group>=0 && group<3 && wire>=0 && wire<55){
					float xx = [xScale getPixAbs:(double)x]; 
					float yy = [yScale getPixAbs:(double)y]; 
					if(k<100)pixel[group][wire][k++] = NSMakePoint(xx,yy);
					if(lastWire==-1)lastWire = wire;
					if(wire != lastWire){
						lastWire = wire;
						k=0;
					}
				}
			}
		}
	}
	coordsLoaded = YES;
}

- (void) makeAllSegmentsLocal
{
	
	[super makeAllSegments];
		
	if(!coordsLoaded)[self loadPixelCoords];
	int i,j,k;
	for(i=0;i<3;i++){
		NSMutableArray* segmentPaths = [NSMutableArray arrayWithCapacity:kNumPadPlaneWires];
		for(j=0;j<kNumPadPlaneWires;j++){
			NSMutableArray* dupPaths = [NSMutableArray arrayWithCapacity:kNumPadPlaneWires];
			for(k=0;k<100;k++){
				NSPoint aPixel = pixel[i][j][k];
				if(aPixel.x == -999 && aPixel.y == -999) break;
				NSBezierPath* aPath = [NSBezierPath bezierPathWithRect:NSMakeRect(aPixel.x-1.5,aPixel.y-1.5,3,3)];
				[dupPaths addObject:aPath];
			}
			[segmentPaths addObject:dupPaths];		
		}
		//store into the whole set
		[segmentPathSet addObject:segmentPaths];
	}
}

- (NSColor*) getColorForSet:(int)setIndex value:(float)aValue
{
	return [colorScale getColorForValue:aValue];
}

- (void) drawRect:(NSRect)rect
{
	int displayType = [delegate displayType];
	int setIndex;
	int numSets = [segmentPathSet count];
	unsigned short aMask = [delegate planeMask];

	for(setIndex = 0;setIndex<numSets;setIndex++){
		if(!(aMask & (1<<setIndex)))continue;
		int segmentIndex;
		NSArray* arrayOfSegmentPaths = [segmentPathSet objectAtIndex:setIndex];
		int numSegments = [arrayOfSegmentPaths count];
		ORSegmentGroup* segmentGroup = [delegate segmentGroup:setIndex];
		for(segmentIndex = 0;segmentIndex<numSegments;segmentIndex++){
			NSArray* dupPaths = [arrayOfSegmentPaths objectAtIndex:segmentIndex];
			for(id segmentPath in dupPaths){
				NSColor* displayColor = nil;
				if([segmentGroup hwPresent:segmentIndex]){
					if([segmentGroup online:segmentIndex]){
						float displayValue;
						switch(displayType){
							case kDisplayEvents:	 displayValue = [segmentGroup getPartOfEvent:segmentIndex];	break;
							case kDisplayThresholds: displayValue = [segmentGroup getThreshold:segmentIndex];	break;
							case kDisplayGains:		 displayValue = [segmentGroup getGain:segmentIndex];		break;
							default:				 displayValue = [segmentGroup getRate:segmentIndex];		break;
						}
						if(displayValue){
							if(displayType != kDisplayEvents){
								displayColor = [self getColorForSet:setIndex value:displayValue];
							}
							else {
								if(displayValue)displayColor = [NSColor blackColor];
							}
						}
					}
					else [[NSColor whiteColor] set];
				}
				else [[NSColor blackColor] set];
				if(displayColor){
					[displayColor set];
					[segmentPath fill];
				}
			}
		}
		
	}
			
	//the the highlighted segment
	if(selectedSet>=0 && selectedPath>=0){	
		NSArray* arrayOfSegmentPaths = [segmentPathSet objectAtIndex:selectedSet];
		NSArray* dupPaths = [arrayOfSegmentPaths objectAtIndex:selectedPath];
		for(id segmentPath in dupPaths){
			[segmentPath setLineWidth:1];
			[[NSColor colorWithCalibratedRed:.7 green:.2 blue:.2 alpha:1] set];
			[segmentPath stroke];
		}
	}
	
	[[NSColor blackColor] set];
	[NSBezierPath strokeRect:[self bounds]];

} 

- (void) mouseDown:(NSEvent*)anEvent
{
    NSPoint localPoint = [self convertPoint:[anEvent locationInWindow] fromView:nil];
	
	//localPoint.x = [xScale getValAbs:localPoint.x]; 
	//localPoint.y = [yScale getValAbs:localPoint.y]; 
	//NSLog(@"%.2f %.2f\n",localPoint.x,localPoint.y);
	BOOL foundOne = NO;
	int i,j,k;
	unsigned short aMask = [delegate planeMask];
	for(i=0;i<3;i++){
		if(!(aMask & (1<<i)))continue;
		for(j=0;j<kNumPadPlaneWires;j++){
			for(k=0;k<100;k++){
				NSPoint p = pixel[i][j][k];
				if(p.x==-999 && p.y==-999)break;
				if(fabsf(localPoint.x-p.x)<=2 && fabsf(localPoint.y-p.y)<=2){
					selectedSet  = i;
					selectedPath = j;
					foundOne = YES;
					break;
				}
			}
			if(foundOne)break;
		}
		if(foundOne)break;
	}
	[delegate selectedSet:selectedSet segment:selectedPath];
	if(selectedSet>=0 && selectedPath>=0 && [anEvent clickCount] >= 2){
		if([anEvent modifierFlags] & NSCommandKeyMask){
			[delegate showDataSetForSet:selectedSet segment:selectedPath];
		}
		else {
			[delegate showDialogForSet:selectedSet segment:selectedPath];
		}
	}
	[self setNeedsDisplay:YES];
}


@end