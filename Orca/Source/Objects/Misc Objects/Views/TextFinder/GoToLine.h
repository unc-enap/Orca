//
//  GoToLine.h
//  ORCA
//
//  Created by Mark Howe on 1/3/07.
//  Copyright 2007 CENPA, University of Washington. All rights reserved.
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


@interface GoToLine : NSObject {
		IBOutlet NSTextField*	lineNumberField;
		IBOutlet id				dialogueView;
		NSLayoutManager*		layoutManager;
        NSArray*                topLevelObjects;
}

/* Common way to get a text finder. One instance of GoToLine per app is good enough. */
+ (GoToLine*) sharedGoToLine;

- (NSPanel*) goToPanel;
- (NSTextView*)textObjectToSearchIn;
- (IBAction) orderFrontGoToPanel:(id)sender;
- (IBAction) jumpButtonClicked:(id)sender;

- (void) showLine:(NSUInteger)lineNumber;
- (BOOL) showCharacter:(NSUInteger)charIndex granularity:(NSSelectionGranularity)granularity;


@end

