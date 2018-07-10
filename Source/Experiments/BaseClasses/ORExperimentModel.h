//
//  ORExperimentModel.h
//  Orca
//
//  Created by Mark Howe on 12/18/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
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

@class ORSegmentGroup;
@class ORAlarm;

@interface ORExperimentModel : ORGroup {
	NSMutableArray* segmentGroups;
	int				hardwareCheck;
	int				cardCheck;
	NSDate*			captureDate;
	NSMutableArray* problemArray;
	ORAlarm*		failedHardwareCheckAlarm;
	ORAlarm*		failedCardCheckAlarm;
	BOOL			replayMode;
	NSString*		selectionString;
	BOOL			somethingSelected;
	int				displayType;
	BOOL			scheduledToHistogram;
    BOOL            showNames;
    BOOL            ignoreHWChecks;
    int             colorScaleType;
    NSColor*        customColor1;
    NSColor*        customColor2;
}

- (id) init;
- (void) registerNotificationObservers;
- (NSMutableArray*) setupMapEntries:(int)index;
- (void) awakeAfterDocumentLoaded;
- (void) runStatusChanged:(NSNotification*)aNote;

#pragma mark •••Accessors
- (BOOL) ignoreHWChecks;
- (void) setIgnoreHWChecks:(BOOL)aIgnoreHWChecks;
- (BOOL) showNames;
- (void) setShowNames:(BOOL)aShowNames;
- (NSColor*) customColor1;
- (void) setCustomColor1:(NSColor*)aType;
- (NSColor*) customColor2;
- (void) setCustomColor2:(NSColor*)aType;

- (int) colorScaleType;
- (void) setColorScaleType:(int)aType;
- (int) displayType;
- (void) setDisplayType:(int)aDisplayType;
- (NSString*) selectionString;
- (void) setSelectionString:(NSString*)aSelectionString;
- (BOOL) replayMode;
- (void) setReplayMode:(BOOL)aReplayMode;
- (void) collectRates;
- (NSDate *) captureDate;
- (void) setCaptureDate: (NSDate *) aCaptureDate;
- (int) hardwareCheck;
- (void) setHardwareCheck: (int) HardwareCheck;
- (int) cardCheck;
- (void) setCardCheck: (int) cardCheck;
- (void) setCardCheckFailed;
- (void) setHardwareCheckFailed;
- (int) numberOfSegmentGroups;
- (ORSegmentGroup*) segmentGroup:(int)aSet;
- (BOOL) somethingSelected;
- (void) setSomethingSelected:(BOOL)aFlag;
- (void) clearTotalCounts;
- (NSString*) reformatSelectionString:(NSString*)aString forSet:(int)aSet;
- (NSString*) getPartStartingWith:(NSString*)aLable parts:(NSArray*)parts;

- (int) numberSegmentsInGroup:(int)aGroup;
- (NSMutableData*) thresholdDataForSet:(int)aSet;
- (NSMutableData*) gainDataForSet:(int)aSet;
- (NSMutableData*) rateDataForSet:(int)aSet;
- (NSMutableData*) totalCountDataForSet:(int)aSet;
- (NSString*) thresholdDataAsStringForSet:(int)aSet;
- (NSString*) gainDataAsStringForSet:(int)aSet;
- (NSString*) rateDataAsStringForSet:(int)aSet;
- (NSString*) totalCountDataAsStringForSet:(int)aSet;

#pragma mark •••Convience Methods
- (void) clearAlarm:(NSString*)aName;
- (void) postAlarm:(NSString*)aName;
- (void) postAlarm:(NSString*)aName severity:(int)aSeverity;
- (void) postAlarm:(NSString*)aName severity:(int)aSeverity reason:(NSString*)aReason;

#pragma mark •••Work Methods
- (void) compileHistograms;
- (BOOL) preRunChecks:(BOOL) skipChecks;
- (BOOL) preRunChecks;
- (void) printProblemSummary;
- (NSString*) crateKey:(NSDictionary*)aDicionary;

#pragma mark •••Subclass Responsibility
- (void) makeSegmentGroups;
- (int)  maxNumSegments;
- (void) handleOldPrimaryMapFormats:(NSString*)aPath;
- (void) readAuxFiles:(NSString*)aPath; //subclasses can override
- (void) saveAuxFiles:(NSString*)aPath; //subclasses can override
- (NSString*) validateHWMapPath:(NSString*)aPath;//subclasses can override
- (NSString*) mapFileHeader:(int)tag;//subclasses can override
- (void) setupSegmentIds;

#pragma mark •••Group Methods
- (void) addGroup:(ORSegmentGroup*)aGroup;
- (void) selectedSet:(int)aSet segment:(int)index;
- (void) registerForRates;
- (void) collectRatesFromAllGroups;
- (ORSegmentGroup*) segmentGroup:(int)aSet;
- (void) showDialogForSet:(int)setIndex segment:(int)index;
- (void) showDataSetForSet:(int)aSet segment:(int)index;
- (void) setSegmentErrorClassName:(NSString*)aClassName card:(int)card channel:(int)channel;
- (void) histogram;
- (void) initHardware;
- (NSString*) dataSetNameGroup:(int)aGroup segment:(int)index;
- (void) setCrateIndex:(int)aValue;
- (void) setCardIndex:(int)aValue;
- (void) setChannelIndex:(int)aValue;
- (void) postCouchDBRecord;

#pragma mark •••Specific Dialog Lock Methods
- (NSString*) experimentMapLock;
- (NSString*) experimentDetectorLock;
- (NSString*) experimentDetailsLock;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (NSMutableDictionary*) captureState;
- (NSString*) capturePListsFile;

@end

extern NSString* ORExperimentModelIgnoreHWChecksChanged;
extern NSString* ORExperimentModelShowNamesChanged;
extern NSString* ExperimentModelDisplayTypeChanged;
extern NSString* ExperimentModelSelectionStringChanged;
extern NSString* ExperimentHardwareCheckChangedNotification;
extern NSString* ExperimentCardCheckChangedNotification;
extern NSString* ExperimentCaptureDateChangedNotification;
extern NSString* ExperimentDisplayUpdatedNeeded;
extern NSString* ExperimentCollectedRates;
extern NSString* ExperimentDisplayHistogramsUpdated;
extern NSString* ExperimentModelSelectionChanged;
extern NSString* ExperimentModelColorScaleTypeChanged;
extern NSString* ExperimentModelCustomColor1Changed;
extern NSString* ExperimentModelCustomColor2Changed;


