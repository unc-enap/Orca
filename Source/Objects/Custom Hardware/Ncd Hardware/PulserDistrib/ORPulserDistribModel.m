//
//  ORPulserDistribModel.cp
//  Orca
//
//  Created by Mark Howe on Thurs Feb 20 2003.
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
#import "ORPulserDistribModel.h"

#import "ORIP408Model.h"
#import "ORHPPulserModel.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORVmeCrateModel.h"

#pragma mark ¥¥¥Connection Strings
static NSString* ORPulserDistrib408Connector 	= @"Pulser to 408 Connector";

#pragma mark ¥¥¥Notification Strings
NSString* ORPulserDistribNoisyEnvBroadcastEnabledChanged = @"ORPulserDistribNoisyEnvBroadcastEnabledChanged";
NSString* ORPulserDistribPatternChangedNotification = @"ORPulserDistribPatternChangedNotification";
NSString* ORPulserDistribPatternBitChangedNotification = @"ORPulserDistribPatternBitChangedNotification";
NSString* ORPulserDisableForPulserChangedNotification = @"ORPulserDisableForPulserChangedNotification";

@implementation ORPulserDistribModel

#pragma mark ¥¥¥Initialization
-(id)init //designated initializer
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setPatternArray:[NSMutableArray arrayWithObjects:
						   [NSNumber numberWithLong:0],
						   [NSNumber numberWithLong:0],
						   [NSNumber numberWithLong:0],
						   [NSNumber numberWithLong:0],
						   nil]];
    [self setNoisyEnvBroadcastEnabled:NO];
    [[self undoManager] enableUndoRegistration];
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [packedArray release];
    [patternArray release];
    [super dealloc];
}

-(void)registerNotificationObservers
{
    
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [notifyCenter addObserver : self
                     selector : @selector(runStatusChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
	
    [notifyCenter addObserver : self
                     selector : @selector(pulserStartingToLoad:)
                         name : ORHPPulserWaveformLoadStartedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(pulserDoneLoading:)
                         name : ORHPPulserWaveformLoadFinishedNotification
                       object : nil];
    
}

- (void) runStatusChanged:(NSNotification*)aNote
{
    if([[ORGlobal sharedGlobal] runRunning]){
        [self shipPDSRecord:patternArray];
    }
}

-(void)pulserStartingToLoad:(NSNotification*)aNote
{
    if(disableForPulser){
        NSLog(@"Disabling the PDS while the Pulser is downloading.\n");
        NSArray* zeroArray = [NSMutableArray arrayWithObjects:
							  [NSNumber numberWithLong:0],
							  [NSNumber numberWithLong:0],
							  [NSNumber numberWithLong:0],
							  [NSNumber numberWithLong:0],
							  nil];
        
        [self loadHardware:zeroArray];
    }
}

-(void)pulserDoneLoading:(NSNotification*)aNote
{
    if(disableForPulser){
        NSLog(@"Reloading the PDS.\n");
        [self loadHardware:patternArray];
    }
}


-(void)setUpImage
{
    [self setImage:[NSImage imageNamed:@"ORPulserDistrib"]];
}

-(void)makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(5, [self frame].size.height - 15-kConnectorSize+.5) withGuardian:self withObjectLink:self];
    [aConnector setConnectorImageType:kVerticalRect];
    [[self connectors] setObject:aConnector forKey:ORPulserDistrib408Connector];
    
	[ aConnector setConnectorType: 'IP1 ' ];
	[ aConnector addRestrictedConnectionType: 'IP2 ' ]; //can only connect to IP inputs
    
    [aConnector release];
}

-(void)makeMainController
{
    [self linkToController:@"ORPulserDistribController"];
}

- (NSString*) helpURL
{
	return @"NCD/PDS.html";
}

#pragma mark ¥¥¥Accessors

- (BOOL) noisyEnvBroadcastEnabled
{
    return noisyEnvBroadcastEnabled;
}

- (void) setNoisyEnvBroadcastEnabled:(BOOL)aNoisyEnvBroadcastEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNoisyEnvBroadcastEnabled:noisyEnvBroadcastEnabled];
    
    noisyEnvBroadcastEnabled = aNoisyEnvBroadcastEnabled;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPulserDistribNoisyEnvBroadcastEnabledChanged object:self];
}

- (uint32_t) dataId { return dataId; }
- (void) setDataId: (uint32_t) DataId
{
    dataId = DataId;
}

- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherPDS
{
    [self setDataId:[anotherPDS dataId]];
}

-(NSMutableArray*)patternArray
{
    return patternArray;
}

-(void)setPatternArray:(NSMutableArray*)newPatternArray
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPatternArray:patternArray];
    
    [patternArray autorelease];
    patternArray=[newPatternArray retain];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORPulserDistribPatternChangedNotification
	 object:self];
}

