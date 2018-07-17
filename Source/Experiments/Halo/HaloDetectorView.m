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

#import "HaloModel.h"
#import "HaloDetectorView.h"
#import "ORColorScale.h"
#import "ORSegmentGroup.h"
#import "ORDetectorSegment.h"


@interface HaloDetectorView (private)
- (void) makeAllSegments;
- (void) makeTestTubeSegments;
@end

@implementation HaloDetectorView
- (void) makeCrateImage
{
    if(!crateImage){
        crateImage = [[NSImage imageNamed:@"Vme64Crate"] copy];
        NSSize imageSize = [crateImage size];
        [crateImage setSize:NSMakeSize(imageSize.width*.7,imageSize.height*.7)];
    }
}

- (void) setViewType:(int)aViewType
{
	viewType = aViewType;
}

#define kCrateInsideX        45
#define kCrateInsideY        35
#define kCrateSeparation     20
#define kCrateInsideWidth   237
#define kCrateInsideHeight   85

- (void) drawRect:(NSRect)rect
{
	if(viewType == kUseCrateView){
 
        int crate;
        for(crate=0;crate<2;crate++){
            float yOffset;
            if(crate==0) yOffset = 0;
            else yOffset = [crateImage imageRect].size.height+20;
            NSRect destRect = NSMakeRect(30,yOffset,[crateImage imageRect].size.width,[crateImage imageRect].size.height);
            [crateImage drawInRect:destRect fromRect:[crateImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];

            [[NSColor blackColor]set];
            NSRect inside = NSMakeRect(kCrateInsideX,yOffset+kCrateInsideY,kCrateInsideWidth,kCrateInsideHeight);
            [NSBezierPath fillRect:inside];
            
            [[NSColor grayColor]set];
            float dx = inside.size.width/21.;
            float dy = inside.size.height/8.;
            [NSBezierPath setDefaultLineWidth:.5];
            int i;
            for(i=0;i<21;i++){
                [NSBezierPath strokeLineFromPoint:NSMakePoint(inside.origin.x+i*dx,inside.origin.y) toPoint:NSMakePoint(inside.origin.x+i*dx,inside.origin.y + inside.size.height)];
            }

            for(i=0;i<8;i++){
                [NSBezierPath strokeLineFromPoint:NSMakePoint(inside.origin.x,inside.origin.y+i*dy) toPoint:NSMakePoint(inside.origin.x + inside.size.width,inside.origin.y+i*dy)];
            }

            
          }
    }
 	[super drawRect:rect];
}

- (NSColor*) getColorForSet:(int)setIndex value:(float)aValue
{
	return [focalPlaneColorScale getColorForValue:aValue];
}

- (void) upArrow
{
	selectedPath++;
	if(selectedSet == 0) selectedPath %= kNumTubes;
}

- (void) downArrow
{
	selectedPath--;
	if(selectedSet == 0){
		if(selectedPath < 0) selectedPath = kNumTubes-1;
	}

}

@end
@implementation HaloDetectorView (private)
- (void) makeAllSegments
{
	[super makeAllSegments];
	
	if(viewType == kUseCrateView){
		float dx = kCrateInsideWidth/21.;
		float dy = kCrateInsideHeight/8.;
		NSMutableArray* segmentPaths = [NSMutableArray arrayWithCapacity:kNumTubes];
		NSMutableArray* errorPaths   = [NSMutableArray arrayWithCapacity:kNumTubes];
		ORSegmentGroup* aGroup = [delegate segmentGroup:0];
		int i;
		int n = [aGroup numSegments];
		for(i=0;i<n;i++){
			ORDetectorSegment* aSegment = [aGroup segment:i];
            int crate    = [[aSegment objectForKey:[aSegment mapEntry:[aSegment crateIndex]forKey:@"key"]] intValue];
			int cardSlot = [aSegment cardSlot];
			int channel  = [aSegment channel];
			if(channel < 0)cardSlot = -1; //we have to make the segment, but we'll draw off screen when not mapped
            float yOffset;
            if(crate==0) yOffset = kCrateInsideY;
            else yOffset = [crateImage imageRect].size.height+kCrateSeparation+kCrateInsideY;
            
			NSRect channelRect = NSMakeRect(kCrateInsideX+cardSlot*dx, yOffset + (channel*dy),dx,dy);
            
			[segmentPaths addObject:[NSBezierPath bezierPathWithRect:channelRect]];
			[errorPaths addObject:[NSBezierPath bezierPathWithRect:NSInsetRect(channelRect, 4, 4)]];
		}
		
		[segmentPathSet addObject:segmentPaths];
		[errorPathSet addObject:errorPaths];
 
	}
	
	else if(viewType == kUseTubeView) {		
		
		NSMutableArray* segmentPaths = [NSMutableArray arrayWithCapacity:kNumTubes];
		NSMutableArray* errorPaths   = [NSMutableArray arrayWithCapacity:kNumTubes];
		
		int bore;
		float height = [self bounds].size.height;
		float width = [self bounds].size.height;
		int evenColumnDelta = width  / 5;
		int rowSpacing      = height / 7;
#define cellSize 30
		
		float xc = cellSize;
		float yc = height-cellSize+10;
		int row = 0;
		for(bore=0;bore<32;bore++){
			
			int t;
			float angle = 90;
			for(t=0;t<4;t++){
				float x = xc + 10 * cos(angle * 3.1415/180.);
				float y = yc + 10 * sin(angle * 3.1415/180.);
				angle -= 90;
				NSRect r = NSMakeRect(10+x-5,y-5,10,10);
				r = NSOffsetRect(r, 0, 0);
				[segmentPaths addObject:[NSBezierPath bezierPathWithOvalInRect:r]];
				[errorPaths   addObject:[NSBezierPath bezierPathWithOvalInRect:NSInsetRect(r, -5, -5)]];
			}
			xc += evenColumnDelta;
			if(xc >= width){
				row++;
				if(row%2==0)xc = cellSize;
				else xc = 2*cellSize;
				yc -= rowSpacing;
			}
		}
		
		//store into the whole set
		[segmentPathSet addObject:segmentPaths];
		[errorPathSet addObject:errorPaths];
		
        [self makeTestTubeSegments];

        
		[self setNeedsDisplay:YES];
	}
}

- (void) makeTestTubeSegments
{
    NSMutableArray* segmentPaths = [NSMutableArray arrayWithCapacity:kNumTubes];
    NSMutableArray* errorPaths   = [NSMutableArray arrayWithCapacity:kNumTubes];
    
    float width = [self bounds].size.height;
    int i;
    float x = width;
    float y = 10;
    for(i=0;i<4;i++){
        NSRect r = NSMakeRect(10+x-5,y-5,10,10);
        r = NSOffsetRect(r, 0, 0);
        [segmentPaths addObject:[NSBezierPath bezierPathWithOvalInRect:r]];
        [errorPaths   addObject:[NSBezierPath bezierPathWithOvalInRect:NSInsetRect(r, -5, -5)]];
        y += 15;
   }
    
    //store into the whole set
    [segmentPathSet addObject:segmentPaths];
    [errorPathSet addObject:errorPaths];

}
- (NSMutableArray*) setupMapEntries:(int) index
{
	//default set -- subsclasses can override
	NSMutableArray* mapEntries = [NSMutableArray array];
	[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kSegmentNumber",	@"key", [NSNumber numberWithInt:0], @"sortType", nil]];
    [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kBore",          @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
    [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kClock",         @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
    [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kNCD",           @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
	[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kCardSlot",		@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
	[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kChannel",		@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
    [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kHvCrate",       @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
    [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kHvSlot",        @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
    [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kHvChan",        @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
    [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kPreAmp",        @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
    [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kPulserCard",	@"key", [NSNumber numberWithInt:0], @"sortType", nil]];
    [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kPulserChan",	@"key", [NSNumber numberWithInt:0], @"sortType", nil]];
	[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kName",			@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
	return mapEntries;
}
@end

