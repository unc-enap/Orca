//  ORPlotPublisher.h
//  Orca
//
//  Created by Mark Howe on June 25, 2009.
//  Copyright 2009 UNC. All rights reserved.
//
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
@class ORCompositePlotView;

@interface ORPlotPublisher : NSWindowController 
{
	IBOutlet NSButton*		cancelButton;
	IBOutlet NSButton*		applyButton;
	IBOutlet NSMatrix*		optionMatrix;
	IBOutlet NSMatrix*		labelMatrix;
	IBOutlet NSColorWell*	colorWell;
	IBOutlet NSTextField*	dataSetField;
	IBOutlet NSImageView*	previewImage;
	IBOutlet NSTextField*	saveSetField;
	
	ORCompositePlotView*	compositePlotView;
	NSMutableDictionary*    oldAttributes;
	NSString*				oldXLabel;
	NSString*				oldYLabel;
	NSString*				oldTitle;
	NSMutableDictionary*    newAttributes;

}

+ (void) publishPlot:(id)aPlot;

- (id) initWithPlot:(id)aPlot;
- (void) beginSheet;

- (IBAction) labelingOptionsAction:(id) sender;
- (IBAction) dataSetAction: (id) sender;
- (IBAction) colorOptionsAction: (id) sender;
- (IBAction) publish:(id) sender;
- (IBAction) cancel:(id) sender;
- (IBAction) saveSetAction:(id) sender;
- (IBAction) loadSetAction:(id) sender;

@end


@interface NSObject (ORPlotPublisher)
- (NSTextField*) titleField;
- (NSView*) viewForPDF;
- (NSMutableDictionary*) attributes;
- (void)setAttributes:(NSMutableDictionary *)anAttributes;
@end
