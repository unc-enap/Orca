//
//  StopLightView.h
//  Orca
//
//  Created by Mark Howe on 4/27/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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




@class ORDotImage;

enum {
    kStoppedLight,
    kCautionLight,
    kGoLight
};

@interface StopLightView : NSView {

    ORDotImage* stopLight;
    ORDotImage* cautionLight;
    ORDotImage* goLight;
    int state;
    ORDotImage* offLight;
    BOOL hideCautionLight;
}

#pragma mark ***Accessors
- (ORDotImage*) offLight;
- (void) setOffLight:(ORDotImage*)aOffLight;
- (int) state;
- (void) setState:(int)aState;
- (ORDotImage*) goLight;
- (void) setGoLight:(ORDotImage*)aGoLight;
- (ORDotImage*) cautionLight;
- (void) setCautionLight:(ORDotImage*)aCautionLight;
- (ORDotImage*) stopLight;
- (void) setStopLight:(ORDotImage*)aStopLight;
- (void) hideCautionLight;
@end
