//
//  ApplicationSupport.m
//  Orca
//
//  Created by Mark Howe on 6/25/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
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

#import "ApplicationSupport.h"
#import "SynthesizeSingleton.h"


@implementation ApplicationSupport

SYNTHESIZE_SINGLETON_FOR_CLASS(ApplicationSupport);

- (NSString*) applicationSupportFolder:(NSString*)subPath
{
	NSString*    path = [self applicationSupportFolder];
    NSFileManager* fm = [NSFileManager defaultManager];
	NSArray* parts = [subPath componentsSeparatedByString:@"/"];
	NSEnumerator* e = [parts objectEnumerator];
	NSString* part;
	while(part = [e nextObject]){
		path = [path stringByAppendingPathComponent:part];
		if(![fm fileExistsAtPath:path]){
			[fm createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];        
		}
	}
	return path;
}

- (NSString*) applicationSupportFolder
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString* basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    
    NSFileManager* fm = [NSFileManager defaultManager];
	
	basePath = [basePath stringByAppendingPathComponent:@"ORCA"];
	if(![fm fileExistsAtPath:basePath]){
		[fm createDirectoryAtPath:basePath withIntermediateDirectories:NO attributes:nil error:nil];        
	}
	
    return basePath;
}

- (NSString*) hostAddress
{
	NSString* hostAddress = @"Unknown";
	NSArray* names =  [[NSHost currentHost] addresses];
	id aName;
	int index = 0;
	int n = [names count];
	int i;
	for(i=0;i<n;i++){
		aName = [names objectAtIndex:i];
		if([aName rangeOfString:@"::"].location == NSNotFound){
			if([aName rangeOfString:@".0.0."].location == NSNotFound){
				hostAddress = aName;
				break;
			}
			index++;
		}
	}
	return hostAddress;
}	
@end
