//
//  ORnEDMCoilModel.h
//  Orca
//
//  Created by Michael Marino 15 Mar 2012 
//  Copyright © 2002 CENPA, University of Washington. All rights reserved
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

#pragma mark •••Imported Files
#import "OrcaObject.h"
#import "OROrderedObjHolding.h"
#import "Accelerate/Accelerate.h"

//defined here so that length of instvars can depend on
#define MaxNumberOfMagnetometers 60
#define MaxNumberOfChannels 3*MaxNumberOfMagnetometers
#define MaxNumberOfCoils 24
#define MaxCurrent 20.0
#define MaxVoltage 30.0

@interface ORnEDMCoilModel : ORGroup <OROrderedObjHolding> {
    NSMutableDictionary* objMap;
    BOOL isRunning;
    float pollingFrequency;
    float proportionalTerm;
    float integralTerm;
    float feedbackThreshold;
    float regularizationParameter;
    NSTimeInterval realProcessingTime;
    NSUInteger SenNumChannels;
    NSUInteger SenNumCoils;
    int NumberOfChannels;
    int NumberOfCoils;
    BOOL debugRunning;
    BOOL dynamicMode;
    BOOL verbose;
    BOOL postDataToDB;
    NSDate* lastProcessStartDate;
    
    
    NSMutableData* FeedbackMatData;
    NSMutableData* SensitivityMatData;
    NSData*        CurVector;
    NSMutableData* CurrentMemory;
    NSUInteger     CurrentMemorySize;
    
    NSData* FieldTarget;
    NSArray* StartCurrent;
    
    NSMutableArray* listOfADCs;
    NSMutableData*  currentADCValues;
    NSString*       RunComment;
    NSMutableArray* MagnetometerMap;
    NSMutableArray* OrientationMatrix;
    NSMutableArray* ActiveChannelMap;
    NSMutableArray* SensorInfo;
    NSMutableArray* SensorDirectInfo;
    
    NSString* postToPath;
    NSTimeInterval postToDBPeriod;
    
    // For Cache during run
    NSMutableData* _FieldVectorLocal;
    NSMutableData* _PrevCurrentLocal;
    NSMutableData* _CurrentDataLocal;
    NSMutableData* _DCurrentLocal;
}

- (void) setUpImage;
- (void) makeMainController;
- (int) rackNumber;
- (BOOL) isRunning;
- (BOOL) debugRunning;
- (BOOL) dynamicMode;
- (void) setDebugRunning:(BOOL)debug;
- (void) setDynamicMode:(BOOL)dynamic;
- (float) realProcessingTime;
- (float) pollingFrequency;
- (float) proportionalTerm;
- (float) integralTerm;
- (float) feedbackThreshold;
- (float) regularizationParameter;
- (void) setPollingFrequency:(float)aFrequency;
- (void) setProportionalTerm:(float)aValue;
- (void) setIntegralTerm:(float)aValue;
- (void) setFeedbackThreshold:(float)aValue;
- (void) setRegularizationParameter:(float)aValue;
- (void) toggleRunState;
- (void) connectAllPowerSupplies;

- (void) addADC:(id)adc;
- (void) removeADC:(id)adc;
- (NSArray*) listOfADCs;

- (int) numberOfChannels;
- (int) numberOfCoils;
- (int) mappedChannelAtChannel:(int)aChan;
- (int) activeChannelAtChannel:(int)aChan;
- (double) conversionMatrix:(int)channel coil:(int)aCoil;
- (double) sensitivityMatrix:(int)coil channel:(int)aChannel;

- (void) setRunComment:(NSString*)aString;
- (void) initializeMagnetometerMapWithPlistFile:(NSString*)plistFile;
- (void) initializeOrientationMatrixWithPlistFile:(NSString*)plistFile;
- (void) initializeSensitivityMatrixWithPlistFile:(NSString*)plistFile;
- (void) initializeActiveChannelMapWithPlistFile:(NSString*)plistFile;
- (void) initializeSensorInfoWithPlistFile:(NSString*)plistFile;

- (void) saveFeedbackInPlistFile:(NSString*)plistFile;
- (void) saveCurrentFieldInPlistFile:(NSString*)plistFile;
- (void) loadTargetFieldWithPlistFile:(NSString*)plistFile;
- (void) setTargetFieldToZero;
- (void) setTargetField;

