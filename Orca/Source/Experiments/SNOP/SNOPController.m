//
//  SNOPController.m
//  Orca
//
//  Created by Mark Howe on Tue Apr 20, 2010.
//  Copyright (c) 2010  University of North Carolina. All rights reserved.
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
#import "SNOPController.h"
#import "SNOPModel.h"
#import "ORColorScale.h"
#import "ORAxis.h"
#import "ORDetectorSegment.h"
#import "ORXL3Model.h"
#import "ORSNOCrateModel.h"
#import "ELLIEModel.h"
#import "ORCouchDB.h"
#import "ORRunModel.h"
#import "ORMTC_Constants.h"
#import "ORMTCModel.h"
#import "SNOP_Run_Constants.h"
#import "SNOCaenModel.h"
#import "TUBiiModel.h"
#import "RunTypeWordBits.hh"
#import "ECARun.h"
#import "NHitMonitor.h"

NSString* ORSNOPRequestHVStatus = @"ORSNOPRequestHVStatus";
NSString* ORRunWaitFinished = @"ORRunWaitFinished";

#define UNITS_UNDECIDED 0
#define UNITS_RAW       1
#define UNITS_CONVERTED 2

// This holds the map between thresholds as ordered by the
// window and as indexed by the MTC model
const int view_model_map[10] = {
    MTC_N100_HI_THRESHOLD_INDEX,
    MTC_N100_MED_THRESHOLD_INDEX,
    MTC_N100_LO_THRESHOLD_INDEX,
    MTC_N20_THRESHOLD_INDEX,
    MTC_N20LB_THRESHOLD_INDEX,
    MTC_OWLN_THRESHOLD_INDEX,
    MTC_ESUMH_THRESHOLD_INDEX,
    MTC_ESUML_THRESHOLD_INDEX,
    MTC_OWLEHI_THRESHOLD_INDEX,
    MTC_OWLELO_THRESHOLD_INDEX};

// The following defines the map between view ordering of triggers and gt mask ordering
const int view_mask_map[10] = {2,1,0,3,4,7,6,5,9,8};

@implementation SNOPController

@synthesize
tellieStandardSequenceFlag,
amellieStandardSequenceFlag,
tellieFireSettings,
amellieFireSettings,
smellieRunFileList = _smellieRunFileList,
tellieRunFileList = _tellieRunFileList,
amellieRunFileList = _amellieRunFileList,
smellieRunFile,
tellieRunFile,
amellieRunFile,
snopBlueColor,
snopRedColor,
snopOrangeColor,
snopBlackColor,
snopGrayColor,
snopGreenColor;

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"SNOP"];

    hvMask = 0;
    doggy_icon = [[RunStatusIcon alloc] init];
    [self initializeUnits];
    return self;

}
- (void) dealloc
{
    [snopBlueColor release];
    [snopGreenColor release];
    [snopOrangeColor release];
    [snopRedColor release];
    [snopBlackColor release];
    [snopGrayColor release];
    [doggy_icon stop_animation];
    [doggy_icon release];
    [smellieRunFile release];
    [tellieRunFile release];
    [_smellieRunFileList release];
    [_tellieRunFileList release];
    [tellieFireSettings release];
    [amellieFireSettings release];
    [amellieRunFile release];
    [_amellieRunFileList release];
    waitingForBuffersAlert = nil;
    [super dealloc];
}

- (IBAction) orcaDBTestAction:(id)sender {
    [[NSWorkspace sharedWorkspace]
     openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%@@%@:%d",
                                   [model orcaDBUserName], [model orcaDBPassword],
                                   [model orcaDBIPAddress], [model orcaDBPort]]]];
}

- (IBAction) testMTCServer:(id)sender
{
    int port = [mtcPort intValue];
    NSString *host = [mtcHost stringValue];
    
    RedisClient *r = [[RedisClient alloc] initWithHostName:host withPort:port];
    
    @try {
        [r connect];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor], @"failed to connect: %@\n", [e reason]);
        [r release];
        return;
    }
    
    [r release];
    
    NSLog(@"connected ok!\n");
}

- (IBAction) testXL3Server:(id)sender
{
    int port = [xl3Port intValue];
    NSString *host = [xl3Host stringValue];
    
    RedisClient *r = [[RedisClient alloc] initWithHostName:host withPort:port];
    
    @try {
        [r connect];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor], @"failed to connect: %@\n", [e reason]);
        [r release];
        return;
    }
    
    [r release];
    
    NSLog(@"connected ok!\n");
}

- (IBAction) testDataServer:(id)sender
{
    int port = [dataPort intValue];
    NSString *host = [dataHost stringValue];
    
    RedisClient *r = [[RedisClient alloc] initWithHostName:host withPort:port];
    
    @try {
        [r connect];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor], @"failed to connect: %@\n", [e reason]);
        [r release];
        return;
    }
    
    [r release];
    
    NSLog(@"connected ok!\n");
}

- (IBAction) testLogServer:(id)sender
{
    int port = [logPort intValue];
    NSString *host = [logHost stringValue];
    
    RedisClient *r = [[RedisClient alloc] initWithHostName:host withPort:port];
    
    @try {
        [r connect];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor], @"failed to connect: %@\n", [e reason]);
        [r release];
        return;
    }
    
    [r release];
    
    NSLog(@"connected ok!\n");
}

- (IBAction) settingsChanged:(id)sender {
    /* Settings tab changed. Set the model variables in SNOPModel. */
    [model setMTCPort:[mtcPort intValue]];
    [model setMTCHost:[mtcHost stringValue]];
    
    [model setXL3Port:[xl3Port intValue]];
    [model setXL3Host:[xl3Host stringValue]];
    
    [model setDataServerPort:[dataPort intValue]];
    [model setDataServerHost:[dataHost stringValue]];
    
    [model setLogServerPort:[logPort intValue]];
    [model setLogServerHost:[logHost stringValue]];
}

- (void) updateSettings: (NSNotification *) aNote
{
    [mtcHost setStringValue:[model mtcHost]];
    [mtcPort setIntValue:[model mtcPort]];
    
    [xl3Host setStringValue:[model xl3Host]];
    [xl3Port setIntValue:[model xl3Port]];
    
    [dataHost setStringValue:[model dataHost]];
    [dataPort setIntValue:[model dataPort]];
    
    [logHost setStringValue:[model logHost]];
    [logPort setIntValue:[model logPort]];
}

-(void)windowDidLoad
{

}

- (NSString*) defaultPrimaryMapFilePath
{
    return @"~/SNOP";
}

-(void) awakeFromNib
{
    detectorSize		= NSMakeSize(1200,700);
    detailsSize		= NSMakeSize(1200,700);//NSMakeSize(450,589);
    focalPlaneSize		= NSMakeSize(1200,700);//NSMakeSize(450,589);
    couchDBSize		= NSMakeSize(1200,700);//(620,595);//NSMakeSize(450,480);
    hvMasterSize		= NSMakeSize(1200,700);
    runsSize		= NSMakeSize(1200,700);
    
    blankView = [[NSView alloc] init];
    [tabView setFocusRingType:NSFocusRingTypeNone];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];

    //Custom colors
    [self setSnopBlueColor:[NSColor colorWithSRGBRed:30./255. green:144./255. blue:255./255. alpha:1]];
    [self setSnopRedColor:[NSColor colorWithSRGBRed:255./255. green:102./255. blue:102./255. alpha:1]];
    [self setSnopGreenColor:[NSColor colorWithSRGBRed:0./255. green:150./255. blue:0./255. alpha:1]];
    [self setSnopOrangeColor:[NSColor colorWithSRGBRed:255./255. green:178./255. blue:102./255. alpha:1]];
    [self setSnopBlackColor:[NSColor colorWithSRGBRed:0./255. green:0./255. blue:0./255. alpha:1]];
    [self setSnopGrayColor:[NSColor colorWithSRGBRed:0./255. green:0./255. blue:0./255. alpha:0.5]];

    //Update conection settings
    [self updateSettings:nil];
    //Sync runnumber with main RunControl
    [self updateRunInfo:nil];
    [self findRunControl:nil];
    [runControl getCurrentRunNumber]; //this should be done by the base class... but it is not
    //Sync SR with MTC

    [doggy_icon start_animation];

    [self initializeUnits];
    [self MTCSettingsChanged:nil];
    [self CAENSettingsChanged:nil];
    [self TUBiiSettingsChanged:nil];
    //Update runtype word
    [self refreshRunWordLabels:nil];
    [self runTypeWordChanged:nil];

    if(!doggy_icon)
    {
        doggy_icon = [[RunStatusIcon alloc] init];
    }

    // ELLIE stop buttons
    [smellieStopRunButton setEnabled:YES];
    [tellieStopRunButton setEnabled:YES];
    [smellieEmergencyStop setEnabled:YES];
    [tellieEmergencyStop setEnabled:YES];

    [super awakeFromNib];
    [self performSelector:@selector(updateWindow)withObject:self afterDelay:0.1];
}

- (void) initializeUnits {
    for(int i=0;i<10;i++) {
        displayUnitsDecider[i] = UNITS_UNDECIDED;
    }
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(dbOrcaDBIPChanged:)
                         name : ORSNOPModelOrcaDBIPAddressChanged
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(dbDebugDBIPChanged:)
                         name : ORSNOPModelDebugDBIPAddressChanged
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(hvStatusChanged:)
                         name : ORXL3ModelHvStatusChanged
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(hvStatusChanged:)
                         name : ORXL3ModelHVNominalVoltageChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(XL3ModeChanged:)
                         name : ORXL3ModelStateChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(XL3ModeChanged:)
                         name : ORXL3ModelXl3ModeChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(triggerStatusChanged:)
                         name : ORXL3ModelTriggerStatusChanged
                        object: nil];

    [notifyCenter addObserver :self
                     selector : @selector(stopSmellieRunAction:)
                         name : ORSMELLIERunFinishedNotification
                        object: nil];

    [notifyCenter addObserver :self
                     selector : @selector(startTellieRunNotification:)
                         name : ORTELLIERunStartNotification
                        object: nil];

    [notifyCenter addObserver :self
                     selector : @selector(stopTellieRunAction:)
                         name : ORTELLIERunFinishedNotification
                        object: nil];

    [notifyCenter addObserver :self
                     selector : @selector(startAmellieRunNotification:)
                         name : ORAMELLIERunStartNotification
                        object: nil];

    [notifyCenter addObserver :self
                     selector : @selector(stopAmellieRunAction:)
                         name : ORAMELLIERunFinishedNotification
                        object: nil];

    [notifyCenter addObserver: self
                     selector: @selector(runStatusChanged:)
                         name: ORRunStatusChangedNotification
                       object: nil];

    [notifyCenter addObserver:self
                     selector:@selector(standardRunsCollectionChanged:)
                         name:ORSNOPModelSRCollectionChangedNotification
                         object:nil];

    [notifyCenter addObserver:self
                     selector:@selector(SRTypeChanged:)
                         name:ORSNOPModelSRChangedNotification
                       object:nil];

    [notifyCenter addObserver:self
                     selector:@selector(SRVersionChanged:)
                         name:ORSNOPModelSRVersionChangedNotification
                       object:nil];

    [notifyCenter addObserver :self
                     selector :@selector(runTypeWordChanged:)
                         name :ORRunTypeChangedNotification
                       object :nil];

    [notifyCenter addObserver :self
                     selector :@selector(runTypeWordChanged:)
                         name :ORSNOPRunTypeWordChangedNotification
                       object :nil];

    [notifyCenter addObserver : self
                     selector : @selector(runsLockChanged:)
                         name : ORSecurityNumberLockPagesChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(runsLockChanged:)
                         name : ORSNOPRunsLockNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(runsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(runsECAChanged:)
                         name : ORECARunChangedNotification
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(runsECAChanged:)
                         name : ORECARunStartedNotification
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(runsECAChanged:)
                         name : ORECARunFinishedNotification
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(routineStatusChanged:)
                         name : ORRoutineChangedNotification
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(MTCSettingsChanged:)
                         name : ORMTCAThresholdChanged
                        object: nil];
    [notifyCenter addObserver : self
                     selector : @selector(MTCSettingsChanged:)
                         name : ORMTCAConversionChanged
                        object: nil];
    [notifyCenter addObserver : self
                     selector : @selector(MTCSettingsChanged:)
                         name : ORMTCABaselineChanged
                        object: nil];
    [notifyCenter addObserver : self
                     selector : @selector(MTCSettingsChanged:)
                         name : ORMTCPulserRateChanged
                        object: nil];
    [notifyCenter addObserver : self
                     selector : @selector(MTCSettingsChanged:)
                         name : ORMTCSettingsChanged
                        object: nil];
    [notifyCenter addObserver : self
                     selector : @selector(MTCSettingsChanged:)
                         name : ORMTCGTMaskChanged
                        object: nil];
    [notifyCenter addObserver : self
                     selector : @selector(MTCSettingsChanged:)
                         name : ORMTCModelIsPedestalEnabledInCSR
                        object: nil];



    [notifyCenter addObserver : self
                     selector : @selector(CAENSettingsChanged:)
                         name : SNOCaenModelEventSizeChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(CAENSettingsChanged:)
                         name : SNOCaenModelEnabledMaskChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(CAENSettingsChanged:)
                         name : SNOCaenModelPostTriggerSettingChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(CAENSettingsChanged:)
                         name : SNOCaenModelTriggerSourceMaskChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(CAENSettingsChanged:)
                         name : SNOCaenModelTriggerOutMaskChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(CAENSettingsChanged:)
                         name : SNOCaenModelFrontPanelControlMaskChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(CAENSettingsChanged:)
                         name : SNOCaenModelCoincidenceLevelChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(CAENSettingsChanged:)
                         name : SNOCaenModelAcquisitionModeChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(CAENSettingsChanged:)
                         name : SNOCaenModelCountAllTriggersChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(CAENSettingsChanged:)
                         name : SNOCaenModelCustomSizeChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(CAENSettingsChanged:)
                         name : SNOCaenModelIsCustomSizeChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(CAENSettingsChanged:)
                         name : SNOCaenModelIsFixedSizeChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(CAENSettingsChanged:)
                         name : SNOCaenModelChannelConfigMaskChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(CAENSettingsChanged:)
                         name : SNOCaenChnlDacChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(CAENSettingsChanged:)
                         name : SNOCaenOverUnderThresholdChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(CAENSettingsChanged:)
                         name : SNOCaenChnlThresholdChanged
                        object: nil];



    [notifyCenter addObserver : self
                     selector : @selector(TUBiiSettingsChanged:)
                         name : ORTubiiSettingsChangedNotification
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(updateSettings:)
                         name : @"SNOPSettingsChanged"
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(fetchSmellieRunFilesFinish:)
                         name : @"SmellieRunFilesLoaded"
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(fetchTellieRunFilesFinish:)
                         name : @"TellieRunFilesLoaded"
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(fetchAmellieRunFilesFinish:)
                         name : @"AmellieRunFilesLoaded"
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(nhitMonitorSettingsChanged:)
                         name : ORSNOPModelNhitMonitorChangedNotification
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(nhitMonitorUpdate:)
                         name : ORNhitMonitorUpdateNotification
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(nhitMonitorResults:)
                         name : ORNhitMonitorResultsNotification
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(nhitMonitor:)
                         name : ORNhitMonitorNotification
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(stillWaitingForBuffers:)
                         name : ORSNOPStillWaitingForBuffersNotification
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(notWaitingForBuffers:)
                         name : ORSNOPNotWaitingForBuffersNotification
                        object: nil];
}

