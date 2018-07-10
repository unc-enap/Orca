//
//  ORGretinaCntView.h
//  Orca
//
//  Created by Mark Howe on 1/25/13.
//  Copyright (c) 2013 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
@class ORGretina4MController;

@interface ORGretinaCntView : NSView {
	IBOutlet ORGretina4MController*  dataSource;
	IBOutlet NSTextField*  preReField;
	IBOutlet NSTextField*  postReField;
	IBOutlet NSTextField*  flatTopField;
    BOOL            optionKeyDown;
    NSRect          b;
	NSImage*        bugImage;
	BOOL            movingPreRisingEdge;
	BOOL            movingRisingEdge;
	BOOL            movingPostRisingEdge;
	NSGradient*     plotGradient;
    
    float           postRisingEdgeBugX;
    float           risingEdgeBugX;
    float           preRisingEdgeBugX;
    
    float           preXDelta;
    float           postXDelta;
    int             baseline;
}

- (id)initWithFrame:(NSRect)frame;
- (void) dealloc;
- (void) setValues:(BOOL)finalValues;
- (void) setValues:(short)channel final:(BOOL)finalValues;
- (void) initBugs;
- (BOOL) anythingSelected;
- (int)  firstOneSelected;
- (void) loadLocalFields;

#pragma mark ¥¥¥Events
- (void) mouseDown:(NSEvent*)event;
- (void) mouseDragged:(NSEvent*)event;
- (void) mouseUp:(NSEvent*)event;
- (BOOL) mouseDownCanMoveWindow;

#pragma mark ¥¥¥Drawing
- (void) drawRect:(NSRect)rect ;

#pragma mark ¥¥¥Actions
- (IBAction) tweakFlatTopCounts:(id)sender;
- (IBAction) tweakPostReCounts:(id)sender;
- (IBAction) tweakPreReCounts:(id)sender;
- (IBAction) flatTopCounts:(id)sender;
- (IBAction) postReCounts:(id)sender;
- (IBAction) preReCounts:(id)sender;

@end
