//
//  ORVme64CrateModel.m
//  Orca
//
//  Created by Mark Howe on Tue Oct 23 2007.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark ¥¥¥Imported Files
#import "ORVme64CrateModel.h"
#import "ORVmeAdapter.h"

@implementation ORVme64CrateModel

#pragma mark ¥¥¥initialization

- (void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so that each crate can have its own version for drawing into.
    //---------------------------------------------------------------------------------------------------
    NSImage* aCachedImage = [NSImage imageNamed:@"Vme64CrateSmall"];
    NSSize cachedImageSize = [aCachedImage size];
    NSImage* i = [[NSImage alloc] initWithSize:cachedImageSize];
    [i lockFocus];
    [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
    if(powerOff){
        NSAttributedString* s = [[[NSAttributedString alloc] initWithString:@"No Pwr"
                                                                 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                     [NSColor redColor],NSForegroundColorAttributeName,
                                                                     [NSFont fontWithName:@"Geneva" size:10],NSFontAttributeName,
                                                                     nil]] autorelease]; 
        [s drawAtPoint:NSMakePoint(25,5)];
    }
    NSFont* theFont = [NSFont messageFontOfSize:9];
    NSAttributedString* theName =  [[[NSAttributedString alloc]
                                     initWithString:[NSString stringWithFormat:@"Crate %d",[self crateNumber]]
                                     attributes:[NSDictionary dictionaryWithObjectsAndKeys:theFont,NSFontAttributeName,[NSColor blackColor],NSForegroundColorAttributeName,nil]]autorelease];
    NSSize textSize = [theName size];
    
    [theName drawInRect:NSMakeRect(cachedImageSize.width/2-textSize.width/2,cachedImageSize.height-textSize.height-4,textSize.width,textSize.height)];
   
    if([[self orcaObjects] count]){
        NSAffineTransform* transform = [NSAffineTransform transform];
        [transform translateXBy:15 yBy:30];
        [transform scaleXBy:.62 yBy:.62];
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
    [self linkToController:@"ORVme64CrateController"];
}
@end

@implementation ORVme64CrateModel (OROrderedObjHolding)
- (int) maxNumberOfObjects
{
    return 21;
}
@end
