//
//  ORManualPlotModel.h
//  Orca
//
//  Created by Mark Howe on Fri Apr 27 2009.
//  Copyright (c) 2009 CENPA, University of Washington. All rights reserved.
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
#define kManualPlotMacol0Keys 3

@class ORDataSet;

@interface ORManualPlotModel : OrcaObject  
{
    int				textSize;
	NSLock*			dataSetLock;
	NSMutableArray*	data;
    BOOL			scheduledForUpdate;
    int				col0Key;
    int				col1Key;
    int				col2Key;
    int				col3Key;
    NSString*		col0Title;
    NSString*		col1Title;
    NSString*		col2Title;
    NSString*		col3Title;
	id				calibration;
	ORDataSet*		fftDataSet;
	NSMutableArray* roiSet;
    NSString*		comment;
}

#pragma mark ***Accessors
- (NSString*) comment;
- (void) setComment:(NSString*)aComment;
- (void) postUpdate;
- (NSString*) col3Title;
- (void) setCol3Title:(NSString*)aCol3Title;
- (NSString*) col2Title;
- (void) setCol2Title:(NSString*)aCol2Title;
- (NSString*) col1Title;
- (void) setCol1Title:(NSString*)aCol1Title;
- (NSString*) col0Title;
- (void) setCol0Title:(NSString*)aCol0Title;
- (int)  col3Key;
- (void) setCol3Key:(int)aCol3Key;
- (int)  col2Key;
- (void) setCol2Key:(int)aCol2Key;
- (int)  col1Key;
- (void) setCol1Key:(int)aCol1Key;
- (int)	 col0Key;
- (void) setCol0Key:(int)aCol0Key;
- (void) addValue1:(float)v1 value2:(float)v2;
- (void) addValue1:(float)v1 value2:(float)v2 value3:(float)v3;
- (void) addValue1:(float)v1 value2:(float)v2 value3:(float)v3 value4:(float)v4;
- (void) setHistogramBins:(int)nBins xLow:(float)xLow xHigh:(float)xHigh;
- (void) fillHistogram:(float)value;
- (void) fillHistogram:(float)value weight:(float)weight;
- (id)   dataAtRow:(int)r column:(int)c;
- (void) clearData;
- (NSString*) fullName;
- (NSString*) commonScriptMethods;

#pragma mark •••Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
- (void) writeDataToFile:(NSString*)aFileName;

#pragma mark •••Data Source Methods
- (void) processResponse:(NSDictionary*)aResponse;
- (unsigned long) numPoints;
- (NSMutableArray*) rois:(int)index;
- (BOOL) dataSet:(int)set index:(unsigned long)index x:(double*)xValue y:(double*)yValue;
@end

extern NSString* ORManualPlotModelCommentChanged;
extern NSString* ORManualPlotModelCol3TitleChanged;
extern NSString* ORManualPlotModelCol2TitleChanged;
extern NSString* ORManualPlotModelCol1TitleChanged;
extern NSString* ORManualPlotModelCol0TitleChanged;
extern NSString* ORManualPlotLock;
extern NSString* ORManualPlotDataChanged;
extern NSString* ORManualPlotModelColKey0Changed;
extern NSString* ORManualPlotModelColKey1Changed;
extern NSString* ORManualPlotModelColKey2Changed;
extern NSString* ORManualPlotModelColKey3Changed;
