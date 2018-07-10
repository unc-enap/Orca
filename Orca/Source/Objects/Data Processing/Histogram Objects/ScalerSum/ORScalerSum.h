//
//  ORScalerSum.h
//  Orca
//
//  Created by Mark Howe on Sun Nov 17 2002.
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

#import "ORDataSetModel.h"

#pragma mark ¥¥¥Forward Declarations
@class ORChannelData;
@class ORScalerSumController;

@interface ORScalerSum : ORDataSetModel  {
    unsigned long 	scalerSum;
    unsigned long 	scalerValue;
	NSLock*			dataLock;
}

#pragma mark ¥¥¥Accessors 
- (NSString*)name;
- (void) loadScalerValue:(unsigned long)newScaler;

#pragma mark ¥¥¥Data Management
- (void) clear;

#pragma mark ¥¥¥Data Source Methods
- (NSString*)   name;


@end
