//
//  ORScriptView.m
//  From UKSyntaxColoredDocument
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


#import "ORScriptView.h"
#import "ORLineNumberingRulerView.h"

@implementation ORScriptView

- (id)initWithFrame:(NSRect)frameRect textContainer:(NSTextContainer *)container
{
    self = [super initWithFrame:frameRect textContainer:container];
    if (self) {
		autoSyntaxColoring = YES;
		maintainIndentation = YES;
		recolorTimer = nil;
		syntaxColoringBusy = NO;
	}
    return self;
}


- (void)	dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[self setDelegate:nil];
	[recolorTimer invalidate];
	[recolorTimer release];
	[super dealloc];
}

- (void)	awakeFromNib
{	
	NSArray* typeArray = [NSArray arrayWithObject:NSStringPboardType];
	[self registerForDraggedTypes:typeArray];
	
	[[self textStorage] setDelegate:self];
	[self setUsesFindPanel:YES];
	NSScrollView* scrollView = [self enclosingScrollView];
	
	ORLineNumberingRulerView* lineNumberView = [[ORLineNumberingRulerView alloc] initWithScrollView:scrollView];
    [scrollView setVerticalRulerView:lineNumberView];
    [scrollView setHasHorizontalRuler:NO];
    [scrollView setHasVerticalRuler:YES];
    [scrollView setRulersVisible:YES];
	[lineNumberView release];
	
	autoSyntaxColoring = YES;
	maintainIndentation = YES;
	recolorTimer = nil;
	syntaxColoringBusy = NO;
	
	[self setDelegate:self];
	
	[progress setUsesThreadedAnimation:YES];
	
	[status setStringValue: @"Finished."];
	
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processEditing:)
												 name: NSTextStorageDidProcessEditingNotification
											   object: [self textStorage]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(colorsChanged:)
												 name: ORSyntaxColorChangedNotification
											   object: nil];
		
	// Put selection at top like Project Builder has it, so user sees it:
	[self setSelectedRange: NSMakeRange(0,0)];
	[self turnOffWrapping];
	[self recolorCompleteFile:nil];
	[self colorsChanged:nil];
}
- (void)mouseDown:(NSEvent *)theEvent
{
    // Start out willing to work with a double-click for delimiter-balancing;
    // see selectionRangeForProposedRange:proposedCharRange granularity: below
    inEligibleDoubleClick = YES;
    
    [super mouseDown:theEvent];
}

- (NSRange)selectionRangeForProposedRange:(NSRange)proposedCharRange
                              granularity:(NSSelectionGranularity)granularity
{
    if ((granularity == NSSelectByWord) && inEligibleDoubleClick) {
        // The proposed range has to be zero-length to qualify
        if (proposedCharRange.length == 0) {
            NSEvent*        event     = [NSApp currentEvent];
            NSEventType     eventType = [event type];
            NSTimeInterval eventTime  = [event timestamp];
            
            if (eventType == NSEventTypeLeftMouseDown) {
                // This is the mouseDown of the double-click; we do not want
                // to modify the selection here, just log the time
                doubleDownTime = eventTime;
            }
            else if (eventType == NSEventTypeLeftMouseUp) {
                // After the double-click interval since the second mouseDown,
                // the mouseUp is no longer eligible
                if (eventTime - doubleDownTime <= [NSEvent doubleClickInterval]){
                    NSString* scriptString = [[self textStorage] string];
                    NSRange   startRange = NSMakeRange(proposedCharRange.location,1);
                    NSString*          s = [scriptString substringWithRange: startRange];
                    unsigned char      c = [s characterAtIndex:0];
                    int      start = (int)startRange.location;
                    int        len = (int)[scriptString length];
                    int i;
                    int level = 0;
                    switch(c){
                        case '[':
                            for(i=start;i<len;i++){
                                NSString* s1 = [scriptString substringWithRange:NSMakeRange(i,1)];
                                if([s1 isEqualToString:@"]"]){
                                    if(level == 1)return NSMakeRange(start,i-start+1);
                                    else level--;
                                }
                                else if([s1 isEqualToString:@"["])level++;
                            }
                            break;
                            
                        case ']':
                            for(i=start;i>0;i--){
                                NSString* s1 = [scriptString substringWithRange:NSMakeRange(i,1)];
                                if([s1 isEqualToString:@"["]){
                                    if(level == 1)return NSMakeRange(i,startRange.location-i+1);
                                    else level--;
                                }
                                else if([s1 isEqualToString:@"]"])level++;
                            }
                            break;
                            
                        case '(':
                            for(i=start;i<len;i++){
                                NSString* s1 = [scriptString substringWithRange:NSMakeRange(i,1)];
                                if([s1 isEqualToString:@")"]){
                                    if(level == 1)return NSMakeRange(start,i-start+1);
                                    else level--;
                                }
                                else if([s1 isEqualToString:@"("])level++;
                            }
                            break;
                            
                        case ')':
                            for(i=start;i>0;i--){
                                NSString* s1 = [scriptString substringWithRange:NSMakeRange(i,1)];
                                if([s1 isEqualToString:@"("]){
                                    if(level == 1)return NSMakeRange(i,startRange.location-i+1);
                                    else level--;
                                }
                                else if([s1 isEqualToString:@")"])level++;
                            }
                            break;
                            
                        case '{':
                            for(i=start;i<len;i++){
                                NSString* s1 = [scriptString substringWithRange:NSMakeRange(i,1)];
                                if([s1 isEqualToString:@"}"]){
                                    if(level == 1)return NSMakeRange(start,i-start+1);
                                    else level--;
                                }
                                else if([s1 isEqualToString:@"{"])level++;
                            }
                            break;
                            
                        case '}':
                            for(i=start;i>0;i--){
                                NSString* s1 = [scriptString substringWithRange:NSMakeRange(i,1)];
                                if([s1 isEqualToString:@"{"]){
                                    if(level == 1)return NSMakeRange(i,startRange.location-i+1);
                                    else level--;
                                }
                                else if([s1 isEqualToString:@"}"])level++;
                            }
                            break;
                    }
                }
                else inEligibleDoubleClick = false;
            }
            else inEligibleDoubleClick = false;
        }
        else inEligibleDoubleClick = false;
    }
    return [super selectionRangeForProposedRange:proposedCharRange
                                     granularity:granularity];
}
- (void) colorsChanged: (NSNotification*)notification
{
	[self recolorCompleteFile:self];
	if([[[self superview] superview] isKindOfClass:[NSScrollView class]]){
		NSScrollView* enclosingView = (NSScrollView*)[[self superview] superview];
		[enclosingView setBackgroundColor:[self backgroundColor]];
		[enclosingView setNeedsDisplay:YES];
	}
}

