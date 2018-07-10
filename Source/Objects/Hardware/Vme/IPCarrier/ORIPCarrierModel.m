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
#import "ORIPCarrierModel.h"
#import "ORVmeIPCard.h"

#pragma mark ¥¥¥Definitions
#define kDefaultIPCarrierAddressModifier	0x29
#define kDefaultIPCarrierBaseAddress		0x00006000


@implementation ORIPCarrierModel

#pragma mark ¥¥¥Initialization
- (id) init //designated initializer
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setAddressModifier:kDefaultIPCarrierAddressModifier];
    [self setBaseAddress:kDefaultIPCarrierBaseAddress];
    
    [[self undoManager] enableUndoRegistration];
    
    
    return self;
    
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"IPCarrierCard"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORIPCarrierController"];
}

- (NSString*) helpURL
{
	return @"VME/IP_Carrier.html";
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0x0380);
}

- (void) positionConnector:(ORConnector*)aConnector forCard:(id)aCard
{
    float tweakX[4] = {1,-1,1,-1};
    NSRect aFrame = [aConnector localFrame];
    int ip = [aCard slotConv];
    float x =  15 + [self slot] * 16*.62 + (ip%2)*6 + tweakX[ip];
    float y;
    if(ip>=2)y=35;
    else y =  75;
    aFrame.origin = NSMakePoint(x,y);
    [aConnector setLocalFrame:aFrame];
}

- (void) probe
{
    NSLog(@"Probing IP Carrier %d,%d address:<0x%08x>\n",[self crateNumber],[self slot],[self baseAddress]);
	
    int addressOffset[4]={0x0080,0x0180,0x0280,0x0380};
	
	int conv[4] = {3,2,1,0};
	NSString* s[4]={
		@"IP A",
		@"IP B",
		@"IP C",
		@"IP D"
	};
    
	int aCard;
	for(aCard = 3;aCard>=0;aCard--){
		int i = conv[aCard];
		@try {
			unsigned char ipac[5];
			strncpy((char*)ipac,"\0",5);
			[[self adapter] readByteBlock:&ipac[0] atAddress:[self baseAddress]+addressOffset[i]+0x1
								numToRead:1 withAddMod:[self addressModifier] usingAddSpace:0x01];
			
			[[self adapter] readByteBlock:&ipac[1] atAddress:[self baseAddress]+addressOffset[i]+0x3
								numToRead:1 withAddMod:[self addressModifier] usingAddSpace:0x01];
			
			[[self adapter] readByteBlock:&ipac[2] atAddress:[self baseAddress]+addressOffset[i]+0x5
								numToRead:1 withAddMod:[self addressModifier] usingAddSpace:0x01];
			
			[[self adapter] readByteBlock:&ipac[3] atAddress:[self baseAddress]+addressOffset[i]+0x7
								numToRead:1 withAddMod:[self addressModifier] usingAddSpace:0x01];
			
			unsigned char manufacturerCode = 0;
			[[self adapter] readByteBlock:&manufacturerCode atAddress:[self baseAddress]+addressOffset[i]+0x9
								numToRead:1 withAddMod:[self addressModifier] usingAddSpace:0x01];
			
			unsigned char modelCode = 0;
			[[self adapter] readByteBlock:&modelCode atAddress:[self baseAddress]+addressOffset[i]+0x0b
								numToRead:1 withAddMod:[self addressModifier] usingAddSpace:0x01];
			
			if(!strcmp((const char*)ipac,"IPAC"))NSLog(@"%@ %s Manufacturer Code: 0x%x  Model Code: 0x%x\n",s[conv[aCard]],ipac,manufacturerCode,modelCode);
			else NSLog(@"%@ ID Prom appears to contain garbage.\n",s[conv[aCard]]);
			
		}
		@catch(NSException* localException) {
			NSLog(@"%@ raised exception during probe. Position probably empty.\n",s[conv[aCard]]);
		}
	}
}
@end

@implementation ORIPCarrierModel (OROrderedObjHolding)
- (int) maxNumberOfObjects { return 4;  }
- (int) objWidth		 { return 58; }
- (int) groupSeparation	 { return 50; }
@end

