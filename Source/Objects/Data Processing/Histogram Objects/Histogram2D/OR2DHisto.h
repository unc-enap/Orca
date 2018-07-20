//
//  OR2DHisto.h
//  Orca
//
//  Created by Mark Howe on Thurs Dec 23 2004.
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
@class OR2DHistoController;

@interface OR2DHisto : ORDataSetModel  {
    uint32_t       dataId;
    unsigned short      numberBinsPerSide;
    unsigned short      minX,maxX,minY,maxY;
    NSMutableData*     histogram; //actually a 2D array stuffed into a 1D
	NSMutableArray*		rois;
}


#pragma mark ¥¥¥Accessors
- (uint32_t) dataId;
- (void) setDataId: (uint32_t) DataId;
- (unsigned short) numberBinsPerSide;
- (void) setNumberBinsPerSide:(unsigned short)bins;
- (uint32_t)valueX:(unsigned short)aXBin y:(unsigned short)aYBin;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;
- (NSMutableArray*) rois;

#pragma mark ¥¥¥Data Management
- (NSDictionary*) dataRecordDescription;
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) packageData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo keys:(NSMutableArray*)aKeyArray;
- (void) mergeHistogram:(uint32_t*)ptr numValues:(uint32_t)numBins;
- (void) load:(uint32_t*)ptr numValues:(uint32_t)num;
- (void) histogramX:(unsigned short)aXValue y:(unsigned short)aYValue;
- (void) loadX:(unsigned short)aXValue y:(unsigned short)aYValue z:(unsigned short)aZValue;
- (void) sumX:(unsigned short)aXValue y:(unsigned short)aYValue z:(unsigned short)aZValue;
- (void) clear;

#pragma mark ¥¥¥Writing Data
- (void) writeDataToFile:(FILE*)aFile;

#pragma mark ¥¥¥Data Source Methods
- (id)   name;
- (NSData*) getDataSetAndNumBinsPerSize:(unsigned short*)value;
- (void) getXMin:(unsigned short*)aMinX xMax:(unsigned short*)aMaxX yMin:(unsigned short*)aMinY yMax:(unsigned short*)aMaxY;
- (NSData*) plotter:(id)aPlotter numberBinsPerSide:(unsigned short*)xValue;
- (void) plotter:(id)aPlotter xMin:(unsigned short*)aMinX xMax:(unsigned short*)aMaxX yMin:(unsigned short*)aMinY yMax:(unsigned short*)aMaxY;
@end