- (void) unselectAll
{
	[self setSelectedRange: NSMakeRange(0,0)];
}

- (void) selectLine:(uint32_t)aLine
{
	NSString* originalText = [[self textStorage] string];
	NSArray* lines = [originalText componentsSeparatedByString:@"\n"];
	NSUInteger selectionStart = 0;
	NSUInteger selectionLen = [[lines objectAtIndex:aLine] length];
	NSUInteger i;
	for(i=0;i<aLine;i++){
		NSUInteger lineLen = [[lines objectAtIndex:i] length];
		selectionStart+=lineLen+1;
	}
	NSRange selectionRange = NSMakeRange(selectionStart,selectionLen);
	[self setSelectedRange: selectionRange];
	[self scrollRangeToVisible: selectionRange];
}

- (void) processEditing: (NSNotification*)notification
{
    NSTextStorage*	textStorage   = [notification object];
/*
	NSRange			range		  = [textStorage editedRange];
	int				changeInLen   = [textStorage changeInLength];
	BOOL			wasInUndoRedo = [[self undoManager] isUndoing] || [[self undoManager] isRedoing];
	BOOL			textLengthMayHaveChanged = NO;
	
	// Was delete op or undo that could have changed text length?
	if( wasInUndoRedo ){
		textLengthMayHaveChanged = YES;
		range = [self selectedRange];
	}
	
	if( changeInLen <= 0 ){
		textLengthMayHaveChanged = YES;
	}
	
	//	Try to get chars around this to recolor any identifier we're in:
	if( textLengthMayHaveChanged ){
		if( range.location > 0 ) range.location--;
		if( (range.location +range.length +2) < [textStorage length] )		range.length += 2;
		else if( (range.location +range.length +1) < [textStorage length] ) range.length += 1;
	}
	
	NSString* stringInRange = [[textStorage string] substringWithRange:range];
	if([stringInRange rangeOfString:@"*"].location != NSNotFound ||
	   [stringInRange rangeOfString:@"/"].location != NSNotFound ||
	   [stringInRange rangeOfString:@"\""].location != NSNotFound)range = NSMakeRange(0,[textStorage length]);
	
	NSRange	currRange = range;
    
	// Perform the syntax coloring:
	if( autoSyntaxColoring && range.length > 0 ) {
		NSRange	effectiveRange;		
		
		NSString* rangeMode = [textStorage attribute: TD_SYNTAX_COLORING_MODE_ATTR
											 atIndex: currRange.location
									  effectiveRange: &effectiveRange];
		
		unsigned int x = range.location;
				
		// Scan up to prev line break:
		while( x > 0 ){
			unichar theCh = [[textStorage string] characterAtIndex: x];
			if( theCh == '\n' || theCh == '\r' ) break;
			--x;
		}
		
		currRange.location = x;
		
		// Scan up to next line break:
		x = range.location + range.length;
		
		while( x < [textStorage length] ){
			unichar theCh = [[textStorage string] characterAtIndex: x];
			if( theCh == '\n' || theCh == '\r' ) break;
			++x;
		}
		
		currRange.length = x - currRange.location;
		
		// Open identifier, comment etc.? Make sure we include the whole range.
		if( rangeMode != nil ) currRange = NSMakeRange(0,[textStorage length]);
		
		// Actually recolor the changed part:
		[self recolorRange: NSMakeRange(0,[textStorage length])];
	}
 */
	//just recolor everytime. This fixes a problem with coloring when in multicomment blocks and multiline strings
	[self recolorRange: NSMakeRange(0,[textStorage length])];	
}

