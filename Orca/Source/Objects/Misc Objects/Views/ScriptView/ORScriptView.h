//
//  ORScriptView.h
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


// Attribute constants added along with styles to program text:
#define	TD_MULTI_LINE_COMMENT_ATTR			@"SyntaxColoring:MultiLineComment"
#define	TD_ONE_LINE_COMMENT_ATTR			@"SyntaxColoring:OneLineComment"
#define	TD_DOUBLE_QUOTED_STRING_ATTR		@"SyntaxColoring:DoubleQuotedString"
#define	TD_SINGLE_QUOTED_STRING_ATTR		@"SyntaxColoring:SingleQuotedString"
#define	TD_IDENTIFIER1_ATTR					@"SyntaxColoring:Identifier1"
#define	TD_IDENTIFIER2_ATTR					@"SyntaxColoring:Identifier2"
#define	TD_CONSTANTS_ATTR					@"SyntaxColoring:Constants"

#define TD_SYNTAX_COLORING_MODE_ATTR		@"UKTextDocumentSyntaxColoringMode"

@interface ORScriptView : NSTextView <NSTextViewDelegate,NSTextStorageDelegate>
{
	IBOutlet NSProgressIndicator*	progress;				// Progress indicator while coloring syntax.
	IBOutlet NSTextField*			status;					// Status display for things like syntax coloring or background syntax checks.
	BOOL							autoSyntaxColoring;		// Automatically refresh syntax coloring when text is changed?
	BOOL							maintainIndentation;	// Keep new lines indented at same depth as their predecessor?
	NSTimer*						recolorTimer;			// Timer used to do the actual recoloring a little while after the last keypress.
	BOOL							syntaxColoringBusy;		// Set while recolorRange is busy, so we don't recursively call recolorRange.
	NSString*						syntaxDefinitionFilename;
    BOOL inEligibleDoubleClick;
    NSTimeInterval doubleDownTime;
    
}

- (IBAction) recolorCompleteFile: (id)sender;
- (IBAction) recolorCompleteFileDeferred: (id)sender;
- (IBAction) toggleAutoSyntaxColoring: (id)sender;
- (IBAction) toggleMaintainIndentation: (id)sender;
- (IBAction) shiftLeft:(id)sender;
- (IBAction) shiftRight:(id)sender;
- (IBAction) prettify:(id)sender;

- (void)	 setAutoSyntaxColoring: (BOOL)state;
- (BOOL)	 autoSyntaxColoring;

- (void)	 setMaintainIndentation: (BOOL)state;
- (BOOL)	 maintainIndentation;

- (void)	 goToLine: (int)lineNum;
- (void)	 unselectAll;
- (void)	 selectLine:(unsigned long)aLine;

- (NSString*) syntaxDefinitionFilename;
- (void) setSyntaxDefinitionFilename:(NSString*)aFileName;

- (void) colorsChanged: (NSNotification*)notification;
- (void) processEditing: (NSNotification*)notification;
- (void) turnOffWrapping;
- (void) recolorRange: (NSRange) range;
- (void) recolorSyntaxTimer: (NSTimer*) sender;

- (void) colorOneLineComment: (NSString*) startCh inString: (NSMutableAttributedString*)s withColor: (NSColor*) col andMode:(NSString*)attr;
- (void) colorCommentsFrom: (NSString*) startCh to: (NSString*) endCh inString: (NSMutableAttributedString*)s withColor: (NSColor*) col andMode:(NSString*)attr;
- (void) colorIdentifier: (NSString*) ident inString: (NSMutableAttributedString*)s withColor: (NSColor*) col andMode:(NSString*)attr charset: (NSCharacterSet*)cset;
- (void) colorStringsFrom: (NSString*) startCh to: (NSString*) endCh inString: (NSMutableAttributedString*)s withColor: (NSColor*) col andMode:(NSString*)attr;
- (BOOL) breakPointAtLine:(NSUInteger)aLineNumber;
@end

