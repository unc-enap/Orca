//
//  ECARun.m
//  Orca
//
//  Created by Javier Caravaca on 1/12/17.
//
//

#import "ECARun.h"
#import "ORRunModel.h"
#import "SNOPModel.h"
#import "ORMTCModel.h"
#import "ORXL3Model.h"
#import "ORFec32Model.h"
#import "ECAPatterns.h"
#import "ORMTC_Constants.h"
#import "RunTypeWordBits.hh"

//Notifications
NSString* ORECARunChangedNotification = @"ORECARunChangedNotification";
NSString* ORECARunStartedNotification = @"ORECARunStartedNotification";
NSString* ORECARunFinishedNotification = @"ORECARunFinishedNotification";

/* This flag must DISABLED for commissioning
 * and normal detector running. Enable it only
 * for testing. */
// #define __TESTING__ 1

/* Definitions */
// Defaults
#define ECA_COARSE_DELAY 150 //ns
#define ECA_FINE_DELAY 0 //ps
#define ECA_PEDESTAL_WIDTH 50 //ns

//ECA Standard values
#define ECA_PDST_TYPE @"PDST"
#define ECA_PDST_RATE 10
#define ECA_PDST_PATTERN 4
#define ECA_PDST_NEVENTS 14
#define ECA_TSLP_TYPE @"TSLP"
#define ECA_TSLP_RATE 200
#define ECA_TSLP_PATTERN 4
#define ECA_TSLP_NEVENTS 11


@implementation ECARun

- (id) init
{
    self = [super init];
    ECAThread = [[NSThread alloc] init]; //Init empty
    start_eca_run = FALSE;
    isFinishing = FALSE;
    isFinished = TRUE;
    return self;

}

- (void) dealloc
{
    [ECAThread release];
    [super dealloc];
}

- (void) stop
{

    /*User intervention to stop the ECA run */

    //Hold the current run until the ECAs are done
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"waiting for ECA run to finish", @"Reason",
                              nil];
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORAddRunStateChangeWait object: self userInfo: userInfo];

    /*Set Thread to be cancelled. Only the thread itself can exit.
     This is done by checking the 'cancel' condition within the
     loop of the thread itself. */
    start_eca_run = FALSE;
    [ECAThread cancel];

}

- (BOOL) isExecuting
{
    return [ECAThread isExecuting];
}

- (BOOL) isFinished
{
    return isFinished;
}

- (BOOL) isFinishing
{
    return isFinishing;
}

