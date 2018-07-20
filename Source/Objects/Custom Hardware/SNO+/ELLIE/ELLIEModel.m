//
//  ELLIEModel.m
//  Orca
//
//  Created by Chris Jones on 01/04/2014.
//
//  Revision history:
//  Ed Leming 30/12/2015 - Memory updates and tidy up.
//
//

/*TODO:
        - Check the standard run name doesn't already exsists in the DB
        - read from and write to the local couch DB for both smellie and tellie
        - fix the intensity steps in SMELLIE such that negative values cannot be considered
        - add the TELLIE GUI Information
        - add the sockets for TELLIE to communicate with itself
        - add the AMELLIE GUI
        - make sure old files cannot be overridden 
        - add the configuration files GUI for all the ELLIE systems (LOW PRIORITY)
        - add the Emergency stop button 
        - make the SMELLIE Control functions private (eventually)
*/

#import "ELLIEModel.h"
#import "ORTaskSequence.h"
#import "ORCouchDB.h"
#import "ORRunModel.h"
#import "SNOPModel.h"
#import "ORMTCModel.h"
#import "TUBiiModel.h"
#import "TUBiiController.h"
#import "ORRunController.h"
#import "ORMTC_Constants.h"
#import "SNOP_Run_Constants.h"
#import "RunTypeWordBits.hh"

//tags to define that an ELLIE run file has been updated
#define kSmellieRunDocumentAdded @"kSmellieRunDocumentAdded"
#define kSmellieRunDocumentUpdated @"kSmellieRunDocumentUpdated"
#define kSmellieConigVersionRetrieved @"kSmellieConfigVersionRetrieved"
#define kSmellieConigRetrieved @"kSmellieConfigRetrieved"

#define kTellieRunDocumentAdded @"kTellieRunDocumentAdded"
#define kTellieRunDocumentUpdated @"kTellieRunDocumentUpdated"
#define kTellieParsRetrieved @"kTellieParsRetrieved"
#define kTellieMapRetrieved @"kTellieMapRetrieved"
#define kTellieNodeRetrieved @"kTellieNodeRetrieved"
#define kTellieRunPlansRetrieved @"kTellieRunPlansRetrieved"

#define kAmellieFibresRetrieved @"kAmellieFibresRetrieved"
#define kAmellieNodesRetrieved @"kAmellieNodesRetrieved"
#define kAmellieRunDocumentAdded @"kAmellieRunDocumentAdded"
#define kAmellieRunDocumentUpdated @"kAmellieRunDocumentUpdated"

//sub run information tags
#define kSmellieSubRunDocumentAdded @"kSmellieSubRunDocumentAdded"

NSString* ELLIEAllLasersChanged = @"ELLIEAllLasersChanged";
NSString* ELLIEAllFibresChanged = @"ELLIEAllFibresChanged";
NSString* smellieRunDocsPresent = @"smellieRunDocsPresent";
NSString* ORTELLIERunStartNotification = @"ORTELLIERunStarted";
NSString* ORSMELLIERunStartNotification = @"ORSMELLIERunStarted";
NSString* ORAMELLIERunStartNotification = @"ORAMELLIERunStarted";
NSString* ORSMELLIERunFinishedNotification = @"ORSMELLIERunFinished";
NSString* ORTELLIERunFinishedNotification = @"ORTELLIERunFinished";
NSString* ORAMELLIERunFinishedNotification = @"ORAMELLIERunFinished";
NSString* ORAMELLIEMappingReceived = @"ORAMELLIEMappingReceived";
NSString* ORSMELLIEInterlockKilled = @"ORSMELLIEInterlockKilled";
NSString* ORELLIEFlashing = @"ORELLIEFlashing";
NSString* ORSMELLIEEmergencyStop = @"ORSMELLIEEmergencyStop";

///////////////////////////////
// Define private methods
@interface ELLIEModel (private)
-(void) _pushEllieCustomRunToDB:(NSString*)aCouchDBName runFiletoPush:(NSMutableDictionary*)customRunFile withDocType:(NSString*)aDocType;
-(void) _pushEllieConfigDocToDB:(NSString*)aCouchDBName runFiletoPush:(NSMutableDictionary*)customRunFile withDocType:(NSString*)aDocType;
-(NSString*) stringDateFromDate:(NSDate*)aDate;
@end


//////////////////////////////
// Begin implementation
@implementation ELLIEModel

// Use synthesize to generate all our setters and getters.
// Be explicit about which instance variables to associate
// with each.
@synthesize tellieFireParameters = _tellieFireParameters;
@synthesize tellieFibreMapping = _tellieFibreMapping;
@synthesize tellieNodeMapping = _tellieNodeMapping;
@synthesize tellieRunNames = _tellieRunNames;
@synthesize tellieRunDoc = _tellieRunDoc;

@synthesize smellieRunSettings = _smellieRunSettings;
@synthesize smellieRunHeaderDocList = _smellieRunHeaderDocList;
@synthesize smellieSubRunInfo = _smellieSubRunInfo;
@synthesize smellieLaserHeadToSepiaMapping = _smellieLaserHeadToSepiaMapping;
@synthesize smellieLaserToInputFibreMapping = _smellieLaserToInputFibreMapping;
@synthesize smellieFibreSwitchToFibreMapping = _smellieFibreSwitchToFibreMapping;
@synthesize smellieSlaveMode = _smellieSlaveMode;
@synthesize smellieConfigVersionNo = _smellieConfigVersionNo;
@synthesize smellieRunDoc = _smellieRunDoc;
@synthesize smellieDBReadInProgress = _smellieDBReadInProgress;

@synthesize amellieRunDoc = _amellieRunDoc;
@synthesize amellieFireParameters = _amellieFireParameters;
@synthesize amellieFibreMapping = _amellieFibreMapping;
@synthesize amellieNodeMapping = _amellieNodeMapping;

@synthesize tellieHost = _tellieHost;
@synthesize smellieHost = _smellieHost;
@synthesize interlockHost = _interlockHost;
@synthesize telliePort = _telliePort;
@synthesize smelliePort = _smelliePort;
@synthesize interlockPort = _interlockPort;

@synthesize tellieClient = _tellieClient;
@synthesize smellieClient = _smellieClient;
@synthesize smellieFlaggingClient = _smellieFlaggingClient;
@synthesize interlockClient = _interlockClient;

@synthesize ellieFireFlag = _ellieFireFlag;
@synthesize tellieMultiFlag = _tellieMultiFlag;
@synthesize exampleTask = _exampleTask;
@synthesize pulseByPulseDelay = _pulseByPulseDelay;
@synthesize currentOrcaSettingsForSmellie = _currentOrcaSettingsForSmellie;

@synthesize tellieThread = _tellieThread;
@synthesize smellieThread = _smellieThread;
@synthesize tellieTransitionThread = _tellieTransitionThread;
@synthesize smellieTransitionThread = _smellieTransitionThread;

@synthesize maintenanceRollOver = _maintenanceRollOver;
@synthesize smellieStopButton = _smellieStopButton;

@synthesize tuningRun = _tuningRun;

/*********************************************************/
/*                  Class control methods                */
/*********************************************************/
- (id) init
{
    self = [super init];
    return self;
}

-(id) initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self){
        [self registerNotificationObservers];

        //Settings
        [self setTellieHost:[decoder decodeObjectForKey:@"tellieHost"]];
        [self setTelliePort:[decoder decodeObjectForKey:@"telliePort"]];

        [self setSmellieHost:[decoder decodeObjectForKey:@"smellieHost"]];
        [self setSmelliePort:[decoder decodeObjectForKey:@"smelliePort"]];

        [self setInterlockHost:[decoder decodeObjectForKey:@"interlockHost"]];
        [self setInterlockPort:[decoder decodeObjectForKey:@"interlockPort"]];

        /* Check if we actually decoded the various server hostnames
         * and ports. decodeObjectForKey() will return NULL if the
         * key doesn't exist, and decodeIntForKey() will return 0. */
        if ([self tellieHost] == NULL) [self setTellieHost:@""];
        if ([self smellieHost] == NULL) [self setSmellieHost:@""];
        if ([self interlockHost] == NULL) [self setInterlockHost:@""];

        if ([self telliePort] == NULL) [self setTelliePort:@"5030"];
        if ([self smelliePort] == NULL) [self setSmelliePort:@"5020"];
        if ([self interlockPort] == NULL) [self setInterlockPort:@"5021"];

        XmlrpcClient* tellieCli = [[XmlrpcClient alloc] initWithHostName:[self tellieHost] withPort:[self telliePort]];
        XmlrpcClient* smellieCli = [[XmlrpcClient alloc] initWithHostName:[self smellieHost] withPort:[self smelliePort]];
        XmlrpcClient* smellieFlaggingCli = [[XmlrpcClient alloc] initWithHostName:[self smellieHost] withPort:[self smelliePort]];
        XmlrpcClient* interlockCli = [[XmlrpcClient alloc] initWithHostName:[self interlockHost] withPort:[self interlockPort]];

        [self setTellieClient:tellieCli];
        [self setSmellieClient:smellieCli];
        [self setSmellieFlaggingClient:smellieFlaggingCli];
        [self setInterlockClient:interlockCli];

        [[self tellieClient] setTimeout:100]; // Sometimes TELLIE calls can take longer than expected due to network speeds on the logging calls.
        [[self smellieClient] setTimeout:1200]; // Smellie server calls are flagging. This sets the max time of single a flash sequence to 20 mins
        [[self smellieFlaggingClient] setTimeout:60]; // Use this client for getting run flags and calling deactivate functions
        [[self interlockClient] setTimeout:10];

        [tellieCli release];
        [smellieCli release];
        [smellieFlaggingCli release];
        [interlockCli release];

        // Force the tuningRun flag (and checkbox) to be zero (i.e. run rolls over at end of T/AMELLIE sequence by default)
        [self setTuningRun:[NSNumber numberWithInteger:0]];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];

    //Settings
    [encoder encodeObject:[self tellieHost] forKey:@"tellieHost"];
    [encoder encodeObject:[self telliePort] forKey:@"telliePort"];

    [encoder encodeObject:[self smellieHost] forKey:@"smellieHost"];
    [encoder encodeObject:[self smelliePort] forKey:@"smelliePort"];

    [encoder encodeObject:[self interlockHost] forKey:@"interlockHost"];
    [encoder encodeObject:[self interlockPort] forKey:@"interlockPort"];
}

- (void) setUpImage
{
    [self setSmellieDBReadInProgress:NO];
    [self setImage:[NSImage imageNamed:@"ellie"]];
}

- (void) makeMainController
{
    [self linkToController:@"ELLIEController"];
}

- (void) wakeUp
{
    if([self aWake])return;
    [super wakeUp];
}

- (void) sleep
{
	[super sleep];
}

-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    // Release all NSObject member vairables
    [_smellieRunSettings release];
    [_currentOrcaSettingsForSmellie release];
    [_tellieRunDoc release];
    [_smellieRunDoc release];
    [_exampleTask release];
    [_smellieRunHeaderDocList release];
    [_smellieSubRunInfo release];

    // Server Clients
    [_tellieClient release];
    [_smellieClient release];
    [_smellieFlaggingClient release];
    
    // tellie settings
    [_tellieFireParameters release];
    [_tellieFibreMapping release];
    [_tellieNodeMapping release];

    // amellie settings
    [_amellieFireParameters release];
    [_amellieFibreMapping release];
    [_amellieRunDoc release];
    [_amellieNodeMapping release];

    // smellie config mappings
    [_smellieLaserHeadToSepiaMapping release];
    [_smellieLaserToInputFibreMapping release];
    [_smellieFibreSwitchToFibreMapping release];
    [_smellieConfigVersionNo release];

    [_tellieRunNames release];
    [_interlockPort release];
    [_tellieHost release];
    [_tellieThread release];
    [_telliePort release];
    [_interlockClient release];
    [_smellieHost release];
    [_smellieThread release];
    [_tellieNodeMapping release];
    [_smelliePort release];
    [_interlockHost release];

    // Threads
    [_smellieTransitionThread release];
    [_tellieTransitionThread release];

    [_tuningRun release];

    [super dealloc];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

    [notifyCenter addObserver : self
                     selector : @selector(checkAndTidyELLIEThreads:)
                         name : ORRunAboutToStopNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(checkAndTidyELLIEThreads:)
                         name : OROrcaAboutToQuitNotice
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(killKeepAlive:)
                         name : ORSMELLIEEmergencyStop
                        object: nil];
}

-(void) checkAndTidyELLIEThreads:(NSNotification *)aNote
{
    /*
     Check to see if an ELLIE fire sequence has been running. If so, the stop*ellieRun methods of
     the ellieModel will post the run wait notification and launch a thread that waits for the smellieThread
     to stop executing before tidying up and, finally, releasing the run wait.
     */
    [self setMaintenanceRollOver:NO];
    if([[self tellieThread] isExecuting]){
        [self stopTellieRun];
    }
    if([[self smellieThread] isExecuting]){
        [self stopSmellieRun];
    }
}

