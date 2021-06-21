//  Orca
//  ORFlashCamRunModel.h
//
//  Created by Tom Caldwell on Monday Dec 26,2019
//  Copyright (c) 2019 University of North Carolina. All rights reserved.
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

#import "OrcaObject.h"
#import "ORTaskSequence.h"
#import "ORConnector.h"

#define kFlashCamMaxEthInterfaces 4

@interface ORFlashCamRunModel : OrcaObject
{
    @private
    NSString* ipAddress;
    NSString* username;
    NSMutableArray* ethInterface;
    NSString* ethType;
    int maxPayload;
    int eventBuffer;
    int phaseAdjust;
    int baselineSlew;
    int integratorLen;
    int eventSamples;
    int traceType;
    float pileupRejection;
    float logTime;
    bool gpsEnabled;
    bool includeBaseline;
    NSString* additionalFlags;
    NSString* overrideCmd;
    bool runOverride;
    NSString* remoteDataPath;
    NSString* remoteFilename;
    unsigned int runNumber;
    unsigned int runCount;
    unsigned int runLength;
    bool runUpdate;
    ORPingTask* pingTask;
    bool pingSuccess;
    ORTaskSequence* runTasks;
    bool runKilled;
}

#pragma mark •••Initialization
- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;

#pragma mark •••Accessors
- (NSString*) ipAddress;
- (int) ethInterfaceCount;
- (int) indexOfInterface:(NSString*)interface;
- (NSString*) ethInterfaceAtIndex:(int)index;
- (NSString*) ethType;
- (int) maxPayload;
- (int) eventBuffer;
- (int) phaseAdjust;
- (int) baselineSlew;
- (int) integratorLen;
- (int) eventSamples;
- (int) traceType;
- (float) pileupRejection;
- (float) logTime;
- (bool) gpsEnabled;
- (bool) includeBaseline;
- (NSString*) additionalFlags;
- (NSString*) overrideCmd;
- (bool) runOverride;
- (NSString*) username;
- (NSString*) remoteDataPath;
- (NSString*) remoteFilename;
- (unsigned int) runNumber;
- (unsigned int) runCount;
- (unsigned int) runLength;
- (bool) runUpdate;
- (bool) pingSuccess;

- (void) setIPAddress:(NSString*)ip;
- (void) setUsername:(NSString*)user;
- (void) addEthInterface:(NSString*)eth;
- (void) setEthInterface:(NSString*)eth atIndex:(int)index;
- (void) removeEthInterface:(NSString*)eth;
- (void) removeEthInterfaceAtIndex:(int)index;
- (void) setEthType:(NSString*)etype;
- (void) setMaxPayload:(int)payload;
- (void) setEventBuffer:(int)buffer;
- (void) setPhaseAdjust:(int)phase;
- (void) setBaselineSlew:(int)slew;
- (void) setIntegratorLen:(int)len;
- (void) setEventSamples:(int)samples;
- (void) setTraceType:(int)ttype;
- (void) setPileupRejection:(float)rej;
- (void) setLogTime:(float)time;
- (void) setGPSEnabled:(bool)enable;
- (void) setIncludeBaseline:(bool)inc;
- (void) setAdditionalFlags:(NSString*)flags;
- (void) setOverrideCmd:(NSString*)cmd;
- (void) setRunOverride:(bool)runover;
- (void) setRemoteDataPath:(NSString*)path;
- (void) setRemoteFilename:(NSString*)fname;
- (void) setRunNumber:(unsigned int)run;
- (void) setRunCount:(unsigned int)count;
- (void) setRunLength:(unsigned int)length;
- (void) setRunUpdate:(bool)update;

#pragma mark •••Commands
- (void) sendPing:(bool)verbose;
- (bool) pingRunning;
- (void) taskFinished:(id)task;
- (void) tasksCompleted:(id)sender;
- (void) taskData:(NSDictionary*)taskData;
- (NSMutableArray*) runFlags;
- (NSMutableArray*) connectedObjects:(NSString*)cname;
- (void) startRun;
- (void) startRunAfterPing;
- (void) killRun;

#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end

#pragma mark •••Externals
extern NSString* ORFlashCamRunModelIPAddressChanged;
extern NSString* ORFlashCamRunModelUsernameChanged;
extern NSString* ORFlashCamRunModelEthInterfaceChanged;
extern NSString* ORFlashCamRunModelEthInterfaceAdded;
extern NSString* ORFlashCamRunModelEthInterfaceRemoved;
extern NSString* ORFlashCamRunModelEthTypeChanged;
extern NSString* ORFlashCamRunModelMaxPayloadChanged;
extern NSString* ORFlashCamRunModelEventBufferChanged;
extern NSString* ORFlashCamRunModelPhaseAdjustChanged;
extern NSString* ORFlashCamRunModelBaselineSlewChanged;
extern NSString* ORFlashCamRunModelIntegratorLenChanged;
extern NSString* ORFlashCamRunModelEventSamplesChanged;
extern NSString* ORFlashCamRunModelTraceTypeChanged;
extern NSString* ORFlashCamRunModelPileupRejectionChanged;
extern NSString* ORFlashCamRunModelLogTimeChanged;
extern NSString* ORFlashCamRunModelGPSEnabledChanged;
extern NSString* ORFlashCamRunModelIncludeBaselineChanged;
extern NSString* ORFlashCamRunModelAdditionalFlagsChanged;
extern NSString* ORFlashCamRunModelOverrideCmdChanged;
extern NSString* ORFlashCamRunModelRunOverrideChanged;
extern NSString* ORFlashCamRunModelRemoteDataPathChanged;
extern NSString* ORFlashCamRunModelRemoteFilenameChanged;
extern NSString* ORFlashCamRunModelRunNumberChanged;
extern NSString* ORFlashCamRunModelRunCountChanged;
extern NSString* ORFlashCamRunModelRunLengthChanged;
extern NSString* ORFlashCamRunModelRunUpdateChanged;
extern NSString* ORFlashCamRunModelPingStart;
extern NSString* ORFlashCamRunModelPingEnd;
extern NSString* ORFlashCamRunModelRunInProgress;
extern NSString* ORFlashCamRunModelRunEnded;