- (bool) setECASettings
{
    /* Set ECA parameters based on the run type word and
     * harcoded settings needed for the ECA algorithm */

    isFinished = NO;
    start_eca_run = NO;
    isFinishing = NO;

    NSArray* objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    if (![objs count]) {
        NSLogColor([NSColor redColor], @"setECASettings: SNO+ control not found.\n");
        goto err;
    }
    aSNOPModel = [objs objectAtIndex:0];

    objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if (![objs count]) {
        NSLogColor([NSColor redColor], @"setECASettings: Run control not found.\n");
        goto err;
    }
    ORRunModel *aRunModel = [objs objectAtIndex:0];
    uint32_t runTypeWord = [aRunModel runType];
    //Load hardcoded values if requested
    if([[aSNOPModel standardRunVersion] isEqualToString:@"ECA_PDST_STANDARD"]){
        //Pedestal run
        [self setECA_type:ECA_PDST_TYPE];
        [self setECA_rate:[NSNumber numberWithInt:ECA_PDST_RATE]];
        [self setECA_pattern:ECA_PDST_PATTERN];
        [self setECA_nevents:ECA_PDST_NEVENTS];
    }
    else if([[aSNOPModel standardRunVersion] isEqualToString:@"ECA_TSLP_STANDARD"]){
        //Time Slope run
        [self setECA_type:ECA_TSLP_TYPE];
        [self setECA_rate:[NSNumber numberWithInt:ECA_TSLP_RATE]];
        [self setECA_pattern:ECA_TSLP_PATTERN];
        [self setECA_nevents:ECA_TSLP_NEVENTS];
    }
    else if([[aSNOPModel standardRunVersion] isEqualToString:@"ECA_USER_SETTINGS"]){
        if ([ECA_type isEqualToString:@"PDST"]) {
            runTypeWord = ~(~runTypeWord | kECATSlopeRun);
            runTypeWord |= kECAPedestalRun;
            [aRunModel setRunType:runTypeWord];
        }
        else if([ECA_type isEqualToString:@"TSLP"]) {
            runTypeWord =~(~runTypeWord | kECAPedestalRun);
            runTypeWord |= kECATSlopeRun;
            [aRunModel setRunType:runTypeWord];
        }
    }
    else{
        NSLogColor([NSColor redColor], @"setECASettings: Unknown standard run version.\n");
        goto err;
    }

    /* Check run type word and set parameters accordingly */
    if( (runTypeWord & kECAPedestalRun) && (runTypeWord & kECATSlopeRun) ){
        NSLogColor([NSColor redColor], @"setECAsettings: Both PDST and TSLP bits checked in the run type word. Don't know what to do!.\n");
        goto err;
    }
    else if( runTypeWord & (kECAPedestalRun) ){
        [self setECA_type:@"PDST"];
    }
    else if( runTypeWord & (kECATSlopeRun) ){
        [self setECA_type:@"TSLP"];
    }
    else{
        //Not an ECA run
        goto err;
    }
    //Set mode
    if( runTypeWord & (kECARun) ){
        [self setECA_mode:ECAMODE_DEDICATED];
    }
    else if( runTypeWord & (kSupernovaRun) ){
        [self setECA_mode:ECAMODE_SUPERNOVA];
    }
    else if( runTypeWord & (kPhysicsRun) ){
        [self setECA_mode:ECAMODE_PHYSICS];
    }
    else{
        NSLogColor([NSColor redColor], @"setECAsettings: Not a valid run for ECA_mode.\n");
        goto err;
    }

    objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];
    if (![objs count]) {
        NSLogColor([NSColor redColor], @"setECASettings: MTC not found.\n");
        goto err;
    }

    anMTCModel = [objs objectAtIndex:0];

    /* Get current MTC settings which aren't loaded by the standard run so we
     * can set them back after the ECA run is finished. */
    prev_pedmask = [anMTCModel pedCrateMask];
    prev_coarsedelay = [anMTCModel coarseDelay];
    prev_finedelay = [anMTCModel fineDelay];
    prev_pedwidth = [anMTCModel pedestalWidth];

    @try {
        [anMTCModel setPgtRate:[[self ECA_rate] floatValue]];

        /* Enable Pedestals */
        [anMTCModel setIsPedestalEnabledInCSR:TRUE];

        /* Enable Pedestal mask for all the crates */
        [anMTCModel setPedCrateMask: (prev_pedmask | 0x7FFFF)];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor], @"setECASettings: error setting MTC model settings. name: %@ reason: %@.\n", [e name], [e reason]);
        goto err;
    }

    start_eca_run = YES;
    return true;

err:
{
    isFinished = YES;
    return false;
}

}

- (void) launchECAThread:(NSNotification*)aNote
{

    if([ECAThread isExecuting]) {
        NSLogColor([NSColor redColor], @"launchECAThread: ECA already running... \n");
        return;
    }

    //Launch ECA thread
    [ECAThread release];
    ECAThread = [[NSThread alloc] initWithTarget:self selector:@selector(doECAs) object:nil];
    [ECAThread start];
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORECARunStartedNotification object:self];

}