- (void) updateWindow
{
    [super updateWindow];
    [model refreshStandardRunsFromDB];
    [self hvStatusChanged:nil];
    [self triggerStatusChanged:nil];
    [self XL3ModeChanged:nil];
    [self dbOrcaDBIPChanged:nil];
    [self dbDebugDBIPChanged:nil];
    [self runStatusChanged:nil];
    [self SRTypeChanged:nil];
    [self SRVersionChanged:nil];
    [self runsLockChanged:nil];
    [self runsECAChanged:nil];
    [self runTypeWordChanged:nil];
    [self nhitMonitorSettingsChanged:nil];
    [self nhitMonitor:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORSNOPRunsLockNotification to:secure];
    [runsLockButton setEnabled:secure];
}

- (void) nhitMonitorSettingsChanged: (NSNotification*) aNote
{
    int row;

    int crate = [model nhitMonitorCrate];
    [nhitMonitorCrateButton selectItemAtIndex:crate];
    int pulserRate = [model nhitMonitorPulserRate];
    [nhitMonitorPulserRate setStringValue:[NSString stringWithFormat:@"%i", pulserRate]];
    int numPulses = [model nhitMonitorNumPulses];
    [nhitMonitorNumPulses setStringValue:[NSString stringWithFormat:@"%i", numPulses]];
    int maxNhit = [model nhitMonitorMaxNhit];
    [nhitMonitorMaxNhit setStringValue:[NSString stringWithFormat:@"%i", maxNhit]];
    int autoRun = [model nhitMonitorAutoRun];
    [nhitMonitorAutoRunButton setState:autoRun];
    int autoPulserRate = [model nhitMonitorAutoPulserRate];
    [nhitMonitorAutoPulserRate setStringValue:[NSString stringWithFormat:@"%i", autoPulserRate]];
    int autoNumPulses = [model nhitMonitorAutoNumPulses];
    [nhitMonitorAutoNumPulses setStringValue:[NSString stringWithFormat:@"%i", autoNumPulses]];
    int autoMaxNhit = [model nhitMonitorAutoMaxNhit];
    [nhitMonitorAutoMaxNhit setStringValue:[NSString stringWithFormat:@"%i", autoMaxNhit]];
    int runType = [model nhitMonitorRunType];
    for (row = 0; row < [nhitMonitorRunTypeWordMatrix numberOfRows]; row++) {
        if (runType & (1L << row)) {
            [nhitMonitorRunTypeWordMatrix setState:1 atRow:row column:0];
        } else {
            [nhitMonitorRunTypeWordMatrix setState:0 atRow:row column:0];
        }
    }
    int crateMask = [model nhitMonitorCrateMask];
    for (row = 0; row < [nhitMonitorCrateMaskMatrix numberOfRows]; row++) {
        if (crateMask & (1L << row)) {
            [nhitMonitorCrateMaskMatrix setState:1 atRow:row column:0];
        } else {
            [nhitMonitorCrateMaskMatrix setState:0 atRow:row column:0];
        }
    }
    double timeInterval = [model nhitMonitorTimeInterval];
    [nhitMonitorTimeInterval setStringValue:[NSString stringWithFormat:@"%.0f", timeInterval]];
}

- (void) nhitMonitorUpdate: (NSNotification*) aNote
{
    NSDictionary *userInfo = [aNote userInfo];

    int nhit = [[userInfo objectForKey:@"nhit"] intValue];
    int maxNhit = [[userInfo objectForKey:@"maxNhit"] intValue];
    [nhitMonitorProgress setDoubleValue:nhit*100/(float) maxNhit];
    [nhitMonitorProgress displayIfNeeded];
}

- (void) nhitMonitorResults: (NSNotification*) aNote
{
    int i;
    NSDictionary *userInfo = [aNote userInfo];

    NSArray *names = @[@"n100_hi", @"n100_med", @"n100_lo", @"n20",
                       @"n20_lb"];

    for (i = 0; i < [names count]; i++) {
        if ([[userInfo objectForKey:names[i]] floatValue] < 0) {
            [[nhitMonitorResultsMatrix cellAtRow:i column:0] setStringValue:
                [NSString stringWithFormat:@"> %i",
                 [[userInfo objectForKey:@"max_nhit"] intValue]]];
        } else {
            [[nhitMonitorResultsMatrix cellAtRow:i column:0] setStringValue:
                [NSString stringWithFormat:@"%.2f",
                 [[userInfo objectForKey:names[i]] floatValue]]];
        }
    }
}

- (void) nhitMonitor: (NSNotification*) aNote
{
    if ([aNote userInfo]) {
        /* The nhit monitor adds a userInfo dictionary when it is finished.
         * It's not possible to tell if it's done by checking to see if it's
         * still running, because when the notification is posted, the thread
         * is still running. */
        [runNhitMonitorButton setEnabled:YES];
        [stopNhitMonitorButton setEnabled:NO];
        [[routineStatusMatrix cellAtRow:1 column:0] setStringValue:@"Not Running"];
        [[routineStatusMatrix cellAtRow:1 column:0] setTextColor:[NSColor blackColor]];
        return;
    }

    if ([[model nhitMonitor] isRunning]) {
        [runNhitMonitorButton setEnabled:NO];
        [stopNhitMonitorButton setEnabled:YES];
        [[routineStatusMatrix cellAtRow:1 column:0] setStringValue:@"Running"];
        [[routineStatusMatrix cellAtRow:1 column:0] setTextColor:[NSColor redColor]];
    } else {
        [runNhitMonitorButton setEnabled:YES];
        [stopNhitMonitorButton setEnabled:NO];
        [[routineStatusMatrix cellAtRow:1 column:0] setStringValue:@"Not Running"];
        [[routineStatusMatrix cellAtRow:1 column:0] setTextColor:[NSColor blackColor]];
    }
}

-(void) SRTypeChanged:(NSNotification*)aNote
{

    NSString* standardRun = [model standardRunType];
    if([standardRunPopupMenu numberOfItems] == 0 || standardRun == nil || [standardRun isEqualToString:@""]){
        //Nothing
    }
    else if([standardRunPopupMenu indexOfItemWithObjectValue:standardRun] == NSNotFound){
        NSLogColor([NSColor redColor],@"Standard Run \"%@\" does not exist. \n", standardRun);
    }
    else{
        [standardRunPopupMenu selectItemWithObjectValue:standardRun];
        [self refreshStandardRunVersions];
    }

}

//Update the SR diplay when SR changes
- (void) SRVersionChanged:(NSNotification*)aNote
{
    NSString* standardRunVersion = [model standardRunVersion];
    if ([standardRunVersionPopupMenu numberOfItems] == 0 || standardRunVersion == nil || [standardRunVersion isEqualToString:@""]) {
        return;
    }
    if ([standardRunVersionPopupMenu indexOfItemWithObjectValue:standardRunVersion] == NSNotFound) {
        NSLogColor([NSColor redColor],@"Standard Run Version \"%@\" does not exist. \n",standardRunVersion);
        return;
    } else {
        [standardRunVersionPopupMenu selectItemWithObjectValue:standardRunVersion];
    }
    
    [self displayThresholdsFromDB];
    [self runTypeWordChanged:nil];
}

- (IBAction) startRunAction:(id)sender
{
    [self endEditing];

    /* Action when the user clicks on the Start or Restart Button. */
    unsigned long dbruntypeword = 0;

    /* If we are not going to maintenance we shouldn't be polling */
    NSMutableDictionary* runSettings = [[[model standardRunCollection] objectForKey:[model standardRunType]] objectForKey:[model standardRunVersion]];

    if (runSettings == nil) {
        NSLogColor([NSColor redColor], @"Standard run %@(%@) does NOT exists in DB. \n", [model standardRunType], [model standardRunVersion]);
        return;
    }

    // Get the run type word of the next run
    dbruntypeword = [[runSettings valueForKey:@"run_type_word"] unsignedLongValue];

    if (!((dbruntypeword & kMaintenanceRun) || (dbruntypeword & kDiagnosticRun))) {
        // Make sure we are not polling
        NSArray *xl3s = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];
        for (ORXL3Model *anXL3 in xl3s) {
            if ([anXL3 isPollingXl3]) {
                NSLog(@"Stopping XL3 polling on crate %d\n",[anXL3 crateNumber]);
                [anXL3 setIsPollingXl3:false];
            }
        }
    }

    // Start the standard run
    [model startStandardRun:[model standardRunType] withVersion:[model standardRunVersion]];
}
- (IBAction) resyncRunAction:(id)sender
{
    /* A resync run does a hard stop and start without the user having to hit
     * stop run and then start run. Doing this resets the GTID, which resyncs
     * crate 9 after it goes out of sync :). */

    [model setResync:YES];

    [self startRunAction:nil];
}

- (IBAction) stopRunAction:(id)sender
{
    [self endEditing];
    [model stopRun];
}

- (void) runStatusChanged:(NSNotification*)aNotification
{
    [startRunButton setEnabled:true];

    if([runControl runningState] == eRunInProgress){
        [startRunButton setTitle:@"RESTART"];
        [lightBoardView setState:kGoLight];
        [runStatusField setStringValue:@"Running"];
        [resyncRunButton setEnabled:true];
        [standardRunPopupMenu setEnabled:true];
        [standardRunVersionPopupMenu setEnabled:true];
        [runNumberField setStringValue:[runControl fullRunNumberString]];
        [doggy_icon start_animation];
	}
	else if([runControl runningState] == eRunStopped){
        [startRunButton setTitle:@"START"];
        [lightBoardView setState:kStoppedLight];
        [runStatusField setStringValue:@"Stopped"];
        [resyncRunButton setEnabled:false];
        [standardRunPopupMenu setEnabled:true];
        [standardRunVersionPopupMenu setEnabled:true];
        [doggy_icon stop_animation];
	}
	else if([runControl runningState] == eRunStarting || [runControl runningState] == eRunStopping || [runControl runningState] == eRunBetweenSubRuns){
        if([runControl runningState] == eRunStarting){
            //The run started so update the display
            [runStatusField setStringValue:@"Starting"];
            [startRunButton setEnabled:false];
            [resyncRunButton setEnabled:false];
            [startRunButton setTitle:@"STARTING..."];
        }
        else {
            //Do nothing
        }
        [lightBoardView setState:kCautionLight];
        [standardRunPopupMenu setEnabled:false];
        [standardRunVersionPopupMenu setEnabled:false];
	}

    if ([runControl isRunning] && ([runControl runType] & kECARun)) {
        /* Disable the ping crates button if we are in an ECA run. */
        [pingCratesButton setEnabled:FALSE];
    } else {
        [pingCratesButton setEnabled:TRUE];
    }

    if ([runControl isRunning]){
        if ([runControl runType] & kEmbeddedPeds) {
            /* Enable LivePed radio button if we are in LivePed run. */
            [livePedRadioButton setEnabled:YES];
            [livePedRunTypeWordAd setHidden:YES];
        } else {
            [livePedRadioButton setEnabled:NO];
            [livePedRunTypeWordAd setHidden:NO];
        }
    } else {
        [livePedRadioButton setEnabled:YES];
        [livePedRunTypeWordAd setHidden:YES];
    }

}

- (IBAction) pingCratesAction: (id) sender
{
    [model pingCrates];
}

- (IBAction) runNhitMonitorAction: (id) sender
{
    [self endEditing];
    [model runNhitMonitor];
}

- (IBAction) stopNhitMonitorAction: (id) sender
{
    [self endEditing];
    [model stopNhitMonitor];
}

- (IBAction) nhitMonitorCrateAction: (id) sender
{
    [model setNhitMonitorCrate:[sender indexOfSelectedItem]];
}

- (IBAction) nhitMonitorPulserRateAction: (id) sender
{
    [model setNhitMonitorPulserRate:[sender intValue]];
}

- (IBAction) nhitMonitorNumPulsesAction: (id) sender
{
    [model setNhitMonitorNumPulses:[sender intValue]];
}

- (IBAction) nhitMonitorMaxNhitAction: (id) sender
{
    [model setNhitMonitorMaxNhit:[sender intValue]];
}

- (IBAction) nhitMonitorAutoRunAction: (id) sender
{
    [model setNhitMonitorAutoRun:[sender state]];
}

- (IBAction) nhitMonitorAutoPulserRateAction: (id) sender
{
    [model setNhitMonitorAutoPulserRate:[sender intValue]];
}

- (IBAction) nhitMonitorAutoNumPulsesAction: (id) sender
{
    [model setNhitMonitorAutoNumPulses:[sender intValue]];
}

- (IBAction) nhitMonitorAutoMaxNhitAction: (id) sender
{
    [model setNhitMonitorAutoMaxNhit:[sender intValue]];
}

- (IBAction) nhitMonitorRunTypeAction: (id) sender
{
    short bit = [sender selectedRow];
    BOOL state  = [[sender selectedCell] state];
    unsigned long currentRunMask = [model nhitMonitorRunType];
    if (state) {
        currentRunMask |= (1L << bit);
    } else {
        currentRunMask &= ~(1L << bit);
    }
    [model setNhitMonitorRunType:currentRunMask];
}

- (IBAction) nhitMonitorCrateMaskAction: (id) sender
{
    short bit = [sender selectedRow];
    BOOL state  = [[sender selectedCell] state];
    unsigned long currentCrateMask = [model nhitMonitorCrateMask];
    if (state) {
        currentCrateMask |= (1L << bit);
    } else {
        currentCrateMask &= ~(1L << bit);
    }
    [model setNhitMonitorCrateMask:currentCrateMask];
}
    
- (IBAction) nhitMonitorTimeIntervalAction: (id) sender
{
    [model setNhitMonitorTimeInterval:[sender doubleValue]];
}

- (void) dbOrcaDBIPChanged:(NSNotification*)aNote
{
    [orcaDBIPAddressPU setStringValue:[model orcaDBIPAddress]];
}

- (void) dbDebugDBIPChanged:(NSNotification*)aNote
{
    [debugDBIPAddressPU setStringValue:[model debugDBIPAddress]];
}

- (void) stillWaitingForBuffers:(NSNotification*)aNote
{
    /* Throw up a window-modal dialog to give the user an option
     * to avoid waiting for the hardware buffers to clear at the end
     * of a run (only for OS X 10.10 or later).  Must be called
     * only from the main thread. */
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSString* s = [NSString stringWithFormat:@"Waiting for buffers to empty..."];
    waitingForBuffersAlert = [[[NSAlert alloc] init] autorelease];
    [waitingForBuffersAlert setMessageText:s];
    [waitingForBuffersAlert addButtonWithTitle:@"Force Stop and LOSE DATA!"];
    [waitingForBuffersAlert setAlertStyle:NSInformationalAlertStyle];
    [waitingForBuffersAlert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn) {
            [model abortWaitingForBuffers]; // don't wait for buffers to clear
            waitingForBuffersAlert = nil;
        }
    }];
