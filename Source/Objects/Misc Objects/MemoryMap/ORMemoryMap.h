//
//  ORMemoryMap.h
//  Orca
//
//  Created by Mark Howe on 3/30/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define ORMemoryMapChanged @"ORMemoryMapChanged"
@class ORMemoryArea;

@interface ORMemoryMap : NSObject {
	NSMutableArray* memoryAreas;
	unsigned lowValue;
	unsigned highValue;
}


- (id) init;
- (void) dealloc;
- (unsigned) lowValue;
- (unsigned) highValue;
- (unsigned) count;
- (ORMemoryArea*) memoryArea:(int)index;
- (void) addMemoryArea:(ORMemoryArea*)anArea;

@end