/*********************************************************/
/*                    TELLIE Functions                   */
/*********************************************************/
-(NSArray*) pollTellieFibre:(double)timeOutSeconds
{
    /*
     Poll the TELLIE hardware using an XMLRPC server and requests the response from the
     hardware. If no response is observed the the hardware is re-polled once every second
     untill a timeout limit has been reached.

     Arguments:
       double timeOutSeconds :  How many seconds to wait before polling is considered a
                                failure and an exception thrown.

    */
    NSArray* blankResponse = [NSArray arrayWithObjects:[NSNumber numberWithInt:0], [NSNumber numberWithInt:0], nil];
    NSArray* pollResponse = [[self tellieClient] command:@"read_pin_sequence"];
    int count = 0;
    NSLog(@"[T/AMELLIE]: Will poll for pin response for the next %1.1f s\n", timeOutSeconds);
    while ([pollResponse isKindOfClass:[NSString class]] && count < timeOutSeconds){
        // Check the thread hasn't been cancelled
        if([[NSThread currentThread] isCancelled]){
            return blankResponse;
        }
        [NSThread sleepForTimeInterval:1.0];
        @try{
            pollResponse = [[self tellieClient] command:@"read_pin_sequence"];
        }@catch(NSException* e){
            NSLogColor([NSColor redColor], @"[T/AMELLIE]: Exception caught polling for PIN response: %@\n", [e reason]);
            return blankResponse;
        }
        count = count + 1;
    }
    
    // Some checks on the response
    if ([pollResponse isKindOfClass:[NSString class]]){
        // In this case the sequence has not completed (likely due to missing triggers).
        // Output a message for the user, then tell the hardware so it can reset its counters
        // ready for the next sequence.
        NSLogColor([NSColor redColor], @"[T/AMELLIE]: PIN diode poll returned %@. Likely that the sequence didn't finish before timeout.\n", pollResponse);
        @try{
            pollResponse = [[self tellieClient] command:@"read_pin_sequence_timeout"];
        }@catch(NSException* e){
            NSLogColor([NSColor redColor], @"[T/AMELLIE]: Exception caught sending pin sequence timeout: %@\n", [e reason]);
            return blankResponse;
        }

        //If the timeout function returned, tell the user what was fed back, otherwise just return blank
        if(![pollResponse isKindOfClass:[NSString class]]){
            NSLogColor([NSColor redColor],
                       @"[T/AMELLIE]: Values returned for incomplete sequence: %i +/- %1.1f. THESE WILL NOT BE PUSHED TO COUCHDB\n",
                       [[pollResponse objectAtIndex:0] integerValue],
                       [[pollResponse objectAtIndex:1] floatValue]);
        }
        return blankResponse;
    } else if ([pollResponse count] != 3) {
        NSLogColor([NSColor redColor], @"[T/AMELLIE]: PIN diode poll returned array of len %i - expected 3\n", [pollResponse count]);
        return blankResponse;
    }
    return pollResponse;
}

-(NSMutableDictionary*) returnTellieFireCommands:(NSString*)fibre withNPhotons:(NSUInteger)photons withFireFrequency:(NSUInteger)frequency withNPulses:(NSUInteger)pulses withTriggerDelay:(NSUInteger)delay inSlave:(BOOL)mode isAMELLIE:(BOOL)amellie
{
    /*
     Calculate the tellie fire commands given certain input parameters
    */
    NSNumber* channel;
    NSDictionary* fireParameters;

    if(amellie){
        channel = [self calcAmellieChannelForFibre:fibre];
        fireParameters = [self amellieFireParameters];
    } else {
        channel = [self calcTellieChannelForFibre:fibre];
        fireParameters = [self tellieFireParameters];
    }
    if([channel intValue] < 0){
        return nil;
    }

    NSNumber* pulseWidth = [self calcTellieChannelPulseSettings:[channel integerValue]
                                                   withNPhotons:photons
                                              withFireFrequency:frequency
                                                        inSlave:mode
                                                        isAMELLIE:amellie];
    if([pulseWidth intValue] < 0){
        return nil;
    }
    
    NSString* modeString;
    if(mode == YES){
        modeString = @"Slave";
    } else {
        modeString = @"Master";
    }
    float pulseSeparation = 1000.*(1./frequency); // TELLIE accepts pulse rate in ms
    NSNumber* fibre_delay = [[fireParameters objectForKey:[NSString stringWithFormat:@"channel_%d",[channel intValue]]] objectForKey:@"fibre_delay"];
    
    NSMutableDictionary* settingsDict = [NSMutableDictionary dictionaryWithCapacity:100];
    [settingsDict setValue:fibre forKey:@"fibre"];
    [settingsDict setValue:channel forKey:@"channel"];
    [settingsDict setValue:modeString forKey:@"run_mode"];
    [settingsDict setValue:[NSNumber numberWithInteger:photons] forKey:@"photons"];
    [settingsDict setValue:pulseWidth forKey:@"pulse_width"];
    [settingsDict setValue:[NSNumber numberWithFloat:pulseSeparation] forKey:@"pulse_separation"];
    [settingsDict setValue:[NSNumber numberWithInteger:pulses] forKey:@"number_of_shots"];
    [settingsDict setValue:[NSNumber numberWithInteger:delay] forKey:@"trigger_delay"];
    [settingsDict setValue:[NSNumber numberWithFloat:[fibre_delay floatValue]] forKey:@"fibre_delay"];
    [settingsDict setValue:[NSNumber numberWithInteger:16383] forKey:@"pulse_height"];
    return settingsDict;
}

-(NSNumber*) calcTellieChannelPulseSettings:(NSUInteger)channel withNPhotons:(NSUInteger)photons withFireFrequency:(NSUInteger)frequency inSlave:(BOOL)mode isAMELLIE:(BOOL)amellie
{
    /*
     Calculate the pulse width settings required to return a given intenstity from a specified channel, 
     at a specified rate.
    */
    NSDictionary* firePars;
    if(amellie){
        firePars = [self amellieFireParameters];
    } else {
        firePars = [self tellieFireParameters];
    }

    // Check if fire parameters have been successfully loaded
    if(firePars == nil){
        if(amellie){
            NSLogColor([NSColor redColor], @"[AMELLIE]: TELLIE_FIRE_PARMETERS doc has not been loaded from telliedb - you need to call loadTellieStaticsFromDB\n");
        } else {
            NSLogColor([NSColor redColor], @"[TELLIE]: TELLIE_FIRE_PARMETERS doc has not been loaded from telliedb - you need to call loadTellieStaticsFromDB\n");
        }
        return 0;
    }
    
    // Run photon intensity check
    bool safety_check = [self photonIntensityCheck:photons atFrequency:frequency];
    if(safety_check == NO){
        NSLogColor([NSColor redColor], @"[TELLIE]: The requested number of photons (%u), is not detector safe at %u Hz. This setting will not be run.\n", photons, frequency);
        return [NSNumber numberWithInt:-1];
    }
    
    // Frequency check
    if(frequency != 1000){
        NSLogColor([NSColor orangeColor], @"[TELLIE]: CAUTION calibrations are only valid at 1kHz. Photon output may vary from requested setting\n");
    }
    
    // Used modality to define a string prefix for reading from database file
    NSString* prefix;
    if(mode == YES){
        prefix = @"slave";
    } else {
        prefix = @"master";
    }
    
    // Get Calibration parameters
    NSArray* IPW_values = [[firePars objectForKey:[NSString stringWithFormat:@"channel_%d",(int)channel]] objectForKey:[NSString stringWithFormat:@"%@_IPW",prefix]];
    NSArray* photon_values = [[firePars objectForKey:[NSString stringWithFormat:@"channel_%d",(int)channel]] objectForKey:[NSString stringWithFormat:@"%@_photons",prefix]];

    ////////////
    // Find minimum calibration point. If request is below minimum, estiamate the IPW
    // setting and inform the user.
    float min_photons = [[photon_values valueForKeyPath:@"@min.self"] floatValue];
    int min_x = [[IPW_values objectAtIndex:[photon_values indexOfObject:[photon_values valueForKeyPath:@"@min.self"]]] intValue];
    if(photons < min_photons){
        NSLog(@"[TELLIE]: Calibration curve for channel %u does not go as low as %u photons\n", channel, photons);
        NSLog(@"[TELLIE]: Using a linear interpolation of -5ph/IPW from min_photons = %.1f to estimate requested %d photon settings\n",min_photons,photons);
        float intercept = min_photons - (-5.*min_x);
        float floatPulseWidth = (photons - intercept)/(-5.);
        NSNumber* pulseWidth = [NSNumber numberWithInteger:floatPulseWidth];
        return pulseWidth;
    }
    
    /////////////
    // If requested photon output is within range, find xy points above and below threshold.
    // Appropriate setting will be estiamated with a linear interpolation between these points.
    int index = 0;
    for(NSNumber* val in photon_values){
        if([val floatValue] < photons){
            break;
        }
        index = index + 1;
    }
    float x1 = [[IPW_values objectAtIndex:(index-1)] floatValue];
    float x2 = [[IPW_values objectAtIndex:(index)] floatValue];
    float y1 = [[photon_values objectAtIndex:(index-1)] floatValue];
    float y2 = [[photon_values objectAtIndex:(index)] floatValue];
    
    // Calculate gradient and offset for interpolation.
    float dydx = (y1 - y2)/(x1 - x2);
    float intercept = y1 - dydx*x1;
    float floatPulseWidth = (photons - intercept) / dydx;
    NSNumber* pulseWidth = [NSNumber numberWithInteger:floatPulseWidth];

    return pulseWidth;
}


-(NSNumber*)calcPhotonsForIPW:(NSUInteger)ipw forChannel:(NSUInteger)channel inSlave:(BOOL)inSlave
{
    /*
     Calculte what photon output will be produced for a given IPW
     */
    
    /////////////
    // Used modality to define a string prefix for reading from database file
    NSString* prefix;
    if(inSlave == YES){
        prefix = @"slave";
    } else {
        prefix = @"master";
    }
    
    //////////////
    // Get Calibration parameters
    NSArray* IPW_values = [[[self tellieFireParameters] objectForKey:[NSString stringWithFormat:@"channel_%d",(int)channel]] objectForKey:[NSString stringWithFormat:@"%@_IPW",prefix]];
    NSArray* photon_values = [[[self tellieFireParameters] objectForKey:[NSString stringWithFormat:@"channel_%d",(int)channel]] objectForKey:[NSString stringWithFormat:@"%@_photons",prefix]];
    
    ////////////
    // Find minimum calibration point. If request is below minimum, estiamate the IPW
    // setting and inform the user.
    float min_photons = [[photon_values valueForKeyPath:@"@min.self"] floatValue];
    int max_ipw = [[IPW_values objectAtIndex:[photon_values indexOfObject:[photon_values valueForKeyPath:@"@min.self"]]] intValue];
    if(ipw > max_ipw){
        NSLog(@"[T/AMELLIE]: Requested IPW is larger than any value in the calibration curve.\n");
        NSLog(@"[T/AMELLIE]: Using a linear interpolation of 5ph/IPW from min_photons = %.1f (IPW = %d) to estimate photon output at requested setting\n",min_photons, max_ipw);
        float intercept = min_photons - (-5.*max_ipw);
        float photonsFloat = (-5.*ipw) + intercept;
        if(photonsFloat < 0){
            photonsFloat = 0.;
        }
        NSNumber* photons = [NSNumber numberWithFloat:photonsFloat];
        return photons;
    }
    
    /////////////
    // If requested photon output is within range, find xy points above and below threshold.
    // Appropriate setting will be estiamated with a linear interpolation between these points.
    int index = 0;
    for(NSNumber* val in IPW_values){
        index = index + 1;
        if([val intValue] > ipw){
            break;
        }
    }
    index = index - 1;
    
    float x1 = [[IPW_values objectAtIndex:(index-1)] floatValue];
    float x2 = [[IPW_values objectAtIndex:(index)] floatValue];
    float y1 = [[photon_values objectAtIndex:(index-1)] floatValue];
    float y2 = [[photon_values objectAtIndex:(index)] floatValue];
    
    // Calculate gradient and offset for interpolation.
    float dydx = (y1 - y2)/(x1 - x2);
    float intercept = y1 - dydx*x1;
    float photonsFloat = (dydx*ipw) + intercept;
    NSNumber* photons = [NSNumber numberWithInteger:photonsFloat];
    
    return photons;
}

-(BOOL)photonIntensityCheck:(NSUInteger)photons atFrequency:(NSUInteger)frequency
{
    /*
     A detector safety check. At high frequencies the maximum tellie output must be small
     to avoid pushing too much current through individual channels / trigger sums. Use a
     loglog curve to define what counts as detector safe.
     */
    
    /*
     Currently the predicted nPhotons does not correlate with reality so this check is defunct.
     it might be worth adding it back eventually once our understanding has improved. For now
     make do with a simple rate check (below).
    float safe_gradient = -1;
    float safe_intercept = 1.05e6;
    float max_photons = safe_intercept*pow(frequency, safe_gradient);
    if(photons > max_photons){
        return NO;
    } else {
        return YES;
    }
     */
    if(frequency > 1.01e3)
        return NO;
    return YES;
}

-(NSString*)calcTellieFibreForNode:(NSUInteger)node{
    /*
     Use node-to-fibre map loaded from the telliedb to find the priority fibre on a node.
     */
    if(![[self tellieNodeMapping] objectForKey:[NSString stringWithFormat:@"panel_%d",(int)node]]){
        NSLogColor([NSColor redColor], @"[TELLIE]: Node map does not include a reference to node: %d",node);
        return nil;
    }
    
    // Read panel info into local dictionary
    NSMutableDictionary* nodeInfo = [[self tellieNodeMapping] objectForKey:[NSString stringWithFormat:@"panel_%d",(int)node]];
    
    //***************************************//
    // Select appropriate fibre for this node.
    //***************************************//
    NSMutableArray* goodFibres = [[NSMutableArray alloc] init];
    NSMutableArray* lowTransFibres = [[NSMutableArray alloc] init];
    NSMutableArray* brokenFibres = [[NSMutableArray alloc] init];
    // Find which fibres are good / bad etc.
    for(NSString* key in nodeInfo){
        if([[nodeInfo objectForKey:key] intValue] ==  0){
            [goodFibres addObject:key];
        } else if([[nodeInfo objectForKey:key] intValue] ==  1){
            [lowTransFibres addObject:key];
        } else if([[nodeInfo objectForKey:key] intValue] ==  2){
            [brokenFibres addObject:key];
        }
    }
    
    NSString* selectedFibre = @"";
    if([goodFibres count] > 0){
        selectedFibre = [self selectPriorityFibre:goodFibres forNode:node];
    } else if([lowTransFibres count] > 0){
        selectedFibre = [self selectPriorityFibre:lowTransFibres forNode:node];
        NSLogColor([NSColor redColor], @"[TELLIE]: Selected low trasmission fibre %@\n", selectedFibre);
    } else if([brokenFibres count] > 0){
        selectedFibre = [self selectPriorityFibre:brokenFibres forNode:node];
        NSLogColor([NSColor redColor], @"[TELLIE]: Selected broken fibre %@\n", selectedFibre);
    }
    
    [goodFibres release];
    [lowTransFibres release];
    [brokenFibres release];

    return selectedFibre;
}

