//
//  ORVmeIOCard.m
//  Orca
//
//  Created by Mark Howe on Fri Nov 22 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORVmeIOCard.h"
#import "ORVmeBusProtocol.h"


#pragma mark ¥¥¥Notification Strings
NSString* ORVmeIOCardBaseAddressChangedNotification  = @"Vme IO Card Base Address Changed";
NSString* ORVmeIOCardExceptionCountChanged           = @"ORVmeIOCardExceptionCountChanged";
NSString* ORVmeDiagnosticsEnabledChanged             = @"ORVmeDiagnosticsEnabledChanged";



@implementation ORVmeIOCard

- (void) dealloc
{
    [diagnosticReport release];
    [oldUserValueDictionary release];
    [super dealloc];
}
#pragma mark ¥¥¥Accessors
- (void) setAddressModifier:(unsigned short)anAddressModifier
{
    addressModifier = anAddressModifier;
}

- (unsigned short)  addressModifier
{
    return addressModifier;
}

- (void) setBaseAddress:(unsigned long) address
{
	[[[self undoManager] prepareWithInvocationTarget:self] setBaseAddress:[self baseAddress]];
    baseAddress = address;
    
	[[NSNotificationCenter defaultCenter]
         postNotificationName:ORVmeIOCardBaseAddressChangedNotification
					   object:self]; 
    
}

- (unsigned long) baseAddress
{
    return baseAddress;
}

- (NSRange)	memoryFootprint
{
	//subclasses should overide to provide an accurate memory range
	return NSMakeRange(baseAddress,1*sizeof(long));
}

- (BOOL) memoryConflictsWith:(NSRange)aRange
{
	return NSIntersectionRange(aRange,[self memoryFootprint]).length != 0;
}

- (id)	adapter
{
	id anAdapter = [guardian adapter];
	if(anAdapter)return anAdapter;
	else [NSException raise:@"No adapter" format:@"You must place a VME adaptor card into the crate (i.e. a SBS Bit3)."];
	return nil;
}

- (unsigned long)   exceptionCount
{
    return exceptionCount;
}

- (void)clearExceptionCount
{
    exceptionCount = 0;
    
	[[NSNotificationCenter defaultCenter]
         postNotificationName:ORVmeIOCardExceptionCountChanged
					   object:self]; 
    
}

- (void)incExceptionCount
{
    ++exceptionCount;
    
	[[NSNotificationCenter defaultCenter]
         postNotificationName:ORVmeIOCardExceptionCountChanged
					   object:self]; 
}


#pragma mark ¥¥¥Archival
static NSString *ORVmeCardBaseAddress 		= @"Vme Base Address";
static NSString *ORVmeCardAddressModifier 	= @"vme Address Modifier";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
	[[self undoManager] disableUndoRegistration];
    
	[self setBaseAddress:[decoder decodeInt32ForKey:ORVmeCardBaseAddress]];
	[self setAddressModifier:[decoder decodeIntForKey:ORVmeCardAddressModifier]];
    
	[[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeInt32:[self baseAddress] forKey:ORVmeCardBaseAddress];
	[encoder encodeInt:[self addressModifier] forKey:ORVmeCardAddressModifier];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [objDictionary setObject:[NSNumber numberWithLong:baseAddress] forKey:@"baseAddress"];
    return objDictionary;
}


- (void) writeAndCheckLong:(unsigned long)aValue
             addressOffset:(short)anOffset
                      mask:(unsigned long)aMask
                 reportKey:(NSString*)aKey
{
    return [self writeAndCheckLong:aValue addressOffset:anOffset mask:aMask reportKey:aKey forceFullInit:NO];
}