#endif
}

- (void) notWaitingForBuffers:(NSNotification*)aNote
{
    /* Close our "Waiting for buffers" dialog if it was open.
     * Must be called only from the main thread. */
    if (waitingForBuffersAlert) {
        [[self window] endSheet:[[self window] attachedSheet] returnCode:NSAlertSecondButtonReturn];
        waitingForBuffersAlert = nil;
    }
}

- (void) hvStatusChanged:(NSNotification*)aNote
{

    NSArray *OWLRows = [NSArray arrayWithObjects:@3,@13,@19,nil];

    if (!aNote) {
        //collect all instances of xl3 objects in Orca
        NSArray* xl3s = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];
        
        // bit wise mask of xl3s
        unsigned long xl3Mask = 0x7ffff;
        
        //loop through all xl3 instances in Orca
        for (id xl3 in xl3s) {
            
            xl3Mask ^= 1 << [xl3 crateNumber];
            int mRow;
            int mColumn;
            bool found;
            
            found = [hvStatusMatrix getRow:&mRow column:&mColumn ofCell:[hvStatusMatrix cellWithTag:[xl3 crateNumber]]];
            if (found) {
                //Individual HV status
                [[hvStatusMatrix cellAtRow:mRow column:1] setStringValue:[xl3 hvASwitch]?@"ON":@"OFF"];
                if ([xl3 hvASwitch]) {
                    [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor redColor]];
		    hvMask |= (1 << [xl3 crateNumber]);
                }
                else {
                    [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor blackColor]];
		    hvMask &= ~(1 << [xl3 crateNumber]);
                }
                [[hvStatusMatrix cellAtRow:mRow column:3] setStringValue:
                 [NSString stringWithFormat:@"%d V",(unsigned int)[xl3 hvNominalVoltageA]]];
                [[hvStatusMatrix cellAtRow:mRow column:4] setStringValue:
                 [NSString stringWithFormat:@"%d V",(unsigned int)[xl3 hvAVoltageReadValue]]];
                [[hvStatusMatrix cellAtRow:mRow column:5] setStringValue:
                 [NSString stringWithFormat:@"%3.1f mA",[xl3 hvACurrentReadValue]]];
            }
            if ([xl3 crateNumber] == 16) {//16B
                int mRow;
                int mColumn;
                bool found;
                found = [hvStatusMatrix getRow:&mRow column:&mColumn ofCell:[hvStatusMatrix cellWithTag:19]];
                if (found) {
                    [[hvStatusMatrix cellAtRow:mRow column:1] setStringValue:[xl3 hvBSwitch]?@"ON":@"OFF"];
                    if ([xl3 hvBSwitch]) {
                        [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor redColor]];
			hvMask |= (1 << 19);
                    }
                    else {
                        [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor blackColor]];
			hvMask &= ~(1 << 19);
                    }
                    [[hvStatusMatrix cellAtRow:mRow column:3] setStringValue:
                     [NSString stringWithFormat:@"%d V",(unsigned int)[xl3 hvNominalVoltageB]]];
                    [[hvStatusMatrix cellAtRow:mRow column:4] setStringValue:
                     [NSString stringWithFormat:@"%d V",(unsigned int)[xl3 hvBVoltageReadValue]]];
                    [[hvStatusMatrix cellAtRow:mRow column:5] setStringValue:
                     [NSString stringWithFormat:@"%3.1f mA",[xl3 hvBCurrentReadValue]]];

                    //Update OWL HV status in crates with OWLs
                    for (id owlRow in OWLRows) {
                        if ([xl3 hvBSwitch]) {
                            [[hvStatusMatrix cellAtRow:[owlRow intValue] column:2] setStringValue:@"OWLs ON"];
                            [[hvStatusMatrix cellAtRow:[owlRow intValue] column:2] setTextColor:[NSColor redColor]];
                        }
                        else {
                            [[hvStatusMatrix cellAtRow:[owlRow intValue] column:2] setStringValue:@"OWLs OFF"];
                            [[hvStatusMatrix cellAtRow:[owlRow intValue] column:2] setTextColor:[NSColor blackColor]];
                        }
                    }
                }
            }
        }
        unsigned short crate_num;
        if (xl3Mask & 1 << 16) {//16B needs an extra care
            xl3Mask |= 1 << 19;
        }
        for (crate_num=0; crate_num<20; crate_num++) {
            if (xl3Mask & 1 << crate_num) {
                int mRow;
                int mColumn;
                bool found;
                found = [hvStatusMatrix getRow:&mRow column:&mColumn ofCell:[hvStatusMatrix cellWithTag:crate_num]];
                if (found) {
                    [[hvStatusMatrix cellAtRow:mRow column:1] setStringValue:@"???"];
                    [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor blackColor]];
                    [[hvStatusMatrix cellAtRow:mRow column:2] setTextColor:[NSColor blackColor]];
                    [[hvStatusMatrix cellAtRow:mRow column:3] setStringValue:@"??? V"];
                    [[hvStatusMatrix cellAtRow:mRow column:4] setStringValue:@"??? V"];
                    [[hvStatusMatrix cellAtRow:mRow column:5] setStringValue:@"??? mA"];
                }
            }
        }
    }
    else { //update from a notification
        int mRow;
        int mColumn;
        bool found;
        found = [hvStatusMatrix getRow:&mRow column:&mColumn ofCell:
                 [hvStatusMatrix cellWithTag:[[aNote object] crateNumber]]];
        
        if (found) {
            [[hvStatusMatrix cellAtRow:mRow column:1] setStringValue:[[aNote object] hvASwitch]?@"ON":@"OFF"];
            if ([[aNote object] hvASwitch]) {
                [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor redColor]];
		hvMask |= (1 << [[aNote object] crateNumber]);
            }
            else {
                [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor blackColor]];
		hvMask &= ~(1 << [[aNote object] crateNumber]);
            }
            [[hvStatusMatrix cellAtRow:mRow column:3] setStringValue:
             [NSString stringWithFormat:@"%d V",(unsigned int)[[aNote object] hvNominalVoltageA]]];
            [[hvStatusMatrix cellAtRow:mRow column:4] setStringValue:
             [NSString stringWithFormat:@"%d V",(unsigned int)[[aNote object] hvAVoltageReadValue]]];
            [[hvStatusMatrix cellAtRow:mRow column:5] setStringValue:
             [NSString stringWithFormat:@"%3.1f mA",[[aNote object] hvACurrentReadValue]]];
        }
        if ([[aNote object] crateNumber] == 16) {//16B
            int mRow;
            int mColumn;
            bool found;
            found = [hvStatusMatrix getRow:&mRow column:&mColumn ofCell:[hvStatusMatrix cellWithTag:19]];
            if (found) {
                [[hvStatusMatrix cellAtRow:mRow column:1] setStringValue:[[aNote object] hvBSwitch]?@"ON":@"OFF"];
                if ([[aNote object] hvBSwitch]) {
                    [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor redColor]];
		    hvMask |= (1 << 19);
                }
                else {
                    [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor blackColor]];
		    hvMask &= ~(1 << 19);
                }
                [[hvStatusMatrix cellAtRow:mRow column:3] setStringValue:
                 [NSString stringWithFormat:@"%d V",(unsigned int)[[aNote object] hvNominalVoltageB]]];
                [[hvStatusMatrix cellAtRow:mRow column:4] setStringValue:
                 [NSString stringWithFormat:@"%d V",(unsigned int)[[aNote object] hvBVoltageReadValue]]];
                [[hvStatusMatrix cellAtRow:mRow column:5] setStringValue:
                 [NSString stringWithFormat:@"%3.1f mA",[[aNote object] hvBCurrentReadValue]]];
            }

            //Update OWL HV status in crates with OWLs
            for (id owlRow in OWLRows) {
                if ([[aNote object] hvBSwitch]) {
                    [[hvStatusMatrix cellAtRow:[owlRow intValue] column:2] setStringValue:@"OWLs ON"];
                    [[hvStatusMatrix cellAtRow:[owlRow intValue] column:2] setTextColor:[NSColor redColor]];
                }
                else {
                    [[hvStatusMatrix cellAtRow:[owlRow intValue] column:2] setStringValue:@"OWLs OFF"];
                    [[hvStatusMatrix cellAtRow:[owlRow intValue] column:2] setTextColor:[NSColor blackColor]];
                }
            }

        }
    }

    // Detector worldwide HV status
    if(hvMask){
        [detectorHVStatus setStringValue:@"PMT HV is ON"];
        [detectorHVStatus setBackgroundColor:snopRedColor];
        [panicDownButton setEnabled:1];
    } else{
        [detectorHVStatus setStringValue:@"PMT HV is OFF"];
        [detectorHVStatus setBackgroundColor:snopBlueColor];
        [panicDownButton setEnabled:0];
    }

}

- (void) triggerStatusChanged:(NSNotification*)aNote
{
    NSArray* xl3s = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];
    for (ORXL3Model* xl3 in xl3s) {
        //Take care of crate 17 and 18
        int row = [xl3 crateNumber];
        if (row > 16) row++;
        [[triggerStatusMatrix cellAtRow:row column:0] setStringValue:[xl3 isTriggerON]?@"ON":@"OFF"];
        if( [xl3 isTriggerON] ) [[triggerStatusMatrix cellAtRow:row column:0] setTextColor:[NSColor redColor]];
        else [[triggerStatusMatrix cellAtRow:row column:0] setTextColor:[NSColor blackColor]];
        if (row++ == 16){
            [[triggerStatusMatrix cellAtRow:row column:0] setStringValue:[xl3 isTriggerON]?@"ON":@"OFF"];
            if( [xl3 isTriggerON] ) [[triggerStatusMatrix cellAtRow:row column:0] setTextColor:[NSColor redColor]];
            else [[triggerStatusMatrix cellAtRow:row column:0] setTextColor:[NSColor blackColor]];
        }
    }
}

- (void) XL3ModeChanged:(NSNotification*)aNote
{
    int i =0;
    NSArray* xl3s = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];
    for (id xl3 in xl3s) {
        ORXL3Model * anXl3 = xl3;
        //[xl3 xl3Mode];
        NSString *xl3ModeDescription;
        if([anXl3 xl3Mode] == 1)        xl3ModeDescription = [NSString stringWithFormat:@"Init"];
        else if ([anXl3 xl3Mode] == 2)  xl3ModeDescription = [NSString stringWithFormat:@"Normal"];
        else if ([anXl3 xl3Mode] == 3)  xl3ModeDescription = [NSString stringWithFormat:@"CGT"];
        else                            xl3ModeDescription = [NSString stringWithFormat:@"???"];

        if([anXl3 crateNumber] == 16){
            i++;
            [[globalxl3Mode cellAtRow:16 column:0] setStringValue:xl3ModeDescription];
            if(i>0){
                [[globalxl3Mode cellAtRow:17 column:0] setStringValue:xl3ModeDescription];
            }
        }
        else if ([anXl3 crateNumber] > 16){
            [[globalxl3Mode cellAtRow:([anXl3 crateNumber]+1) column:0] setStringValue:xl3ModeDescription];
        }
        else{
            [[globalxl3Mode cellAtRow:[anXl3 crateNumber] column:0] setStringValue:xl3ModeDescription];
        }
    }
}

#pragma mark ¥¥¥Interface Management
- (IBAction) orcaDBIPAddressAction:(id)sender
{
    [model setOrcaDBIPAddress:[sender stringValue]];
}

- (IBAction) debugDBIPAddressAction:(id)sender
{
    [model setDebugDBIPAddress:[sender stringValue]];
}

- (IBAction) orcaDBClearHistoryAction:(id)sender
{
    [model clearOrcaDBConnectionHistory];
}

- (IBAction) debugDBClearHistoryAction:(id)sender
{
    [model clearDebugDBConnectionHistory];
}

- (IBAction) orcaDBFutonAction:(id)sender
{
    
    NSString *url = [NSString stringWithFormat:@"http://%@:%@@%@:%d/_utils/database.html?%@",[model orcaDBUserName],[model orcaDBPassword],[model orcaDBIPAddress],[model orcaDBPort],[model orcaDBName]];
    NSString* urlScaped = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlScaped]];
}

- (IBAction) debugDBFutonAction:(id)sender
{
    
    NSString *url = [NSString stringWithFormat:@"http://%@:%@@%@:%d/_utils/database.html?%@", [model debugDBUserName], [model debugDBPassword],[model debugDBIPAddress],[model debugDBPort], [model debugDBName]];
    NSString* urlScaped = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlScaped]];
}

- (IBAction) debugDBTestAction:(id)sender
{
    [[NSWorkspace sharedWorkspace]
     openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%@@%@:%d",
                                   [model debugDBUserName], [model debugDBPassword],
                                   [model debugDBIPAddress], [model debugDBPort]]]];
}


- (IBAction) orcaDBPingAction:(id)sender
{
    [model orcaDBPing];
}

- (IBAction) debugDBPingAction:(id)sender
{
    [model debugDBPing];
}

- (IBAction)hvMasterPanicAction:(id)sender
{

    BOOL cancel = ORRunAlertPanel(@"Panic Down the entire detector",@"Is this really what you want?",@"Cancel",@"Yes",nil);
    if(cancel) return;

    [[[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")] makeObjectsPerformSelector:@selector(hvPanicDown)];
    NSLogColor([NSColor redColor],@"Detector wide panic down started\n");
}

- (IBAction)rampDownSingleCrateAction:(id)sender
{

    NSArray* xl3s = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];
    int crateNumber = [sender selectedRow];

    //Handle crates 16B, 17 and 18
    NSString *HVBlabel = @"";
    if(crateNumber > 16){
        if(crateNumber == 17) HVBlabel = @"B";
        crateNumber--;
    }

    //Confirm
    BOOL cancel = ORRunAlertPanel([NSString stringWithFormat:@"Ramp Down Crate %i%@?",crateNumber,HVBlabel],@"Is this really what you want?",@"Cancel",@"Yes",nil);
    if (cancel) return;
    for (id xl3 in xl3s) {
        if ([xl3 crateNumber] != crateNumber) continue;
        if ([xl3 isTriggerON]) {
            [xl3 hvTriggersOFF];
        }
        if([HVBlabel isEqualToString:@"B"]) [xl3 setHvBNextStepValue:0];
        else [xl3 setHvANextStepValue:0];
        return;
    }

    NSLogColor([NSColor redColor],@"XL3 %i not found. Unable to Ramp Down. \n",crateNumber);
    
}

- (IBAction) reportAction:(id)sender
{
    NSString *url = [NSString stringWithFormat:@"https://github.com/snoplus/orca/issues/new"];
    NSString* urlScaped = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlScaped]];
}

