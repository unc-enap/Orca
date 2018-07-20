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
	
	uint32_t dataId1D;
	uint32_t dataId2D;
	uint32_t dataIdStrip;
	
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
	uint32_t		processingTimeHist[kFilterTimeHistoSize];
	NSLock*				timerLock;
	BOOL				timerEnabled;
	ORTimer*			mainTimer;
	ORTimer*			runTimer;
	uint32_t		lastRunTimeValue;
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
    int32_t mStartFilterNodeCount;
    nodeType** mStartFilterNodes;
    int32_t mFilterNodeCount;
    nodeType** mFilterNodes;
    int32_t mFinishFilterNodeCount;
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
- (uint32_t) processingTimeHist:(int)index;
- (void) clearTimeHistogram;
- (BOOL) timerEnabled;
- (void) setTimerEnabled:(int)aState;

- (BOOL) exitNow;
- (NSMutableArray*) inputValues;
- (NSMutableArray*) outputValues;
- (void) addInputValue;
- (void) removeInputValue:(NSUInteger)i;

#pragma mark •••Data Handling
- (uint32_t) dataId1D;
- (void) setDataId1D: (uint32_t) aDataId;
- (uint32_t) dataId2D;
- (void) setDataId2D: (uint32_t) aDataId;
- (uint32_t) dataIdStrip;
- (void) setDataIdStrip: (uint32_t) aDataId;
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
- (BOOL) record:(uint32_t*)aRecordPtr isEqualTo:(uint32_t)aValue;
- (uint32_t) extractRecordID:(uint32_t)aValue;
- (uint32_t) extractRecordLen:(uint32_t)aValue;
- (uint32_t) extractValue:(uint32_t)aValue mask:(uint32_t)aMask thenShift:(uint32_t)shift;
- (void) shipRecord:(uint32_t*)p length:(int32_t)length;
- (void) checkStackIndex:(uint32_t) i;
- (void) checkStack:(uint32_t)index ptr:(uint32_t) ptr;
- (void) pushOntoStack:(uint32_t)i ptrCheck:(uint32_t)ptrCheck record:(uint32_t*)p;
- (uint32_t*) popFromStack:(uint32_t)i;
- (uint32_t*) popFromStackBottom:(uint32_t)i;
- (void) shipStack:(uint32_t)i;
- (void) dumpStack:(uint32_t)i;
- (int32_t) stackCount:(uint32_t)i;
- (void) histo1D:(int)i value:(uint32_t)aValue;
- (void) histo2D:(int)i x:(uint32_t)x y:(uint32_t)y;
- (void) stripChart:(int)i time:(uint32_t)x value:(uint32_t)y;
- (void) setOutput:(int)index withValue:(uint32_t)aValue;
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
- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(uint32_t*)ptr;
@end

@interface ORFilterDecoderFor2D : ORBaseDecoder
{}
- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(uint32_t*)ptr;
@end

@interface ORFilterDecoderForStrip : ORBaseDecoder
{}
- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(uint32_t*)ptr;
@end

@interface NSObject (Filter)
- (BOOL) unload;
@end

