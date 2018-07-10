//
//  NSApplication_Extensions.h
//  Orca
//
//  Created by Mark Howe on 3/30/14.
//
//

#import <Cocoa/Cocoa.h>
#import "NSApplication+Extensions.h"
@implementation NSApplication (OrcaExtensions)

- (void)relaunch:(id)sender arguments:(NSArray*)arguments
{
	NSString *daemonPath = [[NSBundle mainBundle] pathForResource:NSApplicationRelaunchDaemon ofType:nil];
    NSMutableArray* theArguments = [NSMutableArray arrayWithObjects:
                             [[NSBundle mainBundle] bundlePath],
                             [NSString stringWithFormat:@"%d", [[NSProcessInfo processInfo] processIdentifier]],
                             nil];
    if(arguments)[theArguments addObjectsFromArray:arguments];
	[NSTask launchedTaskWithLaunchPath:daemonPath
                             arguments: theArguments];
	[self terminate:sender];
}

@end