-(NSNumber*) calcTellieChannelForFibre:(NSString*)fibre
{
    /*
     Use patch pannel map loaded from the telliedb to map a given fibre to the correct tellie channel.
    */
    if([self tellieFibreMapping] == nil){
        NSLogColor([NSColor redColor], @"[TELLIE]: fibre map has not been loaded from couchdb - you need to call loadTellieStaticsFromDB\n");
        return [NSNumber numberWithInt:-1];
    }
    if(![[[self tellieFibreMapping] objectForKey:@"fibres"] containsObject:fibre]){
        NSLogColor([NSColor redColor], @"[TELLIE]: Patch map does not include a reference to fibre: %@\n",fibre);
        return [NSNumber numberWithInt:-2];
    }
    NSUInteger fibreIndex = [[[self tellieFibreMapping] objectForKey:@"fibres"] indexOfObject:fibre];
    NSUInteger channelInt = [[[[self tellieFibreMapping] objectForKey:@"channels"] objectAtIndex:fibreIndex] integerValue];
    NSNumber* channel = [NSNumber numberWithInteger:channelInt];
    return channel;
}

-(NSNumber*) calcAmellieChannelForFibre:(NSString*)fibre
{
    /*
     Use patch pannel map loaded from the amelliedb to map a given fibre to the correct amellie channel.
     */
    if([self amellieFibreMapping] == nil){
        NSLogColor([NSColor redColor], @"[AMELLIE]: fibre map has not been loaded from couchdb - you need to call loadTellieStaticsFromDB\n");
        return [NSNumber numberWithInt:-1];
    }
    if(![[[self amellieFibreMapping] objectForKey:@"fibres"] containsObject:fibre]){
        NSLogColor([NSColor redColor], @"[AMELLIE]: Patch map does not include a reference to fibre: %@\n",fibre);
        return [NSNumber numberWithInt:-2];
    }
    NSUInteger fibreIndex = [[[self amellieFibreMapping] objectForKey:@"fibres"] indexOfObject:fibre];
    NSUInteger channelInt = [[[[self amellieFibreMapping] objectForKey:@"channels"] objectAtIndex:fibreIndex] integerValue];
    NSNumber* channel = [NSNumber numberWithInteger:channelInt];
    return channel;
}

-(NSString*) calcTellieFibreForChannel:(NSUInteger)channel
{
    /*
     Use patch pannel map loaded from the telliedb to map a given fibre to the correct tellie channel.
     */
    if([self tellieFibreMapping] == nil){
        NSLogColor([NSColor redColor], @"[TELLIE]: fibre map has not been loaded from couchdb - you need to call loadTellieStaticsFromDB\n");
        return nil;
    }

    NSUInteger channelIndex;
    @try{
        channelIndex = [[[self tellieFibreMapping] objectForKey:@"channels"] indexOfObject:[NSString stringWithFormat:@"%d",(int)channel]];
    }@catch(NSException* e) {
        channelIndex = [[[self tellieFibreMapping] objectForKey:@"channels"] indexOfObject:[NSString stringWithFormat:@"%d",(int)channel]];
    }
    NSString* fibre = [[[self tellieFibreMapping] objectForKey:@"fibres"] objectAtIndex:channelIndex];
    return fibre;
}

-(NSString*)selectPriorityFibre:(NSArray*)fibres forNode:(NSUInteger)node{
    /*
     Select appropriate fibre based on naming convensions for the node at
     which they were installed.
     */
    
    //First find if primary / secondary fibres exist.
    NSString* primaryFibre = [NSString stringWithFormat:@"FT%03ldA", node];
    NSString* secondaryFibre = [NSString stringWithFormat:@"FT%03ldB", node];
    
    if([fibres indexOfObject:primaryFibre] != NSNotFound){
        return [fibres objectAtIndex:[fibres indexOfObject:primaryFibre]];
    }
    if([fibres indexOfObject:secondaryFibre] != NSNotFound){
        return [fibres objectAtIndex:[fibres indexOfObject:secondaryFibre]];
    }
    
    // If priority fibres don't exist, sort others into A/B arrays
    NSMutableArray* aFibres = [[NSMutableArray alloc] init];
    NSMutableArray* bFibres = [[NSMutableArray alloc] init];
    for(NSString* fibre in fibres){
        if([fibre rangeOfString:@"A"].location != NSNotFound){
            [aFibres addObject:fibre];
        } else if([fibre rangeOfString:@"B"].location != NSNotFound){
            [bFibres addObject:fibre];
        }
    }
    
    // Select from available fibes, with a preference for A type
    NSString* returnFibre = @"";
    if([aFibres count] > 0){
        returnFibre = [aFibres objectAtIndex:0];
    } else if ([bFibres count] > 0){
        returnFibre = [bFibres objectAtIndex:0];
    }
    [aFibres release];
    [bFibres release];
    return returnFibre;
}

//////////////////////////////////////////////////////
// AMELLIE parameter functions
-(NSMutableDictionary*)returnAmellieFireCommands:(NSString*)fibre
                                     withPhotons:(NSUInteger)photons
                               withFireFrequency:(NSUInteger)frequency
                                     withNPulses:(NSUInteger)pulses
                                withTriggerDelay:(NSUInteger)delay
                                         inSlave:(BOOL)mode
{
    /*
     Calculate the tellie fire commands given certain input parameters
     */
    NSNumber* amellieChannel = [self calcAmellieChannelForFibre:fibre];
    NSNumber* pulseWidth = [self calcTellieChannelPulseSettings:[amellieChannel integerValue]
                                                   withNPhotons:photons
                                              withFireFrequency:frequency
                                                        inSlave:mode
                                                      isAMELLIE:YES];
    NSString* modeString;
    if(mode == YES){
        modeString = @"Slave";
    } else {
        modeString = @"Master";
    }
    float pulseSeparation = 1000.*(1./frequency); // TELLIE accepts pulse rate in ms
    NSNumber* fibre_delay = [[[self amellieFireParameters]
                              objectForKey:[NSString stringWithFormat:@"channel_%d",[amellieChannel intValue]]]
                                objectForKey:@"fibre_delay"];

    NSMutableDictionary* settingsDict = [NSMutableDictionary dictionaryWithCapacity:100];
    [settingsDict setValue:fibre forKey:@"fibre"];
    [settingsDict setValue:amellieChannel forKey:@"channel"];
    [settingsDict setValue:modeString forKey:@"run_mode"];
    [settingsDict setValue:[NSNumber numberWithInteger:photons] forKey:@"photons"];
    [settingsDict setValue:pulseWidth forKey:@"pulse_width"];
    [settingsDict setValue:[NSNumber numberWithFloat:pulseSeparation] forKey:@"pulse_separation"];
    [settingsDict setValue:[NSNumber numberWithInteger:pulses] forKey:@"number_of_shots"];
    [settingsDict setValue:[NSNumber numberWithInteger:delay] forKey:@"trigger_delay"];
    [settingsDict setValue:[NSNumber numberWithFloat:[fibre_delay floatValue]] forKey:@"fibre_delay"];
    [settingsDict setValue:[NSNumber numberWithInteger:16383] forKey:@"pulse_height"];
    return settingsDict;
}



-(void)startTellieRunThread:(NSDictionary*)fireCommands forTELLIE:(BOOL)forTELLIE
{
    /*
     Launch a thread to host the tellie run functionality.
    */
    //////////////////////
    // Make invocation so we can pass multiple args into thread
    NSMethodSignature *signature = [self methodSignatureForSelector:@selector(startTellieRun: forTELLIE:)];
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:self];
    [invocation setSelector:@selector(startTellieRun: forTELLIE:)];
    [invocation setArgument:&fireCommands atIndex:2];
    [invocation setArgument:&forTELLIE atIndex:3];
    [invocation retainArguments];

    //////////////////////
    // Start tellie thread
    [self setTellieThread:[[NSThread alloc] initWithTarget:invocation selector:@selector(invoke) object:nil]];
    [[self tellieThread] start];
}

-(void)startTellieMultiRunThread:(NSArray*)fireCommandArray forTELLIE:(BOOL)forTELLIE
{
    /*
     Launch a thread to host the tellie multi run functionality.
     */

    //////////////////////
    // Make invocation so we can pass multiple args into thread
    NSMethodSignature *signature = [self methodSignatureForSelector:@selector(startTellieMultiRun: forTELLIE:)];
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:self];
    [invocation setSelector:@selector(startTellieMultiRun: forTELLIE:)];
    [invocation setArgument:&fireCommandArray atIndex:2];
    [invocation setArgument:&forTELLIE atIndex:3];
    [invocation retainArguments];

    //////////////////////
    // Start tellie thread
    [self setTellieThread:[[NSThread alloc] initWithTarget:invocation selector:@selector(invoke) object:nil]];
    [[self tellieThread] start];
}

-(void) startTellieMultiRun:(NSArray*)fireCommandArray forTELLIE:(BOOL)forTELLIE
{
    /*
     Fire light down one or more fibres using fireCommands given in the passed array.
     Calls startTellieRun on each element in the array.

     Arguments:
     NSMutableDictionary fireCommandArray :     An a array of dictionaries containing
                                                hardware settings to be passed to the
                                                tellie hardware.
     */
    //////////////////////////////
    // Set a flag so startTellieRun
    // knows not to finish the run
    // on completion.
    [self setTellieMultiFlag:YES];

    //////////////////////////////
    // Loop over all objects in
    // passed array
    int counter = 0;
    NSUInteger nloops = [fireCommandArray count];
    for(NSDictionary* fireCommands in fireCommandArray){
        if([[NSThread currentThread] isCancelled]){
            goto err;
        }
        // Check if we're at the end of a sequence. If we are, set the multiFlag to NO.
        // This will mean all shutdown stuff will be performed at the end of flashing.
        counter = counter + 1;
        if(counter == nloops){
            [self setTellieMultiFlag:NO];
        }
        [self startTellieRun:fireCommands forTELLIE:forTELLIE];
    }

err:
{
    ////////////////////////////
    // Reset flag and tidy
    [self setTellieMultiFlag:NO];

    ////////////
    // If thread errored we need to post a note to
    // call the formal stop proceedure. If the thread
    // was canelled we must already be in a 'stop'
    // button push, so don't need to post.
    if(![[NSThread currentThread] isCancelled]){
        dispatch_sync(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:ORTELLIERunFinishedNotification object:self];
        });
    }
    [[NSThread currentThread] cancel];
}
}

-(void) startTellieRun:(NSDictionary *)fireCommands
{
    [self startTellieRun:fireCommands forTELLIE:YES];
}

