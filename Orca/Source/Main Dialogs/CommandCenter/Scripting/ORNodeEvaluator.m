//
//  ORNodeEvaluator.m
//  Orca
//
//  Created by Mark Howe on 12/29/06.
//  Copyright 2006 University of North Carolina. All rights reserved.
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


#import "ORNodeEvaluator.h"
#import "ORScriptRunner.h"
#import "NodeTree.h"
#import "OrcaScript.h"
#import "ORCard.h"
#import "ORCamacCard.h"
#import "NSInvocation+Extensions.h"
#import "OrcaScript.tab.h"
#import "ORAlarmCollection.h"
#import "NSNotifications+Extensions.h"
#import "ObjectFactory.h"

@interface ORNodeEvaluator (Interpret_private)
- (id)		processStatements:(id) p;
- (id)		doOperation:(id) p container:(id)aContainer;
- (id)      print:(id) p;
- (id)		printFile:(id) p;
- (id)		openLogFile:(id) p;
- (id)		arrayList:(id) p;
- (id)		makeString:(id) p;
- (id)		catString:(id) p;
- (id)		arrayAssignment:(id)p leftBranch:(id)leftNode withValue:(id)aValue;
- (id)		doFunctionCall:(id)p;
- (id)		valueArray:(id)p;
- (id)      typeArray:(id)p;
- (id)		doValueAppend:(id)p container:(id)aContainer;
- (id)		defineArray:(id) p;
- (id)		defineVariable:(id) p;
- (id)		processLeftArray:(id) p;
- (id)		processTry:(id) p;
- (id)		processThrow:(id) p;
- (id)      makeException:(id) p;
- (id)      makeDictionary:(id) p;
- (id)      makeArray:(id) p;
- (id)		processIf:(id) p;
- (id)		processUnless:(id) p;
- (id)      bitExtract:(id) p;
- (id)		forLoop:(id) p;
- (id)		waitUntil:(id) p;
- (id)		waitTimeOut:(id) p;
- (id)		whileLoop:(id) p;
- (id)		doLoop:(id) p;
- (id)		doSwitch:(id) p;
- (id)      doCase:(id)p;
- (id)      doCaseRange:(id)p;
- (id)      doCaseRange1:(id)p;
- (id)      doCaseGtE:(id)p;
- (id)      doCaseLtE:(id)p;
- (id)      doCaseGt:(id)p;
- (id)      doCaseLt:(id)p;
- (id)		doDefault:(id)p;
- (id)		processObjC:(id) p;
- (id)		processSelectName:(id) p;
- (id)		processDiv:(id) p;
- (id)		processDIV_ASSIGN:(id) p;
- (id)		doReturn:(id) p;
- (id)		doExit:(id) p;
- (id)		doAssign:(id)p op:(int)opr;
- (id)		postAlarm:(id)p;
- (id)		clearAlarm:(id)p;
- (id)		extractValue:(int)index name:(NSString*)aFunctionName args:(NSArray*)valueArray;
- (id)		sleepFunc:(id)p;
- (id)      yieldFunc:(id)p;
- (id)		timeFunc;
- (id)		runShellCmd:(id)p;
- (id)		writeLine:(id) p;
- (id)		deleteFile:(id) p;
- (id)		getStringFromFile:(id) p;
- (id)      confirmWithUser:(id) p;
- (id)      confirmWithUserTimeout:(id) p;
- (id)      requestFromUser:(id) p;
- (void)    startConfirmSheet:(id)aString;
- (void)    startRequestSheet:(id)aString;
- (void)    endRequestSheet;
- (id)      showStatusDialog:(id) p;
- (id)      genRandom:(id) p;
- (id)      valueArray:(id)p;
- (id)      addNodes:(id)p;
- (id)      processGlobalBranches:(id)p;
- (id)      processGlobals:(id)p;
- (id)      doGlobalVar:(id)p;
- (id)      doGlobalAssign:(id)p;
- (void)    addVariabletoCheckDictionary:(NSString *)aVariable;

- (NSMutableDictionary*) makeSymbolTable;
- (NSComparisonResult) compare:(id)a to:(id)b;
@end

@interface ORNodeEvaluator (Graph_Private)
- (id) printNode:(id)p atLevel:(int)aLevel lastOne:(BOOL)lastChild;
- (id) finalPass:(id)string;
@end

@implementation ORNodeEvaluator

#pragma mark •••Initialization
- (id) initWithFunctionTable:(id)aFunctionTable functionName:(NSString*)aFunctionName
{
	self = [super init];
	if(self) {
		functionTable = [aFunctionTable retain];
		_two  = [[NSDecimalNumber alloc] initWithInt:2];
		_one  = [[NSDecimalNumber one] retain];
		_zero = [[NSDecimalNumber zero] retain];
		switchLevel = 0;
		functionName = [aFunctionName copy];
		[self setUpSysCallTable];
		symbolTableLock = [[NSLock alloc] init];
        if([aFunctionName isEqualToString:@"main"]){
            [self setGlobalSymbolTable:[NSMutableDictionary dictionary]];
        }
	}
	return self;  
}

-(void)dealloc 
{
    delegate = nil;
	[logFileHandle release];
	[functionTable release];
	[symbolTable release];
    [globalSymbolTable release];
	[_two release];
	[_one release];
	[_zero release];
	[parsedNodes release];
	[sysCallTable release];
	[symbolTableLock release];
	[functionName release];
    [variableCheckDictionary release];
    for(ORStatusController* aShowDialog in statusDialogs){
        [aShowDialog close];
    }
    [statusDialogs release];
	[super dealloc];
}
- (void) closeStatusDialogs
{
    for(ORStatusController* aDialog in statusDialogs){
        [aDialog close];
    }
    [statusDialogs release];
    statusDialogs = nil;
}
- (NSUndoManager*) undoManager
{
	return [(ORAppDelegate*)[NSApp delegate] undoManager];
}

#pragma mark •••Accessors
- (void) setUserResult:(int)aResult
{
    switch(aResult){
        case 0:  userResult = _zero; break;
        case 1:  userResult = _one; break;
        default: userResult = _two; break;
    }
    userResponded = YES;
}

- (NSString*) functionName
{
	return functionName;
}

- (void) setFunctionLevel:(int)aLevel
{
	functionLevel = aLevel;
}

- (int) functionLevel
{
	return functionLevel;
}

- (void) setDelegate:(id)aDelegate
{
	delegate = aDelegate;
}

- (NSString*) scriptName
{
	return [delegate scriptName];
}


#pragma mark •••Symbol Table Routines
- (void) setUpSysCallTable
{
	if(sysCallTable)[sysCallTable release];
	sysCallTable = [[NSMutableDictionary dictionary] retain];
	
	[sysCallTable setObject: [ORSysCall sysCall:&powf	name:@"pow"		numArgs:2] forKey:@"pow"];
	[sysCallTable setObject: [ORSysCall sysCall:&fmodf	name:@"fmod"	numArgs:2] forKey:@"fmod"];
	[sysCallTable setObject: [ORSysCall sysCall:&sqrtf	name:@"sqrt"	numArgs:1] forKey:@"sqrt"];
	[sysCallTable setObject: [ORSysCall sysCall:&ceilf	name:@"ceil"	numArgs:1] forKey:@"ceil"];
	[sysCallTable setObject: [ORSysCall sysCall:&floorf	name:@"floor"	numArgs:1] forKey:@"floor"];
	[sysCallTable setObject: [ORSysCall sysCall:&roundf	name:@"round"	numArgs:1] forKey:@"round"];
	[sysCallTable setObject: [ORSysCall sysCall:&cosf	name:@"cos"		numArgs:1] forKey:@"cos"];
	[sysCallTable setObject: [ORSysCall sysCall:&sinf	name:@"sin"		numArgs:1] forKey:@"sin"];
	[sysCallTable setObject: [ORSysCall sysCall:&tanf	name:@"tan"		numArgs:1] forKey:@"tan"];
	[sysCallTable setObject: [ORSysCall sysCall:&acosf	name:@"acos"	numArgs:1] forKey:@"acos"];
	[sysCallTable setObject: [ORSysCall sysCall:&asinf	name:@"asin"	numArgs:1] forKey:@"asin"];
	[sysCallTable setObject: [ORSysCall sysCall:&atanf	name:@"atan"	numArgs:1] forKey:@"atan"];
	[sysCallTable setObject: [ORSysCall sysCall:&fabsf	name:@"abs"		numArgs:1] forKey:@"abs"];
	[sysCallTable setObject: [ORSysCall sysCall:&expf	name:@"exp"		numArgs:1] forKey:@"exp"];
	[sysCallTable setObject: [ORSysCall sysCall:&logf	name:@"log"		numArgs:1] forKey:@"log"];
	[sysCallTable setObject: [ORSysCall sysCall:&log10f	name:@"log10"	numArgs:1] forKey:@"log10"];
}

- (void) setArgs:(id)someArgs
{	
	int i=0;
	id anItem;
	NSEnumerator* e = [someArgs objectEnumerator];
	while(anItem = [e nextObject]){	
		if([anItem isKindOfClass:[NSDictionary class]]){
            [globalSymbolTable threadSafeSetObject:[anItem objectForKey:@"iValue"] forKey:[anItem objectForKey:@"name"] usingLock:symbolTableLock];
		}
		else {
            [globalSymbolTable threadSafeSetObject:anItem forKey:[NSString stringWithFormat:@"$%d",i] usingLock:symbolTableLock];
			i++;
		}
	}
}

//------------------
// external access to the 'min' set of symbols

- (NSUInteger) symbolTableCount
{
	[symbolTableLock lock];

	int theCount = [[self minSymbolTable] count];
	[symbolTableLock unlock];
	return theCount;
}

- (id) symbolNameForIndex:(int)i
{
	id theName = @"";
	[symbolTableLock lock];
	NSMutableDictionary* subsetTable = [self minSymbolTable];
	if(i<[subsetTable count]){
		NSArray* keys = [[subsetTable allKeys] sortedArrayUsingSelector:@selector(compare:)];
		theName = [[[keys objectAtIndex:i] retain] autorelease];
	}
	[symbolTableLock unlock];

	return theName;
}

- (id) symbolValueForIndex:(int)i
{
	id theValue = @"";
	[symbolTableLock lock];
	NSMutableDictionary* subsetTable = [self minSymbolTable];
	if(i<[subsetTable count]){
		NSArray* keys = [[subsetTable allKeys] sortedArrayUsingSelector:@selector(compare:)];
		 theValue = [[[subsetTable objectForKey:[keys objectAtIndex:i]] retain] autorelease];
	}
	[symbolTableLock unlock];
	
	return theValue;
}

- (void) setValue:(id)aValue forIndex:(int) anIndex
{
	[symbolTableLock lock];
	if(!aValue)aValue = _zero;
	NSArray* keys = [[[self minSymbolTable] allKeys] sortedArrayUsingSelector:@selector(compare:)];
	[symbolTable setObject:aValue forKey:[keys objectAtIndex:anIndex]];
	[symbolTableLock unlock];	
}
//------------------


- (NSMutableDictionary*) minSymbolTable
{
	NSMutableDictionary* minSymbolTable = [symbolTable mutableCopy];
	
	[minSymbolTable removeObjectsForKeys:[NSArray arrayWithObjects:	@"nil",
																	@"NULL",
																	@"FALSE",
																	@"false",
																	@"true",
																	@"TRUE",
																	@"no",
																	@"NO",
																	@"yes",
																	@"YES",
																	nil]];
	 
	return [minSymbolTable autorelease];
}
- (NSDictionary*) globalSymbolTable
{
    return globalSymbolTable;
}
- (void) setGlobalSymbolTable:(NSMutableDictionary*)aDict;
{
    [aDict retain];
    [globalSymbolTable release];
    globalSymbolTable = aDict;
}
- (NSDictionary*) symbolTable
{
    return symbolTable;
}
- (void) setSymbolTable:(NSDictionary*)aSymbolTable
{
	if(!aSymbolTable){
        [symbolTable release];
        symbolTable = nil;
        return;
    }
	
	if(!symbolTable)symbolTable = [[self makeSymbolTable] retain];
	[symbolTable addEntriesFromDictionary:aSymbolTable];
}

