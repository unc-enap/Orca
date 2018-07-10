//
//  ECARun.h
//  Orca
//
//  Created by Javier Caravaca on 1/12/17.
//
//  Class that handles ECA or electronic ADC calibrations.
//

#ifndef Orca_ECARun_h
#define Orca_ECARun_h

#import <Foundation/Foundation.h>

#define ECAMODE_DEDICATED 0
#define ECAMODE_SUPERNOVA 1
#define ECAMODE_PHYSICS 2

@interface ECARun : NSObject {

@private
    //ECA Variables
    int ECA_pattern;
    NSString* ECA_type;
    int ECA_tslope_pattern;
    int ECA_nevents;
    NSNumber* ECA_rate;
    int ECA_mode;
    NSString* ECA_pattern_string;

    //Other objects
    id anMTCModel;
    id aSNOPModel;
    NSArray *anXL3Model;
    NSArray *aFECModel;
    //Previous run
    bool start_eca_run;
    int prev_coarsedelay;
    int prev_finedelay;
    uint16_t prev_pedwidth;
    uint32_t prev_pedmask;

    //ECA thread
    NSThread *ECAThread;
    bool isFinishing;
    bool isFinished;
    int ECA_currentStep;
    int ECA_currentPoint;
    double ECA_currentDelay;

}

- (int) ECA_mode;
- (NSString*) ECA_mode_string;
- (int) ECA_pattern;
- (NSString*) ECA_pattern_string;
- (NSString*) ECA_type;
- (int) ECA_tslope_pattern;
- (int) ECA_nevents;
- (NSNumber*) ECA_rate;
- (int) ECA_nsteps;
- (int) ECA_currentStep;
- (int) ECA_currentPoint;
- (int) ECA_currentDelay;
- (double) ECA_subruntime;
- (void) setECA_mode:(int)aValue;
- (void) setECA_pattern:(int)aValue;
- (void) setECA_type:(NSString*)aValue;
- (void) setECA_tslope_pattern:(int)aValue;
- (void) setECA_nevents:(int)aValue;
- (void) setECA_rate:(NSNumber*)aValue;
- (void) setECA_currentStep:(int)aValue;
- (void) setECA_currentPoint:(int)aValue;
- (void) setECA_currentDelay:(double)aValue;
- (BOOL) isExecuting;
- (BOOL) isFinished;
- (BOOL) isFinishing;
- (void) stop;
- (bool) setECASettings;
- (void) launchECAThread:(NSNotification*)aNote;
- (void) doECAs;
- (BOOL) doPedestals;
- (BOOL) doTSlopes;
- (void) changePedestalMask:(NSMutableArray*)aPedestal_mask;
- (BOOL) triggersOFF;
- (BOOL) loadTriggersWithCrateMask:(NSMutableArray*)aPedestal_mask;
- (BOOL) triggersON;

//Notifications
extern NSString* ORECAStatusChangedNotification;
extern NSString* ORECARunChangedNotification;
extern NSString* ORECARunStartedNotification;
extern NSString* ORECARunFinishedNotification;

@end

#endif