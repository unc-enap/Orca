//
//  ORWindowListController.m
//  Orca
//
//  Created by Mark Howe on Fri Mar 8 2007.
//  Copyright (c) 2007 CENPA, University of Washington. All rights reserved.
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


#pragma mark ¥¥¥Imported Files
#import "ORWindowListController.h"
#import "SynthesizeSingleton.h"

//aux function for sorting window names
int windowNameSort(id w1, id w2, void *context) { return [[w2 title] compare:[w1 title]]; }

@implementation ORWindowListController

#pragma mark ¥¥¥Initialization
SYNTHESIZE_SINGLETON_FOR_ORCLASS(WindowListController);

-(id)init
{
    self=[super initWithWindowNibName:@"WindowList"];
	[self setWindowFrameAutosaveName:@"WindowList"];
    return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

#pragma mark ¥¥¥Window Management
- (void) awakeFromNib
{
    [[self window] setLevel: NSStatusWindowLevel];
    [[self window] setAlphaValue:.75];
    [[self window] setOpaque:NO];
    [[self window] setHasShadow: NO];
	[self setUpControls];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowClosing:) name:NSWindowWillCloseNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowOpening:) name:NSMenuDidChangeItemNotification object:nil];
}

- (void) setUpControls
{
	[[listView subviews] makeObjectsPerformSelector:@selector(removeFromSuperviewWithoutNeedingDisplay)];
	
	NSArray* windowList = [[NSApp windows] sortedArrayUsingFunction:windowNameSort context:nil];
	int i = 0;
	for(id aWindow in windowList){
		if([aWindow isKindOfClass:NSClassFromString(@"NSPanel")])continue;
		if([aWindow isKindOfClass:NSClassFromString(@"NSDrawerWindow")])continue;
		if([[aWindow title] isEqualToString:@"Window"])continue;
		if([[aWindow title] length]>0 && ![[aWindow title] isEqualToString:@"Window List"]){
			[self addButtonForWindow:aWindow index:i];
			i++;
		}
	}
	[self resizeWindowToSize:NSMakeSize(200,20*i)];
	[listView setNeedsDisplay:YES];
}

- (void) windowClosing:(NSNotification*)aNote
{
	[self performSelector:@selector(setUpControls) withObject:self afterDelay:.1];
}

- (void) windowOpening:(NSNotification*)aNote
{
	if([[[aNote object] title] isEqualToString:@"Window"]){
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
		[self performSelector:@selector(setUpControls) withObject:self afterDelay:.1];
	}
}


- (NSButton*) addButtonForWindow:(NSWindow*)aWindow index:(int)index
{
	NSButton* button = [[NSButton alloc] initWithFrame:NSMakeRect(0,index*20,200,20)];
	[button setTitle:[aWindow title]];
	[button setBezelStyle:NSShadowlessSquareBezelStyle];
	[button setFont:[NSFont fontWithName:@"Geneva" size:9]];
	[button setEnabled:YES];
	[button setTarget:self];
	[button setAction:@selector(bringToFront:)];
	[listView addSubview:button];  
	[button release];  // the superview retains the button
	return button;
}

- (void)resizeWindowToSize:(NSSize)newSize
{
    NSRect aFrame;
    
    float newHeight = newSize.height;
    float newWidth = newSize.width;
    
    aFrame = [NSWindow contentRectForFrameRect:[[self window] frame] 
                                     styleMask:[[self window] styleMask]];
    
    aFrame.origin.y += aFrame.size.height;
    aFrame.origin.y -= newHeight;
    aFrame.size.height = newHeight;
    aFrame.size.width = newWidth;
    
    aFrame = [NSWindow frameRectForContentRect:aFrame 
                                     styleMask:[[self window] styleMask]];
    
    [[self window] setFrame:aFrame display:YES animate:YES];
}

- (IBAction) bringToFront:(id)sender
{
	NSString* windowTitle = [sender title];
	NSArray* windowList = [NSApp windows];
	NSEnumerator* e = [windowList objectEnumerator];
	id aWindow;
	while(aWindow = [e nextObject]){
		if([[aWindow title] isEqualToString:windowTitle]){
			[aWindow makeKeyAndOrderFront:self];
			break;
		}
	}
}

@end

