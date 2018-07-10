//
//  ORBit3Model.m
//  Orca
//
//  Created by Mark Howe on Mon Nov 18 2002.
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
#import "ORBit3Model.h"

@implementation ORBit3Model

#pragma mark ¥¥¥Initialization

- (id) init //designated initializer
{
	self = [super init];
	return self;
}

-(void)dealloc
{
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"Bit3Card"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORBit3Controller"];
}

- (NSString*) helpURL
{
	return @"VME/SBS_Bit3.html";
}

#pragma mark ¥¥¥Hardware Access
- (id) controllerCard
{
	return [[self crate] controllerCard];
}


- (void) resetContrl
{
	id controller = [[self crate] controllerCard];
	if(!controller){
		[NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
	}
	[controller resetContrl];
}

- (void) checkStatusErrors
{
	id controller = [[self crate] controllerCard];
	if(!controller){
		[NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
	}
	[controller checkStatusErrors];
}

-(void) readLongBlock:(unsigned long *) readAddress
			atAddress:(unsigned int) vmeAddress
			numToRead:(unsigned int) numberLongs
		   withAddMod:(unsigned short) anAddressModifier
					   usingAddSpace:(unsigned short) anAddressSpace
{
	id controller = [[self crate] controllerCard];
	if(!controller){
		[NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
	}
	[controller readLongBlock:readAddress
					atAddress:vmeAddress
					numToRead:numberLongs
				   withAddMod:anAddressModifier
				usingAddSpace:anAddressSpace];
}

-(void) writeLongBlock:(unsigned long *) writeAddress
			 atAddress:(unsigned int) vmeAddress
			numToWrite:(unsigned int) numberLongs
			withAddMod:(unsigned short) anAddressModifier
						   usingAddSpace:(unsigned short) anAddressSpace
{
	id controller = [[self crate] controllerCard];
	if(!controller){
		[NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
	}
	[controller writeLongBlock:writeAddress
					 atAddress:vmeAddress
					numToWrite:numberLongs
					withAddMod:anAddressModifier
				 usingAddSpace:anAddressSpace];
	
}

-(void) readLong:(unsigned long *) readAddress
	   atAddress:(unsigned int) vmeAddress
	 timesToRead:(unsigned int) numberLongs
	  withAddMod:(unsigned short) anAddressModifier
   usingAddSpace:(unsigned short) anAddressSpace
{
	id controller = [[self crate] controllerCard];
	if(!controller){
		[NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
	}
	[controller readLong:readAddress
			   atAddress:vmeAddress
			 timesToRead:numberLongs
			  withAddMod:anAddressModifier
		   usingAddSpace:anAddressSpace];
}

-(void) readByteBlock:(unsigned char *) readAddress
			atAddress:(unsigned int) vmeAddress
			numToRead:(unsigned int) numberBytes
		   withAddMod:(unsigned short) anAddressModifier
					   usingAddSpace:(unsigned short) anAddressSpace
{
	id controller = [[self crate] controllerCard];
	if(!controller){
		[NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
	}
	[controller readByteBlock:readAddress
					atAddress:vmeAddress
					numToRead:numberBytes
				   withAddMod:anAddressModifier
				usingAddSpace:anAddressSpace];
	
}

-(void) writeByteBlock:(unsigned char *) writeAddress
			 atAddress:(unsigned int) vmeAddress
			numToWrite:(unsigned int) numberBytes
			withAddMod:(unsigned short) anAddressModifier
						   usingAddSpace:(unsigned short) anAddressSpace
{
	id controller = [[self crate] controllerCard];
	if(!controller){
		[NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
	}
	[controller writeByteBlock:writeAddress
					 atAddress:vmeAddress
					numToWrite:numberBytes
					withAddMod:anAddressModifier
				 usingAddSpace:anAddressSpace];
	
}


-(void) readWordBlock:(unsigned short *) readAddress
			atAddress:(unsigned int) vmeAddress
			numToRead:(unsigned int) numberWords
		   withAddMod:(unsigned short) anAddressModifier
					   usingAddSpace:(unsigned short) anAddressSpace
{
	id controller = [[self crate] controllerCard];
	if(!controller){
		[NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
	}
	[controller readWordBlock:readAddress
					atAddress:vmeAddress
					numToRead:numberWords
				   withAddMod:anAddressModifier
				usingAddSpace:anAddressSpace];
	
}

-(void) writeWordBlock:(unsigned short *) writeAddress
			 atAddress:(unsigned int) vmeAddress
			numToWrite:(unsigned int) numberWords
			withAddMod:(unsigned short) anAddressModifier
						   usingAddSpace:(unsigned short) anAddressSpace
{
	id controller = [[self crate] controllerCard];
	if(!controller){
		[NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
	}
	[controller writeWordBlock:writeAddress
					 atAddress:vmeAddress
					numToWrite:numberWords
					withAddMod:anAddressModifier
				 usingAddSpace:anAddressSpace];
	
}






@end