-(void) startTellieRun:(NSDictionary*)fireCommands forTELLIE:(BOOL)forTELLIE
{
    /*
     Fire a tellie using hardware settings passed as dictionary. This function
     calls a python script on the DAQ1 machine, passing it command line arguments relating
     to specific tellie channel settings. The called python script relays the commands 
     to the tellie hardware using a XMLRPC server which must be lanuched manually via the
     command line prior to launching ORCA.
     
     Arguments: 
        NSMutableDictionary fireCommands :  A dictionary containing hardware settings to
                                            be relayed to the tellie hardware.
     
    */
    ///////////
    //Set tellieFiring flag
    [self setEllieFireFlag:YES];

    //////////
    /// This will likely be run in a thread so set-up an auto release pool
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    ///////////
    // Make a sting accessable inside err; incase of error.
    NSString* errorString;
    NSString* prefix = @"[TELLIE]";
    if(!forTELLIE){
        prefix = @"[AMELLIE]";
    }
    //////////////
    //Get a Tubii object
    NSArray*  tubiiModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"TUBiiModel")];
    if(![tubiiModels count]){
        NSLogColor([NSColor redColor], @"%@: Couldn't find Tubii model.\n",prefix);
        goto err;
    }
    TUBiiModel* theTubiiModel = [tubiiModels objectAtIndex:0];

    ///////////////
    //Add run control object
    NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSLogColor([NSColor redColor], @"%@: Couldn't find ORRunModel please add one to the experiment\n",prefix);
        goto err;
    }
    ORRunModel* runControl = [runModels objectAtIndex:0];
    
    ///////////////
    //Add SNOPModel object
    NSArray*  snopModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    if(![snopModels count]){
        NSLogColor([NSColor redColor], @"%@: Couldn't find SNOPModel\n",prefix);
        goto err;
    }
    SNOPModel* snopModel = [snopModels objectAtIndex:0];

    ///////////////////////
    // Check TELLIE run type is masked in
    if(forTELLIE){
        if(!([snopModel lastRunTypeWord] & kTELLIERun)){
            NSLogColor([NSColor redColor], @"%@: TELLIE bit is not masked into the run type word.\n",prefix);
            NSLogColor([NSColor redColor], @"[TELLIE]: Please load the TELLIE standard run type.\n");
            goto err;
        }
    } else {
        if(!([snopModel lastRunTypeWord] & kAMELLIERun)){
            NSLogColor([NSColor redColor], @"%@: AMELLIE bit is not masked into the run type word.\n",prefix);
            NSLogColor([NSColor redColor], @"%@: Please load the TELLIE standard run type.\n",prefix);
            goto err;
        }
    }

    ////////////////////////
    // Check keep alive is running.
    if(![[theTubiiModel keepAliveThread] isExecuting]){
        NSLog(@"The keep alive thread between ORCA and TUBii was inactive. Relaunching.\n");
        [theTubiiModel activateKeepAlive];
    }

    ///////////////////////
    // Check trigger is being sent to asyncronus port of the MTC/D (EXT_A)
    NSUInteger asyncTrigMask;
    @try{
        asyncTrigMask = [theTubiiModel asyncTrigMask];
    } @catch(NSException* e) {
        NSLogColor([NSColor redColor], @"%@: Error requesting asyncTrigMask from Tubii.\n",prefix);
        goto err;
    }

    //////////////
    // Get run mode boolean
    BOOL isSlave = YES;
    if([[fireCommands objectForKey:@"run_mode"] isEqualToString:@"Master"]){
        isSlave = NO;
    }

    //////////////
    // TUBii has two possible slave mode configurations.
    // 0 [@NO]:  Master mode : Trigger path = TELLIE->TUBii->MTC/D
    // 1 [@YES]: Slave mode  : Trigger path = TUBii->TELLIE
    //                                        TUBii->MTC/D
    //
    // In master mode TELLIE generates internal triggers which then get piped down a 20m cable to TUBii.
    //
    // In slave mode TUBii first sends a trigger to TELLIE, then independently, after some delay, sends
    // a trigger onto the MTC/D in anticipation that the TELLIE trigger would have been properly received.
    //
    // These two modalities require significantly different trigger delays to be set in order to centre
    // TELLIE light in the event window.

    @try{
        [theTubiiModel setTellieMode:isSlave];
    } @catch(NSException* e){
        NSLogColor([NSColor redColor], @"[TELLIE]: Problem setting correct master/ slave mode behaviour at TUBii, reason: %@\n", [e reason]);
        goto err;
    }

    /////////////
    // Final settings check
    NSNumber* photonOutput = [self calcPhotonsForIPW:[[fireCommands objectForKey:@"pulse_width"] integerValue] forChannel:[[fireCommands objectForKey:@"channel"] integerValue] inSlave:isSlave];
    float rate = 1000.*(1./[[fireCommands objectForKey:@"pulse_separation"] floatValue]);
    NSLog(@"---------------------------Single Fibre Settings Summary-------------------------\n");
    NSLog(@"%@: Fibre: %@\n", prefix, [fireCommands objectForKey:@"fibre"]);
    NSLog(@"%@: Channel: %i\n", prefix, [[fireCommands objectForKey:@"channel"] intValue]);
    if (isSlave){
        NSLog(@"%@: Mode: slave\n", prefix);
    } else {
        NSLog(@"%@: Mode: master\n", prefix);
    }
    NSLog(@"%@: IPW: %d\n", prefix, [[fireCommands objectForKey:@"pulse_width"] integerValue]);
    NSLog(@"%@: Trigger delay: %1.1f ns\n", prefix, [[fireCommands objectForKey:@"trigger_delay"] floatValue]);
    NSLog(@"%@: Fibre delay: %1.2f ns\n", prefix, [[fireCommands objectForKey:@"fibre_delay"] floatValue]);
    NSLog(@"%@: No. triggers %d\n", prefix, [[fireCommands objectForKey:@"number_of_shots"] integerValue]);
    NSLog(@"%@: Rate %1.1f Hz\n", prefix, rate);
    NSLog(@"%@: Expected photon output: %i photons / pulse\n", prefix, [photonOutput integerValue]);
    NSLog(@"------------\n");
    NSLog(@"%@: Estimated excecution time %1.1f mins\n", prefix, (([[fireCommands objectForKey:@"number_of_shots"] integerValue] / rate) + 10) / 60.);
    NSLog(@"---------------------------------------------------------------------------------------------\n");

    BOOL safety_check = [self photonIntensityCheck:[photonOutput integerValue] atFrequency:rate];
    if(safety_check == NO){
        NSLogColor([NSColor redColor], @"%@: The requested number of photons (%u), is not detector safe at %f Hz. This setting will not be run.\n",  prefix, [photonOutput integerValue], rate);
        goto err;
    }

    /////////////
    // TELLIE pin readout is an average measurement of the passed "number_of_shots".
    // If a large number of shots are requested it is useful to split the data into smaller chunks,
    // this way we get multiple pin readings.
    NSNumber* loops = [NSNumber numberWithInteger:1];
    int totalShots = (int)[[fireCommands objectForKey:@"number_of_shots"] integerValue];
    float fRemainder = fmod(totalShots, 5e3);
    if( totalShots > 5e3){
        if (fRemainder > 0){
            int iLoops = (totalShots - fRemainder) / 5e3;
            loops = [NSNumber numberWithInteger:(iLoops+1)];
        } else {
            int iLoops = totalShots / 5e3;
            loops =[NSNumber numberWithInteger:iLoops];
        }
    }

    ///////////////
    // Now set-up is done, push initial run document
    if([runControl isRunning]){
        @try{
            if(forTELLIE){
                [self pushInitialTellieRunDocument];
            } else {
                [self pushInitialAmellieRunDocument];
            }
        }@catch(NSException* e){
            NSLogColor([NSColor redColor],@"%@: Problem pushing initial run description document: %@\n", prefix, [e reason]);
            goto err;
        }
    }

    dispatch_sync(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ORELLIEFlashing object:self];
    });

    ///////////////
    // Fire loop! Pass variables to the tellie server.
    for(int i = 0; i<[loops integerValue]; i++){
        if(![self ellieFireFlag] || [[NSThread currentThread] isCancelled]){
            //errorString = @"ELLIE fire flag set to @NO";
            goto err;
        }

        /////////////////
        // Calculate how many shots to fire in this loop
        NSNumber* noShots = [NSNumber numberWithInt:5e3];
        if(i == ([loops integerValue]-1) && fRemainder > 0){
            noShots = [NSNumber numberWithInt:fRemainder];
        }
        
        //////////////////////
        // Set loop independent tellie channel settings
        if(i == 0){

            ////////
            // Send stop command to ensure buffer is clear
            @try{
                [[self tellieClient] command:@"stop"];
            } @catch(NSException* e){
                // This should only ever be called from the main thread so can raise
                NSLogColor([NSColor redColor], @"%@: Problem with tellie server interpreting stop command!\n", prefix);
            }
            
            ////////
            // Init channel using fireCommands
            NSArray* fireArgs = @[[[fireCommands objectForKey:@"channel"] stringValue],
                                  [noShots stringValue],
                                  [[fireCommands objectForKey:@"pulse_separation"] stringValue],
                                  [NSNumber numberWithInt:0], // Trigger delay now handled by TUBii
                                  [[fireCommands objectForKey:@"pulse_width"] stringValue],
                                  [[fireCommands objectForKey:@"pulse_height"] stringValue],
                                  [[fireCommands objectForKey:@"fibre_delay"] stringValue],
                                  ];
            
            NSLog(@"%@: Init-ing tellie with settings\n", prefix);
            @try{
                [[self tellieClient] command:@"init_channel" withArgs:fireArgs];
            } @catch(NSException *e){
                errorString = [NSString stringWithFormat:@"%@: Problem init-ing channel on server: %@\n", prefix, [e reason]];
                NSLogColor([NSColor redColor], errorString);
                goto err;
            }

            @try{
                [theTubiiModel setTellieDelay:[[fireCommands objectForKey:@"trigger_delay"] intValue]];
            } @catch(NSException* e) {
                errorString = [NSString stringWithFormat:@"%@: Problem setting trigger delay at TUBii: %@\n", prefix, [e reason]];
                NSLogColor([NSColor redColor], errorString);
                goto err;
            }
        }
        
        ////////////////////
        // Init can take a while. Make sure no-one hit
        // a stop button
        if([[NSThread currentThread] isCancelled]){
            goto err;
        }
        
        /////////////////////
        // Set loop dependent tellie channel settings
        @try{
            [[self tellieClient] command:@"set_pulse_number" withArgs:@[noShots]];
        } @catch(NSException* e) {
            errorString = [NSString stringWithFormat:@"%@: Problem setting pulse number: %@\n", prefix, [e reason]];
            NSLogColor([NSColor redColor], errorString);
            goto err;
        }
        
        ///////////////
        // Make a temporary directoy to add sub_run fields being run in this loop
        NSMutableDictionary* valuesToFillPerSubRun = [NSMutableDictionary dictionaryWithCapacity:100];
        [valuesToFillPerSubRun setDictionary:fireCommands];
        [valuesToFillPerSubRun setObject:noShots forKey:@"number_of_shots"];
        [valuesToFillPerSubRun setObject:photonOutput forKey:@"photons"];
        
        NSLog(@"%@: Firing fibre %@: %d pulses, %1.0f Hz\n", prefix, [fireCommands objectForKey:@"fibre"], [noShots integerValue], rate);
        
        ///////////////
        // Handle master / slave mode firing
        //////////////
        // SLAVE MODE
        if([[fireCommands objectForKey:@"run_mode"] isEqualToString:@"Slave"]){
            ///////////
            // Tell tellie to accept a sequence of external triggers
            @try{
                [[self tellieClient] command:@"trigger_averaged"];
            } @catch(NSException* e) {
                errorString = [NSString stringWithFormat:@"%@ Problem setting pulse number on server: %@\n", prefix, [e reason]];
                NSLogColor([NSColor redColor], errorString);
                goto err;
            }

            ////////////
            // Set the tubii model aand ask it to fire
            @try{
                [theTubiiModel fireTelliePulser_rate:rate pulseWidth:100 NPulses:[noShots intValue]];
            } @catch(NSException* e){
                errorString = [NSString stringWithFormat:@"%@: Problem setting TUBii parameters: %@\n", prefix, [e reason]];
                NSLogColor([NSColor redColor], errorString);
                goto err;
            }

        //////////////
        // MASTER MODE
        } else {
            /////////////
            // Tell tellie to fire a master mode sequence
            @try{
                [[self tellieClient] command:@"fire_sequence"];
            } @catch(NSException* e){
                errorString = [NSString stringWithFormat: @"%@: Problem requesting tellie master to fire: %@\n", prefix, [e reason]];
                NSLogColor([NSColor redColor],errorString);
                goto err;
            }
        }

        //////////////////
        // Before we poll, check thread is still alive.
        // polling can take a while so worth doing here first.
        if([[NSThread currentThread] isCancelled]){
            goto err;
        }
        //////////////////
        // Poll tellie for a pin reading. Give the sequence a 3s grace period to finish
        // int32_t for some reason
        float pollTimeOut = (1./rate)*[noShots floatValue] + 3.;
        NSArray* pinReading = nil;
        @try{
            pinReading = [self pollTellieFibre:pollTimeOut];
        } @catch(NSException* e){
            errorString = [NSString stringWithFormat:@"%@: Problem polling for pin: %@\n", prefix, [e reason]];
            NSLogColor([NSColor redColor], errorString);
            goto err;
        }
        NSLog(@"%@: Pin response received %i +/- %1.1f\n", prefix, [[pinReading objectAtIndex:0] integerValue], [[pinReading objectAtIndex:1] floatValue]);
        @try {
            [valuesToFillPerSubRun setObject:[pinReading objectAtIndex:0] forKey:@"pin_value"];
            [valuesToFillPerSubRun setObject:[pinReading objectAtIndex:1] forKey:@"pin_rms"];
        } @catch (NSException *e) {
            errorString = [NSString stringWithFormat:@"%@: Unable to add pin readout to sub_run file due to error: %@\n", prefix, [e reason]];
            NSLogColor([NSColor redColor], errorString);
            goto err;
        }
        
        ////////////
        // Update run document
        if([runControl isRunning]){
            @try{
                if(forTELLIE){
                    [self updateTellieRunDocument:valuesToFillPerSubRun];
                } else {
                    [self updateAmellieRunDocument:valuesToFillPerSubRun];
                }
            } @catch(NSException* e){
                NSLogColor([NSColor redColor],@"%@: Problem updating run description document: %@\n", prefix, [e reason]);
                goto err;
            }

            //////////////////
            // Start a new subrun
            [runControl performSelectorOnMainThread:@selector(prepareForNewSubRun) withObject:nil waitUntilDone:YES];
            [runControl performSelectorOnMainThread:@selector(startNewSubRun) withObject:nil waitUntilDone:YES];
        }
    }

    // Set fire flag
    [self setEllieFireFlag:NO];

    NSLog(@"%@: TELLIE fire sequence completed\n", prefix);

    ////////////
    // Make sure hardware is put back into safe state
    if(![self tellieMultiFlag]){

        // TELLIE
        @try{
            NSString* responseFromTellie = [[self tellieClient] command:@"stop"];
            NSLog(@"%@: Sent stop command to hardware, received: %@\n",prefix, responseFromTellie);
        } @catch(NSException* e){
            // This should only ever be called from the main thread so can raise
            NSLogColor([NSColor redColor], @"%@: Problem with tellie server interpreting stop command!\n", prefix);
        }

        // TUBii
        @try{
            [theTubiiModel stopTelliePulser];
        } @catch(NSException* e) {
            NSLogColor([NSColor redColor], @"%@: Problem stopping TUBii pulser!\n", prefix);
        }

        dispatch_sync(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:ORTELLIERunFinishedNotification object:self];
        });
        [[NSThread currentThread] cancel];
    }

    [pool release];

    return;

err:
    {
        [self setEllieFireFlag:NO];
        [self setTellieMultiFlag:NO];

        //Resetting the mtcd to settings before the smellie run
        NSLog(@"%@: Killing requested flash sequence\n", prefix);

        // TELLIE
        @try{
            NSString* responseFromTellie = [[self tellieClient] command:@"stop"];
            NSLog(@"%@: Sent stop command to hardware, received: %@\n",prefix, responseFromTellie);
        } @catch(NSException* e){
            // This should only ever be called from the main thread so can raise
            NSLogColor([NSColor redColor], @"%@: Problem with tellie server interpreting stop command!\n", prefix);
        }

        // TUBii
        @try{
            [theTubiiModel stopTelliePulser];
        } @catch(NSException* e) {
            NSLogColor([NSColor redColor], @"%@: Problem stopping TUBii pulser!\n", prefix);
        }

        ////////////
        // Post a note saying we've jumped out of the run sequence
        if(![[NSThread currentThread] isCancelled]){
            dispatch_sync(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:ORTELLIERunFinishedNotification object:self];
            });
        }
        [[NSThread currentThread] cancel];
        [pool release];
    }
}

-(void)stopTellieRun
{
    /*
     Before we perform any tidy-up actions, we want to make sure the run thread has stopped
     executing. If the run has not been ended using the tellie specific 'stop fibre' button,
     but instead the user has simply hit the main run stop button on the SNOPController, we
     need to make sure TELLIE has properly cleaned up before we roll into a new run.
     Fortunately there is a handy wait notification that gets picked up by the run control.

     Here we post the run wait notification and launch a thread that waits for the tellieThread
     to stop executing before tidying up and, finally, releasing the run wait.
     */

    [[self tellieThread] cancel];

    // Post a notification telling the run control to wait until the thread finishes
    NSDictionary* userInfo  = [NSDictionary dictionaryWithObjectsAndKeys:@"waiting for T/AMELLIE run to finish", @"Reason", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAddRunStateChangeWait object:self userInfo:userInfo];

    //////////////////////
    // Set fire flag to no. If a run sequence is currently underway, this will stop
    [self setEllieFireFlag:NO];
    [self setTellieMultiFlag:NO];

    if([[self tellieThread] isExecuting]){

        [[self tellieThread] cancel];

        ///////////////////////////////////////
        // If a run transition thread isn't yet running, run one.
        // Doing it this way avoids multiple transition behaviours.
        if(![_tellieTransitionThread isExecuting]){
            NSLog(@"[T/AMELLIE]: Waiting for T/AMELLIE server to release blocking trigger function...\n");
            [self setTellieTransitionThread:[[NSThread alloc] initWithTarget:self selector:@selector(tellieRunTransition) object:nil]];
            [[self tellieTransitionThread] start];
        } else {
            // Release the wait request posted at the start of this function - one is already queued.
            [[NSNotificationCenter defaultCenter] postNotificationName:ORReleaseRunStateChangeWait object:self];
        }
    } else {
        // Tell run control it can stop waiting
        [[NSNotificationCenter defaultCenter] postNotificationName:ORReleaseRunStateChangeWait object:self];
    }
  }

