//
//  ORCardContainerView.m
//  Orca
//
//  Created by Mark Howe on Wed Nov 27, 2002.
//  Copyright  © 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark ¥¥¥Imported Files
#import "ORCardContainerView.h"
#import "OROrderedObjManager.h"

@implementation ORCardContainerView

@synthesize drawSlotNumbers,drawSlots;


//flagged as a crasher by XCode 8. Removed MAH 4/1/17
//- (void) awakeFromNib
//{
//	[[self window] makeFirstResponder:self];
//}

- (BOOL) validateLayoutItems:(NSMenuItem*)menuItem
{
	return NO;
}

- (BOOL) prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    if([super prepareForDragOperation:sender]){
        NSPoint aPoint     = [sender draggedImageLocation];
        NSPoint localPoint = [self convertPoint:aPoint fromView:nil];
        if([group conformsToProtocol:@protocol(OROrderedObjHolding)]){
            return [[OROrderedObjManager for:group] dropPositionOK:localPoint];
        }
            else return NO;
    }
    else return NO;
}

- (NSPoint) suggestPasteLocationFor:(id)aCard
{
	return [[OROrderedObjManager for:group] suggestLocationFor:aCard];
}
    
- (void) drawBackground:(NSRect)aRect
{
    if(drawSlotNumbers){
        [[OROrderedObjManager for:group] drawSlotLabels];
    }
    if(drawSlots){
        [[OROrderedObjManager for:group] drawSlotBoundaries];
    }
}

- (void) contentSizeChanged:(NSNotification*)note
{
}

- (BOOL) dropPositionOK:(NSPoint)aPoint
{
    return [[OROrderedObjManager for:group] dropPositionOK:aPoint];
}

- (void) moveSelectedObjects:(NSPoint)delta
{
	[[OROrderedObjManager for:group] moveSelectedObjects:delta];
}

- (BOOL) canAddObject:(id) obj atPoint:(NSPoint)aPoint
{
    if(![[(ORAppDelegate*)[NSApp delegate]document] documentCanBeChanged])return NO;

    else return [[OROrderedObjManager for:group] canAddObject:obj atPoint:aPoint];
}

- (void) moveObject:(id)obj to:(NSPoint)aPoint
{
    [[OROrderedObjManager for:group] moveObject:obj to:aPoint];
}

@end
