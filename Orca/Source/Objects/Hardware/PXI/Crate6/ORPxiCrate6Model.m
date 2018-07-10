//
//  ORPxiAdapterModel.h
//  Orca
//
//  Created by Mark Howe on Thurs Aug 26 2010
//  Copyright (c) 2010 University of North Carolina. All rights reserved.
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
#import "ORPxiCrate6Model.h"
#import "ORPxiAdapterModel.h"

@implementation ORPxiCrate6Model

#pragma mark ¥¥¥initialization
- (void) makeConnectors
{	
	[super makeConnectors];
	ORConnector* aConnector = [[self connectors] objectForKey:[self crateAdapterConnectorKey]];
    [aConnector setOffColor:[NSColor darkGrayColor]];
	[aConnector setConnectorType:'PXIA'];    
}

- (void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so that each crate can have its own version for drawing into.
    //---------------------------------------------------------------------------------------------------
    NSImage* aCachedImage = [NSImage imageNamed:@"PxiCrate6Small"];
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
    if(powerOff){
        NSAttributedString* s = [[[NSAttributedString alloc] initWithString:@"No Pwr"
                                                                 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                     [NSColor redColor],NSForegroundColorAttributeName,
                                                                     [NSFont fontWithName:@"Geneva" size:10],NSFontAttributeName,
                                                                     nil]] autorelease]; 
        [s drawAtPoint:NSMakePoint(90,0)];
    }
    
    if([[self orcaObjects] count]){
        NSAffineTransform* transform = [NSAffineTransform transform];
        [transform translateXBy:68 yBy:20];
        [transform scaleXBy:.43 yBy:.43];
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
    [self linkToController:@"ORPxiCrate6Controller"];
}

//- (NSString*) helpURL
//{
//	return @"Pxi/Crates.html";
//}

- (void) connected
{
	[[self orcaObjects] makeObjectsPerformSelector:@selector(connected)];
}

- (void) disconnected
{
	[[self orcaObjects] makeObjectsPerformSelector:@selector(disconnected)];
}

#pragma mark ¥¥¥Accessors
- (NSString*) adapterArchiveKey
{
	return @"Pxi Adapter";
}

- (NSString*) crateAdapterConnectorKey
{
	return @"Pxi Crate Adapter Connector";
}

- (void) setAdapter:(id)anAdapter
{
	[super setAdapter:anAdapter];
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
	[super registerNotificationObservers];
	   
    [notifyCenter addObserver : self
                     selector : @selector(viewChanged:)
                         name : ORPxiCardSlotChangedNotification
                       object : nil];


    [notifyCenter addObserver : self
                     selector : @selector(powerFailed:)
                         name : @"PxiPowerFailedNotification"
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(powerRestored:)
                         name : @"PxiPowerRestoredNotification"
                       object : nil];
}


- (void) powerFailed:(NSNotification*)aNotification
{
    if([aNotification object] == [self controllerCard]){
        [self setPowerOff:YES];
		if(!cratePowerAlarm){
			cratePowerAlarm = [[ORAlarm alloc] initWithName:@"No Pxi Crate Power" severity:0];
			[cratePowerAlarm setSticky:YES];
			[cratePowerAlarm setHelpStringFromFile:@"NoPxiCratePowerHelp"];
			[cratePowerAlarm postAlarm];
		} 
    }
}

- (void) powerRestored:(NSNotification*)aNotification
{
    if([aNotification object] == [self controllerCard]){
        [self setPowerOff:NO];
		[cratePowerAlarm clearAlarm];
		[cratePowerAlarm release];
		cratePowerAlarm = nil;
    }
}
@end


@implementation ORPxiCrate6Model (OROrderedObjHolding)
- (int) maxNumberOfObjects	{ return 6; }
- (int) objWidth			{ return 28; }
@end
