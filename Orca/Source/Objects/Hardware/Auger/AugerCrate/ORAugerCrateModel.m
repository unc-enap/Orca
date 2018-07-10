//
//  ORAugerCrateModel.m
//  Orca
//
//  Created by Mark Howe on Fri Aug 5, 2005.
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
#import "ORAugerDefs.h"
#import "ORAugerCrateModel.h"
#import "ORAugerFireWireCard.h"

#import "ORAugerCard.h"

#pragma mark ¥¥¥Local Strings
static NSString* ORAugerCrateFireWireIn 	= @"ORAugerCrateFireWireIn";
static NSString* ORAugerCrateFireWireOut 	= @"ORAugerCrateFireWireOut";

@implementation ORAugerCrateModel

#pragma mark ¥¥¥initialization

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void) makeConnectors
{	
	ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(0,0) withGuardian:self withObjectLink:self];
	[[self connectors] setObject:aConnector forKey:ORAugerCrateFireWireIn];
    [aConnector setOffColor:[NSColor magentaColor]];
    [aConnector setConnectorType:'FWrI'];				  //this is a FireWire Input
	[aConnector addRestrictedConnectionType: 'FWrO' ]; //can only connect to FireWire Outputs
	[aConnector release];

}

- (void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so that each crate can have its own version for drawing into.
    //---------------------------------------------------------------------------------------------------
    NSImage* aCachedImage = [NSImage imageNamed:@"AugerCrate"];
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
    if(powerOff){
        NSAttributedString* s = [[[NSAttributedString alloc] initWithString:@"No Pwr"
                                                                 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                     [NSColor redColor],NSForegroundColorAttributeName,
                                                                     [NSFont fontWithName:@"Geneva" size:10],NSFontAttributeName,
                                                                     nil]] autorelease]; 
        [s drawAtPoint:NSMakePoint(25,5)];
    }
    
    if([[self orcaObjects] count]){
        NSAffineTransform* transform = [NSAffineTransform transform];
        [transform translateXBy:10 yBy:25];
        [transform scaleXBy:.5 yBy:.5];
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
    [self linkToController:@"ORAugerCrateController"];
}


#pragma mark ¥¥¥Accessors

- (NSString*) adapterArchiveKey
{
	return @"Auger Adapter";
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(viewChanged:)
                         name : ORAugerCardSlotChangedNotification
                       object : nil];
    
}

- (void) setCrateNumber: (unsigned int) aCrateNumber
{
	[super setCrateNumber:aCrateNumber];
	ORConnector* aConnector = [[self connectors] objectForKey:ORAugerCrateFireWireOut];
	id anObj = [aConnector connectedObject];
	[anObj setCrateNumber:[self crateNumber]+1];

}

- (void) findInterface
{
	[[self adapter] findInterface];
}

- (void) adapterChanged:(NSNotification*)aNote
{
	if([aNote object] == self){
		[[self adapter] findInterface];
	}
}

- (id) getFireWireInterface:(unsigned long)aVenderID
{
	id connectedObj = [self objectConnectedTo:ORAugerCrateFireWireIn];
	return [ connectedObj getFireWireInterface:aVenderID];
}

- (void) checkCards
{
	NSEnumerator* e  = [[self orcaObjects] objectEnumerator];
	ORAugerCard* anObject;
	while(anObject = [e nextObject]){
		[anObject checkPresence];
	}	
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
	[[self undoManager] disableUndoRegistration];
        
	[[self undoManager] enableUndoRegistration];
	
	[self registerNotificationObservers];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
}
@end