- (BOOL) textView:(NSTextView *)tv shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
	if( maintainIndentation && replacementString && ([replacementString isEqualToString:@"\n"] || [replacementString isEqualToString:@"\r"]) ){
		NSMutableString*			newStr = [[replacementString mutableCopy] autorelease];
		NSMutableAttributedString*  textStore = [self textStorage];
		BOOL						hadSpaces = NO;
        int				lastSpace = (int)affectedCharRange.location,
		prevLineBreak = 0;
		NSRange						spacesRange = { 0, 0 };
		unichar						theChar = 0;
        int				x;
		
		if(affectedCharRange.location>0) x = (int)affectedCharRange.location -1;
		else							 x = 0;
		
		NSString* tsString = [textStore string];
		
		while( true ){
			theChar = [tsString characterAtIndex: x];
			
			switch( theChar ){
				case '\n':
				case '\r':
					prevLineBreak = x +1;
					x = 0;  // Terminate the loop.
					break;
					
				case ' ':
				case '\t':
					if( !hadSpaces ){
						lastSpace = x;
						hadSpaces = YES;
					}
					break;
					
				default:
					hadSpaces = NO;
					break;
			}
			
			if( x == 0 )break;
			
			x--;
		}
		
		if( hadSpaces ){
			spacesRange.location = prevLineBreak;
			spacesRange.length = lastSpace -prevLineBreak +1;
			if( spacesRange.length > 0 ) {
				[newStr appendString: [tsString substringWithRange:spacesRange]];
			}
		}
		
		[textStore replaceCharactersInRange: affectedCharRange withString: newStr];
		return NO;
	}
	else return YES;
}


// -----------------------------------------------------------------------------
//	recolorCompleteFileDeferred:
//		Set a timer that waits a little and then re-colors the entire document.
//		Since this is a slow action, by using a timer, if the user types some
//		more, the recoloring will be "pushed back" until the user is finished
//		typing. This may not look quite as good, but is a compromise between
//		speed and accuracy we can sometimes take.
//------------------------------------------------------------------------------

- (IBAction) recolorCompleteFileDeferred: (id)sender
{
	// Drop any pending recalcs.
	[recolorTimer invalidate];
	[recolorTimer release];
	
	// Schedule a new timer:
	recolorTimer = [[NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(recolorSyntaxTimer:)
												   userInfo:nil repeats: NO] retain];
}

// This actually triggers the recoloring:
- (void)	recolorSyntaxTimer: (NSTimer*) sender
{
	[recolorTimer release];
	recolorTimer = nil;
	[self recolorCompleteFile: self];	// Slow. During typing we only recolor the changed parts, but sometimes we need this instead.
}

- (IBAction)	toggleAutoSyntaxColoring: (id)sender
{
	[self setAutoSyntaxColoring: ![self autoSyntaxColoring]];
	[self recolorCompleteFile: nil];
}

- (void) setAutoSyntaxColoring: (BOOL)state
{
	autoSyntaxColoring = state;
}

- (BOOL)	autoSyntaxColoring
{
	return autoSyntaxColoring;
}

- (IBAction)	toggleMaintainIndentation: (id)sender
{
	[self setMaintainIndentation: ![self maintainIndentation]];
}

- (void)	setMaintainIndentation: (BOOL)state
{
	maintainIndentation = state;
}

