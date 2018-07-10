/*
        TextFinder.m
        Copyright (c) 1995-2002 by Apple Computer, Inc., all rights reserved.
        Author: Ali Ozer

        Find and replace functionality with a minimal panel...
        Would be nice to have the buttons in the panel validate; this would allow the 
            replace buttons to become disabled for readonly docs
*/
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

#import "TextFinder.h"
#import "SynthesizeSingleton.h"

@interface NSString (NSStringTextFinding)

- (NSRange)findString:(NSString *)string selectedRange:(NSRange)selectedRange options:(NSUInteger)mask wrap:(BOOL)wrapFlag;

@end

@implementation TextFinder

SYNTHESIZE_SINGLETON_FOR_CLASS(TextFinder);

- (id) init 
{
    if (!(self = [super init])) return nil;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidActivate:) name:NSApplicationDidBecomeActiveNotification object:[NSApplication sharedApplication]];

    [self setFindString:@"" writeToPasteboard:NO];
    [self loadFindStringFromPasteboard];

    return self;
}

- (void) appDidActivate:(NSNotification *)notification {
    [self loadFindStringFromPasteboard];
}

- (void) loadFindStringFromPasteboard 
{
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];
    if ([[pasteboard types] containsObject:NSStringPboardType]) {
        NSString *string = [pasteboard stringForType:NSStringPboardType];
        if (string && [string length]) {
            [self setFindString:string writeToPasteboard:NO];
        }
    }
}

- (void) loadFindStringToPasteboard 
{
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];
    [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    [pasteboard setString:[self findString] forType:NSStringPboardType];
}

- (void) loadUI 
{
    if (!findTextField) {
#if !defined(MAC_OS_X_VERSION_10_9)
        if (![NSBundle loadNibNamed:@"FindPanel" owner:self]){
#else
            if (![[NSBundle mainBundle] loadNibNamed:@"FindPanel" owner:self topLevelObjects:&topLevelObjects]){
#endif
        
            NSLog(@"Failed to load FindPanel.nib");
            NSBeep();
        }
        [topLevelObjects retain];

		if (self == sharedTextFinder) [[findTextField window] setFrameAutosaveName:@"Find"];
    }
    [findTextField setStringValue:[self findString]];
}

- (void) dealloc 
{
    //should never get here.. We are a singleton.
    if (self != sharedTextFinder) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [findString release];
        [super dealloc];
    }
}

- (NSString*) findString 
{
    return findString;
}

- (void) setFindString:(NSString *)string 
{
    [self setFindString:string writeToPasteboard:YES];
}

- (void) setFindString:(NSString *)string writeToPasteboard:(BOOL)flag {
    if ([string isEqualToString:findString]) return;
    [findString autorelease];
    findString = [string copyWithZone:[self zone]];
    if (findTextField) {
        [findTextField setStringValue:string];
        [findTextField selectText:nil];
    }
    if (flag) [self loadFindStringToPasteboard];
}

- (NSTextView*) textObjectToSearchIn {
    id obj = [[NSApp mainWindow] firstResponder];
    return (obj && [obj isKindOfClass:[NSTextView class]]) ? obj : nil;
}

- (NSPanel*) findPanel 
{
    if (!findTextField) [self loadUI];
    return (NSPanel *)[findTextField window];
}

/* The primitive for finding; this ends up setting the status field (and beeping if necessary)...
*/
- (BOOL) find:(BOOL)direction 
{
    NSTextView *text = [self textObjectToSearchIn];
    lastFindWasSuccessful = NO;
    if (text) {
        NSString *textContents = [text string];
        if (textContents && [textContents length]) {
            NSRange range;
            unsigned options = 0;
			if (direction == Backward) options |= NSBackwardsSearch;
            if (!ignoreCaseButton || [ignoreCaseButton state]) options |= NSCaseInsensitiveSearch;
            range = [textContents findString:[self findString] selectedRange:[text selectedRange] options:options wrap:YES];
            if (range.length) {
                [text setSelectedRange:range];
                [text scrollRangeToVisible:range];
                lastFindWasSuccessful = YES;
            }
        }
    }
    if (!lastFindWasSuccessful) {
        NSBeep();
        [statusField setStringValue:NSLocalizedStringFromTable(@"Not found", @"FindPanel", @"Status displayed in find panel when the find string is not found.")];
    } 
	else {
        [statusField setStringValue:@""];
    }
    return lastFindWasSuccessful;
}

