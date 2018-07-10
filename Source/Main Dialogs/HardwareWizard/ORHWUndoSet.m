//
//  ORHWUndoSet.m
//  Orca
//
//  Created by Mark Howe on Sun Feb 15 2004.
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


#import "ORHWUndoSet.h"

@implementation ORHWUndoSet
+ (id) setWithUndo:(NSInvocation*)anUndoInvocation redo:(NSInvocation*)aRedoInvocation
{
    ORHWUndoSet* set = [[ORHWUndoSet alloc] init]; 
    [set setUndoInvocation: anUndoInvocation];
    [set setRedoInvocation: aRedoInvocation];
    return [set autorelease];
} 

- (id) init
{
    self = [super init];    
    return self;
}

- (void) dealloc
{
    [redoInvocation release];
    [undoInvocation release];

    [super dealloc];
}


- (NSInvocation *) undoInvocation
{
    return undoInvocation;
}
- (void) setUndoInvocation: (NSInvocation *) aUndoInvocation
{
    [aUndoInvocation retain];
    [undoInvocation release];
    undoInvocation = aUndoInvocation;
}

- (NSInvocation *) redoInvocation
{
    return redoInvocation;
}
- (void) setRedoInvocation: (NSInvocation *) aRedoInvocation
{
    [aRedoInvocation retain];
    [redoInvocation release];
    redoInvocation = aRedoInvocation;
}
- (NSUndoManager *)undoManager
{
    return [[[NSDocumentController sharedDocumentController] currentDocument] undoManager];
}

- (void) undo
{    
    [[self undoManager] disableUndoRegistration];
    [undoInvocation invoke];
    [[self undoManager] enableUndoRegistration];
}

- (void) redo
{    
    [[self undoManager] disableUndoRegistration];
    [redoInvocation invoke];
    [[self undoManager] enableUndoRegistration];
}

@end
