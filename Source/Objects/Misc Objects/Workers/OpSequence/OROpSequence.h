//
//  OROpSequence
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
@class OROpSequenceQueue;
@class OROpSeqStep;

typedef enum
{
	kOpSeqQueueNeverRun,
	kOpSeqQueueRunning,
	kOpSeqQueueFinished,
	kOpSeqQueueFailed,
	kOpSeqQueueCancelled
} enumOpSeqQueueState;

@interface OROpSequence : NSObject
{
    id                  delegate;
    enumOpSeqQueueState state;
	OROpSequenceQueue*  scriptQueue;
	NSArray*            steps;
    int                 idIndex;
    BOOL                allowedToRun;
    NSMutableDictionary* stepStorage;
}
- (id)   initWithDelegate:(id)aDelegate idIndex:(int)anIndex;
- (void) start;
- (void)cancel:(id)parameter;
- (NSArray*) operations;
- (id) step:(OROpSeqStep*)aStep objectForKey:(NSString*)aKey;
- (void) step:(OROpSeqStep*)aStep setObject:(id)aValue forKey:(NSString*)aKey;

@property (nonatomic, assign) BOOL                 allowedToRun;
@property (nonatomic, assign) int                  idIndex;
@property (nonatomic, assign) enumOpSeqQueueState  state;
@property (nonatomic, retain) NSArray*             steps;
@property (nonatomic, retain) NSMutableDictionary* stepStorage;
@property (assign)            id                   delegate;
@property (nonatomic, retain, readonly) OROpSequenceQueue* scriptQueue;

@end

extern NSString* OROpSequenceAllowedToRunChanged;
extern NSString* OROpSeqStepsChanged;
extern NSString* ORSequenceQueueCountChanged;

@interface NSObject (OROpSequence)
-(NSArray*) scriptSteps:(int)index;
-(BOOL)     allowedToRun:(int)index;
@end;