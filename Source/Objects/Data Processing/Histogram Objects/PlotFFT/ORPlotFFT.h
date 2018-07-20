//
//  ORPlotFFT.h
//  Orca
//
//  Created by Mark Howe on Sun Nov 17 2002.
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


#pragma mark ¥¥¥Imported Files

#import "ORDataSetModel.h"

#pragma mark ¥¥¥Forward Declarations
@class ORChannelData;
@class ORPlotFFTController;

@interface ORPlotFFT : ORDataSetModel  {
    uint32_t dataId;
    NSArray* 	realArray;
    NSArray* 	imaginaryArray;
	NSArray*	powerSpectrumArray;
	BOOL		showReal;
	BOOL		showImaginary;
	BOOL		showPowerSpectrum;
	NSRecursiveLock*	dataLock;
}

#pragma mark ¥¥¥Accessors
- (void) processResponse:(NSDictionary*)aResponse;
- (void) setRealArray:(NSArray*)aaRealArray imaginaryArray:(NSArray*)anImaginaryArray;
- (BOOL) showReal;
- (void) setShowReal:(BOOL)aFlag;
- (NSArray*) powerSpectrumArray;
- (void) setPowerSpectrumArray:(NSArray*)anArray;
- (BOOL) showImaginary;
- (void) setShowImaginary:(BOOL)aFlag;
- (BOOL) showPowerSpectrum;
- (void) setShowPowerSpectrum:(BOOL)aFlag;
- (NSUInteger) numberChans;

#pragma mark ¥¥¥Data Management
- (void) clear;

#pragma mark ¥¥¥Writing Data
- (void) writeDataToFile:(FILE*)aFile;

#pragma mark ¥¥¥Data Source Methods
- (id)   name;
- (int)	numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;
- (float) plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x; 
@end

extern NSString* ORPlotFFTShowChanged;


