//
//  ORScriptRunner.h
//  Orca
//
//  Created by Mark Howe  Dec 2006.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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
#define kDebuggerPaused  1
#define kDebuggerRunning 2

#define kPauseHere		 0
#define kRunToBreakPoint 1
#define kSingleStep		 2
#define kStepInto		 3
#define kStepOutof		 4

@class ORNodeEvaluator;

@interface ORScriptRunner : NSObject {
@private
	id					 finishTarget;
	SEL					 finishSelector;
	unsigned			 yaccInputPosition;
	BOOL				 stopThread;
	BOOL				 running;
	BOOL				 parsedOK;
	NSData*				 expressionAsData;
	NSString*			 scriptName;
	
	NSMutableDictionary* functionTable;
	ORNodeEvaluator*	eval;
	id					inputValue;
	BOOL				exitNow;
	BOOL				scriptExists;
	unsigned long		lastLine;
	unsigned long       lastFunctionLevel;
	BOOL				step;
	BOOL				scriptShouldPause;
	int					debuggerState;
	BOOL				debugging;
	NSMutableIndexSet*	breakpoints;
	int					debugMode;
	NSMutableDictionary*    displayDictionary;
	NSThread*				scriptThread;
	NSMutableDictionary*	importedContents;
	BOOL					suppressStartStopMessage;
} 

#pragma mark ¥¥¥Accessors
- (BOOL) suppressStartStopMessage;
- (void) setSuppressStartStopMessage:(BOOL)aState;
- (void) setBreakpoints:(NSMutableIndexSet*)aSet;
- (ORNodeEvaluator*) eval;
- (BOOL)		exitNow;
- (id)			displayDictionary;
- (id)			inputValue;
- (void)		setInputValue:(id)aValue;
- (void)		setString:(NSString* )theString;
- (NSMutableDictionary*) functionTable;
- (void)		setFunctionTable:(NSMutableDictionary*)aFunctionTable;
- (void)		appendFunctionTable:(NSMutableDictionary*)aFunctionTable;
- (NSString*)	scriptName;
- (void)		setScriptName:(NSString*)aString;
- (BOOL)		parsedOK;
- (BOOL)		scriptExists;
- (void)		setArgs:(NSArray*)args;

#pragma mark ¥¥¥Run Methods
- (BOOL) running;
- (void) run:(id) someArgs  sender:(id)aSender;
- (void) stop;
- (void) setFinishCallBack:(id)aTarget selector:(SEL)aSelector;
- (void) togglePause;
- (void) singleStep;
- (NSUInteger) symbolTableCount;
- (id) symbolNameForIndex:(int)i;
- (id) symbolValueForIndex:(int)i;
- (long) lastLine;
- (int) debuggerState;
- (void) setDebuggerState:(int)aState;
- (void) setBreakpoints:(NSMutableIndexSet*)aSet;
- (void) checkBreakpoint:(unsigned long) lineNumber functionLevel:(int)functionLevel;
- (BOOL) debugging;
- (void) setDebugging:(BOOL)aState;
- (int) debugMode;
- (void) setDebugMode:(int) aMode;
- (id) display:(id)aValue forKey:(id)aKey;
- (void) runScriptAsString:(NSString*)aScript; //for testing

#pragma mark ¥¥¥Parsering stuff
- (void) gatherImportedFiles:(NSString*)scriptString rootFile:(NSString*)aFile;
- (void) parseFile:(NSString*) aPath;
- (void) parse:(NSString*) theString;
- (void) subParse:(NSString*)theString rootFile:(NSString*)aFile;

#pragma mark ¥¥¥Group Evaluators
- (void)	evaluateAll:(id) args sender:(id)aSender;
- (void)	printAll;

#pragma mark ¥¥¥Yacc Input
- (int)		 yyinputToBuffer:(char* )theBuffer withSize:(int)maxSize;

@end

extern NSString* ORScriptRunnerDebuggingChanged;
extern NSString* ORScriptRunnerDebuggerStateChanged;
extern NSString* ORScriptRunnerRunningChanged;
extern NSString* ORScriptRunnerParseError;
extern NSString* ORScriptRunnerDisplayDictionaryChanged;