- (void) saveCurrentStartCurrentInPlistFile:(NSString*)plistFile;
- (void) loadStartCurrentWithPlistFile:(NSString*)plistFile;
- (void) setStartCurrentToZero;
- (void) startWithStartCurrent;

- (void) resetConversionMatrix;
- (void) resetMagnetometerMap;
- (void) resetOrientationMatrix;
- (void) resetSensitivityMatrix;
- (void) resetActiveChannelMap;
- (void) resetSensorInfo;

- (void) buildFeedback;
- (void) saveFeedbackInPlistFile:(NSString*)plistFile;
- (void) buildReplaceFeedback;

- (NSString*) runComment;
- (NSArray*) magnetometerMap;
- (NSArray*) orientationMatrix;
- (NSData*)  feedbackMatData;
- (NSData*)  sensitivityMatData;
- (NSArray*) activeChannelMap;
- (NSArray*) sensorInfo;
- (NSArray*) sensorDirectInfo;

- (void) setPostToPath:(NSString*)aPath;
- (NSString*) postToPath;

- (void) setPostDataToDB:(BOOL)postData;
- (BOOL) postDataToDB;
- (void) setPostDataToDBPeriod:(NSTimeInterval)period;
- (NSTimeInterval) postDataToDBPeriod;

- (BOOL) verbose;
- (BOOL) withStartCurrent;
- (void) setVerbose:(BOOL)aVerb;

- (void) initializeForRunning;
- (void) cleanupForRunning;

#pragma mark •••Held objects
- (int) magnetometerChannels;
- (int) coilChannels;

- (void) enableOutput:(BOOL)enab atCoil:(int)coil;
- (void) setVoltage:(double)volt atCoil:(int)coil;
- (void) setCurrent:(double)current atCoil:(int)coil;
- (double) readBackSetCurrentAtCoil:(int)coil;
- (double) getCurrent:(int)coil;
- (double) readBackSetVoltageAtCoil:(int)coil;
- (double) fieldAtMagnetometer:(int)magn;
- (double) targetFieldAtMagnetometer:(int)magn;
- (double) startCurrentAtCoil:(int)coil;
- (double) xPositionAtChannel:(int)magn;
- (double) yPositionAtChannel:(int)magn;
- (double) zPositionAtChannel:(int)magn;
- (NSString*) fieldDirectionAtChannel:(int)magn;

#pragma mark •••ORGroup
- (void) objectCountChanged;

#pragma mark •••OROrderedObjHolding Protocol
- (int) maxNumberOfObjects;
- (int) objWidth;
- (int) groupSeparation;
- (NSString*) nameForSlot:(int)aSlot;
- (NSRange) legalSlotsForObj:(id)anObj;
- (int) slotAtPoint:(NSPoint)aPoint;
- (NSPoint) pointForSlot:(int)aSlot;
- (void) place:(id)anObj intoSlot:(int)aSlot;
- (int) slotForObj:(id)anObj;
- (int) numberSlotsNeededFor:(id)anObj;

#pragma mark •••Holding ADCs
- (NSArray*) validObjects;

@end

extern NSString* ORnEDMCoilPollingActivityChanged;
extern NSString* ORnEDMCoilPollingFrequencyChanged;
extern NSString* ORnEDMCoilProportionalTermChanged;
extern NSString* ORnEDMCoilIntegralTermChanged;
extern NSString* ORnEDMCoilFeedbackThresholdChanged;
extern NSString* ORnEDMCoilRegularizationParameterChanged;
extern NSString* ORnEDMCoilRunCommentChanged;
extern NSString* ORnEDMCoilADCListChanged;
extern NSString* ORnEDMCoilHWMapChanged;
extern NSString* ORnEDMCoilActiveChannelMapChanged;
extern NSString* ORnEDMCoilSensitivityMapChanged;
extern NSString* ORnEDMCoilSensorInfoChanged;
extern NSString* ORnEDMCoilDebugRunningHasChanged;
extern NSString* ORnEDMCoilDynamicModeHasChanged;
extern NSString* ORnEDMCoilVerboseHasChanged;
extern NSString* ORnEDMCoilRealProcessTimeHasChanged;
extern NSString* ORnEDMCoilTargetFieldHasChanged;
extern NSString* ORnEDMCoilStartCurrentHasChanged;
extern NSString* ORnEDMCoilPostToPathHasChanged;
extern NSString* ORnEDMCoilPostDataToDBHasChanged;
extern NSString* ORnEDMCoilPostDataToDBPeriodHasChanged;
