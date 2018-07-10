//  ORVmeCrate.m
//  Orca
//
//  Created by Mark Howe on 1/24/09.
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

#import "ORVmeCrate.h"
#import "ORVmeIOCard.h"

@implementation ORVmeCrate

- (void) printMemoryMap
{
	if([self count]){
		NSLogFont([NSFont fontWithName:@"Monaco" size:12], @"Slot  Card                  Memory Footprint\n");
		NSLogFont([NSFont fontWithName:@"Monaco" size:12], @"--------------------------------------------\n");
		id aCard;
		NSEnumerator* e = [self objectEnumerator];
		while(aCard = [e nextObject]){
			if([aCard isKindOfClass:[ORVmeIOCard class]]){
				NSRange aRange = [aCard memoryFootprint];
				NSString* s = [NSString stringWithFormat:@"%4d %-20s 0x%08x - 0x%08x",[aCard slot],[[aCard className] cStringUsingEncoding:NSASCIIStringEncoding],aRange.location,NSMaxRange(aRange)];
				NSLogFont([NSFont fontWithName:@"Monaco" size:12], @"%@\n",s);
			}
		}
		NSLogFont([NSFont fontWithName:@"Monaco" size:12], @"--------------------------------------------\n");

		id aCard1;
		id aCard2;
		NSEnumerator* e1 = [self objectEnumerator];
		while(aCard1 = [e1 nextObject]){
			if([aCard1 isKindOfClass:[ORVmeIOCard class]]){
				NSEnumerator* e2 = [self objectEnumerator];
				while(aCard2 = [e2 nextObject]){
					if([aCard2 isKindOfClass:[ORVmeIOCard class]]){
						if(aCard1 == aCard2)continue;
						if([aCard1 memoryConflictsWith:[aCard2 memoryFootprint]]){
							NSLog(@"%@ (Slot %d) conflicts with %@ (Slot %d)\n",[aCard1 className],[aCard1 slot],[aCard2 className],[aCard2 slot]);
						}
					}
				}
			}
		}
		
	}
	else {
		NSLog(@"Crate is empty\n");
	}
}

@end
