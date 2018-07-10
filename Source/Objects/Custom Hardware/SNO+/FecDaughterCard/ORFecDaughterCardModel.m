//
//  ORFecDaughterCardModel.cp
//  Orca
//
//  Created by Mark Howe on Wed Oct 15,2008.
//  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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
#import "ORFecDaughterCardModel.h"
#import "ORFec32Model.h"
#import "ORSNOConstants.h"
#import "ORXL3Model.h"


NSString* ORDCModelEverythingChanged        = @"ORDCModelEverythingChanged";
NSString* ORDCModelCommentsChanged			= @"ORDCModelCommentsChanged";
NSString* ORDCModelShowVoltsChanged			= @"ORDCModelShowVoltsChanged";
NSString* ORDCModelSetAllCmosChanged		= @"ORDCModelSetAllCmosChanged";
NSString* ORDCModelCmosRegShownChanged		= @"ORDCModelCmosRegShownChanged";
NSString* ORDCModelRp1Changed				= @"ORDCModelRp1Changed";
NSString* ORDCModelRp2Changed				= @"ORDCModelRp2Changed";
NSString* ORDCModelVliChanged				= @"ORDCModelVliChanged";
NSString* ORDCModelVsiChanged				= @"ORDCModelVsiChanged";
NSString* ORDCModelVtChanged				= @"ORDCModelVtChanged";
NSString* ORDCModelVbChanged				= @"ORDCModelVbChanged";
NSString* ORDCModelNs100widthChanged		= @"ORDCModelNs100widthChanged";
NSString* ORDCModelNs20widthChanged			= @"ORDCModelNs20widthChanged";
NSString* ORDCModelNs20delayChanged			= @"ORDCModelNs20delayChanged";
NSString* ORDCModelTac0trimChanged			= @"ORDCModelTac0trimChanged";
NSString* ORDCModelTac1trimChanged			= @"ORDCModelTac1trimChanged";
NSString* ORDBLock = @"ORDBLock";

@implementation ORFecDaughterCardModel

#pragma mark •••Initialization
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
	[self loadDefaultValues];
	[self setComments:@""];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (uint32_t) boardIDAsInt
{
    return strtoul([[self boardID] UTF8String], NULL, 16);
}

-(void)dealloc
{
    [comments release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"FecDaughterCard"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORFecDaughterCardController"];
}

- (Class) guardianClass 
{
	return NSClassFromString(@"ORFec32Model");
}
- (NSString*) identifier
{
    return [NSString stringWithFormat:@"DC (%d,%d,%d)",[[guardian guardian ] crateNumber],[guardian stationNumber],[self stationNumber]];
}
#pragma mark •••Accessors
- (int) globalCardNumber
{
	//return ([[guardian guardian ] crateNumber] * 16) + ([guardian stationNumber] * 4) + [self slot];
	return ([[[[self guardian] guardian] adapter] crateNumber] *16*4) + ([[self guardian] stationNumber] * 4) + [self slot];
}

- (NSComparisonResult) globalCardNumberCompare:(id)aCard
{
	return [self globalCardNumber] - [aCard globalCardNumber];
}

- (NSString*) comments
{
    return comments;
}

- (void) setComments:(NSString*)aComments
{
	if(!aComments) aComments = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setComments:comments];
    
    [comments autorelease];
    comments = [aComments copy];    
	
    [self postNotificationName:ORDCModelCommentsChanged];
}

- (void) setSlot:(int)aSlot
{
	[super setSlot:aSlot];
	[[self guardian] objectCountChanged];
}

- (BOOL) showVolts
{
    return showVolts;
}

- (void) setShowVolts:(BOOL)aShowVolts
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShowVolts:showVolts];
    showVolts = aShowVolts;
    [self postNotificationName:ORDCModelShowVoltsChanged];
}

- (BOOL) setAllCmos
{
    return setAllCmos;
}

- (void) setSetAllCmos:(BOOL)aSetAllCmos
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSetAllCmos:setAllCmos];
    setAllCmos = aSetAllCmos;
    [self postNotificationName:ORDCModelSetAllCmosChanged];
}

