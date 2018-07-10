//
//  ORFilterModel.m
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
#import "ORFilterModel.h"
#import "ORDataSet.h"
#import "ORFilterSymbolTable.h"
#import "FilterScript.h"
#import "ORDataTypeAssigner.h"
#import "ORQueue.h"
#import "ORFilterPluginBaseClass.h"
#import "ORDecoder.h"
#import "FilterScriptEx.h"

NSString* ORFilterModelUsePluginChanged = @"ORFilterModelUsePluginChanged";
NSString* ORFilterModelPluginValidChanged = @"ORFilterModelPluginValidChanged";
NSString* ORFilterModelPluginPathChanged = @"ORFilterModelPluginPathChanged";
static NSString* ORFilterInConnector 		= @"Filter In Connector";
static NSString* ORFilterOutConnector 		= @"Filter Out Connector";
static NSString* ORFilterFilteredConnector  = @"Filtered Out Connector";

NSString* ORFilterLastFileChanged			= @"ORFilterLastFileChanged";
NSString* ORFilterNameChanged				= @"ORFilterNameChanged";
NSString* ORFilterInputValuesChanged		= @"ORFilterInputValuesChanged";
NSString* ORFilterDisplayValuesChanged		= @"ORFilterDisplayValuesChanged";
NSString* ORFilterBreakChainChanged			= @"ORFilterBreakChainChanged";
NSString* ORFilterLastFileChangedChanged	= @"ORFilterLastFileChangedChanged";
NSString* ORFilterScriptChanged				= @"ORFilterScriptChanged";
NSString* ORFilterTimerEnabledChanged		= @"ORFilterTimerEnabledChanged";
NSString* ORFilterUpdateTiming				= @"ORFilterUpdateTiming";
NSString* ORFilterLock                      = @"ORFilterLock";

//========================================================================
#pragma mark •••YACC interface
#import "OrcaScript.tab.h"
extern void resetFilterState();
extern void FilterScriptrestart();
extern int FilterScriptparse();

//-----------------------------------------
//we will take over ownership of these pointers
//and will release them in this object
//they have to be global for us to get at them
extern long startFilterNodeCount;
extern nodeType** startFilterNodes;
extern long filterNodeCount;
extern nodeType** filterNodes;
extern long finishFilterNodeCount;
extern nodeType** finishFilterNodes;
//-----------------------------------------
extern long numFilterLines;
extern BOOL parsedSuccessfully;

ORFilterModel* theFilterRunner = nil;
int FilterScriptYYINPUT(char* theBuffer,int maxSize) 
{
	return [theFilterRunner yyinputToBuffer:theBuffer withSize:maxSize];
}
int ex(nodeType*, id);
int filterGraph(nodeType*);
//========================================================================

@interface ORFilterModel (private)
- (void) loadDataIDsIntoSymbolTable:(NSMutableDictionary*)aHeader;
@end

@implementation ORFilterModel

#pragma mark •••Initialization
- (id) init //designated initializer
{
	self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    [[self undoManager] enableUndoRegistration];
	
	return self;
}

-(void)dealloc
{	
    [pluginPath release];
	[pluginInstance release];
	[self freeNodes];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scheduledUpdate) object:nil];
	[currentDecoder release];
	[expressionAsData release];
	[inputValues release];
	[outputValues release];
	[lastFile release];
	[script release];
	[scriptName release];
	[timerLock release];
	[mainTimer release];
	[stackIndexErrorReported release];
	[stackPtrErrorReported release];
    [super dealloc];
}

- (void) awakeAfterDocumentLoaded
{
	[self loadPlugin]; //temp
}

- (void) freeNodes
{
	int i;
	if(mFilterNodes){
		for(i=0;i<mFilterNodeCount;i++){
			[self freeNode:mFilterNodes[i]];
		}
		free(mFilterNodes);
		mFilterNodes = nil;
		mFilterNodeCount = 0;
	}
	if(mStartFilterNodes){
		for(i=0;i<mStartFilterNodeCount;i++){
			[self freeNode:mStartFilterNodes[i]];
		}
		free(mStartFilterNodes);
		mStartFilterNodes = nil;
		mStartFilterNodeCount = 0;
	}
	if(mFinishFilterNodes){
		for(i=0;i<mFinishFilterNodeCount;i++){
			if(mFinishFilterNodes[i]){
				[self freeNode:mFinishFilterNodes[i]];
				mFinishFilterNodes[i]  = nil;
			}
		}
		free(mFinishFilterNodes);
		mFinishFilterNodes = nil;
		mFinishFilterNodeCount = 0;
	}
}
- (void) freeNode:(nodeType*) p
{
    int i;
    
    if (!p) return;
    if (p->type == typeOpr) {
        for (i = 0; i < p->opr.nops; i++) [self freeNode:p->opr.op[i]];
    }
    free (p);
    p = nil;
}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"Filter"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORFilterController"];
}

