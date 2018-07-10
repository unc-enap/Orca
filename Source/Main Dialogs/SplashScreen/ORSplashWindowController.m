//
//  ORSplashWindowController.m
//  Orca
//
//  Created by Mark Howe on 9/19/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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


#import "ORSplashWindowController.h"
#import "ORTimedTextField.h"

@implementation ORSplashWindowController

-(id)init
{
    self = [super initWithWindowNibName:@"SplashScreen"];
	[self registerNotificationObservers];
    return self;
}
- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void) awakeFromNib
{
    [[self window] setBackgroundColor: [NSColor clearColor]];
    [[self window] setLevel: NSStatusWindowLevel];
    [[self window] setAlphaValue:1.0];
    [[self window] setOpaque:NO];
    [[self window] setHasShadow: YES];
    [[self window] center];
	
	NSDictionary* infoDictionary = [[NSBundle mainBundle] infoDictionary];

	NSMutableString* svnVersion = [NSMutableString stringWithString:@""];
	NSString* svnVersionPath = [[NSBundle mainBundle] pathForResource:@"svnversion"ofType:nil];
	NSFileManager* fm = [NSFileManager defaultManager];
	if([fm fileExistsAtPath:svnVersionPath])svnVersion = [NSMutableString stringWithContentsOfFile:svnVersionPath encoding:NSASCIIStringEncoding error:nil];
	if([svnVersion hasSuffix:@"\n"]){
		[svnVersion replaceCharactersInRange:NSMakeRange([svnVersion length]-1, 1) withString:@""];
	}


	NSString* versionString = [infoDictionary objectForKey:@"CFBundleVersion"];
	[versionField setStringValue:[NSString stringWithFormat:@"Version %@%@%@",
		versionString,[svnVersion length]?@":":@"",[svnVersion length]?svnVersion:@""]];

	[infoField setStringValue:@"Starting..."];

}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
	
	[[NSNotificationCenter defaultCenter] addObserver : self
                                             selector : @selector(infoFieldChanged:)
                                                 name : @"ORStartUpMessage"
                                               object : nil];
}

- (void) infoFieldChanged:(NSNotification*)aNote
{
	[infoField setStringValue:[[aNote userInfo] objectForKey:@"Message"]];
	[infoField display];

}

@end


@implementation ORSplashWindow
//use a #if to get rid of compiler warning about NSWindowStyleMask
#if defined(MAC_OS_X_VERSION_10_12)

- (id) initWithContentRect: (NSRect) contentRect
                 styleMask: (NSWindowStyleMask) aStyle
                   backing: (NSBackingStoreType) bufferingType
                     defer: (BOOL) flag

#else

- (id) initWithContentRect: (NSRect) contentRect
                 styleMask: (unsigned int) aStyle
                   backing: (NSBackingStoreType) bufferingType
                     defer: (BOOL) flag
#endif

{
    if (self = [super initWithContentRect: contentRect
                                styleMask: NSBorderlessWindowMask
                                  backing: bufferingType
                                    defer: flag])

    {
       // other initialization
    }

    return self;
}@end