-(uint32_t)patternMaskForArray:(int)arrayIndex
{
    return (uint32_t)[[patternArray objectAtIndex:arrayIndex] longValue];
}

-(void)setPatternMaskForArray:(int)arrayIndex to:(uint32_t)aValue
{
    int32_t currentValue = [self patternMaskForArray:arrayIndex];
    [[[self undoManager] prepareWithInvocationTarget:self] setPatternMaskForArray:arrayIndex to:currentValue];
    
    [patternArray replaceObjectAtIndex:arrayIndex withObject:[NSNumber numberWithLong:aValue]];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORPulserDistribPatternBitChangedNotification
	 object:self];
}


// ----------------------------------------------------------
// - disableForPulser:
// ----------------------------------------------------------

-(BOOL)disableForPulser
{
    return disableForPulser;
}

// ----------------------------------------------------------
// - setDisableForPulser:
// ----------------------------------------------------------

-(void)setDisableForPulser:(BOOL)flag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDisableForPulser:disableForPulser];
    disableForPulser = flag;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORPulserDisableForPulserChangedNotification
	 object:self];
}


#pragma mark ¥¥¥Archival
static NSString *ORPulserDistribPatternArray= @"ORPulserDistribPatternArray";
static NSString *ORPulserDisableForPulser    = @"ORPulserDisableForPulser";

-(id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [self loadMemento:decoder];
    [self setNoisyEnvBroadcastEnabled:[decoder decodeBoolForKey:@"ORPulserDistribModelNoisyEnvBroadcastEnabled"]];
    
    [self registerNotificationObservers];
    
    return self;
}

-(void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [self saveMemento:encoder];
    [encoder encodeBool:noisyEnvBroadcastEnabled forKey:@"ORPulserDistribModelNoisyEnvBroadcastEnabled"];
}

-(void)loadMemento:(NSCoder*)aDecoder
{
    [[self undoManager] disableUndoRegistration];
    [self setPatternArray:[aDecoder decodeObjectForKey:ORPulserDistribPatternArray]];
    [self setDisableForPulser:[aDecoder decodeBoolForKey:ORPulserDisableForPulser]];
    [[self undoManager] enableUndoRegistration];
}

-(void)saveMemento:(NSCoder*)anEncoder
{
    [anEncoder encodeObject:[self patternArray] forKey:ORPulserDistribPatternArray];
    [anEncoder encodeBool:[self disableForPulser] forKey:ORPulserDisableForPulser];
}

-(NSData*)memento
{
    NSMutableData* memento = [NSMutableData data];
    NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:memento];
    [self saveMemento:archiver];
    [archiver finishEncoding];
	[archiver release];
    return memento;
}

-(void)restoreFromMemento:(NSData*)aMemento
{
	if(aMemento){
		NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:aMemento];
		[self loadMemento:unarchiver];
		[unarchiver finishDecoding];
		[unarchiver release];
		[self loadHardware:patternArray];
	}
}

#pragma mark ¥¥¥Data Record
- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORPulserDistribDecoderForPDS",      @"decoder",
								 [NSNumber numberWithLong:dataId],     @"dataId",
								 [NSNumber numberWithBool:NO],         @"variable",
								 [NSNumber numberWithLong:4],          @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"PDSRecord"];
    return dataDictionary;
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORPulserDistribModel"];
    
    
}
#pragma mark ¥¥¥Hardware Access
//-------------------------------------------------------------------------------
//load the data to hardware...format....
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//                                       ^----completion bit
//                               ^^^^ ^^^-----potential Instruction complete channels
//                   ^------------------------strobe
//                  ^-------------------------clear
//             ^^ ^^--------------------------address
//   ^^ ^^^^ ^^-------------------------------data
//-------------------------------------------------------------------------------
-(void)loadHardware:(NSArray*)aPatternArray
{
	@try {    
        if(noisyEnvBroadcastEnabled){
			[[NSNotificationCenter defaultCenter] postNotificationName:ORHardwareEnvironmentNoisy object:self];
		}
		uint32_t kDataMask     = 0x3ffc0000;
		uint32_t kStrobeMask	= 0x00010000;
		
		ORIP408Model* the408 = [self objectConnectedTo:ORPulserDistrib408Connector];
		
		if(the408){
			NSEnumerator* e = [aPatternArray objectEnumerator];
			NSNumber* maskPattern;
			short i=0;
			if(!packedArray)packedArray = [[NSMutableArray arrayWithCapacity:16]retain];
			while(maskPattern = [e nextObject]){
				uint32_t value = (uint32_t)[maskPattern longValue];
				[packedArray addObject:[NSNumber numberWithUnsignedChar:value&0x00ff]];
				[packedArray addObject:[NSNumber numberWithUnsignedChar:(value&0xff00)>>8]];
			}
			
			e = [packedArray objectEnumerator];
			NSNumber* bitPattern;
			i=0;
			while(bitPattern = [e nextObject]){
				uint32_t dataWord = 0;
				dataWord |= i<<18;						//load the address
				dataWord |=(([bitPattern longValue]<<22)& kDataMask);     //pack in the data
				
				[the408 setOutputWithMask:kDataMask value:dataWord];	//load the data
				[the408 setOutputWithMask:kStrobeMask value:0x00010000];	//load the strobe
				
				if(![self waitForCompletion]){
                    NSLogError(@" ",@"Pulser",@"Time out loading PDS",nil);
                }
				
				[the408 setOutputWithMask:kStrobeMask value:0x0L];			//clear the strobe
				++i;
			}
			[packedArray release];
			packedArray = nil;
            
            [self shipPDSRecord:aPatternArray];
            
		}
		else {
			[NSException raise:@"PDS Not Connected to IP408" format:@"Connection IP408 is required."];
		}
	}
	@catch(NSException* localException) {
		if(noisyEnvBroadcastEnabled){
			[[NSNotificationCenter defaultCenter] postNotificationName:ORHardwareEnvironmentQuiet object:self];
		}
		NSLogError(@" ",@"Pulser",@"Loading PDS",nil);
		[localException raise];
	}
	
	if(noisyEnvBroadcastEnabled){
		[[NSNotificationCenter defaultCenter] postNotificationName:ORHardwareEnvironmentQuiet object:self];
	}
}

