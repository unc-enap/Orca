//
//  GoTo.h
//  ORCA
//
//  Created by Mark Howe on 1/3/07.
//  Copyright 2007 CENPA, University of Washington. All rights reserved.
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

#import <Cocoa/Cocoa.h>
#import "GoToLine.h"
#import "SynthesizeSingleton.h"

@interface NSString (NSStringTextFinding)
- (NSRange)findString:(NSString *)string selectedRange:(NSRange)selectedRange options:(NSUInteger)mask wrap:(BOOL)wrapFlag;
@end

@implementation GoToLine

SYNTHESIZE_SINGLETON_FOR_CLASS(GoToLine);

- (void) loadUI 
{
    if (!lineNumberField) {
#if !defined(MAC_OS_X_VERSION_10_9)
        if (![NSBundle loadNibNamed:@"GoToLine" owner:self]){
#else
        if (![[NSBundle mainBundle] loadNibNamed:@"GoToLine" owner:self topLevelObjects:&topLevelObjects]){
#endif

            NSLog(@"Failed to load GoToLine.nib");
            NSBeep();
        }
        [topLevelObjects retain];
		if (self == sharedGoToLine) [[lineNumberField window] setFrameAutosaveName:@"Find"];
    }
}

- (void) dealloc 
{
    if (self != sharedGoToLine) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [topLevelObjects release];
        [super dealloc];
    }
}

- (NSTextView*) textObjectToSearchIn {
    id obj = [[NSApp mainWindow] firstResponder];
	if([obj isKindOfClass:[NSTextView class]]){
		layoutManager = [obj layoutManager];
		return obj;
	}
    else return nil;
}

- (NSPanel*) goToPanel 
{
    if (!lineNumberField) [self loadUI];
    return (NSPanel *)[lineNumberField window];
}


- (void) orderFrontGoToPanel:(id)sender 
{
	//commit all text editing... subclasses should call before doing their work.
	id oldFirstResponder = [[NSApp mainWindow] firstResponder];
	if(![[NSApp mainWindow] makeFirstResponder:[NSApp mainWindow]]){
		[[NSApp mainWindow] endEditingFor:nil];		
	}
	[[NSApp mainWindow] makeFirstResponder:oldFirstResponder];

    NSPanel *panel = [self goToPanel];
    [lineNumberField selectText:nil];
    [panel makeKeyAndOrderFront:nil];
}

- (BOOL) validateMenuItem:(NSMenuItem *)anItem
{

    if ([anItem action] == @selector(orderFrontGoToPanel:)) {
        return ([self textObjectToSearchIn] != NULL);
    }
    // if it isn't one of our menu items, we'll let the
    // superclass take care of it
    return [super validateMenuItem:anItem];
}

- (IBAction) jumpButtonClicked:(id)sender
{
	if( [sender tag] != 1 ) { // jump & close or cancel
		[dialogueView orderOut:self];
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
        [[[NSApplication sharedApplication] keyWindow] endSheet:dialogueView];
#else
        [[NSApplication sharedApplication]  endSheet:dialogueView];
#endif
	}

	if( [sender tag] == -1 ) return;

	[self showLine:[lineNumberField intValue]];
	
}


-(void)showLine:(NSUInteger)lineNumber
{
	NSUInteger indexLine = 0;
	NSUInteger charIndex = 0;
	NSRange lineRange;
	
	// Skip all lines that are visible at the top of the text view (if any)
	while ( indexLine < lineNumber ){
		++indexLine;
		
		[layoutManager lineFragmentRectForGlyphAtIndex:charIndex effectiveRange:&lineRange];
		charIndex = NSMaxRange( lineRange );
	}
	
	NSUInteger targetCharIndex =  charIndex - 1;

	[self showCharacter:targetCharIndex granularity:-1];
}


-(BOOL)showCharacter:(NSUInteger)charIndex granularity:(NSSelectionGranularity)granularity
	// show line in document text view
	// Granularity is one of NSSelectByCharacter, NSSelectByWord, NSSelectByParagraph, or -1(select by line)
{
	NSRange		lineRange;
	
	// Return if text view is empty
	id textView = [self textObjectToSearchIn];
	if([[textView textStorage] length]  < charIndex +1 ) return NO;
	
	
	// Show in textView
    switch(granularity){
        case NSSelectByCharacter:
        case NSSelectByWord:
        case NSSelectByParagraph:
            [textView setSelectedRange: [textView selectionRangeForProposedRange:NSMakeRange(charIndex,1) granularity:granularity]];
            break;
        default:
            [layoutManager lineFragmentRectForGlyphAtIndex:
             [layoutManager glyphRangeForCharacterRange:NSMakeRange(charIndex,1)
                                   actualCharacterRange:NULL].location effectiveRange:&lineRange];
            
            
            // Now lineRange is glyph range of the line
            // Convert lineRange(glyph range) --> lineRange(char range)
            lineRange = [layoutManager characterRangeForGlyphRange: lineRange
                                                  actualGlyphRange:NULL];
            [textView setSelectedRange:lineRange];

            break;

    }
	
	[textView scrollRangeToVisible: [textView selectedRange]];
	return YES;
}

@end