- (IBAction) logAction:(id)sender
{
    NSString *url = [NSString stringWithFormat:@"http://snopl.us/shift/"];
    NSString* urlScaped = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlScaped]];
}

- (IBAction) opManualAction:(id)sender
{
    NSString *url = [NSString stringWithFormat:@"http://snopl.us/detector/operator_manual/operator_manual.html"];
    NSString* urlScaped = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlScaped]];
}

- (IBAction)hvMasterTriggersOFF:(id)sender
{
    BOOL cancel = ORRunAlertPanel(@"Disabling Channel Triggers",@"Is this really what you want?",@"Cancel",@"Yes",nil);
    if(cancel) return;

    [model hvMasterTriggersOFF];
}

#pragma mark ¥¥¥Table Data Source

- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)tabViewItem
{
    
    if([tabView indexOfTabViewItem:tabViewItem] == 0){
        //StandardRuns
        [[self window] setContentView:blankView];
        [self resizeWindowToSize:runsSize];
        [[self window] setContentView:snopView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 1){
        //HV
        [self resizeWindowToSize:hvMasterSize];
        [[self window] setContentView:blankView];
        [[self window] setContentView:snopView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 2){
        //State
        [[detectorState mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://snopl.us/monitoring/state"] ] ];
        [[self window] setContentView:blankView];
        [self resizeWindowToSize:detectorSize];
        [[self window] setContentView:snopView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 3){
        //Settings
        [[self window] setContentView:blankView];
        [self resizeWindowToSize:detailsSize];
        [[self window] setContentView:snopView];
    }

    int index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"orca.SNOPController.selectedtab"];
}

#pragma mark ¥¥¥ComboBox Data Source
- (NSInteger) numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    if (aComboBox == orcaDBIPAddressPU) {
        return [[model orcaDBConnectionHistory] count];
    }
    else if (aComboBox == debugDBIPAddressPU) {
        return [[model debugDBConnectionHistory] count];
    }
    
    return 0;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
    if (aComboBox == orcaDBIPAddressPU) {
        return [model orcaDBConnectionHistoryItem:index];
    }
    else if (aComboBox == debugDBIPAddressPU) {
        return [model debugDBConnectionHistoryItem:index];
    }
    
    return nil;
}

//smellie functions ----------------------------------------------

//this fetches the smellie run file information
- (IBAction) fetchSmellieRunFiles:(id)sender
{
    // Temporarily disable drop down list and remove old items
    [smellieRunFileNameField addItemWithObjectValue:@""];
    [smellieRunFileNameField selectItemWithObjectValue:@""];
    [smellieRunFileNameField setEnabled:NO];
    [smellieRunFileNameField removeAllItems];
    [smellieStartRunButton setEnabled:NO];
    
    // Set the smellieRunFileList to nil
    [self setSmellieRunFileList:nil];
    
    // Call getSmellieRunFiles from the model. This queries the DB and sets the smellieRunFiles
    // property. This function runs asyncronously so we have to wait for a notification to be
    // posted back before we can fill and re-activate the dropdown list (see below).
    [model getSmellieRunFiles];
}

-(void) fetchSmellieRunFilesFinish:(NSNotification *)aNote
{
    // When we get a noticication that the database read has finished, set local variables
    NSMutableDictionary *runFileDict = [[NSMutableDictionary alloc] initWithDictionary:[model smellieRunFiles]];
    
    NSMutableArray* runNames = [NSMutableArray array];
    for(id key in runFileDict){
        id loopValue = [runFileDict objectForKey:key];
        @try {
            [runNames addObject:[NSString stringWithFormat:@"%@",[loopValue objectForKey:@"run_name"]]];
        } @catch(NSException* e) {
            NSLog(@"[SMELLIE]: Problem loading run plan documents, reason : %@\n", [e reason]);
        }
    }

    // Fill the combo box with alphabetically sorted information
    [smellieRunFileNameField addItemsWithObjectValues:[runNames sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]];

    [smellieRunFileNameField setEnabled:YES];
    [smellieLoadRunFile setEnabled:YES];
    
    [self setSmellieRunFileList:runFileDict];
    NSLog(@"[SMELLIE] %i run plan documents sucessfully loaded\n", [runFileDict count]);
    [runFileDict release];
}

- (IBAction) fetchTellieRunFiles:(id)sender
{
    // Temporarily disable drop down list and remove old items
    [tellieRunFileNameField addItemWithObjectValue:@""];
    [tellieRunFileNameField selectItemWithObjectValue:@""];
    [tellieRunFileNameField setEnabled:NO];
    [tellieRunFileNameField removeAllItems];
    [tellieStartRunButton setEnabled:NO];

    // Set the smellieRunFileList to nil
    [self setTellieRunFileList:nil];

    // Call getTellieRunFiles from the model. This queries the DB and sets the tellieRunFiles
    // property. This function runs asyncronously so we have to wait for a notification to be
    // posted back before we can fill and re-activate the dropdown list (see below).
    [model getTellieRunFiles];
}

-(void) fetchTellieRunFilesFinish:(NSNotification *)aNote
{
    // When we get a noticication that the database read has finished, set local variables
    NSMutableDictionary *runFileDict = [[NSMutableDictionary alloc] initWithDictionary:[model tellieRunFiles]];

    NSMutableArray* runNames = [NSMutableArray array];
    for(id key in runFileDict){
        id loopValue = [runFileDict objectForKey:key];
        [runNames addObject:[NSString stringWithFormat:@"%@",[loopValue objectForKey:@"name"]]];
    }
    
    // Fill the combo box with alphabetically sorted information
    [tellieRunFileNameField addItemsWithObjectValues:[runNames sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]];
    
    [tellieRunFileNameField setEnabled:YES];
    [tellieLoadRunFile setEnabled:YES];

    [self setTellieRunFileList:runFileDict];
    [runFileDict release];
}

- (IBAction) fetchAmellieRunFiles:(id)sender
{
    // Temporarily disable drop down list and remove old items
    [amellieRunFileNameField addItemWithObjectValue:@""];
    [amellieRunFileNameField selectItemWithObjectValue:@""];
    [amellieRunFileNameField setEnabled:NO];
    [amellieRunFileNameField removeAllItems];
    [amellieStartRunButton setEnabled:NO];

    // Set the smellieRunFileList to nil
    [self setAmellieRunFileList:nil];

    // Call getAmellieRunFiles from the model. This queries the DB and sets the tellieRunFiles
    // property. This function runs asyncronously so we have to wait for a notification to be
    // posted back before we can fill and re-activate the dropdown list (see below).
    [model getAmellieRunFiles];
}

-(void) fetchAmellieRunFilesFinish:(NSNotification *)aNote
{
    // When we get a noticication that the database read has finished, set local variables
    NSMutableDictionary *runFileDict = [NSMutableDictionary dictionaryWithDictionary:[model amellieRunFiles]];

    //Fill lthe combo box with information
    for(id key in runFileDict){
        id loopValue = [runFileDict objectForKey:key];
        [amellieRunFileNameField addItemWithObjectValue:[NSString stringWithFormat:@"%@",[loopValue objectForKey:@"name"]]];
    }

    [amellieRunFileNameField setEnabled:YES];
    [amellieLoadRunFile setEnabled:YES];

    [self setAmellieRunFileList:runFileDict];
}

-(IBAction)loadSmellieRunAction:(id)sender
{
    if([smellieRunFileNameField objectValueOfSelectedItem]!= nil)
    {
        //Loop through all the smellie files in the run list
        for(id key in [self smellieRunFileList]){

            id currentRunFile = [[self smellieRunFileList] objectForKey:key];

            NSString *thisRunFile = [currentRunFile objectForKey:@"run_name"];
            NSString *requestedRunFile = [smellieRunFileNameField objectValueOfSelectedItem];

            if( [thisRunFile isEqualToString:requestedRunFile]){

                NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ELLIEModel")];
                if (![objs count]) {
                    NSLogColor([NSColor redColor], @"ELLIE model not available, add an ELLIE model to your experiment\n");
                    return;
                }
                ELLIEModel* theELLIEModel = [objs objectAtIndex:0];

                // Set this to be the current smellie run file
                [self setSmellieRunFile:currentRunFile];
                [model setSmellieRunNameLabel:[NSString stringWithFormat:@"%@",[smellieRunFile objectForKey:@"run_name"]]];

                // Set some gui labels straight from the settings dict
                [loadedSmellieRunNameLabel setStringValue:[smellieRunFile objectForKey:@"run_name"]];
                [loadedSmellieTriggerFrequencyLabel setStringValue:[smellieRunFile objectForKey:@"trigger_frequency"]];

                // Set Lasers, Fibres and wavelength labels
                NSArray* smellieLaserArray = [smellieRunFile objectForKey:@"lasers"];
                NSArray* smellieFibreArray = [smellieRunFile objectForKey:@"fibres"];
                NSArray* smellieWavelengthsArray = [smellieRunFile objectForKey:@"central_wavelengths"];
                NSString* laserString = [smellieLaserArray componentsJoinedByString:@", "];
                NSString* fibreString = [smellieFibreArray componentsJoinedByString:@", "];
                NSString* wavelengthString = [smellieWavelengthsArray componentsJoinedByString:@", "];
                [loadedSmellieLasersLabel setStringValue:laserString];
                [loadedSmellieFibresLabel setStringValue:fibreString];
                [loadedSmellieSuperKwavelengths setStringValue:wavelengthString];

                // Set time estimate label
                NSNumber* totalTime = [theELLIEModel estimateSmellieRunTime:[self smellieRunFile]];
                [loadedSmellieApproxTimeLabel setStringValue:[NSString stringWithFormat:@"%0.1f",[totalTime floatValue]]];
            }
        }
        //Activate run buttons
        [smellieStartRunButton setEnabled:YES];
    }
    else{
        [loadedSmellieRunNameLabel setStringValue:@""];
        [loadedSmellieApproxTimeLabel setStringValue:@""];
        [loadedSmellieLasersLabel setStringValue:@""];
        [loadedSmellieFibresLabel setStringValue:@""];
        [loadedSmellieTriggerFrequencyLabel setStringValue:@""];
        [loadedSmellieSuperKwavelengths setStringValue:@""];
        [loadedSmellieOperationModeLabel setStringValue:@""];
        NSLog(@"Main SNO+ Control: Please choose a Smellie Run File from selection\n");
    }
}

- (IBAction) startSmellieRunAction:(id)sender
{
    /////////////////////
    // Get the ELLIE model
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ELLIEModel")];
    if (![objs count]) {
        NSLogColor([NSColor redColor], @"ELLIE model not available, add an ELLIE model to your experiment\n");
        return;
    }
    ELLIEModel* theELLIEModel = [objs objectAtIndex:0];

    //////////////////
    // Check if a run is already ongoing
    // If so tell the user and ignore this
    // button press
    if([[theELLIEModel smellieThread] isExecuting]){
        NSLogColor([NSColor redColor], @"[SMELLIE]: A Smellie fire sequence is already on going. Cannot launch a new one until current sequence has finished\n");
        return;
    }

    //////////////////
    // Check if we're in the correct
    // standard run type
    if(!([model runTypeWord] & kSMELLIERun)){
        ORRunAlertPanel(@"The SMELLIE standard run is not loaded.",@"You must load a SMELLIE standard run and start a new run before starting a fire sequence",@"OK",nil,nil);
        return;
    }

    [smellieLoadRunFile setEnabled:NO];
    [smellieRunFileNameField setEnabled:NO];
    [smellieStopRunButton setEnabled:YES];
    [smellieEmergencyStop setEnabled:YES];
    [smellieStartRunButton setEnabled:NO];

    //////////////////////
    // Start smellie thread
    [theELLIEModel startInterlockThread];
    [theELLIEModel startSmellieRunThread:smellieRunFile];
}

- (IBAction) stopSmellieRunAction:(id)sender
{
    [smellieLoadRunFile setEnabled:YES];
    [smellieRunFileNameField setEnabled:YES];
    [smellieStopRunButton setEnabled:NO];

    ///////////////////////
    // Get the ELLIEModel
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ELLIEModel")];
    if (![objs count]) {
        NSLogColor([NSColor redColor], @"ELLIE model not available, add an ELLIE model to your experiment\n");
        return;
    }
    ELLIEModel* theELLIEModel = [objs objectAtIndex:0];

    /////////////////////////
    // If this call is from a button press push an acknowledgement
    // to the logs. Seeing as SMELLIE takes so long to shut down, it
    // is important to let the user know whats going on.
    if(![sender isKindOfClass:[NSNotification class]]){
        NSLog(@"#############################################\n");
        NSLog(@"[SMELLIE]\n");
        NSLog(@"\t\tRun stop button recongnised.\n");
        NSLog(@"\t\tEXTA triggers will stop within the next 10s.\n");
        NSLog(@"\t\tPutting the lasers to safe state may take\n");
        NSLog(@"\t\tup to 2 minutes.\n");
        NSLog(@"#############################################\n");
        ////////////////////////
        // In the case of a button push we also want to set a couple
        // of flags in the ELLIEModel to define how it will handle
        // run tansitions.
        //
        // In this case it will simply roll over into a new
        // SMELLIE run so the flash sequence can be easily
        // re-started.
        [theELLIEModel setMaintenanceRollOver:NO];
        [theELLIEModel setSmellieStopButton:YES];
    }

    //Call stop smellie run method to tidy up SMELLIE's hardware state
    @try{
        [theELLIEModel stopSmellieRun];
    } @catch(NSException* e){
        NSLogColor([NSColor redColor], @"Problem stopping smellie run: %@\n", [e reason]);
        return;
    }

    [loadedSmellieRunNameLabel setStringValue:@""];
    [loadedSmellieTriggerFrequencyLabel setStringValue:@""];
    [loadedSmellieLasersLabel setStringValue:@""];
    [loadedSmellieFibresLabel setStringValue:@""];
    [loadedSmellieSuperKwavelengths setStringValue:@""];
    [loadedSmellieApproxTimeLabel setStringValue:@""];
}

- (IBAction) emergencySmellieStopAction:(id)sender
{
    [smellieStartRunButton setEnabled:NO];
    ///////////////////////
    // Get the ELLIEModel
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ELLIEModel")];
    if (![objs count]) {
        NSLogColor([NSColor redColor], @"ELLIE model not available, add an ELLIE model to your experiment\n");
        return;
    }
    ELLIEModel* theELLIEModel = [objs objectAtIndex:0];

    // Check if we need to do anything
    if(![[theELLIEModel smellieThread] isExecuting]){
        NSLog(@"[SMELLIE]: A Smellie fire sequence does not appear to be running\n");
        return;
    }

    NSLog(@"#############################################\n");
    NSLog(@"[SMELLIE]\n");
    NSLog(@"\t\tEmergency run stop button recongnised.\n");
    NSLog(@"\t\tEXTA triggers will stop within the next [10s].\n");
    NSLog(@"\t\tPutting the lasers to safe state may take\n");
    NSLog(@"\t\tup to [2 minutes].\n");
    NSLog(@"#############################################\n");

    ////////////////////////
    // Set a couple of flags in the ELLIEModel to tell
    // it how to handle run transitions when this button
    // has been activated.
    //
    // In this case it will simply roll over into a new
    // SMELLIE run so the flash sequence can be easily
    // re-started.
    [theELLIEModel setMaintenanceRollOver:NO];
    [theELLIEModel setSmellieStopButton:YES];

    @try {
        [theELLIEModel killKeepAlive:nil];
    } @catch(NSException* e){
        NSLogColor([NSColor redColor], @"Problem stopping smellie run: %@\n", [e reason]);
        return;
    }
}

-(IBAction)loadTellieRunAction:(id)sender
{
    if([tellieRunFileNameField objectValueOfSelectedItem]!= nil)
    {
        //Loop through all the smellie files in the run list
        for(id key in [self tellieRunFileList]){

            id currentRunFile = [[self tellieRunFileList] objectForKey:key];

            NSString *thisRunFile = [currentRunFile objectForKey:@"name"];
            NSString *requestedRunFile = [tellieRunFileNameField objectValueOfSelectedItem];

            if( [thisRunFile isEqualToString:requestedRunFile]){

                [self setTellieRunFile:currentRunFile];
                [loadedTellieRunNameLabel setStringValue:[tellieRunFile objectForKey:@"name"]];
                [model setTellieRunNameLabel:[NSString stringWithFormat:@"%@",[tellieRunFile objectForKey:@"name"]]];

                NSArray* nodes = [[self tellieRunFile] objectForKey:@"nodes"];
                NSString* nodesString = [nodes componentsJoinedByString:@", "];

                [loadedTellieNodesLabel setStringValue:nodesString];
                [loadedTellieIntensityLabel setStringValue:[tellieRunFile objectForKey:@"photons_per_pulse"]];
                [loadedTellieFireRateLabel setStringValue:[tellieRunFile objectForKey:@"trigger_rate"]];
                [loadedTellieNoPulsesLabel setStringValue:[tellieRunFile objectForKey:@"trigger_per_node"]];

                BOOL slaveCheck = [[tellieRunFile objectForKey:@"slave_mode"] boolValue];
                if(slaveCheck){
                    [loadedTellieOperationLabel setStringValue:@"Slave"];
                } else {
                    [loadedTellieOperationLabel setStringValue:@"Master"];
                }

                // Estimate run time
                int no_pulses = [[tellieRunFile objectForKey:@"trigger_per_node"] intValue];
                int no_nodes = [nodes count];
                int rate = [[tellieRunFile objectForKey:@"trigger_rate"] intValue];
                float total_time = (no_nodes*no_pulses)/(rate*60)*1.1;
                [loadedTellieRunTimeLabel setStringValue:[NSString stringWithFormat:@"%0.1f",total_time]];
            }
        }
        //Activate run buttons
        [tellieStartRunButton setEnabled:YES];
        [tellieStopRunButton setEnabled:NO];
    }
    else{
        [loadedTellieRunNameLabel setStringValue:@""];
        [loadedTellieRunTimeLabel setStringValue:@""];
        [loadedTellieNodesLabel setStringValue:@""];
        [loadedTellieIntensityLabel setStringValue:@""];
        [loadedTellieFireRateLabel setStringValue:@""];
        [loadedTellieNoPulsesLabel setStringValue:@""];
        [loadedTellieOperationLabel setStringValue:@""];
        NSLog(@"Main SNO+ Control: Please choose a Tellie Run File from selection\n");
    }
}

-(void)startTellieRunNotification:(NSNotification *)note;
{
    [self setTellieFireSettings:[note userInfo]];

    //////////////////
    // Get ellie model and launch a fire
    // sequence
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ELLIEModel")];
    if (![objs count]) {
        NSLogColor([NSColor redColor], @"ELLIE model not available, add an ELLIE model to your experiment\n");
        return;
    }
    ELLIEModel* theELLIEModel = [objs objectAtIndex:0];

    //////////////////
    // Check if a run is already ongoing
    // If so tell the user and ignore this
    // button press
    if([[theELLIEModel tellieThread] isExecuting]){
        NSLogColor([NSColor redColor], @"[TELLIE]: A tellie fire sequence is already on going. Cannot launch a new one until current sequence has finished\n");
        return;
    }

    if(!([model runTypeWord] & kTELLIERun)){
        ORRunAlertPanel(@"The TELLIE standard run is not loaded.",@"You must load a TELLIE standard run and start a new run before starting a fire sequence",@"OK",nil,nil);
        return;
    }

    /////////////////////
    // Set a flag which defines if we should
    // roll over into maintenance or not.
    [self setTellieStandardSequenceFlag:NO];

    [tellieLoadRunFile setEnabled:NO];
    [tellieRunFileNameField setEnabled:NO];
    [tellieStopRunButton setEnabled:YES];
    [tellieStartRunButton setEnabled:NO];

    //////////////////////
    // Start tellie thread
    [theELLIEModel startTellieRunThread:[self tellieFireSettings] forTELLIE:YES];
}

-(IBAction)startTellieRunAction:(id)sender
{
    
    //////////////////
    // Get ellie model
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ELLIEModel")];
    if (![objs count]) {
        NSLogColor([NSColor redColor], @"ELLIE model not available, add an ELLIE model to your experiment\n");
        return;
    }
    ELLIEModel* theELLIEModel = [objs objectAtIndex:0];
    
    //////////////////
    // Check if a run is already ongoing
    // If so tell the user and ignore this
    // button press
    if([[theELLIEModel tellieThread] isExecuting]){
        NSLogColor([NSColor redColor], @"[TELLIE]: A tellie fire sequence is already on going. Cannot launch a new one until current sequence has finished\n");
        return;
    }

    if(!([model runTypeWord] & kTELLIERun)){
        ORRunAlertPanel(@"The TELLIE standard run is not loaded.",@"You must load a TELLIE standard run and start a new run before starting a fire sequence",@"OK",nil,nil);
        return;
    }

    /////////////////////////
    // Get settings for each node
    NSArray* nodes = [[self tellieRunFile] objectForKey:@"nodes"];
    NSUInteger photons = [[[self tellieRunFile] objectForKey:@"photons_per_pulse"] integerValue];
    NSUInteger no_pulses = [[[self tellieRunFile] objectForKey:@"trigger_per_node"] integerValue];
    NSUInteger rate = [[[self tellieRunFile] objectForKey:@"trigger_rate"] integerValue];
    NSUInteger delay = [[[self tellieRunFile] objectForKey:@"trigger_delay"] integerValue];
    NSUInteger slaveValue = [[[self tellieRunFile] objectForKey:@"slave_mode"] integerValue];
    BOOL inSlave = NO;
    if(slaveValue == 1){
        inSlave = YES;
    }
    NSMutableArray* settingsArray = [NSMutableArray arrayWithCapacity:[nodes count]];
    for(NSNumber* node in nodes){
        NSString* fibre = [theELLIEModel calcTellieFibreForNode:[node integerValue]];
        NSMutableDictionary* settings = [theELLIEModel returnTellieFireCommands:fibre
                                                                   withNPhotons:photons
                                                              withFireFrequency:rate
                                                                    withNPulses:no_pulses
                                                               withTriggerDelay:delay
                                                                        inSlave:inSlave
                                                                      isAMELLIE:@NO];

        [settingsArray addObject:settings];
    }

    /////////////////////
    // Set a flag which defines if we should
    // roll over into maintenance or not.
    [self setTellieStandardSequenceFlag:YES];

    [tellieRunFileNameField setEnabled:NO];
    [tellieStopRunButton setEnabled:YES];
    [tellieStartRunButton setEnabled:NO];

    //////////////////////
    // Start tellie thread
    [theELLIEModel startTellieMultiRunThread:settingsArray forTELLIE:YES];
}

- (IBAction) stopTellieRunAction:(id)sender
{
    //Collect a series of objects from the ELLIEModel
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ELLIEModel")];
    if (![objs count]) {
        NSLogColor([NSColor redColor], @"ELLIE model not available, add an ELLIE model to your experiment\n");
        return;
    }
    ELLIEModel* theELLIEModel = [objs objectAtIndex:0];

    //Call stop tellie run method to tidy up TELLIE's hardware state
    @try{
        [theELLIEModel stopTellieRun];
    } @catch(NSException* e){
        NSLogColor([NSColor redColor], @"Problem stopping tellie run: %@\n", [e reason]);
        return;
    }

    [self setTellieFireSettings:nil];
}

- (IBAction)emergencyTellieStopAction:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TELLIEEmergencyStop" object:self];
    [tellieLoadRunFile setEnabled:NO];
    [tellieRunFileNameField setEnabled:NO];
    [tellieStartRunButton setEnabled:NO];
    [tellieStopRunButton setEnabled:YES];
}

-(IBAction)loadAmellieRunAction:(id)sender
{
    if([amellieRunFileNameField objectValueOfSelectedItem]!= nil)
    {
        //Loop through all the smellie files in the run list
        for(id key in [self amellieRunFileList]){

            id currentRunFile = [[self amellieRunFileList] objectForKey:key];

            NSString *thisRunFile = [currentRunFile objectForKey:@"name"];
            NSString *requestedRunFile = [amellieRunFileNameField objectValueOfSelectedItem];

            if( [thisRunFile isEqualToString:requestedRunFile]){

                [self setAmellieRunFile:currentRunFile];
                [loadedAmellieRunNameLabel setStringValue:[amellieRunFile objectForKey:@"name"]];
                [model setAmellieRunNameLabel:[NSString stringWithFormat:@"%@",[amellieRunFile objectForKey:@"name"]]];

                NSArray* fibres = [[self amellieRunFile] objectForKey:@"fibres"];
                NSString* fibresString = [fibres componentsJoinedByString:@", "];

                [loadedAmellieFibresLabel setStringValue:fibresString];
                [loadedAmellieIntensityLabel setStringValue:[amellieRunFile objectForKey:@"NHits"]];
                [loadedAmellieFireRateLabel setStringValue:[amellieRunFile objectForKey:@"trigger_rate"]];
                [loadedAmellieNoPulsesLabel setStringValue:[amellieRunFile objectForKey:@"trigger_per_node"]];

                BOOL slaveCheck = [[amellieRunFile objectForKey:@"slave_mode"] boolValue];
                if(slaveCheck){
                    [loadedAmellieOperationLabel setStringValue:@"Slave"];
                } else {
                    [loadedAmellieOperationLabel setStringValue:@"Master"];
                }

                // Estimate run time
                int no_pulses = [[amellieRunFile objectForKey:@"trigger_per_node"] intValue];
                int no_nodes = [fibres count];
                int rate = [[amellieRunFile objectForKey:@"trigger_rate"] intValue];
                float total_time = (no_nodes*no_pulses)/(rate*60)*1.1;
                [loadedAmellieRunTimeLabel setStringValue:[NSString stringWithFormat:@"%0.1f",total_time]];
            }
        }
        //Activate run buttons
        [amellieStartRunButton setEnabled:YES];
        [amellieStopRunButton setEnabled:YES];
    }
    else{
        [loadedAmellieRunNameLabel setStringValue:@""];
        [loadedAmellieRunTimeLabel setStringValue:@""];
        [loadedAmellieFibresLabel setStringValue:@""];
        [loadedAmellieIntensityLabel setStringValue:@""];
        [loadedAmellieFireRateLabel setStringValue:@""];
        [loadedAmellieNoPulsesLabel setStringValue:@""];
        [loadedAmellieOperationLabel setStringValue:@""];
        NSLog(@"Main SNO+ Control: Please choose an Amellie Run File from selection\n");
    }
}

-(void)startAmellieRunNotification:(NSNotification *)note;
{
    [self setAmellieFireSettings:[note userInfo]];

    //////////////////
    // Get ellie model and launch a fire
    // sequence
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ELLIEModel")];
    if (![objs count]) {
        NSLogColor([NSColor redColor], @"ELLIE model not available, add an ELLIE model to your experiment\n");
        return;
    }
    ELLIEModel* theELLIEModel = [objs objectAtIndex:0];

    //////////////////
    // Check if a run is already ongoing
    // If so tell the user and ignore this
    // button press
    if([[theELLIEModel tellieThread] isExecuting]){
        NSLogColor([NSColor redColor], @"[AMELLIE]: A fire sequence is already on going. Cannot launch a new one until current sequence has finished\n");
        return;
    }

    if(!([model runTypeWord] & kAMELLIERun)){
         ORRunAlertPanel(@"The AMELLIE standard run is not loaded.",@"You must load a AMELLIE standard run and start a new run before starting a fire sequence",@"OK",nil,nil);
         return;
     }

    /////////////////////
    // Set a flag which defines if we should
    // roll over into maintenance or not.
    [self setTellieStandardSequenceFlag:NO];

    [amellieLoadRunFile setEnabled:NO];
    [amellieRunFileNameField setEnabled:NO];
    [amellieStopRunButton setEnabled:YES];
    [amellieStartRunButton setEnabled:NO];

    //////////////////////
    // Start tellie thread
    [theELLIEModel startTellieRunThread:[self amellieFireSettings] forTELLIE:NO];
}

-(IBAction)startAmellieRunAction:(id)sender
{
    //////////////////
    // Get ellie model
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ELLIEModel")];
    if (![objs count]) {
        NSLogColor([NSColor redColor], @"ELLIE model not available, add an ELLIE model to your experiment\n");
        return;
    }
    ELLIEModel* theELLIEModel = [objs objectAtIndex:0];

    //////////////////
    // Check if a run is already ongoing
    // If so tell the user and ignore this
    // button press
    if([[theELLIEModel tellieThread] isExecuting]){
        NSLogColor([NSColor redColor], @"[AMELLIE]: A fire sequence is already on going. Cannot launch a new one until current sequence has finished\n");
        return;
    }

     if(!([model runTypeWord] & kAMELLIERun)){
         ORRunAlertPanel(@"The AMELLIE standard run is not loaded.",@"You must load a AMELLIE standard run and start a new run before starting a fire sequence",@"OK",nil,nil);
     return;
     }

    /////////////////////////
    // Get settings for each node
    NSArray* fibres = [[self amellieRunFile] objectForKey:@"fibres"];
    NSUInteger photons = [[[self amellieRunFile] objectForKey:@"photons"] integerValue];
    NSUInteger no_pulses = [[[self amellieRunFile] objectForKey:@"trigger_per_node"] integerValue];
    NSUInteger rate = [[[self amellieRunFile] objectForKey:@"trigger_rate"] integerValue];
    NSUInteger delay = [[[self amellieRunFile] objectForKey:@"trigger_delay"] integerValue];
    NSUInteger slaveValue = [[[self amellieRunFile] objectForKey:@"slave_mode"] integerValue];
    BOOL inSlave = NO;
    if(slaveValue == 1){
        inSlave = YES;
    }
    NSMutableArray* settingsArray = [[NSMutableArray alloc] init];
    for(NSString* fibre in fibres){
        NSMutableDictionary* settings = [theELLIEModel returnTellieFireCommands:fibre
                                                                   withNPhotons:photons
                                                              withFireFrequency:rate
                                                                    withNPulses:no_pulses
                                                               withTriggerDelay:delay
                                                                        inSlave:inSlave
                                                                      isAMELLIE:@YES];

        [settingsArray addObject:settings];
    }

    /////////////////////
    // Set a flag which defines if we should
    // roll over into maintenance or not.
    [self setTellieStandardSequenceFlag:YES];

    [amellieRunFileNameField setEnabled:NO];
    [amellieStopRunButton setEnabled:YES];
    [amellieStartRunButton setEnabled:NO];

    //////////////////////
    // Start tellie thread
    [theELLIEModel startTellieMultiRunThread:settingsArray forTELLIE:NO];
    [settingsArray release];
}

- (IBAction) stopAmellieRunAction:(id)sender
{
    [self stopTellieRunAction:nil];
    [self setAmellieFireSettings:nil];
}

- (IBAction)emergencyAmellieStopAction:(id)sender
{
    //////////////////////////////
    // Emergency stop for AMELLIE and TELLIE is handeled identically,
    // just need to update correct gui elements.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TELLIEEmergencyStop" object:self];
    [amellieLoadRunFile setEnabled:NO];
    [amellieRunFileNameField setEnabled:NO];
    [amellieStartRunButton setEnabled:NO];
    [amellieStopRunButton setEnabled:YES];
}


- (IBAction) runsLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORSNOPRunsLockNotification to:[sender intValue] forWindow:[self window]];
}

