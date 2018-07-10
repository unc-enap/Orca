//
//  ORAdcProcessorModel.h
//  Orca
//
//  Created by Mark Howe on 04/05/12.
//  Copyright 20012 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina  sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "OROutputElement.h"
#import "ORProcessNub.h"

@class ORAdcProcessorLowLimitNub;
@class ORAdcProcessorHighLimitNub;

@interface ORAdcProcessorModel : OROutputElement {
	double hwValue;
	BOOL valueTooLow;
	BOOL valueTooHigh;
	ORAdcProcessorLowLimitNub*  lowLimitNub;
	ORAdcProcessorHighLimitNub* highLimitNub;
}

#pragma mark ***Accessors
- (NSString*) report;
- (id) hwObject;
- (void) setHwObject:(id) anObject;
- (int) bit;
- (void) setBit:(int)aBit;

- (double) hwValue;
- (BOOL) valueTooLow;
- (BOOL) valueTooHigh;
- (void) viewSource;

@end

@interface ORAdcProcessorLowLimitNub : ORProcessNub
- (id) eval;
- (int) evaluatedState;
@end

@interface ORAdcProcessorHighLimitNub : ORProcessNub
- (id) eval;
- (int) evaluatedState;
@end
@interface NSObject (ORAdcProcessor)
-(BOOL) dataForChannelValid:(int)aChannel;
@end
