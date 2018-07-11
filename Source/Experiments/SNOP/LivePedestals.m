//
//  LivePedestals.m
//  Orca
//
//  Created by Javier Caravaca on 5/3/17.
//
//

#import "LivePedestals.h"
#import "ECAPatterns.h"
#import "RunTypeWordBits.hh"
#import "ORMTC_Constants.h"
#import "SNOPModel.h"
#import "ORMTCModel.h"
#import "ORXL3Model.h"
#import "ORFec32Model.h"

/* This flag must be undefined for normal operations.
 * Uncomment this line only for testings purposes. */
// #define __TESTING__ 1

#define PEDGT_DELAY 150 //ns

@implementation LivePedestals

- (id) init
{
    self = [super init];
    PedThread = [[NSThread alloc] init];
    current_step = 0;
    current_status = LIVEPEDS_RUNNING;
    run_livepeds = FALSE;
    [self registerNotificationObservers];
    return self;
}

- (void) dealloc
{
    [PedThread release];
    [super dealloc];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

    [notifyCenter addObserver : self
                     selector : @selector(stopLivePedsThread:)
                         name : ORRunAboutToStopNotification
                       object : nil];
}

- (void) start
{
    /* Set flag to true so that the LivePeds thread starts
     * or continues with the routine */
    run_livepeds = TRUE;
}

- (void) stop
{
    /* Set flag to false so that the LivePeds thread stop
     * firing pedestals */
    run_livepeds = FALSE;
}

- (bool) isThreadRunning
{
    return [PedThread isExecuting];
}


- (void) launchLivePedsThread
{

    /* We launch the LivePed thread if the corresponding run type word
     * is enabled. */
    if(![self isThreadRunning]){
        [PedThread initWithTarget:self selector:@selector(doLivePeds) object:nil];
        [PedThread start];
    }

}

- (void) stopLivePedsThread:(NSNotification*)aNote
{

    /* Cancel the livePed thread and stop firing pedestals. */
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"waiting for live pedestals to finish", @"Reason",
                              nil];
    if([self isThreadRunning]){
        [[NSNotificationCenter defaultCenter] postNotificationName:ORAddRunStateChangeWait object: self userInfo: userInfo];
        [PedThread cancel];
    }

}

- (void) doLivePeds
{

    /* The livePed thread will periodically check if conditions are met
     * to fire embedded pedestals. Conditions:
     * - NHitMonitor not running
     * - Not in an ECA run
     * - User has not intervened to stop them
     */

    @autoreleasepool {

        /* Get channel by channel pattern */
        int eca_pattern_num_steps = getECAPatternNSteps(4); //Channel-by-channel
        NSMutableArray* pedestal_mask = getECAPattern(4); //Channel-by-channel

        /* Get models */
        //MTC model
        NSArray* objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];
        if ([objs count]) {
            anMTCModel = [objs objectAtIndex:0];
        } else {
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

        //SNO+ model
        objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
        if ([objs count]) {
            aSNOPModel = [objs objectAtIndex:0];
        } else {
            goto stop;
        }

        if (pedestal_mask == nil) {
            NSLogColor([NSColor redColor], @"LivePeds: Error loading pedestal mask for pattern 4 \n");
            goto stop;
        }
        else if([pedestal_mask count] == 0){
            NSLogColor([NSColor redColor], @"LivePeds: Error loading pedestal mask for pattern 4 \n");
            goto stop;
        }

        while (true) {

            if([self shouldIrun]){

                if( ![self isLockAvailable] ){
                    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORRoutineChangedNotification object:self userInfo:@{@"routine":@"LivePeds", @"status":@"Waiting for lock"}];
                }
                else{ // Got the lock!
                    @try{
                        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORRoutineChangedNotification object:self userInfo:@{@"routine":@"LivePeds", @"status":@"Running"}];

                        // Save previous MTC settings
                        prev_coarsedelay = [anMTCModel coarseDelay];
                        prev_finedelay = [anMTCModel fineDelay];
                        prev_pedmask = [anMTCModel pedCrateMask];
                        prev_pulserRate = [anMTCModel pgtRate];

                        // Set correct MTC settings for the pedestals
                        [anMTCModel setCoarseDelay:PEDGT_DELAY];
                        [anMTCModel setFineDelay:0];
                        [anMTCModel setPedCrateMask:prev_pedmask | 0x7FFFF];
                        [anMTCModel setPgtRate:1]; //1Hz

                        // Set EPED records
                        [aSNOPModel updateEPEDStructWithCoarseDelay:[anMTCModel coarseDelay] fineDelay:[anMTCModel fineDelay] chargePulseAmp:0x0 pedestalWidth:[anMTCModel pedestalWidth] calType:30];

                        // Load in HW
#ifndef __TESTING__
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            [anMTCModel setIsPedestalEnabledInCSR:YES];
                            [anMTCModel setPulserEnabled:YES];
                            [anMTCModel loadCoarseDelayToHardware];
                            [anMTCModel loadFineDelayToHardware];
                            [anMTCModel loadGTCrateMaskToHardware];
                            [anMTCModel loadPedestalCrateMaskToHardware];
                            [anMTCModel setGlobalTriggerWordMask];
                            [anMTCModel loadPulserRateToHardware];
                        });
#endif

                        while ( run_livepeds ) { // While radio button is on, keep firing

                            current_status=LIVEPEDS_RUNNING;

                            //Update Pedestal mask
                            [self changePedestalMask:[pedestal_mask objectAtIndex:current_step]];

                            //Ship EPED Headers
                            [aSNOPModel updateEPEDStructWithStepNumber:current_step];
                            dispatch_sync(dispatch_get_main_queue(), ^{
                                [aSNOPModel shipEPEDRecord];
                            });

                            //Fire one pedestal
                            dispatch_sync(dispatch_get_main_queue(), ^{
                                [anMTCModel continueMTCPedestalsFixedRate];
                            });
                            usleep(1.1e6); //sleep for a second while firing pedestals

                            //End of step
                            dispatch_sync(dispatch_get_main_queue(), ^{
                                [anMTCModel stopMTCPedestalsFixedRate];
                            });

                            [self setCurrent_step:current_step+1];
                            if(current_step>=eca_pattern_num_steps) [self setCurrent_step:0];

                            if ([PedThread isCancelled]) {
                                break;
                            }

                        } //end while loop

                        // Recover previous MTC settings
                        [anMTCModel setCoarseDelay:prev_coarsedelay];
                        [anMTCModel setFineDelay:prev_finedelay];
                        [anMTCModel setPedCrateMask:prev_pedmask];
                        [anMTCModel setPgtRate:prev_pulserRate];
#ifndef __TESTING__
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            [anMTCModel setIsPedestalEnabledInCSR:NO];
                            [anMTCModel loadCoarseDelayToHardware];
                            [anMTCModel loadFineDelayToHardware];
                            [anMTCModel loadPedestalCrateMaskToHardware];
                            [anMTCModel loadPulserRateToHardware];
                            [anMTCModel fireMTCPedestalsFixedRate];
                        });