- (void) doECAs
{

    /* This is the actual ECA algorithm, which needs to be run in a separate thread */
    @autoreleasepool {

        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORRoutineChangedNotification object:self userInfo:@{@"routine":@"ECA"}];

        /* Get models */
        //MTC model
        NSArray* objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];
        if ([objs count]) {
            anMTCModel = [objs objectAtIndex:0];
        } else {
            NSLogColor([NSColor redColor], @"ECARun: couldn't find MTC model. \n");
            goto stop;
        }

        //XL3 models
        anXL3Model = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];
        if (![anXL3Model count]) {
            NSLogColor([NSColor redColor], @"ECARun: couldn't find XL3 model. \n");
            goto stop;
        }

        //FEC models
        aFECModel = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORFec32Model")];
        if (![aFECModel count]) {
            NSLogColor([NSColor redColor], @"ECARun: couldn't find FEC model. \n");
            goto stop;
        }

        /*Check whether PED EXT bit is enabled. Otherwise the GT will latch the 10MHz
         clock and cause a 20ns uncertainty in the TAC measurements*/
        if(!([anMTCModel gtMask] & MTC_EXT_8_MASK)){
            NSLogColor([NSColor redColor], @" Enable EXT PED bit in the MTC trigger mask. Stopping ECAs... \n");
            goto stop;
        }

        if(ECA_mode != ECAMODE_DEDICATED){
            /* Do not allow to run with triggers ON with
             a pattern other than channel by channel! */
            if(ECA_pattern != 4){
                NSLogColor([NSColor redColor], @"You are not allowed to run ECA with "
                           "physics triggers enabled for high occupancy patterns!\n");
                goto stop;
            }
        }
        else{
            /* Disable channel triggers and stop if it fails */
            if(![self triggersOFF]){
                goto stop;
            }
        }

        /* Set MTC correct settings for ECAs */
        dispatch_sync(dispatch_get_main_queue(), ^{

            [anMTCModel stopMTCPedestalsFixedRate];
            [anMTCModel setCoarseDelay:ECA_COARSE_DELAY];
            [anMTCModel setFineDelay:ECA_FINE_DELAY];
            [anMTCModel setPedestalWidth:ECA_PEDESTAL_WIDTH];
#ifndef __TESTING__
            [anMTCModel loadCoarseDelayToHardware];
            [anMTCModel loadFineDelayToHardware];
            [anMTCModel loadPedWidthToHardware];
#endif
        });

        NSLog(@"************************* \n");
        NSLog(@"Starting ECA Run \n");
        switch (ECA_mode){
            case ECAMODE_DEDICATED: NSLog(@"Dedicated Run \n"); break;
            case ECAMODE_SUPERNOVA: NSLog(@"Supernova-Live \n"); break;
            case ECAMODE_PHYSICS: NSLog(@"Physics-Live \n"); break;
        }
        NSLog(@"------------------------- \n");
        NSLog(@" Events per cell: %d \n", ECA_nevents);
        NSLog(@" Pattern: %@ \n", ECA_pattern_string );
        NSLog(@" TSlope: %d \n", ECA_tslope_pattern);
        NSLog(@" Type: %@ \n", ECA_type);
        NSLog(@" Rate: %@ \n", ECA_rate);
        NSLog(@" SubRun Time: %f seconds \n", [self ECA_subruntime]);
        NSLog(@"************************* \n");

        [self setECA_currentDelay:(double)ECA_COARSE_DELAY+(double)ECA_FINE_DELAY/100.];

        //Do ECAs
        if([ECA_type isEqualToString:@"PDST"]){
            if(![self doPedestals]) {
                // User stopped manually
                goto stop;
            }
        }
        else if([ECA_type isEqualToString:@"TSLP"]){
            if(![self doTSlopes]) {
                // User stopped manually
                goto stop;
            }
        }
        else{
            NSLogColor([NSColor redColor],@"Unknown ECA type: %@ \n",ECA_type);
            goto stop;
        }

    stop:

        isFinishing = TRUE;
        NSLog(@"************************* \n");
        NSLog(@"Finishing ECA Run \n");
        NSLog(@"************************* \n");

        //Recover previous settings
        dispatch_sync(dispatch_get_main_queue(), ^{
            [aSNOPModel zeroPedestalMasks];
            [anMTCModel setPedestalWidth:prev_pedwidth];
            [anMTCModel setPedCrateMask:prev_pedmask];
            [anMTCModel setCoarseDelay:prev_coarsedelay];
            [anMTCModel setFineDelay:prev_finedelay];
        });

        //Turn triggers back ON if not in physics
        if(ECA_mode == ECAMODE_PHYSICS){
            // Don't need to turn ON triggers
        } else if(![self triggersON]){
            NSLogColor([NSColor redColor], @"*************************************************** \n");
            NSLogColor([NSColor redColor], @" Some triggers couldn't be enabled: The GUI status  \n");
            NSLogColor([NSColor redColor], @" might not show the real state of the detector      \n");
            NSLogColor([NSColor redColor], @"*************************************************** \n");
        }

        dispatch_sync(dispatch_get_main_queue(), ^{
            if( [ECAThread isCancelled] ){
                [[NSNotificationCenter defaultCenter] postNotificationName:ORReleaseRunStateChangeWait object:self];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:ORECARunFinishedNotification object:self];
            isFinished = TRUE;
        });

        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORRoutineChangedNotification object:self userInfo:@{@"routine":@"ECA", @"status":@"Not running"}];

    }//end autoreleasepool

}