- (NSString*) helpURL
{
	return @"Data_Chain/Data_Filter.html";
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(0,2*[self frame].size.height/3. - kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORFilterInConnector];
	[aConnector setIoType:kInputConnector];
    [aConnector release];
	
    aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width/2 - kConnectorSize/2 , 0) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORFilterFilteredConnector];
	[aConnector setIoType:kOutputConnector];
    [aConnector release];
    
    aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width-kConnectorSize,2*[self frame].size.height/3. - kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORFilterOutConnector];
	[aConnector setIoType:kOutputConnector];
    [aConnector release];
}

#pragma mark •••Accessors

- (BOOL) usePlugin
{
    return usePlugin;
}

- (void) setUsePlugin:(BOOL)aUsePlugin
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUsePlugin:usePlugin];
    
    usePlugin = aUsePlugin;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFilterModelUsePluginChanged object:self];
}

- (BOOL) pluginValid
{
    return pluginValid;
}

- (void) setPluginValid:(BOOL)aPluginValid
{
    pluginValid = aPluginValid;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFilterModelPluginValidChanged object:self];
}

- (NSString*) pluginPath
{
    return pluginPath;
}

- (void) setPluginPath:(NSString*)aPluginPath
{
	if(!aPluginPath)aPluginPath = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setPluginPath:pluginPath];
    
    [pluginPath autorelease];
    pluginPath = [aPluginPath copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFilterModelPluginPathChanged object:self];
	
}

- (void) refreshInputs
{
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFilterInputValuesChanged object:self];
}

- (NSMutableArray*) inputValues
{
	return inputValues;
}

- (NSMutableArray*) outputValues
{
	return outputValues;
}

- (void) addInputValue
{
	if(!inputValues)inputValues = [[NSMutableArray array] retain];
	[inputValues addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
							[NSString stringWithFormat:@"$%d",[inputValues count]],	@"name",
							[NSNumber numberWithUnsignedLong:0],					@"iValue",
							nil]];
	
}

- (NSArray*) collectConnectedObjectsOfClass:(Class)aClass
{
    NSMutableArray* collection = [NSMutableArray arrayWithCapacity:256];
	id obj = [[connectors objectForKey:ORFilterOutConnector] connectedObject];
	[collection addObjectsFromArray:[obj collectConnectedObjectsOfClass:aClass]];
	return collection;
}

- (void) removeInputValue:(int)i
{
	[inputValues removeObjectAtIndex:i];
}

- (BOOL)	exitNow
{
	return exitNow;
}

- (NSString*) lastFile
{
	return lastFile;
}

- (void) setLastFile:(NSString*)aFile
{
	if(!aFile)aFile = [[NSHomeDirectory() stringByAppendingPathComponent:@"Untitled"] stringByExpandingTildeInPath];
	[[[self undoManager] prepareWithInvocationTarget:self] setLastFile:lastFile];
    [lastFile autorelease];
    lastFile = [aFile copy];		
	[[NSNotificationCenter defaultCenter] postNotificationName:ORFilterLastFileChangedChanged object:self];
}

- (unsigned long) processingTimeHist:(int)index
{
    return processingTimeHist[index];
}

- (void) clearTimeHistogram
{
    memset(processingTimeHist,0,kFilterTimeHistoSize*sizeof(unsigned long));
	[[NSNotificationCenter defaultCenter] postNotificationName:ORFilterUpdateTiming object:self];
}

- (BOOL) timerEnabled
{
	return timerEnabled;
}

- (void) setTimerEnabled:(int)aState
{
	timerEnabled = aState;
	if(timerEnabled){
		[self clearTimeHistogram];
		mainTimer = [[ORTimer alloc]init];
		[mainTimer start];
	}
	else {
		[mainTimer release];
		mainTimer = nil;
	}
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORFilterTimerEnabledChanged
	 object:self];
}

