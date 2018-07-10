//
//  ORNplHVModel.h
//  Orca
//
//  Created by Mark Howe on Wed Jun 4 2008
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

#import "ORRamperModel.h"
#import "ORHWWizard.h"

@class NetSocket;

#define kNplHVCurrentAdc		0x0
#define kNplHVVoltageAdc		0x1
#define kNplHVDac				0x2
#define kNplHVStatusControl		0x3


//reg defs for ADC AD7734
#define kNplHVCommReg			0x0
#define kNplHVIOPort			0x1
#define kNplHVRevision			0x2
#define kNplHVTest				0x3
#define kNplHVIOAdcStatus		0x4
#define kNplHVCheckSum			0x5
#define kNplHVAdc0ScaleCalib	0x6
#define kNplHVAdcFullScale		0x7
#define kNplHVChanData			0x8
#define kNplHVChan0ScaleCal		0x10
#define kNplHVChanFSCal			0x18
#define kNplHVChanStatus		0x20
#define kNplHVChanSetup			0x28
#define kNplHVChanConvTime		0x30
#define kNplHVMode				0x38

#define kNplHvRead				0x40
#define kNplHvWrite				0x00

@interface ORNplHVModel : ORRamperModel
{
	id comBoard;
	int boardNumber;
	int dac[8];
	int adc[8];
	int current[8];
	int controlReg[8];
}

#pragma mark ***Accessors
- (int) adc:(int)aChan;
- (void) setAdc:(int)channel withValue:(int)aValue;
- (int) dac:(int)aChan;
- (void) setDac:(int)channel withValue:(int)aValue;
- (int) current:(int)aChan;
- (void) setCurrent:(int)channel withValue:(int)aValue;
- (int) controlReg:(int)aChan;
- (void) setControlReg:(int)channel withValue:(int)aValue;
- (SEL) getMethodSelector;
- (SEL) setMethodSelector;
- (SEL) initMethodSelector;
- (void) junk;
- (void) loadDac:(int)aChan;
- (void) revision;
- (void) setVoltageReg:(int)aReg chan:(int)aChan value:(int)aValue;
- (void) setCurrentReg:(int)aReg chan:(int)aChan value:(int)aValue;
- (int) numberOfChannels;
- (void) initBoard;

#pragma mark ***Utilities
- (void) sendCmd;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORNplHVLock;