- (id) valueForSymbol:(NSString*) aKey
{
    id aValue = nil;
    if([globalSymbolTable objectForKey:aKey]){
        aValue  = [globalSymbolTable threadSafeObjectForKey:aKey usingLock:symbolTableLock];
    }
    else {
        if(!symbolTable)symbolTable = [[self makeSymbolTable] retain];
        aValue  = [symbolTable threadSafeObjectForKey:aKey usingLock:symbolTableLock];
        if(!aValue){
            aValue = _zero;
            [self setValue:aValue forSymbol:aKey];
        }
    }
	return aValue;
}

- (id) setValue:(id)aValue forSymbol:(id) aSymbol
{
	if(!aSymbol)aValue = _zero; //shouldn't happen, but can't put a nil into the dictionary
	
    if([globalSymbolTable objectForKey:aSymbol]){
        [globalSymbolTable threadSafeSetObject:aValue forKey:aSymbol usingLock:symbolTableLock];
    }
    else {
        if(!symbolTable)symbolTable = [[self makeSymbolTable] retain];
        if(!aValue)aValue = _zero;
        [symbolTable threadSafeSetObject:aValue forKey:aSymbol usingLock:symbolTableLock];
    }
	return aValue;
}

- (NSDictionary*) makeSymbolTableFor:(NSString*)aFunctionName args:(id)argObject
{
	if(!argObject)return nil;
	
	NSString* argumentNameString = [self execute:[functionTable objectForKey:[NSString stringWithFormat:@"%@_ArgNode",aFunctionName]] container:nil];
	NSArray* argKeys = [argumentNameString componentsSeparatedByString:@","];
	if([argKeys count] == [argObject count]){
        NSMutableDictionary* symbolTableForFunction = [self makeSymbolTable];
		if([argObject count]){
            [symbolTableForFunction addEntriesFromDictionary:[NSDictionary dictionaryWithObjects:argObject forKeys:argKeys]];
		}
        return symbolTableForFunction;
	}
	else {
		//arg count mismatch
		//allow main to be special and ignore input arg if none declared
		if([aFunctionName isEqualToString:@"main"] && [argKeys count]==0){
			return nil;
		}
		else {
			NSLogColor([NSColor redColor],@"[%@] %@ called with wrong number of arguments. Check the syntax.\n",[self scriptName],aFunctionName);
			[NSException raise:@"Run time" format:@"Wrong number of Arguments"];
		}
	}
	return nil;
}


#pragma mark •••Individual Evaluators
#define NodeValue(aNode) [self execute:[[p nodeData] objectAtIndex:aNode] container:nil]
#define NodeValueWithContainer(aNode,aContainer) [self execute:[[p nodeData] objectAtIndex:aNode] container:aContainer]
#define VARIABLENAME(aNode)  [[[p nodeData] objectAtIndex:aNode] nodeData]
#define LineNumber(aNode) [[[p nodeData] objectAtIndex:0] line]

- (id) execute:(id) p container:(id)aContainer
{
	[delegate checkBreakpoint:[p line] functionLevel:functionLevel];
	if([delegate exitNow])return _zero;
    if (!p) return nil;
    switch([(Node*)p type]) {
		case typeCon:				return [p nodeData];
		case typeStr:				return [p nodeData];
		case typeOperationSymbol:   return [p nodeData];
		case typeId:				return [self valueForSymbol:[p nodeData]];
		case typeArg:				return [self valueForSymbol:[p nodeData]];
		case typeSelVar:			return [p nodeData];
		case typeOpr:				return [self doOperation:p container:aContainer];
	}
	return nil; //should never actually get here.
}


#pragma mark •••Finders and Helpers

- (id) makeObject:(id) p
{
	return [ObjectFactory makeObject:VARIABLENAME(0)];
}

- (id) sortObject:(id) p
{
    return [self sortObject:p ascending:YES];

}
- (id) sortObjectR:(id) p
{
    return [self sortObject:p ascending:NO];
}
- (id) sortObject:(id)p ascending:(BOOL)ascending
{
    id  collectionObj = NodeValue(0);
    if([collectionObj isKindOfClass:NSClassFromString(@"NSDictionary")]){
        //convert to an array of the keys and sort the keys
        collectionObj = [collectionObj allKeys];
    }
    
    if([collectionObj isKindOfClass:NSClassFromString(@"NSArray")]){
        NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: ascending];
        return [collectionObj sortedArrayUsingDescriptors: [NSArray arrayWithObject: sortOrder]];
    }
    else if([collectionObj isKindOfClass:NSClassFromString(@"NSString")]){
        return collectionObj;
    }
    else return collectionObj;
}

- (id) findObject:(id) p
{
	//needs to return NSDecimalNumber holding the obj pointer.
	NSString* theClassName = VARIABLENAME(0);
	Class theClass = NSClassFromString(theClassName);
	if([theClass isEqualTo:[[(ORAppDelegate*)[NSApp delegate] document] class]]){
		return [(ORAppDelegate*)[NSApp delegate] document];
	}
	else {
		NSArray* objects = [[(ORAppDelegate*)[NSApp delegate]  document] collectObjectsOfClass:theClass];
		if([objects count] == 0)return _zero;
		id anObj = [objects objectAtIndex:0];
		if([anObj isKindOfClass:NSClassFromString(@"ORVmeDaughterCard")])  return [self findVmeDaughterCard:p collection:objects];
		else if([anObj isKindOfClass:NSClassFromString(@"ORCard")])  return [self findCard:p collection:objects];
		else if([anObj isKindOfClass:NSClassFromString(@"ORCrate")])  return [self findCrate:p collection:objects];
		else {
			int numArgs = [[p nodeData] count];
			if(numArgs == 1){
				//use the first obj found
				return [objects objectAtIndex:0];
			}
			else {
				//assume node 1 holds a tag #
				int tag = [NodeValue(1) longValue];
				id anObj;
				NSEnumerator* e = [objects objectEnumerator];
				while(anObj = [e nextObject]){
					if([anObj respondsToSelector:@selector(uniqueIdNumber)]){
						if([anObj uniqueIdNumber] == tag) {
							return anObj; 
						}
					}
				}
				return _zero;
			}
		}
	}
}

- (id) findCrate:(id)p collection:objects
{
	id anObj;
	NSEnumerator* e = [objects objectEnumerator];
	int numArgs = [[p nodeData] count];
	int crateNumber;
	if(numArgs == 1){
		crateNumber = 0;
	}
	else if(numArgs == 2){
		crateNumber = [NodeValue(1) intValue];
	}
	else return _zero;
	
	while(anObj = [e nextObject]){
		if([anObj respondsToSelector:@selector(crateNumber)]){
			if([anObj crateNumber] == crateNumber) {
				return anObj; 
			}
		}
	}
	return _zero;
}

- (id) findCard:(id)p collection:objects
{
	//CAMAC and AUGER use station numbers instead of slot number (station numbers are +1)
	id anObj;
	NSEnumerator* e = [objects objectEnumerator];
	int numArgs = [[p nodeData] count];
	int crateNumber, cardNumber;
	if(numArgs == 3){
		//both crate and slot numbers are included
		crateNumber = [NodeValue(1) intValue];
		cardNumber  = [NodeValue(2) intValue];
	}
	else if(numArgs == 2){
		//only a slot number is included
		crateNumber = 0;
		cardNumber = [NodeValue(1) intValue];
	}
	else return _zero;
	
	while(anObj = [e nextObject]){
		if([anObj respondsToSelector:@selector(stationNumber)]){
			if([anObj crateNumber] == crateNumber && [anObj stationNumber] == cardNumber) {
				return anObj; 
			}
		}
		else {
			if([anObj crateNumber] == crateNumber  && [anObj slot] == cardNumber){
				return anObj;
			}
		}
	}
	return _zero;
}


- (id) findVmeDaughterCard:(id)p collection:objects
{
	id anObj;
	NSEnumerator* e = [objects objectEnumerator];
	int numArgs = [[p nodeData] count];
	int crateNumber, carrierSlot,cardNumber;
	if(numArgs == 4){
		//both crate and slot numbers are included
		crateNumber = [NodeValue(1) intValue];
		carrierSlot  = [NodeValue(2) intValue];
		cardNumber  = [NodeValue(3) intValue];
	}
	else if(numArgs == 3){
		//only a slot number is included
		crateNumber = 0;
		carrierSlot  = [NodeValue(1) intValue];
		cardNumber  = [NodeValue(2) intValue];
	}
	else return _zero;
	
	while(anObj = [e nextObject]){
		if([anObj crateNumber] == crateNumber  && [[anObj guardian] slot] == carrierSlot &&  [anObj slot] == cardNumber){
			return anObj;
		}
	}
	return _zero;
}

- (id) sciString:(id) p precision:(id)thePrecision
{
	if([p isKindOfClass:NSClassFromString(@"NSDecimalNumber")]){
		NSString* format = [NSString stringWithFormat:@"%%.%dE",[thePrecision intValue]];
		return [NSString stringWithFormat:format,[p floatValue]];
	}
	return _zero;
}

- (id) fixedString:(id) p precision:(id)thePrecision
{
	if([p isKindOfClass:NSClassFromString(@"NSDecimalNumber")]){
		NSString* format = [NSString stringWithFormat:@"%%.%df",[thePrecision intValue]];
		return [NSString stringWithFormat:format,[p floatValue]];
	}
	return _zero;
}

- (void) printAll:(NSArray*)someNodes
{
    [variableCheckDictionary release];
    variableCheckDictionary = nil;
	for(id aNode in someNodes){
		[self printNode:aNode];
	}
    [self checkForCaseIssues];
}

- (void) checkForCaseIssues
{
    int firstOne = YES;
    for(NSString* aKey in [variableCheckDictionary allKeys]){
        NSArray* vars = [variableCheckDictionary objectForKey:aKey];
        if([vars count] > 1){
            if(firstOne){
                firstOne = NO;
                NSLogColor([NSColor redColor],@"Possible Issue: the following variables differ only in case:\n");
            }
            NSLog(@"%@\n",vars);
        }
    }
}

- (BOOL) exitNow
{
	return [delegate exitNow];
}

-(id) printNode:(id) p 
{
    int level = 0;
    NSString* theTree = [self finalPass:[self printNode:p atLevel:level lastOne:NO]];
    BOOL printWholeTree = ([[NSApp currentEvent] modifierFlags] & 0x80000)>0; //option key is down

    if(printWholeTree){
        NSLogFont([NSFont fontWithName:@"Monaco" size:9.0],@"\n%@",theTree);
    }
    return _zero;
}

- (ORNodeEvaluator*) functionEvaluator
{
	if(functionEvaluator)return [functionEvaluator functionEvaluator];
	else return self;
}


@end

@implementation ORNodeEvaluator (Interpret_private)
- (void) addVariabletoCheckDictionary:(NSString *)aVariable
{
    //don't card about the logic fixed variables
    if([aVariable isEqualToString:@"YES"])  return;
    if([aVariable isEqualToString:@"NO"])   return;
    if([aVariable isEqualToString:@"FALSE"])return;
    if([aVariable isEqualToString:@"TRUE"])  return;
    
    if(!variableCheckDictionary)variableCheckDictionary= [[NSMutableDictionary dictionary]retain];
    NSString* aKey = [aVariable uppercaseString];
    NSMutableArray* allLikeThis = [variableCheckDictionary objectForKey:aKey];
    if(!allLikeThis)allLikeThis = [NSMutableArray array];
    BOOL exists = NO;
    for(NSString* anEntry in allLikeThis){
        if([anEntry isEqualToString:aVariable]){
            exists = YES;
            break;
        }
    }
    if(!exists) [allLikeThis addObject:aVariable];
    
    [variableCheckDictionary setObject:allLikeThis forKey:aKey];
}