-(void)tellieRunTransition
{
    /////////////
    // This will run in a thread so add release pool
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    ///////////////////////////////////////////
    // Wait for thread to stop
    while ([[self tellieThread] isExecuting]) {
        [NSThread sleepForTimeInterval:0.1];
    }

    // Only roll over if this is NOT a tuning run.
    if(![[self tuningRun] boolValue]){
        ///////////////
        //Add run control object
        NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
        if(![runModels count]){
            NSLogColor([NSColor redColor], @"[T/AMELLIE]: Couldn't find ORRunModel please add one to the experiment\n");
            goto err;
        }
        ORRunModel* runControl = [runModels objectAtIndex:0];
        // Roll over the run.
        [runControl performSelectorOnMainThread:@selector(restartRun) withObject:nil waitUntilDone:YES];
    }

err:{
    // Tell run control it can stop the run.
    dispatch_sync(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ORReleaseRunStateChangeWait object:self];
    });

    NSLog(@"[T/AMELLIE]: End of ELLIE sequence\n");
    [pool release];
}
}

/*****************************/
/*   tellie db interactions  */
/*****************************/
-(void) pushInitialTellieRunDocument
{
    /*
     Create a standard tellie run doc using ELLIEModel / SNOPModel / ORRunModel class
     variables and push up to the telliedb. Additionally, the run doc dictionary set as
     the tellieRunDoc propery, to be updated later in the run.
     */
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSMutableDictionary* runDocDict = [NSMutableDictionary dictionaryWithCapacity:10];
    
    NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSLogColor([NSColor redColor], @"[TELLIE_UPLOAD]: Couldn't find ORRunModel\n");
        return;
    }
    ORRunModel* runControl = [runModels objectAtIndex:0];

    NSString* docType = [NSMutableString stringWithFormat:@"TELLIE_RUN"];
    NSMutableArray* subRunArray = [NSMutableArray arrayWithCapacity:10];

    [runDocDict setObject:docType forKey:@"type"];
    [runDocDict setObject:[NSString stringWithFormat:@"%i",0] forKey:@"version"];
    [runDocDict setObject:[NSString stringWithFormat:@""] forKey:@"index"];
    [runDocDict setObject:[self stringDateFromDate:nil] forKey:@"timestamp"];
    [runDocDict setObject:[NSMutableArray arrayWithObjects:
                            [NSNumber numberWithUnsignedLong:[runControl runNumber]],
                            [NSNumber numberWithUnsignedLong:[runControl runNumber]], nil]
                            forKey:@"run_range"];
    [runDocDict setObject:subRunArray forKey:@"sub_run_info"];

    [self setTellieRunDoc:runDocDict];
    [[self couchDBRef:self withDB:@"telliedb"] addDocument:runDocDict tag:kTellieRunDocumentAdded];
    [pool release];
}

- (void) updateTellieRunDocument:(NSDictionary*)subRunDoc
{
    /*
     Update [self tellieRunDoc] with subrun information.
     
     Arguments:
     NSDictionary* subRunDoc:  Subrun information to be added to the current [self tellieRunDoc].
     */
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    // Get run control
    NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSLogColor([NSColor redColor], @"[TELLIE_UPLOAD]: Couldn't find ORRunModel\n");
        return;
    }
    ORRunModel* runControl = [runModels objectAtIndex:0];
    
    NSMutableDictionary* runDocDict = [[self tellieRunDoc] mutableCopy];
    NSMutableDictionary* subRunDocDict = [subRunDoc mutableCopy];

    [subRunDocDict setObject:[NSNumber numberWithInt:[runControl subRunNumber]] forKey:@"sub_run_number"];

    NSMutableArray * subRunInfo = [[runDocDict objectForKey:@"sub_run_info"] mutableCopy];
    [subRunInfo addObject:subRunDocDict];
    [runDocDict setObject:subRunInfo forKey:@"sub_run_info"];

    //Update tellieRunDoc property.
    [self setTellieRunDoc:runDocDict];

    //check to see if run is offline or not
    if([[ORGlobal sharedGlobal] runMode] == kNormalRun){
        [[self couchDBRef:self withDB:@"telliedb"]
         updateDocument:runDocDict
         documentId:[runDocDict objectForKey:@"_id"]
         tag:kTellieRunDocumentUpdated];
    }

    [runDocDict release];
    [subRunDocDict release];
    [subRunInfo release];
    [pool release];
}

-(void) loadTELLIEStaticsFromDB
{
    /*
     Load current tellie channel calibration and patch map settings from telliedb.
     This function accesses the telliedb and pulls down the most recent fireParameters,
     fibreMapping and nodeMapping documents. The data is then saved to the member variables
     tellieFireParameters, tellieFibreMapping and tellieNodeMapping.
     */
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    //Set all to be nil
    [self setTellieFireParameters:nil];
    [self setTellieFibreMapping:nil];
    [self setTellieNodeMapping:nil];

    NSString* parsString = [NSString stringWithFormat:@"_design/tellieQuery/_view/fetchFireParameters?descending=False&limit=1"];
    NSString* mapString = [NSString stringWithFormat:@"_design/tellieQuery/_view/fetchCurrentMapping?key=2147483647"];
    NSString* nodeString = [NSString stringWithFormat:@"_design/mapping/_view/node_to_fibre?descending=True&limit=1"];

    // Make requests
    [[self couchDBRef:self withDB:@"telliedb"] getDocumentId:parsString tag:kTellieParsRetrieved];
    [[self couchDBRef:self withDB:@"telliedb"] getDocumentId:mapString tag:kTellieMapRetrieved];
    [[self couchDBRef:self withDB:@"telliedb"] getDocumentId:nodeString tag:kTellieNodeRetrieved];
    [self loadTELLIERunPlansFromDB];
    [pool release];
}

-(void) loadTELLIERunPlansFromDB
{
    [self setTellieRunNames:nil];
    NSString* runPlansString = [NSString stringWithFormat:@"_design/runs/_view/run_plans"];
    [[self couchDBRef:self withDB:@"telliedb"] getDocumentId:runPlansString tag:kTellieRunPlansRetrieved];
}

-(void)parseTellieFirePars:(id)aResult
{
    NSMutableDictionary* fireParametersDoc =[[[aResult objectForKey:@"rows"]  objectAtIndex:0] objectForKey:@"value"];
    NSLog(@"[TELLIE_DATABASE]: channel calibrations sucessfully loaded\n");
    [self setTellieFireParameters:fireParametersDoc];
}

-(void)parseTellieFibreMap:(id)aResult
{
    NSMutableDictionary* mappingDoc =[[[aResult objectForKey:@"rows"]  objectAtIndex:0] objectForKey:@"value"];
    NSLog(@"[TELLIE_DATABASE]: mapping document sucessfully loaded\n");
    [self setTellieFibreMapping:mappingDoc];
}

-(void)parseTellieNodeMap:(id)aResult
{
    NSMutableDictionary* nodeDoc =[[[aResult objectForKey:@"rows"]  objectAtIndex:0] objectForKey:@"value"];
    NSLog(@"[TELLIE_DATABASE]: node mapping document sucessfully loaded\n");
    [self setTellieNodeMapping:nodeDoc];
}

-(void)parseTellieRunPlans:(id)aResult
{
    NSArray* rows = [aResult objectForKey:@"rows"];
    NSMutableArray* names = [NSMutableArray arrayWithCapacity:[rows count]];
    for(NSDictionary* row in rows){
        [names addObject:[[row objectForKey:@"value"] objectForKey:@"name"]];
    }
    NSLog(@"[TELLIE_DATABASE]: run plan lables sucessfully loaded\n");
    [self setTellieRunNames:names];
}

/*****************************/
/*   amellie db interactions  */
/*****************************/
-(void) pushInitialAmellieRunDocument
{
    /*
     Create a standard tellie run doc using ELLIEModel / SNOPModel / ORRunModel class
     variables and push up to the telliedb. Additionally, the run doc dictionary set as
     the tellieRunDoc propery, to be updated later in the run.
     */
    NSMutableDictionary* runDocDict = [NSMutableDictionary dictionaryWithCapacity:10];

    NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSLogColor([NSColor redColor], @"[AMELLIE_UPLOAD]: Couldn't find ORRunModel\n");
        return;
    }
    ORRunModel* runControl = [runModels objectAtIndex:0];

    NSString* docType = [NSMutableString stringWithFormat:@"AMELLIE_RUN"];
    NSMutableArray* subRunArray = [NSMutableArray arrayWithCapacity:10];

    [runDocDict setObject:docType forKey:@"type"];
    [runDocDict setObject:[NSString stringWithFormat:@"%i",0] forKey:@"version"];
    [runDocDict setObject:[NSString stringWithFormat:@""] forKey:@"index"];
    [runDocDict setObject:[self stringDateFromDate:nil] forKey:@"timestamp"];
    [runDocDict setObject:[NSMutableArray arrayWithObjects:
                           [NSNumber numberWithUnsignedLong:[runControl runNumber]],
                           [NSNumber numberWithUnsignedLong:[runControl runNumber]], nil]
                   forKey:@"run_range"];
    [runDocDict setObject:subRunArray forKey:@"sub_run_info"];

    [self setAmellieRunDoc:runDocDict];
    [[self couchDBRef:self withDB:@"amellie"] addDocument:runDocDict tag:kAmellieRunDocumentAdded];
}

- (void) updateAmellieRunDocument:(NSDictionary*)subRunDoc
{
    /*
     Update [self amellieRunDoc] with subrun information.

     Arguments:
     NSDictionary* subRunDoc:  Subrun information to be added to the current [self tellieRunDoc].
     */

    // Get run control
    NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSLogColor([NSColor redColor], @"[AMELLIE_UPLOAD]: Couldn't find ORRunModel\n");
        return;
    }
    ORRunModel* runControl = [runModels objectAtIndex:0];

    NSMutableDictionary* runDocDict = [[self amellieRunDoc] mutableCopy];
    NSMutableDictionary* subRunDocDict = [subRunDoc mutableCopy];

    [subRunDocDict setObject:[NSNumber numberWithInt:[runControl subRunNumber]] forKey:@"sub_run_number"];

    NSMutableArray * subRunInfo = [[runDocDict objectForKey:@"sub_run_info"] mutableCopy];
    [subRunInfo addObject:subRunDocDict];
    [runDocDict setObject:subRunInfo forKey:@"sub_run_info"];

    //Update tellieRunDoc property.
    [self setAmellieRunDoc:runDocDict];

    //check to see if run is offline or not
    if([[ORGlobal sharedGlobal] runMode] == kNormalRun){
        [[self couchDBRef:self withDB:@"amellie"]
         updateDocument:runDocDict
         documentId:[runDocDict objectForKey:@"_id"]
         tag:kAmellieRunDocumentUpdated];
    }
    [subRunInfo release];
    [runDocDict release];
    [subRunDocDict release];
}

-(void) loadAMELLIEStaticsFromDB
{
    /*
     Load current Amellie channel calibration and patch map settings from couch.
     This function accesses the telliedb and pulls down the most recent fireParameters
     and fibreMapping documents. The data is then saved to the member variables
     amellieFireParameters and amellieFibreMapping.
     */

    //Set all to be nil
    [self setAmellieFireParameters:nil];
    [self setAmellieFibreMapping:nil];

    NSString* fibreString = [NSString stringWithFormat:@"_design/orcaQueries/_view/fetchFibreMapping?key=2147483647"];
    NSString* nodeString = [NSString stringWithFormat:@"_design/orcaQueries/_view/fetchNodeMapping?key=2147483647"];

    // Make requests
    [[self couchDBRef:self withDB:@"amellie"] getDocumentId:fibreString tag:kAmellieFibresRetrieved];
    [[self couchDBRef:self withDB:@"amellie"] getDocumentId:nodeString tag:kAmellieNodesRetrieved];
}

-(void)parseAmellieFirePars:(id)aResult
{
    NSMutableDictionary* fireParametersDoc =[[[aResult objectForKey:@"rows"]  objectAtIndex:0] objectForKey:@"value"];
    NSLog(@"[AMELLIE_DATABASE]: channel calibrations sucessfully loaded\n");
    [self setAmellieFireParameters:fireParametersDoc];
}

-(void)parseAmellieFibreMap:(id)aResult
{
    NSMutableDictionary* mappingDoc =[[[aResult objectForKey:@"rows"]  objectAtIndex:0] objectForKey:@"value"];
    NSLog(@"[AMELLIE_DATABASE]: mapping document sucessfully loaded\n");
    [self setAmellieFibreMapping:mappingDoc];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ORAMELLIEMappingReceived object:self];
    });
}

-(void)parseAmellieNodeMap:(id)aResult
{
    NSMutableDictionary* mappingDoc =[[[aResult objectForKey:@"rows"]  objectAtIndex:0] objectForKey:@"value"];
    NSLog(@"[AMELLIE_DATABASE]: mapping document sucessfully loaded\n");
    [self setAmellieNodeMapping:mappingDoc];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ORAMELLIEMappingReceived object:self];
    });
}

/*********************************************************/
/*                  Smellie Functions                    */
/*********************************************************/
-(void) setSmellieNewRun:(NSNumber *)runNumber{
    NSArray* args = @[runNumber];
    id result = [[self smellieClient] command:@"new_run" withArgs:args];
    if([result isKindOfClass:[NSString class]]){
        NSException* e = [NSException
                          exceptionWithName:@"SMELLIE EXCEPTION"
                          reason:result
                          userInfo:nil];
        [e raise];
    }
}

-(void) deactivateSmellieLasers
{
    id result = [[self smellieFlaggingClient] command:@"deactivate"];
    if([result isKindOfClass:[NSString class]]){
        NSException* e = [NSException
                          exceptionWithName:@"SMELLIE EXCEPTION"
                          reason:result
                          userInfo:nil];
        [e raise];
    }
    NSLog(@"[SMELLIE]: Lasers deactivated\n");
}