- (BOOL) doPedestals
{

    NSLog(@"Starting ECA Pedestal Run... \n");

    uint32_t coarse_delay = [anMTCModel coarseDelay];
    uint32_t fine_delay = [anMTCModel fineDelay];
    uint32_t pedestal_width = [anMTCModel pedestalWidth];

    //EPED headers
    [aSNOPModel updateEPEDStructWithCoarseDelay:coarse_delay fineDelay:fine_delay chargePulseAmp:0x0 pedestalWidth:pedestal_width calType:10 + (ECA_pattern+1)];

    //Inject pedestals
    int eca_pattern_num_steps = getECAPatternNSteps(ECA_pattern);
    NSMutableArray* pedestal_mask = getECAPattern(ECA_pattern);
    if (pedestal_mask == nil) {
        NSLogColor([NSColor redColor], @"ECA: Error loading pedestal mask for pattern: %d \n", ECA_pattern);
        return false;
    }
    else if([pedestal_mask count] == 0){
        [pedestal_mask release];
        NSLogColor([NSColor redColor], @"ECA: Error loading pedestal mask for pattern: %d \n", ECA_pattern);
        return false;
    }

    for (int step=0; step < eca_pattern_num_steps; step++) {

        [self setECA_currentStep:step+1];

        // Set channel triggers OFF only for pedestaled channels
        if(ECA_mode == ECAMODE_SUPERNOVA){
            if(![self loadTriggersWithCrateMask:[pedestal_mask objectAtIndex:step]]){
                [pedestal_mask release];
                return false;
            }
        }

        //Update Pedestal mask
        [self changePedestalMask:[pedestal_mask objectAtIndex:step]];

        [aSNOPModel updateEPEDStructWithStepNumber:step];

        //Ship EPED Headers
        dispatch_sync(dispatch_get_main_queue(), ^{
            [aSNOPModel shipEPEDRecord];
        });

        //Fire pedestals at the pulser rate during a time=sub_run_time
        dispatch_sync(dispatch_get_main_queue(), ^{
            [anMTCModel continueMTCPedestalsFixedRate];
        });
        usleep([self ECA_subruntime] * 1e6);

        //End of sub-run
        dispatch_sync(dispatch_get_main_queue(), ^{
            [anMTCModel stopMTCPedestalsFixedRate];
        });

        //Check if user has cancelled ECAs and quit in that case
        if([ECAThread isCancelled]) {
            NSLog(@"ECA cancelled by user... \n");
            start_eca_run = FALSE;
            [pedestal_mask release];
            return false;
        }

    } // end ECA steps

    //OK run
    [pedestal_mask release];
    return true;

}