- (short) cmosRegShown
{
    return cmosRegShown;
}

- (void) setCmosRegShown:(short)aCmosRegShown
{
	if(aCmosRegShown<0)aCmosRegShown = 7;
	if(aCmosRegShown>7)aCmosRegShown = 0;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setCmosRegShown:cmosRegShown];
    cmosRegShown = aCmosRegShown;
    [self postNotificationName:ORDCModelCmosRegShownChanged];
}

- (unsigned char) rp1:(short)anIndex
{
	return rp1[anIndex];
}

- (void) setRp1:(short)anIndex withValue:(unsigned char)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRp1:anIndex withValue:rp1[anIndex]];
    rp1[anIndex] = aValue;
    [self postNotificationName:ORDCModelRp1Changed];
}

- (unsigned char) rp2:(short)anIndex
{
	return rp2[anIndex];
}

- (void) setRp2:(short)anIndex withValue:(unsigned char)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRp2:anIndex withValue:rp2[anIndex]];
    rp2[anIndex] = aValue;
    [self postNotificationName:ORDCModelRp2Changed];
}

- (unsigned char) vli:(short)anIndex
{
	return vli[anIndex];
}

- (void) setVli:(short)anIndex withValue:(unsigned char)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVli:anIndex withValue:vli[anIndex]];
    vli[anIndex] = aValue;
    [self postNotificationName:ORDCModelVliChanged];
}

- (unsigned char) vsi:(short)anIndex
{
	return vsi[anIndex];
}

- (void) setVsi:(short)anIndex withValue:(unsigned char)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVsi:anIndex withValue:vsi[anIndex]];
    vsi[anIndex] = aValue;
    [self postNotificationName:ORDCModelVsiChanged];
}

- (unsigned char) vt:(short)anIndex
{
	return vt[anIndex];
}

- (void) setVt:(short)anIndex withValue:(unsigned char)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVt:anIndex withValue:vt[anIndex]];
    vt[anIndex] = aValue;
    [self postNotificationName:ORDCModelVtChanged];
}

- (unsigned char) vt_ecal:(short)anIndex
{
    return _vt_ecal[anIndex];
}

- (void) setVt_ecal:(short)anIndex withValue:(unsigned char)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVt_ecal:anIndex withValue:[self vt_ecal:anIndex]];
    _vt_ecal[anIndex] = aValue;
    [self silentUpdateVt:anIndex];
    [self postNotificationName:ORDCModelVtChanged];
}

- (unsigned char) vt_zero:(short)anIndex
{
    return _vt_zero[anIndex];
}

- (void) setVt_zero:(short)anIndex withValue:(unsigned char)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVt_zero:anIndex withValue:[self vt_zero:anIndex]];
    _vt_zero[anIndex] = aValue;
    [self silentUpdateVt:anIndex];
    [self postNotificationName:ORDCModelVtChanged];
}

- (short) vt_corr:(short)anIndex
{
    return _vt_corr[anIndex];
}

- (void) setVt_corr:(short)anIndex withValue:(short)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVt_corr:anIndex withValue:[self vt_corr:anIndex]];
    _vt_corr[anIndex] = aValue;
    [self silentUpdateVt:anIndex];
    [self postNotificationName:ORDCModelVtChanged];
}

- (unsigned char) vt_safety
{
    return _vt_safety;
}

- (void) setVt_safety:(unsigned char)vt_safety
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVt_safety:vt_safety];
    _vt_safety = vt_safety;
    unsigned short ch;
    for (ch=0; ch<8; ch++) {
        [self silentUpdateVt:ch];
    }
    [self postNotificationName:ORDCModelVtChanged];
}

- (unsigned char) vb:(short)anIndex
{
	return vb[anIndex];
}

- (unsigned char) vb:(short)ch egain:(short)gain
{
	return vb[ch + (gain?8:0)];
}

- (void) setVb:(short)anIndex withValue:(unsigned char)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVb:anIndex withValue:vb[anIndex]];
    vb[anIndex] = aValue;
    [self postNotificationName:ORDCModelVbChanged];
}