-(void) CancelSmellieTriggers
{
    id result = [[self smellieFlaggingClient] command:@"set_run_flag_false"];
    if([result isKindOfClass:[NSString class]]){
        NSException* e = [NSException
                          exceptionWithName:@"SMELLIE EXCEPTION"
                          reason:result
                          userInfo:nil];
        [e raise];
    }
}

-(void)setSmellieLaserHeadMasterMode:(NSNumber*)laserSwitchChan withIntensity:(NSNumber*)intensity withRepRate:(NSNumber*)rate withFibreInput:(NSNumber*)fibreInChan withFibreOutput:(NSNumber*)fibreOutChan withNPulses:(NSNumber*)noPulses withGainVoltage:(NSNumber *)gain
{
    /*
    Run the SMELLIE system in Master Mode (NI Unit provides the trigger signal for both the lasers and the detector) using the PicoQuant Laser Heads
    
    :param ls_chan: the laser switch channel
    :param intensity: the laser intensity in per mil
    :param rep_rate: the repition rate of requested laser sequence
    :param fs_input_channel: the fibre switch input channel
    :param fs_output_channel: the fibre switch output channel
    :param n_pulses: the number of pulses
    :param gain: the gain setting to be applied at the MPU
    */
    NSArray* args = @[laserSwitchChan, intensity, rate, fibreInChan, fibreOutChan, noPulses, gain];
    id result = [[self smellieClient] command:@"laserheads_master_mode" withArgs:args];
    if([result isKindOfClass:[NSString class]]){
        NSException* e = [NSException
                          exceptionWithName:@"SMELLIE EXCEPTION"
                          reason:result
                          userInfo:nil];
        [e raise];
    }
}

-(void)setSmellieLaserHeadSlaveMode:(NSNumber*)laserSwitchChan withIntensity:(NSNumber*)intensity withFibreInput:(NSNumber*)fibreInChan withFibreOutput:(NSNumber*)fibreOutChan withTime:(NSNumber*)time withGainVoltage:(NSNumber*)gain
{
    /*
    Run the SMELLIE system in Slave Mode (SNO+ MTC/D provides the trigger signal for both the lasers and the detector) using the PicoQuant Laser Heads

    :param ls_chan: the laser switch channel
    :param intensity: the laser intensity in per mil
    :param fs_input_channel: the fibre switch input channel
    :param fs_output_channel: the fibre switch output channel
    :param n_pulses: the number of pulses
    :param time: time until SNODROP exits slave mode
    :param gain: the gain setting to be applied at the MPU
    */
    NSArray* args = @[laserSwitchChan, intensity, fibreInChan, fibreOutChan, time, gain];
    id result = [[self smellieClient] command:@"laserheads_slave_mode" withArgs:args];
    if([result isKindOfClass:[NSString class]]){
        NSException* e = [NSException
                          exceptionWithName:@"SMELLIE EXCEPTION"
                          reason:result
                          userInfo:nil];
        [e raise];
    }
}

-(void)setSmellieSuperkMasterMode:(NSNumber*)intensity withRepRate:(NSNumber*)rate withWavelengthLow:(NSNumber*)wavelengthLow withWavelengthHi:(NSNumber*)wavelengthHi withFibreInput:(NSNumber*)fibreInChan withFibreOutput:(NSNumber*)fibreOutChan withNPulses:(NSNumber*)noPulses withGainVoltage:(NSNumber *)gain
{
    /*
     Run the SMELLIE superK laser in Master Mode
     
     :param intensity: the laser intensity in per mil
     :param rep_rate: the repetition rate of requested laser sequence
     :param wavelength_low: the low edge of the wavelength window
     :param wavelength_hi: the high edge of the wavelength window
     :param fs_input_channel: the fibre switch input channel
     :param fs_output_channel: the fibre switch output channel
     :param n_pulses: the number of pulses
     :param gain: the gain setting to be applied at the MPU
     */
    NSArray* args = @[intensity, rate, wavelengthLow, wavelengthHi, fibreInChan, fibreOutChan, noPulses, gain];
    id result = [[self smellieClient] command:@"superk_master_mode" withArgs:args];
    if([result isKindOfClass:[NSString class]]){
        NSException* e = [NSException
                          exceptionWithName:@"SMELLIE EXCEPTION"
                          reason:result
                          userInfo:nil];
        [e raise];
    }
}

-(void) startInterlockThread;
{
    /*
     Launch a thread to host the keep alive pulsing.
     */

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    //////////////
    //Get the run controller
    NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Couldn't find ORRunModel. Please add it to the experiment and restart the run.\n");
        return;
    }
    ORRunModel* runControl = [runModels objectAtIndex:0];

    NSArray* args = @[[NSNumber numberWithInteger:[runControl runNumber]]];
    @try {
        [[self interlockClient] command:@"new_run" withArgs:args];
        [[self interlockClient] command:@"set_arm"];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor], @"[SMELLIE]: Problem activating interlock server, reason: %@\n", [e reason]);
        [self setEllieFireFlag:NO];
        [pool release];
        return;
    }

    //////////////////////
    // Start interlock thread
    interlockThread = [[NSThread alloc] initWithTarget:self selector:@selector(pulseKeepAlive:) object:nil];
    [interlockThread start];
    [pool release];
}

-(void) killKeepAlive:(NSNotification*)aNote
{
    /*
     Stop pulsing the keep alive and disarm the interlock
    */

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    // Cancel the SMELLIE run threads - If we've killed the interlock, we will never want to keep running
    [interlockThread cancel];
    [[self smellieThread] cancel];
    [self setEllieFireFlag:NO];

    // Tell SMELLIE to stop generating triggers. This sets a flag in the server functions to tell them to jump out early
    @try{
        [self CancelSmellieTriggers];
    } @catch(NSException *e) {
        NSLogColor([NSColor redColor], @"[SMELLIE]: Problem telling smellie to stop sending triggers, reason: %@\n", [e reason]);
    }

    // Additionally send an explicit disarm command to the interlock.
    @try {
        [[self interlockClient] command:@"set_disarm"];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor], @"[SMELLIE]: Problem disarming interlock server, reason: %@\n", [e reason]);
    }
    [pool release];
 }

-(void) pulseKeepAlive:(id)passed
{
    /*
     A fuction to be run in a thread, continually sending keep alive pulses to the interlock server
    */
    while (![interlockThread isCancelled]) {
        @try{
            [[self interlockClient] command:@"send_keepalive"];
        } @catch(NSException* e) {
            NSLogColor([NSColor redColor], @"[SMELLIE]: Problem sending keep alive to interlock server, reason: %@\n", [e reason]);
            [self setEllieFireFlag:NO];
            return;
        }
        [NSThread sleepForTimeInterval:0.05];
    }
    NSLog(@"[SMELLIE]: Stopped sending keep-alive to interlock server\n");
}

-(void) startSmellieRunInBackground:(NSDictionary*)smellieSettings
{
    [self performSelectorOnMainThread:@selector(startSmellieRun:) withObject:smellieSettings waitUntilDone:NO];
}

-(NSNumber*)estimateSmellieRunTime:(NSDictionary *)smellieSettings
{
    /*
        Use a dictionary of run settings to estimate the execution time of a smellie sequence
    */

    ////////////////////////////
    // Globals
    float triggerFrequency = [[smellieSettings objectForKey:@"trigger_frequency"] floatValue];
    float numberTriggersPerLoop = [[smellieSettings objectForKey:@"triggers_per_loop"] floatValue];

    ////////////////////////////
    // Fixed wavelength pars and time calc

    // Get laser / fibre arrays
    NSArray* smellieLaserArray = [smellieSettings objectForKey:@"lasers"];
    NSArray* smellieFibreArray = [smellieSettings objectForKey:@"fibres"];
    NSArray* smellieWavelegnthsArray = [smellieSettings objectForKey:@"central_wavelengths"];
    NSUInteger nSubRuns = [[smellieSettings objectForKey:@"total_sub_runs"] unsignedIntegerValue];

    float fireTime = (numberTriggersPerLoop * nSubRuns) / (triggerFrequency);

    //////////////////////
    // Define some parameters for overheads calculation
    float changeIntensity = 0.5;
    float changeFibre = 0.1;
    float changeFixedLaser = 45;
    float changeSKWavelength = 1;
    float changeGain = 0.5;

    float laserOverhead = [smellieLaserArray count]*changeFixedLaser;
    float fibreOverhead = [smellieLaserArray count]*changeFibre;
    float wavelengthOverhead = [smellieFibreArray count]*[smellieWavelegnthsArray count]*changeSKWavelength;
    float intensityOverhead = nSubRuns*changeIntensity;
    float gainOverhead = nSubRuns*changeGain;
    float totalOverhead = laserOverhead + fibreOverhead + wavelengthOverhead + intensityOverhead + gainOverhead;

    float totalTime = (fireTime + totalOverhead) / 60.;
    return [NSNumber numberWithFloat:totalTime];
}

-(void) startSmellieRunThread:(NSDictionary*)smellieSettings;
{
    /*
     Launch a thread to host the smellie run functionality.
    */

    //////////////////////
    // Start tellie thread
    [self setSmellieThread:[[NSThread alloc] initWithTarget:self selector:@selector(startSmellieRun:) object:smellieSettings]];
    [[self smellieThread] start];
}

