//
//  ORRunWorker.m
//  Orca
//
//  Created by Mark Howe on Thu Nov 21 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
//

#import "ORRunWorker.h"
#import "ORRunModel.h"

@implementation ORRunWorker

- (void) doWork
{
	ORRunModel *theRunModel = (ORRunModel *)[self parent];
	[theRunModel doWork];
	[super doWork];
}


@end
