//
//  ORPluginManager.h
//  Orca
//
//  Created by Mark Howe on Mon Apr 21 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
//

#pragma mark •••Imported Files
#import <Foundation/Foundation.h>
#import "ORPluginProtocol.h"

@interface ORPluginManager : NSObject {
	NSMutableDictionary* pluginClasses;
	NSMutableDictionary* pluginBundles;
}

+ (ORPluginManager*) pluginManager;

- (id) 	 init;
- (void) dealloc;
- (void) loadPlugins;

- (NSObject<ORPluginProtocol>*) pluginForName:(NSString*)name;

@end