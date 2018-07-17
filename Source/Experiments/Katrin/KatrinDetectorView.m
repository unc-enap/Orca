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

#import "KatrinDetectorView.h"
#import "ORColorScale.h"
#import "KatrinConstants.h"
#import "ORSegmentGroup.h"
#import "ORDetectorSegment.h"
#import "ORAxis.h"
#import "KatrinModel.h"
#define crateX 48.
#define crateY 265.
#define crateW 313.
#define crateH 188.

@interface KatrinDetectorView (private)
- (void) makeAllSegments;
- (void) makeVetoSegments;
@end

@implementation KatrinDetectorView

- (void) dealloc
{
	[theBackground release];
	[super dealloc];
}

- (void) awakeFromNib
{	
	[theBackground release];
	theBackground = [[NSImage imageNamed:@"IpeV4CrateBig"] retain];
	[[focalPlaneColorScale colorAxis] setLabel:@"Main Focal Plane"];
	[[vetoColorScale colorAxis] setLabel:@"Veto"];
	[[vetoColorScale colorAxis] setOppositePosition:YES];
	[focalPlaneColorScale setExcludeZero:YES];
	[vetoColorScale setExcludeZero:YES];

}

- (void) setViewType:(int)aViewType
{
	viewType = aViewType;
}

- (void) drawRect:(NSRect)rect
{
	if(viewType == kUseCrateView){
		float h = [self bounds].size.height;
		//float w = [self bounds].size.width;
		float extra = 75;
		float imageHeight = [theBackground size].height;
		float imageWidth = [theBackground size].width;
		NSRect destRect = NSMakeRect(25,h-imageHeight-extra-40,imageWidth+extra,imageHeight+extra);
		NSRect srcRect = NSMakeRect(0,0,imageWidth,imageHeight);
		
		[theBackground drawInRect:destRect fromRect:srcRect operation:NSCompositingOperationSourceOver fraction:1.0];
		[[NSColor blackColor] set];
		[NSBezierPath fillRect:NSMakeRect(crateX,crateY, crateW,crateH)];
		[[NSColor whiteColor] set];
		float dx = crateW/21.;
		int i;
		NSFont* font = [NSFont systemFontOfSize:9.0];
		NSDictionary* attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName,[NSColor whiteColor],NSForegroundColorAttributeName,nil];
		for(i=0;i<21;i++){
			[NSBezierPath strokeLineFromPoint:NSMakePoint(crateX + i*dx,crateY) toPoint:NSMakePoint(crateX + i*dx,crateY+crateH )];
			if(i%2 != 1){
				NSAttributedString* s = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d",i+1] attributes:attrsDictionary];
				float sw = [s size].width;
				float sh = [s size].height;
				[s drawAtPoint:NSMakePoint(crateX + i*dx + (dx/2.- sw/2.),crateY-sh)];
                [s release];
			}
		}
	}
	else if(viewType == kUsePreampView){
		//float xc = [self bounds].size.width/2;
		//float yc = [self bounds].size.height/2;
		//NSBezierPath* aPath = [NSBezierPath bezierPath];
		//NSPoint centerPoint = NSMakePoint(xc,yc);
		//float r = MIN(xc,yc)-5;
		//[aPath appendBezierPathWithArcWithCenter:centerPoint radius:r startAngle:360 endAngle:0 clockwise:YES];
		//[aPath closePath];
				
		//[[NSColor blackColor] set];
		//[aPath stroke];
	}
	[super drawRect:rect];
}

- (NSColor*) getColorForSet:(int)setIndex value:(float)aValue
{
	if(setIndex==0)return [focalPlaneColorScale getColorForValue:aValue];
	else return [vetoColorScale getColorForValue:aValue];
}

- (void) upArrow
{
	selectedPath++;
	if(selectedSet == 0) selectedPath %= kNumFocalPlaneSegments;
	else				 selectedPath %= kNumVetoSegments;
}

- (void) downArrow
{
	selectedPath--;
	if(selectedSet == 0){
		if(selectedPath < 0) selectedPath = kNumFocalPlaneSegments-1;
	}
	else {
		if(selectedPath < 0) selectedPath = kNumVetoSegments-1;
	}
}

- (void) leftArrow
{
	if(selectedSet == 0){

		int d;
		if(selectedPath>=0 && selectedPath<4)d = 4;
		else if(selectedPath>=4 && selectedPath<12)d = 8;
		else d= 12;

		selectedPath-=d;
		if(selectedPath == -4) selectedPath = kNumFocalPlaneSegments-1;
		else if(selectedPath < 0) selectedPath = 0;
	}
	else {
		selectedPath--;
		if(selectedPath < 0) selectedPath = kNumVetoSegments-1;
	}
}

