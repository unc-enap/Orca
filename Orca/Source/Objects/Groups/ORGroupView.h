//
//  ORGroupView.h
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
@class ORGroup;

@interface ORGroupView : NSView <NSMenuDelegate>{
    id                  mouseTask;
    BOOL                dragSessionInProgress;
    BOOL                goodObjectsInDrag;
    ORGroup*            group;
    NSColor*            backgroundColor;
    NSArray*            draggedObjects;
    NSArray*            savedObjects;
    NSMutableArray*     draggedNodes;
	NSImage*            backgroundImage;
    BOOL                dragLocked;
}

#pragma mark ¥¥¥Accessors
- (NSArray*)draggedNodes;
- (void) dragDone;
- (void) setGroup:(ORGroup*)aModel;
- (ORGroup*) group;
- (NSColor*) backgroundColor;
- (void) setBackgroundColor:(NSColor*)aColor;
- (NSEnumerator*) objectEnumerator;
- (id) dataSource;
- (void) setDragLocked:(BOOL)aState;

#pragma mark ¥¥¥Graphics
- (void) setBackgroundImage:    (NSImage *)newImage;
- (void) drawBackground:        (NSRect)aRect;
- (void) drawContents:          (NSRect)aRect;
- (void) backgroundColorChanged:(NSNotification*)aNotification;
- (void) lineColorChanged:      (NSNotification*)aNotification;
- (void) lineTypeChanged:       (NSNotification*)aNotification;
- (void) contentSizeChanged:    (NSNotification*)aNotification;
- (void) imageChanged:          (NSNotification*)aNotification;

- (NSRect) resizeView:(NSRect)aNewRect;
- (NSRect) normalized;

#pragma mark ¥¥¥Mouse Events
- (void) setMouseTask:(id)aTask;
- (id)   mouseTask;
- (void) clearSelections:(BOOL)shiftKeyDown;
- (void) checkSelectionRect:(NSRect)aRect inView:(NSView*)aView;
- (void) checkRedrawRect:(NSRect)aRect inView:(NSView*)aView;
- (void) flagsChanged:(NSEvent *)theEvent;
- (void) keyDown:(NSEvent *)event;
- (void) moveSelectedObjectsUp:(NSEvent*)event;
- (void) moveSelectedObjectsDown:(NSEvent*)event;
- (void) moveSelectedObjectsLeft:(NSEvent*)event;
- (void) moveSelectedObjectsRight:(NSEvent*)event;
- (void) moveSelectedObjects:(NSPoint)delta;
- (BOOL) validateMenuItem:(NSMenuItem*)menuItem;
- (void) doControlClick:(NSView*)aView;
- (void) setEnableIconControls:(BOOL) aState;

#pragma mark ¥¥¥Actions
- (IBAction) copy:(id)sender;
- (IBAction) cut:(id)sender;
- (IBAction) paste:(id)sender;
- (IBAction) delete:(id)sender;
- (IBAction) arrangeInCircle:(id)sender;
- (IBAction) alignLeft:(id)sender;
- (IBAction) alignRight:(id)sender;
- (IBAction) alignBottom:(id)sender;
- (IBAction) alignTop:(id)sender;
- (IBAction) alignVerticalCenters:(id)sender;
- (IBAction) alignHorizontalCenters:(id)sender;
- (IBAction) sendToBack:(id)sender;
- (IBAction) bringToFront:(id)sender;
- (IBAction) getInfo:(id)sender;
- (IBAction) selectBackgroundImage:(id)sender;
- (IBAction) clearBackgroundImage:(id)sender;

#pragma mark ¥¥¥Drag and Drop
- (NSPoint) suggestPasteLocationFor:(id)anObject;
- (BOOL) dropPositionOK:(NSPoint)aPoint;
- (NSDragOperation) draggingSourceOperationMaskForLocal:(BOOL)flag;
- (BOOL) ignoreModifierKeysWhileDragging;
- (NSDragOperation) draggingEntered:(id <NSDraggingInfo>)sender;
- (NSDragOperation) draggingUpdated:(id <NSDraggingInfo>)sender;
- (void) draggingExited:(id <NSDraggingInfo>)sender;
- (BOOL) prepareForDragOperation:(id <NSDraggingInfo>)sender;
- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender;
- (void) concludeDragOperation:(id <NSDraggingInfo>)sender;
- (void) pasteboard:(NSPasteboard *)sender provideDataForType:(NSString *)type;
- (void) moveObject:(id)obj to:(NSPoint)aPoint;
- (BOOL) canAddObject:(id) obj atPoint:(NSPoint)aPoint;


#pragma mark ¥¥¥Connection Management
-(void)doConnectionFrom:(NSPoint)pt1 to:(NSPoint)pt2;

@end


@interface NSObject (ORGroupView)
- (NSString*) backgroundImagePath;
- (void) setBackgroundImagePath:(NSString*)aPath;
@end

@interface ORScrollView : NSScrollView
{
}
- (void) drawRect:(NSRect)aRect;
@end
