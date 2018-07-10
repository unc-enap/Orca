//
//  NHitMonitor.m
//  Orca
//
//  Created by Anthony LaTorre on Thursday, April 13, 2017.
//

#import "NHitMonitor.h"
#import "anet.h"
#import "ORMTCModel.h"
#import "ORXL3Model.h"
#import "record_info.h"
#import "ORFec32Model.h"
#import "SNOPModel.h"
#import "OROrderedObjManager.h"
#import "ORPQModel.h"
#import "ORGlobal.h"
#import "RedisClient.h"
#import "ORMTC_Constants.h"
#import "TUBiiModel.h"
#import "ORAppDelegate.h"

#define SWAP_INT32(a,b) swap_int32((uint32_t *)(a),(b))

NSString* ORNhitMonitorUpdateNotification = @"ORNhitMonitorUpdateNotification";
NSString* ORNhitMonitorResultsNotification = @"ORNhitMonitorResultsNotification";
NSString* ORNhitMonitorNotification = @"ORNhitMonitorNotification";

// PH 04/23/98
// Swap 4-byte integer/floats between native and external format
void swap_int32(uint32_t *val_pt, int count)
{
    uint32_t *last = val_pt + count;
    while (val_pt < last) {
        *val_pt = ((*val_pt << 24) & 0xff000000) |
                  ((*val_pt <<  8) & 0x00ff0000) |
                  ((*val_pt >>  8) & 0x0000ff00) |
                  ((*val_pt >> 24) & 0x000000ff);
        ++val_pt;
    }
    return;
}

static int write_record(int sock, struct GenericRecordHeader *header, char *buf)
{
    /* Write a record to the data stream server. Note that header should
     * already be byte swapped. Returns -1 on error. */
    if (anetWrite(sock, (char *) header,
                  sizeof(struct GenericRecordHeader)) == -1) {
        return -1;
    }

    if (anetWrite(sock, buf, ntohl(header->RecordLength)) == -1) {
        return -1;
    }

    return 0;
}

static int read_record(int sock, struct GenericRecordHeader *header, char *buf)
{
    /* Reads a single record from the data stream server. Returns -1 on error. */
    if (anetRead(sock, (char *) header,
                 sizeof(struct GenericRecordHeader)) == -1) {
        return -1;
    }

    if (anetRead(sock, buf, ntohl(header->RecordLength)) == -1) {
        return -1;
    }

    return 0;
}

static float get_threshold(int *counts, int max_nhit, int num_pulses)
{
    /* Returns the trigger threshold for a given NHIT trigger by looking for
     * the nhit at which the trigger rate crosses 50%.
     *
     * Returns -1 if no point crosses 50%. */
    int i;

    if (counts[0] > num_pulses/2.0) {
        /* we are already above threshold at 0 nhit */
        return 0;
    }

    for (i = 1; i < max_nhit; i++) {
        if (counts[i] > num_pulses/2.0) {
            return (i-1) + (num_pulses/2.0 - counts[i-1])/(counts[i] - counts[i-1]);
        }
    }

    return -1;
}

