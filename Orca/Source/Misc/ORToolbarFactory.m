//
//  ORToolbarFactory.m
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
 
#import "ORToolbarFactory.h"

@interface ORToolbarFactory (ORToolbarFactoryPrivateMethods)
-(void)		setupToolbar;
@end


@implementation ORToolbarFactory
-(void) dealloc
{
	[toolbarItems release];
	[toolbarIdentifier release];
	[super dealloc];
}
 
-(void) awakeFromNib
{
	[self setupToolbar];
}

// -----------------------------------------------------------------------------
//	setToolbarIdentifier:
//		Lets you change the toolbar identifier at runtime. This will recreate
//		the toolbar from the item definition .plist file for that identifier.
// -----------------------------------------------------------------------------
-(void)	setToolbarIdentifier: (NSString*)str
{
	[toolbarIdentifier autorelease];
	toolbarIdentifier = [str copy];
	
	[self setupToolbar];
}

// -----------------------------------------------------------------------------
//	toolbarIdentifier:
//		Returns the toolbar identifier this object manages. Defaults to the
//		application's bundle identifier with the autosave name of the owning
//		window appended to it.
// -----------------------------------------------------------------------------
-(NSString*) toolbarIdentifier
{
	if( !toolbarIdentifier ) {
		toolbarIdentifier = [[NSString stringWithFormat: @"%@.%@", [[NSBundle mainBundle] bundleIdentifier], [[owner windowController] windowNibName]] retain];
	}
	return toolbarIdentifier;
}

// -----------------------------------------------------------------------------
//	toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:
//		Creates the appropriate toolbar item for the specified identifier.
//		This simply lets NSToolbarItem handle system-defined toolbar items,
//		while setting up all others according to the dictionaries from the
//		.plist file.
// -----------------------------------------------------------------------------
-(NSToolbarItem*) toolbar: (NSToolbar*)toolbar itemForItemIdentifier: (NSString*)itemIdentifier willBeInsertedIntoToolbar: (BOOL)flag;
{
	NSDictionary*	allItems = [toolbarItems objectForKey: @"Items"];
	NSDictionary*   currItem;
	NSToolbarItem*  tbi = nil;
		
	// One of the system-provided items?
	if( [itemIdentifier isEqualToString: NSToolbarSeparatorItemIdentifier]
		|| [itemIdentifier isEqualToString: NSToolbarSpaceItemIdentifier]
		|| [itemIdentifier isEqualToString: NSToolbarFlexibleSpaceItemIdentifier]
		|| [itemIdentifier isEqualToString: NSToolbarShowColorsItemIdentifier]
		|| [itemIdentifier isEqualToString: NSToolbarShowFontsItemIdentifier]
		|| [itemIdentifier isEqualToString: NSToolbarPrintItemIdentifier]
		|| [itemIdentifier isEqualToString: NSToolbarCustomizeToolbarItemIdentifier] )
		return [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier] autorelease];
	
	// Otherwise, look it up in our list of custom items:
	currItem = [allItems objectForKey: itemIdentifier];
	if( currItem ){
		SEL			itemAction = NSSelectorFromString([currItem objectForKey: @"Action"]);
		NSString*   itemLabel = [currItem objectForKey: @"Label"];
		NSString*   itemCustomLabel = [currItem objectForKey: @"CustomizationLabel"];
		NSString*   itemTooltip = [currItem objectForKey: @"ToolTip"];
		NSImage*	itemImage = [NSImage imageNamed: itemIdentifier];
		
		// ... and create an NSToolbarItem for it and set that up:
		tbi = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier] autorelease];
		[tbi setAction: itemAction];
		[tbi setLabel: itemLabel];
		[tbi setImage: itemImage];
		if(itemCustomLabel) [tbi setPaletteLabel: itemCustomLabel];
		else				[tbi setPaletteLabel: itemLabel];
		if(itemTooltip)		[tbi setToolTip: itemTooltip];
	}
	
	return tbi;
}
    

// -----------------------------------------------------------------------------
//	toolbarDefaultItemIdentifiers:
//		Returns the list of item identifiers we want to be in this toolbar by
//		default. The list is loaded from the .plist file's "DefaultItems" array.
// -----------------------------------------------------------------------------
-(NSArray*) toolbarDefaultItemIdentifiers: (NSToolbar*)toolbar
{
	return [toolbarItems objectForKey: @"DefaultItems"];
}

// -----------------------------------------------------------------------------
//	toolbarAllowedItemIdentifiers:
//		Returns the list of item identifiers that may be in the toolbar. This
//		simply returns the identifiers of all the items in our "Items"
//		dictionary, plus a few sensible defaults like separators and spacer
//		items the user may want to add as well.
//
//		If this function doesn't return the item identifier, it *can't* be in
//		the toolbar. Though if this returns it, that doesn't mean it currently
//		is in the toolbar.
// -----------------------------------------------------------------------------
-(NSArray*) toolbarAllowedItemIdentifiers: (NSToolbar*)toolbar
{
	NSDictionary*	allItems = [toolbarItems objectForKey: @"Items"];
	int				icount   = [allItems count];
	NSMutableArray*	allowedItems = [NSMutableArray arrayWithCapacity: icount +4];
	NSEnumerator*   allItemItty;
	NSString*		currItem;
	
	for( allItemItty = [allItems keyEnumerator]; currItem = [allItemItty nextObject]; ){
		[allowedItems addObject: currItem];
	}	
	[allowedItems addObject: NSToolbarSeparatorItemIdentifier];
	[allowedItems addObject: NSToolbarSpaceItemIdentifier];
	[allowedItems addObject: NSToolbarFlexibleSpaceItemIdentifier];
	[allowedItems addObject: NSToolbarCustomizeToolbarItemIdentifier];
	
	return allowedItems;
}
@end

@implementation ORToolbarFactory (ORToolbarFactoryPrivateMethods)
// -----------------------------------------------------------------------------
//	setupToolbar:
//		(Re)create our toolbar. This loads the .plist file whose name is the
//		toolbar identifier and loads it. Then it adds the toolbar to our
//		window.
// -----------------------------------------------------------------------------
- (void) setupToolbar
{
	// Load list of items:
	NSString*   toolbarItemsPlistPath = [[NSBundle mainBundle] pathForResource: [self toolbarIdentifier] ofType: @"plist"];
	if(toolbarItems)[toolbarItems release];
	toolbarItems = [[NSDictionary dictionaryWithContentsOfFile: toolbarItemsPlistPath] retain];

	// (Re-) create toolbar:
	NSToolbar*  tb = [[[NSToolbar alloc] initWithIdentifier: [self toolbarIdentifier]] autorelease];
	[tb setDelegate: self];
	[tb setAllowsUserCustomization: YES];
	[tb setAutosavesConfiguration: YES];
	[owner setToolbar: tb];
}
@end