- (id) doOperation:(id) p container:(id)aContainer
{
	NSComparisonResult result;
	id val;
	switch([[p nodeData] operatorTag]) {
			
		case ';':				return [self processStatements:p];
		case kFuncCall:			return [self doFunctionCall:p];
        case '#':               return [self valueArray:p];
        case '$':               return [self typeArray:p];
		case kMakeArgList:		return [self doValueAppend:p container:aContainer];
		case ',':				return [[NSString stringWithFormat:@"%@",NodeValue(0)] stringByAppendingString:[@"," stringByAppendingFormat:@"%@",NodeValue(1)]];
        case GLOBAL:            return [self processGlobals:p];
        case kGlobal:           return [self processGlobalBranches:p];
        case kGlobalVar:        return [self doGlobalVar:p];
        case kGlobalAssign:     return [self doGlobalAssign:p];
        case SELFFUNCTION:      return [self functionName];
        case SYMBOLS:           return [self symbolTable];
        case GLOBALS:           return [self globalSymbolTable];
        case kDefineArray:      return [self defineArray:p];
		case kLeftArray:		return [self processLeftArray:p];
		case kArrayAssign:		return [self arrayAssignment:p leftBranch:[[p nodeData] objectAtIndex:0] withValue:NodeValue(1)];
		case kArrayListAssign:	return [self arrayList:p];
			
			//loops
		case FOR:			return [self forLoop:p];
		case BREAK:			[NSException raise:@"break"    format:@""]; return nil;
		case CONTINUE:		[NSException raise:@"continue" format:@""]; return nil;
		case EXIT:			return [self doExit:p];
		case RETURN:		return [self doReturn:p];
		case WHILE:			return [self whileLoop:p];
		case DO:			return [self doLoop:p];
		case SWITCH:		return [self doSwitch:p];
        case CASE:          return [self doCase:p];
        case kCaseRange:    return [self doCaseRange:p];
        case kCaseRange1:   return [self doCaseRange1:p];
        case kCaseGtE:      return [self doCaseGtE:p];
        case kCaseLtE:      return [self doCaseLtE:p];
        case kCaseGt:       return [self doCaseGt:p];
        case kCaseLt:       return [self doCaseLt:p];
		case DEFAULT:		return [self doDefault:p];
			
        //built-in funcs
		case SLEEP:			return [self sleepFunc:p];
		case YIELD:			return [self yieldFunc:p];
		case TIME:			return [self timeFunc];
		case CONFIRM:       return [self confirmWithUser:p];
		case REQUEST:       return [self requestFromUser:p];
		case kConfirmTimeOut:	return [self confirmWithUserTimeout:p];
		case SHOW:          return [self showStatusDialog:p];
		case NSDICTIONARY:	return [self makeDictionary:p];
		case NSARRAY:       return [self makeArray:p];

		case MAKEEXCEPTION:	return [self makeException:p];
        case NSDATECOMPONENTS:
        {
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
            NSCalendar* cal = [[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian] autorelease];
            return  [cal components:
                     NSCalendarUnitYear |
                     NSCalendarUnitMonth |
                     NSCalendarUnitWeekday |
                     NSCalendarUnitDay |
                     NSCalendarUnitHour |
                     NSCalendarUnitMinute |
                     NSCalendarUnitSecond
                           fromDate:[NSDate date]];
#else
            NSCalendar* cal = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
            return  [cal components:
                     NSYearCalendarUnit |
                     NSMonthCalendarUnit |
                     NSWeekdayCalendarUnit |
                     NSDayCalendarUnit |
                     NSHourCalendarUnit |
                     NSMinuteCalendarUnit |
                     NSSecondCalendarUnit
                           fromDate:[NSDate date]];
#endif
        }
        case SEEDRANDOM:        {
            time_t t;
            time(&t);
            srand((unsigned int)t);
        }
        case RANDOM:            return [self genRandom:p];
		case NSFILEMANAGER:		return [NSFileManager defaultManager];
		case STRINGFROMFILE:	return [self getStringFromFile:p];
		case WRITELINETOFILE:	return [self writeLine:p];
		case DELETEFILE:		return [self deleteFile:p];
		case DISPLAY:		return [delegate display:NodeValue(1) forKey:NodeValue(0)];
		case WAITUNTIL:		return [self waitUntil:p];
		case kWaitTimeOut:	return [self waitTimeOut:p];
		case MAKESTRING:	return [self makeString:p];
		case CATSTRING:		return [self catString:p];
		case ALARM:			return [self postAlarm:p];
		case CLEAR:			return [self clearAlarm:p];
		case SHELL:			return [self runShellCmd:p];
			
			//printing
        case PRINT:         return [self print:p];
		case PRINTFILE:		return [self printFile:p];
		case LOGFILE:		return [self openLogFile:p];
		case kAppend:		return [[NSString stringWithFormat:@"%@",NodeValue(0)] stringByAppendingString:[@" " stringByAppendingFormat:@"%@",NodeValue(1)]];
		case kTightAppend:	return [[NSString stringWithFormat:@"%@",NodeValue(0)] stringByAppendingString:[NSString stringWithFormat:@"%@",NodeValue(1)]];
		case HEX:			return [NSString stringWithFormat:@"0x%lx",(unsigned long)[NodeValue(0) unsignedLongValue]];
		case MAKEPOINT:		return [NSString stringWithFormat:@"@(%@,%@)",NodeValue(0),NodeValue(1)];
		case MAKERECT:		return [NSString stringWithFormat:@"@(%@,%@,%@,%@)",NodeValue(0),NodeValue(1),NodeValue(2),NodeValue(3)];
		case MAKESIZE:		return [NSString stringWithFormat:@"@(%@,%@)",NodeValue(0),NodeValue(1)];
		case MAKERANGE:		return [NSString stringWithFormat:@"@(%@,%@)",NodeValue(0),NodeValue(1)];
		case FIXED:			return [self fixedString:NodeValue(0) precision:NodeValue(1)];
		case SCI:			return [self sciString:NodeValue(0) precision:NodeValue(1)];

			//obj-C ops
		case '@':			return [self processObjC:p];
		case kObjList:		return [NodeValue(0) stringByAppendingFormat:@"%@",NodeValue(1)];
		case kSelName:		return [self processSelectName:p];
		case FIND:			return [self findObject:p];
        case MAKE:          return [self makeObject:p];
        case SORT:          return [self sortObject:p];
        case SORTR:         return [self sortObjectR:p];

			//math ops
		case '=':			return [self setValue: NodeValue(1) forSymbol:[[[p nodeData] objectAtIndex:0] nodeData]];
		case UMINUS:		return [[NSDecimalNumber decimalNumberWithString:@"-1"] decimalNumberByMultiplyingBy:NodeValue(0)];
		case '%':			return [NSDecimalNumber numberWithLong:[NodeValue(0) longValue] % [NodeValue(1) longValue]];
		case '+':			return [self addNodes:p];
		case '-':			return [NodeValue(0) decimalNumberBySubtracting: NodeValue(1)];
		case '*':			return [NodeValue(0) decimalNumberByMultiplyingBy: NodeValue(1)];
		case '/':			return [self processDiv:p];
		case ADD_ASSIGN:	return [self doAssign:p op:ADD_ASSIGN];
		case SUB_ASSIGN:	return [self doAssign:p op:SUB_ASSIGN];
		case MUL_ASSIGN:	return [self doAssign:p op:MUL_ASSIGN];
		case DIV_ASSIGN:	return [self doAssign:p op:DIV_ASSIGN];
		case OR_ASSIGN:		return [self doAssign:p op:OR_ASSIGN];
		case LEFT_ASSIGN:	return [self doAssign:p op:LEFT_ASSIGN];
		case RIGHT_ASSIGN:	return [self doAssign:p op:RIGHT_ASSIGN];
		case MOD_ASSIGN:	return [self doAssign:p op:MOD_ASSIGN];
		case XOR_ASSIGN:	return [self doAssign:p op:XOR_ASSIGN];
		case AND_ASSIGN:	return [self doAssign:p op:AND_ASSIGN];
			
			//bit ops
		case '&':			return [NSDecimalNumber numberWithLong:[NodeValue(0) longValue] & [NodeValue(1) longValue]];
		case '|':			return [NSDecimalNumber numberWithLong:[NodeValue(0) longValue] | [NodeValue(1) longValue]];
		case LEFT_OP:		return [NSDecimalNumber numberWithLong:[NodeValue(0) longValue] << [NodeValue(1) longValue]];
		case RIGHT_OP:		return [NSDecimalNumber numberWithLong:[NodeValue(0) longValue] >> [NodeValue(1) longValue]];
		case '~':			return [NSDecimalNumber numberWithLong: ~[NodeValue(0) longValue]];
		case '^':			return [NSDecimalNumber numberWithLong: [NodeValue(0) longValue] ^ [NodeValue(1) longValue]];
            //exception handling
		case TRY:			return [self processTry:p];
		case THROW:			return [self processThrow:p];

			//logic
		case IF:			return [self processIf:p];
		case UNLESS:		return [self processUnless:p];
		case kConditional:  
		{
			if([NodeValue(0) isKindOfClass:[NSNumber class]]){
				return [NodeValue(0) boolValue] ? NodeValue(1) : NodeValue(2);
			}
			else return NodeValue(0)  ? NodeValue(1) : NodeValue(2);
		}
            
        case kBitExtract: return [self bitExtract:p];
            
		case '!':  
		{
            id result = NodeValue(0);
			if([result isKindOfClass:[NSNumber class]]){
                
				if([result intValue]==0)return _one;
				else return _zero;
			}
			else if(result==0)return _one;
			else return _zero;
		}
			
		case AND_OP:
			if([NodeValue(0) longValue] && [NodeValue(1) longValue]) return _one;
			else return _zero;
			
		case OR_OP:
			if([NodeValue(0) longValue] || [NodeValue(1) longValue]) return _one;
			else return _zero;
			
		case '>':       
			if([self compare:NodeValue(0) to: NodeValue(1)] == NSOrderedDescending) return _one;
			else return _zero;
			
		case '<':       
			   if([self compare:NodeValue(0) to: NodeValue(1)]==NSOrderedAscending)return _one;
			else return _zero;
			
		case LE_OP:       
			   result = [self compare:NodeValue(0) to: NodeValue(1)];
			if(result==NSOrderedSame || result==NSOrderedAscending)return _one;
			else return _zero;
			
		case GE_OP: 
			   result = [self compare:NodeValue(0) to: NodeValue(1)];
			if(result==NSOrderedSame || result==NSOrderedDescending)return _one;
			else return _zero;
			
		case NE_OP:       
			   result = [self compare:NodeValue(0) to: NodeValue(1)];
			if(result!=NSOrderedSame)return _one;
			else return _zero;
			
		case EQ_OP:   
			result = [self compare:NodeValue(0) to: NodeValue(1)];
			if(result==NSOrderedSame)return _one;
			else return _zero;
			   
			//inc/dec ops
		case kPreInc: return  [self setValue:[NodeValue(0) decimalNumberByAdding: _one] forSymbol:[[[p nodeData] objectAtIndex:0] nodeData]];
		case kPreDec: return [self setValue:[NodeValue(0) decimalNumberBySubtracting: _one] forSymbol:[[[p nodeData] objectAtIndex:0] nodeData]];
			
		case kPostInc:
		{
			val = NodeValue(0);
			[self setValue:[val decimalNumberByAdding: _one] forSymbol:[[[p nodeData] objectAtIndex:0] nodeData]];
			return val;
		}
			
		case kPostDec:
		{
			val = NodeValue(0);
			[self setValue:[val decimalNumberBySubtracting: _one] forSymbol:[[[p nodeData] objectAtIndex:0] nodeData]];
			return val;
		}
	}
    return _zero; //should never actually get here.
}

- (id) processDiv:(id) p
{
	id result = nil;
	@try {
		result =  [NodeValue(0) decimalNumberByDividingBy:NodeValue(1)];
	}
	@catch(NSException* localException) {
		NSLog(@"divide by zero in %@\n",[self scriptName]);
		result = [NSDecimalNumber notANumber];
	}
	return result;
}

- (id) processDIV_ASSIGN:(id)p
{
	id result = nil;
	@try {
		result =  [self setValue:[NodeValue(0) decimalNumberByDividingBy:NodeValue(1)] forSymbol:VARIABLENAME(0)];
	}
	@catch(NSException* localException) {
		NSLog(@"divide by zero in %@\n",[self scriptName]);
		result = [NSDecimalNumber notANumber];
	}
	return result;
}

- (id) doAssign:(id)p op:(int)opr
{
	long value = [NodeValue(0) longValue];
	switch(opr){
		case LEFT_ASSIGN:  value <<= [NodeValue(1) longValue]; break;
		case RIGHT_ASSIGN: value >>= [NodeValue(1) longValue]; break;
		case MOD_ASSIGN:   value %=  [NodeValue(1) longValue]; break;
		case XOR_ASSIGN:   value ^=  [NodeValue(1) longValue]; break;
		case AND_ASSIGN:   value &=  [NodeValue(1) longValue]; break;
		case OR_ASSIGN:    value |=  [NodeValue(1) longValue]; break;
		case ADD_ASSIGN:	return [self setValue:[NodeValue(0) decimalNumberByAdding:NodeValue(1)] forSymbol:VARIABLENAME(0)];
		case SUB_ASSIGN:	return [self setValue:[NodeValue(0) decimalNumberBySubtracting:NodeValue(1)] forSymbol:VARIABLENAME(0)];
		case MUL_ASSIGN:	return [self setValue:[NodeValue(0) decimalNumberByMultiplyingBy:NodeValue(1)] forSymbol:VARIABLENAME(0)];
		case DIV_ASSIGN:	return [self processDIV_ASSIGN:p];
	}	
	return [self setValue:[NSDecimalNumber numberWithLong:value] forSymbol:VARIABLENAME(0)];
}