- (void) orderFrontFindPanel:(id)sender 
{
	//commit all text editing... subclasses should call before doing their work.
	id oldFirstResponder = [[NSApp mainWindow] firstResponder];
	if(![[NSApp mainWindow] makeFirstResponder:[NSApp mainWindow]]){
		[[NSApp mainWindow] endEditingFor:nil];		
	}
	[[NSApp mainWindow] makeFirstResponder:oldFirstResponder];

    NSPanel *panel = [self findPanel];
    [findTextField selectText:nil];
    [panel makeKeyAndOrderFront:nil];
}

/**** Action methods for gadgets in the find panel; these should all end up setting or clearing the status field ****/

- (void) findNextAndOrderFindPanelOut:(id)sender {
    [findNextButton performClick:nil];
    if (lastFindWasSuccessful) {
        [[self findPanel] orderOut:sender];
    } 
	else {
		[findTextField selectText:nil];
    }
}

- (void) findNext:(id)sender {
    if (findTextField) [self setFindString:[findTextField stringValue]];	/* findTextField should be set */
    [self find:Forward];
}

- (void) findPrevious:(id)sender {
    if (findTextField) [self setFindString:[findTextField stringValue]];	/* findTextField should be set */
    [self find:Backward];
}

- (void) replace:(id)sender {
    NSTextView *text = [self textObjectToSearchIn];
    // shouldChangeTextInRange:... should return NO if !isEditable, but doesn't...
    if (text && [text isEditable] && [text shouldChangeTextInRange:[text selectedRange] replacementString:[replaceTextField stringValue]]) {
        [[text textStorage] replaceCharactersInRange:[text selectedRange] withString:[replaceTextField stringValue]];
        [text didChangeText];
    } else {
        NSBeep();
    }
    [statusField setStringValue:@""];
}

- (void) replaceAndFind:(id)sender {
    [self replace:sender];
    [self findNext:sender];
}

#define ReplaceAllScopeEntireFile 42
#define ReplaceAllScopeSelection 43

/* The replaceAll: code is somewhat complex.  One reason for this is to support undo well --- To play along with the undo mechanism in the text object, this method goes through the shouldChangeTextInRange:replacementString: mechanism. In order to do that, it precomputes the section of the string that is being updated. An alternative would be for this method to handle the undo for the replaceAll: operation itself, and register the appropriate changes. However, this is simpler...

Turns out this approach of building the new string and inserting it at the appropriate place in the actual text storage also has an added benefit of performance; it avoids copying the contents of the string around on every replace, which is significant in large files with many replacements. Of course there is the added cost of the temporary replacement string, but we try to compute that as tightly as possible beforehand to reduce the memory requirements.
*/
- (void) replaceAll:(id)sender {
    NSTextView *text = [self textObjectToSearchIn];
    if (!text || ![text isEditable]) {
	[statusField setStringValue:@""];
        NSBeep();
    } else {
        NSTextStorage *textStorage = [text textStorage];
        NSString *textContents = [text string];
        BOOL entireFile = replaceAllScopeMatrix ? ([replaceAllScopeMatrix selectedTag] == ReplaceAllScopeEntireFile) : YES;
        NSRange replaceRange = entireFile ? NSMakeRange(0, [textStorage length]) : [text selectedRange];
        unsigned searchOption = ((!ignoreCaseButton || [ignoreCaseButton state]) ? NSCaseInsensitiveSearch : 0);
        unsigned replaced = 0;
        NSRange firstOccurence;
        
        if (findTextField) [self setFindString:[findTextField stringValue]];

        // Find the first occurence of the string being replaced; if not found, we're done!
        firstOccurence = [textContents rangeOfString:[self findString] options:searchOption range:replaceRange];
        if (firstOccurence.length > 0) {
	    NSAutoreleasePool *pool;
            NSString *targetString = [self findString];
	    NSString *replaceString = [replaceTextField stringValue];
            NSMutableAttributedString *temp;	/* This is the temporary work string in which we will do the replacements... */
            NSRange rangeInOriginalString;	/* Range in the original string where we do the searches */

	    // Find the last occurence of the string and union it with the first occurence to compute the tightest range...
            rangeInOriginalString = replaceRange = NSUnionRange(firstOccurence, [textContents rangeOfString:targetString options:NSBackwardsSearch|searchOption range:replaceRange]);

            temp = [[NSMutableAttributedString alloc] init];

            [temp beginEditing];

	    // The following loop can execute an unlimited number of times, and it could have autorelease activity.
	    // To keep things under control, we use a pool, but to be a bit efficient, instead of emptying everytime through
	    // the loop, we do it every so often. We can only do this as long as autoreleased items are not supposed to
	    // survive between the invocations of the pool!

    	    pool = [[NSAutoreleasePool alloc] init];

            while (rangeInOriginalString.length > 0) {
                NSRange foundRange = [textContents rangeOfString:targetString options:searchOption range:rangeInOriginalString];
                if (foundRange.length == 0) {
                    [temp appendAttributedString:[textStorage attributedSubstringFromRange:rangeInOriginalString]];	// Copy the remainder
                    rangeInOriginalString.length = 0;	// And signal that we're done
                } else {
                    NSRange rangeToCopy = NSMakeRange(rangeInOriginalString.location, foundRange.location - rangeInOriginalString.location + 1);	// Copy upto the start of the found range plus one char (to maintain attributes with the overlap)...
                    [temp appendAttributedString:[textStorage attributedSubstringFromRange:rangeToCopy]];
                    [temp replaceCharactersInRange:NSMakeRange([temp length] - 1, 1) withString:replaceString];
                    rangeInOriginalString.length -= NSMaxRange(foundRange) - rangeInOriginalString.location;
                    rangeInOriginalString.location = NSMaxRange(foundRange);
                    replaced++;
                    if (replaced % 100 == 0) {	// Refresh the pool... See warning above!
                        [pool release];
                        pool = [[NSAutoreleasePool alloc] init];
                    }
                }
            }

	    [pool release];

            [temp endEditing];

	    // Now modify the original string
            if ([text shouldChangeTextInRange:replaceRange replacementString:[temp string]]) {
                [textStorage replaceCharactersInRange:replaceRange withAttributedString:temp];
                [text didChangeText];
            } else {	// For some reason the string didn't want to be modified. Bizarre...
                replaced = 0;
            }

            [temp release];
        }
        if (replaced == 0) {
            NSBeep();
            [statusField setStringValue:NSLocalizedStringFromTable(@"Not found", @"FindPanel", @"Status displayed in find panel when the find string is not found.")];
        } else {
            [statusField setStringValue:[NSString localizedStringWithFormat:NSLocalizedStringFromTable(@"%d replaced", @"FindPanel", @"Status displayed in find panel when indicated number of matches are replaced."), replaced]];
        }
    }
}

