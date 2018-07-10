//
//  ORQuadStateBox.m
//  Orca
//
//  Created by Mark Howe on Thursday Jun 18, 2015.
//  Copyright 2015 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------
#import "ORQuadStateBox.h"
#import "NSImage+Extensions.h"
#import "SynthesizeSingleton.h"

@implementation ORQuadStateBox

SYNTHESIZE_SINGLETON_FOR_ORCLASS(QuadStateBox);

- (NSImage*) imageForState:(int)aState
{
	NSNumber* theStateKey   = [NSNumber numberWithInt:aState];
	NSImage* anImage        = [imageDictionary objectForKey:theStateKey];
	if(!anImage) {
        if(!imageDictionary) imageDictionary = [[NSMutableDictionary dictionary] retain];
        switch(aState){
            case kQuadStateBoxOff:                  anImage = [NSImage imageNamed:@"offBox"];           break;
            case kQuadStateBoxOnOffPending:         anImage = [NSImage imageNamed:@"onOffPendingBox"];  break;
            case kQuadStateBoxImageOffOnPending:    anImage = [NSImage imageNamed:@"offOnPendingBox"];  break;
            case kQuadStateBoxImageOn:              anImage = [NSImage imageNamed:@"onBox"];            break;
            default:                                anImage = nil;
        }
        if(anImage)[imageDictionary setObject:anImage forKey:theStateKey];

	}
	return anImage;
}
@end
