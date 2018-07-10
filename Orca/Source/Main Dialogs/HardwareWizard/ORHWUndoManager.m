//
//  ORHWUndoManager.m
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


#import "ORHWUndoManager.h"
#import "ORHWUndoSet.h"


@implementation ORHWUndoManager

+ (ORHWUndoManager*) hwUndoManager
{
    ORHWUndoManager* undoManager = [[ORHWUndoManager alloc]init];
    return [undoManager autorelease];
}

- (id) init
{
    self = [super init];
    [self setUndoList:[NSMutableArray array]];
    [self setMarkList:[NSMutableArray array]];
    index = -1;
    return self;
}

// ----------------------------------------------------------
//  - dealloc:
// ----------------------------------------------------------

- (void) dealloc
{
    [undoList release];
    [markList release];
    [super dealloc];
}

- (NSMutableArray *) undoList
{
    return undoList; 
}

- (void) setUndoList: (NSMutableArray *) anUndoList
{
    [anUndoList retain];
    [undoList release];
    undoList = anUndoList;
}
- (NSMutableArray *) markList
{
    return markList;
}

- (void) setMarkList: (NSMutableArray *) aMarkList
{
    [aMarkList retain];
    [markList release];
    markList = aMarkList;
}
- (void) clearMarks
{
    [markList removeAllObjects];
}
- (void) clearUndoList
{
    [undoList removeAllObjects];
}

- (void) startNewUndoGroup
{
    [undoList addObject:[NSMutableArray arrayWithCapacity:256]];
    index++;
}


- (void) addToUndo:(NSInvocation*)undoInvocation withRedo:(NSInvocation*)redoInvocation
{
    if(undoInvocation){
        ORHWUndoSet* aSet = [ORHWUndoSet setWithUndo:undoInvocation redo:redoInvocation];
        [[undoList lastObject] addObject:aSet];
    }
}

        
- (void) setMark
{        
    [markList addObject:[undoList lastObject]];
}

- (void) undo
{
    if(index>=0){
        if(index >= [undoList count])index = [undoList count]-1;
        id group = [undoList objectAtIndex:index];
        NSEnumerator* e = [group objectEnumerator];
        id item;
        while(item = [e nextObject]){
            [item undo];
        }
        index--;
    }
}

- (void) redo
{
    if(index == -1 || index <= [undoList count]){
        if(index == -1)index = 0;
        id group = [undoList objectAtIndex:index];
        NSEnumerator* e = [group objectEnumerator];
        id item;
        while(item = [e nextObject]){
            [item redo];
        }
        index++;
    }
}

- (void) undoToMark:(int)markIndex
{
    if(markIndex!=-1){
        id markedGroup = [markList objectAtIndex:markIndex];
        //find the group in the undoList
        int markIndex = [undoList indexOfObject:markedGroup];
        if(markIndex<=index){
            do{
                if(![self canUndo])break;
                [self undo];
            }while(index>=markIndex);
        }
        else {
            do{
                if(![self canRedo])break;
               [self redo];
            }while(index<markIndex);
        }
    }
}



- (BOOL) canUndo
{
    if(([undoList count]>0) && (index >=0))return YES;
    else return NO;
}
- (BOOL) canRedo
{
    if(([undoList count]>0) && ((index == -1) || (index < [undoList count])))return YES;
    else return NO;
}

- (int) numberOfMarks
{
    return [markList count];
}

@end