- (id) processObjC:(id) p
{
	NSString* argList = NodeValue(1); //argList is string with the format name:value#name:value#etc...
	argList = [argList stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	argList = [argList stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"#"]];
	id result= nil;
    // The following can throw exceptions, but this what we want.
    id target = NodeValue(0);
    if(target != _zero){
        result =  [NSInvocation invoke:argList withTarget:target];
    }
	if(result == nil) return _zero;
	else			  return result;
}

- (id) processSelectName:(id) p
{
	id selName  = NodeValue(0);
	id selValue = NodeValue(1);
	return [NSString stringWithFormat:@"%@:%lu#",selName,(unsigned long)selValue];
}

- (id) processStatements:(id) p
{
	unsigned numNodes = [[p nodeData] count];
	int i;
	for(i=0;i<numNodes;i++)NodeValue(i);
	return nil;
}

- (id) processGlobals:(id) p
{
    NodeValue(0);
    return nil;
}

- (id) print:(id) p
{
	NSString* s = [[delegate scriptName] length]?[delegate scriptName]:@"OrcaScript";
	id output = NodeValue(0);
	NSLog(@"[%@] %@\n",s, output);
	return nil;
}	

- (id) printFile:(id) p
{
	id output = NodeValue(0);
	
	if(logFileHandle){
        NSString* s1 = [NSString stringWithFormat:@"%@ %@\n",[NSDate date],output];
		[logFileHandle writeData:[s1 dataUsingEncoding:NSASCIIStringEncoding]];
	}
	
	return nil;
}	

- (id) runShellCmd:(id)p
{
	//blocks
	NSString* s = NodeValue(0);
	s = [s trimSpacesFromEnds];
	s = [s removeExtraSpaces];
	NSLog(@"Shell: %@\n",s);
	NSMutableArray* parts = [[[s componentsSeparatedByString:@" "] mutableCopy] autorelease];
	if([parts count]){
		NSString* command = [[[parts objectAtIndex:0] retain] autorelease];
		NSArray* args = nil;
		if([parts count] >=2){
			[parts removeObjectAtIndex:0];
			args = parts;
		}
		NSTask *task			 = [[NSTask alloc] init];
		NSPipe *newPipe			 = [NSPipe pipe];
		NSFileHandle *readHandle = [newPipe fileHandleForReading];
		[task setLaunchPath:command];
		if(args)[task setArguments:args];
		[task setStandardOutput:newPipe];
		[task setStandardError:newPipe];
		[task launch];
		NSData* inData = [readHandle readDataToEndOfFile];
		NSString* tempString = [[NSString alloc] initWithData:inData encoding:NSASCIIStringEncoding];
		[task release];
		[tempString autorelease];
        [readHandle closeFile];
		NSLog(@"%@\n", tempString);
	}
	return nil;
}

- (id) openLogFile:(id) p
{
	NSString*       s = [[self scriptName] length]?[self scriptName]:@"OrcaScript";
	NSFileManager* fm = [NSFileManager defaultManager];
	NSString*    shortPath = NodeValue(0);
	NSString*    path = [shortPath stringByExpandingTildeInPath];
	NSLog(@"[%@] using %@ as log file\n",s,[path stringByAbbreviatingWithTildeInPath]);
	if(![fm fileExistsAtPath:path]){
		BOOL fileCreated = [fm createFileAtPath:path contents:nil attributes:nil];
		if(!fileCreated) NSLogColor([NSColor redColor], @"[%@] unable to create log file %@\n",s, [path stringByAbbreviatingWithTildeInPath]);
	}
	[logFileHandle closeFile];
	[logFileHandle release];
	logFileHandle = [[NSFileHandle fileHandleForUpdatingAtPath:path] retain];
	if(!logFileHandle){
		NSLogColor([NSColor redColor], @"[%@] unable to open log file %@\n",s, [path stringByAbbreviatingWithTildeInPath]);
	}
	[logFileHandle seekToEndOfFile];
	return nil;
}	

- (id) makeString:(id) p
{
	return NodeValue(0); 
}	

- (id) catString:(id) p
{
	NSString* s = NodeValue(0);
	return s;
	//return [[s componentsSeparatedByString:@" "] componentsJoinedByString:@""]; 
}	

- (id) dataFromString:(id) p
{
	NSString* d = [NSString stringWithString:NodeValue(0)];
	return [d dataUsingEncoding:NSASCIIStringEncoding];;
}	

- (id) getStringFromFile:(id) p
{
	NSString* s = NodeValue(0);
	s = [s stringByExpandingTildeInPath];
	NSString* contents = [NSString stringWithContentsOfFile:s encoding:NSASCIIStringEncoding error:nil];
    if([contents length])return contents;
    else return @"";
}

- (id) requestFromUser:(id) p
{
    userResponded = NO;
    [self performSelectorOnMainThread:@selector(startRequestSheet:) withObject:NodeValue(0) waitUntilDone:NO];
	do {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		if([self exitNow]){
			[pool release];
			break;
		}
		else {
            if(userResponded){
                [pool release];
                break;
            }
		}
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
		[pool release];
	} while(1);
    [self performSelectorOnMainThread:@selector(endRequestSheet) withObject:nil waitUntilDone:YES];

    return userResult;
}

- (void) startRequestSheet:(id)aString
{
    userDialogController = [[ORScriptUserRequestController alloc] initWithDelegate:self
                                                                          title:[NSString stringWithFormat:@"%@\nRequests Input",[delegate scriptName]]
                                                                  variableList:aString];
	[userDialogController showWindow:self];
}

- (void) endRequestSheet
{
    [userDialogController close];
    [userDialogController release];
    userDialogController = nil;
  
}
- (id) showStatusDialog:(id) p
{
    NSWindowController* statusDialogController = [[ORScriptUserStatusController alloc] initWithDelegate:self variableList:NodeValue(0)];
	[statusDialogController performSelectorOnMainThread:@selector(showWindow:) withObject:self waitUntilDone:YES];
    if(!statusDialogs)statusDialogs = [[NSMutableArray array] retain];
    [statusDialogs addObject:statusDialogController];
    return [statusDialogController autorelease];
}

- (id) confirmWithUser:(id) p
{
    userResponded = NO;
    [self performSelectorOnMainThread:@selector(startConfirmSheet:) withObject:NodeValue(0) waitUntilDone:NO];
	do {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		if([self exitNow]){
			[pool release];
			break;
		}
		else {
            if(userResponded){
                [pool release];
                break;
            }
		}
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
		[pool release];
	} while(1);
    [self performSelectorOnMainThread:@selector(endRequestSheet) withObject:nil waitUntilDone:YES];
    return userResult;
}

- (id) confirmWithUserTimeout:(id)p
{
	//return _zero if user canceled.
	//return _one if user confirmed.
	//return _two if timed-out.
    userResponded = NO;
    [self performSelectorOnMainThread:@selector(startConfirmSheet:) withObject:NodeValue(0) waitUntilDone:NO];
	float timeOut = [NodeValue(1) floatValue];
	do {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		@try {
			if([self exitNow]){
                break;
			}
            else if(userResponded)break;

			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
			timeOut -= .1;
			if(timeOut <= 0){
				[self setUserResult:2];
                [pool release];
                break;
			}
            [userDialogController performSelectorOnMainThread:@selector(setTimeToGo:) withObject:[NSNumber numberWithFloat:timeOut] waitUntilDone:NO];

		}
		@catch(NSException* localException) {
		}
		
		[pool release];
		
	}while(1);
    
    [self performSelectorOnMainThread:@selector(endRequestSheet) withObject:nil waitUntilDone:YES];
    
	return userResult;
}


- (void) startConfirmSheet:(id)aString
{
    userDialogController = [[ORScriptUserConfirmController alloc] initWithDelegate:self
                                                                       title:[NSString stringWithFormat:@"%@\nRequests Confirmation",[delegate scriptName]]
                                                               confirmString:aString];
	[userDialogController showWindow:self];
}

- (id) arrayAssignment:(id)p leftBranch:(id)leftNode withValue:(id)aValue
{
	NSMutableArray* theArray = [self execute:[[leftNode nodeData] objectAtIndex:0] container:nil];
	int n = [[self execute:[[leftNode nodeData] objectAtIndex:1] container:nil] longValue];
	if(n>=0 && n<[theArray count]){
		[theArray replaceObjectAtIndex:n withObject:aValue];
	}
	return nil;
}

- (id) doValueAppend:(id)p container:(id)aContainer
{
	int i;
	for(i=0;i<2;i++){
		id value = NodeValueWithContainer(i,aContainer);
		if(value){
			BOOL doRelease = YES;
			if([value isKindOfClass:[NSMutableArray class]]) value = [value mutableCopy];
			else if(![value isKindOfClass:[OrcaObject class]]) value = [value copy];
			else doRelease = NO;
			[aContainer addObject:value];
			if(doRelease)[value release];
		}
	}
	return nil;
}

- (id) doFunctionCall:(id)p
{
	id returnValue = nil;
	NSString* aFunctionName = VARIABLENAME(0);
	NSMutableArray* argObject = [[[NSMutableArray alloc] initWithCapacity:10]autorelease];
	id result = NodeValueWithContainer(1,argObject);
	if([argObject count] == 0 && result!=nil)[argObject addObject:result];
	
	id someNodes = [functionTable objectForKey:aFunctionName];
	if(someNodes){
        functionEvaluator = [[ORNodeEvaluator alloc] initWithFunctionTable:functionTable functionName:aFunctionName];
		[functionEvaluator setDelegate:delegate];
		[functionEvaluator setFunctionLevel:functionLevel+1];
		[functionEvaluator setSymbolTable:[self makeSymbolTableFor:aFunctionName args:argObject]];
        [functionEvaluator setGlobalSymbolTable:globalSymbolTable];
		@try {
			unsigned i;
			unsigned numNodes = [someNodes count];
			for(i=0;i<numNodes;i++){
				if([delegate exitNow])break;
				id aNode = [someNodes objectAtIndex:i];
				[functionEvaluator execute:aNode container:nil];
			}
		}
		@catch(NSException* localException) {
			if([[localException name] isEqualToString: @"return"]){
				NSDictionary* userInfo = [localException userInfo];
				if(userInfo){
					returnValue = [userInfo objectForKey:@"returnValue"];
				}
			}
			else {
				[functionEvaluator release];
				functionEvaluator = nil;
				[localException raise];
			}
		}
		[functionEvaluator release];
		functionEvaluator = nil;
	}
	else {
		ORSysCall* aCall = [sysCallTable objectForKey:aFunctionName];
		if(aCall) return [aCall executeWithArgs:argObject];
		else if([aFunctionName isEqualToString:@"pointx"])   return [self extractValue:0			name:aFunctionName	args:argObject];
		else if([aFunctionName isEqualToString:@"pointy"])   return [self extractValue:1			name:aFunctionName	args:argObject];
		else if([aFunctionName isEqualToString:@"rectx"])    return [self extractValue:0			name:aFunctionName	args:argObject];
		else if([aFunctionName isEqualToString:@"recty"])    return [self extractValue:1			name:aFunctionName	args:argObject];
		else if([aFunctionName isEqualToString:@"rectw"])    return [self extractValue:2			name:aFunctionName	args:argObject];
		else if([aFunctionName isEqualToString:@"recth"])    return [self extractValue:3			name:aFunctionName	args:argObject];
		else if([aFunctionName isEqualToString:@"rangeloc"]) return [self extractValue:0			name:aFunctionName	args:argObject];
		else if([aFunctionName isEqualToString:@"rangelen"]) return [self extractValue:1			name:aFunctionName	args:argObject];
		else {
			NSLog(@"%@ has no function called %@ in its function table. Check line %d\n",[self scriptName],aFunctionName, [[p nodeData]line]);
			[NSException raise:@"Run time" format:@"Function not found"];
		}
	}
	
	return returnValue;
}

