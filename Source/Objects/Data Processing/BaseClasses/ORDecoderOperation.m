//
//  ORDecoderOperation.m
//  OrcaIntel
//
//  Created by Mark Howe on 11/14/2009.
//  Copyright 2009 CENPA, University of North Carolina. All rights reserved.
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

#import "ORDecoderOperation.h"

@implementation ORDecoderOperation
- (id)initWithPath:(NSString*)aPath delegate:(id)aDelegate
{
	self = [super init];
    [self setFilePath:aPath];
	[self setDelegate:aDelegate];
	fp = [[NSFileHandle fileHandleForReadingAtPath:aPath] retain];
	[self setCurrentDecoder: [ORDecoder decoderWithFile:fp]];
    return self;
}

- (void) dealloc
{
    [fp closeFile];
	[filePath release];
	[currentDecoder release];
	[super dealloc];
}

- (void) setDelegate:(id)aDelegate
{
	delegate = aDelegate;
}

- (void) setCurrentDecoder:(ORDecoder*)aDecoder
{
	[aDecoder retain];
	[currentDecoder release];
	currentDecoder = aDecoder;
    [currentDecoder setSkipRateCounts:YES];
	needToSwap = [currentDecoder needToSwap];
}

- (void) setFilePath:(NSString*)aPath
{
	aPath = [aPath stringByExpandingTildeInPath];
	[filePath release];
    filePath = [aPath copy];
}

- (void) main 
{
	//subclasses need to override
}

- (NSDictionary*) currentHeader
{
	return [currentDecoder fileHeader];
}

@end
