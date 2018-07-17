//
//  ORPxiAdapterModel.h
//  Orca
//
//  Created by Mark Howe on Thurs Jan 6,2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics 
//sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#pragma mark ¥¥¥Imported Files
#import "ORMPodMiniCrateModel.h"

@implementation ORMPodMiniCrateModel

#pragma mark ¥¥¥initialization
- (void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so that each crate can have its own version for drawing into.
    //---------------------------------------------------------------------------------------------------
    NSImage* aCachedImage = [NSImage imageNamed:@"MPodMiniCrateSmall"];
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
    if(powerOff){
        NSAttributedString* s = [[[NSAttributedString alloc] initWithString:@"No Pwr"
                                                                 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                     [NSColor redColor],NSForegroundColorAttributeName,
                                                                     [NSFont fontWithName:@"Geneva" size:10],NSFontAttributeName,
                                                                     nil]] autorelease]; 
        [s drawAtPoint:NSMakePoint(5,40)];
    }
    
    if([[self hvConstraints] count]){
        NSImage* constraintImage = [NSImage imageNamed:@"smallLock"];
        [constraintImage drawAtPoint:NSMakePoint([[self image] size].width/2 - [constraintImage size].width/2,35) fromRect:[constraintImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
    }
    
    if([[self orcaObjects] count]){
        NSAffineTransform* transform = [NSAffineTransform transform];
        [transform translateXBy:3 yBy:65];
        [transform scaleXBy:.46 yBy:.46];
        [transform concat];
        NSEnumerator* e  = [[self orcaObjects] objectEnumerator];
        OrcaObject* anObject;
        while(anObject = [e nextObject]){
            BOOL oldHighlightState = [anObject highlighted];
            [anObject setHighlighted:NO];
            [anObject drawSelf:NSMakeRect(0,0,500,[[self image] size].height)];
            [anObject setHighlighted:oldHighlightState];
        }
    }
    [i unlockFocus];
    [self setImage:i];
    [i release];
    
    [[NSNotificationCenter defaultCenter]
                postNotificationName:OROrcaObjectImageChanged
                              object:self];
}

- (void) makeMainController
{
    [self linkToController:@"ORMPodMiniCrateController"];
}

- (NSString*) helpURL
{
	return @"MPod/MiniCrate.html";
}
@end


@implementation ORMPodMiniCrateModel (OROrderedObjHolding)
- (int) maxNumberOfObjects	{ return 5; }
@end