#pragma mark •••Data Handling
- (void) processData:(NSArray*)dataArray decoder:(ORDecoder*)aDecoder;
{
	if(aDecoder != currentDecoder){
		[currentDecoder release];
		currentDecoder = [aDecoder retain];
        //[currentDecoder setSkipRateCounts:YES];
		if(usePlugin && firstTime){
			[symbolTable release];
			symbolTable = [[ORFilterSymbolTable alloc] init];
		}
		if(firstTime){
			[self loadDataIDsIntoSymbolTable:[aDecoder fileHeader]];
			[aDecoder generateObjectLookup];
			if(usePlugin){
				[pluginInstance setSymbolTable:symbolTable];
				[pluginInstance start];
			}
			else {
				[filterExecuter startFilterScript:mStartFilterNodes nodeCount:mStartFilterNodeCount delegate:self];
			}
			firstTime = NO;
		}
	}
	
	//pass it on
    [dataArray retain];
	[thePassThruObject processData:dataArray decoder:aDecoder];
	//each block of data is an array of NSData objects, each potentially containing many records..
	for(id data in dataArray){
		[data retain];
		//each record must be filtered by the filter code. 
		long totalLen = [data length]/sizeof(long);
		if(totalLen>0){
			unsigned long* ptr = (unsigned long*)[data bytes];
			while(totalLen>0){
				
				long recordLen = ExtractLength(*ptr);
				if(recordLen > totalLen){
					NSLogError(@" ",@"Filter",@"Bad Record:Incorrect Length",nil);
					break;
				}
				
				filterData tempData;
				unsigned long t = [runTimer microseconds]/1000;
				if(t!=lastRunTimeValue){
					lastRunTimeValue = t;
					tempData.type		= kFilterLongType;
					tempData.val.lValue = t;
					[symbolTable setData:tempData forKey:"ElapsedTime"];
				}
				
				if(timerEnabled) [mainTimer reset];
				
				if(usePlugin){
					[pluginInstance filter:ptr length:recordLen];
				}
				else {
					tempData.type		= kFilterPtrType;
					tempData.val.pValue = ptr;
					[symbolTable setData:tempData forKey:"CurrentRecordPtr"];
					
					tempData.type		= kFilterLongType;
					tempData.val.lValue = recordLen;
					[symbolTable setData:tempData forKey:"CurrentRecordLen"];
					
					@try {
                        
                        [filterExecuter runFilterNodes:mFilterNodes nodeCount:mFilterNodeCount delegate:self];
					}
					@catch(NSException* e){
					}
				}
				if(timerEnabled){
					float delta = [mainTimer microseconds];
					if(delta<kFilterTimeHistoSize)processingTimeHist[(int)delta]++;
					else processingTimeHist[kFilterTimeHistoSize-1]++;
				}
				
				ptr += recordLen;
				totalLen -= recordLen;
			}
		}
		else {
			[symbolTable removeKey:"CurrentRecordPtr"];
			[symbolTable removeKey:"CurrentRecordLen"];
		}
		[data release];
	}
	[dataArray release];
}

- (unsigned long) dataId1D { return dataId1D; }
- (void) setDataId1D: (unsigned long) aDataId
{
    dataId1D = aDataId;
}

- (unsigned long) dataId2D { return dataId2D; }
- (void) setDataId2D: (unsigned long) aDataId
{
    dataId2D = aDataId;
}

- (unsigned long) dataIdStrip { return dataIdStrip; }
- (void) setDataIdStrip: (unsigned long) aDataId
{
    dataIdStrip = aDataId;
}

- (void) setDataIds:(id)assigner
{
    dataId1D       = [assigner assignDataIds:kLongForm];
    dataId2D       = [assigner assignDataIds:kLongForm];
    dataIdStrip       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherObj
{
    [self setDataId1D:[anotherObj dataId1D]];
    [self setDataId2D:[anotherObj dataId2D]];
    [self setDataIdStrip:[anotherObj dataIdStrip]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
	
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORFilterDecoderFor1D",				@"decoder",
								 [NSNumber numberWithLong:dataId1D],     @"dataId",
								 [NSNumber numberWithBool:NO],           @"variable",
								 [NSNumber numberWithLong:2],            @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Filter1D"];
	
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORFilterDecoderFor2D",				@"decoder",
				   [NSNumber numberWithLong:dataId2D],     @"dataId",
				   [NSNumber numberWithBool:NO],           @"variable",
				   [NSNumber numberWithLong:3],            @"length",
				   nil];
    [dataDictionary setObject:aDictionary forKey:@"Filter2D"];
	
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORFilterDecoderForStrip",				@"decoder",
				   [NSNumber numberWithLong:dataIdStrip],   @"dataId",
				   [NSNumber numberWithBool:NO],           @"variable",
				   [NSNumber numberWithLong:3],            @"length",
				   nil];
    [dataDictionary setObject:aDictionary forKey:@"StripChart"];
	
    return dataDictionary;
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
	if(inputValues) [objDictionary setObject:inputValues forKey:@"inputValues"];
    if(scriptName)  [objDictionary setObject:scriptName forKey:@"scriptName"];
    if(lastFile) [objDictionary setObject:lastFile forKey:@"lastFile"];
    [dictionary setObject:objDictionary forKey:@"FilterObject"];
	return objDictionary;
}

- (BOOL) filterPluginIsValid:(Class) filterClass
{
    if([filterClass isSubclassOfClass:[ORFilterPluginBaseClass class]])return YES;
    else return NO;
}

