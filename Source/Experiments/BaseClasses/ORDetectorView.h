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

@class ORColorScale;

#define kDisplayEvents		0
#define kDisplayRates		1
#define kDisplayThresholds	2
#define kDisplayGains		3
#define kDisplayTotalCounts	4

@interface ORDetectorView : NSView
{
	@protected
		NSMutableArray* segmentPathSet;
		NSMutableArray* errorPathSet;
		NSMutableArray* labelPathSet;
		int selectedSet;
		int selectedPath;
		id delegate;
        NSImage* crateImage;
}
- (id)initWithFrame:(NSRect)frameRect;
- (void) dealloc;
- (void) makeCrateImage;
- (void) setDelegate:(id)aDelegate;
- (void) makeAllSegments;
- (void) mouseDown:(NSEvent*)anEvent;
- (void)drawRect:(NSRect)rect;
- (void)setFrameSize:(NSSize)newSize;
- (void) clrSelection;
- (void) showSelectedDialog;
- (int) selectedSet;
- (int) selectedPath;
- (NSColor*) outlineColor:(int)aSet;
- (NSColor*) selectedColor:(int)aSet;

//subclass reponsiblity
- (void) upArrow;
- (void) downArrow;
- (void) leftArrow;
- (void) rightArrow;
- (NSColor*) getColorForSet:(int)setIndex value:(float)aValue;

@end

@interface NSObject (ORDetectorView)
- (float) getRateSet:(int)setIndex segment:(int)segmentIndex;
- (float) getGainSet:(int)setIndex segment:(int)segmentIndex;
- (float) getThresholdSet:(int)setIndex segment:(int)segmentIndex;
@end