- (IBAction)refreshRunWordLabels:(id)sender
{
    for(int ibit=0;ibit<32;ibit++){
        NSString *aName = [NSString stringWithUTF8String:RunTypeWordBitNames[ibit]];
        [[runTypeWordMatrix cellAtRow:ibit column:0] setTitle:aName];
    }
}

- (IBAction)runTypeWordAction:(id)sender
{
    short bit = [sender selectedRow];
    BOOL state  = [[sender selectedCell] state];
    unsigned long currentRunMask = [model runTypeWord];
    if(state) currentRunMask |= (1L<<bit);
    else      currentRunMask &= ~(1L<<bit);
    //Unset bits for the mutually exclusive part so that it's impossible to mess up with it
    if(bit<11){
        for(int i=0; i<11; i++){
            currentRunMask &= ~(1L<<i);
        }
        if(state) currentRunMask |= (1L<<bit);
        else      currentRunMask &= ~(1L<<bit);
    }

    [runControl setRunType:currentRunMask];
}

- (void) runsLockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress				= [gOrcaGlobals runInProgress];
    BOOL locked						= [gSecurity isLocked:ORSNOPRunsLockNotification];
    BOOL lockedOrNotRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORSNOPRunsLockNotification];
    BOOL notRunningOrInMaintenance = isNotRunningOrIsInMaintenance();

    //[softwareTriggerButton setEnabled: !locked && !runInProgress];
    [runsLockButton setState: locked];

    //Enable or disable fields
    [standardRunThresCurrentValues setEnabled:!locked];
    [standardRunSaveButton setEnabled:!locked];
    [standardRunLoadButton setEnabled:!locked];
    [standardRunLoadinHWButton setEnabled:!lockedOrNotRunningMaintenance];
    [triggersOFFButton setEnabled:notRunningOrInMaintenance];

    [timedRunCB setEnabled:!runInProgress];
    [timeLimitField setEnabled:!locked];
    [repeatRunCB setEnabled:!locked];
    [orcaDBIPAddressPU setEnabled:!locked];
    [debugDBIPAddressPU setEnabled:!locked];
    [mtcPort setEnabled:!locked];
    [mtcHost setEnabled:!locked];
    [xl3Port setEnabled:!locked];
    [xl3Host setEnabled:!locked];
    [dataPort setEnabled:!locked];
    [dataHost setEnabled:!locked];
    [logPort setEnabled:!locked];
    [logHost setEnabled:!locked];
    [sessionDBUser setEnabled:!locked];
    [sessionDBPassword setEnabled:!locked];
    [sessionDBName setEnabled:!locked];
    [sessionDBAddress setEnabled:!locked];
    [sessionDBPort setEnabled:!locked];
    [sessionDBLockID setEnabled:!locked];
    [orcaDBUser setEnabled:!locked];
    [orcaDBPswd setEnabled:!locked];
    [orcaDBName setEnabled:!locked];
    [orcaDBPort setEnabled:!locked];
    [orcaDBClearButton setEnabled:!locked];
    [debugDBUser setEnabled:!locked];
    [debugDBPswd setEnabled:!locked];
    [debugDBName setEnabled:!locked];
    [debugDBPort setEnabled:!locked];
    [debugDBClearButton setEnabled:!locked];
    [nhitMonitorAutoPulserRate setEnabled:!locked];
    [nhitMonitorAutoNumPulses setEnabled:!locked];
    [nhitMonitorAutoMaxNhit setEnabled:!locked];
    [nhitMonitorRunTypeWordMatrix setEnabled:!locked];
    [nhitMonitorCrateMaskMatrix setEnabled:!locked];
    [nhitMonitorTimeInterval setEnabled:!locked];

    //Do not lock detector state bits to the operator
    for(int irow=0;irow<21;irow++){
        [[runTypeWordMatrix cellAtRow:irow column:0] setEnabled:!lockedOrNotRunningMaintenance];
    }
    [rampDownCrateButton setEnabled:notRunningOrInMaintenance];
    [inMaintenanceLabel setHidden:notRunningOrInMaintenance];

    //Display status
    if(![gSecurity numberItemsUnlocked]){
        [lockStatusTextField setStringValue:@"OPERATOR MODE"];
        [lockStatusTextField setBackgroundColor:snopBlueColor];
    }
    else if(runInProgress){
        [lockStatusTextField setStringValue:@"RUN IN PROGRESS"];
        [lockStatusTextField setBackgroundColor:snopGreenColor];

        if([runControl runType] & kMaintenanceRun){
            [lockStatusTextField setStringValue:@"RUN IN MAINTENANCE"];
            [lockStatusTextField setBackgroundColor:snopOrangeColor];
        }
        else if ([runControl runType] & kDiagnosticRun){
            [lockStatusTextField setStringValue:@"DIAGNOSTIC RUN"];
            [lockStatusTextField setBackgroundColor:snopOrangeColor];
        }

    }
    else{
        [lockStatusTextField setStringValue:@"EXPERT MODE"];
        [lockStatusTextField setBackgroundColor:snopRedColor];
    }
    
}