- (void) reloadPlugin
{
    #if defined(MAC_OS_X_VERSION_10_5) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
        NSBundle* currBundle = [NSBundle bundleWithPath:[pluginPath stringByExpandingTildeInPath]];
        [pluginInstance release];
        pluginInstance = nil;
        [currBundle unload];
    #endif

 	[self loadPlugin];
}

- (void) loadPlugin
{  
	BOOL pluginAvailable = NO;
	[pluginInstance release];
	pluginInstance = nil;
	if([pluginPath length]){
        NSBundle* currBundle = [NSBundle bundleWithPath:[pluginPath stringByExpandingTildeInPath]];
        if(currBundle){
            Class currPrincipalClass = [currBundle principalClass];
            if(currPrincipalClass && [self filterPluginIsValid:currPrincipalClass]) {  // Validation
                pluginInstance = [[currPrincipalClass alloc] initWithDelegate:self];
                if(pluginInstance) {
					pluginAvailable = YES;
					NSLog(@"Loaded Filter Plugin: %@\n",pluginPath);
				}
            }
        }
    }
	[self setPluginValid:pluginAvailable];
}


- (void) verifyFilterIsReady
{
	
	runTimer = [[ORTimer alloc] init];
	[runTimer start];
	lastRunTimeValue = 0;
	
	int i;
	for(i=0;i<kNumFilterStacks;i++) stacks[i] = nil;
	
	if(usePlugin){
		if(!pluginValid){
			NSLog(@"Filter Plugin <%@> is not Valid. Run Not Allowed.\n",pluginPath);
			[NSException raise:@"Plugin Error" format:@"Plugin not valid."];
		}
	}
	else {
		[self parseScript];
		
		if(!parsedOK){
			NSLog(@"Filter script parse error prevented run start\n");
			[NSException raise:@"Parse Error" format:@"Filter Script parse failed."];
		}
	}
}

- (void) cleanUpFilter
{
	[self freeNodes];
	
	int i;
	for(i=0;i<kNumFilterStacks;i++){
		[self dumpStack:i];
	}
	
	[runTimer release];
	runTimer = nil;
	
	[currentDecoder release];
	currentDecoder = nil;
	
	[symbolTable release];
	symbolTable = nil;
	
	[stackIndexErrorReported release];
	stackIndexErrorReported = nil;
	
	[stackPtrErrorReported release];
	stackPtrErrorReported = nil;
}

- (void) runTaskStarted:(NSDictionary*)userInfo
{		
	[self clearTimeHistogram];
	
	firstTime = YES;
	currentDecoder = nil;
	
	[self verifyFilterIsReady]; //throws on error
	
	thePassThruObject = [self objectConnectedTo:ORFilterOutConnector];
	theFilteredObject = [self objectConnectedTo:ORFilterFilteredConnector];
	
	[thePassThruObject runTaskStarted:userInfo];
	
	[thePassThruObject setInvolvedInCurrentRun:YES];
	
	
	NSMutableDictionary* infoCopy = [userInfo mutableCopy];
	[infoCopy setObject:@"Filtered" forKey:kFileSuffix];
	
	[theFilteredObject runTaskStarted:infoCopy];
	[infoCopy release];
	[theFilteredObject setInvolvedInCurrentRun:YES];
	
	
}

- (void) subRunTaskStarted:(NSDictionary*)userInfo
{
	//we don't care
}


- (void) runTaskStopped:(NSDictionary*)userInfo
{
	
	[thePassThruObject runTaskStopped:userInfo];
	[theFilteredObject runTaskStopped:userInfo];
	[thePassThruObject setInvolvedInCurrentRun:NO];
	[theFilteredObject setInvolvedInCurrentRun:NO];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORFilterUpdateTiming object:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORFilterDisplayValuesChanged object:self];
	
}

- (void) preCloseOut:(NSDictionary*)userInfo
{
}

- (void) closeOutRun:(NSDictionary*)userInfo
{
	
	if(usePlugin) [pluginInstance finish];
	else		  [filterExecuter finishFilterScript:mFinishFilterNodes nodeCount:mFinishFilterNodeCount delegate:self];
	
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORFilterDisplayValuesChanged object:self];
	
	
	[theFilteredObject closeOutRun:userInfo];
	[thePassThruObject closeOutRun:userInfo];
	
	[self cleanUpFilter];
    
    [filterExecuter release];
    filterExecuter = nil;
}

- (void) setRunMode:(int)aMode
{
	[[self objectConnectedTo:ORFilterOutConnector] setRunMode:aMode];
	[[self objectConnectedTo:ORFilterFilteredConnector] setRunMode:aMode];
}

- (void) runTaskBoundary
{
}

- (NSString*) script
{
	return script;
}

- (void) setScript:(NSString*)aString
{
	if(!aString)aString= @"";
    //[[[self undoManager] prepareWithInvocationTarget:self] setScript:script];
    [script autorelease];
    script = [aString copy];	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORFilterScriptChanged object:self];
}

