//
//  ORTest.h
//  Orca
//
//  Created by snodaq on 9/22/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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





@interface ORTest : NSObject
{
	int tag;
	SEL testSelector;
}
+ testSelector:(SEL)aSelector tag:(int)aTag;
- (id) initTestSelector:(SEL)aSelector tag:(int)aTag;
- (void) runForObject:(id)anObj;
@end


@interface ORTestSuit : NSObject
{
	NSMutableArray* tests;
}
- (void) dealloc;
- (void) addTest:(ORTest*)aTest;
- (void) runForObject:(id)anObject;
- (void) stopForObject:(id)anObject;
@end

@interface NSObject (ORTest)
- (void) runningTest:(int)testTag status:(NSString*)theStatus;
- (void) setTestsRunning:(BOOL)aState;
- (BOOL) testsRunning;

@end