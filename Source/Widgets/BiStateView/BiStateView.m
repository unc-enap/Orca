//
//  BiStateView.m
//  Orca
//
//  Created by Mark Howe on 9/28/04.
//  Copyright 2004 CENPA, University of Washington. All rights reserved.
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


#import "BiStateView.h"


@implementation BiStateView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setOnImageName:@"checkMark"];
        [self setOffImageName:@"exMark"];
        [self setUnKnownImageName:@"questionMark"];
        [self setState:UNKNOWN];
    }
    return self;
}

- (void) dealloc
{
    [self setOnImageName: nil];
    [self setOffImageName: nil];
    [self setUnKnownImageName: nil];
    [self setImage: nil];

    [super dealloc];
}


- (NSImage *) image
{
    return image; 
}

- (void) setImage: (NSImage *) anImage
{
    [anImage retain];
    [image release];
    image = anImage;
}

- (NSString *) onImageName
{
    return onImageName; 
}

- (void) setOnImageName: (NSString *) aName
{
    [aName retain];
    [onImageName release];
    onImageName = aName;
}


- (NSString *) offImageName
{
    return offImageName; 
}

- (void) setOffImageName: (NSString *) aName
{
    [aName retain];
    [offImageName release];
    offImageName = aName;
}

- (NSString *) unKnownImageName
{
    return unKnownImageName; 
}

- (void) setUnKnownImageName: (NSString *) UnKnownImageName
{
    [UnKnownImageName retain];
    [unKnownImageName release];
    unKnownImageName = UnKnownImageName;
}

- (int) state
{
    return state;
}

- (void) setState: (int) flag
{
    state = flag;
    switch(flag){
        case 0: [self setImage:[NSImage imageNamed:offImageName]]; break;
        case 1: [self setImage:[NSImage imageNamed:onImageName]]; break;
        default: [self setImage:[NSImage imageNamed:unKnownImageName]]; break;
    }
    [image setSize:[self bounds].size];
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect 
{
    [image drawAtPoint:NSZeroPoint fromRect:[image imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
}

@end
