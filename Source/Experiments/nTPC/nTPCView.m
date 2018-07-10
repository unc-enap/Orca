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

#import "nTPCView.h"
#import "ORColorScale.h"
#import "nTPCConstants.h"
#import "ORExperimentModel.h"
#import "ORDetectorView.h"
#import "ORSegmentGroup.h"

#define highlightLineWidth 2

@implementation nTPCView

- (void) makeAllSegments
{
	[super makeAllSegments];
	
	float h = [self bounds].size.height;
	float w = [self bounds].size.width;
	
	//=========the Anode Plane Part=============
	NSMutableArray* segmentPaths = [NSMutableArray arrayWithCapacity:kNumAnodeWires];
	NSMutableArray* errorPaths = [NSMutableArray arrayWithCapacity:kNumAnodeWires];

	float totalWidth = [self bounds].size.width;
	float anodePlusSpaceWidth = totalWidth/(float)kNumAnodeWires;
	float anodeWidth = anodePlusSpaceWidth;
	if(anodeWidth<1)anodeWidth = 1;
	float anodeSpace = anodePlusSpaceWidth - anodeWidth;
	
	float x = anodeSpace/2;
	int j;
	for(j=0;j<kNumAnodeWires;j++){
		NSBezierPath* aPath = [NSBezierPath bezierPathWithRect:NSMakeRect(x,0,anodeWidth,h)];
		[segmentPaths addObject:aPath];
					
		aPath = [NSBezierPath bezierPathWithRect:NSMakeRect(x-anodeWidth/2,0,anodeWidth,h)];
		[errorPaths addObject:aPath];

		x += anodePlusSpaceWidth;
	}
	//store into the whole set
	[segmentPathSet addObject:segmentPaths];
	[errorPathSet addObject:errorPaths];

	//=========the Cathode Plane Part=============
	NSMutableArray* segment1Paths = [NSMutableArray arrayWithCapacity:kNumCathodeWires];
	NSMutableArray* error1Paths = [NSMutableArray arrayWithCapacity:kNumCathodeWires];
	float totalHeight = [self bounds].size.height;
	float cathodePlusSpaceWidth = totalHeight/(float)kNumCathodeWires;
	float cathodeWidth = cathodePlusSpaceWidth*.25;
	if(cathodeWidth<1)cathodeWidth= 1;
	float cathodeSpace = cathodePlusSpaceWidth - cathodeWidth;
	
	float y = cathodeSpace/2;
	
	for(j=0;j<kNumCathodeWires;j++){
		NSBezierPath* aPath = [NSBezierPath bezierPathWithRect:NSMakeRect(0,y,w,cathodeWidth)];
		[segment1Paths addObject:aPath];
					
		aPath = [NSBezierPath bezierPathWithRect:NSMakeRect(0,y-2,w,cathodeWidth+4)];
		[error1Paths addObject:aPath];
		y += cathodePlusSpaceWidth;
	}
	//store into the whole set
	[segmentPathSet addObject:segment1Paths];
	[errorPathSet addObject:error1Paths];
}

- (NSColor*) getColorForSet:(int)setIndex value:(unsigned long)aValue
{
	return [colorScale getColorForValue:aValue];
}


- (void) upArrow
{
	selectedPath++;
	if(selectedSet == 0) selectedPath %= kNumAnodeWires;
	else				 selectedPath %= kNumCathodeWires;
}

- (void) downArrow
{
	selectedPath--;
	if(selectedSet == 0){
		if(selectedPath < 0) selectedPath = kNumAnodeWires-1;
	}
	else {
		if(selectedPath < 0) selectedPath = kNumCathodeWires-1;
	}
}

- (void) leftArrow
{
	if(selectedSet == 0){
		selectedPath--;
		if(selectedPath < 0) selectedPath = kNumAnodeWires-1;
	}
	else {
		selectedPath--;
		if(selectedPath < 0) selectedPath = kNumCathodeWires-1;
	}
}

- (void) rightArrow
{
	if(selectedSet == 0) {
		selectedPath++;
		selectedPath %= kNumAnodeWires;
	}
	else {
		selectedPath++;
		selectedPath %= kNumCathodeWires;
	}
}

- (void)drawRect:(NSRect)rect
{
	int displayType = [delegate displayType];
	BOOL displayErrors = ([delegate hardwareCheck]==0) || ([delegate cardCheck]==0);
	int setIndex;
	int numSets = [segmentPathSet count];

	
	for(setIndex = 0;setIndex<numSets;setIndex++){
		int segmentIndex;
		NSArray* arrayOfSegmentPaths = [segmentPathSet objectAtIndex:setIndex];
		int numSegments = [arrayOfSegmentPaths count];
		ORSegmentGroup* segmentGroup = [delegate segmentGroup:setIndex];
		for(segmentIndex = 0;segmentIndex<numSegments;segmentIndex++){
			NSBezierPath*   segmentPath  = [arrayOfSegmentPaths objectAtIndex:segmentIndex];
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
							displayColor = [self getColorForSet:setIndex value:(int)displayValue];
						}
						else {
							if(displayValue)displayColor = [NSColor blackColor];
						}
					}
				}
				//else [[NSColor whiteColor] set];
			}
			//else [[NSColor blackColor] set];
			if(displayColor){
				[displayColor set];
				[segmentPath fill];
			}
			//display error spot if needed
			if(displayErrors && [segmentGroup getError:segmentIndex]){
				NSArray* arrayOfErrorPaths   = [errorPathSet objectAtIndex:setIndex];
				[[NSColor colorWithCalibratedRed:.7 green:.2 blue:.2 alpha:1] set];
				[[arrayOfErrorPaths objectAtIndex:segmentIndex] fill];
			}
		}
		
	}
			
	//the the highlighted segment
	if(selectedSet>=0 && selectedPath>=0){	
		NSArray* arrayOfSegmentPaths = [segmentPathSet objectAtIndex:selectedSet];
		NSBezierPath*   segmentPath  = [arrayOfSegmentPaths objectAtIndex:selectedPath];
		[segmentPath setLineWidth:1];
		[[NSColor colorWithCalibratedRed:.7 green:.2 blue:.2 alpha:1] set];
		[segmentPath stroke];
	}
	
	[[NSColor blackColor] set];
	[NSBezierPath strokeRect:[self bounds]];

} 


@end