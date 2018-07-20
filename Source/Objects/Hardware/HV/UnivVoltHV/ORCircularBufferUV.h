//
//  ORCircularBufferUV.h
//  Orca
//
//  Created by Jan Wouters on 4/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//#define CBkTimeKey = @"Time";
//#define CBkHVKey = "@HVValue";

//const int CBkTimeIndex = 0;
//const int CBkHVIndex = 1;


@interface ORCircularBufferUV : NSObject {
	NSMutableArray*		mStorageArray;
	int32_t				mSize;
	int32_t				mHeadIndex;
	int32_t				mTailIndex;
	Boolean				mFWrapped;
	
}

- (id) init;
- (void) setSize: (int32_t) aSize;
- (NSUInteger) count;
- (void) insertHVEntry: (NSDate *) aDateOfAquistion hvValue: (NSNumber*) anHVEntry;
- (NSDictionary *) HVEntry: (int32_t) anOffset;

@end

extern NSString* CBeTime ;
extern NSString* CBeValue;
