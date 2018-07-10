//
//  ORKatrinSLTModel.h
//  Orca
//
//  Created by A Kopmann on Fri 29.2.2008.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark •••Imported Files
#import "ORIpeSLTModel.h"
#import "ORDataTaker.h"
//#import "ORKatrinFLTModel.h"//SLT needs to call some FLT code to init histogramming -tb- 2008-04-24

@class ORReadOutList;
@class ORDataPacket;
@class TimedWorker;
@class ORKatrinFLTModel;
@class ORAlarm;


@interface ORKatrinSLTModel : ORIpeSLTModel 
{
		//for hw histogram access
        ORKatrinFLTModel *firstHistoModeFLT;
        BOOL fltsInHistoDaqMode;
		ORAlarm* fltFPGAConfigurationAlarm;
}

#pragma mark •••Initialization
- (id)   init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;

- (void) initBoard;

#pragma mark •••Accessors
- (ORAlarm*) fltFPGAConfigurationAlarm;
- (void) setFltFPGAConfigurationAlarm:(ORAlarm*) aAlarm;

#pragma mark ••••hw histogram access
- (int) waitForSecondStrobeOfFLT:(ORKatrinFLTModel *)flt;
- (void) startAllHistoModeFLTs;
- (void) stopAllHistoModeFLTs;
- (void) clearAllHistoModeFLTBuffers;

#pragma mark •••DataTaker
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;

@end

extern NSString* ORKatrinSLTModelHW_ResetChanged;