static int get_nhit_trigger_count(char *err, RedisClient *mtc, int sock, char *buf, int nhit, int num_pulses, struct NhitRecord *nhit_record, int timeout)
{
    /* Get the number of triggers which had an NHIT trigger fire. Returns -1 if
     * there was an error or the current thread was cancelled. */
    int current_gtid, nrecords, start, i;
    int count = 0;
    struct GenericRecordHeader header;
    struct MTCReadoutData *mtc_readout_data;

    /* get current GTID */
    current_gtid = [mtc intCommand:"get_gtid"];

    start = time(NULL);

    while (1) {
        /* Check to see if we should stop. */
        if ([[NSThread currentThread] isCancelled]) {
            sprintf(err, "current thread was cancelled");
            return -1;
        }

        if (time(NULL) > start + timeout) {
            sprintf(err, "timed out after %i seconds", timeout);
            return -1;
        }

        if (read_record(sock, &header, buf) == -1) {
            if (errno == EAGAIN || errno == EWOULDBLOCK) {
                continue;
            }
            sprintf(err, "error reading MTCD record: %s", strerror(errno));
            return -1;
        }

        nrecords = ntohl(header.RecordLength)/sizeof(struct MTCReadoutData);

        for (i = 0; i < nrecords; i++) {
            mtc_readout_data = (struct MTCReadoutData *) (buf + i*sizeof(struct MTCReadoutData));

            SWAP_INT32(mtc_readout_data, 6);

            /* If we read out a GTID before we started, we can't be sure that
             * it occurred after we set the XL3 pedestal mask and started the
             * pulser, so we wait until we get a GTID aftere when we started. */
            if (mtc_readout_data->BcGT < current_gtid) continue;

            if (mtc_readout_data->Pedestal) {
                if (mtc_readout_data->Nhit_100_Lo)
                    nhit_record->nhit_100_lo[nhit] += 1;
                if (mtc_readout_data->Nhit_100_Med)
                    nhit_record->nhit_100_med[nhit] += 1;
                if (mtc_readout_data->Nhit_100_Hi)
                    nhit_record->nhit_100_hi[nhit] += 1;
                if (mtc_readout_data->Nhit_20)
                    nhit_record->nhit_20[nhit] += 1;
                if (mtc_readout_data->Nhit_20_LB)
                    nhit_record->nhit_20_lb[nhit] += 1;

                count += 1;
            }

            if (count >= num_pulses) break;
        }

        if (count >= num_pulses) break;
    }

    return 0;
}

@implementation NHitMonitor

- (id) init
{
    self = [super init];
    runningThread = [[NSThread alloc] init];
    buf = malloc(DATASTREAM_BUFFER_SIZE);
    sock = -1;
    [self registerNotificationObservers];
    return self;
}

- (void) dealloc
{
    [self disconnect];
    free(buf);
    [runningThread release];
    [super dealloc];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

    [notifyCenter addObserver : self
                     selector : @selector(runAboutToStop:)
                         name : ORRunAboutToStopNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(orcaAboutToQuit:)
                         name : OROrcaAboutToQuitNotice
                       object : nil];
}

- (void) runAboutToStop: (NSNotification*) aNote
{
    /* Stop the nhit monitor if it's running and post a notification telling
     * the run control to wait. Then we wait until the thread is done. */
    if (![self isRunning]) return;

    [self stop];

    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"waiting for nhit monitor", @"Reason",
                              nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAddRunStateChangeWait object: self userInfo: userInfo];

    /* detach a thread to wait until we actually stop. */
    [NSThread detachNewThreadSelector:@selector(_waitForThreadToFinish)
                             toTarget:self
                           withObject:nil];
}

- (void) orcaAboutToQuit: (NSNotification*) aNote
{
    /* Stop the nhit monitor if it's running and delay the termination. */
    if (![self isRunning]) return;

    [self stop];

    /* Tell Orca to wait five seconds before quitting. */
    [(ORAppDelegate *)[NSApp delegate] delayTermination];
}

- (void) _waitForThreadToFinish
{
    /* Thread to wait until the nhit monitor is done and then post a
     * notification telling the run control to continue. */
    while ([self isRunning]) {
        [NSThread sleepForTimeInterval:0.1];
    }

    /* Go ahead and end the run. */
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORReleaseRunStateChangeWait object: self];
}

- (BOOL) isRunning
{
    /* Returns if the nhit monitor is currently running. */
    return [runningThread isExecuting];
}

- (void) stop
{
    /* Stop the nhit monitor. */
    if ([self isRunning]) [runningThread cancel];
}

