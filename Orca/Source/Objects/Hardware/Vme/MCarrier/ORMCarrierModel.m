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
#import "ORMCarrierModel.h"
#import "ORVmeMCard.h"

#pragma mark ¥¥¥Definitions
#define kDefaultMCarrierAddressModifier	0x29
#define kDefaultMCarrierBaseAddress		0x00009000

@implementation ORMCarrierModel

#pragma mark ¥¥¥Initialization
- (id) init //designated initializer
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setAddressModifier:kDefaultMCarrierAddressModifier];
    [self setBaseAddress:kDefaultMCarrierBaseAddress];
    
    [[self undoManager] enableUndoRegistration];
    
    
    return self;
    
}
- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"MCarrierCard"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORMCarrierController"];
}

- (NSString*) helpURL
{
	return @"VME/M_Carrier.html";
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0xFE);
}

- (void) positionConnector:(ORConnector*)aConnector forCard:(id)aCard
{
    NSRect aFrame = [aConnector localFrame];
    int ip = [aCard slot];
    float x = 20 + [self slot] * 16*.62;
    float y = 33 + ip*32*.62;
    aFrame.origin = NSMakePoint(x,y);
    [aConnector setLocalFrame:aFrame];
}

- (void) probe
{
    NSEnumerator* e = [[self orcaObjects] objectEnumerator];
    ORVmeMCard* aCard;
    while(aCard = [e nextObject]){
        @try {
            [aCard probe];
        }
		@catch(NSException* localException) {
            NSLog(@"Exception: %@\n",localException);
        }
    }
}

@end

@implementation ORMCarrierModel (OROrderedObjHolding)
- (int) maxNumberOfObjects { return 4;  }
- (int) objWidth		 { return 60; }
- (int) groupSeparation	 { return 0; }
@end