- (BOOL)	maintainIndentation
{
	return maintainIndentation;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    //check with the object(s) to make sure it can be dropped here.
    NSPasteboard *pb = [sender draggingPasteboard];
	return [pb stringForType:NSStringPboardType]!=nil;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pb = [sender draggingPasteboard];
    NSString* s = [pb stringForType:NSStringPboardType];
    
	if(s)return NSDragOperationCopy;
	else return NSDragOperationNone;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{	// no prep needed, but we do want to proceed...
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pb = [sender draggingPasteboard];
    NSString* s = [pb stringForType:NSStringPboardType];
	//[self insertText:s];
    NSRange insertRange = [self selectedRange];
    if(insertRange.location != NSNotFound){
        [self insertText:s replacementRange:insertRange];
    }
	return YES;
}

- (void)	goToLine: (int)lineNum
{
	NSRange			theRange = { 0, 0 };
	NSString*		vString = [self string];
	unsigned		currLine = 1;
	NSCharacterSet* vSet = [NSCharacterSet characterSetWithCharactersInString: @"\n\r"];
	int				x;
	
	for( x = 0; x < [vString length]; x++ ){
		if( ![vSet characterIsMember: [vString characterAtIndex: x]] )continue;
		
		theRange.length = x -theRange.location +1;
		if( currLine >= lineNum ) break;
		currLine++;
		theRange.location = theRange.location +theRange.length;
	}
	
    [status setStringValue: [NSString stringWithFormat: @"Characters %lu to %lu", theRange.location +1, theRange.location +theRange.length]];
	[self scrollRangeToVisible: theRange];
	[self setSelectedRange: theRange];
}

- (void) turnOffWrapping
{
	const float			LargeNumberForText	= 1.0e7;
	NSTextContainer*	textContainer		= [self textContainer];
	NSScrollView*		scrollView			= [self enclosingScrollView];
	NSRect				frame;
	
	// Make sure we can see right edge of line:
    [scrollView setHasHorizontalScroller:YES];
	
	// Make text container so wide it won't wrap:
	[textContainer setContainerSize: NSMakeSize(LargeNumberForText, LargeNumberForText)];
	[textContainer setWidthTracksTextView:  NO];
    [textContainer setHeightTracksTextView: NO];
	
	// Make sure text view is wide enough:
	frame.origin = NSMakePoint(0.0, 0.0);
    frame.size	 = [scrollView contentSize];
	
    [self setMaxSize:NSMakeSize(LargeNumberForText, LargeNumberForText)];
    [self setHorizontallyResizable:YES];
    [self setVerticallyResizable:YES];
    [self setAutoresizingMask:NSViewNotSizable];
}

- (BOOL) validateMenuItem:(NSMenuItem*)menuItem
{
	NSRange	theSelection = [self selectedRange];
	if ([menuItem action] == @selector(shiftLeft:)) {
        if(theSelection.length>0)return YES;
        else return NO;
    }
    else if ([menuItem action] == @selector(shiftRight:)) {
        if(theSelection.length>0)return YES;
        else return NO;
    }    
	else return [super validateMenuItem: menuItem];
}

// -----------------------------------------------------------------------------
//	recolorCompleteFile:
//		IBAction to do a complete recolor of the whole friggin' document.
//		This is called once after the document's been loaded and leaves some
//		custom styles in the document which are used by recolorRange to properly
//		perform recoloring of parts.
// -----------------------------------------------------------------------------
- (IBAction) recolorCompleteFile: (id)sender
{
	NSRange	range = NSMakeRange(0,[[self textStorage] length]);
	[self recolorRange: range];
}

//-----------------------------------------------------------------------------
//	recolorRange:
//		Try to apply syntax coloring to the text in our text view. This
//		overwrites any styles the text may have had before. This function
//		guarantees that it'll preserve the selection.
//		
//		Note that the order in which the different things are colorized is
//		important. E.g. identifiers go first, followed by comments, since that
//		way colors are removed from identifiers inside a comment and replaced
//		with the comment color, etc. 
//		
//		To make this more flexible, we might want to change this to work with
//		a syntax dictionary that contains start/end strings for multi-line
//		comments etc. Some of the things we may want to make adjustable have
//		already been moved out into separate variables, but some haven't.
//		
//		The range passed in here is special, and may not include partial
//		identifiers or the end of a comment. Make sure you include the entire
//		multi-line comment etc. or it'll lose color.
//--------------------------------------------------------------------------

- (void) recolorRange: (NSRange)range
{
 	if( syntaxColoringBusy ) return;			 // Prevent endless loop when recoloring's replacement of text causes processEditing to fire again.
	
	
	if( range.length == 0 || recolorTimer )	{    // don't recolor partially if a full recolorization is pending.
		return;
	}
	[[(ORAppDelegate*)[NSApp delegate] undoManager] disableUndoRegistration];
	@try {
		syntaxColoringBusy = YES;
		[progress startAnimation:nil];
		
		[status setStringValue: [NSString stringWithFormat: @"Recoloring syntax in %@", NSStringFromRange(range)]];
		
		// Get the text we'll be working with:
		//NSRange						vOldSelection = [self selectedRange];
		
		NSMutableAttributedString*	vString		  = [[NSMutableAttributedString alloc] initWithString: [[[self textStorage] string] substringWithRange: range]];
		[vString autorelease];
		
		// The following should probably be loaded from a dictionary in some file, to allow adaptation to various languages:
		NSDictionary*				vSyntaxDefinition	 = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource: [self syntaxDefinitionFilename] ofType:@"plist"]];
		NSString*					vBlockCommentStart	 = [vSyntaxDefinition objectForKey: @"BlockComment:Start"];
		NSString*					vBlockCommentEnd	 = [vSyntaxDefinition objectForKey: @"BlockComment:End"];
		NSString*					vOneLineCommentStart = [vSyntaxDefinition objectForKey: @"OneLineComment:Start"];
		
		//Script editer... Load colors to use from preferences:
		[self setBackgroundColor: colorForData([[NSUserDefaults standardUserDefaults] objectForKey: ORScriptBackgroundColor])];
		NSColor*					vCommentColor		= colorForData([[NSUserDefaults standardUserDefaults] objectForKey: ORScriptCommentColor]);
		NSColor*					vStringColor		= colorForData([[NSUserDefaults standardUserDefaults] objectForKey: ORScriptStringColor]);
		NSColor*					vIdentifier1Color	= colorForData([[NSUserDefaults standardUserDefaults] objectForKey: ORScriptIdentifier1Color]);
		NSColor*					vIdentifier2Color	= colorForData([[NSUserDefaults standardUserDefaults] objectForKey: ORScriptIdentifier2Color]);
		NSColor*					vConstantsColor	    = colorForData([[NSUserDefaults standardUserDefaults] objectForKey: ORScriptConstantsColor]);
		NSDictionary*				vStyles				= [NSDictionary dictionaryWithObject: [NSFont fontWithName:@"Monaco" size:10.0] forKey: NSFontAttributeName];
		
		// Color identifiers listed in identifiers1.txt:
		NSCharacterSet*	vIdentCharset		 = [NSCharacterSet characterSetWithCharactersInString: [vSyntaxDefinition objectForKey: @"Identifiers:Charset"]];
		NSString*		vCurrIdent;
		NSArray*		vIdents = [vSyntaxDefinition objectForKey: @"Identifiers1"];
		NSEnumerator*	vItty	= [vIdents objectEnumerator];
		while( vCurrIdent = [vItty nextObject] ){
			[self colorIdentifier:vCurrIdent inString:vString withColor:vIdentifier1Color andMode:TD_IDENTIFIER1_ATTR charset:vIdentCharset];
		}
		
		
		// Color identifiers listed in identifiers2.txt:
		vIdents = [vSyntaxDefinition objectForKey: @"Identifiers2"];
		vItty	= [vIdents objectEnumerator];
		while( vCurrIdent = [vItty nextObject] ){
			[self colorIdentifier:vCurrIdent inString:vString withColor:vIdentifier2Color andMode:TD_IDENTIFIER2_ATTR charset:vIdentCharset];
		}
		
		// Color constants listed in constants.txt:
		vIdents = [vSyntaxDefinition objectForKey: @"Constants"];
		vItty	= [vIdents objectEnumerator];
		while( vCurrIdent = [vItty nextObject] ){
			[self colorIdentifier:vCurrIdent inString:vString withColor:vConstantsColor andMode:TD_CONSTANTS_ATTR charset:vIdentCharset];
		}
		
		// Colorize comments, strings etc, obliterating any identifiers inside them:
		[self colorStringsFrom: @"\"" to: @"\"" inString: vString withColor: vStringColor andMode: TD_DOUBLE_QUOTED_STRING_ATTR];   // Strings.
		
		// Comments:
		[self colorOneLineComment: vOneLineCommentStart inString: vString withColor: vCommentColor andMode: TD_ONE_LINE_COMMENT_ATTR];
		[self colorCommentsFrom: vBlockCommentStart to: vBlockCommentEnd inString: vString withColor:vCommentColor andMode: TD_MULTI_LINE_COMMENT_ATTR];
		
		// Replace the range with our recolored part:
		[vString addAttributes: vStyles range: NSMakeRange( 0, [vString length] )];
		[[self textStorage] replaceCharactersInRange: range withAttributedString: vString];
		
		@try {
			//			[self setSelectedRange:vOldSelection];  // Restore selection.
		}
		@catch(NSException* localException) {
		}
		
		[progress stopAnimation:nil];
		syntaxColoringBusy = NO;
	}
	@catch(NSException* localException) {
		syntaxColoringBusy = NO;
		[progress stopAnimation:nil];
		//[localException raise];
	}
	[[(ORAppDelegate*)[NSApp delegate] undoManager] enableUndoRegistration];
}


