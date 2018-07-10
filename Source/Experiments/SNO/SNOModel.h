//
//  SNOModel.h
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


#pragma mark ¥¥¥Imported Files
#import "ORDataTaker.h"
#import "SNOController.h"
#import "SNOMonitoredHardware.h"

@class ORDataPacket;
@class ORTimeRate;

@interface SNOModel :  OrcaObject
{
    @private
        NSDictionary*       xAttributes;
        NSDictionary*       yAttributes;	 

	NSMutableArray *tableEntries;
    NSMutableDictionary *slowControlMap;
	int slowControlPollingState;
	int xl3PollingState;
	BOOL pollXl3;
	BOOL pollSlowControl;
    BOOL isPlottingGraph;
    BOOL isPollingXl3TotalRate;
	NSString *slowControlMonitorStatusString;
    NSString *runType;
    NSString *iosUsername;
    NSString *iosPasswd;
	NSColor *slowControlMonitorStatusStringColor;
    NSArray *iosCards;
    NSArray *ioServers;
    ORTimeRate *parameterRate;
    ORTimeRate *totalDataRate;
//	SNOMonitoredHardware *db;
}

#pragma mark ¥¥¥Notifications
- (void) runStatusChanged:(NSNotification*)aNote;

#pragma mark ¥¥¥Accessors
- (NSDictionary*)   xAttributes;
- (void) setYAttributes:(NSDictionary*)someAttributes;
- (NSDictionary*)   yAttributes;
- (void) setXAttributes:(NSDictionary*)someAttributes;
- (void) runAboutToStart:(NSNotification*)aNote;
- (void) runEnded:(NSNotification*)aNote;
- (void) getRunTypesFromOrcaDB:(NSMutableArray *)runTypeList;
- (void) setRunTypeName:(NSString *)aType;
- (NSString *) getRunType;
- (ORTimeRate *) parameterRate;
- (ORTimeRate *) totalDataRate;
- (BOOL) isPlottingGraph;
//- (void) writeNewRunTypeDocument:(NSString *)runNotes;
//- (NSString *) getSourceDocId;

//monitor
- (void) getDataFromMorca;
- (void) getXl3Rates;
- (void) setXl3Polling:(int)aState;
- (void) startXl3Polling;
- (void) stopXl3Polling;
- (void) collectSelectedVariable;
- (void) releaseParameterRate;
- (void) startTotalXL3RatePoll;
- (void) stopTotalXL3RatePoll;
- (float) totalRate;

//slow control
- (void) forwardPorts;
- (void) connectToIOServer;
- (void) setIoserverUsername:(NSString*)aString;
- (void) setIoserverPasswd:(NSString*)aString;
- (void) setSlowControlPolling:(int)aState;
- (void) startSlowControlPolling;
- (void) stopSlowControlPolling;
- (void) setSlowControlParameterThresholds;
- (void) setSlowControlChannelGain;
- (void) enableSlowControlParameter;
- (void) setSlowControlMapping; //obsolete - has to be updated
- (void) readAllVoltagesFromIOServers;
- (SNOSlowControl*) getSlowControlVariable:(int)index;
- (void) setSlowControlMonitorStatusString:(NSString *)aString;
- (void) setSlowControlMonitorStatusStringColor:(NSColor *)aColor;
- (NSString*) getSlowControlMonitorStatusString;
- (NSColor*) getSlowControlMonitorStatusStringColor;

//ORTaskSequence delegate methods
- (void) tasksCompleted:(id)sender;
//connection delegate methods
- (void) getSlowControlMap:(NSString *)aString;
- (void) getIOSCards:(NSString *)aString;
- (void) getIOS:(NSString *)aString;
- (void) getAllChannelValues:(NSString *)aString withKey:(NSString*)aKey;
- (void) getAllConfig:(NSString *)aString withKey:(NSString*)aKey;
- (void) updateIOSChannelThresholds:(NSString *) aString ofChannel:(NSString *)aKey;
@end

extern NSString* ORSNOChartXChangedNotification;
extern NSString* ORSNOChartYChangedNotification;
extern NSString* slowControlTableChanged;
extern NSString* slowControlConnectionStatusChanged;
extern NSString* totalRatePlotChanged;