-(void)startSmellieRun:(NSDictionary*)smellieSettings
{
    /*
     Form a smellie run using the passed smellie run file, stored in smellieSettings dictionary.
    */
    NSLog(@"[SMELLIE]: Setting up a SMELLIE Run\n");

    //////////////
    // This will likely run in thread so make an auto release pool
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    [self setMaintenanceRollOver:YES]; // Asssume we roll over by default.
    [self setSmellieStopButton:NO]; // Had the stop button been pressed?

    /////////////////////
    // Define some static variables
    int counter=0;
    NSString* laser;
    NSString* fibre;
    NSNumber* wavelengthLowEdge;
    NSNumber* wavelengthHighEdge;
    NSNumber* intensity;
    NSNumber* gain;
    NSNumber* rate = [NSNumber numberWithInteger:[[smellieSettings objectForKey:@"trigger_frequency"] integerValue]];
    NSNumber* nTriggers = [NSNumber numberWithInteger:[[smellieSettings objectForKey:@"triggers_per_loop"] integerValue]];
    NSMutableArray* fireSettingsArray = [NSMutableArray arrayWithCapacity:51];

    //////////////
    //   GET TUBii & RunControl MODELS
    //////////////
    //Get a Tubii object
    NSArray*  tubiiModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"TUBiiModel")];
    if(![tubiiModels count]){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Couldn't find Tubii model.\n");
        goto err;
    }
    TUBiiModel* theTubiiModel = [tubiiModels objectAtIndex:0];

    //////////////
    //Get the run controller
    NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Couldn't find ORRunModel. Please add it to the experiment and restart the run.\n");
        goto err;
    }
    ORRunModel* runControl = [runModels objectAtIndex:0];

    ///////////////
    // RUN CONTROL
    ///////////////////////
    // Check SMELLIE run type is masked in
    if(!([runControl runType] & kSMELLIERun)){
        NSLogColor([NSColor redColor], @"[SMELLIE] SMELLIE bit is not masked into the run type word\n");
        NSLogColor([NSColor redColor], @"[SMELLIE]: Please load the SMELLIE standard run type.\n");
        goto err;
    }

    ////////////////////////
    // Check keep alive is running.
    if(![[theTubiiModel keepAliveThread] isExecuting]){
        NSLog(@"The keep alive thread between ORCA and TUBii was inactive. Relaunching.\n");
        [theTubiiModel activateKeepAlive];
    }

    ///////////////////////
    // Check trigger is being sent to asyncronus port (EXT_A)
    NSUInteger asyncTrigMask;
    @try{
        asyncTrigMask = [theTubiiModel asyncTrigMask];
    } @catch(NSException* e) {
        NSLogColor([NSColor redColor], @"[SMELLIE]: Error requesting asyncTrigMask from Tubii.\n");
        goto err;
    }
    if(!(asyncTrigMask & 0x800000)){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Triggers as not being sent to asynchronous MTC/D port\n");
        NSLogColor([NSColor redColor], @"[SMELLIE]: Please amend via the TUBii GUI (triggers tab)\n");
        goto err;
    }

    /////////////////////
    // Create and push initial smellie run doc and tell smellie which run we're in
    [self setEllieFireFlag:YES];

    if([runControl isRunning]){
        @try{
            [self setSmellieNewRun:[NSNumber numberWithUnsignedLong:[runControl runNumber]]];
        } @catch(NSException* e) {
            NSLogColor([NSColor redColor], @"[SMELLIE]: Problem with server request: %@\n", [e reason]);
            goto err;
        }
        
        @try{
            [self pushInitialSmellieRunDocument];
        } @catch(NSException* e){
            NSLogColor([NSColor redColor],@"[SMELLIE]: Problem pushing initial run log: %@\n", [e reason]);
            goto err;
        }
    }
    /////////////////////
    // Tell gui we're about to flash
    dispatch_sync(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ORELLIEFlashing object:self];
    });

    //////////////////////
    // BEGIN LOOPING!
    //
    for(NSDictionary* subRun in [smellieSettings objectForKey:@"sub_runs"]){
        ////////////////////////
        // Check if thread has been canceled
        if([self ellieFireFlag] == NO || [[NSThread currentThread] isCancelled]){
            NSLogColor([NSColor redColor], @"[SMELLIE]: thread has been cancelled, killing sequence.\n");
            goto err;
        }
        
        ///////////////////////
        // Loop settings
        @try{
            laser = [subRun objectForKey:@"laser"];
            fibre = [subRun objectForKey:@"fibre"];
            wavelengthLowEdge = [NSNumber numberWithInteger:[[subRun objectForKey:@"wavelength_low"] integerValue]];
            wavelengthHighEdge  = [NSNumber numberWithInteger:[[subRun objectForKey:@"wavelength_hi"] integerValue]];
            intensity = [NSNumber numberWithInteger:[[subRun objectForKey:@"intensity"] integerValue]];
            gain = [NSNumber numberWithFloat:[[subRun objectForKey:@"gain"] floatValue]];
        } @catch(NSException* e) {
            NSLogColor([NSColor redColor], @"[SMELLIE]: Sub run settings could not be properly read, reason : %@.\n", [e reason]);
            goto err;
        }

        ///////////////////////
        // Loop settings to be passed to couchdb
        NSMutableDictionary* valuesToFillPerSubRun = [NSMutableDictionary dictionaryWithCapacity:10];
        [valuesToFillPerSubRun setObject:laser forKey:@"laser"];
        [valuesToFillPerSubRun setObject:fibre forKey:@"fibre"];
        [valuesToFillPerSubRun setObject:nTriggers forKey:@"number_of_shots"];
        [valuesToFillPerSubRun setObject:intensity forKey:@"intensity"];
        [valuesToFillPerSubRun setObject:gain forKey:@"gain"];
        [valuesToFillPerSubRun setObject:rate forKey:@"pulse_rate"];
        [valuesToFillPerSubRun setObject:wavelengthHighEdge forKey:@"wavelength_high_edge"];
        [valuesToFillPerSubRun setObject:wavelengthLowEdge forKey:@"wavelength_low_edge"];
        [valuesToFillPerSubRun setObject:[NSNumber numberWithInt:[runControl subRunNumber]] forKey:@"sub_run_number"];
        [fireSettingsArray insertObject:valuesToFillPerSubRun atIndex:counter];

        ///////////////////////
        // Fibre switch stuff
        NSNumber* laserSwitchChannel;
        NSNumber* fibreInputSwitchChannel;
        NSNumber* fibreOutputSwitchChannel;
        @try{
            laserSwitchChannel = [[self smellieLaserHeadToSepiaMapping] objectForKey:laser];
            fibreInputSwitchChannel = [[self smellieLaserToInputFibreMapping] objectForKey:laser];
            fibreOutputSwitchChannel = [[self smellieFibreSwitchToFibreMapping] objectForKey:fibre];
        } @catch(NSException* e) {
            NSLogColor([NSColor redColor], @"[SMELLIE]: Could not map laser and / or fibre switch, reason : %@\n", [e reason]);
        }

        //////////////////////
        // Print sub-run settings
        NSLog(@"--------------  Settings summary : Sub Run %d\n", [[valuesToFillPerSubRun objectForKey:@"sub_run_number"] integerValue]);
        NSLog(@"[SMELLIE]: Laser \t\t: %@\n", laser);
        NSLog(@"[SMELLIE]: Fibre \t\t: %@\n", fibre);
        NSLog(@"[SMELLIE]: Wavelength \t: %d\n", [wavelengthLowEdge integerValue]);
        NSLog(@"[SMELLIE]: Intensity\t\t: %1.1f\n", [intensity floatValue]);
        NSLog(@"[SMELLIE]: PMT Gain \t\t: %1.2f\n", [gain floatValue]);
        NSLog(@"[SMELLIE]: No. triggers\t: %d\n", [nTriggers integerValue]);
        NSLog(@"[SMELLIE]: Rate\t\t\t: %1.1f Hz\n", [rate floatValue]);

        ///////////////////////
        // Tell the hardware what to do
        if([laser isEqualTo:@"superK"]){

            @try{
                [theTubiiModel setSmellieDelay:[[smellieSettings objectForKey:@"delay_superK"] intValue]];
            } @catch(NSException* e) {
                NSLogColor([NSColor redColor], @"[SMELLIE]: Problem setting trigger delay at TUBii: %@\n", [e reason]);
                goto err;
            }

            @try{
                [self setSmellieSuperkMasterMode:intensity withRepRate:rate withWavelengthLow:wavelengthLowEdge withWavelengthHi:wavelengthHighEdge withFibreInput:fibreInputSwitchChannel withFibreOutput:fibreOutputSwitchChannel withNPulses:nTriggers withGainVoltage:gain];
            } @catch(NSException* e){
                NSLogColor([NSColor redColor], @"[SMELLIE]: Problem with smellie server request: %@\n", [e reason]);
                goto err;
            }
        } else {

            @try{
                [theTubiiModel setSmellieDelay:[[smellieSettings objectForKey:@"delay_fixed_wavelength"] intValue]];
            } @catch(NSException* e) {
                NSLogColor([NSColor redColor], @"[SMELLIE]: Problem setting trigger delay at TUBii: @\n", [e reason]);
                goto err;
            }

            @try{
                [self setSmellieLaserHeadMasterMode:laserSwitchChannel withIntensity:intensity withRepRate:rate withFibreInput:fibreInputSwitchChannel withFibreOutput:fibreOutputSwitchChannel withNPulses:nTriggers withGainVoltage:gain];
            } @catch(NSException* e){
                NSLogColor([NSColor redColor], @"[SMELLIE]: Problem with smellie server request: %@\n", [e reason]);
                goto err;
            }
        }

        //////////////////
        //Push record of sub-run settings to db
        //
        // We do this in chunks as each push to
        // the db comes with some overheads.
        if([runControl isRunning]){
            if(counter > 0 && counter % 50 == 0){
                @try{
                    [self updateSmellieRunDocument:fireSettingsArray];
                } @catch(NSException* e){
                    NSLogColor([NSColor redColor], @"[SMELLIE]: Problem updating couchdb run file: %@\n", [e reason]);
                    goto err;
                }
                ////////////////////
                // Reset counter for addressing objects in an array
                [fireSettingsArray removeAllObjects];
                counter = 0;
            }
        }

        //////////////////
        //Check if run file requests a sleep time between sub_runs
        if([smellieSettings objectForKey:@"sleep_between_sub_run"]){
            NSTimeInterval sleepTime = [[smellieSettings objectForKey:@"sleep_between_sub_run"] floatValue];
            [NSThread sleepForTimeInterval:sleepTime];
        }
                        
        //////////////////
        // RUN CONTROL
        //Prepare new subrun - will produce a subrun boundrary in the zdab.
        if([runControl isRunning] && ![[NSThread currentThread] isCancelled]){
            [runControl performSelectorOnMainThread:@selector(prepareForNewSubRun) withObject:nil waitUntilDone:YES];
            [runControl performSelectorOnMainThread:@selector(startNewSubRun) withObject:nil waitUntilDone:YES];
        }
    } // End of subRun loop

err:
{
    ////////////////////////
    // Deactivate the system

    ////////////////////////
    // Check if we have any sub-run settings we need to pipe up
    if([runControl isRunning] && fireSettingsArray){
        if([fireSettingsArray count] > 0){
            @try{
                [self updateSmellieRunDocument:fireSettingsArray];
            } @catch(NSException* e){
                NSLogColor([NSColor redColor], @"[SMELLIE]: Problem updating couchdb run file: %@\n", [e reason]);
                goto err;
            }
        }
    }

    // Keep alive - will stop light any light
    [self killKeepAlive:nil];

    // Tubii
    @try{
        [theTubiiModel stopSmelliePulser];
    } @catch(NSException* e){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Problem sending stop command to the SMELLIE pulsar.\n");
    }

    // Smellie lasers
    @try{
        NSLog(@"[SMELLIE]: Waiting for lasers to deactivate....\n");
        [self deactivateSmellieLasers];
    } @catch(NSException* e) {
        NSLogColor([NSColor redColor], @"[SMELLIE]: Deactivate command failed, reason: %@\n", [e reason]);
    }

    NSLog(@"[SMELLIE]: Run sequence stopped.\n");
    //Release dict holding sub-run info
    [[NSThread currentThread] cancel];

    //////////////////////////////////////////
    //Post a note. on the main thread to request a call to handle run rollover stuff
    [[NSThread currentThread] cancel];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSMELLIERunFinishedNotification object:self];
    });
    [pool release];
}
}

-(void)stopSmellieRun
{
    /*
     Before we perform any tidy-up actions, we want to make sure the run thread has stopped
     executing. If the run has not been canceled using the smellie specific 'stop fibre' button,
     but instead the user has simply hit the main run stop button on the SNOPController, we
     need to make sure SMELLIE has properly cleaned up before we roll into a new run.
     Fortunately there is a handy wait notification that gets picked up by the run control.

     Here we post the run wait notification and launch a thread that waits for the smellieThread
     to stop executing before tidying up and, finally, releasing the run wait.
     */

    // Post a notification telling the run control to wait until the thread finishes
    NSDictionary* userInfo  = [NSDictionary dictionaryWithObjectsAndKeys:@"waiting for smellie run to finish", @"Reason", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAddRunStateChangeWait object:self userInfo:userInfo];

    if([[self smellieThread] isExecuting]){
        // Cancel the SMELLIE thread
        [[self smellieThread] cancel];

        // Tell SMELLIE hardware to stop generating triggers
        @try{
            // Use a second SMELLIE client (which is not being blocked by the current fire sequence) to set
            // a flag on the server. The flag will cause it to jump out of it's current trigger sequence early.
            [self CancelSmellieTriggers];
        } @catch(NSException *e) {
            NSLogColor([NSColor redColor], @"[SMELLIE]: Problem telling smellie to stop sending triggers, reason: %@\n", [e reason]);
        }

        ///////////////////////////////////////
        // If a run transition thread isn't yet running, run one.
        // Doing it this way avoids multiple transition behaviours.
        if(![_smellieTransitionThread isExecuting]){
            // Detatch thread to monitor smellie run thread
            NSLog(@"[SMELLIE]: Waiting for SMELLIE server to release blocking trigger function...\n");
            [self setSmellieTransitionThread:[[NSThread alloc] initWithTarget:self selector:@selector(smellieRunTransition) object:nil]];
            [[self smellieTransitionThread] start];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:ORReleaseRunStateChangeWait object:self];
        }
    } else {
        // Tell run control it can stop waiting
        [[NSNotificationCenter defaultCenter] postNotificationName:ORReleaseRunStateChangeWait object:self];
    }
}

-(void)smellieRunTransition
{
    //////////////////////////////////////////////
    // Make a pool to handle this stuff
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    /////////////////////////////////////////////
    // Wait for smellie thread to stop executing
    while ([[self smellieThread] isExecuting]) {
        [NSThread sleepForTimeInterval:0.2];
    }
    NSLog(@"[SMELLIE]: Blocking function released\n");

    ////////////////////////////////////////////
    // Tell run control it can stop waiting (this is a spawned thread so use dispatch_sync)
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORReleaseRunStateChangeWait object:self];

    //////////////////////////////////////////
    // HANDLE RUN ROLLOVERS
    //
    // If the sequence finished without external influence, move into a maintenance run.
    if([self maintenanceRollOver]){
        NSArray*  snopModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
        if(![snopModels count]){
            NSLogColor([NSColor redColor], @"[SMELLIE]: Couldn't find SNOPModel\n");
            goto err;
        }
        SNOPModel* snopModel = [snopModels objectAtIndex:0];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [snopModel startStandardRun:@"MAINTENANCE" withVersion:@"DEFAULT"];
        });
        [pool release];
        return;
    }

    ///////
    // Now, there's two possible cases. Either someone hit the SMELLIE stop lasers button,
    // or they hit stop / resync / start run.
    //
    // In the fist case we want to roll over the run number so the 'bad' data set which was
    // cancelled is separated from any futher SMELLIE data by a run boundary. In the second case
    // do nothing and let the run control sort out whatever was requested.
    if([self smellieStopButton]){
        NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
        if(![runModels count]){
            NSLogColor([NSColor redColor], @"[SMELLIE]: Couldn't find ORRunModel. Please add it to the experiment and restart the run.\n");
            goto err;
        }
        ORRunModel* runControl = [runModels objectAtIndex:0];
        [runControl performSelectorOnMainThread:@selector(restartRun) withObject:nil waitUntilDone:YES];
    }

    [pool release];
    return;

err:
{
    // Tell run control it can stop waiting
    dispatch_sync(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ORReleaseRunStateChangeWait object:self];
    });

    [pool release];
    NSLog(@"[SMELLIE]: Run sequence stopped - TUBii is in an undefined state (may still be sending triggers).\n");
}
}


/*****************************/
/*  smellie db interactions  */
/*****************************/
-(void) pushInitialSmellieRunDocument
{
    /*
     Create a standard smellie run doc using ELLIEModel / SNOPModel / ORRunModel class
     variables and push up to the smelliedb. Additionally, the run doc dictionary set as
     the tellieRunDoc propery, to be updated later in the run.
     */
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSMutableDictionary* runDocDict = [NSMutableDictionary dictionaryWithCapacity:10];

    NSArray *runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Couldn't find ORRunModel. Please add one to the experiment and restart the run.\n");
        return;
    }
    ORRunModel* runControl = [runModels objectAtIndex:0];

    NSArray*  snopModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    if(![snopModels count]){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Couldn't find SNOPModel. Please add one to the experiment and restart the run.\n");
        return;
    }
    SNOPModel* aSnotModel = [snopModels objectAtIndex:0];

    NSString* docType = [NSMutableString stringWithFormat:@"SMELLIE_RUN"];
    NSMutableArray* subRunArray = [NSMutableArray arrayWithCapacity:15];

    [runDocDict setObject:docType forKey:@"type"];
    [runDocDict setObject:[NSString stringWithFormat:@"%i",0] forKey:@"version"];
    [runDocDict setObject:[NSString stringWithFormat:@""] forKey:@"index"];
    [runDocDict setObject:[aSnotModel smellieRunNameLabel] forKey:@"run_description_used"];
    [runDocDict setObject:[self stringDateFromDate:nil] forKey:@"timestamp"];
    [runDocDict setObject:[self smellieConfigVersionNo] forKey:@"configuration_version"];
    [runDocDict setObject:[NSNumber numberWithInteger:[runControl runNumber]] forKey:@"run"];
    [runDocDict setObject:[NSMutableArray arrayWithObjects:[NSNumber numberWithUnsignedLong:[runControl runNumber]],[NSNumber numberWithUnsignedLong:[runControl runNumber]], nil] forKey:@"run_range"];

    [runDocDict setObject:subRunArray forKey:@"sub_run_info"];

    [self setSmellieRunDoc:runDocDict];

    [[self couchDBRef:self withDB:@"smellie"] addDocument:runDocDict tag:kSmellieRunDocumentAdded];
    [pool release];
}