- (void) start: (int) crate pulserRate: (int) pulserRate numPulses: (int) numPulses maxNhit: (int) maxNhit
{
    /* Start the nhit monitor. This function will launch a thread which starts
     * the nhit monitor and then return immediately. To check when the nhit
     * monitor is done, you can periodically poll isRunning(). Any errors will
     * be printed to the log and the thread will quit. If the nhit monitor
     * succeeds, it will print the thresholds to the log, upload the results to
     * the database, and then quit. */
    if ([self isRunning]) {
        NSLog(@"nhit monitor is already running!\n");
        return;
    }

    /* Print out the settings we are going to run with. */
    NSLog(@"nhit monitor starting\n");
    NSLog(@"crate = %i\n", crate);
    NSLog(@"pulser rate = %i Hz\n", pulserRate);
    NSLog(@"num pulses = %i\n", numPulses);
    NSLog(@"max nhit = %i\n", maxNhit);

    /* There is no way as far as I can tell to launch a thread with more than
     * one argument, so we just put everything in a dictionary. */
    NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInt:crate], @"crate",
                            [NSNumber numberWithInt:pulserRate], @"pulserRate",
                            [NSNumber numberWithInt:numPulses], @"numPulses",
                            [NSNumber numberWithInt:maxNhit], @"maxNhit",
                             nil];

    [runningThread initWithTarget:self selector:@selector(run:) object:args];
    [runningThread start];

    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORNhitMonitorNotification object:self userInfo:nil];
}

- (int) connect
{
    /* Connect to the data server. Returns -1 on error. If successful, the
     * instance variable sock will be a socket file descriptor connected to the
     * data server. */
    SNOPModel *snop;
    char err[ANET_ERR_LEN];
    struct GenericRecordHeader header;

    /* Make sure we are disconnected. */
    [self disconnect];

    /* Get the SNO+ model object since we need to get the data server hostname. */
    NSArray* snops = [[(ORAppDelegate*)[NSApp delegate] document]
         collectObjectsOfClass:NSClassFromString(@"SNOPModel")];

    if ([snops count] == 0) {
        NSLogColor([NSColor redColor], @"unable to find SNO+ model object.\n");
        return -1;
    }

    snop = [snops objectAtIndex:0];

    sock = anetTcpConnect(err, (char *) [[snop dataHost] UTF8String], [snop dataPort]);

    if (sock == ANET_ERR) {
        NSLogColor([NSColor redColor], @"failed to connect to data server: %s",
                   err);
        return -1;
    }

    anetSendTimeout(err, sock, 1000);
    anetReceiveTimeout(err, sock, 1000);

    /* Send our name to the data server. */
    header.RecordID = htonl(kSCmd);
    header.RecordLength = htonl(4);
    header.RecordVersion = htonl(kId);

    if (write_record(sock, &header, "nhit") == -1) {
        NSLogColor([NSColor redColor], @"failed to send name to data server\n");
        goto err;
    }

    if (read_record(sock, &header, buf) == -1) {
        NSLogColor([NSColor redColor], @"failed to receive response from data server\n");
        goto err;
    }

    /* Subscribe to MTCD records from the data server. */
    header.RecordID = htonl(kSCmd);
    header.RecordLength = htonl(4);
    header.RecordVersion = htonl(kSub);

    if (write_record(sock, &header, "MTCD") == -1) {
        NSLogColor([NSColor redColor], @"failed to send subscription to data server\n");
        goto err;
    }

    if (read_record(sock, &header, buf) == -1) {
        NSLogColor([NSColor redColor], @"failed to receive response from data server\n");
        goto err;
    }

    return 0;
err:
    [self disconnect];
    return -1;
}

- (void) disconnect
{
    if (sock > 0) close(sock);
    sock = -1;
}

- (void) nhitMonitorCallback: (ORPQResult *) result
{
    if (!result) {
        NSLogColor([NSColor redColor], @"nhit monitor: failed to upload nhit monitor results to database!\n");
        return;
    }
}

