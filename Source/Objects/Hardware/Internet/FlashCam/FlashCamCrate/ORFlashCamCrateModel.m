//  Orca
//  ORFlashCamCrateModel.m
//
//  Created by Tom Caldwell on Monday Jan 1, 2020
//  Copyright (c) 2020 University of North Carolina. All rights reserved.
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

#import "ORFlashCamCrateModel.h"

@implementation ORFlashCamCrateModel

#pragma mark •••Initialization

- (void) setUpImage
{
    // cache the image and scale the size
    NSImage* aCachedImage = [NSImage imageNamed:@"flashcam_crate"];
    NSSize size = [aCachedImage size];
    NSSize newsize;
    newsize.width  = 0.595*size.width*14./20;
    newsize.height = 0.5*size.height;
    // create the new image and a box to draw it in
    NSImage* i = [[NSImage alloc] initWithSize:newsize];
    [i lockFocus];
    NSRect rect;
    rect.origin = NSZeroPoint;
    rect.size.width = newsize.width;
    rect.size.height = newsize.height;
    // draw the image in the scaled box
    [aCachedImage drawInRect : rect
                    fromRect : NSZeroRect
                   operation : NSCompositingOperationSourceOver
                    fraction : 1.0];
    // draw the crate number
     NSFont* font = [NSFont messageFontOfSize:9];
     NSAttributedString* cname =  [[[NSAttributedString alloc]
                                      initWithString:[NSString stringWithFormat:@"Crate %d",[self crateNumber]]
                                      attributes:[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName,[NSColor whiteColor],NSForegroundColorAttributeName,nil]]autorelease];
     NSSize textSize = [cname size];
     [cname drawInRect:NSMakeRect(newsize.width/2-textSize.width/2, newsize.height-textSize.height*1.6, textSize.width, textSize.height)];
    // draw the crate objects
    if([[self orcaObjects] count]){
        NSAffineTransform* transform = [NSAffineTransform transform];
        [transform translateXBy:17 yBy:18];
        [transform scaleXBy:0.6 yBy:0.5];
        [transform concat];
        NSEnumerator* e  = [[self orcaObjects] objectEnumerator];
        OrcaObject* anObject;
        while(anObject = [e nextObject]){
            BOOL oldHighlightState = [anObject highlighted];
            [anObject setHighlighted:NO];
            [anObject drawSelf:NSMakeRect(0,0,350,[[self image] size].height)];
            [anObject setHighlighted:oldHighlightState];
        }
    }
    [i unlockFocus];
    [self setImage:i];
    [i release];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:OROrcaObjectImageChanged
                                                        object:self];
}

- (void) makeMainController
{
    [self linkToController:@"ORFlashCamCrateController"];
}

- (void) makeConnectors
{
    [super makeConnectors];
}

- (NSString*) helpURL
{
    return @"FlashCam/Crates.html";
}

#pragma mark •••Accessors
- (NSString*) adapterArchiveKey
{
    return @"FlashCam Adapter";
}

- (NSString*) crateAdapterConnectorKey
{
    return @"FlashCam Crate Adapter Connector";
}
@end

@implementation ORFlashCamCrateModel (OROrderedObjHolding)
- (int) maxNumberOfObjects { return 14; }
- (int) objWidth { return 25; }
@end
