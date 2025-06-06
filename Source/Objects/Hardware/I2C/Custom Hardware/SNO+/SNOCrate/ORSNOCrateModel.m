//
//  ORSNOCrateModel.m
//  Orca
//
//  Created by Mark Howe on Tue, Apr 30, 2008.
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


#pragma mark •••Imported Files
#import "ORSNOCrateModel.h"
#import "ORSNOCard.h"
#import "ORSNOConstants.h"
#import "ORXL3Model.h"
#import "ORFec32Model.h"
#import "ObjectFactory.h"
#import "OROrderedObjManager.h"
#import "ORSelectorSequence.h"

static const struct {
	uint32_t Register;	//XL2
	uint32_t Memory;	//XL2
	NSString* IPAddress;	//XL3
	uint32_t Port;	//XL3
} kSnoCrateBaseAddress[]={
{0x00002800, 	0x01400000,	@"10.0.0.1",	44701},	//0
{0x00003000,	0x01800000,	@"10.0.0.2",	44702},	//1
{0x00003800,	0x01c00000,	@"10.0.0.3",	44703},	//2
{0x00004000,	0x02000000,	@"10.0.0.4",	44704},	//3
{0x00004800,	0x02400000,	@"10.0.0.5",	44705},	//4
{0x00005000,	0x02800000,	@"10.0.0.6",	44706},	//5
{0x00005800,	0x02c00000,	@"10.0.0.7",	44707},	//6
{0x00006000,	0x03000000,	@"10.0.0.8",	44708},	//7
{0x00006800,	0x03400000,	@"10.0.0.9",	44709},	//8
{0x00007800,	0x03C00000,	@"10.0.0.10",	44710},	//9
{0x00008000,	0x04000000,	@"10.0.0.11",	44711},	//10
{0x00008800,	0x04400000,	@"10.0.0.12",	44712},	//11
{0x00009000,	0x04800000,	@"10.0.0.13",	44713},	//12
{0x00009800,	0x04C00000,	@"10.0.0.14",	44714},	//13
{0x0000a000,	0x05000000,	@"10.0.0.15",	44715},	//14
{0x0000a800,	0x05400000,	@"10.0.0.16",	44716},	//15
{0x0000b000,	0x05800000,	@"10.0.0.17",	44717},	//16
{0x0000b800,	0x05C00000,	@"10.0.0.18",	44718},	//17
{0x0000c000,	0x06000000,	@"10.0.0.19",	44719},	//18
//{0x0000c800,	0x06400000}	//crate 19 is really at 0xd000
{0x0000d000,	0x06800000,	@"10.0.0.20",	44720}	//19
};

NSString* ORSNOCrateSlotChanged = @"ORSNOCrateSlotChanged";

@implementation ORSNOCrateModel

#pragma mark •••initialization
- (void) makeConnectors
{	
}

- (void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so that each crate can have its own version for drawing into.
    //---------------------------------------------------------------------------------------------------
    NSImage* aCachedImage = [NSImage imageNamed:@"SNOCrate"];
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
    if(powerOff){
        NSAttributedString* s = [[[NSAttributedString alloc] initWithString:@"No Pwr"
			attributes:[NSDictionary dictionaryWithObjectsAndKeys:
			[NSColor redColor],NSForegroundColorAttributeName,
			[NSFont fontWithName:@"Geneva" size:10],NSFontAttributeName,nil]] autorelease]; 
	[s drawAtPoint:NSMakePoint(25,5)];
    }
    
    if([[self orcaObjects] count]){
        NSAffineTransform* transform = [NSAffineTransform transform];
        [transform translateXBy:5 yBy:13];
        [transform scaleXBy:.39 yBy:.44];
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
    [self linkToController:@"ORSNOCrateController"];
}

- (void) connected
{
	[[self orcaObjects] makeObjectsPerformSelector:@selector(connected)];
}

- (void) disconnected
{
	[[self orcaObjects] makeObjectsPerformSelector:@selector(disconnected)];
}

- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian
{
    return [aGuardian isKindOfClass:[self guardianClass]];	
}

- (Class) guardianClass 
{
	return NSClassFromString(@"ORSNORackModel");
}

- (void) setSlot:(int)aSlot
{
	slot = aSlot;
	NSEnumerator* e  = [[self orcaObjects] objectEnumerator];
    id anObject;
    while(anObject = [e nextObject]){
		[anObject guardian:self positionConnectorsForCard:anObject];
    }
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORSNOCrateSlotChanged
	 object:self];
}