- (id) addNodes:(id)p
{
    id node0 = NodeValue(0);
    id node1 = NodeValue(1);
    if([node0 isKindOfClass:[NSDecimalNumber class]] && [node1 isKindOfClass:[NSDecimalNumber class]]){
        return [node0 decimalNumberByAdding: node1];
    }
    else if([node0 isKindOfClass:[NSString class]] && [node1 isKindOfClass:[NSString class]]){
        return [NSString stringWithFormat:@"%@%@",node0,node1];
    }
    else {
        return [NSString stringWithFormat:@"%@%@",node0,node1];
    }
}

- (id) defineArray:(id) p
{
	int n = [NodeValue(1) longValue];
	NSMutableArray* theArray = [NSMutableArray arrayWithCapacity:n];
	//fill it with zeros;
	int i;
	for(i=0;i<n;i++)[theArray addObject:_zero];
	[self setValue:theArray forSymbol:VARIABLENAME(0)];
	return nil;
}

- (id) arrayList:(id) p
{
	int n = [NodeValue(1) longValue];
	NSMutableArray* argObject = [[[NSMutableArray alloc] initWithCapacity:100] autorelease];
	id result = NodeValueWithContainer(2,argObject);
	if([argObject count] == 0 && result!=nil)[argObject addObject:result];
	int m = [argObject count];
	[self setValue:argObject forSymbol:VARIABLENAME(0)];
	if(n<m)[argObject removeObjectsInRange:NSMakeRange(n,m-n)];
	else {
		int i;
		for(i=0;i<n-m;i++)[argObject addObject:_zero];
	}
	return nil;
}	


- (id) defineVariable:(id) p
{
	if(!symbolTable)symbolTable = [[self makeSymbolTable] retain];
	id varName = VARIABLENAME(0);
	[symbolTable setObject:_zero forKey:varName];	
	return varName;
}

- (id) processLeftArray:(id) p
{
	int n = [NodeValue(1) longValue];
	NSMutableArray* theArray = NodeValue(0);
	if(n>=0 && n<[theArray count]){
		return [theArray objectAtIndex:n];
	}
	else { //run time error
        [NSException raise:@"Array Bounds" format:@"Out of Bounds Error. Line: %d",LineNumber(0)];
	}
	return nil;
}
- (id) processTry:(id) p
{
    if ([[(Node*)p nodeData] count] == 3){
        @try {
            NodeValue(0);
        }
        @catch (NSException* e) {
            [self setValue: e forSymbol:[[[p nodeData] objectAtIndex:2] nodeData]];
            NodeValue(1);
        }
    }
    else {
        @try {
            NodeValue(0);
        }
        @catch (NSException* e) {
            [self setValue: e forSymbol:[[[p nodeData] objectAtIndex:2] nodeData]];
            NodeValue(1);
        }
        @finally {
            NodeValue(3);
        }
    }
	return nil;
}

- (id) processThrow:(id) p
{
    id e = NodeValue(0);
    if([e isKindOfClass:NSClassFromString(@"NSException")]){
        @throw((NSException*)e);
    }
    else {
        NSException* e = [NSException exceptionWithName:@"Bad Argument"
                                                 reason:[NSString stringWithFormat:@"Argument to throw must be an NSException."]
                                               userInfo:nil];
        [e raise];

    }
    return nil;
}

- (id) makeException:(id) p
{
    id name     = NodeValue(0);
    id reason   = NodeValue(1);
    id userInfo = NodeValue(2);
    if([userInfo isKindOfClass:NSClassFromString(@"NSDictionary")]){
        return [NSException exceptionWithName:name reason:reason userInfo:userInfo];
    }
    else {
        NSException* e = [NSException exceptionWithName:@"Bad Argument"
                                                 reason:[NSString stringWithFormat:@"Argument to throw must be an NSDictionary."]
                                               userInfo:nil];
        [e raise];
        
    }
    return nil;
}

- (id) makeDictionary:(id) p
{
    if([[p nodeData] count] == 0) return [NSMutableDictionary dictionary];
    else {
        NSMutableDictionary* d = [NSMutableDictionary dictionary];
        NSMutableArray* anArray = [NSMutableArray arrayWithArray:NodeValue(0)];
        int n = [anArray count];
        int i;
        for(i=0;i<n;i+=2){
            [d setObject:[anArray objectAtIndex:i+1] forKey:[anArray objectAtIndex:i]];
        }
        return d;
    }
    return nil;
}

- (id) processGlobalBranches:(id)p
{
    if(![functionName isEqualToString:@"main"]){
        NSException* e = [NSException exceptionWithName:@"global def outside of main"
                                                 reason:[NSString stringWithFormat:@"The keyword 'global' can only be in the main function"]
                                               userInfo:nil];
        [e raise];
    }
    NodeValue(0);
    if([[p nodeData] count]==2)NodeValue(1);
    return nil;
}

- (id) doGlobalVar:(id)p
{
    id theVariableName = VARIABLENAME(0);
    id theNewValue     = _zero; //default
    id existingValue  = [self valueForSymbol:theVariableName];
    if(existingValue != nil){
        theNewValue = existingValue;
        [symbolTable threadSafeRemoveObjectForKey:theVariableName usingLock:symbolTableLock];
    }
    [globalSymbolTable threadSafeSetObject:theNewValue forKey:theVariableName usingLock:symbolTableLock];
    return nil;
}
- (id) doGlobalAssign:(id)p
{
    id theVariableName = VARIABLENAME(0);
    id theValue        = NodeValue(1);
    id existingValue  = [self valueForSymbol:theVariableName];
    if(existingValue != nil){
        [symbolTable threadSafeRemoveObjectForKey:theVariableName usingLock:symbolTableLock];
    }

    [globalSymbolTable threadSafeSetObject:theValue forKey:theVariableName usingLock:symbolTableLock];
    return nil;
}

- (void) addGlobalSymbol:(NSString*)aVariableName
{
    [globalSymbolTable setValue:_zero forKey:aVariableName];
}

- (id) makeArray:(id) p
{
    if([[p nodeData] count] == 0) return [NSMutableArray array];
    else {
        NSMutableArray* anArray = [NSMutableArray arrayWithArray:NodeValue(0)];
        return anArray;
    }
    return nil;
}

- (id) valueArray:(id)p
{
    if([[p nodeData] count] == 2){
        return [NSMutableArray arrayWithObjects:NodeValue(0),NodeValue(1),nil];
    }
    else {
        NSMutableArray* anArray = [NSMutableArray arrayWithArray:NodeValue(0)];
        [anArray addObject:NodeValue(1)];
        [anArray addObject:NodeValue(2)];
        return anArray;
    }
}

- (id) typeArray:(id)p
{
    if([[p nodeData] count] == 1){
        return [NSMutableArray arrayWithObjects:NodeValue(0),nil];
    }
    else {
        NSMutableArray* anArray = [NSMutableArray arrayWithArray:NodeValue(0)];
        [anArray addObject:NodeValue(1)];
        return anArray;
    }
}

- (id) processIf:(id) p
{
	if (![NodeValue(0) isEqual: _zero])		  return NodeValue(1);
	else if ([[(Node*)p nodeData] count] > 2) return NodeValue(2);
	return nil;
}

- (id) processUnless:(id) p
{
	if ([NodeValue(0) isEqual: _zero])		  return NodeValue(1);
	return nil;
}

- (id) bitExtract:(id) p
{
    unsigned long theValue = [NodeValue(0) unsignedLongValue];
    long val1 = [NodeValue(1) unsignedLongValue];
    long val2 = [NodeValue(2) unsignedLongValue];
    if(val1 > val2) {
        [NSException raise:@"Run Time Exception" format:@"Bit extract parameters out of order. Line: %d",LineNumber(1)];
    }
    if(val1 < 0 | val2 < 0) {
        [NSException raise:@"Run Time Exception" format:@"Bit extract parameter is negative. Line: %d",LineNumber(1)];
    }
    if(val1 > 32 | val2 > 32) {
        [NSException raise:@"Run Time Exception" format:@"Bit extract parameter greater than 32. Line: %d",LineNumber(1)];
    }
    unsigned short aShift = MIN(val1,val2);
    unsigned long aMask = 0L;
    int numBits = abs(val2 - val1)+1;
    int i;
    for(i=0;i<numBits;i++){
        aMask |= 0x1<<i;
    }
    return [NSDecimalNumber numberWithUnsignedLong:(theValue>>aShift) & aMask];
}
- (id) doSwitch:(id) p
{
	@try {
		switchLevel++;
		switchValue[switchLevel] = NodeValue(0);
		NodeValue(1);
	}
	@catch(NSException* localException) {
		if(![[localException name] isEqualToString:@"break"]){
			switchValue[switchLevel] = nil;
			switchLevel--;
			[localException raise]; //rethrow
		}
	}
	switchValue[switchLevel] = nil;
	switchLevel--;
	return nil;
}

- (id) doCase:(id)p
{
	if([switchValue[switchLevel] isEqualToNumber: NodeValue(0)]){
		NodeValue(1);
		if([[p nodeData] count] == 3)NodeValue(2);
	}
	return nil;
}

- (id) doCaseRange1:(id)p
{
    NSDecimalNumber* leftNum  = NodeValue(0);
    NSDecimalNumber* rightNum = NodeValue(1);
    if([leftNum compare:rightNum] == NSOrderedAscending){
        int leftCompare  = [switchValue[switchLevel] compare: leftNum];
        int rightCompare = [switchValue[switchLevel] compare: rightNum];
        if(leftCompare  != NSOrderedSame && rightCompare  != NSOrderedSame ){
            if((leftCompare  == NSOrderedDescending) && (rightCompare == NSOrderedAscending) ){
                NodeValue(2);
                if([[p nodeData] count] == 4)NodeValue(3);
            }
        }
    }
    else {
        [NSException raise:@"Run time" format:@"Case range must be ascending. Line: %d",LineNumber(0)];
    }
    return nil;
}
- (id) doCaseRange:(id)p
{
    NSDecimalNumber* leftNum  = NodeValue(0);
    NSDecimalNumber* rightNum = NodeValue(1);
    if([leftNum compare:rightNum] == NSOrderedAscending){
        int leftCompare  = [switchValue[switchLevel] compare: leftNum];
        int rightCompare = [switchValue[switchLevel] compare: rightNum];
        if((leftCompare  == NSOrderedSame || leftCompare  == NSOrderedDescending) &&
           (rightCompare == NSOrderedSame || rightCompare == NSOrderedAscending) ){
            NodeValue(2);
            if([[p nodeData] count] == 4)NodeValue(3);
        }
    }
    else {
        [NSException raise:@"Run time" format:@"Case range must be ascending. Line: %d",LineNumber(0)];
    }
    return nil;
}

- (id) doCaseGt:(id)p
{
    int compare  = [switchValue[switchLevel] compare: NodeValue(0)];
    if(compare  == NSOrderedDescending){
        NodeValue(1);
        if([[p nodeData] count] == 3)NodeValue(2);
    }
    
    return nil;
}

- (id) doCaseLt:(id)p
{
    int compare  = [switchValue[switchLevel] compare: NodeValue(0)];
    if(compare  == NSOrderedAscending){
        NodeValue(1);
        if([[p nodeData] count] == 3)NodeValue(2);
    }
    return nil;
}

- (id) doCaseGtE:(id)p
{
    int compare  = [switchValue[switchLevel] compare: NodeValue(0)];
    if(compare  == NSOrderedSame || compare  == NSOrderedDescending){
        NodeValue(1);
        if([[p nodeData] count] == 3)NodeValue(2);
    }

    return nil;
}

- (id) doCaseLtE:(id)p
{
    int compare  = [switchValue[switchLevel] compare: NodeValue(0)];
    if(compare  == NSOrderedSame || compare  == NSOrderedAscending){
        NodeValue(1);
        if([[p nodeData] count] == 3)NodeValue(2);
    }
    return nil;
}

- (id) doDefault:(id)p
{
	NodeValue(0); //execute the code
	if([[p nodeData] count] == 2)NodeValue(1); //do the break branch
	return nil;
}

