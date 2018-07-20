//
//  ORMemoryArea.h
//  Orca
//
//  Created by Mark Howe on 3/30/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ORMemoryArea : NSObject {
	NSString* name;
	unsigned lowValue;
	unsigned highValue;
	NSMutableArray* elements;
}
- (NSString*) name;
- (void) setName:(NSString*)aName;
- (unsigned) lowValue;
- (unsigned) highValue;

- (void) addMemorySection:(NSString*)aName 
			  baseAddress:(uint32_t)anAddress 
		   startingOffset:(int)offset 
			  sizeInBytes:(uint32_t)aSize;

- (unsigned) count;
- (NSString*) name:(unsigned)index;
- (uint32_t)  baseAddress:(int)index;
- (int)  offset:(int)index;
- (uint32_t)  sizeInBytes:(int)index;

@end