- (BOOL) doTSlopes
{

    NSLog(@"Starting ECA TSlope Run... \n");

    uint32_t coarse_delay = [anMTCModel coarseDelay];
    uint32_t fine_delay = [anMTCModel fineDelay];
    uint32_t pedestal_width = [anMTCModel pedestalWidth];

    //Get time delays
    const int tslope_nsteps = 50; //CHANGE TO 50 BEFORE COMMISSIONING
    NSMutableArray *tslope_delays_coarse = [[[NSMutableArray alloc] initWithCapacity:tslope_nsteps] autorelease];
    NSMutableArray *tslope_delays_fine = [[[NSMutableArray alloc] initWithCapacity:tslope_nsteps] autorelease];
    for (int ipoint=0; ipoint<tslope_nsteps; ipoint++) {
        [tslope_delays_coarse addObject:[NSNumber numberWithInt:ipoint*10 + 10]];
        [tslope_delays_fine addObject:[NSNumber numberWithInt:0]];
    }

    //EPED headers
    [aSNOPModel updateEPEDStructWithCoarseDelay:coarse_delay fineDelay:fine_delay chargePulseAmp:0x0 pedestalWidth:pedestal_width calType:20 + (ECA_pattern+1)];

    //Inject pedestals
    int eca_pattern_num_steps = getECAPatternNSteps(ECA_pattern);
    NSMutableArray* pedestal_mask = getECAPattern(ECA_pattern);
    if (pedestal_mask == nil) {
        NSLogColor([NSColor redColor], @"ECA: Error loading pedestal mask for pattern: %d \n", ECA_pattern);
        return false;
    }
    else if([pedestal_mask count] == 0){
        [pedestal_mask release];
        NSLogColor([NSColor redColor], @"ECA: Error loading pedestal mask for pattern: %d \n", ECA_pattern);
        return false;
    }

    @try{
        for (int step=0; step < eca_pattern_num_steps; step++) {

            [self setECA_currentStep:step+1];

            // Set channel triggers OFF only for pedestaled channels
            if(ECA_mode == ECAMODE_SUPERNOVA){
                if(![self loadTriggersWithCrateMask:[pedestal_mask objectAtIndex:step]]){
                    [pedestal_mask release];
                    return false;
                }
            }

            //Update Pedestal mask
            [self changePedestalMask:[pedestal_mask objectAtIndex:step]];

            for (int ipoint=0; ipoint<tslope_nsteps; ipoint++) {

                [aSNOPModel updateEPEDStructWithStepNumber:step];

                uint32_t current_coarse_delay = (uint32_t)[[tslope_delays_coarse objectAtIndex:ipoint] unsignedLongValue];
                uint32_t current_fine_delay = (uint32_t)[[tslope_delays_fine objectAtIndex:ipoint] unsignedLongValue];

                [self setECA_currentPoint:ipoint+1];

                dispatch_sync(dispatch_get_main_queue(), ^{
                    [anMTCModel setCoarseDelay:(int)current_coarse_delay];
                    [anMTCModel setFineDelay:(int)current_fine_delay];
#ifndef __TESTING__
                    [anMTCModel loadCoarseDelayToHardware];
                    [anMTCModel loadFineDelayToHardware];
#endif
                });

                [self setECA_currentDelay:(double)current_coarse_delay+(double)current_fine_delay/100.];

                [aSNOPModel updateEPEDStructWithCoarseDelay:current_coarse_delay fineDelay:current_fine_delay chargePulseAmp:0x0 pedestalWidth:pedestal_width calType:20 + (ECA_pattern+1)];

                //Ship EPED Headers
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [aSNOPModel shipEPEDRecord];
                });

                //Fire pedestals at the pulser rate during a time=sub_run_time
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [anMTCModel continueMTCPedestalsFixedRate];
                });
                usleep([self ECA_subruntime] * 1e6);

                //End of sub-run
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [anMTCModel stopMTCPedestalsFixedRate];
                });

                //Check if user has cancelled ECAs and quit in that case
                if([ECAThread isCancelled]) {
                    NSLog(@"ECA cancelled by user... \n");
                    //Don't leak memory
                    [pedestal_mask release];
                    return false;
                }

            }

        } // end ECA steps
    }
    @catch(...){
        //Don't leak memory
        [pedestal_mask release];
        return false;
    }

    [pedestal_mask release];

    //OK run
    return true;

}

