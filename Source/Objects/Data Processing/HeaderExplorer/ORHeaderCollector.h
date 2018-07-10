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
	unsigned long runDataID;
	unsigned long currentRunStart;
	unsigned long currentRunEnd;
	long long fileSize;
}

- (id)   initWithPath:(NSString*)aPath delegate:(id)aDelegate;
- (void) dealloc;
- (void) processData;
- (void) processRunRecord:(unsigned long*)p;
- (void)logHeader:(NSDictionary*)aHeader
		 runStart:(unsigned long)runStart 
		   runEnd:(unsigned long)runEnd 
		runNumber:(unsigned long)runNumber 
		useSubRun:(unsigned long)useSubRun
	 subRunNumber:(unsigned long)subRunNumber
		 fileSize:(unsigned long)fileSize
		 fileName:(NSString*)aFilePath;

@end

@interface NSObject (ORHeaderCollector)
- (void) updateProgress:(NSNumber*)amountDone;
- (BOOL) cancelAndStop;
- (void) setFileToProcess:(NSString*)newFileToProcess;
- (void)logHeader:(NSDictionary*)aHeader
		 runStart:(unsigned long)runStart 
		   runEnd:(unsigned long)runEnd 
		runNumber:(unsigned long)runNumber 
		useSubRun:(unsigned long)useSubRun
	 subRunNumber:(unsigned long)subRunNumber
		 fileSize:(unsigned long)fileSize		
		 fileName:(NSString*)aFilePath;
- (void) checkStatus;
@end