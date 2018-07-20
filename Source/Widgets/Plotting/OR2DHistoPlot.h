//
//  OR2DHistoPlot.h
//  plotterDev
//
//  Created by Mark Howe on 2/20/10.
//  Copyright 2010 University of North Carolina. All rights reserved.
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
#import "ORPlotWithROI.h"

@interface NSObject (OR2DHistoDataSourceMethods)
- (NSData*) plotter:(id) aPlotter  numberBinsPerSide:(unsigned short*)xValue;
- (void) plotter:(id) aPlotter xMin:(unsigned short*)aMinX xMax:(unsigned short*)aMaxX yMin:(unsigned short*)aMinY yMax:(unsigned short*)aMaxY;
@end

@interface OR2DHistoPlot : ORPlotWithROI {
}

#pragma mark ***Drawing
- (void) drawData;
- (void) drawExtras;

#pragma mark ***Helpers
- (void) logLin;
- (int32_t) maxValueChannelinXRangeFrom:(int32_t)minChannel to:(int32_t)maxChannel;
- (void) keyDown:(NSEvent*)theEvent;
- (void) shiftRoiUp;
- (void) shiftRoiDown;
- (void) shiftRoiRight;
- (void) shiftRoiLeft;


@end