- (void) updateSmellieRunDocument:(NSArray*)subRunArray
{
    /*
     Update [self smellieRunDoc] with subrun information.
     
     Arguments:
     NSDictionary* subRunDoc:  Subrun information to be added to the current [self tellieRunDoc].
     */
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    // Reverse the array so it's in sub-run order
    NSArray* reversedArray = [[subRunArray reverseObjectEnumerator] allObjects];
    
    // Add the passed array to it
    NSArray* newSubRunInfo = [[[self smellieRunDoc] objectForKey:@"sub_run_info"] arrayByAddingObjectsFromArray:reversedArray];

    // Add the newly appended array back to the copy of runDocDict
    [[self smellieRunDoc] setObject:newSubRunInfo forKey:@"sub_run_info"];

    // Update the document on couchdb
    [[self couchDBRef:self withDB:@"smellie"] updateDocument:[self smellieRunDoc] documentId:[[self smellieRunDoc] objectForKey:@"_id"] tag:kSmellieRunDocumentUpdated];

    [pool release];
}

-(void) fetchCurrentSmellieConfig
{
    /*
     Query smellie config documenets on the smelliedb to find the most recent config versioning
     number.
    */
    NSString *requestString = [NSString stringWithFormat:@"_design/smellieMainQuery/_view/fetchMostRecentConfigVersion?descending=True&limit=1"];
    // Set config version number to be nil
    [self setSmellieConfigVersionNo:nil];
    [[self couchDBRef:self withDB:@"smellie"] getDocumentId:requestString tag:kSmellieConigVersionRetrieved];
}

-(void) parseCurrentConfigVersion:(id)aResult
{
    /*
     Parse the relavent information from the couch result given by fetchRecentSmellieConfig (above).
    */
    NSNumber* configVersion  = [[[aResult objectForKey:@"rows"]  objectAtIndex:0] objectForKey:@"key"];
    [self setSmellieConfigVersionNo:configVersion];
    
    // Now we have the most recent version number, go get the relavent file.
    [self fetchConfigurationFile:configVersion];
}

-(void) fetchConfigurationFile:(NSNumber*)currentVersion
{
    /*
     Fetch the current configuration document of a given version number.
     
     Arguments:
        NSNumber* currentVersion: The version number to be used with the query.
    */
    NSString *requestString = [NSString stringWithFormat:@"_design/smellieMainQuery/_view/pullEllieConfigHeaders?key=[%i]&limit=1",
                               [currentVersion intValue]];

    [[self couchDBRef:self withDB:@"smellie"] getDocumentId:requestString tag:kSmellieConigRetrieved];
}

-(void) parseConfigurationFile:(id)aResult
{
    /*
     Use the result returned by the couchdb querey prouced in fetchConfigurationFile (above) to
     fill dictionaries defining smellie's hardware configuration.
    */
    NSMutableDictionary* configForSmellie = [[[[aResult objectForKey:@"rows"]  objectAtIndex:0] objectForKey:@"value"] objectForKey:@"configuration_info"];

    //Set laser head to 'sepia' laser switch mapping
    NSMutableDictionary *laserHeadDict = [configForSmellie objectForKey:@"laserSwitchChannels"];
    NSMutableDictionary *laserHeadToSepiaMapping = [[NSMutableDictionary alloc] initWithCapacity:10];
    for (NSString* laserChannel in laserHeadDict){
        NSNumber* laserHeadIndex = [NSNumber numberWithInt:[[self extractNumberFromText:laserChannel] intValue]];
        NSString *laserHeadConnected = [NSString stringWithFormat:@"%@",[laserHeadDict objectForKey:laserChannel]];
        [laserHeadToSepiaMapping setObject:laserHeadIndex forKey:laserHeadConnected];
    }
    [self setSmellieLaserHeadToSepiaMapping:laserHeadToSepiaMapping];

    //Set laser to input fibre mapping
    NSMutableDictionary *fibreSwitchDict = [configForSmellie objectForKey:@"fibreSwitchChannels"];
    NSMutableDictionary *laserToInputFibreMapping = [[NSMutableDictionary alloc] initWithCapacity:10];
    NSMutableDictionary *fibreSwitchOutputToFibre = [[NSMutableDictionary alloc] initWithCapacity:10];
    for (NSString* switchChannel in fibreSwitchDict){
        NSString* firstChar = [switchChannel substringWithRange:NSMakeRange(0, 1)];
        NSNumber* numInString = [NSNumber numberWithInt:[[self extractNumberFromText:switchChannel] intValue]];
        if ([firstChar isEqualToString:@"i"]) { // Input channels
            NSString *laserHeadConnected = [NSString stringWithFormat:@"%@",[fibreSwitchDict objectForKey:switchChannel]];
            [laserToInputFibreMapping setObject:numInString forKey:laserHeadConnected];
        } else if ([firstChar isEqualToString:@"o"]) { // Output channels
            NSString *fibreConnected = [NSString stringWithFormat:@"%@",[fibreSwitchDict objectForKey:switchChannel]];
            [fibreSwitchOutputToFibre setObject:numInString forKey:fibreConnected];
        }
    }
    [self setSmellieLaserToInputFibreMapping:laserToInputFibreMapping];
    [self setSmellieFibreSwitchToFibreMapping:fibreSwitchOutputToFibre];

    [laserHeadToSepiaMapping release];
    [laserToInputFibreMapping release];
    [fibreSwitchOutputToFibre release];
    
    NSLog(@"[SMELLIE] config file (version %i) sucessfully loaded\n", [[self smellieConfigVersionNo] intValue]);
}

/*********************************************************/
/*              General Database Functions               */
/*********************************************************/
- (ORCouchDB*) couchDBRef:(id)aCouchDelegate withDB:(NSString*)entryDB;
{
    /*
     Get an ORCouchDB object pointing to a sno+ couchDB repo.
     
     Arguments:
     id aCouchDelegate:  An OrcaObject which will be delgated some functionality during
     ORCouchDB function calls. This is used to select which model
     handels the returned result via a couchDBResult method.
     NSString* entryDB:  The SNO+ couchDB repo to be assocated with the ORCouchDB object.
     
     Returns:
     ORCouchDB* result:  An ORCouchDB object pointing to the entryDB repo.
     */
    //Collect a series of objects from the SNOPModel
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    SNOPModel* aSnotModel = [objs objectAtIndex:0];
    
    ORCouchDB* result = [ORCouchDB couchHost:aSnotModel.orcaDBIPAddress
                                        port:aSnotModel.orcaDBPort
                                    username:aSnotModel.orcaDBUserName
                                         pwd:aSnotModel.orcaDBPassword
                                    database:entryDB
                                    delegate:self];
    
    if (aCouchDelegate)
        [result setDelegate:aCouchDelegate];
    
    return result;
}

- (void) couchDBResult:(id)aResult tag:(NSString*)aTag op:(id)anOp
{
    /*
     A delagate function which catches the result of couchdb queries.
     The relavent follow up function (normally to parse the returned data)
     is called based on the tag that was sent with the request.
     
     Arguments:
     id aResult:     Object returned by cauchdb query.
     NSString* aTag: The query tag to check against expected cases.
     id anOp:        This doesn't appear to be used??
     */
    @synchronized(self){
        if(aResult == (id)[NSNull null]){
            NSLogColor([NSColor redColor], @"[ELLIE]: DB Query returned NULL %@", aTag);
            return;
        }
        if([aResult isKindOfClass:[NSDictionary class]]){
            NSString* message = [aResult objectForKey:@"Message"];
            if(message){
                [aResult prettyPrint:@"CouchDB Message:"];
            }

            NSString* error = [aResult objectForKey:@"error"];
            if(error){
                NSLogColor([NSColor redColor], @"[ELLIE]: Problem recieving couch doc with tag %@: %@\n", aTag, error);
                return;
            }
            //Look through all of the possible tags for ellie couchDB results
            //This is called when smellie run header is queried from CouchDB
            if ([aTag isEqualToString:kTellieRunDocumentAdded]){
                NSMutableDictionary* runDoc = [[self tellieRunDoc] mutableCopy];
                [runDoc setObject:[aResult objectForKey:@"id"] forKey:@"_id"];
                [self setTellieRunDoc:runDoc];
                [runDoc release];
            } else if ([aTag isEqualToString:kSmellieRunDocumentAdded]){
                NSMutableDictionary* runDoc = [[self smellieRunDoc] mutableCopy];
                [runDoc setObject:[aResult objectForKey:@"id"] forKey:@"_id"];
                [self setSmellieRunDoc:runDoc];
                [runDoc release];
            } else if ([aTag isEqualToString:kSmellieConigVersionRetrieved]){
                [self parseCurrentConfigVersion:aResult];
            } else if ([aTag isEqualToString:kSmellieConigRetrieved]){
                [self parseConfigurationFile:aResult];
            } else if ([aTag isEqualToString:kTellieParsRetrieved]){
                [self parseTellieFirePars:aResult];
            } else if ([aTag isEqualToString:kTellieMapRetrieved]){
                [self parseTellieFibreMap:aResult];
            } else if ([aTag isEqualToString:kTellieNodeRetrieved]){
                [self parseTellieNodeMap:aResult];
            } else if ([aTag isEqualToString:kTellieRunPlansRetrieved]){
                [self parseTellieRunPlans:aResult];
            } else if ([aTag isEqualToString:kAmellieFibresRetrieved]){
                [self parseAmellieFibreMap:aResult];
            } else if ([aTag isEqualToString:kAmellieNodesRetrieved]){
                [self parseAmellieNodeMap:aResult];
            }

            //If no tag is found for the query result
            else {
                NSLog(@"No Tag assigned to that query/couchDB View \n");
                NSLog(@"Object: %@\n",aResult);
            }
        }

        else if([aResult isKindOfClass:[NSArray class]]){
            [aResult prettyPrint:@"CouchDB"];
        }
        else{
            //no docs found 
        }
    }
}

/****************************************/
/*        Misc generic methods          */
/****************************************/

- (NSString *)extractNumberFromText:(NSString *)text
{
    NSCharacterSet *nonDigitCharacterSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    return [[text componentsSeparatedByCharactersInSet:nonDigitCharacterSet] componentsJoinedByString:@""];
}


- (NSString*) stringDateFromDate:(NSDate*)aDate
{
    /*
     Format date object to a string for inclusion in couchDB files.
     
     Arguments:
     NSDate* aDate : A NSDate object with the current time / date.
     
     Returns:
     NSString* result : The date formatted into a human readable sting.
     */
    NSDateFormatter* snotDateFormatter = [[NSDateFormatter alloc] init];
    [snotDateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SS'Z'"];
    snotDateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    NSDate* strDate;
    if (!aDate)
        strDate = [NSDate date];
    else
        strDate = aDate;
    NSString* result = [snotDateFormatter stringFromDate:strDate];
    [snotDateFormatter release];

    return result;
}

- (NSString*) stringUnixFromDate:(NSDate*)aDate
{
    /*
     Format date object to a string with the standard unix format.
     
     Arguments:
     NSDate* aDate : A NSDate object with the current time / date.
     
     Returns:
     NSString* result : The date formatted into a human readable sting.
     */
    NSDate* strDate;
    if(!aDate){
        strDate = [NSDate date];
    }else{
        strDate = aDate;
    }
    NSString* result = [NSString stringWithFormat:@"%f",[strDate timeIntervalSince1970]];
    strDate = nil;

    return result;
}

/****************************************/
/*            Server settings           */
/****************************************/
- (void) setTelliePort: (NSString*) port
{
    // Set the port number for the tellie server XMLRPC client.
    if ([port isEqualToString:[self telliePort]]) return;

    [port retain];
    [_telliePort release];
    _telliePort = port;

    [[self tellieClient] setPort:port];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ELLIEServerSettingsChanged" object:self];
}

- (void) setSmelliePort: (NSString*) port
{
    // Set the port number for the smellie server XMLRPC client.
    if ([port isEqualToString:[self smelliePort]]) return;

    [port retain];
    [_smelliePort release];
    _smelliePort = port;

    [[self smellieClient] setPort:port];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ELLIEServerSettingsChanged" object:self];
}

- (void) setInterlockPort: (NSString*) port
{
    // Set the port number for the interlock server XMLRPC client.
    if ([port isEqualToString:[self interlockPort]]) return;

    [port retain];
    [_interlockPort release];
    _interlockPort = port;

    [[self interlockClient] setPort:port];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ELLIEServerSettingsChanged" object:self];
}

- (void) setTellieHost: (NSString*) host
{
    // Set the host for the tellie server XMLRPC client.
    if (host == [self tellieHost]) return;

    [host retain];
    [_tellieHost release];
    _tellieHost = host;

    [[self tellieClient] setHost:host];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ELLIEServerSettingsChanged" object:self];
}

- (void) setSmellieHost: (NSString*) host
{
    // Set the host for the smellie server XMLRPC client.
    if (host == [self smellieHost]) return;

    [host retain];
    [_smellieHost release];
    _smellieHost = host;

    [[self smellieClient] setHost:host];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ELLIEServerSettingsChanged" object:self];
}

- (void) setInterlockHost: (NSString*) host
{
    // Set the host for the interlock server XMLRPC client.
    if (host == [self interlockHost]) return;

    [host retain];
    [_interlockHost release];
    _interlockHost = host;

    [[self interlockClient] setHost:host];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ELLIEServerSettingsChanged" object:self];
}

- (void) setTuningRun:(NSNumber *)tuningRun
{
    // Set the host for the interlock server XMLRPC client.
    if (tuningRun == [self tuningRun]) return;

    [tuningRun retain];
    [_tuningRun release];
    _tuningRun = tuningRun;

    [[NSNotificationCenter defaultCenter] postNotificationName:@"ELLIETuningRunChanged" object:self];
}

-(BOOL)pingTellie
{
    @try{
        [[self tellieClient] command:@"test"];
    } @catch(NSException* e) {
        NSLogColor([NSColor redColor], @"Could not ping tellie server, reason: %@\n", [e reason]);
        return NO;
    }
    return YES;
}

-(BOOL)pingSmellie
{
    @try{
        [[self smellieClient] command:@"is_connected"];
    } @catch(NSException* e) {
        NSLogColor([NSColor redColor], @"Could not ping smellie server, reason: %@\n", [e reason]);
        return NO;
    }
    return YES;
}

-(BOOL)pingInterlock
{
    @try{
        [[self interlockClient] command:@"is_connected"];
    } @catch(NSException* e) {
        NSLogColor([NSColor redColor], @"Could not ping interlock server, reason: %@\n", [e reason]);
        return NO;
    }
    return YES;
}



@end