- (unsigned char) ns100width:(short)anIndex
{
	return ns100width[anIndex];
}

- (void) setNs100width:(short)anIndex withValue:(unsigned char)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNs100width:anIndex withValue:ns100width[anIndex]];
    ns100width[anIndex] = aValue;
    [self postNotificationName:ORDCModelNs100widthChanged];
}

- (unsigned char) ns20width:(short)anIndex
{
	return ns20width[anIndex];
}

- (void) setNs20width:(short)anIndex withValue:(unsigned char)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNs20width:anIndex withValue:ns20width[anIndex]];
    ns20width[anIndex] = aValue;
    [self postNotificationName:ORDCModelNs20widthChanged];
}

- (unsigned char) ns20delay:(short)anIndex
{
	return ns20delay[anIndex];
}
- (void) setNs20delay:(short)anIndex withValue:(unsigned char)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNs20delay:anIndex withValue:ns20delay[anIndex]];
    ns20delay[anIndex] = aValue;
    [self postNotificationName:ORDCModelNs20delayChanged];
}

- (unsigned char) tac0trim:(short)anIndex
{
	return tac0trim[anIndex];
}

- (void) setTac0trim:(short)anIndex withValue:(unsigned char)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTac0trim:anIndex withValue:tac0trim[anIndex]];
    tac0trim[anIndex] = aValue;
    [self postNotificationName:ORDCModelTac0trimChanged];
}

- (unsigned char) tac1trim:(short)anIndex
{
	return tac1trim[anIndex];
}
- (void) setTac1trim:(short)anIndex withValue:(unsigned char)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTac1trim:anIndex withValue:tac1trim[anIndex]];
    tac1trim[anIndex] = aValue;
    [self postNotificationName:ORDCModelTac1trimChanged];
}

#pragma mark ====Converter Methods
- (void) setRp1Voltage:(short)n withValue:(float)value
{
	[self setRp1:n withValue:255.0*(value-kRp1Min)/(kRp1Max-kRp1Min)+0.5];
}

- (float) rp1Voltage:(short) n
{
	return ((kRp1Max-kRp1Min)/255.0)*rp1[n]+kRp1Min;
}

- (void) setRp2Voltage:(short)n withValue:(float)value
{
	[self setRp2:n withValue:255.0*(value-kRp2Min)/(kRp2Max-kRp2Min)+0.5];
}

- (float) rp2Voltage:(short) n
{
	return ((kRp2Max-kRp2Min)/255.0)*rp2[n]+kRp2Min;
}

- (void) setVliVoltage:(short)n withValue:(float)value
{
	[self setVli:n withValue:255.0*(value-kVliMin)/(kVliMax-kVliMin)+0.5];
}

- (float) vliVoltage:(short) n
{
	return ((kVliMax-kVliMin)/255.0)*vli[n]+kVliMin;
}

- (void) setVsiVoltage:(short)n withValue:(float)value
{
	[self setVsi:n withValue:255.0*(value-kVsiMin)/(kVsiMax-kVsiMin)+0.5];
}

- (float) vsiVoltage:(short) n
{
	return ((kVsiMax-kVsiMin)/255.0)*vsi[n]+kVsiMin;
}

- (void) setVtVoltage:(short)n withValue:(float)value
{
	[self setVt:n withValue:255.0*(value-kVtMin)/(kVtMax-kVtMin)+0.5];
}

- (float) vtVoltage:(short) n
{
	return ((kVtMax-kVtMin)/255.0)*vt[n]+kVtMin;
}

- (void) setVbVoltage:(short)n withValue:(float)value
{
	[self setVb:n withValue:255.0*(value-kVbMin)/(kVbMax-kVbMin)+0.5];
}

- (float) vbVoltage:(short) n
{
	return ((kVbMax-kVbMin)/255.0)*vb[n]+kVbMin;
}