- (void) writeAndCheckLong:(unsigned long)aValue
             addressOffset:(short)anOffset
                      mask:(unsigned long)aMask
                 reportKey:(NSString*)aKey
             forceFullInit:(BOOL) forceFullInit
{
    BOOL valueChanged = [self longValueChanged:aValue valueKey:aKey];
    if( valueChanged || forceFullInit){
        unsigned long writeValue = aValue & aMask;
        [[self adapter] writeLongBlock: &writeValue
                             atAddress: [self baseAddress] + anOffset
                            numToWrite: 1
                            withAddMod: [self addressModifier]
                         usingAddSpace: 0x01];
        
        if(diagnosticsEnabled){
            NSLog(@"%@ wrote: %d (0x%08x) to 0x%x (%@) \n",[self fullID],aValue,aValue,anOffset,aKey);

            unsigned long readBackValue = 0;
            [[self adapter] readLongBlock: &readBackValue
                                atAddress: [self baseAddress] + anOffset
                               numToRead: 1
                               withAddMod: [self addressModifier]
                            usingAddSpace: 0x01];
            
            readBackValue &= aMask;
            
            [self verifyValue: writeValue matches:readBackValue reportKey:aKey];
         }
    }
}

- (void) clearOldUserValues
{
    [oldUserValueDictionary release];
    oldUserValueDictionary=nil;
}

- (BOOL) longValueChanged:(unsigned long)aValue valueKey:(NSString*)aKey
{
    if(!oldUserValueDictionary)oldUserValueDictionary = [[NSMutableDictionary dictionary] retain];
    
    if(![oldUserValueDictionary objectForKey:aKey] ||
       [[oldUserValueDictionary objectForKey:aKey] unsignedLongValue] != aValue){
        [oldUserValueDictionary setObject:[NSNumber numberWithUnsignedLong:aValue] forKey:aKey];
        return YES;
    }
    else return NO;
}


- (BOOL) diagnosticsEnabled {return diagnosticsEnabled;}
- (void) setDiagnosticsEnabled:(BOOL)aState
{
    if(aState!=diagnosticsEnabled){
        [[[self undoManager] prepareWithInvocationTarget:self] setDiagnosticsEnabled:diagnosticsEnabled];
        diagnosticsEnabled = aState;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORVmeDiagnosticsEnabledChanged object: self]; 
    }
}

- (void) verifyValue:(unsigned long)val1 matches:(unsigned long)val2 reportKey:aKey
{
    if(val1 != val2){
        if(!diagnosticReport)diagnosticReport = [[NSMutableDictionary dictionary] retain];
        NSString* errorString = [NSString stringWithFormat:@"0x%08lx != 0x%08lx",val1,val2];
        //there may be an existing error record for this key, if so we add to it, otherwise we make a new one
        NSMutableDictionary* aRecord = [diagnosticReport objectForKey:aKey];
        if(!aRecord)aRecord = [NSMutableDictionary dictionary];
        unsigned long errorCount = [[aRecord objectForKey:@"ErrorCount"]unsignedLongValue];
        errorCount++;
        [aRecord setObject:[NSNumber numberWithUnsignedLong:errorCount] forKey:@"ErrorCount"];
        [aRecord setObject:errorString forKey:@"LastErrorString"];
        [aRecord setObject:aKey forKey:@"Name"];
        [diagnosticReport setObject:aRecord forKey:aKey];
    }
}
- (void) briefDiagnosticsReport
{
    if(!diagnosticReport)NSLog(@"%@: No Errors Reported\n",[self fullID]);
    else {
        NSLog(@"%@ : %d Registers reported read/write mismatches\n",[self fullID],[[diagnosticReport allKeys] count]);
    }
}
- (void) printDiagnosticsReport
{
    if(!diagnosticReport)NSLog(@"%@: No diagnostic report Available\n",[self fullID]);
    else {
        NSLog(@"%@: Dagnostic report:\n",[self fullID]);
        NSLog(@"%d Registers reported read/write mismatches\n",[[diagnosticReport allKeys] count]);
		NSArray* sortedKeys = [[diagnosticReport allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        for(NSString* aKey in sortedKeys){
            NSDictionary* anEntry = [diagnosticReport objectForKey:aKey];
            NSLog(@"%@: %@ ErrorCount: %@\n",[anEntry objectForKey:@"Name"],[anEntry objectForKey:@"LastErrorString"],[anEntry objectForKey:@"ErrorCount"]);
        }
    }
}
- (void) clearDiagnosticsReport
{
    [diagnosticReport release];
    diagnosticReport = nil;
}
@end
