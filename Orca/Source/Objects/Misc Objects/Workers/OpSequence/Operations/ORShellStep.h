//
//  ORShellStep.h
//  Orca
//
//  Created by Matt Gallagher on 2010/11/01.
//  Found on web and heavily modified by Mark Howe on Fri Nov 28, 2013.
//  Copyright (c) 2013  University of North Carolina. All rights reserved.
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

#import "OROpSeqStep.h"

@class ORTaskHandler;

@interface ORShellStep : OROpSeqStep
{
	NSString*       launchPath;
	NSArray*        argumentsArray;
	ORTaskHandler*  taskHandler;
	NSDictionary*   environment;
	id              currentDirectory;
	ORShellStep*    outputPipe;
	ORShellStep*    errorPipe;
	NSString*       outputStateKey;
	NSString*       errorStateKey;
	BOOL            trimNewlines;
	NSCondition*    taskStartedCondition;
	
	NSString*       outputStringErrorPattern;
	NSString*       errorStringErrorPattern;
}

@property (assign) BOOL         trimNewlines;
@property (copy) NSString*      outputStateKey;
@property (copy) NSString*      errorStateKey;
@property (retain) id           currentDirectory;
@property (copy) NSDictionary*  environment;
@property (copy) NSString*      launchPath;
@property (copy) NSArray*       argumentsArray;
@property (copy) NSString*      outputStringErrorPattern;
@property (copy) NSString*      errorStringErrorPattern;

+ (ORShellStep *)shellStepWithCommandLine:(NSString *)aLaunchPath, ... NS_REQUIRES_NIL_TERMINATION;

- (void) pipeOutputInto:(ORShellStep*)destination;
- (void) pipeErrorInto:(ORShellStep*) destination;
- (void)taskComplete:(ORTaskHandler*)aTaskHandler;
- (void)receiveOutputData:(NSData *)data fromTaskHandler:(ORTaskHandler *)handler;
- (void)receiveErrorData:(NSData *)data fromTaskHandler:(ORTaskHandler *)handler;

@end
