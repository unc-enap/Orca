/* =============================================================================
	FILE:		UKPrefsPanel.h
	
	AUTHORS:	M. Uli Kusterer (UK), (c) Copyright 2003, all rights reserved.
	
	DIRECTIONS:
		UKPrefsPanel is ridiculously easy to use: Create a tabless NSTabView,
		where the name of each tab is the name for the toolbar item, and the
		identifier of each tab is the identifier to be used for the toolbar
		item to represent it. Then create image files with the identifier as
		their names to be used as icons in the toolbar.
	
		Finally, drag UKPrefsPanel.h into the NIB with the NSTabView,
		instantiate a UKPrefsPanel and connect its tabView outlet to your
		NSTabView. When you open the window, the UKPrefsPanel will
		automatically add a toolbar to the window with all tabs represented by
		a toolbar item, and clicking an item will switch between the tab view's
		items.

	
	REVISIONS:
		2003-08-13	UK	Added auto-save, fixed bug with empty window titles.
		2003-07-22  UK  Added Panther stuff, documented.
		2003-06-30  UK  Created.
   ========================================================================== */
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

/* -----------------------------------------------------------------------------
	Headers:
   -------------------------------------------------------------------------- */




/* -----------------------------------------------------------------------------
	Classes:
   -------------------------------------------------------------------------- */
@interface UKPrefsPanel : NSObject <NSToolbarDelegate>
{
	IBOutlet NSTabView*		tabView;			// The tabless tab-view that we're a switcher for.
	NSMutableDictionary*	itemsList;			// Auto-generated from tab view's items.
	NSString*				baseWindowName;		// Auto-fetched at awakeFromNib time. We append a colon and the name of the current page to the actual window title.
	NSString*				autosaveName;		// Identifier used for saving toolbar state and current selected page of prefs window.
}

// Accessors for specifying the tab view: (you should just hook these up in IB)
-(void)			setTabView: (NSTabView*)tv;
-(NSTabView*)   tabView;

-(void)			setAutosaveName: (NSString*)name;
-(NSString*)	autosaveName;

// Action for hooking up this object and the menu item:
-(IBAction)		orderFrontPrefsPanel: (id)sender;

// You don't have to care about these:
-(void)	mapTabsToToolbar;
-(IBAction)	changePanes: (id)sender;

@end
