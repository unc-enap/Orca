//
//  ORVertex.m
//  ORCA
//
//  Created by Laura Wendlandt on 6/28/13.
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

#import "ORVertex.h"

@implementation ORVertex

- (id)initWithX:(float)myX Y:(float)myY Z:(float)myZ
{
    self = [super init];
    
    x = myX;
    y = myY;
    z = myZ;
    return self;
}

- (float) largestAbsolute
{
    if(fabs(x) > fabs(y))
    {
        if(fabs(x) > fabs(z))
            return fabs(x);
        else if (fabs(z) > fabs(y))
            return fabs(z);
    }
    return fabs(y);
}

- (void) divideAllBy:(float)num
{
    x /= num;
    y /= num;
    z /= num;
}


- (float) getX
{
    return x;
}

- (float) getY
{
    return y;
}

- (float) getZ
{
    return z;
}

@end