- (void) setScriptNoNote:(NSString*)aString
{
    [script autorelease];
    script = [aString copy];	
}

- (NSString*) scriptName
{
	if([scriptName length])return @"";
	else return scriptName;
}

- (void) setScriptName:(NSString*)aString
{
	if(!aString)aString = @"OrcaScript";
    [[[self undoManager] prepareWithInvocationTarget:self] setScriptName:scriptName];
    [scriptName autorelease];
    scriptName = [aString copy];	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORFilterNameChanged object:self];
}



#pragma mark ***Script Methods

- (BOOL) parsedOK
{
	return parsedOK;
}

- (void) parseScript
{
	parsedOK = YES;
	if(!running){
            
		[self parse:script];
        
		parsedOK = parsedSuccessfully;
		if(parsedOK && ([[NSApp currentEvent] modifierFlags] & 0x80000)>0){
			//option key is down
			int i;
			for(i=0;i<mStartFilterNodeCount;i++)	 [filterExecuter filterGraph:mStartFilterNodes[i]];
			for(i=0;i<mFilterNodeCount;i++)		 [filterExecuter filterGraph:mFilterNodes[i] ];
            for(i=0;i<mFinishFilterNodeCount;i++) [ filterExecuter filterGraph:mFinishFilterNodes[i] ];
		}
	}
}

- (void) loadScriptFromFile:(NSString*)aFilePath
{
	[self setLastFile:aFilePath];
	[self setScript:[NSString stringWithContentsOfFile:[lastFile stringByExpandingTildeInPath] encoding:NSASCIIStringEncoding error:nil]];
}

- (void) saveFile
{
	[self saveScriptToFile:lastFile];
}

- (void) saveScriptToFile:(NSString*)aFilePath
{
	NSFileManager* fm = [NSFileManager defaultManager];
	if([fm fileExistsAtPath:[aFilePath stringByExpandingTildeInPath]]){
		[fm removeItemAtPath:[aFilePath stringByExpandingTildeInPath] error:nil];
	}
	NSData* theData = [script dataUsingEncoding:NSUTF8StringEncoding];
	[fm createFileAtPath:[aFilePath stringByExpandingTildeInPath] contents:theData attributes:nil];
	[self setLastFile:aFilePath];
}

#pragma mark •••Archival

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setUsePlugin:[decoder decodeBoolForKey:@"ORFilterModelUsePlugin"]];
    [self setPluginPath:[decoder decodeObjectForKey:@"pluginPath"]];
	[self setScript:[decoder decodeObjectForKey:@"script"]];
    [self setScriptName:[decoder decodeObjectForKey:@"scriptName"]];
    [self setLastFile:[decoder decodeObjectForKey:@"lastFile"]];
    inputValues = [[decoder decodeObjectForKey:@"inputValues"] retain];
	
	[[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:usePlugin forKey:@"ORFilterModelUsePlugin"];
    [encoder encodeObject:pluginPath forKey:@"pluginPath"];
    [encoder encodeObject:script forKey:@"script"];
    [encoder encodeObject:scriptName forKey:@"scriptName"];
    [encoder encodeObject:inputValues forKey:@"inputValues"];
    [encoder encodeObject:lastFile forKey:@"lastFile"];
}

#pragma mark •••Parsers

- (void) parseFile:(NSString*)aPath
{
	NSString* contents = [NSString stringWithContentsOfFile:[aPath stringByExpandingTildeInPath] encoding:NSASCIIStringEncoding error:nil];
	[self parse:contents];
}

-(void) parse:(NSString* )theString 
{  
	// yacc has a number of global variables so it is NOT thread safe
	// Acquire the lock to ensure one parse processing at a time
	@synchronized((ORAppDelegate*)[NSApp delegate]){
		parsedOK = NO;
		@try { 
			
			resetFilterState();
			FilterScriptrestart(NULL);
			
            [symbolTable release];
            symbolTable = [[ORFilterSymbolTable alloc] init];

            theFilterRunner = self;
			[self setString:theString];
			parsedSuccessfully  = NO;
			numFilterLines = 0;
			// Call the parser that was generated by yacc
 			FilterScriptparse();
           
                               
			if(parsedSuccessfully) {
				NSLog(@"%d Lines Parsed Successfully\n",numFilterLines);
				parsedOK = YES;
                
                if(filterExecuter)[filterExecuter release];
                filterExecuter = [[FilterScriptEx alloc]  init];
                [filterExecuter setSymbolTable:symbolTable];
                
                mStartFilterNodeCount   = startFilterNodeCount;
                mStartFilterNodes       = startFilterNodes;
                startFilterNodes        = nil;
                startFilterNodeCount    = 0;

                mFilterNodeCount        = filterNodeCount;
                mFilterNodes            = filterNodes;
                filterNodes            = nil;
                filterNodeCount        = 0;

                mFinishFilterNodeCount   = finishFilterNodeCount;
                mFinishFilterNodes       = finishFilterNodes;
                finishFilterNodes       = nil;
                finishFilterNodeCount   = 0;

            }
			else  {
				NSLog(@"line %d: %@\n",numFilterLines+1,[[theString componentsSeparatedByString:@"\n"] objectAtIndex:numFilterLines]);
			}
			
			
		}
		@catch(NSException* localException) {
			NSLog(@"line %d: %@\n",numFilterLines+1,[[theString componentsSeparatedByString:@"\n"] objectAtIndex:numFilterLines]);
			NSLog(@"Caught %@: %@\n",[localException name],[localException reason]);
			//[functionList release];
			//functionList = nil;
			
		}
		theFilterRunner = nil;
	}
}


