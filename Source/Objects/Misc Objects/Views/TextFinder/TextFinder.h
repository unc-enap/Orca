/*
    Reusable find panel functionality (find, replace).
    Need one shared instance of TextFinder to which the menu items and widgets in the find panel are connected.
    Loads UI lazily.
    Works on first responder, assumed to be an NSTextView.
*/
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

#define Forward YES
#define Backward NO

@interface TextFinder : NSObject {
    IBOutlet NSTextField*	findTextField;
    IBOutlet NSTextField*	replaceTextField;
    IBOutlet NSButton*		ignoreCaseButton;
    IBOutlet NSButton*		findNextButton;
    IBOutlet NSMatrix*		replaceAllScopeMatrix;
    IBOutlet NSTextField*	statusField;
    BOOL                    lastFindWasSuccessful;
    NSString*               findString;
    NSArray*                topLevelObjects;
}

/* Common way to get a text finder. One instance of TextFinder per app is good enough. */
+ (TextFinder*) sharedTextFinder;

/* Main method for external users; does a find in the first responder. Selects found range or beeps. */
- (BOOL) find:(BOOL)direction;

/* Loads UI lazily */
- (NSPanel*) findPanel;

/* Gets the first responder and returns it if it's an NSTextView */
- (NSTextView*)textObjectToSearchIn;

/* Get/set the current find string. Will update UI if UI is loaded */
- (NSString*) findString;
- (void) setFindString:(NSString *)string;
- (void) setFindString:(NSString *)string writeToPasteboard:(BOOL)flag;

/* Misc internal methods */
- (void) appDidActivate:(NSNotification*)notification;
- (void) loadFindStringFromPasteboard;
- (void) loadFindStringToPasteboard;

/* Action methods, sent from the find panel UI; can also be connected to menu items */
- (void) findNext:(id)sender;
- (void) findPrevious:(id)sender;
- (void) findNextAndOrderFindPanelOut:(id)sender;
- (void) replace:(id)sender;
- (void) replaceAndFind:(id)sender;
- (void) replaceAll:(id)sender;
- (void) orderFrontFindPanel:(id)sender;
- (void) takeFindStringFromSelection:(id)sender;
- (void) jumpToSelection:(id)sender;

@end