//-----------------------------------------------------------------------------
//	textView:willChangeSelectionFromCharacterRange:toCharacterRange:
//		Delegate method called when our selection changes. Updates our status
//		display to indicate which characters are selected.
//-----------------------------------------------------------------------------
- (NSRange)  textView: (NSTextView*)textView willChangeSelectionFromCharacterRange: (NSRange)oldSelectedCharRange
	 toCharacterRange:(NSRange)newSelectedCharRange
{
	[status setStringValue: [NSString stringWithFormat: @"Selected char %lu to %lu",
							 newSelectedCharRange.location +1,
							 newSelectedCharRange.location +newSelectedCharRange.length]];
	
	// TODO: Also display line number in status line.
	
	return newSelectedCharRange;
}


//-----------------------------------------------------------------------------
//	syntaxDefinitionFilename:
//		Like windowNibName, this should return the name of the syntax
//		definition file to use. Advanced users may use this to allow different
//		coloring to take place depending on the file extension by returning
//		different file names here.
//		
//		Note that the ".plist" extension is automatically appended to the file
//		name.
//-----------------------------------------------------------------------------

- (NSString*)	syntaxDefinitionFilename
{
	if(!syntaxDefinitionFilename)return @"SyntaxDefinition";
	else return syntaxDefinitionFilename;
}

