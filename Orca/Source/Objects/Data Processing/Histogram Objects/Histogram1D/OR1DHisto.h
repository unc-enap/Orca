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
    unsigned long dataId;
    unsigned long 	overFlow;
    unsigned int 	numberBins;
    NSMutableData* 	histogram;
    NSData*         pausedHistogram;
	NSMutableArray* rois;
}


#pragma mark ¥¥¥Accessors
- (void) processResponse:(NSDictionary*)aResponse;
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void)setNumberBins:(int)aNumberBins;
- (int) numberBins;
- (unsigned long)value:(unsigned long)aBin;
- (unsigned long) overFlow;
- (NSMutableArray*) rois;
- (NSData*) getNonZeroRawDataWithStart:(unsigned long*)start end:(unsigned long*)end;
- (NSString*) getnonZeroDataAsStringWithStart:(unsigned long*)start end:(unsigned long*)end;

#pragma mark ¥¥¥Data Management
- (void) histogram:(unsigned long)aValue;
- (void) histogramWW:(unsigned long)aValue weight:(unsigned long) weight; // ak 6.8.07
- (void) loadData:(NSData*)someData;
- (void) mergeHistogram:(unsigned long*)ptr numValues:(unsigned long)numBins;
- (void) mergeEnergyHistogram:(unsigned long*)ptr numBins:(unsigned long)numBins maxBins:(unsigned long)maxBins
                                                 firstBin:(unsigned long)firstBin   stepSize:(unsigned long)stepSize 
                                                   counts:(unsigned long)counts;
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

