//
//  NSApplication_Extensions.h
//  Orca
//
//  Created by Mark Howe on 3/30/14.
//
//

#import <Cocoa/Cocoa.h>

#define NSApplicationRelaunchDaemon @"RelaunchOrca"

@interface NSApplication (OrcaExtensions)
- (void)relaunch:(id)sender arguments:(NSArray*)arguments;
@end