#pragma mark •••Yacc Input
- (void)setString:(NSString* )theString 
{
	NSData* theData = [theString dataUsingEncoding:NSUTF8StringEncoding];
	[theData retain];
	[expressionAsData release];
	expressionAsData = theData;
	yaccInputPosition = 0;
}

-(int)yyinputToBuffer:(char* )theBuffer withSize:(int)maxSize 
{
	int theNumberOfBytesRemaining = ([expressionAsData length] - yaccInputPosition);
	int theCopySize = maxSize < theNumberOfBytesRemaining ? maxSize : theNumberOfBytesRemaining;
	[expressionAsData getBytes:theBuffer range:NSMakeRange(yaccInputPosition,theCopySize)];  
	yaccInputPosition = yaccInputPosition + theCopySize;
	return theCopySize;
}

#pragma mark ***Plugin Interface

- (BOOL) record:(unsigned long*)aRecordPtr isEqualTo:(unsigned long)aValue
{
	return ExtractDataId(aRecordPtr[0]) == aValue;
}

- (unsigned long) extractRecordID:(unsigned long)aValue
{
	return ExtractDataId(aValue);
}

- (unsigned long) extractRecordLen:(unsigned long)aValue
{
	return ExtractLength(aValue);
}

- (unsigned long) extractValue:(unsigned long)aValue mask:(unsigned long)aMask thenShift:(unsigned long)shift
{
	return (aValue & aMask) >> shift;
}

- (void) shipRecord:(unsigned long*)p length:(long)length
{
	if(p && length){
		//pass it on
		NSArray* dataArray = [NSArray arrayWithObject:[NSData dataWithBytes:p length:length*sizeof(long)]];
		[theFilteredObject processData:dataArray decoder:currentDecoder];
	}
}

- (void) checkStackIndex:(int) i
{
	if(i<0 || i>=kNumFilterStacks){
		if(![stackIndexErrorReported objectForKey:[NSNumber numberWithInt:i]]){
			if(!stackIndexErrorReported)stackIndexErrorReported = [[NSMutableDictionary dictionary] retain];
			[stackIndexErrorReported setObject:@"dummy" forKey:[NSNumber numberWithInt:i]];
			NSLog(@"Filter <%@>: Stack Index (%d) not greater than 0 and less than %d. Script behaviour is now undefined!! \n",scriptName,i,kNumFilterStacks);
		}
		[NSException raise:@"Filter Script Error" format:@"Stack Index out of bounds."];
	}
}

- (void) checkStack:(int)i ptr:(unsigned long) ptr
{
	if(!ptr){
		if(![stackPtrErrorReported objectForKey:[NSNumber numberWithInt:i]]){
			if(!stackPtrErrorReported)stackPtrErrorReported = [[NSMutableDictionary dictionary] retain];
			[stackPtrErrorReported setObject:@"dummy" forKey:[NSNumber numberWithInt:i]];
			NSLog(@"Filter <%@>: Tried to put a nil pointer onto stack (%d). Script behaviour is now undefined!! \n",scriptName,i,kNumFilterStacks);
		}
		[NSException raise:@"Filter Script Error" format:@"Stack nil pointer."];
	}
}
- (void) pushOntoStack:(int)i ptrCheck:(unsigned long)ptrCheck record:(unsigned long*)p
{
	[self checkStackIndex:i]; //can throw
	[self checkStack:i ptr:ptrCheck]; //can throw
	
	if(!stacks[i])stacks[i] = [[ORQueue alloc] init];
	NSData* theRecord = [NSData dataWithBytes:p length:ExtractLength(*p)*sizeof(long)];
	[stacks[i] enqueue:theRecord];
}

- (unsigned long*) popFromStack:(int)i
{
	[self checkStackIndex:i]; //can throw
	
	NSData* data = [stacks[i] dequeue];
	return (unsigned long*)[data bytes];
}