- (id) doLoop:(id) p
{
	//eval do loop. do { loop guts }while(i<10);
	do {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		if([delegate exitNow]){
			[pool release];
			break; 
		}
		else {
			@try {
				NodeValue(0); //loop guts
				if([NodeValue(1) isEqual:_zero]){ //end of loop check i.e. while(i<10)
					[pool release];
					break;
				}
			}
			@catch(NSException* localException) {
				if([[localException name] isEqualToString:@"continue"]){
					[pool release];
					continue;
				}
				else if([[localException name] isEqualToString:@"break"]){
					[pool release];
					break;
				}
				else [localException raise];
			}
		}
        [pool release];

	} while(1);
	
	return nil;
}

- (id) whileLoop:(id)p
{
	//eval while loop. while(i<10) {loop guts}
	while(1){ 
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		if([self exitNow]){
			[pool release];
			break; 
		}
		else {
			@try {
				if([NodeValue(0) isEqual:_zero]){ //end of loop check, i.e. while(i<10)
					[pool release];
					break;
				}
				NodeValue(1);	//guts of loop
			}
			@catch(NSException* localException) {
				if([[localException name] isEqualToString:@"continue"]){
					[pool release];
					continue;
				}
				else if([[localException name] isEqualToString:@"break"]){
					[pool release];
					break;
				}
				else [localException raise];
			}
		}
		[pool release];
	}
	return nil;
}

- (id) forLoop:(id) p
{
    
    if ([[(Node*)p nodeData] count] ==3){
        //eval for loop ,i.e. for(a in b){ loop guts }
        id  collectionObj = NodeValue(1);

        if([collectionObj isKindOfClass:NSClassFromString(@"NSArray")]){
            //OK, we'll continue without doing anything here.
        }
        else if([collectionObj isKindOfClass:NSClassFromString(@"NSDictionary")]){
            //convert to an array of the keys
            collectionObj = [collectionObj allKeys];
        }
        else {
            [NSException raise:@"Run Time Exception" format:@"%@ is not an array or dictionary. Line: %d",VARIABLENAME(1),LineNumber(1)];
        }
        
        int i;
        int n = [collectionObj count];
        for(i=0;i<n;i++){
            NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
            if([self exitNow]){
                [pool release];
                break;
            }
            @try {
                id aValue = [collectionObj objectAtIndex:i];
                [self setValue: aValue forSymbol:[[[p nodeData] objectAtIndex:0] nodeData]];
                NodeValue(2); //this is the loop guts
            }
            @catch(NSException* localException) {
                if([[localException name] isEqualToString:@"continue"]){
                    [pool release];
                    i++;
                    continue;
                }
                else if([[localException name] isEqualToString:@"break"]){
                    [pool release];
                    break;
                }
                else [localException raise];
            }
            [pool release];
        }
    }
    else {
        //eval for loop ,i.e. for(i=0;i<10;i++){ loop guts }
        NodeValue(0); //loop init, i.e. i=0
        do {
            NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
            if([self exitNow]){
                [pool release];
                break;
            }
            else {
                @try {
                    if([NodeValue(1) isEqual: _zero]){ //the end of loop check, i.e. i<10
                        [pool release];
                        break;
                    }
                    NodeValue(3); //this is the loop guts
                    NodeValue(2); //this is the end of loop action, i.e. i++
                }
                @catch(NSException* localException) {
                    if([[localException name] isEqualToString:@"continue"]){
                        [pool release];
                        NodeValue(2); //this is the end of loop action, i.e. i++
                        continue;
                    }
                    else if([[localException name] isEqualToString:@"break"]){
                        [pool release];
                        break;
                    }
                    else [localException raise];
                }
            }
            [pool release];
        } while(1);
    }
	return nil;
}

- (id) waitUntil:(id)p
{
	bool exitTime = NO;
	do {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		@try {
			if([self exitNow]){	
				exitTime = YES;
			}
			if([NodeValue(0) boolValue]){
				[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:.3]];
				exitTime = YES;
			}
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
		}
		@catch(NSException* localException) {
		}
		[pool release];
		if(exitTime)break;
	}while(1);
	return _one;
}

- (id) waitTimeOut:(id)p
{
	//return _one if timed-out.
	//return _zero if finshed because wait condition satisified.
	float timeOut = [NodeValue(1) floatValue];
	float time = 0;
	bool exitTime = NO;
	NSNumber* exitValue = _one;
	do {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		@try {
			if([self exitNow]){
				exitTime = YES;
			}
			if([NodeValue(0) boolValue]){
				[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:.3]];
				exitTime = YES;
			}
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
			time += .01;
			if(time >= timeOut){
				exitTime = YES;
				exitValue = _zero;
			}
		}
		@catch(NSException* localException) {
		}
		
		[pool release];
		if(exitTime)break;
		
	}while(1);
	return exitValue;
}

- (id) yieldFunc:(id)p
{
	int delay = [NodeValue(0) intValue];
    if(delay<1)delay=1;
	int total=0;
	bool exitTime = NO;
	do {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		@try {
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
			if([self exitNow]){
				exitTime = YES;
			}
			total += 1;
		}
		@catch(NSException* localException) {
		}
		[pool release];
		if(exitTime)break;
	}while(total<delay);
	return nil;
}


- (id) sleepFunc:(id)p
{
	float delay = [NodeValue(0) floatValue];
	float total=0;
	bool exitTime = NO;
	do {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		@try {
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
			if([self exitNow]){
				exitTime = YES;
			}
			total += .01f;
		}
		@catch(NSException* localException) {
		}
		[pool release];
		if(exitTime)break;
	}while(total<delay);
	return nil;
}

- (id) timeFunc
{
	struct timeval time1; 
	double theTime = 0; 
	int ierr = gettimeofday(&time1, NULL) ; 
	if (ierr == 0 )theTime = time1.tv_sec + time1.tv_usec/1.0E6;
	return [NSDecimalNumber numberWithDouble:theTime];
}

- (id) genRandom:(id) p
{
    long minValue = [NodeValue(0) longValue];
    long maxValue = [NodeValue(1) longValue];
	long result =  (rand() % ((maxValue +1) - minValue)) + minValue;
    return [NSDecimalNumber numberWithLong:result];
}

- (id) postAlarm:(id)p
{
	ORAlarm* anAlarm = [[ORAlarm alloc] initWithName:NodeValue(0) severity:MIN(kNumAlarmSeverityTypes-1,[NodeValue(1) intValue])];
	BOOL needsHelp = YES;
	if([[p nodeData] count] == 3){
		id s = NodeValue(2);
		if([s isKindOfClass:[NSString class]]){
			s = [s stringByAppendingFormat:@"\n\n Script [%@] posted this alarm. Acknowledge it and it will go away.",[self scriptName]];
			[anAlarm setHelpString:s];
			needsHelp = NO;
		}
	}
	if(needsHelp) {
		NSString* s = [NSString stringWithFormat:@"\nScript [%@] posted this alarm. Acknowledge it and it will go away.",[self scriptName]];
		[anAlarm setHelpString:s];
	}
	[anAlarm performSelectorOnMainThread:@selector(postAlarm) withObject:nil waitUntilDone:YES];
	[anAlarm release];
	return nil;
}

- (id) clearAlarm:(id)p
{
	id s = NodeValue(0);
	if([s isKindOfClass:[NSString class]]){
		[[ORAlarmCollection sharedAlarmCollection] performSelectorOnMainThread:@selector(removeAlarmWithName:) withObject:s waitUntilDone:YES];
	}
	return nil;
}

- (id) doExit:(id) p
{
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:@"Forced exit: 'exit' keywork executed" forKey:@"returnValue"];
	NSException* excep = [[[NSException alloc] initWithName:@"exit" reason:@"exit" userInfo:userInfo] autorelease];
	[excep raise];
	return nil; //never actually gets here.
}

- (id) doReturn:(id) p
{
	id returnValue = NodeValue(0);
	NSDictionary* userInfo;
	if(returnValue)	userInfo = [NSDictionary dictionaryWithObject:returnValue forKey:@"returnValue"];
	else			userInfo = [NSDictionary dictionaryWithObject:_zero forKey:@"returnValue"];
	NSException* excep = [[[NSException alloc] initWithName:@"return" reason:@"returnValue" userInfo:userInfo] autorelease];
	[excep raise];
	return nil; //never actually gets here.
}

- (id) writeLine:(id) p
{
	NSString* path = NodeValue(0);
	NSString* s    = NodeValue(1);
	s = [s stringByAppendingString:@"\n"];
	path = [path stringByExpandingTildeInPath];
	NSFileManager* fm = [NSFileManager defaultManager];
	if(![fm fileExistsAtPath:path]){
		[fm createDirectoryAtPath:[path stringByDeletingLastPathComponent]  withIntermediateDirectories:YES attributes:nil error:nil];
		[fm createFileAtPath:path contents:nil attributes:nil];
	}
	NSFileHandle* fp = [NSFileHandle fileHandleForUpdatingAtPath:path];
	[fp seekToEndOfFile];
	[fp writeData:[s dataUsingEncoding:NSASCIIStringEncoding]];
	return nil;
}


- (id) deleteFile:(id) p
{
	NSString* path = NodeValue(0);
	path = [path stringByExpandingTildeInPath];
	NSFileManager* fm = [NSFileManager defaultManager];
	if([fm fileExistsAtPath:path]){
		[fm removeItemAtPath:path  error:nil];
	}
	return nil;
}


- (id) extractValue:(int)index name:(NSString*)aFunctionName args:(NSArray*)valueArray
{
	id string = [valueArray objectAtIndex:0];
	if([string isKindOfClass:[NSString class]]){
		if([string hasPrefix:@"@("] && [string hasSuffix:@")"]){
			string = [string substringFromIndex:2];
			string = [string substringToIndex:[string length]-1];
			NSArray* parts = [string componentsSeparatedByString:@","];
			if([parts count]>=index+1){
				return [NSDecimalNumber decimalNumberWithString:[parts objectAtIndex:index]];
			}
		}
	}
	
	NSLog(@"In %@, <%@> not passed the right kind of argument. Check the syntax.\n",[self scriptName],aFunctionName);
    [NSException raise:@"Run time" format:@"Arg Type error."];
	return nil;
}


- (NSMutableDictionary*) makeSymbolTable
{
	NSMutableDictionary* aSymbolTable = [NSMutableDictionary dictionary];
	//preload with some constants
	[aSymbolTable setObject:_zero forKey:@"nil"];
	[aSymbolTable setObject:_zero forKey:@"NULL"];
	[aSymbolTable setObject:_zero forKey:@"FALSE"];
	[aSymbolTable setObject:_zero forKey:@"false"];
	[aSymbolTable setObject:_one  forKey:@"true"];
	[aSymbolTable setObject:_one  forKey:@"TRUE"];
	[aSymbolTable setObject:_zero  forKey:@"no"];
	[aSymbolTable setObject:_zero  forKey:@"NO"];
	[aSymbolTable setObject:_one  forKey:@"yes"];
	[aSymbolTable setObject:_one  forKey:@"YES"];
	return aSymbolTable;
}
- (NSComparisonResult) compare:(id)a to:(id)b
{
    if([a isKindOfClass:[b class]])return [a compare:b];
    else if([a isKindOfClass:NSClassFromString(@"NSString")] && [b isKindOfClass:NSClassFromString(@"NSDecimalNumber")]){
        return [[NSDecimalNumber decimalNumberWithString:a] compare:b];
    }
    else if([b isKindOfClass:NSClassFromString(@"NSString")] && [a isKindOfClass:NSClassFromString(@"NSDecimalNumber")]){
        return [a compare:[NSDecimalNumber decimalNumberWithString:b]];
    }
    else {
        [NSException raise:@"Run time" format:@"illegal to compare %@ to %@",[a className],[b className]];
        return NO; //never get here... just to make compiler happy
    }
}
@end

@implementation ORNodeEvaluator (Graph_Private)