- (void) rightArrow
{
	if(selectedSet == 0) {
		int d;
		if(selectedPath>=0 && selectedPath<4)d = 4;
		else if(selectedPath>=4 && selectedPath<12)d = 8;
		else d= 12;
		selectedPath+=d;
		if(selectedPath > kNumFocalPlaneSegments-1) selectedPath = 0;
	}
	else {
		selectedPath++;
		selectedPath %= kNumVetoSegments;
	}
}
@end
@implementation KatrinDetectorView (private)
- (void) makeAllSegments
{
	float pi = 3.1415927;
	float xc = [self bounds].size.width/2;
	float h  = [self bounds].size.height;
	
	float r = xc*.14;			//radius of the center focalPlaneSegment NOTE: sets the scale of the whole thing
	float area = 2*pi*r*r;		//area of the center focalPlaneSegment
	
	[super makeAllSegments];
	
	NSPoint centerPoint = NSMakePoint(xc,h-xc - 1);

	if(viewType == kUseCrateView){
				
		float dx = crateW/21.;
		float dy = crateH/24.;
		int set;
		int numSets = [delegate numberOfSegmentGroups];
		for(set=0;set<numSets;set++){
			NSMutableArray* segmentPaths = [NSMutableArray arrayWithCapacity:kNumFocalPlaneSegments];
			NSMutableArray* errorPaths   = [NSMutableArray arrayWithCapacity:kNumFocalPlaneSegments];
			ORSegmentGroup* aGroup = [delegate segmentGroup:set];
			int i;
			int n = [aGroup numSegments];
			for(i=0;i<n;i++){
				ORDetectorSegment* aSegment = [aGroup segment:i];
				int cardSlot = [aSegment cardSlot]-1;
				int channel = [aSegment channel];
				if(channel < 0){
					cardSlot = -1; //we have to make the segment, but we'll draw off screen when not mapped
				}
				NSRect channelRect = NSMakeRect(crateX + cardSlot*dx,crateY + channel*dy,dx,dy);
				[segmentPaths addObject:[NSBezierPath bezierPathWithRect:channelRect]];
				[errorPaths addObject:[NSBezierPath bezierPathWithRect:NSInsetRect(channelRect, 4, 4)]];
			}
			
			[segmentPathSet addObject:segmentPaths];
			[errorPathSet addObject:errorPaths];
		}
	}
	else if(viewType == kUsePreampView){	
		NSMutableArray* segmentPaths = [NSMutableArray arrayWithCapacity:kNumFocalPlaneSegments];
		NSMutableArray* errorPaths   = [NSMutableArray arrayWithCapacity:kNumFocalPlaneSegments];
		
		//do the four inner channels
		int i;
		
		for(i=0;i<4;i++){
			NSAffineTransform *transform = [NSAffineTransform transform];
			[transform translateXBy: xc yBy: h-xc-1];
			[transform rotateByDegrees:i*360/4. + 2*360/24.];
			NSRect segRect = NSMakeRect(5,-3,20,6);
			NSBezierPath* segPath = [NSBezierPath bezierPathWithRect:segRect];
			[segPath transformUsingAffineTransform: transform];
			[segmentPaths addObject:segPath];
			NSBezierPath* errorPath = [NSBezierPath bezierPathWithRect:NSInsetRect(segRect, 4, 2)];
			[errorPath transformUsingAffineTransform: transform];
			[errorPaths addObject:errorPath];
		}
		int j;
		for(j=0;j<6;j++){
			float angle = 0;
			float deltaAngle = 360/12.;
			for(i=0;i<24;i++){
				NSAffineTransform *transform = [NSAffineTransform transform];
				[transform translateXBy: xc yBy: h-xc-1];
				[transform rotateByDegrees:angle];
				NSRect segRect = NSMakeRect(25+j*25,-3,25,6);
				NSBezierPath* segPath = [NSBezierPath bezierPathWithRect:segRect];
				[segPath transformUsingAffineTransform: transform];
				[segmentPaths addObject:segPath];
				NSBezierPath* errorPath = [NSBezierPath bezierPathWithRect:NSInsetRect(segRect, 4, 2)];
				[errorPath transformUsingAffineTransform: transform];
				[errorPaths addObject:errorPath];
				angle += deltaAngle;
				if(i==11)angle = deltaAngle/2.;
			}
		}

		[segmentPathSet addObject:segmentPaths];
		[errorPathSet addObject:errorPaths];
		[self makeVetoSegments];
	}	
	else if(viewType == kUsePixelView) {
		//=========the Focal Plane Part=============
		area /= 4.;
		
		NSMutableArray* segmentPaths = [NSMutableArray arrayWithCapacity:kNumFocalPlaneSegments];
		NSMutableArray* errorPaths   = [NSMutableArray arrayWithCapacity:kNumFocalPlaneSegments];
		
		float startAngle;
		float deltaAngle;
		int j;
		r = 0;
		for(j=0;j<kNumRings;j++){
			
			int i;
			int numSeqPerRings;
			if(j==0){
				numSeqPerRings = 4;
				startAngle = 0.;
			}
			else {
				numSeqPerRings = kNumSegmentsPerRing;
				if(kStaggeredSegments){
					if(!(j%2))startAngle = 0;
					else startAngle = -360./(float)numSeqPerRings/2.;	
				}
				else {
					startAngle = 0;
				}
			}
			deltaAngle = 360./(float)numSeqPerRings;
			
			float errorAngle1 = deltaAngle/5.;
			float errorAngle2 = 2*errorAngle1;
			
			//calculate the next radius.
			float r2 = sqrtf(numSeqPerRings*area/(pi*2) + r*r);
			float midR1 = (r2+r)/2. - 2.;
			float midR2 = midR1 + 4.;
			
			for(i=0;i<numSeqPerRings;i++){
				NSBezierPath* aPath = [NSBezierPath bezierPath];
				[aPath appendBezierPathWithArcWithCenter:centerPoint radius:r startAngle:startAngle endAngle:startAngle+deltaAngle clockwise:NO];
				[aPath appendBezierPathWithArcWithCenter:centerPoint radius:r2 startAngle:startAngle+deltaAngle endAngle:startAngle clockwise:YES];
				[aPath closePath];
				[segmentPaths addObject:aPath];
				
				float midAngleStart = (startAngle + startAngle + deltaAngle)/2. - errorAngle1;
				float midAngleEnd   = midAngleStart + errorAngle2;
				
				aPath = [NSBezierPath bezierPath];
				[aPath appendBezierPathWithArcWithCenter:centerPoint radius:midR1 startAngle:midAngleStart endAngle:midAngleEnd clockwise:NO];
				[aPath appendBezierPathWithArcWithCenter:centerPoint radius:midR2 startAngle:midAngleEnd endAngle:midAngleStart clockwise:YES];
				[aPath closePath];
				[errorPaths addObject:aPath];
				
				startAngle += deltaAngle;
			}
			r = r2;
		}
		//store into the whole set
		[segmentPathSet addObject:segmentPaths];
		[errorPathSet addObject:errorPaths];
		
		[self makeVetoSegments];		
	}
}