- (void) changePedestalMask:(NSMutableArray*)aPedestal_mask
{

    //Set pedestal mask in FEC: this does not load it yet
    for (ORFec32Model *fec in aFECModel) {
        int crate_number = [fec crateNumber];
        if(crate_number == 19) crate_number = 0; //hack for the teststand
        NSUInteger card_number = [fec stationNumber];
        int mask = [[[aPedestal_mask objectAtIndex:crate_number] objectAtIndex:card_number] intValue];
        //NSLog(@"PEDESTAL MASK: %d, %d, %x \n",crate_number,card_number,mask);
        dispatch_async(dispatch_get_main_queue(), ^{
            [fec setPedEnabledMask:mask];
        });
    }

    //Load pedestal mask
    for (ORXL3Model *xl3 in anXL3Model) {
        //NSLog(@"Set pedestal for XL3 %d \n", [xl3 crateNumber]);
        dispatch_async(dispatch_get_main_queue(), ^{
            [xl3 setPedestalInParallel];
        });
    }

    //Check the pedestal mask changes have finished
    for (ORXL3Model *xl3 in anXL3Model) {
        NSDate* aDate = [[NSDate alloc] init];
        while ([xl3 changingPedMask]) {
            usleep(1e3); //sleep 1ms
            //Timeout after 3s
            if ([aDate timeIntervalSinceNow] < -3) {
                NSLogColor([NSColor redColor], @" Pedestal mask couldn't change. \n");
            }
        }
        [aDate release];
    }

}

- (BOOL) loadTriggersWithCrateMask:(NSMutableArray*)aPedestal_mask
{
    /* Disable triggers for the channels with pedestal enabled
     * Disable triggers for channels 17 and 18 by default. */

    //Deep copy the array so that we don't modify the original
    NSMutableArray *used_pedestal_mask = [[NSMutableArray alloc] initWithCapacity:[aPedestal_mask count]];
    for (id element in aPedestal_mask){
        [used_pedestal_mask addObject:[element mutableCopy]];
    }

    BOOL triggersSetOK = TRUE;
    for (ORXL3Model *xl3 in anXL3Model) {
        int crate = [xl3 crateNumber];
        if(crate == 19) crate = 0; //hack for the teststand
        if([[xl3 xl3Link] isConnected]){
            @try {
                //Enable bits 17 and 18
                for (int islot=0; islot<16; islot++){
                    NSNumber *temp = [[used_pedestal_mask objectAtIndex:crate] objectAtIndex:islot];
                    temp = [NSNumber numberWithUnsignedInt:[temp unsignedIntValue] | 1<<17];
                    temp = [NSNumber numberWithUnsignedInt:[temp unsignedIntValue] | 1<<18];
                    temp = [NSNumber numberWithUnsignedInt:~[temp unsignedIntValue]];
                    [[used_pedestal_mask objectAtIndex:crate] replaceObjectAtIndex:islot withObject:temp];
                }
                [xl3 loadTriggersWithCrateMask:[used_pedestal_mask objectAtIndex:crate]];
            }
            @catch (NSException *exception) {
                NSLogColor([NSColor redColor], @"ECA: triggers could not be disabled for crate %d \n",crate);
                triggersSetOK = FALSE;
            }
        }
        else{
            NSLog(@"ECA: triggers could not be disabled for crate %d because XL3 is not connected\n",crate);
        }
    }

    [used_pedestal_mask release];
    return triggersSetOK;
}

- (BOOL) triggersOFF
{
    NSMutableArray *detector_mask = [NSMutableArray array];
    for (int icrate=0; icrate<19; icrate++) {
        NSMutableArray* crate_pattern = [NSMutableArray array];
        for (int islot=0; islot<16; islot++) {
            [crate_pattern addObject:[NSNumber numberWithUnsignedInt:0xFFFFFFFF]];
        }
        [detector_mask addObject:crate_pattern];
    }
    return [self loadTriggersWithCrateMask:detector_mask];
}