- (int) slot
{
	return slot;
}

#pragma mark •••Accessors
- (uint32_t) memoryBaseAddress
{
	int index =  [self crateNumber];
	if(index>=0 && index<=kMaxSNOCrates) return kSnoCrateBaseAddress[index].Memory;
	else {
		[[NSException exceptionWithName:@"SNO Crate" reason:@"SNO Crate Index out of bounds" userInfo:nil] raise];
		return 0; //to get rid of compiler warning, can't really get here
	}
}

- (uint32_t) registerBaseAddress
{
	int index =  [self crateNumber];
	if(index>=0 && index<=kMaxSNOCrates) return kSnoCrateBaseAddress[index].Register;
	else {
		[[NSException exceptionWithName:@"SNO Crate" reason:@"SNO Crate Index out of bounds" userInfo:nil] raise];
		return 0; //to get rid of compiler warning, can't really get here
	}
}

- (NSString*) iPAddress
{
	int index =  [self crateNumber];
	if(index>=0 && index<=kMaxSNOCrates) return kSnoCrateBaseAddress[index].IPAddress;
	else {
		[[NSException exceptionWithName:@"SNO Crate" reason:@"SNO Crate Index out of bounds" userInfo:nil] raise];
		return 0; //to get rid of compiler warning, can't really get here
	}
}

- (uint32_t) portNumber
{
	int index =  [self crateNumber];
	if(index>=0 && index<=kMaxSNOCrates) return kSnoCrateBaseAddress[index].Port;
	else {
		[[NSException exceptionWithName:@"SNO Crate" reason:@"SNO Crate Index out of bounds" userInfo:nil] raise];
		return 0; //to get rid of compiler warning, can't really get here
	}
}

- (void) assumeDisplayOf:(ORConnector*)aConnector
{
    [guardian assumeDisplayOf:aConnector];
}

- (void) removeDisplayOf:(ORConnector*)aConnector
{
    [guardian removeDisplayOf:aConnector];
}


- (void) setGuardian:(id)aGuardian
{
    id oldGuardian = guardian;
    [super setGuardian:aGuardian];
    
    NSEnumerator* e  = [[self orcaObjects] objectEnumerator];
    id anObject;
    while(anObject = [e nextObject]){
        if(aGuardian == nil){
            [anObject guardianRemovingDisplayOfConnectors:oldGuardian ];
        }
        [anObject guardianAssumingDisplayOfConnectors:aGuardian];
        if(aGuardian != nil){
            [anObject guardian:self positionConnectorsForCard:anObject];
        }
    }
}

- (void) positionConnector:(ORConnector*)aConnector forCard:(id)aCard
{
	NSRect aFrame = [aConnector localFrame];
    float x =  7+[aCard slot] * 17 * .285 ;
    float y = 40 + [self slot] * [self frame].size.height +  ([self slot]*17);
	if([aConnector ioType] == kOutputConnector)y += 35;
    aFrame.origin = NSMakePoint(x,y);
    [aConnector setLocalFrame:aFrame];
}


#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
	[super registerNotificationObservers];
	
    [notifyCenter addObserver : self
                     selector : @selector(viewChanged:)
                         name : ORSNOCardSlotChanged
                       object : nil];
	
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"SNO Crate %d",[self crateNumber]];
}


#pragma mark •••HW Access

