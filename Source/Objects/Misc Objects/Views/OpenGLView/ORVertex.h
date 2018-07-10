//
//  ORVertex.h
//  ORCA
//
//  Created by Laura Wendlandt on 6/28/13.
//.obj specification info: http://paulbourke.net/dataformats/obj/
//.mtl specification info: http://www.fileformat.info/format/material/
//
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

#import <Foundation/Foundation.h>

@interface ORVertex : NSObject
{
    float x,y,z;
}

- (id) initWithX:(float)myX Y:(float)myY Z:(float)myZ;
- (float) largestAbsolute; //returns largest absolute value of x, y, and z
- (void) divideAllBy:(float)num;

- (float) getX;
- (float) getY;
- (float) getZ;

@end