- (void) loadDefaultValues
{
	int i;
	for(i=0;i<2;i++){
		[self setRp1:i withValue:115];
		[self setRp2:i withValue:135];
		[self setVli:i withValue:120];
		[self setVsi:i withValue:120];
	}
    [self setVt_safety:2];
	for(i=0;i<8;i++){
		[self setVt_ecal:i withValue:255];
		[self setVt_zero:i withValue:0];
		[self setVt_corr:i withValue:0];
        [self setVt:i withValue:255];
	}
	for(i=0;i<16;i++){
		[self setVb:i withValue:160]; 
	}
	for(i=0;i<8;i++){
		[self setNs100width:i withValue:126]; 
		[self setNs20width:i withValue:32]; 
		[self setNs20delay:i withValue:2]; 
		[self setTac0trim:i withValue:0]; 
		[self setTac1trim:i withValue:0]; 
	}
}

//This information basically follows the loadDefaultValues information above but loads into a mutable dictionary array
- (NSMutableDictionary*) pullFecDaughterInformationForOrcaDB
{
    //Initialise the main array
    NSMutableDictionary* daughterBoardDBInfo = [NSMutableDictionary dictionaryWithCapacity:20];
    
    
    //Initialise the smaller array
    NSMutableDictionary* rp1Array = [NSMutableDictionary dictionaryWithCapacity:20];
    NSMutableDictionary* rp2Array = [NSMutableDictionary dictionaryWithCapacity:20];
    NSMutableDictionary* vliArray = [NSMutableDictionary dictionaryWithCapacity:20];
    NSMutableDictionary* vsiArray = [NSMutableDictionary dictionaryWithCapacity:20];
    NSMutableDictionary* vt_ecalArray = [NSMutableDictionary dictionaryWithCapacity:20];
    NSMutableDictionary* vt_zeroArray = [NSMutableDictionary dictionaryWithCapacity:20];
    NSMutableDictionary* vt_corrArray = [NSMutableDictionary dictionaryWithCapacity:20];
    NSMutableDictionary* vtArray = [NSMutableDictionary dictionaryWithCapacity:20];
    NSMutableDictionary* vbArray = [NSMutableDictionary dictionaryWithCapacity:20];
    NSMutableDictionary* ns100widthArray = [NSMutableDictionary dictionaryWithCapacity:20];
    NSMutableDictionary* ns20widthArray = [NSMutableDictionary dictionaryWithCapacity:20];
    NSMutableDictionary* ns20delayArray = [NSMutableDictionary dictionaryWithCapacity:20];
    NSMutableDictionary* tac0trimArray = [NSMutableDictionary dictionaryWithCapacity:20];
    NSMutableDictionary* tac1trimArray = [NSMutableDictionary dictionaryWithCapacity:20];
    //NSMutableDictionary* fecBoardIds = [NSMutableDictionary dictionaryWithCapacity:20];
    
	int i;
	for(i=0;i<2;i++){
		[rp1Array setObject:[NSNumber numberWithFloat:[self rp1:i]] forKey:[NSString stringWithFormat:@"%i",i]];
        [rp2Array setObject:[NSNumber numberWithFloat:[self rp2:i]] forKey:[NSString stringWithFormat:@"%i",i]];
        [vliArray setObject:[NSNumber numberWithFloat:[self vli:i]] forKey:[NSString stringWithFormat:@"%i",i]];
        [vsiArray setObject:[NSNumber numberWithFloat:[self vsi:i]] forKey:[NSString stringWithFormat:@"%i",i]];
	}
    
    //Add these objects back in later
    /*[daughterBoardDBInfo setObject:rp1Array forKey:@"rp1"];
    [daughterBoardDBInfo setObject:rp2Array forKey:@"rp2"];
    [daughterBoardDBInfo setObject:vliArray forKey:@"vli"];
    [daughterBoardDBInfo setObject:vsiArray forKey:@"vsi"];*/

    [daughterBoardDBInfo setObject:[NSNumber numberWithFloat:[self vt_safety]] forKey:@"vt_safety"];
    
	for(i=0;i<8;i++){
        [vt_ecalArray setObject:[NSNumber numberWithFloat:[self vt_ecal:i]] forKey:[NSString stringWithFormat:@"%i",i]];
        [vt_zeroArray setObject:[NSNumber numberWithFloat:[self vt_zero:i]] forKey:[NSString stringWithFormat:@"%i",i]];
        [vt_corrArray setObject:[NSNumber numberWithFloat:[self vt_corr:i]] forKey:[NSString stringWithFormat:@"%i",i]];
        [vtArray setObject:[NSNumber numberWithFloat:[self vt:i]] forKey:[NSString stringWithFormat:@"%i",i]];
	}
    
    //get the board ids
    //for(i=0;i<4;i++){
        //[fecBoardIds setObject:[self performBoardIDRead:[self slot]] forKey:[NSString stringWithFormat:@"%i",i]];
    //}
    
    //Get the daughter board ID
    [daughterBoardDBInfo setObject:[self boardID] forKey:@"daughter_board_id"];
    
    //TODO:Add these objects back in later
    //[daughterBoardDBInfo setObject:vt_ecalArray forKey:@"vt_ecal"];
    [daughterBoardDBInfo setObject:vt_zeroArray forKey:@"vt_zero"];
    //[daughterBoardDBInfo setObject:vt_corrArray forKey:@"vt_corr"];
    [daughterBoardDBInfo setObject:vtArray forKey:@"vt"];
    //[daughterBoardDBInfo setObject:fecBoardIds forKey:@"fec_board_ids"];
    
	for(i=0;i<16;i++){
        [vbArray setObject:[NSNumber numberWithFloat:[self vb:i]] forKey:[NSString stringWithFormat:@"%i",i]];
	}
	for(i=0;i<8;i++){
        
        [ns100widthArray setObject:[NSNumber numberWithFloat:[self ns100width:i]] forKey:[NSString stringWithFormat:@"%i",i]];
        [ns20widthArray setObject:[NSNumber numberWithFloat:[self ns20width:i]] forKey:[NSString stringWithFormat:@"%i",i]];
        [ns20delayArray setObject:[NSNumber numberWithFloat:[self ns20delay:i]] forKey:[NSString stringWithFormat:@"%i",i]];
        [tac0trimArray setObject:[NSNumber numberWithFloat:[self tac0trim:i]] forKey:[NSString stringWithFormat:@"%i",i]];
        [tac1trimArray setObject:[NSNumber numberWithFloat:[self tac1trim:i]] forKey:[NSString stringWithFormat:@"%i",i]];
	}
    
    //Add these objects back in later
    /*[daughterBoardDBInfo setObject:ns100widthArray forKey:@"ns100width"];
    [daughterBoardDBInfo setObject:ns20widthArray forKey:@"ns20width"];
    [daughterBoardDBInfo setObject:ns20delayArray forKey:@"ns20delay"];
    [daughterBoardDBInfo setObject:tac0trimArray forKey:@"tac0delay"];
    [daughterBoardDBInfo setObject:tac1trimArray forKey:@"tac1delay"];*/

    
    return daughterBoardDBInfo;
}

