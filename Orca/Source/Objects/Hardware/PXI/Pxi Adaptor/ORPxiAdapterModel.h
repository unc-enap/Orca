//
//  ORPxiAdapterModel.h
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
#import "ORPxiCard.h"
#import "ORPxiBusProtocol.h"

@interface ORPxiAdapterModel :  ORPxiCard <ORPxiBusProtocol> 
{
}

#pragma mark ¥¥¥Hardware Access
- (id) controllerCard;
- (void) resetContrl;
- (void) checkStatusErrors;

-(void) readLongBlock:(unsigned long *) readAddress
									atAddress:(unsigned long) pxiAddress
									numToRead:(unsigned int) numberLongs;

-(void) writeLongBlock:(unsigned long *) writeAddress
										atAddress:(unsigned long) pxiAddress
										numToWrite:(unsigned int) numberLongs;

-(void) readByteBlock:(unsigned char *) readAddress
									atAddress:(unsigned long) pxiAddress
									numToRead:(unsigned int) numberBytes;

-(void) writeByteBlock:(unsigned char *) writeAddress
										atAddress:(unsigned long) pxiAddress
										numToWrite:(unsigned int) numberBytes;

-(void) readWordBlock:(unsigned short *) readAddress
									atAddress:(unsigned long) pxiAddress
									numToRead:(unsigned int) numberWords;

-(void) writeWordBlock:(unsigned short *) writeAddress
										atAddress:(unsigned long) pxiAddress
										numToWrite:(unsigned int) numberWords;
@end


