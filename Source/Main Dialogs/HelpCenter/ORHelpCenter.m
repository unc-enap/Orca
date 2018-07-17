//----------------------------------------------------------
//  ORHelpCenter.h
//
//  Created by Mark Howe on Wed Mar 29, 2006.
//  Copyright  © 2002 CENPA. All rights reserved.
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
#import "ORHelpCenter.h"

#define kORCAHelpURL @"http://orca.physics.unc.edu"
#define kAccountRoot @"~markhowe"

@implementation ORHelpCenter
- (id)init
{
    self = [super initWithWindowNibName:@"HelpCenter"];
	[[NSNotificationCenter defaultCenter] addObserver : self
											 selector : @selector(defaultPathChanged:)
												 name :	ORHelpFilesPathChanged
											   object : nil];
    return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (NSString *) helpFilePath 
{
	NSString* theHelpFilePath;
	BOOL useCustomLocation = [[[NSUserDefaults standardUserDefaults] objectForKey:ORHelpFilesUseDefault] boolValue];
	if(useCustomLocation){
		theHelpFilePath = [[NSUserDefaults standardUserDefaults] objectForKey:ORHelpFilesPath];
		if([theHelpFilePath length]){
			if(![[theHelpFilePath lastPathComponent] isEqualToString:@"index.html"]){
				theHelpFilePath = [theHelpFilePath stringByAppendingString:@"/index.html"];
			}
		}
		else {
			[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:YES] forKey:ORHelpFilesUseDefault];
			theHelpFilePath = kORCAHelpURL;
		}
	}
	else {
		theHelpFilePath = kORCAHelpURL;
	}
	return theHelpFilePath;
}

- (void) awakeFromNib
{
	//[self defaultPathChanged:nil];
	[defaultPathField setStringValue:[self helpFilePath]];
	[[self window] orderOut:nil]; //this forces everything to be set up so the first showHelpCenterPage call works
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"Load Failed"];
    [alert setInformativeText:@"Check Internet Connection"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:nil];
#else
    NSBeginAlertSheet (@"Load Failed",@"OK",nil,nil,[self window],self,nil,nil,nil,@"Check Internet Connection");
#endif
}

- (void) defaultPathChanged:(NSNotification*) aNote
{
	[defaultPathField setStringValue:[self helpFilePath]];
	if([[self helpFilePath] length]){
		[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[self helpFilePath]]]];
	}
}

- (void) showHelpCenterPage:(NSString*)aPage
{
	if([aPage length]){
		NSString* mainPage = [self helpFilePath];
		NSString* thePage = [mainPage stringByAppendingFormat:@"/%@/%@",kAccountRoot,aPage];
		[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:thePage]]];
		[[self window] makeKeyAndOrderFront:nil];
	}
	else [self showHelpCenter:self];
}


#pragma mark ¥¥¥Actions
- (IBAction) showHelpCenter:(id)sender
{
    if([[self helpFilePath] length]){
		[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[self helpFilePath]]]];
	}
    [[self window] makeKeyAndOrderFront:nil];

}

- (IBAction) goHome:(id)sender
{
	if([[self helpFilePath] length]){
		[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[self helpFilePath]]]];
	}
}
@end