- (void) takeFindStringFromSelection:(id)sender {
    NSTextView *textView = [self textObjectToSearchIn];
    if (textView) {
        NSString *selection = [[textView string] substringWithRange:[textView selectedRange]];
        [self setFindString:selection];
    }
}

- (void)  jumpToSelection:sender {
    NSTextView *textView = [self textObjectToSearchIn];
    if (textView) {
        [textView scrollRangeToVisible:[textView selectedRange]];
    }
}


- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{

    if ([anItem action] == @selector(orderFrontFindPanel:)) {
        return ([self textObjectToSearchIn] != NULL);
    }
    if ([anItem action] == @selector(findNext:)) {
        return ([self textObjectToSearchIn] != NULL);
    }
    if ([anItem action] == @selector(findPrevious:)) {
        return ([self textObjectToSearchIn] != NULL);
    }
    if ([anItem action] == @selector(takeFindStringFromSelection:)) {
        return ([self textObjectToSearchIn] != NULL);
    }
    if ([anItem action] == @selector(jumpToSelection:)) {
        return ([self textObjectToSearchIn] != NULL);
    }
    // if it isn't one of our menu items, we'll let the
    // superclass take care of it
    return [super validateMenuItem:anItem];
}
@end


@implementation NSString (NSStringTextFinding)

- (NSRange) findString:(NSString *)string selectedRange:(NSRange)selectedRange options:(NSUInteger)options wrap:(BOOL)wrap {
    BOOL forwards = (options & NSBackwardsSearch) == 0;
    unsigned length = [self length];
    NSRange searchRange, range;

    if (forwards) {
	searchRange.location = NSMaxRange(selectedRange);
	searchRange.length = length - searchRange.location;
	range = [self rangeOfString:string options:options range:searchRange];
        if ((range.length == 0) && wrap) {	/* If not found look at the first part of the string */
	    searchRange.location = 0;
            searchRange.length = selectedRange.location;
            range = [self rangeOfString:string options:options range:searchRange];
        }
    } else {
	searchRange.location = 0;
	searchRange.length = selectedRange.location;
        range = [self rangeOfString:string options:options range:searchRange];
        if ((range.length == 0) && wrap) {
            searchRange.location = NSMaxRange(selectedRange);
            searchRange.length = length - searchRange.location;
            range = [self rangeOfString:string options:options range:searchRange];
        }
    }
    return range;
}        

@end
