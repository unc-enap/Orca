//
//  ORStandardEnumerator.h
//  Mandy
//
//  Created by Andreas on Mon Aug 04 2003.
//  Copyright (c) 2003 Andreas Mayer. All rights reserved.
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


typedef int (*CountMethod)(id, SEL);
typedef id (*NextObjectMethod)(id, SEL, int);

@interface ORStandardEnumerator : NSEnumerator {
	id collection;
	SEL countSelector;
	SEL nextObjectSelector;
	CountMethod count;
	NextObjectMethod nextObject;
	int position;
}

- (id)initWithCollection:(id)theCollection countSelector:(SEL)theCountSelector objectAtIndexSelector:(SEL)theObjectSelector;


@end