- (void) silentUpdateVt:(short)anIndex
{
    //rethink what really makes sense to set, the following doesn't
    //we don't touch ecal, zero, and safety
    //we tune corr and vt to make sense
    
    short vt_val;
    //new vt value
    vt_val = [self vt_ecal:anIndex] + [self vt_corr:anIndex];
    if (vt_val < 0) {
        vt_val = 0;
    }
    if (vt_val > 255) {
        vt_val = 255;
    }
    //check we are safe
    if (vt_val < [self vt_zero:anIndex] + [self vt_safety]) {
        //do NOT set the corr to avoid dead-lock
        //do not touch ecal values, increment the correction
        vt_val = [self vt_zero:anIndex] + [self vt_safety];
        if (vt_val < 0) {
            vt_val = 0;
        }
        if (vt_val > 255) {
            vt_val = 255;
        }
        _vt_corr[anIndex] = vt_val - [self vt_ecal:anIndex];
    }
    vt[anIndex] = (unsigned char) vt_val;
}

#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setComments:		[decoder decodeObjectForKey:@"comments"]];
    [self setShowVolts:		[decoder decodeBoolForKey:@"showVolts"]];
	[self setSetAllCmos:	[decoder decodeBoolForKey:@"setAllCmos"]];
	[self setCmosRegShown:	[decoder decodeIntForKey:@"cmosRegShown"]];
	int i;
	for(i=0;i<2;i++){
		[self setRp1:i withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"rp1_%d",i]]];
		[self setRp2:i withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"rp2_%d",i]]];
		[self setVli:i withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"vli_%d",i]]];
		[self setVsi:i withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"vsi_%d",i]]];
	}
	[self setVt_safety: [decoder decodeIntForKey:@"vt_safety"]];    
 	for(i=0;i<8;i++){
        //the order is important see silentUpdateVt
		[self setVt_ecal:i withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"vt_ecal_%d",i]]];
		[self setVt_zero:i withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"vt_zero_%d",i]]];
		[self setVt_corr:i withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"vt_corr_%d",i]]];
        [self silentUpdateVt:i];
        
		[self setNs100width:i withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"select100nsTrigger_%d",i]]];
		[self setNs100width:i withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"ns100width_%d",i]]];
		[self setNs20width:i withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"ns20width_%d",i]]];
		[self setNs20delay:i withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"ns20delay_%d",i]]];
		[self setTac0trim:i withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"tac0trim_%d",i]]];
		[self setTac1trim:i withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"tac1trim_%d",i]]];
	}
 	for(i=0;i<16;i++){
		[self setVb:i withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"vb_%d",i]]];
	}
	[[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeObject:comments	forKey:@"comments"];
	[encoder encodeBool:showVolts	forKey:@"showVolts"];
	[encoder encodeBool:setAllCmos	forKey:@"setAllCmos"];
	[encoder encodeInt:cmosRegShown forKey:@"cmosRegShown"];
    [encoder encodeInt:[self vt_safety] forKey:@"vt_safety"];
	int i;
	for(i=0;i<2;i++){
		[encoder encodeInt:rp1[i] forKey:[NSString stringWithFormat:@"rp1_%d",i]];
		[encoder encodeInt:rp2[i] forKey:[NSString stringWithFormat:@"rp2_%d",i]];
		[encoder encodeInt:vli[i] forKey:[NSString stringWithFormat:@"vli_%d",i]];
		[encoder encodeInt:vsi[i] forKey:[NSString stringWithFormat:@"vsi_%d",i]];
	}
 	for(i=0;i<8;i++){
		[encoder encodeInt:[self vt_ecal:i] forKey:[NSString stringWithFormat:@"vt_ecal_%d",i]];
		[encoder encodeInt:[self vt_zero:i] forKey:[NSString stringWithFormat:@"vt_zero_%d",i]];
		[encoder encodeInt:[self vt_corr:i] forKey:[NSString stringWithFormat:@"vt_corr_%d",i]];
		[encoder encodeInt:ns100width[i] forKey:[NSString stringWithFormat:@"ns100width_%d",i]];
		[encoder encodeInt:ns20width[i] forKey:[NSString stringWithFormat:@"ns20width_%d",i]];
		[encoder encodeInt:ns20delay[i] forKey:[NSString stringWithFormat:@"ns20delay_%d",i]];
		[encoder encodeInt:tac0trim[i] forKey:[NSString stringWithFormat:@"tac0trim_%d",i]];
		[encoder encodeInt:tac1trim[i] forKey:[NSString stringWithFormat:@"tac1trim_%d",i]];
	}
 	for(i=0;i<16;i++){
		[encoder encodeInt:vb[i] forKey:[NSString stringWithFormat:@"vb_%d",i]];
	}
}

- (void) readBoardIds
{
	@try {
		[self setBoardID:[self performBoardIDRead:[self slot]]];
	}
	@catch(NSException* localException) {
		//[self setBoardID:@"0000"];	
	}
}

- (NSString*) performBoardIDRead:(short) boardIndex
{
	NSString* result = @"---";
	@try {
		result = [[self guardian] performBoardIDRead:DC_BOARD0_ID_INDEX + boardIndex];
	}
	@catch(NSException* localException) {
		[localException raise];
	}
	return result;
}

- (void) setVtToHw
{
    // call xl3 loadHardware
    [[[[self guardian] guardian] adapter]
         loadHardwareWithSlotMask: (1 << [[self guardian] stationNumber])];
}
@end


