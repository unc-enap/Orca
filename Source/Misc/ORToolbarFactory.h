//
//  ORToolbarFactory.h
//  found on the web somewhere?????
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

/*
	PURPOSE:
	Easily add toolbars to windows in your application.
	
	DIRECTIONS:
	To use ORToolbarFactory, drag this header file into your NIB file's window.
	Now you'll be able to instantiate a ORToolbarFactory object in your NIB.
	Hook up the ORToolbarFactory's "owner" outlet with the NSWindow on which you
	want a toolbar. Make sure you have specified an "Autosave name" for the
	NSWindow (e.g. "MainWindow").
	
	Now create a file that is named with your application's bundle identifier
	(e.g. "com.mycompany.myapplication"), followed by a period, the autosave
	name of the NSWindow and ".plist"
	(e.g. "com.mycompany.myapplication.MainWindow.plist").
	
	In this file you can now define the toolbar items that will be available in
	your window's toolbar. The file must contain a dictionary of item
	definition dictionaries under the key "Items". These item definition
	dictionaries are stored under the item identifier as the key. The actual
	item definition dictionary contains the following keys (all strings):
	
	Action  -   The selector to call on the first responder when this item is
				clicked, e.g. "close:" or "print:" or "myCustomIBAction:".
	Label   -   The label to display under the toolbar item in the toolbar.
	CustomizationLabel -
				An alternate label to be displayed in the "Customize toolbar"
				window for this item. This can be more detailed. If this isn't
				present, the "Label" will be used here as well.
	ToolTip -   The tool tip to display when the mouse is over this item in the
				toolbar. If this isn't specified, no tooltip is shown.
	
	The image to be used for the toolbar item must have the item identifier as
	its name (plus any filename extension needed to indicate the image file's
	type, e.g. ".tiff").
	
	The file must also contain an array under the key "DefaultItems", which
	contains the list of item identifiers to be displayed in this toolbar by
	default. Apart from the identifiers in this file, you can also specify
	the identifiers defined by Apple, i.e. NSToolbarSeparatorItem,
	NSToolbarSpaceItem, NSToolbarFlexibleSpaceItem, or NSToolbarCustomizeToolbar,
	which are automatically added to the list of allowed items.
	
	If you want to allow NSToolbarShowColorsItem, NSToolbarShowFontsItem, or
	NSToolbarPrintItem, you have to explicitly add them to the "Items" dictionary
	or they won't show up in the customization sheet. You needn't specify any
	actions, labels or tool tips for them, though.
	
	To enable/disable toolbar items as needed, implement
		-(BOOL) validateToolbarItem: (NSToolbarItem*)item;
	on the owning NSWindow. This works analogous to validateMenuItem:.
*/


@interface ORToolbarFactory : NSObject <NSToolbarDelegate>
{
	IBOutlet NSWindow*		owner;				// Window to put the toolbar on.
	NSDictionary*			toolbarItems;		// List of possible items in the toolbar.
	NSString*				toolbarIdentifier;  // The toolbar identifier and base file name.
}

-(void) dealloc;
-(void) awakeFromNib;
-(void)	setToolbarIdentifier: (NSString*)str;
-(NSString*) toolbarIdentifier;
-(NSToolbarItem*) toolbar: (NSToolbar*)toolbar itemForItemIdentifier: (NSString*)itemIdentifier willBeInsertedIntoToolbar: (BOOL)flag;
-(NSArray*) toolbarDefaultItemIdentifiers: (NSToolbar*)toolbar;
-(NSArray*) toolbarAllowedItemIdentifiers: (NSToolbar*)toolbar;

@end