- (id) printNode:(id)p atLevel:(int)aLevel lastOne:(BOOL)lastChild
{
    if (!p) return @"";
	
	NSMutableString* line = [NSMutableString stringWithString:@"?"];
	
    switch([(Node*)p type]) {
        case typeId:
            line = [NSMutableString stringWithFormat:@"ident(%s)",    [[p nodeData] cStringUsingEncoding:NSASCIIStringEncoding]];
            [self  addVariabletoCheckDictionary:[p nodeData]]; //this checks for variables that differ only in case
            break;
            
        case typeCon:               line = [NSMutableString stringWithFormat:@"c(%@)",		[p nodeData]];	break;
        case typeSelVar:			line = [NSMutableString stringWithFormat:@"selVar(%s)", [[p nodeData] cStringUsingEncoding:NSASCIIStringEncoding]];	break;
        case typeStr:				line = [NSMutableString stringWithFormat:@"\"%s\"",		[[p nodeData] cStringUsingEncoding:NSASCIIStringEncoding]];	break;
		case typeOperationSymbol:	line = [NSMutableString stringWithFormat:@"oper(%s)",	[[p nodeData] cStringUsingEncoding:NSASCIIStringEncoding]];	break;
        case typeOpr:
            switch([[p nodeData] operatorTag]){
				case kArrayListAssign:	line = [NSMutableString stringWithString:@"[arrayInit]"];	break;
                case kDefineArray:		line = [NSMutableString stringWithString:@"[defineArray]"];	break;
                case kArrayAssign:		line = [NSMutableString stringWithString:@"[=]"];			break;
                case kLeftArray:		line = [NSMutableString stringWithString:@"[arrayLValue]"];	break;
                case kRightArray:		line = [NSMutableString stringWithString:@"[arrayRValue]"];	break;
                case kConditional:      line = [NSMutableString stringWithString:@"[Conditional]"];  break;
                case kBitExtract:       line = [NSMutableString stringWithString:@"[BitExtract]"]; break;
                case TRY:				line = [NSMutableString stringWithString:@"[try]"];			break;
                case CATCH:				line = [NSMutableString stringWithString:@"[catch]"];		break;
                case FINALLY:			line = [NSMutableString stringWithString:@"[finally]"];		break;
                case MAKEEXCEPTION:		line = [NSMutableString stringWithString:@"[makeException]"];break;
                case THROW:             line = [NSMutableString stringWithString:@"[throw]"];		break;
                case DO:				line = [NSMutableString stringWithString:@"[do]"];			break;
                case WHILE:				line = [NSMutableString stringWithString:@"[while]"];		break;
                case FOR:				line = [NSMutableString stringWithString:@"[for]"];			break;
                case IF:				line = [NSMutableString stringWithString:@"[if]"];			break;
                case UNLESS:			line = [NSMutableString stringWithString:@"[unless]"];		break;
                case SWITCH:			line = [NSMutableString stringWithString:@"[switch]"];		break;
                case CASE:				line = [NSMutableString stringWithString:@"[case]"];		break;
                case DEFAULT:			line = [NSMutableString stringWithString:@"[default]"];		break;
                case PRINT:             line = [NSMutableString stringWithString:@"[print]"];       break;
                case PRINTFILE:			line = [NSMutableString stringWithString:@"[printFile]"];	break;
                case DISPLAY:			line = [NSMutableString stringWithString:@"[display]"];		break;
                case LOGFILE:			line = [NSMutableString stringWithString:@"[logFile]"];		break;
				case MAKESTRING:		line = [NSMutableString stringWithString:@"[makeString]"];	break;
				case CATSTRING:			line = [NSMutableString stringWithString:@"[catString]"];	break;
                case GLOBAL:            line = [NSMutableString stringWithString:@"[GLOBAL]"];      break;
                case SELFFUNCTION:      line = [NSMutableString stringWithString:@"[SELFFunction]"];break;
                case SYMBOLS:           line = [NSMutableString stringWithString:@"[SYMBOLS]"];     break;
                case GLOBALS:           line = [NSMutableString stringWithString:@"[GLOBALS]"];     break;
                case kGlobal:           line = [NSMutableString stringWithString:@"[globalList]"];  break;
                case kGlobalVar:        line = [NSMutableString stringWithString:@"[globalVar]"];   break;
                case kGlobalAssign:     line = [NSMutableString stringWithString:@"[globalAssign]"];break;
                case kPostInc:			line = [NSMutableString stringWithString:@"[postInc]"];		break;
                case kPreInc:			line = [NSMutableString stringWithString:@"[preInc]"];		break;
                case kPostDec:			line = [NSMutableString stringWithString:@"[postDec]"];		break;
                case kPreDec:			line = [NSMutableString stringWithString:@"[prdDec]"];		break;
                case kAppend:			line = [NSMutableString stringWithString:@"[append]"];		break;
                case kTightAppend:      line = [NSMutableString stringWithString:@"[append(tight)]"];break;
                case ';':				line = [NSMutableString stringWithString:@"[;]"];			break;
                case '=':				line = [NSMutableString stringWithString:@"[=]"];			break;
                case UMINUS:			line = [NSMutableString stringWithString:@"[-]"];			break;
                case '~':				line = [NSMutableString stringWithString:@"[~]"];			break;
                case '^':				line = [NSMutableString stringWithString:@"[^]"];			break;
                case '%':				line = [NSMutableString stringWithString:@"[%]"];			break;
                case '!':				line = [NSMutableString stringWithString:@"[!]"];			break;
                case '+':				line = [NSMutableString stringWithString:@"[+]"];			break;
                case '-':				line = [NSMutableString stringWithString:@"[-]"];			break;
                case '*':				line = [NSMutableString stringWithString:@"[*]"];			break;
                case '/':				line = [NSMutableString stringWithString:@"[/]"];			break;
                case '<':				line = [NSMutableString stringWithString:@"[<]"];			break;
                case '>':				line = [NSMutableString stringWithString:@"[>]"];			break;
                case kCaseRange:        line = [NSMutableString stringWithString:@"[<=<]"];         break;
                case kCaseRange1:       line = [NSMutableString stringWithString:@"[<<]"];         break;
                case kCaseGtE:          line = [NSMutableString stringWithString:@"[>=]"];         break;
                case kCaseLtE:          line = [NSMutableString stringWithString:@"[<=]"];         break;
                case kCaseGt:           line = [NSMutableString stringWithString:@"[>]"];         break;
                case kCaseLt:           line = [NSMutableString stringWithString:@"[<]"];         break;

                case LEFT_OP:           line = [NSMutableString stringWithString:@"[<<]"];          break;
                case RIGHT_OP:			line = [NSMutableString stringWithString:@"[<<]"];			break;
				case AND_OP:			line = [NSMutableString stringWithString:@"[&&]"];			break;
				case '&':				line = [NSMutableString stringWithString:@"[&]"];			break;
				case OR_OP:				line = [NSMutableString stringWithString:@"[||]"];			break;
				case '|':				line = [NSMutableString stringWithString:@"[|]"];			break;
				case GE_OP:				line = [NSMutableString stringWithString:@"[>=]"];			break;
                case LE_OP:				line = [NSMutableString stringWithString:@"[<=]"];			break;
                case NE_OP:				line = [NSMutableString stringWithString:@"[!=]"];			break;
                case EQ_OP:				line = [NSMutableString stringWithString:@"[==]"];			break;
				case '@':				line = [NSMutableString stringWithString:@"[ObjC]"];		break;
				case kObjList:			line = [NSMutableString stringWithString:@"[ObjVarList]"];	break;
				case kSelName:			line = [NSMutableString stringWithString:@"[ObjCVar]"];		break;
				case BREAK:				line = [NSMutableString stringWithString:@"[break]"];		break;
				case EXIT:				line = [NSMutableString stringWithString:@"[exit]"];		break;
				case RETURN:			line = [NSMutableString stringWithString:@"[return]"];		break;
				case CONTINUE:			line = [NSMutableString stringWithString:@"[continue]"];	break;
				case SLEEP:				line = [NSMutableString stringWithString:@"[sleep]"];		break;
				case YIELD:				line = [NSMutableString stringWithString:@"[yield]"];		break;
				case NSDICTIONARY:		line = [NSMutableString stringWithString:@"[nsdictionary]"]; break;
				case NSARRAY:			line = [NSMutableString stringWithString:@"[nsarray]"];		 break;
                case NSDATECOMPONENTS:  line = [NSMutableString stringWithString:@"[nsdatecomponents]"]; break;
				case NSFILEMANAGER:		line = [NSMutableString stringWithString:@"[NSFileManager]"];  break;
				case WRITELINETOFILE:	line = [NSMutableString stringWithString:@"[writeLine]"]; break;
				case DELETEFILE:		line = [NSMutableString stringWithString:@"[deleteFile]"]; break;
				case STRINGFROMFILE:	line = [NSMutableString stringWithString:@"[stringFromFile]"]; break;
				case HEX:				line = [NSMutableString stringWithString:@"[hex]"];			break;
				case WAITUNTIL:			line = [NSMutableString stringWithString:@"[waituntil]"];	break;				
				case ALARM:				line = [NSMutableString stringWithString:@"[alarm]"];		break;				
				case CLEAR:				line = [NSMutableString stringWithString:@"[clear]"];		break;				
				case kWaitTimeOut:		line = [NSMutableString stringWithString:@"[waittimeout]"];	break;
                case FIND:				line = [NSMutableString stringWithString:@"[find]"];		break;
                case LEFT_ASSIGN:		line = [NSMutableString stringWithString:@"[<<=]"];			break;
                case RIGHT_ASSIGN:		line = [NSMutableString stringWithString:@"[>>=]"];			break;
                case ADD_ASSIGN:		line = [NSMutableString stringWithString:@"[+=]"];			break;
                case SUB_ASSIGN:		line = [NSMutableString stringWithString:@"[-=]"];			break;
                case MUL_ASSIGN:		line = [NSMutableString stringWithString:@"[*=]"];			break;
                case DIV_ASSIGN:		line = [NSMutableString stringWithString:@"[/=]"];			break;
                case OR_ASSIGN:			line = [NSMutableString stringWithString:@"[|=]"];			break;
                case AND_ASSIGN:		line = [NSMutableString stringWithString:@"[&=]"];			break;
                case kFuncCall:			line = [NSMutableString stringWithString:@"[call]"];		break;
				case kMakeArgList:		line = [NSMutableString stringWithString:@"[argList]"];		break;
				case MAKEPOINT:			line = [NSMutableString stringWithString:@"[point]"];		break;
				case MAKERECT:			line = [NSMutableString stringWithString:@"[rect]"];		break;
				case MAKESIZE:			line = [NSMutableString stringWithString:@"[size]"];		break;
				case MAKERANGE:			line = [NSMutableString stringWithString:@"[range]"];		break;
				case REQUEST:			line = [NSMutableString stringWithString:@"[request]"];		break;
				case CONFIRM:			line = [NSMutableString stringWithString:@"[confirm]"];		break;
				case SEEDRANDOM:		line = [NSMutableString stringWithString:@"[seedRandom]"];	break;
                case RANDOM:            line = [NSMutableString stringWithString:@"[random]"];        break;
                case SORT:              line = [NSMutableString stringWithString:@"[sort]"];        break;
				case kConfirmTimeOut:	line = [NSMutableString stringWithString:@"[confirmtimeout]"];	break;
                case '#':				line = [NSMutableString stringWithString:@"[#]"];			break;
                case '$':				line = [NSMutableString stringWithString:@"[$]"];			break;
                case ',':				line = [NSMutableString stringWithString:@"[,]"];			break;
				default:				line = [NSMutableString stringWithString:@"[??]"];			break;
            }
            break;
    }
    
	NSString* prependString = @"";
	int i;
	for(i=0;i<aLevel;i++){
		if(i>=aLevel-1)prependString = [prependString stringByAppendingString:@"|----"];
		else prependString = [prependString stringByAppendingString:@"|    "];
	}
	[line insertString:prependString atIndex:0];
	[line appendString:@"\n"];
	
	int count = 0;
	if ([(Node*)p type] == typeOpr){
		count = [[(Node*)p nodeData] count];
	}
	
    /* node is leaf */
	if (count == 0) {
		if(lastChild){
			NSString* suffixString = @"";
			int i;
			for(i=0;i<aLevel;i++){
				if(i<aLevel)suffixString = [suffixString stringByAppendingString:@"|    "];
			}
			[line appendFormat:@"%@\n",suffixString];
		}
        return line;
    }
	
	aLevel++;
    /* node has children */
    for (i = 0; i < count; i++) {
		[line appendString:[self printNode:[[(Node*)p nodeData] objectAtIndex:i] atLevel:aLevel lastOne:i==count-1]];
    }
	
	return line;
}

