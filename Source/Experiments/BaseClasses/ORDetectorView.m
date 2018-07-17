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
#import "ORExperimentModel.h"
#import "ORDetectorView.h"
#import "ORColorScale.h"
#import "ORSegmentGroup.h"

#define highlightLineWidth 2

@implementation ORDetectorView

- (id)initWithFrame:(NSRect)frameRect
{
	self=[super initWithFrame:frameRect];
	[self makeAllSegments];
	selectedSet		= -1;
	selectedPath    = -1;
	return self;
}

- (void) dealloc
{
	[segmentPathSet release];
	[errorPathSet release];
    [crateImage release];
    [labelPathSet release];
	[super dealloc];
}

- (void) awakeFromNib
{
    [self makeCrateImage];
}

- (void) setDelegate:(id)aDelegate
{
	//don't retain delegates!
	delegate = aDelegate;
}

- (void) makeCrateImage
{
    //subclasses can override
}

- (void) makeAllSegments
{
	if(!segmentPathSet)segmentPathSet = [[NSMutableArray array] retain];
	[segmentPathSet removeAllObjects];
	if(!errorPathSet)errorPathSet = [[NSMutableArray array] retain];
	[errorPathSet removeAllObjects];
	if(!labelPathSet)labelPathSet = [[NSMutableArray array] retain];
	[labelPathSet removeAllObjects];
}

- (BOOL) acceptsFirstResponder
{
    return YES;
}

- (void) keyDown:(NSEvent *)event
{
	int keyCode = [event keyCode];
	if(selectedSet>=0 && selectedPath>=0){
		if(keyCode == 126){
			[self upArrow];
		}
		else if(keyCode == 124){
			[self rightArrow];
		}
		else if(keyCode == 125){
			[self downArrow];
		}
		else if(keyCode == 123){
			[self leftArrow];
		}
		[delegate selectedSet:selectedSet segment:selectedPath];
		[self setNeedsDisplay:YES];
	}
	else [super keyDown:event];
}

//subclass responsibility
- (void) upArrow {;}
- (void) downArrow{;}
- (void) leftArrow{;}
- (void) rightArrow{;}
- (NSColor*) getColorForSet:(int)setIndex value:(float)aValue{return nil;}
- (int) selectedSet  {return selectedSet;}
- (int) selectedPath {return selectedPath;}

- (void) clrSelection
{
	selectedSet  = -1;
	selectedPath = -1;
	[delegate selectedSet:selectedSet segment:selectedPath];
	
	[self setNeedsDisplay:YES];
}

- (void) showSelectedDialog
{
	if(selectedSet>=0 && selectedPath>=0){
		[delegate showDialogForSet:selectedSet segment:selectedPath];
	}
}

- (void) mouseDown:(NSEvent*)anEvent
{
    NSPoint localPoint = [self convertPoint:[anEvent locationInWindow] fromView:nil];
	selectedSet  = -1;
	selectedPath = -1;
	
	int setIndex;
	for(setIndex = 0;setIndex<[segmentPathSet count];setIndex++){
		int segmentIndex;
		NSArray* arrayOfPaths = [segmentPathSet objectAtIndex:setIndex];
		for(segmentIndex = 0;segmentIndex<[arrayOfPaths count];segmentIndex++){
			NSBezierPath* aPath = [arrayOfPaths objectAtIndex:segmentIndex];
			if([aPath containsPoint:localPoint]){
				selectedSet  = setIndex;
				selectedPath = segmentIndex;
                break;
			}
		}
        if(selectedSet>=0)break;
	}
	[delegate selectedSet:selectedSet segment:selectedPath];
	if(selectedSet>=0 && selectedPath>=0 && [anEvent clickCount] >= 2){
		if([anEvent modifierFlags] & NSEventModifierFlagCommand){
			[delegate showDataSetForSet:selectedSet segment:selectedPath];
		}
		else {
			[delegate showDialogForSet:selectedSet segment:selectedPath];
		}
	}
	[self setNeedsDisplay:YES];
}