- (void) setSyntaxDefinitionFilename:(NSString*)aFileName
{
    [syntaxDefinitionFilename release];
    syntaxDefinitionFilename = [aFileName copy];	
}

//-----------------------------------------------------------------------------
//	colorStringsFrom:
//		Apply syntax coloring to all strings. This is basically the same code
//		as used for multi-line comments, except that it ignores the end
//		character if it is preceded by a backslash.
// ----------------------------------------------------------------------------

- (void)	colorStringsFrom: (NSString*) startCh to: (NSString*) endCh inString: (NSMutableAttributedString*) s
				withColor: (NSColor*) col andMode:(NSString*)attr
{
	@try {
		NSScanner*					vScanner = [NSScanner scannerWithString: [s string]];
		NSDictionary*				vStyles = [NSDictionary dictionaryWithObjectsAndKeys:
											   col, NSForegroundColorAttributeName,
											   attr, TD_SYNTAX_COLORING_MODE_ATTR,
											   nil];
		BOOL						vIsEndChar = NO;
		BOOL						justExtit = NO;
		while( ![vScanner isAtEnd] ){
			uint32_t		vStartOffs,vEndOffs;
			vIsEndChar = NO;
			
			// Look for start of string:
			[vScanner scanUpToString: startCh intoString: nil];
			vStartOffs = (int)[vScanner scanLocation];
			if( ![vScanner scanString:startCh intoString:nil] ) {
				break;
			}
			while( !vIsEndChar && ![vScanner isAtEnd] )	{  // Loop until we find end-of-string marker or our text to color is finished:
				[vScanner scanUpToString: endCh intoString: nil];
				uint32_t x = (uint32_t)[vScanner scanLocation] -1;
				
				if( [[s string] characterAtIndex: x] != '\\' )	// Backslash before the end marker? That means ignore the end marker.
					vIsEndChar = YES;	// A real one! Terminate loop.
				if( ![vScanner scanString:endCh intoString:nil] ){	// But skip this char before that.
					justExtit = YES;
					break;
					//NS_VOIDRETURN;
				}
			}
			
			vEndOffs = (uint32_t)[vScanner scanLocation];
			
			// Now mess with the string's styles:
			[s setAttributes: vStyles range: NSMakeRange( vStartOffs, vEndOffs -vStartOffs )];
			if(justExtit)break;
		}
	}
	@catch(NSException* localException) {
		// Just ignore it, syntax coloring isn't that important.
	}
}


//----------------------------------------------------------------------------
//	colorCommentsFrom:
//		Try to apply syntax coloring to the text in our text view. This
//		overwrites any styles the text may have had before. This colorizes
//		the entire text and is not suited for parsing sub-ranges. As such, it
//		is mainly intended for colorizing syntax at startup when a new document
//		is opened.
//		
//		This function guarantees that it'll preserve the selection.
// ---------------------------------------------------------------------------

