//
//  SNODetectorView.h
//  Orca
//
//  Created by H S  Wan Chan Tseung on 11/18/11.
//  Copyright (c) 2011 CENPA, University of Washington. All rights reserved.
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

@class ORColorScale;
#import "ORGenericView.h"
#import "SNOMonitoredHardware.h"
#import "Sno_Monitor_Adcs.h"
#define highlightLineWidth			3
#define kOnlineTubeDisplay			0
#define kTubeTypeDisplay			1
#define kPedestalsDisplay			2
#define kThresholdsDisplay			3
#define kVBalsLoDisplay				4
#define kVBalsHiDisplay				5
#define kCmosRatesDisplay			6
#define kHvOnDisplay				7
#define kRelaysDisplay				8
#define kThreshMaxDisplay			9
#define kSequencerDisplay			10
#define k20nsTriggerDisplay			11
#define k100nsTriggerDisplay		12
#define kCmosReadDisplay			13
#define kQllDisplay					14
#define kTempDisplay				15
#define kFifoDisplay				16
#define kBaseCurrentDisplay			17
#define kCheckerMismatchesDisplay	18
#define kRatesDisplay				19
#define kFECVoltagesDisplay         20
#define kXL3VoltagesDisplay         21
#define kTubeSelectionMode  0
#define kCardSelectionMode  1
#define kCrateSelectionMode 2
#define kNumXL3Voltages 7

@interface SNODetectorView : ORGenericView
{	
	IBOutlet ORColorScale*  detectorColorBar;
	NSAttributedString* detectorTitle;
	NSMutableString* selectionString;
	NSMutableAttributedString* globalStatsString;
	int selectionMode;
	@private
    NSMutableDictionary* colorBarAxisAttributes;
    NSMutableArray* axisChanges;
	NSMutableArray *crateRectsInCrateView;
	NSMutableArray *cardRectsInCrateView;
	NSMutableArray *channelRectsInCrateView;
	NSMutableArray *channelRectsInPSUPView;
    NSMutableArray *voltageRectsInCrateView;
    NSMutableArray *xl3VoltageRectsInCrateView;
    BOOL pollingInProgress;
	BOOL pickPSUPView;
	int parameterToDisplay;
    int previousParameterDisplayed;
	int selectedCrate;
	int selectedCard;
	int selectedChannel;
    int selectedVoltage;
    int selectedXL3Voltage;
	int numTubesOnline;
	int numUnknownTubes;
	int numOwlTubes;
	int numLowGainTubes;
	int numButtTubes;
	int numNeckTubes;
	SNOMonitoredHardware *db;
}

- (void) setViewType:(BOOL)aViewType;
- (void) setParameterToDisplay:(int)aParameter;
- (void) setSelectionMode:(int)aMode;
- (void) updateSNODetectorView;
- (void) updateAxes;
- (void) resetStats;
- (void) iniAxisChanges;
- (void) getRectPositions;
- (NSColor *) getPMTColor:(int)aCrate card:(int)aCard pmt:(int)aPMT;
- (NSColor *) getFECVoltageColor:(int)aCrate card:(int)aCard voltage:(int)aVoltage;
- (NSColor *) getXL3VoltageColor:(int)aCrate voltage:(int)aVoltage;
- (NSColor *) getCrateColor:(int) aCrate;
- (NSColor *) getCardColor:(int) aCrate card:(int)aCard;
- (void) formatGlobalStatsString;
//- (void) formatDetectorTitleString;
- (void) setDetectorTitleString:(NSString *)aString;
- (NSMutableString *) selectionString;
- (NSString *) getCurrentDisplayValue;
- (NSMutableDictionary*) colorBarAxisAttributes;
- (void) setColorBarAxisAttributes:(NSMutableDictionary*)newColorBarAttributes;
- (void) setColorAxisChanged:(BOOL)aBOOL;
- (void) setPollingInProgress:(BOOL)aBOOL;


@end

extern NSString* selectionStringChanged;
extern NSString* newValueAvailable;
extern NSString* plotButtonDisabled;