//--------------------------------------------------------
// ORMJDBiasWatcherModel
// Created by Mark  A. Howe on Thursday, Aug 11, 2016
// Code partially generated by the OrcaCodeWizard. Written by Mark A. Howe.
// Copyright (c) 2016 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina  sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark •••Imported Files

@class MajoranaModel;
@class ORiSegHVCard;
@class ORMJDPreAmpModel;

#define kMaxDetectors 140

@interface ORMJDBiasWatcherModel : ORGroup
{
@private
    BOOL docReady;
    MajoranaModel*  mjd;
    int             watchLookup[kMaxDetectors];
    BOOL            watch[kMaxDetectors];
    NSMutableDictionary* hvObjs;
    NSMutableDictionary* preAmpObjs;
}

#pragma mark •••Initialization
- (id)   init;
- (void) dealloc;


#pragma mark •••Accessors
- (BOOL) watch:(int)index;
- (int) numberWatched;
- (int) watchLookup:(int)i;

- (void) setWatch:(int)index value:(BOOL)aFlag;
- (NSString*) detectorName:(int)index;
- (NSString*) detectorName:(int)index useLookUp:(BOOL)useLookUp;
- (NSString*) hvId:(int)index useLookUp:(BOOL)useLookUp;
- (NSString*) hvId:(int)index;
- (NSString*) preAmpId:(int)index;
- (NSString*) preAmpId:(int)index useLookUp:(BOOL)useLookUp;

- (int) numberDetectors;
- (void) objectsChanged:(NSNotification*)aNote;

- (uint32_t) numberPointsInHVPlot:(int)index;
- (uint32_t) numberPointsInHvPlot:(ORiSegHVCard*)anHVCard channel:(int)aChan;
- (int) hvChannel:(int)index;
- (ORiSegHVCard*) hvObj:(int)index;
- (void) hvPlot:(int)index dataIndex:(int)dataIndex x:(double*)xValue y:(double*)yValue;

- (uint32_t) numberPointsInPreAmpPlot:(int)index;
- (uint32_t) numberPointsInPreAmpPlot:(ORMJDPreAmpModel*)aPreAmpCard channel:(int)aChan;
- (int) preAmpChannel:(int)index;
- (ORMJDPreAmpModel*) preAmpObj:(int)index;
- (int) preAmpChannel:(int)index;
- (void) preAmpPlot:(int)index dataIndex:(int)dataIndex x:(double*)xValue y:(double*)yValue;

- (void) pollNow;


//testing routines
- (void) addValueToHV:(int)index value:(float)aValue;

- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORMJDBiasWatcherModelWatchChanged;
extern NSString* ORMJDBiasWatcherForceUpdate;

