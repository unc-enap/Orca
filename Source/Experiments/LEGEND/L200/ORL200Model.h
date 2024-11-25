//  Orca
//  ORL200Model.h
//
//  Created by Tom Caldwell on Monday Mar 21, 2022
//  Copyright (c) 2022 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina Department of Physics and Astrophysics
//sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import "ORExperimentModel.h"
#import "ORInFluxDBModel.h"
#import "ORHistoModel.h"

@class ORRunModel;
@class ORLNGSSlowControlsModel;
@class ORDataFileModel;

#define kL200DetectorStrings  12
#define kL200MaxDetsPerString 14
#define kL200SiPMInnerChans   18
#define kL200SiPMOuterChans   40
#define kL200MuonVetoChans    66
#define kL200MaxAuxChans       6
#define kL200MaxCC4s          24*7
#define kL200MaxADCCards      14*4

@interface ORL200Model : ORExperimentModel
{
    int      viewType;
    uint32_t runType;
    ORInFluxDBModel* influxDB;
    ORRunModel*      rc;
    ORLNGSSlowControlsModel* slowControls;
    int  influxIndex;
    BOOL linked;
    bool updateDataFilePaths;
    //----------------------
    int dataPeriod;
    int dataCycle;
    int lastDataCycle;
    int dataType;
    int sourcePosCount;
    
    NSString* customType;
    NSString* l200FileName;
    NSString* metaInfo;
    NSString* metaError;
    NSString* metaFolder;
    NSMutableDictionary* metaDataDict;
    NSArray* lastSourceArray;

}

#pragma mark •••Accessors
- (int)  viewType;
- (void) getRunType:(ORRunModel*)rc;

- (void) setViewType:(int)type;
- (void) setDetectorStringPositions;
- (void) setSiPMPositions;
- (void) setPMTPositions;
- (void) setAuxChanPositions;
- (void) findInFluxDB;
- (void) findSlowControls;
- (void) findRunControl;
- (void) findObjects:(NSNotification*)aNote;
- (void) runTypeChanged:(NSNotification*) aNote;
- (void) dataFileWritten:(NSNotification*) aNote;
- (void) updateDataFilePaths:(NSNotification*)aNote;

- (void) runStarted:(NSNotification*) aNote;
- (void) runStopped:(NSNotification*) aNote;
//----------------------
- (int)       dataPeriod;
- (void)      setDataPeriod:(int)aValue;
- (int)       dataCycle;
- (void)      setDataCycle:(int)aValue;
- (int)       dataType;
- (void)      setDataType:(int)aValue;
- (NSString*) customType;
- (void)      setCustomType:(NSString*)aType;
- (NSString*) l200FileName;
- (void)      setL200FileName:(NSString*)s;
- (NSString*) metaInfo;
- (void)      setMetaInfo:(NSString*)s;
- (NSString*) metaError;
- (void)      setMetaError:(NSString*)s;
- (NSString*) getDataType;

#pragma mark •••Segment Group Methods
- (void) showDataSet:(NSString*)name forSet:(int)aSet segment:(int)index;
- (NSString*) objectNameForCrate:(NSString*)crateName andCard:(NSString*)cardName;
- (BOOL) validateDetector:(int)index;
- (BOOL) validateSiPM:(int)index;
- (BOOL) validatePMT:(int)index;
- (BOOL) validateAuxChan:(int)index;
- (BOOL) validateCC4:(int)index;
- (BOOL) validateADC:(int)index;
- (NSString*) valueForLabel:(NSString*)label fromParts:(NSArray*)parts;

#pragma mark •••Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark •••MetaInfo routines
- (void) readMetaDict;
- (void) storeMetaDict;
- (void) finalizeMetaInfo;
- (void) addRunToMetaDict:(NSString*)dataFile;

@end

extern NSString* ORL200ModelViewTypeChanged;
extern NSString* ORL200ModelDataCycleChanged;
extern NSString* ORL200ModelDataPeriodChanged;
extern NSString* ORL200ModelDataTypeChanged;
extern NSString* ORL200ModelCustomTypeChanged;
extern NSString* ORL200ModelL200FileNameChanged;
extern NSString* ORL200ModelMetaInfoChanged;
extern NSString* ORL200ModelMetaErrorChanged;

@interface ORL200HeaderRecordID : NSObject
- (NSString*) fullID;
@end