- (void) runsECAChanged:(NSNotification*)aNotification
{

    //Refresh values in GUI to match the model
    int index = [[model anECARun] ECA_pattern];
    if(index < 0)
    {
        NSLogColor([NSColor redColor], @"ECA bad index returned\n");
        return;
    }
    [ECApatternPopUpButton selectItemAtIndex:index];
    [ECAtypePopUpButton selectItemWithTitle:[[model anECARun] ECA_type]];
    int integ = [[model anECARun] ECA_tslope_pattern];
    [TSlopePatternTextField setIntValue:integ];
    integ = [[model anECARun] ECA_nevents];
    [ecaNEventsTextField setIntValue:integ];
    [ecaPulserRate setObjectValue:[[model anECARun] ECA_rate]];

    if([[aNotification name] isEqualTo:ORECARunStartedNotification]) {
        [ECApatternPopUpButton setEnabled:false];
        [ECAtypePopUpButton setEnabled:false];
        [ecaNEventsTextField setEnabled:false];
        [ecaPulserRate setEnabled:false];
    }
    else if([[aNotification name] isEqualTo:ORECARunFinishedNotification]){
        [ECApatternPopUpButton setEnabled:true];
        [ECAtypePopUpButton setEnabled:true];
        [ecaNEventsTextField setEnabled:true];
        [ecaPulserRate setEnabled:true];
    }

}

- (void) ECAStatusChanged
{

    ECARun *theECARun = [model anECARun];

    //Status
    if ([theECARun isFinished]){
        [[ecaStatusMatrix cellAtRow:0 column:0] setStringValue:@"Not running"];
        [[routineStatusMatrix cellAtRow:0 column:0] setStringValue:@"Not running"];
        [[ecaStatusMatrix cellAtRow:0 column:0] setTextColor:[NSColor blackColor]];
        [[routineStatusMatrix cellAtRow:0 column:0] setTextColor:[NSColor blackColor]];
    }
    else if ([theECARun isExecuting]){
        [[ecaStatusMatrix cellAtRow:0 column:0] setStringValue:@"Running"];
        [[routineStatusMatrix cellAtRow:0 column:0] setStringValue:@"Running"];
        [[ecaStatusMatrix cellAtRow:0 column:0] setTextColor:[NSColor redColor]];
        [[routineStatusMatrix cellAtRow:0 column:0] setTextColor:[NSColor redColor]];
    }
    //Mode
    [[ecaStatusMatrix cellAtRow:1 column:0] setStringValue:[theECARun ECA_mode_string]];
    //Pattern
    [[ecaStatusMatrix cellAtRow:2 column:0] setStringValue:[theECARun ECA_pattern_string]];
    //Type
    [[ecaStatusMatrix cellAtRow:3 column:0] setStringValue:[theECARun ECA_type]];
    //Number of events
    [[ecaStatusMatrix cellAtRow:4 column:0] setIntValue:[theECARun ECA_nevents]];
    //Rate
    [[ecaStatusMatrix cellAtRow:5 column:0] setObjectValue:[theECARun ECA_rate]];
    //Step
    NSString * ecaStepLabel = [NSString stringWithFormat:@"%d/%d",[theECARun ECA_currentStep],[theECARun ECA_nsteps] ];
    [[ecaStatusMatrix cellAtRow:6 column:0] setStringValue:ecaStepLabel];
    //TSlope point
    NSString * ecaPointLabel = [NSString stringWithFormat:@"%d/%d",[theECARun ECA_currentPoint],[theECARun ECA_tslope_pattern] ];
    if([[theECARun ECA_type] isEqualToString:@"PDST"]) ecaPointLabel = @"--";
    [[ecaStatusMatrix cellAtRow:7 column:0] setStringValue:ecaPointLabel];
    //Delay
    [[ecaStatusMatrix cellAtRow:8 column:0] setDoubleValue:[theECARun ECA_currentDelay]];

}

//ECA RUNS
- (IBAction)ecaPatternChangedAction:(id)sender
{
    int value = (int)[ECApatternPopUpButton indexOfSelectedItem];
    [[model anECARun] setECA_pattern:value];
}

- (IBAction)ecaTypeChangedAction:(id)sender
{
    [[model anECARun] setECA_type:[ECAtypePopUpButton titleOfSelectedItem]];
}

- (IBAction)ecaTSlopePatternChangedAction:(id)sender
{
    int value = [TSlopePatternTextField intValue];
    [[model anECARun] setECA_tslope_pattern:value];
}

- (IBAction)ecaNEventsChangedAction:(id)sender
{
    int value = [ecaNEventsTextField intValue];
    [[model anECARun] setECA_nevents:value];
}

- (IBAction)ecaPulserRateAction:(id)sender
{
    [[model anECARun] setECA_rate:[ecaPulserRate objectValue]];
}

//LIVE PEDESTALS
- (IBAction)livePedestalsAction:(id)sender {

    switch ([sender selectedColumn]) {
        case 0:
            [[model livePeds] stop];
            break;
        case 1:
            [[model livePeds] start];
            break;
        default:
            break;
    }

}

- (void) routineStatusChanged:(NSNotification*)aNote
{

    /* GUI updates for the different ORCA threads like ECA, LivePeds, ... */

    // Disable embedded pedestals by default and deal with the
    // logic below
    [livePedRadioButton setEnabled:NO];

    NSDictionary *userInfo = [aNote userInfo];
    if(userInfo == nil) return;
    if ([userInfo objectForKey:@"routine"] == nil) return;
    /* ECAs */
    if ([[userInfo objectForKey:@"routine"] isEqualToString:@"ECA"]){
        [self ECAStatusChanged];
    }
    /* Embedded Pedestals */
    else if ([[userInfo objectForKey:@"routine"] isEqualToString:@"LivePeds"]){
        NSString *status = [userInfo objectForKey:@"status"];
        [[routineStatusMatrix cellAtRow:2 column:0] setStringValue:status];
        [livePedStatusLabel setStringValue:status];

        if ( [[model livePeds] isThreadRunning] ){
            [livePedRadioButton setEnabled:YES];

            if ([[userInfo objectForKey:@"status"] isEqualToString:@"Running"]){
                [[routineStatusMatrix cellAtRow:2 column:0] setTextColor:[NSColor redColor]];
                [livePedStatusLabel setTextColor:[NSColor redColor]];
                [livePedRadioButton setEnabled:YES];
            }
            else if ([[userInfo objectForKey:@"status"] isEqualToString:@"Not Running"]){
                [[routineStatusMatrix cellAtRow:2 column:0] setTextColor:[NSColor blackColor]];
                [livePedStatusLabel setTextColor:[NSColor blackColor]];
                [livePedRadioButton setEnabled:YES];
            }
            else if ([[userInfo objectForKey:@"status"] isEqualToString:@"NHitMonitor ON"]){
                [[routineStatusMatrix cellAtRow:2 column:0] setTextColor:[NSColor redColor]];
                [livePedStatusLabel setTextColor:[NSColor redColor]];
                [livePedRadioButton setEnabled:NO];
            }

        }
        else {
            [[routineStatusMatrix cellAtRow:2 column:0] setTextColor:[NSColor blackColor]];
            [livePedStatusLabel setTextColor:[NSColor blackColor]];
            [livePedRadioButton setEnabled:NO];
        }

    }

    return;

}

