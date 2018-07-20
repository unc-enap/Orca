//
//  OR1DHisto.h
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
@class OR1DHistoController;

@interface OR1DHisto : ORDataSetModel  {
    uint32_t dataId;
    uint32_t 	overFlow;
    uint32_t 	numberBins;
    NSMutableData* 	histogram;
    NSData*         pausedHistogram;
	NSMutableArray* rois;
}


#pragma mark ¥¥¥Accessors
- (void) processResponse:(NSDictionary*)aResponse;
- (uint32_t) dataId;
- (void) setDataId: (uint32_t) DataId;
- (void)setNumberBins:(uint32_t)aNumberBins;
- (uint32_t) numberBins;
- (uint32_t)value:(uint32_t)aBin;
- (uint32_t) overFlow;
- (NSMutableArray*) rois;
- (NSData*) getNonZeroRawDataWithStart:(uint32_t*)start end:(uint32_t*)end;
- (NSString*) getnonZeroDataAsStringWithStart:(uint32_t*)start end:(uint32_t*)end;

#pragma mark ¥¥¥Data Management
- (void) histogram:(uint32_t)aValue;
- (void) histogramWW:(uint32_t)aValue weight:(uint32_t) weight; // ak 6.8.07
- (void) loadData:(NSData*)someData;
- (void) mergeHistogram:(uint32_t*)ptr numValues:(uint32_t)numBins;
- (void) mergeEnergyHistogram:(uint32_t*)ptr numBins:(uint32_t)numBins maxBins:(uint32_t)maxBins
                                                 firstBin:(uint32_t)firstBin   stepSize:(uint32_t)stepSize 
                                                   counts:(uint32_t)counts;
- (void) clear;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;
- (NSDictionary*) dataRecordDescription;
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;

#pragma mark ¥¥¥Writing Data
- (void) writeDataToFile:(FILE*)aFile;
- (void) packageData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo keys:(NSMutableArray*)aKeyArray;

#pragma mark ¥¥¥Data Source Methods
- (id)   name;
- (int) numberPointsInPlot:(id)aPlot;
- (void) plotter:(id)aPlot index:(int)i x:(double*)xValue y:(double*)yValue;
@end

