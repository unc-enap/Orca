//
//  OR2DHistoController.h
//  Orca
//
//  Created by Mark Howe on Thurs Dec 23 2004.
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
#import "ORDataController.h"

@class OR2dRoiController;

@interface OR2DHistoController : ORDataController {
	IBOutlet NSView*		roiView;
    OR2dRoiController*		roiController;
}
- (id) init;
- (BOOL) plotterShouldShowRoi:(id)aPlot;
- (IBAction) logLin:(NSToolbarItem*)item;
- (IBAction) zoomIn:(id)sender;
- (IBAction) zoomOut:(id)sender;
- (NSMutableArray*) roiArrayForPlotter:(id)aPlot;

#pragma mark ¥¥¥Data Source
- (NSData*) plotter:(id)aPlotter numberBinsPerSide:(unsigned short*)xValue;
- (void) plotter:(id)aPlotter xMin:(unsigned short*)aMinX xMax:(unsigned short*)aMaxX yMin:(unsigned short*)aMinY yMax:(unsigned short*)aMaxY;

@end
