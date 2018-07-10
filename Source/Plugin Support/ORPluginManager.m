//
//  ORPluginManager.m
//  Orca
//
//  Created by Mark Howe on Mon Apr 21 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
//

#pragma mark •••Imported Files
#import "ORPluginManager.h"
#import "ORDefaults.h"

static ORPluginManager* pluginManager = nil;

@implementation ORPluginManager

+ (ORPluginManager*) pluginManager
{
	if(!pluginManager){
		pluginManager = [[ORPluginManager alloc] init];
	}
	return pluginManager;
}

- (id) init
{
	self = [super init];
	[self loadPlugins];
	return self;
}


- (void) dealloc
{
	pluginManager = nil;
	[pluginClasses release];
	[pluginBundles release];
	[super dealloc];
}

- (void) loadPlugins
{
	if(!pluginClasses) pluginClasses = [[NSMutableDictionary alloc] init];
	if(!pluginBundles) pluginBundles = [[NSMutableDictionary alloc] init];

	NSString* path =[[[NSUserDefaults standardUserDefaults] objectForKey: ORPluginFolderPreferences] stringByExpandingTildeInPath];
	if(path){
		NSEnumerator* e = [[NSBundle pathsForResourcesOfType:@"plugin" inDirectory:path] objectEnumerator];
		NSString* pluginPath;
		while(pluginPath = [e nextObject]){
			NSBundle* pluginBundle = [NSBundle bundleWithPath:pluginPath];
			NSDictionary* pluginDictionary = [pluginBundle infoDictionary];
			NSString* pluginName = [pluginDictionary objectForKey:@"NSPrincipalClass"];
			if(pluginName){
				Class pluginClass = [pluginBundle principalClass];
				if([pluginClass conformsToProtocol:@protocol(ORPluginProtocol)] && [pluginClass isKindOfClass:[NSObject class]]){
					[pluginClasses setObject:pluginClass forKey:pluginName];
					[pluginBundles setObject:pluginBundle forKey:pluginName];
				}
			}
		}
	}
}

- (NSObject<ORPluginProtocol>*) pluginForName:(NSString*)name
{
	Class plugin = [pluginClasses objectForKey:name];
	if(plugin){
		return [[[plugin alloc]initWithBundle:[pluginBundles objectForKey:name]] autorelease];
	}
	return nil;
}

@end
