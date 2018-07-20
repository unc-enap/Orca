//
//  ORVmeIOCard.h
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

#import "ORVmeCard.h"

#pragma mark ¥¥¥Definitions
#define	kAccessRemoteIO			0x01
#define	kAccessRemoteRAM		0x02
#define	kAccessRemoteDRAM		0x03


@interface ORVmeIOCard : ORVmeCard
{
	@protected
	id                   controller; //use to cache the controller for abit more speed. use with care!
    uint32_t        baseAddress;
    unsigned short       addressModifier;
    uint32_t        exceptionCount;
    BOOL                 diagnosticsEnabled;
    NSMutableDictionary* diagnosticReport;
    NSMutableDictionary* oldUserValueDictionary;
}

#pragma mark ¥¥¥Accessors
- (void) 			setBaseAddress:(uint32_t) anAddress;
- (uint32_t) 	baseAddress;
- (BOOL)            diagnosticsEnabled;
- (void)            setDiagnosticsEnabled:(BOOL)aState;
- (void)			setAddressModifier:(unsigned short)anAddressModifier;
- (unsigned short)  addressModifier;
- (id)				adapter;
- (uint32_t)   exceptionCount;
- (void)			incExceptionCount;
- (void)			clearExceptionCount;
- (NSRange)			memoryFootprint;
- (BOOL)			memoryConflictsWith:(NSRange)aRange;

- (void)            writeAndCheckLong:(uint32_t)aValue
                        addressOffset:(uint32_t)anOffset
                                 mask:(uint32_t)aMask
                            reportKey:(NSString*)aKey
                        forceFullInit:(BOOL) forceFullInit;

- (void)            writeAndCheckLong:(uint32_t)aValue
                        addressOffset:(uint32_t)anOffset
                                 mask:(uint32_t)aMask
                            reportKey:(NSString*)aKey;

- (BOOL) longValueChanged:(uint32_t)aValue valueKey:(NSString*)aKey;
- (void) clearOldUserValues;

- (void) verifyValue:(uint32_t)val1 matches:(uint32_t)val2 reportKey:aKey;
- (void) clearDiagnosticsReport;
- (void) briefDiagnosticsReport;
- (void) printDiagnosticsReport;
@end

#pragma mark ¥¥¥External String Definitions
extern NSString* ORVmeIOCardBaseAddressChangedNotification;
extern NSString* ORVmeIOCardExceptionCountChanged;
extern NSString* ORVmeDiagnosticsEnabledChanged;
