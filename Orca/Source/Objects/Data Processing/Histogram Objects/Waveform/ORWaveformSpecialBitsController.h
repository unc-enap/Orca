//
//  ORWaveformSpecialBitsController.h
//  Orca
//
//  Created by Mark Howe on Mon Jan 06 2003.
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


#pragma mark ¥¥¥Imported Files
#import "ORWaveformController.h"

@interface ORWaveformSpecialBitsController : ORWaveformController {
}

#pragma mark ¥¥¥Data Source
- (void) plotter:(id)aPlot index:(int)index x:(double*)x y:(double*)y;
//#if 0
//2017-02-15 -tb- commented out to force using the 'slow' plotting methods for KATRIN waveforms (required to take the offset index into account)
- (NSUInteger) plotter:(id)aPlot indexRange:(NSRange)aRange stride:(NSUInteger)stride x:(NSMutableData*)x y:(NSMutableData*)y;
//#endif
@end