//STANDARD RUNS
- (IBAction)standardRunNewValueAction:(id)sender
{
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];
    ORMTCModel* mtcModel;
    if ([objs count]) {
        mtcModel = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find MTC model. Please add it to the experiment and restart the run.\n");
        return;
    }

    int activeCell = [sender selectedRow];
    float raw;
    int threshold_index;
    float threshold_value;
    int units;
    switch (activeCell) {
        //NHIT100HI
        case 0:
            threshold_value = [[sender cellAtRow:0 column:0] floatValue];
            threshold_index = MTC_N100_HI_THRESHOLD_INDEX;
            break;
        //NHIT100MED
        case 1:
            threshold_value = [[sender cellAtRow:1 column:0] floatValue];
            threshold_index = MTC_N100_MED_THRESHOLD_INDEX;
            break;
        //NHIT100LO
        case 2:
            threshold_value = [[sender cellAtRow:2 column:0] floatValue];
            threshold_index = MTC_N100_LO_THRESHOLD_INDEX;
            break;
        //NHIT20
        case 3:
            threshold_value = [[sender cellAtRow:3 column:0] floatValue];
            threshold_index = MTC_N20_THRESHOLD_INDEX;
            break;
        //NHIT20LO
        case 4:
            threshold_value = [[sender cellAtRow:4 column:0] floatValue];
            threshold_index = MTC_N20LB_THRESHOLD_INDEX;
            break;
        //OWLN
        case 5:
            threshold_value = [[sender cellAtRow:5 column:0] floatValue];
            threshold_index = MTC_OWLN_THRESHOLD_INDEX;
            break;
        //ESUMHI
        case 6:
            threshold_value = [[sender cellAtRow:6 column:0] floatValue];
            threshold_index = MTC_ESUMH_THRESHOLD_INDEX;
            break;
        //ESUMLO
        case 7:
            threshold_value = [[sender cellAtRow:7 column:0] floatValue];
            threshold_index = MTC_ESUML_THRESHOLD_INDEX;
            break;
        //OWLEHI
        case 8:
            threshold_value = [[sender cellAtRow:8 column:0] floatValue];
            threshold_index = MTC_OWLEHI_THRESHOLD_INDEX;
            break;
        //OWLELO
        case 9:
            threshold_value = [[sender cellAtRow:9 column:0] floatValue];
            threshold_index = MTC_OWLELO_THRESHOLD_INDEX;
            break;
        //Prescale
        case 10:
            raw = [[sender cellAtRow:10 column:0] floatValue];
            [mtcModel setPrescaleValue:raw];
            return;
            break;
        //Pulser
        case 11:
            raw = [[sender cellAtRow:11 column:0] floatValue];
            [mtcModel setPgtRate:raw];
            return;
            break;
    }
    @try{
        units = [self decideUnitsToUseForRow:activeCell usingModel:mtcModel];
        [mtcModel setThresholdOfType:threshold_index fromUnits:units toValue:threshold_value];
    }
    @catch(NSException *excep) {
        NSLogColor([NSColor redColor], @"Error while trying to set the MTC threshold, reason: %@\n",[excep reason]);
    }
}
- (BOOL) isRowNHit: (int) row {
    return row<6; // All the NHit type thresholds are the first 7...i realize this is a bit weird but it works
    // ...for now
}

- (int) decideUnitsToUseForRow: (int) row usingModel:(id) mtcModel {
    int units;
    if(displayUnitsDecider[row] == UNITS_UNDECIDED)
    {
        if([mtcModel ConversionIsValidForThreshold:view_model_map[row]]) {
            NSString* label = [self isRowNHit:row] ? @"NHits" : @"mV";
            units = [self isRowNHit:row] ? MTC_NHIT_UNITS : MTC_mV_UNITS;
            [[standardRunThreshLabels cellAtRow:row column:0] setStringValue:label];
            displayUnitsDecider[row] = UNITS_CONVERTED;
        }
        else {
            units=  MTC_RAW_UNITS;
            [[standardRunThreshLabels cellAtRow:row column:0] setStringValue:@"Raw DAC Counts"];
            displayUnitsDecider[row] = UNITS_RAW;
        }
    }
    else if (displayUnitsDecider[row] == UNITS_CONVERTED) {
        units = [self isRowNHit:row] ? MTC_NHIT_UNITS : MTC_mV_UNITS;
    }
    else {
        units = MTC_RAW_UNITS;
    }
    return units;
}

-(void) updateThresholdDisplayAt:(int) row isInMask:(BOOL) inMask usingModel:(id) mtcModel andFormatter:(NSFormatter*) formatter
{
    int units = [self decideUnitsToUseForRow:row usingModel:mtcModel];
    float value = [mtcModel getThresholdOfType:view_model_map[row] inUnits:units];

    [[standardRunThresCurrentValues cellAtRow:row column:0] setFloatValue:value];
    [[standardRunThresCurrentValues cellAtRow:row column:0] setFormatter:formatter];

    if(inMask) {
        [[standardRunThresCurrentValues cellAtRow:row column:0] setTextColor:[self snopBlueColor]];
    } else{
        [[standardRunThresCurrentValues cellAtRow:row column:0] setTextColor:[self snopRedColor]];
    }
}

- (void) MTCSettingsChanged:(NSNotification*)aNotification
{
    if(aNotification && [[aNotification name] isEqualToString:ORMTCAConversionChanged])
    {
        [self initializeUnits];
    }
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];
    ORMTCModel* mtcModel;
    if ([objs count]) {
        mtcModel = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find MTC model. Please add it to the experiment and restart the run.\n");
        return;
    }

    //Setup format
    NSNumberFormatter *thresholdFormatter = [[[NSNumberFormatter alloc] init] autorelease];;
    [thresholdFormatter setFormat:@"##0.0"];

    //GTMask
    int gtmask = [mtcModel gtMask];

    for(int i=0;i<10;i++)
    {
        @try {
            BOOL inMask = ((1<<view_mask_map[i]) & gtmask) !=0;
            [self updateThresholdDisplayAt:i isInMask:inMask usingModel:mtcModel andFormatter:thresholdFormatter];
        } @catch (NSException *exception) {
            NSLogColor([NSColor redColor], @"Error while displaying threshold. Reason:%@\n.",[exception reason]);
        }
    }

    //Prescale
    [[standardRunThresCurrentValues cellAtRow:10 column:0] setFloatValue:[mtcModel prescaleValue]];
    [[standardRunThresCurrentValues cellAtRow:10 column:0] setFormatter:thresholdFormatter];
    if((gtmask >> 11) & 1){
        [[standardRunThresCurrentValues cellAtRow:10 column:0] setTextColor:[self snopBlueColor]];
    } else{
        [[standardRunThresCurrentValues cellAtRow:10 column:0] setTextColor:[self snopRedColor]];
    }
    //Pulser
    [[standardRunThresCurrentValues cellAtRow:11 column:0] setFloatValue:[mtcModel pgtRate]];
    [[standardRunThresCurrentValues cellAtRow:11 column:0] setFormatter:thresholdFormatter];
    if((gtmask >> 10) & 1){
        [[standardRunThresCurrentValues cellAtRow:11 column:0] setTextColor:[self snopBlueColor]];
    } else{
        [[standardRunThresCurrentValues cellAtRow:11 column:0] setTextColor:[self snopRedColor]];
    }
    if(aNotification && [[aNotification name] isEqualToString:ORMTCAConversionChanged])
    {
        [self redisplayThresholdValuesUsingModel:mtcModel];
    }

    //LO width
    [[standardRunMTCCurrentValues cellAtRow:0 column:0] setIntValue:[mtcModel lockoutWidth]];
    //Pulser ON
    [[standardRunMTCCurrentValues cellAtRow:1 column:0] setStringValue:([mtcModel pulserEnabled]?@"ON":@"OFF")];
    //Pulser mode (PGT/PED)
    [[standardRunMTCCurrentValues cellAtRow:2 column:0] setStringValue:([mtcModel isPedestalEnabledInCSR]?@"PED":@"PGT")];

    [self highlightDifferencesBetween:standardRunMTCCurrentValues And:standardRunMTCStoredValues];

}

- (void) CAENSettingsChanged:(NSNotification*)aNotification
{
    SNOCaenModel *caenModel = [aNotification object];
    if(caenModel==NULL){
        NSArray* objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOCaenModel")];
        if ([objs count]) {
            caenModel = [objs objectAtIndex:0];
        } else {
            NSLogColor([NSColor redColor], @"couldn't find CAEN model. Please add it to the experiment and restart the run.\n");
            return;
        }
    }
    [self displayCAENSettings:[caenModel serializeToDictionary] inMatrix:standardRunCAENCurrentMatrix];
}

- (void) TUBiiSettingsChanged:(NSNotification*)aNotification
{

    TUBiiModel *tubiiModel = [aNotification object];
    if(tubiiModel==NULL){
        NSArray* objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"TUBiiModel")];
        if ([objs count]) {
            tubiiModel = [objs objectAtIndex:0];
        } else {
            NSLogColor([NSColor redColor], @"couldn't find TUBii model. Please add it to the experiment and restart the run.\n");
            return;
        }
    }
    [self displayTUBiiSettings:[tubiiModel serializeToDictionary] inMatrix:standardRunTUBiiCurrentMatrix];
}

- (IBAction)loadStandardRunFromDBAction:(id)sender
{
    NSString *standardRun = [standardRunPopupMenu objectValueOfSelectedItem];
    NSString *standardRunVer = [standardRunVersionPopupMenu objectValueOfSelectedItem];

    [model loadStandardRun:standardRun withVersion: standardRunVer];
}

- (IBAction)loadCurrentSettingsInHW:(id)sender
{
    BOOL cancel = ORRunAlertPanel(@"Loading current Standard Run settings into Hardware",@"Is this really what you want?",@"Cancel",@"Yes, reload hardware",nil);
    if (!cancel) {
        [model loadSettingsInHW];
    }
}

- (IBAction)saveStandardRunToDBAction:(id)sender
{
    NSString *standardRun = [standardRunPopupMenu objectValueOfSelectedItem];
    NSString *standardRunVer = [standardRunVersionPopupMenu objectValueOfSelectedItem];
    
    if(![model saveStandardRun:standardRun withVersion:standardRunVer]){
        NSLogColor([NSColor redColor], @"Couldn't save standard run due to a problem. \n");
    }
}

// Create a new SR item if doesn't exist, set the runType string value and query the DB to display the trigger configuration
- (IBAction)standardRunPopupAction:(id)sender
{
    NSString *standardRun = [[[standardRunPopupMenu stringValue] uppercaseString] copy];
    [standardRunPopupMenu setStringValue:standardRun];

    // Create new SR if does not exist
    if ([standardRunPopupMenu indexOfItemWithObjectValue:standardRun] == NSNotFound && [standardRun isNotEqualTo:@""]) {
        BOOL cancel = ORRunAlertPanel([NSString stringWithFormat:@"Creating new Standard Run: \"%@\"", standardRun],@"Is this really what you want?",@"Cancel",@"Yes, Make New Standard Run",nil);
        if (cancel) {
            [standardRunPopupMenu selectItemWithObjectValue:[model standardRunType]];
            [standardRunVersionPopupMenu selectItemWithObjectValue:[model standardRunVersion]];
            [standardRun release];
            return;
        } else {
            [standardRunPopupMenu addItemWithObjectValue:standardRun];
            [standardRunVersionPopupMenu addItemWithObjectValue:@"DEFAULT"];
            [model saveStandardRun:standardRun withVersion:@"DEFAULT"];
        }
    }
    
    // Set run type name
    if(![[model standardRunType] isEqualToString:standardRun]) {
        [model setStandardRunType:standardRun];
    }

    [standardRun release];
}

- (IBAction)standardRunVersionPopupAction:(id)sender
{
    NSString *standardRun = [[[standardRunPopupMenu stringValue] uppercaseString] copy];
    NSString *standardRunVer = [[[standardRunVersionPopupMenu stringValue] uppercaseString] copy];
    [standardRunVersionPopupMenu setStringValue:standardRunVer];

    // Create new SR version if does not exist
    if ([standardRunVersionPopupMenu indexOfItemWithObjectValue:standardRunVer] == NSNotFound && [standardRunVer isNotEqualTo:@""]) {
        if ([standardRun isEqualToString:@"DIAGNOSTIC"]) {
            NSLog(@"You cannot create a version for a DIAGNOSTIC run.\n");
            [standardRun release];
            [standardRunVer release];
            return;
        }

        BOOL cancel = ORRunAlertPanel([NSString stringWithFormat:@"Creating new Version: \"%@\" of Standard Run: \"%@\"", standardRunVer, standardRun], @"Is this really what you want?",@"Cancel",@"Yes, Make New Version",nil);
        if (cancel) {
            [standardRunVersionPopupMenu selectItemWithObjectValue:[model standardRunVersion]];
        } else {
            [standardRunVersionPopupMenu addItemWithObjectValue:standardRunVer];
            [standardRunVersionPopupMenu selectItemWithObjectValue:standardRunVer];
            [model saveStandardRun:standardRun withVersion:standardRunVer];
        }
    }
    
    // Set run type name
    if (![[model standardRunVersion] isEqualToString:standardRunVer]) {
        [model setStandardRunVersion:standardRunVer];
    }

    [standardRun release];
    [standardRunVer release];
}

//Run Type Word
- (void) runTypeWordChanged:(NSNotification*)aNote
{

    if ([[aNote name] isEqualTo:ORRunTypeChangedNotification]) {
        unsigned long currentRunWord = [runControl runType];
        [model setRunTypeWord:currentRunWord];
    }

    //Update display
    for(int i=0;i<32;i++){
        [[runTypeWordMatrix cellAtRow:i column:0] setState:([model runTypeWord] &(1L<<i))!=0];
    }
    
}

- (void) redisplayThresholdValuesUsingModel: (id)mtcModel {
    int units;
    float value;
    for(int i=0; i<10; i++) {
        if(thresholdsFromDB[i] > 0) {
            units = [self decideUnitsToUseForRow:i usingModel:mtcModel];
            value = [mtcModel convertThreshold:thresholdsFromDB[i] OfType:view_model_map[i] fromUnits:MTC_RAW_UNITS toUnits:units];
            [[standardRunThresStoredValues cellAtRow:i column:0] setFloatValue:value];
        }
    }
}

- (void) updateSingleDBThresholdDisplayForRow:(int) row inMask:(BOOL) inMask withModel:(id) mtcModel withFormatter:(NSFormatter*) formatter toValue:(float) raw {
    float value;
    int units;
    @try {
        units = [self decideUnitsToUseForRow:row usingModel:mtcModel];
        value = [mtcModel convertThreshold:raw OfType:view_model_map[row] fromUnits:MTC_RAW_UNITS toUnits:units];
    } @catch (NSException *excep) {
        NSLogColor([NSColor redColor], @"Failed to convert the thresholds from raw units. Reason: %@\n",[excep reason]);
    }
    [[standardRunThresStoredValues cellAtRow:row column:0] setFormatter:formatter];
    [[standardRunThresStoredValues cellAtRow:row column:0] setFloatValue:value];
    if(inMask) {
        [[standardRunThresStoredValues cellAtRow:row column:0] setTextColor:[self snopBlueColor]];
    } else{
        [[standardRunThresStoredValues cellAtRow:row column:0] setTextColor:[self snopRedColor]];
    }
    thresholdsFromDB[row] = raw;
}

