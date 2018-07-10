//
//  LivePedestals.h
//  Orca
//
//  Created by Javier Caravaca on 5/3/17.
//
//  Class to handle embedded pedestals
//

#ifndef Orca_LivePedestals_h
#define Orca_LivePedestals_h

#import <Foundation/Foundation.h>

#define LIVEPEDS_STOPPED 0
#define LIVEPEDS_RUNNING 1

@interface LivePedestals : NSObject {

@private

    //Status
    int current_step;
    int current_status;
    bool run_livepeds;

    //Objects
    id anMTCModel;
    id aSNOPModel;
    NSArray *anXL3Model;
    NSArray *aFECModel;

    //Previous run
    int prev_coarsedelay;
    int prev_finedelay;
    uint32_t prev_pedmask;
    float prev_pulserRate;

    //Pedestals thread
    NSThread *PedThread;

}

- (bool) run_livepeds;
- (int) current_step;
- (void) setCurrent_step:(int)aValue;
- (bool) isRunning;
- (void) start;
- (void) stop;
- (bool) isLockAvailable;
- (bool) shouldIrun;
- (void) launchLivePedsThread;
- (bool) isThreadRunning;

@end


#endif