#endif
                    }
                    @finally{
                        [[aSNOPModel ecaLock] unlock]; //Allow the NHitMonitor to run at this point
                    }
                }
            }
            else {
                [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORRoutineChangedNotification object:self userInfo:@{@"routine":@"LivePeds", @"status":@"Not Running"}];
            }

            if ([PedThread isCancelled]) {
                break;
            }

            usleep(1e6); //sleep for a second before trying again
            
        } // end while-true

    stop:

        [pedestal_mask release];

        current_status=LIVEPEDS_STOPPED;

        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORRoutineChangedNotification object:self userInfo:@{@"routine":@"LivePeds", @"status":@"Not Running"}];
        // Release wait
        [[NSNotificationCenter defaultCenter] postNotificationName:ORReleaseRunStateChangeWait object:self];

    }

}

- (void) changePedestalMask:(NSMutableArray*)pedestal_mask
{

    //Set pedestal mask in FEC: this does not load it yet
    for (ORFec32Model *fec in aFECModel) {
        int crate_number = [fec crateNumber];
        if(crate_number == 19) crate_number = 0; //hack for the teststand
        int card_number = (int)[fec stationNumber];
        int mask = [[[pedestal_mask objectAtIndex:crate_number] objectAtIndex:card_number] intValue];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [fec setPedEnabledMask:mask];
        });
    }

    //Load pedestal mask
    for (ORXL3Model *xl3 in anXL3Model) {
        //NSLog(@"Set pedestal for XL3 %d \n", [xl3 crateNumber]);
        [xl3 setPedestalInParallel];
    }

    //Check the pedestal mask changes have finished
    for (ORXL3Model *xl3 in anXL3Model) {
        NSDate* aDate = [NSDate date];
        while ([xl3 changingPedMask]) {
            usleep(1e3); //sleep 1ms
            //Timeout after 3s
            if ([aDate timeIntervalSinceNow] < -3) {
                NSLogColor([NSColor redColor], @" Pedestal mask couldn't change. \n");
            }
        }
    }
    
}

- (bool) isLockAvailable
{

    /* Try to acquire the lock for 2 seconds. If we can't get it then we
     * just skip embedded pedestals. */
    bool lockReleased = NO;
    if ([[aSNOPModel ecaLock] lockBeforeDate:[NSDate dateWithTimeIntervalSinceNow:2.0]]) {
        lockReleased = YES;
    } else {
        NSLogColor([NSColor redColor],
                   @"LivePeds: unable to acquire eca lock!\n");
    }

    return lockReleased;
}

- (bool) shouldIrun
{
    unsigned int ECAmask = kECARun | kECAPedestalRun | kECATSlopeRun;
    bool isECARun = ([aSNOPModel runTypeWord] & ECAmask);
    bool isEmbPedRun = ([aSNOPModel runTypeWord] & kEmbeddedPeds);

    return run_livepeds && !isECARun && isEmbPedRun;
}

- (bool) run_livepeds
{
    return run_livepeds;
}

- (int) current_step
{
    return current_step;
}

- (void)setCurrent_step:(int)aValue
{
    current_step = aValue;
}

- (bool) isRunning
{
    return (current_status==LIVEPEDS_RUNNING);
}

@end