- (unsigned long*) popFromStackBottom:(int)i
{
	[self checkStackIndex:i]; //can throw
	NSData* data = [stacks[i] dequeueFromBottom];
	return (unsigned long*)[data bytes];
}

- (void) shipStack:(int)i
{
	[self checkStackIndex:i]; //can throw
	if(stacks[i] && ![stacks[i] isEmpty]) {
		while(![stacks[i] isEmpty]){
			NSArray* dataArray = [NSArray arrayWithObject:[stacks[i] dequeueFromBottom]];
			[theFilteredObject processData:dataArray decoder:currentDecoder];
		}
		
		[self dumpStack:i];
	}
}

- (long) stackCount:(int)i
{
	[self checkStackIndex:i]; //can throw
	return [stacks[i] count];
}

- (void) dumpStack:(int)i
{
	[self checkStackIndex:i]; //can throw
	[stacks[i] release];
	stacks[i] = nil;
}

- (void) histo1D:(int)i value:(unsigned long)aValue
{
	unsigned long p[2];
	p[0] = dataId1D | 2;
	p[1] = (i & 0xff) << 24 | (aValue & 0x00ffffff);
	//pass it on
	NSArray* someData = [NSArray arrayWithObject:[NSData dataWithBytes:p length:2*sizeof(long)]];
	[theFilteredObject processData:someData decoder:currentDecoder];
}

- (void) histo2D:(int)i x:(unsigned long)x y:(unsigned long)y
{
	unsigned long p[3];
	p[0] = dataId2D | 3;
	p[1] = (i & 0xff) << 24 | (x & 0xffff);
	p[2] = (y & 0xffff);
	
	//pass it on
	NSArray* someData = [NSArray arrayWithObject:[NSData dataWithBytes:p length:3*sizeof(long)]];
	[theFilteredObject processData:someData decoder:currentDecoder];
}

- (void) stripChart:(int)i time:(unsigned long)aTimeIndex value:(unsigned long)aValue
{
	unsigned long p[3];
	p[0] = dataIdStrip | 3;
	p[1] = (i & 0xffff) << 16 | (aValue & 0xffff); 
	p[2] = aTimeIndex;
	
	//pass it on
	NSArray* someData = [NSArray arrayWithObject:[NSData dataWithBytes:p length:3*sizeof(long)]];
	[theFilteredObject processData:someData decoder:currentDecoder];
}


- (void) setOutput:(int)index withValue:(unsigned long)aValue
{
	if(!outputValues) outputValues = [[NSMutableArray array] retain];
	if(index>[outputValues count]){
		int i;
		for(i=[outputValues count];i<index;i++){
			[outputValues addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:
									  [NSString stringWithFormat:@"%d",i], @"name",
									  [NSString stringWithFormat:@"%d",0], @"iValue",
									  nil]];
		}
	}
	if(index==[outputValues count]){
		[outputValues addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
								 [NSString stringWithFormat:@"%d",index],   @"name",
								 [NSString stringWithFormat:@"%lu",aValue], @"iValue",
								 nil]];
	}
	else {
		[outputValues replaceObjectAtIndex:index withObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
															 [NSString stringWithFormat:@"%d",index],  @"name",
															 [NSString stringWithFormat:@"%lu",aValue], @"iValue",
															 nil]];
	}
	NSTimeInterval currentTimeRef = [NSDate timeIntervalSinceReferenceDate];
	if(currentTimeRef - lastOutputUpdateTimeRef >= 1){
		lastOutputUpdateTimeRef = currentTimeRef;
		[self performSelectorOnMainThread:@selector(scheduledUpdate) withObject:nil waitUntilDone:NO];
	}
}

- (void) resetDisplays
{
	[outputValues release];
	outputValues = nil;
}

- (void) scheduledUpdate
{
	[[NSNotificationCenter defaultCenter] postNotificationName:ORFilterDisplayValuesChanged object:self];
}

@end