- (void) makeVetoSegments
{
	//========the Veto part==========
	float xc = [self bounds].size.width/2;
	float h  = [self bounds].size.height;
	NSPoint centerPoint = NSMakePoint(xc,h-xc-1);
	NSMutableArray* segment1Paths = [NSMutableArray arrayWithCapacity:64];
	NSMutableArray* error1Paths = [NSMutableArray arrayWithCapacity:64];
	float startAngle	= 360./5./8./2.;
	float r1	= xc-20;
	float r2	= xc;
	float midR1 = (r2+r1)/2. - 2;
	float midR2 = midR1 + 4;
	float deltaAngle  = 360./5./8.;
	float midVetoR = r1 + (r2 - r1)/2.;
    int j;
    for(j=0;j<8;j++){
        int i;
        for(i=0;i<4;i++){
            NSBezierPath* aPath = [NSBezierPath bezierPath];
            [aPath appendBezierPathWithArcWithCenter:centerPoint radius:r1 startAngle:startAngle endAngle:startAngle+deltaAngle clockwise:NO];
            [aPath appendBezierPathWithArcWithCenter:centerPoint radius:r2 startAngle:startAngle+deltaAngle endAngle:startAngle clockwise:YES];
            [aPath closePath];
            [segment1Paths addObject:aPath];
            
            aPath = [NSBezierPath bezierPath];
            [aPath appendBezierPathWithArcWithCenter:centerPoint radius:midR1 startAngle:startAngle+10 endAngle:startAngle+deltaAngle-10 clockwise:NO];
            [aPath appendBezierPathWithArcWithCenter:centerPoint radius:midR2 startAngle:startAngle+deltaAngle-10 endAngle:startAngle+10 clockwise:YES];
            [aPath closePath];
            [error1Paths addObject:aPath];

            startAngle += deltaAngle;
        }
        startAngle += 360/5./8.;
    }
	
	//now the half moon end caps
	//top
	r1 = 20;
	r2 = 60;
	midR1 = (r2+r1)/2.;
	midR2 = midR1;
	midVetoR = r1 + (r2 - r1)/2.;
	startAngle = 0;
	deltaAngle = 180/4.;
    centerPoint = NSMakePoint([self bounds].size.width-r2,r2+20);
    for(j=0;j<2;j++){
        int i;
        for(i=0;i<4;i++){
            NSBezierPath* aPath = [NSBezierPath bezierPath];
            [aPath appendBezierPathWithArcWithCenter:centerPoint radius:r1 startAngle:startAngle endAngle:startAngle+deltaAngle clockwise:NO];
            [aPath appendBezierPathWithArcWithCenter:centerPoint radius:r2 startAngle:startAngle+deltaAngle endAngle:startAngle clockwise:YES];
            [aPath closePath];
            [segment1Paths addObject:aPath];
            
            aPath = [NSBezierPath bezierPath];
            [aPath appendBezierPathWithArcWithCenter:centerPoint radius:midR1 startAngle:startAngle+30 endAngle:startAngle+deltaAngle-30 clockwise:NO];
            [aPath appendBezierPathWithArcWithCenter:centerPoint radius:midR2 startAngle:startAngle+deltaAngle-30 endAngle:startAngle+30 clockwise:YES];
            [aPath closePath];
            [error1Paths addObject:aPath];

            startAngle += deltaAngle;
        }
        centerPoint.y -= 8;
    }
	
	//store into the whole set
	[segmentPathSet addObject:segment1Paths];
	[errorPathSet addObject:error1Paths];
}


@end
