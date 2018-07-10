//
//  ORFilterModel.h
//  Orca
//
//  Created by Mark Howe on Mon Nov 18 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark •••Imported Files
#import "ORDataChainObject.h"
#import "ORBaseDecoder.h"
#import "ORDataProcessing.h"
#import "FilterScript.h"

#define kNumScriptArgs 5
#define kNumDisplayValues 5
#define kNumFilterStacks 256

#pragma mark •••Forward Declarations
@class ORQueue;
@class ORTimer;
@class ORDecoder;
@class FilterScriptEx;
@class ORFilterSymbolTable;

#define kFilterTimeHistoSize 4000

@interface ORFilterModel :  ORDataChainObject <ORDataProcessing>

{
@private
	
	unsigned long dataId1D;
	unsigned long dataId2D;
	unsigned long dataIdStrip;
	
	NSString*			lastFile;
	NSString*			script;
	NSString*			scriptName;
	NSMutableArray*		inputValues;
	NSMutableArray*		outputValues;
	
	BOOL				running;
	BOOL				parsedOK;
	unsigned			yaccInputPosition;
	NSData*				expressionAsData;
	BOOL				exitNow;
	BOOL				firstTime;
	ORDecoder*			currentDecoder;
	ORQueue*			stacks[kNumFilterStacks];
	unsigned long		processingTimeHist[kFilterTimeHistoSize];
	NSLock*				timerLock;
	BOOL				timerEnabled;
	ORTimer*			mainTimer;
	ORTimer*			runTimer;
	unsigned long		lastRunTimeValue;
	NSTimeInterval		lastOutputUpdateTimeRef;
	NSString*			pluginPath;
	BOOL				pluginValid;
	id					pluginInstance;
	BOOL				usePlugin;
	id					thePassThruObject;  //cache the object on the other side of the pass thru connection
	id					theFilteredObject;	//cache the object on the other side of the filter connection
	NSMutableDictionary* stackIndexErrorReported;
	NSMutableDictionary* stackPtrErrorReported;
    FilterScriptEx* filterExecuter;
    ORFilterSymbolTable* symbolTable;
    //-----------------------------
    //we take over the node pointers
    long mStartFilterNodeCount;
    nodeType** mStartFilterNodes;
    long mFilterNodeCount;
    nodeType** mFilterNodes;
    long mFinishFilterNodeCount;
    nodeType** mFinishFilterNodes;
    //-----------------------------

}

- (id)   init;
- (void) dealloc;
- (void) freeNodes;
- (void) freeNode:(nodeType*) p;

#pragma mark •••Accessors
- (BOOL) usePlugin;
- (void) setUsePlugin:(BOOL)aUsePlugin;
- (BOOL) pluginValid;
- (void) setPluginValid:(BOOL)aPluginValid;
- (NSString*) pluginPath;
- (void) setPluginPath:(NSString*)aPluginPath;
- (NSString*) lastFile;
- (void) setLastFile:(NSString*)aFile;
- (NSString*) script;
- (void) setScript:(NSString*)aString;
- (void) setScriptNoNote:(NSString*)aString;
- (NSString*) scriptName;
- (void) setScriptName:(NSString*)aString;
- (BOOL) parsedOK;
- (unsigned long) processingTimeHist:(int)index;
- (void) clearTimeHistogram;
- (BOOL) timerEnabled;
- (void) setTimerEnabled:(int)aState;

- (BOOL) exitNow;
- (NSMutableArray*) inputValues;
- (NSMutableArray*) outputValues;
- (void) addInputValue;
- (void) removeInputValue:(int)i;

#pragma mark •••Data Handling
- (unsigned long) dataId1D;
- (void) setDataId1D: (unsigned long) aDataId;
- (unsigned long) dataId2D;
- (void) setDataId2D: (unsigned long) aDataId;
- (unsigned long) dataIdStrip;
- (void) setDataIdStrip: (unsigned long) aDataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherObj;
- (NSDictionary*) dataRecordDescription;

- (void) verifyFilterIsReady;
- (void) runTaskStarted:(NSDictionary*)userInfo;
- (void) runTaskStopped:(NSDictionary*)userInfo;
- (void) preCloseOut:(NSDictionary*)userInfo;
- (void) closeOutRun:(NSDictionary*)userInfo;
- (void) processData:(NSArray*)dataArray decoder:(ORDecoder*)aDecoder;
- (void) setRunMode:(int)aMode;
- (void) cleanUpFilter;

#pragma mark ***Script Methods
- (void) parseScript;
- (void) saveFile;
- (void) loadScriptFromFile:(NSString*)aFilePath;
- (void) saveScriptToFile:(NSString*)aFilePath;

#pragma mark ***Plugin Interface
- (BOOL) filterPluginIsValid:(Class) filterClass;
- (void) reloadPlugin;
- (void) loadPlugin;
- (BOOL) record:(unsigned long*)aRecordPtr isEqualTo:(unsigned long)aValue;
- (unsigned long) extractRecordID:(unsigned long)aValue;
- (unsigned long) extractRecordLen:(unsigned long)aValue;
- (unsigned long) extractValue:(unsigned long)aValue mask:(unsigned long)aMask thenShift:(unsigned long)shift;
- (void) shipRecord:(unsigned long*)p length:(long)length;
- (void) checkStackIndex:(int) i;
- (void) checkStack:(int)index ptr:(unsigned long) ptr;
- (void) pushOntoStack:(int)i ptrCheck:(unsigned long)ptrCheck record:(unsigned long*)p;
- (unsigned long*) popFromStack:(int)i;
- (unsigned long*) popFromStackBottom:(int)i;
- (void) shipStack:(int)i;
- (void) dumpStack:(int)i;
- (long) stackCount:(int)i;
- (void) histo1D:(int)i value:(unsigned long)aValue;
- (void) histo2D:(int)i x:(unsigned long)x y:(unsigned long)y;
- (void) stripChart:(int)i time:(unsigned long)x value:(unsigned long)y;
- (void) setOutput:(int)index withValue:(unsigned long)aValue;
- (void) resetDisplays;
- (void) scheduledUpdate;
- (void) refreshInputs;

#pragma mark •••Parsers
- (void) parseFile:(NSString*)aPath;
- (BOOL) parsedOK;
- (void) parse:(NSString*)theString;

#pragma mark •••Yacc Input
- (void) setString:(NSString* )theString;
- (int) yyinputToBuffer:(char* )theBuffer withSize:(int)maxSize;

#pragma mark •••Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end


extern NSString* ORFilterModelUsePluginChanged;
extern NSString* ORFilterModelPluginValidChanged;
extern NSString* ORFilterModelPluginPathChanged;
extern NSString* ORFilterLock;
extern NSString* ORFilterLastFileChanged;
extern NSString* ORFilterNameChanged;
extern NSString* ORFilterLastFileChangedChanged;
extern NSString* ORFilterScriptChanged;
extern NSString* ORFilterInputValuesChanged;
extern NSString* ORFilterDisplayValuesChanged;
extern NSString* ORFilterTimerEnabledChanged;
extern NSString* ORFilterUpdateTiming;


@interface ORFilterDecoderFor1D : ORBaseDecoder
{}
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)ptr;
@end

@interface ORFilterDecoderFor2D : ORBaseDecoder
{}
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)ptr;
@end

@interface ORFilterDecoderForStrip : ORBaseDecoder
{}
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)ptr;
@end

@interface NSObject (Filter)
- (BOOL) unload;
@end

