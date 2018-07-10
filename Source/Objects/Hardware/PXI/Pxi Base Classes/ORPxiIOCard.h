//
//  ORPxiIOCard.h
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
#import "ORPxiAdapterModel.h"

@interface ORPxiIOCard : ORPxiCard {

	@protected
	id	controller; //use to cache the controller for abit more speed. use with care!
    unsigned long 	baseAddress;
    unsigned long	exceptionCount;
}

#pragma mark ¥¥¥Accessors
- (void) 			setBaseAddress:(unsigned long) anAddress;
- (unsigned long) 	baseAddress;
- (id)				adapter;
- (unsigned long)   exceptionCount;
- (void)			incExceptionCount;
- (void)			clearExceptionCount;
- (NSRange)			memoryFootprint;
- (BOOL)			memoryConflictsWith:(NSRange)aRange;

@end

#pragma mark ¥¥¥External String Definitions
extern NSString* ORPxiIOCardBaseAddressChanged;
extern NSString* ORPxiIOCardExceptionCountChanged;