- (void)	colorCommentsFrom: (NSString*) startCh to: (NSString*) endCh inString: (NSMutableAttributedString*) s
				 withColor: (NSColor*) col andMode:(NSString*)attr
{
	@try {
		NSScanner*					vScanner = [NSScanner scannerWithString: [s string]];
		NSDictionary*				vStyles = [NSDictionary dictionaryWithObjectsAndKeys:
											   col, NSForegroundColorAttributeName,
											   attr, TD_SYNTAX_COLORING_MODE_ATTR,
											   nil];
		
		while( ![vScanner isAtEnd] ){			
			// Look for start of multi-line comment:
			[vScanner scanUpToString: startCh intoString: nil];
			NSUInteger vStartOffs = [vScanner scanLocation];
			if( ![vScanner scanString:startCh intoString:nil] )
				break;
			
			// Look for associated end-of-comment marker:
			[vScanner scanUpToString: endCh intoString: nil];
			if( ![vScanner scanString:endCh intoString:nil] )break;
			NSUInteger vEndOffs = [vScanner scanLocation];
			
			// Now mess with the string's styles:
			[s setAttributes: vStyles range: NSMakeRange( vStartOffs, vEndOffs -vStartOffs )];
        
		}
	}
	@catch(NSException* localException) {
		// Just ignore it, syntax coloring isn't that important.
	}
}

- (void)	colorOneLineComment: (NSString*) startCh inString: (NSMutableAttributedString*) s
				   withColor: (NSColor*) col andMode:(NSString*)attr
{
	@try {
		NSScanner*					vScanner = [NSScanner scannerWithString: [s string]];
		NSDictionary*				vStyles = [NSDictionary dictionaryWithObjectsAndKeys:
											   col, NSForegroundColorAttributeName,
											   attr, TD_SYNTAX_COLORING_MODE_ATTR,
											   nil];
		
		while( ![vScanner isAtEnd] ) {
			NSUInteger		vStartOffs,
			vEndOffs;
			
			// Look for start of one-line comment:
			[vScanner scanUpToString: startCh intoString: nil];
			vStartOffs = [vScanner scanLocation];
			if( ![vScanner scanString:startCh intoString:nil] )break;
			
			// Look for associated line break:
			[vScanner skipUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString: @"\n\r"]];
			
			vEndOffs = [vScanner scanLocation];
			
			// Now mess with the string's styles:
			[s setAttributes: vStyles range: NSMakeRange( vStartOffs, vEndOffs -vStartOffs )];
			
		}
	}
	@catch(NSException* localException) {
		// Just ignore it, syntax coloring isn't that important.
	}
}


- (void)	colorIdentifier: (NSString*) ident inString: (NSMutableAttributedString*) s
			   withColor: (NSColor*) col andMode:(NSString*)attr charset: (NSCharacterSet*)cset
{
	@try {
		NSScanner*					vScanner = [NSScanner scannerWithString: [s string]];
		NSDictionary*				vStyles = [NSDictionary dictionaryWithObjectsAndKeys:
											   col, NSForegroundColorAttributeName,
											   attr, TD_SYNTAX_COLORING_MODE_ATTR,
											   nil];
		
		
		NSUInteger							vStartOffs = 0;
		
		[vScanner setCaseSensitive:YES];
		
		// Skip any leading whitespace chars, somehow NSScanner doesn't do that:
		while( vStartOffs < [[s string] length] ){
			if( [cset characterIsMember: [[s string] characterAtIndex: vStartOffs]] )break;
			vStartOffs++;
		}
		
		[vScanner setScanLocation: vStartOffs];
		
		while( ![vScanner isAtEnd] ){
			// Look for start of identifier:
			[vScanner scanUpToString: ident intoString: nil];
			vStartOffs = [vScanner scanLocation];
			if( ![vScanner scanString:ident intoString:nil] )  break;
			
			if( vStartOffs > 0 ) {	// Check that we're not in the middle of an identifier:
				// Alphanum character before identifier start?
				if( [cset characterIsMember: [[s string] characterAtIndex: (vStartOffs -1)]] ) continue;
			}
			
			if( (vStartOffs +[ident length] +1) < [s length] ){
				// Alphanum character following our identifier?
				if( [cset characterIsMember: [[s string] characterAtIndex: (vStartOffs +[ident length])]] ) continue;
			}
			
			// Now mess with the string's styles:
			[s setAttributes: vStyles range: NSMakeRange( vStartOffs, [ident length] )];
			
		}
		
	}
	@catch(NSException* localException) {
		// Just ignore it, syntax coloring isn't that important.
	}
}

- (IBAction) shiftLeft:(id)sender
{
	NSString* originalText = [[self textStorage] string];
	NSRange	theSelection   = [self selectedRange];
	NSRange paragraphRange = [self selectionRangeForProposedRange:theSelection granularity:NSSelectByParagraph];
	NSArray* lines = [[originalText substringWithRange:paragraphRange] componentsSeparatedByString:@"\n"];
	NSMutableArray* newLines = [NSMutableArray array];
	NSEnumerator* e = [lines objectEnumerator];
	NSString* s;
	BOOL changed = NO;
	while(s = [e nextObject]){
		if([s hasPrefix:@" "] || [s hasPrefix:@"\t"]){
			[newLines addObject:[s substringFromIndex:1]];
			changed = YES;
		}
		else [newLines addObject:s];
	}
	s = [newLines componentsJoinedByString:@"\n"];
	if(changed && [self shouldChangeTextInRange:paragraphRange replacementString:s]){
		[self replaceCharactersInRange:paragraphRange withString:s];
		[self setSelectedRange:NSMakeRange(paragraphRange.location,[s length])];
		[self didChangeText];
	}
}

