//
//  ORReplayFileFactory.m
//  Orca
//
//  Created by Rielage on Thu Oct 02 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ORReplayFileFactory.h"
#import "ORReplayFileModel.h"

@implementation ORReplayFileFactory

- (void) makeObject:(NSRect)aFrame
{
    ORReplayFileModel* anObject = [[ORReplayFileModel alloc] init];
    [anObject setUpImage];
	[anObject makeConnectors];
    [self setOrcaObject: [anObject autorelease]];
}

@end