- (void) scanWorkingSlot
{
	pauseWork = NO;
	BOOL adapterOK = YES;
	@try {
		[[self adapter] selectCards:(uint32_t)(1L<<[self stationForSlot:workingSlot])];	
	}
	@catch(NSException* localException) {
		adapterOK = NO;
		NSLog(@"Unable to reach XL2/3 in crate: %d (Not inited?)\n",[self crateNumber]);
	}
	if(!adapterOK)working = NO;
	if(working){
		@try {
			
			ORFec32Model* proxyFec32 = [ObjectFactory makeObject:@"ORFec32Model"];
			[proxyFec32 setGuardian:self];
			
			NSString* boardID = [proxyFec32 performBoardIDRead:MC_BOARD_ID_INDEX];
			if(![boardID isEqual: @"0000"] && ![boardID isEqual: @"0000"]){
				NSLog(@"Crate %2d Fec %2d BoardID: %@\n",[self crateNumber],[self stationForSlot:workingSlot],boardID);
				ORFec32Model* theCard = [[OROrderedObjManager for:self] objectInSlot:workingSlot];
				if(!theCard){
					[self addObjects:[NSArray arrayWithObject:proxyFec32]];
					[self place:proxyFec32 intoSlot:workingSlot];
					theCard = proxyFec32;
				}
				pauseWork = YES;
				[theCard setBoardID:boardID];
				[theCard scan:@selector(scanWorkingSlot)];
				workingSlot--;
				//if (workingSlot == 0) working = NO;
			}
			else {
				NSLog(@"Crate %2d Fec %2d BoardID: %@\n",[self crateNumber],[self stationForSlot:workingSlot],boardID);
				ORFec32Model* theCard = [[OROrderedObjManager for:self] objectInSlot:workingSlot];
				if(theCard)[self removeObject:theCard];
			}
		}
		@catch(NSException* localException) {
			NSLog(@"Crate %2d Fec %2d BoardID: -----\n",[self crateNumber],[self stationForSlot:workingSlot]);
			ORFec32Model* theCard = [[OROrderedObjManager for:self] objectInSlot:workingSlot];
			if(theCard)[self removeObject:theCard];
		}
	}
	if(!pauseWork){
		workingSlot--;
		if(working && (workingSlot>0)){
			[self performSelector:@selector(scanWorkingSlot)withObject:nil afterDelay:0];
		}	
		else {
			[[self adapter] deselectCards];
		}
	}
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
	[[self undoManager] disableUndoRegistration];
    
    [self setSlot:[decoder decodeIntForKey:@"slot"]];
	[[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeInteger:[self slot] forKey:@"slot"];
}

- (short) numberSlotsUsed
{
	return 1;
}

- (void) resetCrate
{
    /* Reset the crate. This function resets the crate, loads the XL3 clocks
     * and dacs, tries to load the Xilinx for all the FEC slots, loads default
     * values for the FEC dacs, shift registers, and sequencer. */
    NSLog(@"Resetting crate %d\n", [self crateNumber]);
	[[self adapter] resetCrateAsync];
}

- (void) initCrateDone
{
	NSLog(@"Initialization of the crate %d done.\n", [self crateNumber]);
}

- (void) fetchECALSettings
{
    /* Fetch the latest ECAL settings and load them to the GUI. */
    [[self adapter] fetchECALSettings];
}

- (void) loadHardware
{
    /* Loads hardware settings from the GUI -> XL3. */
    [[self adapter] loadHardware];

    /* Put the XL3 in NORMAL mode and set the readout mask to all cards which
     * are present. */
    [[self undoManager] disableUndoRegistration];
    [[self adapter] setXl3Mode:NORMAL_MODE];
    [[self undoManager] enableUndoRegistration];
    [[self adapter] writeXl3Mode:NORMAL_MODE];
}

@end

@implementation ORSNOCrateModel (OROrderedObjHolding)
- (int) maxNumberOfObjects
{
    return kNumSNOCrateSlots;
}

- (int) objWidth
{
    return 12;
}

- (NSUInteger) stationForSlot:(int)aSlot
{
	return 16-aSlot;
}

- (NSRange) legalSlotsForObj:(id)anObj
{
	if( [anObj isKindOfClass:NSClassFromString(@"ORXL2Model")]){
		return NSMakeRange(17,1);
	}
	else if( [anObj isKindOfClass:NSClassFromString(@"ORXL3Model")]){
		return NSMakeRange(17,1);
	}	
	else {
		return  NSMakeRange(1,[self maxNumberOfObjects]-2);
	}
}

@end