- (BOOL) triggersON
{
    BOOL triggersSetOK = TRUE;

    for (ORXL3Model *xl3 in anXL3Model) {
        if([[xl3 xl3Link] isConnected]){
            @try {
                [xl3 loadTriggers];
            }
            @catch (NSException *exception) {
                NSLogColor([NSColor redColor], @"ECA: triggers could not be enabled for crate %d \n",[xl3 crateNumber]);
                triggersSetOK = FALSE;
            }
        }
        else{
            NSLog(@"ECA: triggers could not be enabled for crate %d because XL3 is not connected\n",[xl3 crateNumber]);
        }
    }
    return triggersSetOK;
}

- (double)ECA_subruntime
{
    return (double)ECA_nevents*16/[ECA_rate doubleValue];
}

- (int)ECA_pattern
{
    return ECA_pattern;
}

- (NSString*) ECA_pattern_string
{
    return getECAPatternName(ECA_pattern);
}

- (void) setECA_pattern:(int)aValue
{
    ECA_pattern = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORECARunChangedNotification object:self];
}

- (int)ECA_nsteps
{
    return getECAPatternNSteps(ECA_pattern);
}

- (int)ECA_currentStep
{
    return ECA_currentStep;
}

- (void)setECA_currentStep:(int)aValue
{
    ECA_currentStep = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORRoutineChangedNotification object:self userInfo:@{@"routine":@"ECA"}];
}

- (int)ECA_currentPoint
{
    return ECA_currentPoint;
}

- (void)setECA_currentPoint:(int)aValue
{
    ECA_currentPoint = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORRoutineChangedNotification object:self userInfo:@{@"routine":@"ECA"}];
}

- (int)ECA_currentDelay
{
    return ECA_currentDelay;
}

- (void)setECA_currentDelay:(double)aValue
{
    ECA_currentDelay = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORRoutineChangedNotification object:self userInfo:@{@"routine":@"ECA"}];
}

- (NSString*)ECA_type
{
    return [NSString stringWithFormat:@"%@",ECA_type];
}

- (void) setECA_type:(NSString*)aValue
{
    if(aValue != ECA_type)
    {
        NSString* temp = ECA_type;
        ECA_type = [aValue retain];
        [temp release];
        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORECARunChangedNotification object:self];
    }
}

- (int)ECA_tslope_pattern
{
    return ECA_tslope_pattern;
}

- (void) setECA_tslope_pattern:(int)aValue
{
    ECA_tslope_pattern = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORECARunChangedNotification object:self];
}

- (int)ECA_nevents
{
    return ECA_nevents;
}

- (void) setECA_nevents:(int)aValue
{
    if(aValue <= 0) aValue = 1;
    ECA_nevents = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORECARunChangedNotification object:self];
}

- (NSNumber*)ECA_rate
{
    return ECA_rate;
}

- (void) setECA_rate:(NSNumber*)aValue
{
    if(aValue != ECA_rate){

        NSNumber* temp = ECA_rate;

        double new_ECA_rate = [aValue doubleValue];
        NSNumber* ECA_rate_limit = [[NSNumber alloc] initWithDouble:1000.];

        if([aValue doubleValue] < 1){
            new_ECA_rate = 1;
            NSLogColor([NSColor redColor], @" ECA: Pulser rate should be greater than 1. \n");
        }
        else if([aValue doubleValue] > [ECA_rate_limit doubleValue]){
            new_ECA_rate = [ECA_rate_limit doubleValue];
            NSLogColor([NSColor redColor], @" ECA: Not allowed to go above 1kHz. \n");
        }

        ECA_rate = [[NSNumber alloc] initWithDouble:new_ECA_rate];
        [ECA_rate_limit release];
        [temp release];
        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORECARunChangedNotification object:self];
    }
}

-(int) ECA_mode
{
    return ECA_mode;
}

-(NSString*) ECA_mode_string
{
    switch (ECA_mode) {
        case ECAMODE_DEDICATED:
            return @"Dedicated Run";
            break;
        case ECAMODE_SUPERNOVA:
            return @"Supernova-live";
            break;
        case ECAMODE_PHYSICS:
            return @"Physics-live";
            break;
        default:
            return @"Unknown";
            break;
    }
}

-(void) setECA_mode:(int)aValue
{
    ECA_mode = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORECARunChangedNotification object:self];
}



@end
