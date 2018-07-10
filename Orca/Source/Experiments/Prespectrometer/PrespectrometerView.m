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

#import "PrespectrometerView.h"
#import "PrespectrometerModel.h"
#import "ORColorScale.h"

@implementation PrespectrometerView
- (void) awakeFromNib
{
	[prespecColorScale setExcludeZero:YES];
	[super awakeFromNib];
}

- (void) makeAllSegments
{
	[super makeAllSegments];
	
	float w = [self bounds].size.width;
	float h = [self bounds].size.height;
	float xc = [self bounds].size.width/2.;
	float yc = [self bounds].size.height/2.;
	float segSize = MIN(w/8.,h/8.);
	NSMutableArray* segmentPaths = [NSMutableArray arrayWithCapacity:64];
	NSMutableArray* errorPaths = [NSMutableArray arrayWithCapacity:64];
	
	NSRect segRect = NSMakeRect(xc - (segSize*8.)/2.,yc + (segSize*8.)/2.,segSize,segSize);
	int i;
	for(i=0;i<8;i++){
		int j;
		for(j=0;j<8;j++){
			NSBezierPath* aPath = [NSBezierPath bezierPath];
			NSRect theRect = NSOffsetRect(segRect,j*segSize,-i*segSize - segSize);
			[aPath appendBezierPathWithRect:theRect];
			[segmentPaths addObject:aPath];

			[labelPathSet addObject:[NSDictionary dictionaryWithObjectsAndKeys:
												[NSNumber numberWithFloat:theRect.origin.x+3],@"X",
												[NSNumber numberWithFloat:NSMidY(theRect)],@"Y",nil]];
			

			theRect = NSInsetRect(theRect,segSize/2.5,segSize/2.5);
			[errorPaths addObject:[NSBezierPath bezierPathWithOvalInRect:theRect]];
			
		}
	}
	[segmentPathSet addObject:segmentPaths];
	[errorPathSet addObject:errorPaths];
}

- (NSColor*) getColorForSet:(int)setIndex value:(float)aValue
{
	return [prespecColorScale getColorForValue:aValue];
}

- (void) upArrow
{
	selectedPath-=8;
	if(selectedPath<0){
		if(selectedPath==-8)selectedPath = 63;
		else selectedPath = 64+selectedPath-1;
	}
}

- (void) downArrow
{
	selectedPath += 8;
	if(selectedPath>=64){
		if(selectedPath==71)selectedPath = 0;
		else selectedPath -= 63;
	}
}

- (void) leftArrow
{
	selectedPath--;
	if(selectedPath<0)selectedPath = 64-1;
}

- (void) rightArrow
{
	selectedPath++;
	selectedPath%=64;
}
@end