- (void)drawRect:(NSRect)rect
{
	int displayType = [delegate displayType];
	BOOL displayErrors = ([delegate hardwareCheck]==0) || ([delegate cardCheck]==0);
	int setIndex;
	int numSets = (int)[segmentPathSet count];
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
																		[NSFont fontWithName:@"Monaco" size:9], NSFontAttributeName,
																		[NSColor whiteColor], NSForegroundColorAttributeName,
																		nil];	
	for(setIndex = 0;setIndex<numSets;setIndex++){
		int segmentIndex;
		NSArray* arrayOfSegmentPaths = [segmentPathSet objectAtIndex:setIndex];
		int numSegments = (int)[arrayOfSegmentPaths count];
		ORSegmentGroup* segmentGroup = [delegate segmentGroup:setIndex];
		for(segmentIndex = 0;segmentIndex<numSegments;segmentIndex++){
			NSBezierPath*   segmentPath  = [arrayOfSegmentPaths objectAtIndex:segmentIndex];
			if([segmentGroup hwPresent:segmentIndex]){
				if([segmentGroup online:segmentIndex]){
					float displayValue;
					switch(displayType){
						case kDisplayThresholds:	displayValue = [segmentGroup getThreshold:segmentIndex];	break;
						case kDisplayGains:			displayValue = [segmentGroup getGain:segmentIndex];			break;
						case kDisplayTotalCounts:	displayValue = [segmentGroup getTotalCounts:segmentIndex];	break;
						default:					displayValue = [segmentGroup getRate:segmentIndex];			break;
					}
					NSColor* displayColor = [self getColorForSet:setIndex value:displayValue];
					if(displayColor)[displayColor set];
					else [[NSColor darkGrayColor] set];
				}
				else [[NSColor whiteColor] set];
			}
			else [[NSColor clearColor] set];
			[segmentPath fill];
			
			//display error spot if needed
			if(displayErrors && [segmentGroup getError:segmentIndex]){
				NSArray* arrayOfErrorPaths   = [errorPathSet objectAtIndex:setIndex];
				[[NSColor colorWithCalibratedRed:.7 green:.2 blue:.2 alpha:1] set];
				[[arrayOfErrorPaths objectAtIndex:segmentIndex] fill];
			}
		}
		
		[[self outlineColor:setIndex] set];
        
		NSBezierPath*   segmentPath = [NSBezierPath bezierPath];
		[segmentPath setLineWidth:0];
		for(segmentIndex = 0;segmentIndex<numSegments;segmentIndex++){
			[segmentPath appendBezierPath: [arrayOfSegmentPaths objectAtIndex:segmentIndex]];
		}
		[segmentPath stroke];
	}
			
	//the the highlighted segment
	if(selectedSet>=0 && selectedPath>=0){	
		NSArray* arrayOfSegmentPaths = [segmentPathSet objectAtIndex:selectedSet];
		NSBezierPath*   segmentPath  = [arrayOfSegmentPaths objectAtIndex:selectedPath];
		[segmentPath setLineWidth:highlightLineWidth];
		[[self selectedColor:setIndex] set];
		[segmentPath stroke];
	}

	if([delegate showNames]){
		for(setIndex = 0;setIndex<numSets;setIndex++){
			int segmentIndex;
			NSArray* arrayOfSegmentPaths = [segmentPathSet objectAtIndex:setIndex];
			int numSegments = (int)[arrayOfSegmentPaths count];
			ORSegmentGroup* segmentGroup = [delegate segmentGroup:setIndex];
			for(segmentIndex = 0;segmentIndex<numSegments;segmentIndex++){
				NSString* name = [[segmentGroup segment:segmentIndex] objectForKey:@"kName"];
				if([name length] && ![name isEqualToString:@"--"]){
					ORDetectorSegment* seg = [labelPathSet objectAtIndex:segmentIndex];
					float x = [[seg objectForKey:@"X"] floatValue];
					float y = [[seg objectForKey:@"Y"] floatValue];
				
					[name drawAtPoint:NSMakePoint(x,y) withAttributes:attributes];
				}
			}
		}
	}
    
    [super drawRect:rect];

}
- (NSColor*) outlineColor:(int)aSet
{
    return [NSColor grayColor];
}
- (NSColor*) selectedColor:(int)aSet
{
    return [NSColor redColor];
}


- (void)setFrameSize:(NSSize)newSize
{
	[super setFrameSize:newSize];
	[self makeAllSegments];
	[self setNeedsDisplay:YES];
}
@end

@implementation NSObject (ORDetectorView)
- (float) getRateSet:(int)setIndex segment:(int)segmentIndex
{
	return -1;
}
- (float) getGainSet:(int)setIndex segment:(int)segmentIndex
{
	return -1;
}
- (float) getThresholdSet:(int)setIndex segment:(int)segmentIndex
{
	return -1;
}
@end