- (void) run: (NSDictionary *) args
{
    SNOPModel *snop;

    @autoreleasepool {
        NSArray* snops = [[(ORAppDelegate*)[NSApp delegate] document]
             collectObjectsOfClass:NSClassFromString(@"SNOPModel")];

        if ([snops count] == 0) {
            NSLogColor([NSColor redColor], @"nhit monitor: unable to find SNO+ model object.\n");
            return;
        }

        snop = [snops objectAtIndex:0];

        /* Try to acquire the lock for 10 seconds. If we can't get it then we
         * just skip running the nhit monitor. */
        if ([[snop ecaLock] lockBeforeDate:[NSDate dateWithTimeIntervalSinceNow:10.0]]) {
            @try {
                [self _run:args];
            } @finally {
                /* Make sure to unlock the lock when we're done. */
                [[snop ecaLock] unlock];
            }
        } else {
            NSLogColor([NSColor redColor],
                       @"nhit monitor: unable to acquire eca lock!\n");
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORNhitMonitorNotification object:self userInfo:@{@"finished":@1}];
        }
    }
}

- (void) _run: (NSDictionary *) args
{
    /* Run the nhit monitor. This method should only be called by the start method. */
    SNOPModel *snop;
    uint32_t pedestals_enabled, pulser_enabled, pedestal_mask, coarse_delay;
    uint32_t fine_delay, pedestal_width;
    uint32_t control_register;
    uint32_t pulser_rate;
    uint32_t gt_mask;
    int i;
    ORFec32Model *fec;
    int slot, channel;

    int crate = [[args objectForKey:@"crate"] intValue];
    int pulserRate = [[args objectForKey:@"pulserRate"] intValue];
    int numPulses = [[args objectForKey:@"numPulses"] intValue];
    int maxNhit = [[args objectForKey:@"maxNhit"] intValue];

    NSArray* snops = [[(ORAppDelegate*)[NSApp delegate] document]
         collectObjectsOfClass:NSClassFromString(@"SNOPModel")];

    if ([snops count] == 0) {
        NSLogColor([NSColor redColor], @"nhit monitor: unable to find SNO+ model object.\n");
        goto err;
    }

    snop = [snops objectAtIndex:0];

    /* Since we are running in a separate thread, it's easiest to just open
     * up a new connection to the mtc server instead of having to dispatch
     * all commands to the main thread. */
    mtc = [[RedisClient alloc] initWithHostName:[snop mtcHost] withPort:[snop mtcPort]];
    /* Autorelease the MTC object. It will get freed when the function
     * finishes since we are in an @autoreleasepool block. */
    [mtc autorelease];

    /* Find the correct XL3. */
    xl3 = nil;

    NSArray* xl3s = [[(ORAppDelegate*)[NSApp delegate] document]
         collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];

    for (i = 0; i < [xl3s count]; i++) {
        if ([[xl3s objectAtIndex:i] crateNumber] == crate) {
            xl3 = [xl3s objectAtIndex:i];
            break;
        }
    }

    if (!xl3) {
        NSLogColor([NSColor redColor], @"nhit monitor: unable to find XL3 %i\n", crate);
        goto err;
    }

    if (![xl3 isTriggerON]) {
        NSLogColor([NSColor redColor], @"nhit monitor: crate %i triggers are off!\n", crate);
        goto err;
    }

    if (maxNhit > MAX_NHIT) {
        NSLogColor([NSColor redColor], @"nhit monitor: max nhit must be less than %i\n", MAX_NHIT);
        goto err;
    }

    /* Disable all pedestals. */
    for (slot = 0; slot < 16; slot++) {
        fec = [[OROrderedObjManager for:[xl3 guardian]] objectInSlot:16-slot];

        if (!fec) continue;

        dispatch_sync(dispatch_get_main_queue(), ^{
            [fec setPedEnabledMask:0];
        });
    }

    /* create a list of channels for which to enable pedestals. We only add
     * channels if both the N100 and N20 triggers are enabled. */
    NSMutableArray *slots = [NSMutableArray array];
    NSMutableArray *channels = [NSMutableArray array];
    /* Loop over channels 17 and 18 first, since they are the most likely
     * to have pickup. Then, we loop over the channels in order starting
     * from 0, except we skip the channels at the edge of each daughter
     * board since those tend to cause pickup on the next set of channels. */
    int channel_order[32] = {17,18,0,1,2,3,4,5,8,9,10,11,12,13,14,19,20,21,22,25,26,27,28,29,30,31,6,7,15,16,23,24};
    for (i = 0; i < 32; i++) {
        channel = channel_order[i];
        for (slot = 0; slot < 16; slot++) {
            fec = [[OROrderedObjManager for:[xl3 guardian]] objectInSlot:16-slot];

            if (!fec) continue;

            if ([fec trigger100nsEnabled: channel] && \
                [fec trigger20nsEnabled: channel]) {
                [slots addObject:[NSNumber numberWithInt:slot]];
                [channels addObject:[NSNumber numberWithInt:channel]];
            }
        }
    }

    if (maxNhit > [channels count]) {
        NSLogColor([NSColor redColor], @"nhit monitor: crate %i only has %i channels with triggers enabled, but max nhit is %i\n", crate, [channels count], maxNhit);
        goto err;
    }

    /* Connect to the data stream server. */
    if ([self connect]) {
        NSLogColor([NSColor redColor], @"nhit monitor: failed to connect to the data stream server\n");
        goto err;
    }

    @try {
        /* Save the current MTC settings so we can set them back when the
         * nhit monitor is done. */
        control_register = [mtc intCommand:"mtcd_read 0x0"];
        pedestals_enabled = control_register & 0x1;
        pulser_enabled = control_register & 0x2;
        pedestal_mask = [mtc intCommand:"get_ped_crate_mask"];
        pulser_rate = [mtc intCommand:"get_pulser_freq"];
        coarse_delay = [mtc intCommand:"get_coarse_delay"];
        fine_delay = [mtc intCommand:"get_fine_delay"];
        pedestal_width = [mtc intCommand:"get_pedestal_width"];
        gt_mask = [mtc intCommand:"get_gt_mask"];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor], @"nhit monitor failed to get mtc "
                   "hardware state. error: %@ reason: %@\n",
                   [e name], [e reason]);
        [self disconnect];
        goto err;
    }

    if ((gt_mask & MTC_PULSE_GT_MASK) == 0) {
        NSLogColor([NSColor redColor], @"nhit monitor: PULSE_GT is not masked in!\n");
        [self disconnect];
        goto err;
    }

    @try {
        /* Initialize the MTC settings for the nhit monitor. */
        [mtc okCommand:"disable_pulser"];
        [mtc okCommand:"enable_pedestals"];
        [mtc okCommand:"set_ped_crate_mask %i", (1 << crate)];
        [mtc okCommand:"set_pulser_freq %i", pulserRate];
        [mtc okCommand:"set_coarse_delay %i", COARSE_DELAY];
        [mtc okCommand:"set_fine_delay %i", FINE_DELAY];
        [mtc okCommand:"set_pedestal_width %i", PEDESTAL_WIDTH];

        /* turn off all pedestals */
        [xl3 setPedestalMask:[xl3 getSlotsPresent] pattern:0];

        /* We call another method here because we need to wrap everything
         * in a try-catch block so that if anything fails we make sure to
         * reset the MTC settings. */
        [self __run:crate pulserRate:pulserRate numPulses:numPulses maxNhit:maxNhit slots:slots channels:channels];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor], @"nhit monitor failed. error: %@ "
                   "reason: %@\n", [e name], [e reason]);
    } @finally {
        /* Make sure to reset all the hardware settings. */
        if (pedestals_enabled) {
            [mtc okCommand:"enable_pedestals"];
        } else {
            [mtc okCommand:"disable_pedestals"];
        }

        if (pulser_enabled) {
            [mtc okCommand:"enable_pulser"];
        } else {
            [mtc okCommand:"disable_pulser"];
        }

        [mtc okCommand:"set_ped_crate_mask %i", pedestal_mask];
        [mtc okCommand:"set_pulser_freq %i", pulser_rate];
        [mtc okCommand:"set_coarse_delay %i", coarse_delay];
        [mtc okCommand:"set_fine_delay %i", fine_delay];
        [mtc okCommand:"set_pedestal_width %i", pedestal_width];

        /* turn off all pedestals */
        [xl3 setPedestalMask:[xl3 getSlotsPresent] pattern:0];

        /* Disconnect from the data server. */
        [self disconnect];
    }

    NSLog(@"nhit monitor done\n");

