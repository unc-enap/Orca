//
//  ORcPCICrateModel.m
//  Orca
//
//  Created by Mark Howe on Mon Feb 6, 2006
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
#import "ORcPCICrateModel.h"
#import "ORcPCICard.h"
#import "ORcPCIBusProtocol.h"

@implementation ORcPCICrateModel

#pragma mark ¥¥¥initialization

- (void) makeConnectors
{
	//short circuit the default connection
}

- (void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so that each crate can have its own version for drawing into.
    //---------------------------------------------------------------------------------------------------
    NSImage* aCachedImage = [NSImage imageNamed:@"cPCICrateSmall"];
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
    NSAttributedString* n = [[NSAttributedString alloc]
							initWithString:[NSString stringWithFormat:@"%d",[self crateNumber]] 
								attributes:[NSDictionary dictionaryWithObject:[NSFont labelFontOfSize:13] forKey:NSFontAttributeName]];
	
	[n drawInRect:NSMakeRect(30,[i size].height-20,[i size].width-20,18)];
	[n release];

    if([[self orcaObjects] count]){
        NSAffineTransform* transform = [NSAffineTransform transform];
        [transform translateXBy:25 yBy:15];
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
    [self linkToController:@"ORcPCICrateController"];
}

- (NSString*) helpURL
{
	return @"cPCI/Crate.html";
}

#pragma mark ¥¥¥Accessors
- (NSString*) adapterArchiveKey
{
	return @"cPCI Adapter";
}

- (NSString*) crateAdapterConnectorKey
{
	return @"cPCI Crate Adapter Connector";
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
	[super registerNotificationObservers];
	
    [notifyCenter addObserver : self
                     selector : @selector(viewChanged:)
                         name : ORcPCICardSlotChangedNotification
                       object : nil];

}


- (void) runAboutToStart:(NSNotification*)aNote
{
}

- (void) runStarted:(NSNotification*)aNote
{
}

- (void) runAboutToStop:(NSNotification*)aNote
{
}

- (void) connected
{
	[[self orcaObjects] makeObjectsPerformSelector:@selector(connected)];
}

- (void) disconnected
{
	[[self orcaObjects] makeObjectsPerformSelector:@selector(disconnected)];
}

@end

@implementation ORcPCICrateModel (OROrderedObjHolding)
- (int) maxNumberOfObjects	{ return 8; }
- (int) objWidth			{ return 12; }
- (NSRange) legalSlotsForObj:(id)anObj
{
	if( [anObj isKindOfClass:NSClassFromString(@"ORcPCIControllerCard")]){
		return NSMakeRange(0,1);
	}
	else {
		return  NSMakeRange(1,[self maxNumberOfObjects]);
	}
}

@end