- (id) finalPass:(id)string
{
	NSMutableArray* lines = [NSMutableArray arrayWithArray:[string componentsSeparatedByString:@"\n"]];
	NSMutableString* aLine;
	int r1 = 0;
	while(1) {
		NSRange r = NSMakeRange(r1,2);
		BOOL delete = YES;
		int count = [lines count];
		int i;
		BOOL done = YES;
		for(i=count-1;i>=0;i--){
			aLine = [lines objectAtIndex:i];
			if([aLine length] < NSMaxRange(r))continue;
			done = NO;
			
			if(delete && [[aLine substringWithRange:r] isEqualToString:@"| "]){
				NSMutableString* newString = [NSMutableString stringWithString:aLine];
				[newString replaceCharactersInRange:r withString:@"  "];
				[lines replaceObjectAtIndex:i withObject:newString];
			}
			else if(delete && [[aLine substringWithRange:r] isEqualToString:@"|-"]){
				delete = NO;
			}
			else if(!delete && ![[aLine substringWithRange:NSMakeRange(r1,1)] isEqualToString:@"|"]){
				delete = YES;
			}
		}
		r1 += 5;
		if(done)break;
	}
	return [lines componentsJoinedByString:@"\n"];
}

@end

@implementation ORSysCall
+ (id) sysCall:(void*)aFuncPtr name:(NSString*)aFuncName obj:anObject numArgs:(int)aNumArgs 
{
    return [[[ORSysCall alloc] initWithCall:aFuncPtr name:aFuncName obj:anObject numArgs:aNumArgs] autorelease];
}

+ (id) sysCall:(void*)aFuncPtr name:(NSString*)aFuncName  numArgs:(int)aNumArgs 
{
    return [[[ORSysCall alloc] initWithCall:aFuncPtr name:aFuncName  obj:nil numArgs:aNumArgs] autorelease];
}

- (id) initWithCall:(void*)afunc name:(NSString*)aFuncName obj:(id)anObj numArgs:(int)n 
{
	self = [super init];
	funcPtr = (unsigned long*)afunc;
	funcName = [aFuncName copy];
	numArgs = n;
	anObject = anObj;
	return self;
}

- (void) dealloc
{
	[funcName release];
	[super dealloc];
}

- (id) executeWithArgs:(NSArray*)valueArray
{
	float (*pt0Func)();
	float (*pt1Func)(float);
	float (*pt2Func)(float,float);
	if(numArgs == [valueArray count]){
		switch(numArgs){
			case 0: pt0Func = funcPtr; return [NSDecimalNumber numberWithFloat:pt0Func()];
			case 1: pt1Func = funcPtr; return [NSDecimalNumber numberWithFloat:pt1Func([[valueArray objectAtIndex:0] floatValue])];
			case 2: pt2Func = funcPtr; return [NSDecimalNumber numberWithFloat:pt2Func([[valueArray objectAtIndex:0] floatValue],[[valueArray objectAtIndex:1] floatValue])];
			default: return nil;
		}
	}
	else {
		[NSException raise:@"Run time" format:@"Arg list error in function: %@",funcName];
	}
	return nil;
}

@end
@implementation NSArray (ORNodeEvaluation)
- (NSComparisonResult)compare:(NSArray *)anOtherArray
{
	if( [self isEqual: anOtherArray])return NSOrderedSame;
	else return NSOrderedDescending;
}
@end

@implementation NSDictionary (ORNodeEvaluation)
- (NSComparisonResult)compare:(NSDictionary *)anOtherDictionary
{
	if( [self isEqual: anOtherDictionary])return NSOrderedSame;
	else return NSOrderedDescending;
}
@end

@implementation OrcaObjectController (ORNodeEvaluation)
- (NSComparisonResult)compare:(NSNumber *)otherNumber
{
	if( [self isEqual: otherNumber])return NSOrderedSame;
	else return NSOrderedDescending;
}

- (BOOL)	exitNow
{
	return NO;
}
@end

@implementation ORScriptUserConfirmController

     @synthesize delegate,confirmString,title;
     
- (id) initWithDelegate:(id)aDelegate title:(NSString*)aTitle confirmString:(NSString*)aString
{    
	if(!(self = [super initWithWindowNibName: @"UserConfirm"]))return nil;
    self.delegate = aDelegate;
    self.title = aTitle;
    NSString* s = [[aString componentsSeparatedByString:@"\\n"] componentsJoinedByString:@"\n"]; //have to convert the newLine string into actual new line char
    self.confirmString = [[s componentsSeparatedByString:@"\\r"] componentsJoinedByString:@"\r"]; //have to convert the newLine string into actual new line char
    [[self window] center];
    return self;
}
     
- (void) dealloc
{
    self.confirmString = nil;
    self.title = nil;
    [super dealloc];
}

- (void) setTimeToGo:(NSNumber*)aTime
{
    if(aTime)[timeOutField setStringValue: [NSString stringWithFormat:@"Timeout: %d s",[aTime intValue]]];
    else     [timeOutField setStringValue:@""];
}

- (void) awakeFromNib
{
    [confirmStringField setStringValue:confirmString];
    [titleField setStringValue:title];
    [super awakeFromNib];
}

- (IBAction) confirmAction:(id)sender
{
    [delegate setUserResult:1];
}

- (IBAction) cancelAction:(id)sender
{
    [delegate setUserResult:0];
}
@end

@implementation ORScriptUserRequestController

@synthesize delegate,variableList,title,inputFields;

- (id) initWithDelegate:(id)aDelegate  title:(NSString*)aTitle variableList:(NSString*)aString
{
	if(!(self = [super initWithWindowNibName: @"UserRequest"]))return nil;
    self.delegate       = aDelegate;
    self.title          = aTitle;
    self.variableList  = aString;
    self.inputFields = [NSMutableDictionary dictionary];
	return self;
}

- (void) dealloc
{
    self.variableList   = nil;
    self.title          = nil;
    self.inputFields    = nil;
    [super dealloc];
}

- (void) awakeFromNib
{
    [titleField setStringValue:title];
    
    NSArray* variables = [variableList componentsSeparatedByString:@","];
    int variableCount = [variables count];
    
    NSRect windowFrame = [[self window] frame];
    float yStart = 30;
    float y = yStart;
    float x = 5;
    float dy = 24;
    int count = 0;
    BOOL reset = NO;
    for(id aName in variables){
        if([inputFields objectForKey:aName])continue; //prevent duplicates
        id theObj = [delegate valueForSymbol:aName];
        //restrict the kind of class that can be used.
        if(![theObj isKindOfClass:NSClassFromString(@"NSDecimalNumber")] &&
           ![theObj isKindOfClass:NSClassFromString(@"NSString")])continue;

        NSString* className = nil;
        if([theObj isKindOfClass:NSClassFromString(@"NSDecimalNumber")])    className = @"NSDecimalNumber";
        else if([theObj isKindOfClass:NSClassFromString(@"NSString")])      className = @"NSString";
        
        NSTextField* labelField = [[NSTextField alloc] initWithFrame:NSMakeRect(x,y,175,20)];
        NSTextField* textField = [[NSTextField alloc] initWithFrame:NSMakeRect(x+85,y,75,20)];
        
        [labelField setAutoresizingMask: NSViewMinYMargin];
        [textField setAutoresizingMask: NSViewMinYMargin];
        
        
        [self.window.contentView addSubview:labelField];
        [self.window.contentView addSubview:textField];
        [labelField setBezeled:NO];
        [labelField setEditable:NO];
        [labelField setDrawsBackground:NO];
        [labelField setAlignment:NSRightTextAlignment];
        [textField setAlignment:NSRightTextAlignment];
                
        [labelField setObjectValue:[NSString stringWithFormat:@"%@:",aName]];
        [textField setObjectValue:theObj];

        //make a small dictionary so we can get the values and classNames later.
        [inputFields setObject:[NSDictionary dictionaryWithObjectsAndKeys:textField,@"textField",className,@"className", nil]
                        forKey:aName];

        [labelField release];
        [textField release];
        y -= dy;
        if(!reset && (++count >= (int)(variableCount/2. +.5))){
            x = 85 + 175 + 10;
            y = yStart;
            reset = YES;
        }
    }
    float windowX = windowFrame.origin.x;
    float windowY = windowFrame.origin.y;
    float h = windowFrame.size.height + count * dy - 4;
    float w = windowFrame.size.width;
    [[self window] setFrame:NSMakeRect(windowX,windowY,w,h) display:YES];
    [[self window]center];
    [super awakeFromNib];
}

- (IBAction) confirmAction:(id)sender
{
    for(id aKey in [inputFields allKeys]){
        NSTextField* aTextField = [[inputFields objectForKey:aKey] objectForKey:@"textField"];
        NSString* aClassName    = [[inputFields objectForKey:aKey] objectForKey:@"className"];
        id newValue= [aTextField stringValue];
        if([aClassName isEqualToString:@"NSDecimalNumber"])newValue = [[[NSDecimalNumber alloc] initWithString:newValue]autorelease];
        if(newValue) [delegate setValue:newValue forSymbol:aKey];
    }

    [delegate setUserResult:1];
}

- (IBAction) cancelAction:(id)sender
{
    [delegate setUserResult:0];
}
@end

@implementation ORScriptUserStatusController

@synthesize delegate,variableList,title,valueFields;

- (id) initWithDelegate:(id)aDelegate variableList:(NSString*)aString
{
	if(!(self = [super initWithWindowNibName: @"UserStatus"]))return nil;
    self.delegate       = aDelegate;
    self.title          = [aDelegate scriptName];
    self.variableList  = aString;
    self.valueFields = [NSMutableDictionary dictionary];
	return self;
}

- (void) dealloc
{
    self.variableList   = nil;
    self.title          = nil;
    self.valueFields    = nil;
    [super dealloc];
}

- (void) awakeFromNib
{
    [titleField setStringValue:title];
    
    NSArray* variables = [variableList componentsSeparatedByString:@","];
    int variableCount  = [variables count];
    
    NSRect windowFrame = [[self window] frame];
    float yStart = 20;
    float y = yStart;
    float x = 5;
    float dy = 24;
    int count = 0;
    BOOL reset = NO;
    [[self window] setTitle:[delegate scriptName]];
    for(id aName in variables){
        if([valueFields objectForKey:aName])continue; //prevent duplicates
        id theObj = [delegate valueForSymbol:aName];
        //restrict the kind of class that can be used.
        if(![theObj isKindOfClass:NSClassFromString(@"NSDecimalNumber")] &&
           ![theObj isKindOfClass:NSClassFromString(@"NSString")])continue;
                
        NSTextField* labelField = [[NSTextField alloc] initWithFrame:NSMakeRect(x,y,120,20)];
        NSTextField* textField = [[NSTextField alloc] initWithFrame:NSMakeRect(x+122,y,75,20)];
        
        [labelField setAutoresizingMask: NSViewMinYMargin];
        [textField setAutoresizingMask: NSViewMinYMargin];
        
        [self.window.contentView addSubview:labelField];
        [self.window.contentView addSubview:textField];
        [labelField setBezeled:NO];
        [labelField setEditable:NO];
        [labelField setDrawsBackground:NO];

        [textField setBezeled:NO];
        [textField setEditable:NO];
        [textField setDrawsBackground:NO];

        [labelField setAlignment:NSRightTextAlignment];
        [textField setAlignment:NSLeftTextAlignment];
        
        [labelField setObjectValue:[NSString stringWithFormat:@"%@:",aName]];
        [textField setObjectValue:theObj];
        
        //make a small dictionary so we can get the values and classNames later.
        [valueFields setObject:[NSDictionary dictionaryWithObjectsAndKeys:textField,@"textField", nil] forKey:aName];
        
        [labelField release];
        [textField release];
        y -= dy;
        
        if(!reset && (++count >= (int)(variableCount/2. +.5))){
            x = 120 + 75 + 25;
            y = yStart;
            reset = YES;
        }
    }
    float windowX = windowFrame.origin.x;
    float windowY = windowFrame.origin.y;
    float h = windowFrame.size.height + count * dy - 4;
    float w = variableCount>=2 ? 2*x - 10 : x-10;
    [[self window] setFrame:NSMakeRect(windowX,windowY,w,h) display:YES];
    [[self window]center];
    [super awakeFromNib];
}

- (void) refresh
{
    [self performSelectorOnMainThread:@selector(refreshOnMainThread) withObject:nil waitUntilDone:NO];
}

- (void) refreshOnMainThread
{
    for(id aName in [valueFields allKeys]){
        id theObj = [delegate valueForSymbol:aName];
        if(![theObj isKindOfClass:NSClassFromString(@"NSDecimalNumber")] &&
           ![theObj isKindOfClass:NSClassFromString(@"NSString")])continue;
        if(theObj){
            id dictionary = [valueFields objectForKey:aName];
            [[dictionary objectForKey:@"textField"] setObjectValue:theObj];
        }
    }
}

@end
