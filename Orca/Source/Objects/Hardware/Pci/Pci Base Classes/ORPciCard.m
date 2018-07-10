//
//  ORPciCard.m
//  Orca
//
//  Created by Mark Howe on Mon Dec 16 2002.
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
#import "ORPciCard.h"
#import "ORMacModel.h"

#pragma mark ¥¥¥Notification Strings
NSString* ORPCICardSlotChangedNotification 	= @"ORPCICardSlotChangedNotification";

@implementation ORPciCard
- (id) init
{
	self = [super init];
	hardwareExists	= NO;
	driverExists	= NO;
	return self;
}

#pragma mark ¥¥¥Initialization
-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [connectorName release];
	[connector release];
    [super dealloc];
}

- (void) awakeAfterDocumentLoaded
{
	okToShowResetWarning = YES;
}


- (Class) guardianClass 
{
	return NSClassFromString(@"ORMacModel");
}

- (NSString*) cardSlotChangedNotification
{
    return ORPCICardSlotChangedNotification;
}

- (void) loadImage:(NSString*)anImageName
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so we can draw into it.
    //---------------------------------------------------------------------------------------------------
    
    NSImage* aCachedImage = [NSImage imageNamed:anImageName];
    NSImage* i = [[[NSImage alloc] initWithSize:[aCachedImage size]]autorelease];
    [i lockFocus];
    [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositeSourceOver fraction:1.0];    
    if(![self hardwareExists]){
        NSBezierPath* path = [NSBezierPath bezierPath];
        [path moveToPoint:NSZeroPoint];
        [path lineToPoint:NSMakePoint([self frame].size.width,[self frame].size.height)];
        [path moveToPoint:NSMakePoint([self frame].size.width,0)];
        [path lineToPoint:NSMakePoint(0,[self frame].size.height)];
        [path setLineWidth:.5];
        [[NSColor redColor] set];
        [path stroke];
    }
    [i unlockFocus];
    
    [self setImage:i];

}

#pragma mark ¥¥¥Accessors

- (BOOL) hardwareExists
{
    return hardwareExists;
}

- (NSString*) connectorName
{
    return connectorName;
}
- (void) setConnectorName:(NSString*)aName
{
    [aName retain];
    [connectorName release];
    connectorName = aName;
    
}

- (ORConnector*) connector
{
    return connector;
}

- (void) setConnector:(ORConnector*)aConnector
{
    [aConnector retain];
    [connector release];
    connector = aConnector;
}


- (void) setSlot:(int)aSlot
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSlot:[self slot]];
    [self setTag:aSlot];
    [guardian positionConnector:[self connector] forCard:self];
    
    [[NSNotificationCenter defaultCenter]
			postNotificationName:[self cardSlotChangedNotification]
                          object: self];
}

- (void) setGuardian:(id)aGuardian
{
    id oldGuardian = guardian;
    [super setGuardian:aGuardian];
    
    if(oldGuardian != aGuardian){
        [oldGuardian removeDisplayOf:[self connector]];
    }
    
    [aGuardian assumeDisplayOf:[self connector]];
    [aGuardian positionConnector:[self connector] forCard:self];
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"slot %d",[self slot]];
}


#pragma mark ¥¥¥Archival
static NSString *ORPciSlotNumber		= @"ORPciCard Slot Number";
static NSString *ORPciConnectorName 	= @"ORPciCard Connector Name";
static NSString *ORPciConnector 		= @"ORPciCard Connector";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setConnectorName:[decoder decodeObjectForKey:ORPciConnectorName]];
    [self setConnector:[decoder decodeObjectForKey:ORPciConnector]];
    [self setSlot:[decoder decodeIntForKey:ORPciSlotNumber]];
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:[self connectorName] forKey:ORPciConnectorName];
    [encoder encodeObject:[self connector] forKey:ORPciConnector];
    [encoder encodeInt:[self slot] forKey:ORPciSlotNumber];
}

@end
