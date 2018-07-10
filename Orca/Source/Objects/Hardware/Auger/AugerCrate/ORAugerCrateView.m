//
//  ORAugerCrateView.m
//  Orca
//
//  Created by Mark Howe on Fri Aug 5, 2005.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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


#import "ORAugerCrateView.h"


#define kNumAugerCrateSlots 21

@implementation ORAugerCrateView

- (int) maxNumberOfCards
{
    return kNumAugerCrateSlots;
}

- (int) cardWidth
{
    return 12;
}

- (NSPoint) suggestPasteLocationFor:(id)aCard
{
	if( [aCard isKindOfClass:NSClassFromString(@"ORAugerControllerCard")]){
		if([self slotRangeEmpty:NSMakeRange(0,1)]){
            return [self constrainLocation:NSMakePoint(0,0)];
		}
		else return NSMakePoint(-1,-1);
	}
	else return [super suggestPasteLocationFor:aCard];
}


- (BOOL) canAddObject:(id)obj atPoint:(NSPoint)aPoint
{
	if([super canAddObject:obj atPoint:aPoint]){
		int aSlot = [self slotAtPoint:aPoint];
		if( [obj isKindOfClass:NSClassFromString(@"ORAugerFireWireCard")]){
			if(aSlot != 0){
				NSLog(@"Rejected attempt to place AUGER controller in non-controller slot\n");
				return NO;
			}
		}
		else {
			if(aSlot == 0){
				NSLog(@"Rejected attempt to place AUGER card in controller slot\n");
				return NO;
			}
		}
		return YES;
	}
	else return NO;
}

- (BOOL) slot:(int) aSlot legalForCard:(id)aCard
{
	NSRange objRange			 = NSMakeRange(aSlot,1);
	NSRange legalControllerRange = NSMakeRange(0,1);
	
	//last check.. Camac restricts the last two slots for the controller
	if([aCard isKindOfClass:NSClassFromString(@"ORAugerSLTModel")]){
		if(!NSEqualRanges(legalControllerRange,objRange))	return NO;
	}
	else if(NSIntersectionRange(legalControllerRange,objRange).length != 0) return NO;
	return YES;
}

@end
