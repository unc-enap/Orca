//
//  NSInvocation+Extensions.h
//  Orca
//
//  Created by Mark Howe on Thu Feb 12 2004.
//  Copyright (c) 2004 CENPA, University of Washington. All rights reserved.
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




@interface NSInvocation (OrcaExtensions) 

+ (NSArray*) argumentsListFromSelector:(NSString*) aSelectorString;
+ (SEL) makeSelectorFromString:(NSString*) aSelectorString;
+ (SEL) makeSelectorFromArray:(NSArray*)cmdItems;
+ (id) invoke:(NSString*)args withTarget:(id)aTarget;
+ (NSInvocation*) invocationWithTarget:(id)target
                              selector:(SEL)aSelector
                       retainArguments:(BOOL)retainArguments
                                  args:(id)firstArg, ...;

- (BOOL) setArgument:(int)argIndex to:(id)aVal;
- (id) returnValue;
- (void) invokeWithNoUndoOnTarget:(id)aTarget;

@end