- (IBAction) shiftRight:(id)sender
{
	NSString* originalText = [[self textStorage] string];
	NSRange	theSelection   = [self selectedRange];
	
	NSRange paragraphRange = [self selectionRangeForProposedRange:theSelection granularity:NSSelectByParagraph];
	NSArray* lines = [[originalText substringWithRange:paragraphRange] componentsSeparatedByString:@"\n"];
	NSMutableArray* newLines = [NSMutableArray array];
	NSEnumerator* e = [lines objectEnumerator];
	NSString* s;
	while(s = [e nextObject]){
		s = [@"\t" stringByAppendingString:s];
		[newLines addObject:s];
	}
	s = [newLines componentsJoinedByString:@"\n"];
	s = [s substringToIndex:[s length]-1];
	if([self shouldChangeTextInRange:paragraphRange replacementString:s]){
		[self replaceCharactersInRange:paragraphRange withString:s];
		[self setSelectedRange:NSMakeRange(paragraphRange.location,[s length]-1)];
		[self didChangeText];
	}
}

- (BOOL) breakPointAtLine:(NSUInteger)aLineNumber
{
	NSScrollView* scrollView = [self enclosingScrollView];
	id theRuler = [scrollView verticalRulerView];
	if([ORLineNumberingRulerView isKindOfClass:[ORLineNumberingRulerView class]]){
		return [(ORLineNumberingRulerView*)theRuler markerAtLine:aLineNumber] != nil;
	}
	else return NO;
}

- (IBAction) prettify:(id)sender
{
	NSString* originalText = [[self textStorage] string];
	NSRange	theSelection   = [self selectedRange];
	BOOL wasSelection = YES;
	if(theSelection.length == 0){
		theSelection = NSMakeRange(0,[originalText length]);
		wasSelection = NO;
	}
	NSRange paragraphRange = [self selectionRangeForProposedRange:theSelection granularity:NSSelectByParagraph];
	NSArray* lines = [[originalText substringWithRange:paragraphRange] componentsSeparatedByString:@"\n"];
	//step one -- remove all leading tabs and spaces
	NSMutableArray* newLines = [NSMutableArray array];
	int level = 0;
    BOOL inCaseBlock = NO;
	for(NSString* s in lines){
		while([s hasPrefix:@" "] || [s hasPrefix:@"\t"]){
			s = [s stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:@""];
		} 
		NSMutableString* tabs = [NSMutableString stringWithString:@""];
		int i;
		for(i=0;i<level;i++)[tabs insertString:@"\t" atIndex:0];
		s = [s stringByReplacingCharactersInRange:NSMakeRange(0,0) withString:tabs];
        if(([s rangeOfString:@"{"].location != NSNotFound) &&
           ([s rangeOfString:@"}"].location == NSNotFound)) {
            level++;
            inCaseBlock = NO;
        }
        else if(([s rangeOfString:@"case"].location    != NSNotFound) ||
                ([s rangeOfString:@"default"].location != NSNotFound)){
            if([s rangeOfString:@"break"].location   == NSNotFound){
                level++;
               inCaseBlock = YES;
            }
        }
        if(([s rangeOfString:@"}"].location != NSNotFound) &&
           ([s rangeOfString:@"{"].location == NSNotFound)){
            inCaseBlock = NO;

            level--;
            if(level<0)level=0;
            if([s hasPrefix:@"\t"])	s = [s stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:@""];
        }
        else if([s rangeOfString:@"break;"].location != NSNotFound && inCaseBlock){
            inCaseBlock = NO;
            level--;
            if(level<0)level=0;
            if([s hasPrefix:@"\t"])	s = [s stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:@""];
        }
		[newLines addObject:s];
	}
    NSString* s;
	s = [newLines componentsJoinedByString:@"\n"];
	s = [s substringToIndex:[s length]];
	//put the text back
	if([self shouldChangeTextInRange:paragraphRange replacementString:s]){
		[self replaceCharactersInRange:paragraphRange withString:s];
		if(wasSelection)[self setSelectedRange:NSMakeRange(paragraphRange.location,[s length]-1)];
		[self didChangeText];
	}
}



@end