-(BOOL)waitForCompletion
{
    uint32_t theResult 		= 0L;
    
    ORIP408Model* the408 = [self objectConnectedTo:ORPulserDistrib408Connector];
    
    NSTimeInterval t0 = [NSDate timeIntervalSinceReferenceDate];
    while(true){
        theResult = [the408 getInputWithMask:0x00000001];
        if(theResult & 0x00000001){
            return YES;
        }
        else {
            if([NSDate timeIntervalSinceReferenceDate]-t0 > .001){
                return NO;
            }
        }
    }
    return YES;
}

//---PDS data record format-----------------------------------
//word 1: dataId and length as usual
//word 2: 32 bit word holding gtid
//word 3: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//        ^^^^ ^^^^ ^^^^ ^^^^---------------------bit pattern for Board 1
//                            ^^^^ ^^^^ ^^^^ ^^^^-bit pattern for Board 0
//word 4: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//        ^^^^ ^^^^ ^^^^ ^^^^---------------------bit pattern for Board 3
//                            ^^^^ ^^^^ ^^^^ ^^^^-bit pattern for Board 2
//------------------------------------------------------------

- (void) shipPDSRecord:(NSArray*)aPatternArray
{
    if([[ORGlobal sharedGlobal] runInProgress]){
        uint32_t dataWord[4]; 
        dataWord[0] = dataId | 4; //lengh is 4 int32_t words
        ORIP408Model* the408 = [self objectConnectedTo:ORPulserDistrib408Connector];
        uint32_t gtid = [[[the408 guardian] crate] requestGTID];
        dataWord[1] = gtid;    
        dataWord[2] = (uint32_t)([[aPatternArray objectAtIndex:1] longValue] & 0x0000ffff)<<16 | ([[aPatternArray objectAtIndex:0] longValue] & 0x0000ffff);
        dataWord[3] = (uint32_t)([[aPatternArray objectAtIndex:3] longValue] & 0x0000ffff)<<16 | ([[aPatternArray objectAtIndex:2] longValue] & 0x0000ffff);
		
        //now that we know the size we fill in the header and ship
        [[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
                                                            object:[NSData dataWithBytes:dataWord length:4*sizeof(int32_t)]];
    }
}

@end


@implementation ORPulserDistribDecoderForPDS
-(uint32_t)decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    return 4; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    NSString* title= @"PDS Record\n\n";
    
    NSString* gtid  = [NSString stringWithFormat:@"GTID   = %u\n",ptr[1]];
    NSString* word1 = [NSString stringWithFormat:@"Board0 = 0x%02x\n",ptr[2] & 0x0000ffff];
    NSString* word2 = [NSString stringWithFormat:@"Board1 = 0x%02x\n",(ptr[2] & 0xffff0000)>>16];
    NSString* word3 = [NSString stringWithFormat:@"Board2 = 0x%02x\n",ptr[3] & 0x0000ffff];
    NSString* word4 = [NSString stringWithFormat:@"Board3 = 0x%02x\n",(ptr[3] & 0xffff0000)>>16];
	
    return [NSString stringWithFormat:@"%@%@%@%@%@%@",title,gtid,word1,word2,word3,word4];               
}

@end
