//
//  ORHeaderCollector.h
//  OrcaIntel
//
//  Created by Mark Howe on 11/14/2009.
//  Copyright 2009 CENPA, University of North Carolina. All rights reserved.
//
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

#import "ORDecoderOperation.h"

@interface ORHeaderCollector : ORDecoderOperation {
	NSMutableData* dataToProcess;
	uint32_t runDataID;
	uint32_t currentRunStart;
	uint32_t currentRunEnd;
	int64_t fileSize;
}

- (id)   initWithPath:(NSString*)aPath delegate:(id)aDelegate;
- (void) dealloc;
- (void) processData;
- (void) processRunRecord:(uint32_t*)p;
- (void)logHeader:(NSDictionary*)aHeader
		 runStart:(uint32_t)runStart 
		   runEnd:(uint32_t)runEnd 
		runNumber:(uint32_t)runNumber 
		useSubRun:(uint32_t)useSubRun
	 subRunNumber:(uint32_t)subRunNumber
		 fileSize:(uint32_t)fileSize
		 fileName:(NSString*)aFilePath;

@end

@interface NSObject (ORHeaderCollector)
- (void) updateProgress:(NSNumber*)amountDone;
- (BOOL) cancelAndStop;
- (void) setFileToProcess:(NSString*)newFileToProcess;
- (void)logHeader:(NSDictionary*)aHeader
		 runStart:(uint32_t)runStart 
		   runEnd:(uint32_t)runEnd 
		runNumber:(uint32_t)runNumber 
		useSubRun:(uint32_t)useSubRun
	 subRunNumber:(uint32_t)subRunNumber
		 fileSize:(uint32_t)fileSize		
		 fileName:(NSString*)aFilePath;
- (void) checkStatus;
@end