err:
    /* Post a notification so that the SNOPController can enable the run
     * button. Note: ideally the SNOPController would just check to see if
     * the nhit monitor was running and then enable/disable the buttons
     * depending on if it's running. However, there is no easy way to post
     * the notification *after* this thread exits, and so when the
     * notification is posted the nhit monitor will still be running. To
     * get around this we add a userInfo dictionary to the notification. */
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORNhitMonitorNotification object:self userInfo:@{@"finished":@1}];
}

- (void) __run: (int) crate pulserRate: (int) pulserRate numPulses: (int) numPulses maxNhit: (int) maxNhit slots: (NSMutableArray *) slots channels:(NSMutableArray *) channels
{
    /* Run the nhit monitor. This method should only be called in a separate
     * thread. The start method should be called to actually start the nhit
     * monitor. */
    int slot, channel;
    struct NhitRecord nhitRecord;
    int i;
    ORFec32Model *fec;
    char err[256];

    if (pulserRate == 0) {
        NSLogColor([NSColor redColor], @"nhit monitor: pulser rate is zero!\n");
        return;
    }

    /* Set the timeout to twice how long we expect it to take. */
    int timeout = numPulses*2/pulserRate;

    /* To compute the time we use time(NULL) which returns the number of
     * seconds as an integer, so we don't want to set it too low. */
    if (timeout < 2) timeout = 2;

    /* Initialize the struct holding the number of nhit triggers which fire for
     * each nhit. */
    for (i = 0; i < MAX_NHIT; i++) {
        nhitRecord.nhit_100_lo[i] = 0;
        nhitRecord.nhit_100_med[i] = 0;
        nhitRecord.nhit_100_hi[i] = 0;
        nhitRecord.nhit_20[i] = 0;
        nhitRecord.nhit_20_lb[i] = 0;
    }

    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORNhitMonitorUpdateNotification object:self userInfo:@{@"nhit": @0, @"maxNhit": [NSNumber numberWithInt:maxNhit]}];
    for (i = 0; i <= maxNhit ; i++) {
        /* Check to see if we should stop. */
        if ([[NSThread currentThread] isCancelled]) {
            NSLogColor([NSColor redColor], @"nhit monitor: current thread was cancelled\n");
            return;
        }

        if (i > 0) {
            slot = [[slots objectAtIndex:i-1] intValue];
            channel = [[channels objectAtIndex:i-1] intValue];
            fec = [[OROrderedObjManager for:[xl3 guardian]] objectInSlot:16-slot];

            dispatch_sync(dispatch_get_main_queue(), ^{
                [fec setPed:channel enabled:1];
            });

            [xl3 setPedestals];
        }

        [mtc okCommand:"enable_pulser"];
        if (get_nhit_trigger_count(err, mtc, sock, buf, i, numPulses,
                                   &nhitRecord, timeout)) {
            NSLogColor([NSColor redColor], @"nhit monitor: %s\n", err);
            return;
        }

        [mtc okCommand:"disable_pulser"];
        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORNhitMonitorUpdateNotification object:self userInfo:@{@"nhit": [NSNumber numberWithInt:i], @"maxNhit": [NSNumber numberWithInt:maxNhit]}];
    }
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORNhitMonitorUpdateNotification object:self userInfo:@{@"nhit": [NSNumber numberWithInt:i], @"maxNhit": [NSNumber numberWithInt:maxNhit]}];

    /* print trigger thresholds */
    float threshold_n100_lo = get_threshold(nhitRecord.nhit_100_lo, maxNhit, numPulses);

    if (threshold_n100_lo < 0) {
        NSLog(@"nhit_100_lo  threshold is > %i nhit\n", maxNhit);
    } else {
        NSLog(@"nhit_100_lo  threshold is %.2f nhit\n", threshold_n100_lo);
    }

    float threshold_n100_med = get_threshold(nhitRecord.nhit_100_med, maxNhit, numPulses);

    if (threshold_n100_med < 0) {
        NSLog(@"nhit_100_med threshold is > %i nhit\n", maxNhit);
    } else {
        NSLog(@"nhit_100_med threshold is %.2f nhit\n", threshold_n100_med);
    }

    float threshold_n100_hi = get_threshold(nhitRecord.nhit_100_hi, maxNhit, numPulses);

    if (threshold_n100_hi < 0) {
        NSLog(@"nhit_100_hi  threshold is > %i nhit\n", maxNhit);
    } else {
        NSLog(@"nhit_100_hi  threshold is %.2f nhit\n", threshold_n100_hi);
    }

    float threshold_n20 = get_threshold(nhitRecord.nhit_20, maxNhit, numPulses);

    if (threshold_n20 < 0) {
        NSLog(@"nhit_20      threshold is > %i nhit\n", maxNhit);
    } else {
        NSLog(@"nhit_20      threshold is %.2f nhit\n", threshold_n20);
    }

    float threshold_n20_lb = get_threshold(nhitRecord.nhit_20_lb, maxNhit, numPulses);

    if (threshold_n20_lb < 0) {
        NSLog(@"nhit_20_lb   threshold is > %i nhit\n", maxNhit);
    } else {
        NSLog(@"nhit_20_lb   threshold is %.2f nhit\n", threshold_n20_lb);
    }

    NSDictionary *userInfo = @{@"n100_lo": @(threshold_n100_lo),
                               @"n100_med": @(threshold_n100_med),
                               @"n100_hi": @(threshold_n100_hi),
                               @"n20": @(threshold_n20),
                               @"n20_lb": @(threshold_n20_lb),
                               @"max_nhit": @(maxNhit)};

    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORNhitMonitorResultsNotification object:self userInfo:userInfo];

    NSMutableString *command = [NSMutableString stringWithFormat:@"INSERT INTO nhit_monitor (crate, num_pulses, pulser_rate, nhit_100_lo, nhit_100_med, nhit_100_hi, nhit_20, nhit_20_lb) VALUES (%i, %i, %i, ", crate, numPulses, pulserRate];

    [command appendString:@"ARRAY["];
    for (i = 0; i < maxNhit - 1; i++) {
        [command appendFormat:@"%i, ", nhitRecord.nhit_100_lo[i]];
    }
    [command appendFormat:@"%i], ", nhitRecord.nhit_100_lo[i]];

    [command appendString:@"ARRAY["];
    for (i = 0; i < maxNhit - 1; i++) {
        [command appendFormat:@"%i, ", nhitRecord.nhit_100_med[i]];
    }
    [command appendFormat:@"%i], ", nhitRecord.nhit_100_med[i]];

    [command appendString:@"ARRAY["];
    for (i = 0; i < maxNhit - 1; i++) {
        [command appendFormat:@"%i, ", nhitRecord.nhit_100_hi[i]];
    }
    [command appendFormat:@"%i], ", nhitRecord.nhit_100_hi[i]];

    [command appendString:@"ARRAY["];
    for (i = 0; i < maxNhit - 1; i++) {
        [command appendFormat:@"%i, ", nhitRecord.nhit_20[i]];
    }
    [command appendFormat:@"%i], ", nhitRecord.nhit_20[i]];

    [command appendString:@"ARRAY["];
    for (i = 0; i < maxNhit - 1; i++) {
        [command appendFormat:@"%i, ", nhitRecord.nhit_20_lb[i]];
    }
    [command appendFormat:@"%i]) RETURNING key", nhitRecord.nhit_20_lb[i]];

    ORPQModel *db = [ORPQModel getCurrent];

    if (!db) {
        NSLog(@"Postgres object not found, please add it to the experiment!\n");
        return;
    }

    [db dbQuery:command object:self selector:@selector(nhitMonitorCallback:) timeout:10.0];

    return;
}
@end