@implementation ORFilterModel (private)
- (void) loadDataIDsIntoSymbolTable:(NSMutableDictionary*)aHeader
{	
	NSMutableDictionary* descriptionDict = [aHeader objectForKey:@"dataDescription"];
	NSString* objKey;
	NSEnumerator*  descriptionDictEnum = [descriptionDict keyEnumerator];
	
	//we are a special case and might not be in the data stream if the data is coming from 
	//the data replay object so we'll check and if needed will define data ids for ourselves.
	NSDictionary* objDictionary = [descriptionDict objectForKey:@"ORFilterDecoderFor1D"];
	long anID = [[objDictionary objectForKey:@"dataId"] longValue];
	if(anID == 0){
		unsigned long maxLongID = 0;
		//loop over all objects in the descript and log the highest id
		while(objKey = [descriptionDictEnum nextObject]){
			NSDictionary* objDictionary = [descriptionDict objectForKey:objKey];
			NSEnumerator* dataObjEnum = [objDictionary keyEnumerator];
			NSString* dataObjKey;
			while(dataObjKey = [dataObjEnum nextObject]){
				NSDictionary* lowestLevel = [objDictionary objectForKey:dataObjKey];
				unsigned long anID = [[lowestLevel objectForKey:@"dataId"] longValue];
				if(IsLongForm(anID)){
					anID >>= 18;
					if(anID>maxLongID)maxLongID = anID;
				}
			} 
		}
		if(maxLongID>0){
			maxLongID++;
			[self setDataId1D:maxLongID<<18];
			maxLongID++;
			[self setDataId2D:maxLongID<<18];
			maxLongID++;
			[self setDataIdStrip:maxLongID<<18];
			[descriptionDict setObject:[self dataRecordDescription] forKey:@"ORFilterModel"];
			
		}
	}
	
	descriptionDictEnum = [descriptionDict keyEnumerator];
	while(objKey = [descriptionDictEnum nextObject]){
		NSDictionary* objDictionary = [descriptionDict objectForKey:objKey];
		NSEnumerator* dataObjEnum = [objDictionary keyEnumerator];
		NSString* dataObjKey;
		while(dataObjKey = [dataObjEnum nextObject]){
			NSDictionary* lowestLevel = [objDictionary objectForKey:dataObjKey];
			NSString* decoderName = [lowestLevel objectForKey:@"decoder"];
			filterData theDataType;
			theDataType.val.lValue = [[lowestLevel objectForKey:@"dataId"] longValue];
			theDataType.type  = kFilterLongType;
			[symbolTable setData:theDataType forKey:[decoderName cStringUsingEncoding:NSASCIIStringEncoding]];
		} 
	}
	
	NSEnumerator* e = [inputValues objectEnumerator];
	NSDictionary* anInputValueDictionary;
	filterData tempData;
	while(anInputValueDictionary = [e nextObject]){
		tempData.type		= kFilterLongType;
		tempData.val.lValue = [[anInputValueDictionary objectForKey:@"iValue"] unsignedLongValue];
		NSString* aKey = [anInputValueDictionary objectForKey:@"name"];
		[symbolTable setData:tempData forKey:[aKey cStringUsingEncoding:NSASCIIStringEncoding]];
	}
}

@end

@implementation ORFilterDecoderFor1D

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
    unsigned long length = 2;
	
    unsigned short index  = (ptr[1]&0xff000000)>>24;
    unsigned long  value = ptr[1]&0x00ffffff;
	
    [aDataSet histogram:value numBins:4096  sender:self  withKeys:@"Filter",
	 [NSString stringWithFormat:@"%d",index],
	 nil];
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Filter Record (1D)\n\n";
    
    NSString* value  = [NSString stringWithFormat:@"Value = %lu\n",ptr[1]&0x00ffffff];
    NSString* index  = [NSString stringWithFormat: @"Index  = %lu\n",(ptr[1]&0xff000000)>>24];    
	
    return [NSString stringWithFormat:@"%@%@%@",title,value,index];               
}


@end

@implementation ORFilterDecoderFor2D
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
    unsigned long length = 3;
	
    [aDataSet histogram2DX:ptr[1]&0x0000ffff y:ptr[2]&0x0000ffff size:256  sender:self  
				  withKeys:@"Filter2D",[NSString stringWithFormat:@"%lu",(ptr[1]&0xff00000)>>24],
	 nil];
	
	
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Filter Record (2D)\n\n";
    
    NSString* index   = [NSString stringWithFormat: @"Index  = %lu\n",(ptr[1]&0xff00000)>>24];
    NSString* valueX  = [NSString stringWithFormat: @"ValueX = %lu\n",ptr[1]&0x0000ffff];
    NSString* valueY  = [NSString stringWithFormat: @"ValueY = %lu\n",ptr[2]&0x0000ffff];    
	
    return [NSString stringWithFormat:@"%@%@%@%@",title,valueX,valueY,index];               
}
@end

@implementation ORFilterDecoderForStrip
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
    unsigned long length = 3;
	
    [aDataSet loadTimeSeries:ptr[1]&0xFFFF atTime:ptr[2] sender:self  
					withKeys:@"FilterStripChart",[NSString stringWithFormat:@"%lu",(ptr[1]&0xffff0000)>>16],
	 nil];
	
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Filter Time Series\n\n";
    
    NSString* index  =     [NSString stringWithFormat: @"Index = %lu\n",(ptr[1] & 0xffff0000)>>16];
    NSString* timeValue  = [NSString stringWithFormat: @"Time  = %lu\n",ptr[1] & 0x0000ffff];
    NSString* value  =     [NSString stringWithFormat: @"Value = %lu\n",ptr[2]];    
	
    return [NSString stringWithFormat:@"%@%@%@%@",title,index,timeValue,value];               
}
@end

