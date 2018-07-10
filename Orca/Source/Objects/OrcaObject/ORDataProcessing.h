//
//  ORDataProcessing.h
//  Orca
//
//  Created by Mark Howe on Tue Nov 2 2009.
//  Copyright (c) 2009 University of North Carolina. All rights reserved.
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

#import "ORDataPacket.h"

@class ORDecoder;

#define kDataPacket		@"kDataPacket"
#define kHeader			@"kHeader"
#define kRunMode		@"kRunMode"
#define kRunNumber		@"kRunNumber"
#define kSubRunNumber	@"kSubRunNumber"
#define kElapsedTime	@"kElapsedTime"
#define kFilePrefix		@"kFilePrefix"
#define kFileSuffix		@"kFileSuffix"

@protocol ORDataProcessing
- (void) processData:(NSArray*)dataArray decoder:(ORDecoder*)aDecoder;
- (void) runTaskStarted:(NSDictionary*)userInfo;
- (void) subRunTaskStarted:(NSDictionary*)userInfo;
- (void) runTaskStopped:(NSDictionary*)userInfo;
- (void) preCloseOut:(NSDictionary*)userInfo;
- (void) closeOutRun:(NSDictionary*)userInfo;
- (void) setInvolvedInCurrentRun:(BOOL)state;
- (void) runTaskBoundary;
@end
