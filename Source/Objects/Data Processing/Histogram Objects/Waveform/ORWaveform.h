//
//  ORWaveform.h
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

#import "ORDataSetModel.h"
#import "ORPlot.h"

@class ORWaveformController;

@interface ORWaveform : ORDataSetModel<ORFastPlotDataSourceMethods>  {
    NSData*				waveform;
    uint32_t		dataOffset;
	int					unitSize;
	BOOL				useUnsignedValues;
	NSMutableArray*		rois;
}

#pragma mark ¥¥¥Accessors 
- (int)	 unitSize;
- (void) setUnitSize:(int)aUnitSize;
- (uint32_t) dataOffset;
- (void) setDataOffset:(uint32_t)newOffset;
- (uint32_t)  numberBins;
- (int32_t) value:(uint32_t)channel;
- (int32_t) value:(uint32_t)channel callerLockedMe:(BOOL)callerLockedMe;
-(NSUInteger) manyValues:(NSRange)overRange to:(double*)output stride:(NSUInteger)stride callerLockedMe:(BOOL)callerLockedMe;
- (void) setWaveform:(NSData*)aWaveform;
- (BOOL) useUnsignedValues;
- (void) setUseUnsignedValues:(BOOL)aState;
- (NSMutableArray*) rois;
- (NSData*) rawData;
- (double) getTrapezoidValue:(unsigned int)channel rampTime:(unsigned int)ramp gapTime:(unsigned int)gap;

#pragma mark ¥¥¥Data Management
- (void) clear;

#pragma mark ¥¥¥Data Source Methods
- (id)   name;
- (uint32_t) startingByteOffset:(id)aPlotter  dataSet:(int)set;
- (unsigned short) unitSize:(id)aPlotter  dataSet:(int)set;
- (NSMutableArray*) rois;
- (int) numberPointsInPlot:(id)aPlot;
- (void) plotter:(id)aPlot index:(int)i x:(double*)xValue y:(double*)yValue;
- (NSUInteger) plotter:(id)aPlot indexRange:(NSRange)aRange stride:(NSUInteger)stride x:(NSMutableData*)x y:(NSMutableData*)y;

//subclasses will override these
- (uint32_t) mask;
- (uint32_t) specialBitMask;

@end

extern NSString* ORWaveformUseUnsignedChanged;