//Query the DB for the selected Standard Run name and version
//and display the values in the GUI.
-(void) displayThresholdsFromDB
{

    NSMutableDictionary* runSettings = [[[model standardRunCollection] objectForKey:[model standardRunType]] objectForKey:[model standardRunVersion]];
    if(runSettings == nil){
        for (int i=0; i<[standardRunThresStoredValues numberOfRows];i++) {
            [[standardRunThresStoredValues cellAtRow:i column:0] setStringValue:@"--"];
            [[standardRunThresStoredValues cellAtRow:i column:0] setTextColor:[self snopRedColor]];
            if(i <10){
                thresholdsFromDB[i] = -1;
            }
        }
        for(int ibit=0; ibit<21; ibit++){ //Data quality bits are not stored in the SR
            [[runTypeWordSRMatrix cellAtRow:ibit column:0] setState:0];
        }
        return;
    }

    //Get run type word first
    unsigned long dbruntypeword = [[runSettings valueForKey:@"run_type_word"] unsignedLongValue];

    //If in DIAGNOSTIC run: display null threshold values
    if(dbruntypeword & kDiagnosticRun){
        for (int i=0; i<[standardRunThresStoredValues numberOfRows];i++) {
            [[standardRunThresStoredValues cellAtRow:i column:0] setStringValue:@"--"];
            [[standardRunThresStoredValues cellAtRow:i column:0] setTextColor:[self snopRedColor]];
            if(i <10){
                thresholdsFromDB[i] = -1;
            }
        }
        for(int ibit=0; ibit<21; ibit++){ //Data quality bits are not stored in the SR
            [[runTypeWordSRMatrix cellAtRow:ibit column:0] setState:0];
        }
    //If in non-DIAGNOSTIC run: display DB threshold values
    } else {
        //MTC
        [self displayMTCSettings:runSettings];
        //CAEN
        [self displayCAENSettings:runSettings inMatrix:standardRunCAENDBMatrix];
        //TUBii
        [self displayTUBiiSettings:runSettings inMatrix:standardRunTUBiiDBMatrix];
    }
    
    //Display runtype word
    for(int ibit=0; ibit<21; ibit++){ //Data quality bits are not stored in the SR
        if((dbruntypeword >> ibit) & 1){
            [[runTypeWordSRMatrix cellAtRow:ibit column:0] setState:1];
        } else{
            [[runTypeWordSRMatrix cellAtRow:ibit column:0] setState:0];
        }
    }
}

- (void) displayMTCSettings:(NSMutableDictionary*)settingsDict
{
    /* Get models */
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];
    ORMTCModel* mtcModel;
    if ([objs count]) {
        mtcModel = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find MTC model. Please add it to the experiment and restart the run.\n");
        return;
    }

    //Setup format
    NSNumberFormatter *thresholdFormatter = [[[NSNumberFormatter alloc] init] autorelease];;
    [thresholdFormatter setFormat:@"##0.0"];

    float mVolts;
    int gtmask = [[settingsDict valueForKey:GTMaskSerializationString] intValue];

    for(int i=0;i<10;i++) {
        float raw = [[settingsDict valueForKey:[mtcModel stringForThreshold:view_model_map[i]]] floatValue];
        BOOL inMask = ((1<< view_mask_map[i]) & gtmask) != 0;
        [self updateSingleDBThresholdDisplayForRow:i inMask:inMask withModel:mtcModel withFormatter:thresholdFormatter toValue:raw];
    }

    //Prescale
    mVolts = [[settingsDict valueForKey:PrescaleValueSerializationString] floatValue];
    [[standardRunThresStoredValues cellAtRow:10 column:0] setFloatValue:mVolts];
    [[standardRunThresStoredValues cellAtRow:10 column:0] setFormatter:thresholdFormatter];
    if((gtmask >> 11) & 1){
        [[standardRunThresStoredValues cellAtRow:10 column:0] setTextColor:[self snopBlueColor]];
    } else{
        [[standardRunThresStoredValues cellAtRow:10 column:0] setTextColor:[self snopRedColor]];
    }
    //Pulser
    mVolts = [[settingsDict valueForKey:PulserRateSerializationString] floatValue];
    [[standardRunThresStoredValues cellAtRow:11 column:0] setFloatValue:mVolts];
    [[standardRunThresStoredValues cellAtRow:11 column:0] setFormatter:thresholdFormatter];
    if((gtmask >> 10) & 1){
        [[standardRunThresStoredValues cellAtRow:11 column:0] setTextColor:[self snopBlueColor]];
    } else{
        [[standardRunThresStoredValues cellAtRow:11 column:0] setTextColor:[self snopRedColor]];
    }
    //LO width
    [[standardRunMTCStoredValues cellAtRow:0 column:0] setIntValue:[[settingsDict valueForKey:LockOutWidthSerializationString] intValue]];
    //Pulser ON
    [[standardRunMTCStoredValues cellAtRow:1 column:0] setStringValue:[[settingsDict valueForKey:PulserEnabledSerializationString] boolValue]?@"ON":@"OFF"];
    //Pulser mode (PGT/PED)
    [[standardRunMTCStoredValues cellAtRow:2 column:0] setStringValue:[[settingsDict valueForKey:PGT_PED_Mode_SerializationString] boolValue]?@"PED":@"PGT"];

    [self highlightDifferencesBetween:standardRunMTCCurrentValues And:standardRunMTCStoredValues];

}


- (void) displayCAENSettings:(NSMutableDictionary*) settingsDict inMatrix:(NSMatrix*)aMatrix
{
    NSArray* objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOCaenModel")];
    SNOCaenModel* caenModel;
    if ([objs count]) {
        caenModel = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find CAEN model. Please add it to the experiment and restart the run.\n");
        return;
    }

    NSNumberFormatter *dacFormat = [[NSNumberFormatter alloc] init];
    [dacFormat setFormat:@"##.##"];
    [[aMatrix cellAtRow:0 column:0] setObjectValue:[NSString stringWithFormat:@"0x%X",[[settingsDict valueForKey:@"CAEN_enabledMask"] unsignedIntValue]]];
    [[aMatrix cellAtRow:1 column:0] setFloatValue:[caenModel convertDacToVolts:[[settingsDict valueForKey:@"CAEN_dac_0"] unsignedShortValue]]];
    [[aMatrix cellAtRow:1 column:0] setFormatter:dacFormat];
    [[aMatrix cellAtRow:2 column:0] setFloatValue:[caenModel convertDacToVolts:[[settingsDict valueForKey:@"CAEN_dac_1"] unsignedShortValue]]];
    [[aMatrix cellAtRow:2 column:0] setFormatter:dacFormat];
    [[aMatrix cellAtRow:3 column:0] setFloatValue:[caenModel convertDacToVolts:[[settingsDict valueForKey:@"CAEN_dac_2"] unsignedShortValue]]];
    [[aMatrix cellAtRow:3 column:0] setFormatter:dacFormat];
    [[aMatrix cellAtRow:4 column:0] setFloatValue:[caenModel convertDacToVolts:[[settingsDict valueForKey:@"CAEN_dac_3"] unsignedShortValue]]];
    [[aMatrix cellAtRow:4 column:0] setFormatter:dacFormat];
    [[aMatrix cellAtRow:5 column:0] setFloatValue:[caenModel convertDacToVolts:[[settingsDict valueForKey:@"CAEN_dac_4"] unsignedShortValue]]];
    [[aMatrix cellAtRow:5 column:0] setFormatter:dacFormat];
    [[aMatrix cellAtRow:6 column:0] setFloatValue:[caenModel convertDacToVolts:[[settingsDict valueForKey:@"CAEN_dac_5"] unsignedShortValue]]];
    [[aMatrix cellAtRow:6 column:0] setFormatter:dacFormat];
    [[aMatrix cellAtRow:7 column:0] setFloatValue:[caenModel convertDacToVolts:[[settingsDict valueForKey:@"CAEN_dac_6"] unsignedShortValue]]];
    [[aMatrix cellAtRow:7 column:0] setFormatter:dacFormat];
    [[aMatrix cellAtRow:8 column:0] setFloatValue:[caenModel convertDacToVolts:[[settingsDict valueForKey:@"CAEN_dac_7"] unsignedShortValue]]];
    [[aMatrix cellAtRow:8 column:0] setFormatter:dacFormat];
    [[aMatrix cellAtRow:9 column:0] setObjectValue:[NSString stringWithFormat:@"0x%X",[[settingsDict valueForKey:@"CAEN_triggerSourceMask"] unsignedIntValue]]];
    [[aMatrix cellAtRow:10 column:0] setObjectValue:[NSString stringWithFormat:@"0x%X",[[settingsDict valueForKey:@"CAEN_triggerOutMask"] unsignedIntValue]]];
    [[aMatrix cellAtRow:11 column:0] setObjectValue:[settingsDict valueForKey:@"CAEN_coincidenceLevel"]];
    [[aMatrix cellAtRow:12 column:0] setObjectValue:[NSString stringWithFormat:@"%@",[[settingsDict valueForKey:@"CAEN_countAllTriggers"] boolValue]? @"YES":@"NO"]];
    [[aMatrix cellAtRow:13 column:0] setObjectValue:[NSString stringWithFormat:@"%@",[[settingsDict valueForKey:@"CAEN_isCustomSize"] boolValue]? @"YES":@"NO"]];
    [[aMatrix cellAtRow:14 column:0] setObjectValue:[settingsDict valueForKey:@"CAEN_eventSize"]];
    [[aMatrix cellAtRow:15 column:0] setIntValue:[[settingsDict valueForKey:@"CAEN_customSize"] unsignedIntValue]*4];
    [[aMatrix cellAtRow:16 column:0] setIntValue:[[settingsDict valueForKey:@"CAEN_postTriggerSetting"] unsignedIntValue]*4];
    [[aMatrix cellAtRow:17 column:0] setObjectValue:[NSString stringWithFormat:@"0x%X",[[settingsDict valueForKey:@"CAEN_channelConfigMask"] unsignedShortValue]]];
    [[aMatrix cellAtRow:18 column:0] setObjectValue:[settingsDict valueForKey:@"CAEN_acquisitionMode"]];
    [[aMatrix cellAtRow:19 column:0] setObjectValue:[NSString stringWithFormat:@"0x%X",[[settingsDict valueForKey:@"CAEN_frontPanelControlMask"] unsignedIntValue]]];

    [dacFormat release];

    [self highlightDifferencesBetween:standardRunCAENCurrentMatrix And:standardRunCAENDBMatrix];

}


- (void) displayTUBiiSettings:(NSMutableDictionary*)settingsDict inMatrix:(NSMatrix*)aMatrix
{

    NSArray* objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"TUBiiModel")];
    TUBiiModel* tubiiModel;
    if ([objs count]) {
        tubiiModel = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find TUBii model. Please add it to the experiment and restart the run.\n");
        return;
    }

    NSNumberFormatter *format = [[NSNumberFormatter alloc] init];
    [format setFormat:@"#.###"];
    [[aMatrix cellAtRow:0 column:0] setIntValue:[[settingsDict valueForKey:@"TUBii_TUBiiPGT_Rate"] intValue]]; //for formatting purposes
    [[aMatrix cellAtRow:1 column:0] setObjectValue:[NSString stringWithFormat:@"0x%X",[[settingsDict valueForKey:@"TUBii_syncTrigMask"] unsignedIntValue]]];
    [[aMatrix cellAtRow:2 column:0] setObjectValue:[NSString stringWithFormat:@"0x%X",[[settingsDict valueForKey:@"TUBii_asyncTrigMask"] unsignedIntValue]]];
    [[aMatrix cellAtRow:3 column:0] setObjectValue:[NSString stringWithFormat:@"0x%X",[[settingsDict valueForKey:@"TUBii_CaenChannelMask"] unsignedIntValue]]];
    [[aMatrix cellAtRow:4 column:0] setObjectValue:[NSString stringWithFormat:@"0x%X",[[settingsDict valueForKey:@"TUBii_CaenGainMask"] unsignedIntValue]]];
    [[aMatrix cellAtRow:5 column:0] setObjectValue:[NSString stringWithFormat:@"0x%X",[[settingsDict valueForKey:@"TUBii_counterMask"] unsignedIntValue]]];
    [[aMatrix cellAtRow:6 column:0] setObjectValue:[NSString stringWithFormat:@"0x%X",[[settingsDict valueForKey:@"TUBii_speakerMask"] unsignedIntValue]]];
    [[aMatrix cellAtRow:7 column:0] setFloatValue:[tubiiModel MTCAMimic_BitsToVolts:[[settingsDict valueForKey:@"TUBii_MTCAMimic1_ThresholdInBits"] integerValue]]];
    [[aMatrix cellAtRow:7 column:0] setFormatter:format];
    [[aMatrix cellAtRow:8 column:0] setIntegerValue:[tubiiModel DGT_BitsToNanoSeconds:[[settingsDict valueForKey:@"TUBii_DGT_Bits"] integerValue]]];
    [[aMatrix cellAtRow:9 column:0] setIntegerValue:[tubiiModel LODelay_BitsToNanoSeconds:[[settingsDict valueForKey:@"TUBii_LO_Bits"] integerValue]]];
    [[aMatrix cellAtRow:10 column:0] setObjectValue:[NSString stringWithFormat:@"0x%X",[[settingsDict valueForKey:@"TUBii_controlReg"] unsignedIntValue]]];

    [self highlightDifferencesBetween:standardRunTUBiiCurrentMatrix And:standardRunTUBiiDBMatrix];

    [format release];
}

- (void) highlightDifferencesBetween:(NSMatrix*)aMatrix And:(NSMatrix*)bMatrix
{
    NSInteger aNEntries = [aMatrix numberOfRows];
    NSInteger bNEntries = [bMatrix numberOfRows];
    if(aNEntries != bNEntries) NSLogColor([NSColor redColor], @"Problem highlighting differences for matrices! Different number of rows. \n");

    for(int irow=0; irow<aNEntries; irow++){
        if( [[[aMatrix cellAtRow:irow column:0] stringValue] isEqualToString:[[bMatrix cellAtRow:irow column:0] stringValue]] )
            [[aMatrix cellAtRow:irow column:0] setTextColor:snopBlackColor];
        else
            [[aMatrix cellAtRow:irow column:0] setTextColor:snopRedColor];
    }
}

- (IBAction) refreshStandardRunsAction:(id)sender
{
    [model refreshStandardRunsFromDB];
}

-(void) standardRunsCollectionChanged:(NSNotification*)aNote
{
    // Clear popup menus
    [standardRunPopupMenu removeAllItems];
    [standardRunVersionPopupMenu removeAllItems];

    // Populate run type popup menu
    for(NSString* aStandardRunType in [model standardRunCollection]){
        [standardRunPopupMenu addItemWithObjectValue:aStandardRunType];
    }
}

-(void) refreshStandardRunVersions
{
    [standardRunVersionPopupMenu deselectItemAtIndex:[standardRunVersionPopupMenu indexOfSelectedItem]];
    [standardRunVersionPopupMenu removeAllItems];

    NSString* standardRunVersion = [model standardRunVersion];
    // Populate run version popup menu
    for (NSString* aStandardRunVersion in [[model standardRunCollection] objectForKey:[model standardRunType]]) {
        [standardRunVersionPopupMenu addItemWithObjectValue:aStandardRunVersion];
    }

    //If there are no versions -> Nothing
    if ([standardRunVersionPopupMenu numberOfItems] == 0 || standardRunVersion == nil || [standardRunVersion isEqualToString:@""]) {
        //Nothing
    }
    //If previous selected version do not exist -> select DEFAULT
    else if ([standardRunVersionPopupMenu indexOfItemWithObjectValue:standardRunVersion] == NSNotFound) {
        [standardRunVersionPopupMenu selectItemWithObjectValue:@"DEFAULT"];
    }
    //else -> recover previous version
    else {
        [standardRunVersionPopupMenu selectItemWithObjectValue:standardRunVersion];
    }
}

@end
