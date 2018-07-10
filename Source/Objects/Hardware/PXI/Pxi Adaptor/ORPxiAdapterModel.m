//
//  ORPxiAdapterModel.m
//  Orca
//
//  Created by Mark Howe on Thurs Aug 26 2010
//  Copyright (c) 2010 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics 
//sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ¥¥¥Imported Files
#import "ORPxiAdapterModel.h"
#import "ORPxiCrate.h"

@implementation ORPxiAdapterModel

#pragma mark ¥¥¥Initialization
- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"PxiAdapterCard"]];
}

- (void) setGuardian:(id)aGuardian
{
    if(aGuardian){
		if([aGuardian adapter] == nil){
			[aGuardian setAdapter:self];			
		}
	}
    else [[self guardian] setAdapter:nil];
	
    [super setGuardian:aGuardian];
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
		[NSException raise:@"Not Connected" format:@"You must connect to a PXI Controller (i.e. a 8336)."];
	}
	[controller resetContrl];
}

- (void) checkStatusErrors
{
	id controller = [[self crate] controllerCard];
	if(!controller){
		[NSException raise:@"Not Connected" format:@"You must connect to a PXI Controller (i.e. a 8336)."];
	}
	[controller checkStatusErrors];
}

-(void) readLongBlock:(unsigned long *) readAddress
			atAddress:(unsigned long) pxiAddress
			numToRead:(unsigned int) numberLongs
{
	id controller = [[self crate] controllerCard];
	if(!controller){
		[NSException raise:@"Not Connected" format:@"You must connect to a PXI Controller (i.e. a 8336)."];
	}
	[controller readLongBlock:readAddress
					atAddress:pxiAddress
					numToRead:numberLongs];
}

-(void) writeLongBlock:(unsigned long *) writeAddress
			 atAddress:(unsigned long) pxiAddress
			numToWrite:(unsigned int) numberLongs

{
	id controller = [[self crate] controllerCard];
	if(!controller){
		[NSException raise:@"Not Connected" format:@"You must connect to a PXI Controller (i.e. a 8336)."];
	}
	[controller writeLongBlock:writeAddress
					 atAddress:pxiAddress
					numToWrite:numberLongs];
}

-(void) readLong:(unsigned long *) readAddress
	   atAddress:(unsigned long) pxiAddress
	 timesToRead:(unsigned int) numberLongs
{
	id controller = [[self crate] controllerCard];
	if(!controller){
		[NSException raise:@"Not Connected" format:@"You must connect to a PXI Controller (i.e. a 8336)."];
	}
	[controller readLong:readAddress
			   atAddress:pxiAddress
			 timesToRead:numberLongs];
}

-(void) readByteBlock:(unsigned char *) readAddress
			atAddress:(unsigned long) pxiAddress
			numToRead:(unsigned int) numberBytes
{
	id controller = [[self crate] controllerCard];
	if(!controller){
		[NSException raise:@"Not Connected" format:@"You must connect to a PXI Controller (i.e. a 8336)."];
	}
	[controller readByteBlock:readAddress
					atAddress:pxiAddress
					numToRead:numberBytes];
}

-(void) writeByteBlock:(unsigned char *) writeAddress
			 atAddress:(unsigned long) pxiAddress
			numToWrite:(unsigned int) numberBytes
{
	id controller = [[self crate] controllerCard];
	if(!controller){
		[NSException raise:@"Not Connected" format:@"You must connect to a PXI Controller (i.e. a 8336)."];
	}
	[controller writeByteBlock:writeAddress
					 atAddress:pxiAddress
					numToWrite:numberBytes];
}


-(void) readWordBlock:(unsigned short *) readAddress
			atAddress:(unsigned long) pxiAddress
			numToRead:(unsigned int) numberWords
{
	id controller = [[self crate] controllerCard];
	if(!controller){
		[NSException raise:@"Not Connected" format:@"You must connect to a PXI Controller (i.e. a 8336)."];
	}
	[controller readWordBlock:readAddress
					atAddress:pxiAddress
					numToRead:numberWords];
}

-(void) writeWordBlock:(unsigned short *) writeAddress
			 atAddress:(unsigned long) pxiAddress
			numToWrite:(unsigned int) numberWords
{
	id controller = [[self crate] controllerCard];
	if(!controller){
		[NSException raise:@"Not Connected" format:@"You must connect to a PXI Controller (i.e. a 8336)."];
	}
	[controller writeWordBlock:writeAddress
					 atAddress:pxiAddress
					numToWrite:numberWords];
	
}

@end
