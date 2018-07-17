//
//  ORIpeV4MiniCrateModel.m
//  Orca
//
//  Created by Mark Howe on Fri Aug 5, 2005.
//  Copyright ¬© 2002 CENPA, University of Washington. All rights reserved.
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

#pragma mark •••Imported Files
#import "ORIpeV4MiniCrateModel.h"

@implementation ORIpeV4MiniCrateModel

#pragma mark •••initialization

- (void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so that each crate can have its own version for drawing into.
    //---------------------------------------------------------------------------------------------------
    NSImage* aCachedImage = [NSImage imageNamed:@"IpeV4MiniCrate"];
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
    
    if([[self orcaObjects] count]){
        NSAffineTransform* transform = [NSAffineTransform transform];
        [transform translateXBy:8 yBy:35];
        [transform scaleXBy:.45 yBy:.45];
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
    [self linkToController:@"ORIpeV4MiniCrateController"];
}

#pragma mark •••OROrderedObjHolding
- (int) maxNumberOfObjects {return 5;}

- (NSRange) legalSlotsForObj:(id)anObj
{
	if(    [anObj isKindOfClass:NSClassFromString(@"ORIpeV4SLTModel")]
        || [anObj isKindOfClass:NSClassFromString(@"OREdelweissSLTModel")]
        || [anObj isKindOfClass:NSClassFromString(@"ORKatrinV4SLTModel")] ){
		return NSMakeRange(2,1);
	}
	else {
		return  NSMakeRange(0,[self maxNumberOfObjects]);
	}
}

- (BOOL) slot:(int)aSlot excludedFor:(id)anObj 
{ 
	if( !(   [anObj isKindOfClass:NSClassFromString(@"ORIpeV4SLTModel")]
          || [anObj isKindOfClass:NSClassFromString(@"OREdelweissSLTModel")]
          || [anObj isKindOfClass:NSClassFromString(@"ORKatrinV4SLTModel")]
          )
           && (aSlot==2)
       ){
		return YES;
	}
	else return NO;
}

@end
