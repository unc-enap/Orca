//
//  OROpSeqStep.m
//  Orca
//
//  Created by Matt Gallagher on 2010/11/01.
//  Found on web and heavily modified by Mark Howe on Fri Nov 28, 2013.
//  Copyright (c) 2013  University of North Carolina. All rights reserved.
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


#import "OROpSeqStep.h"
#import "OROpSequenceQueue.h"
#import "OROpSequence.h"

@implementation OROpSeqStep

@synthesize title;
@synthesize errorTitle;
@synthesize successTitle;
@synthesize outputStringStorage;
@synthesize errorStringStorage;
@synthesize currentQueue;
@synthesize concurrentStep;
@synthesize errorCount;
@synthesize requirements;
@synthesize andConditions;
@synthesize skipConditions;
@synthesize orConditions;
@synthesize numAllowedErrors;
@synthesize persistantStorageObj;
@synthesize persistantAccessKey;
@synthesize forceError;

- (id)init
{
	self = [super init];
	if (self != nil) {
		outputStringStorage = [[NSTextStorage alloc] init];
		errorStringStorage  = [[NSTextStorage alloc] init];
	}
	return self;
}

//
// attributedStringForString:
//
// Used to apply the standard text attributes to a string.
//
// Also double checks that the currentQueue is set (so that the attributes are
// accessible).
//
// Parameters:
//    aString - the NSString to convert into an NSAttributedString
//
// returns the NSAttributedString
//
- (NSAttributedString *)attributedStringForString:(NSString *)aString
{
	NSAssert1(currentQueue,
              @"Method %@ should only be invoked while currentQueue is set.",
              NSStringFromSelector(_cmd));
    
	return [[[NSAttributedString alloc] initWithString:aString
                                            attributes:currentQueue.textAttributes] autorelease];
}

- (NSString*) title
{
	if (!title) return [self description];
	else return title;
}

- (void) setPersistentStorageObj:(id)anObj accessKey:(NSString*)aKey
{
    self.persistantStorageObj   = anObj;
    self.persistantAccessKey    = aKey;
}

- (void) setErrorCount:(NSInteger)aValue
{
    errorCount = aValue;
    //also save to persistant storage
    [persistantStorageObj step:self setObject:[NSNumber numberWithInteger:aValue] forKey:@"errorCount"];
}

- (void) runStep
{
    self.errorCount = [[persistantStorageObj step:self objectForKey:@"errorCount"] intValue];
    if(self.errorCount >= [self numAllowedErrors])self.errorCount=0;
}

//
// main
//
// This is the default NSOperation entry point but for ScriptSteps it is only
// used to set and clear the queue either side of -runStep and check if any
// errors occurred (and stop the queue if one occurred).
//
- (void) main
{
    NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];

	self.currentQueue = (OROpSequenceQueue*)[NSOperationQueue currentQueue];
    
	if(![self checkSkipConditions] && [self checkConditions]){
        [self runStep];
    }
	else {
        [self cancel];
    }
    
	//if  (([self errorCount] > 0) ) {
	//	[[NSOperationQueue currentQueue] cancelAllOperations];
	//}
	self.currentQueue = nil;
    [thePool release];
}

- (void)dealloc
{
	[title               release];
	[errorTitle          release];
    [successTitle        release];
	[outputStringStorage release];
	[errorStringStorage  release];
    [currentQueue        release];
	[concurrentStep      release];
    [requirements        release];
    [skipConditions      release];
    [andConditions       release];
    [orConditions        release];
    [persistantAccessKey release];
    
    title               = nil;
	errorTitle          = nil;
    successTitle        = nil;
	outputStringStorage = nil;
	errorStringStorage  = nil;
    currentQueue        = nil;
	concurrentStep      = nil;
    requirements        = nil;
    skipConditions      = nil;
    andConditions       = nil;
    orConditions        = nil;
    persistantStorageObj= nil;
    persistantAccessKey = nil;
    
	[super dealloc];
}

- (enumScriptStepState)state
{
    if ([self isExecuting])return kSeqStepActive;
    else if ([self isFinished]) {
        if ([self errorCount] != 0 || forceError){
            if([self errorCount]<[self numAllowedErrors] && !forceError) return kSeqStepWarning;
            else                                          return kSeqStepFailed;
        }
        else if ([self isCancelled])        return kSeqStepCancelled;
        else                                return kSeqStepSuccess;
    }
    else return kSeqStepPending;
}

- (NSString*) finalStateString
{
    if ([self isFinished]) {
        NSString* s;
        NSInteger ec = [self errorCount];
        NSInteger ac = [self numAllowedErrors];
        
        if(ec==0 && !self.forceError){
            if(self.successTitle)s = self.successTitle;
            else                 s = @"Success";
        }
        else {
            if(ac>0){
                s = [NSString stringWithFormat: @"%d/%d error%s", (int32_t)ec,(int32_t)ac,ec>1?"s":""];
            }
            else s = [NSString stringWithFormat: @"%d error%s", (int32_t)ec,ec>1?"s":""];
            
            if((self.errorString && ec>=ac) || forceError) s = self.errorTitle;
        }
        return s;
    }
    else return @"Running";
}

- (void) require:(NSString*)aKey value:(NSString*)aValue
{
    if(!requirements)self.requirements = [NSMutableDictionary dictionary];
    [requirements setObject:aValue forKey:aKey];
}

- (void) addSkipCondition:(NSString*)aKey value:(NSString*)aValue
{
    if(!skipConditions)self.skipConditions = [NSMutableDictionary dictionary];
    [skipConditions setObject:aValue forKey:aKey];
}


- (void) addAndCondition:(NSString*)aKey value:(NSString*)aValue
{
    if(!andConditions)self.andConditions = [NSMutableDictionary dictionary];
    [andConditions setObject:aValue forKey:aKey];
}

- (void) addOrCondition:(NSString*)aKey value:(NSString*)aValue
{
    if(!orConditions)self.orConditions = [NSMutableDictionary dictionary];
    [orConditions setObject:aValue forKey:aKey];
}

- (BOOL) checkSkipConditions
{
    if(!skipConditions)return NO;
    //if any skip conditions are true return YES
    
    for(id aKey in skipConditions){
        NSString* aValue    = [self resolvedScriptValueForValue:[ScriptValue scriptValueWithKey:aKey]];
        NSString* skipValue = [skipConditions objectForKey:aKey];
        if([aValue isEqualToString:skipValue])return YES;
    }
    return NO;
}

- (BOOL) checkConditions
{
    if(!andConditions && !orConditions)return YES;
    //if any And conditions are present they ALL must be true
    
    BOOL andValue = YES;
    for(id aKey in andConditions){
        NSString* aValue        = [self resolvedScriptValueForValue:[ScriptValue scriptValueWithKey:aKey]];
        NSString* requiredValue = [andConditions objectForKey:aKey];
        andValue &= [aValue isEqualToString:requiredValue];
    }
    
    //if ANY of the or conditions are present
    BOOL orValue = NO;
    if(!orConditions)orValue = YES;
    else {
        for(id aKey in orConditions){
            NSString* aValue        = [self resolvedScriptValueForValue:[ScriptValue scriptValueWithKey:aKey]];
            NSString* requiredValue = [orConditions objectForKey:aKey];
            orValue |= [aValue isEqualToString:requiredValue];
        }
    }

    return andValue & orValue;
}

- (NSInteger) checkRequirements
{
    NSInteger err=0;
    for(id aKey in requirements){
        NSString* aValue = [self resolvedScriptValueForValue:[ScriptValue scriptValueWithKey:aKey]];
        NSString* requiredValue = [requirements objectForKey:aKey];
        if(![aValue isEqualToString:requiredValue]){
            err++;
        }
    }
    return err;
}

#pragma mark -- Methods for appending/setting the outputStringStorage

//
// applyOutputAttributesToRange:
//
// A method intended for internal use only. Used to ensure that string storage
// changes are only performed on the main thread.
//
// Takes a dictionary containing @"range" and @"attributes" keys. The attributes
// are applied to the range within the output string.
//
// Parameters:
//    attributesAndRange - a dictionary containing @"range" and @"attributes" keys
//
- (void)applyOutputAttributesToRange:(NSDictionary *)attributesAndRange
{
	if (![[NSThread currentThread] isEqual:[NSThread mainThread]]) {
		[self
         performSelectorOnMainThread:_cmd
         withObject:attributesAndRange
         waitUntilDone:NO];
		return;
	}
	
	NSRange range = [[attributesAndRange objectForKey:@"range"] rangeValue];
	NSDictionary *attributes = [attributesAndRange objectForKey:@"attributes"];
	
	[outputStringStorage beginEditing];
	[outputStringStorage setAttributes:attributes range:range];
	[outputStringStorage endEditing];
}

//
// appendAttributedOutputString:
//
// A method intended for internal use only. Used to ensure that string storage
// changes are only performed on the main thread.
//
// Appends attributed string data to the outputStringStorage
//
// Parameters:
//    string - the attributed string data
//
- (void)appendAttributedOutputString:(NSAttributedString *)string
{
	if (![[NSThread currentThread] isEqual:[NSThread mainThread]]) {
		[self performSelectorOnMainThread:_cmd
                               withObject:string
                            waitUntilDone:NO];
		return;
	}
	
	[outputStringStorage beginEditing];
	[outputStringStorage appendAttributedString:string];
	[outputStringStorage endEditing];
}

//
// replaceAttributedOutputString:
//
// A method intended for internal use only. Used to ensure that string storage
// changes are only performed on the main thread.
//
// Replaces the outputStringStorage
//
// Parameters:
//    string - the attributed string data
//
- (void)replaceAttributedOutputString:(NSAttributedString *)string
{
	if (![[NSThread currentThread] isEqual:[NSThread mainThread]]) {
		[self performSelectorOnMainThread:_cmd
                               withObject:string
                            waitUntilDone:NO];
		return;
	}
	
	[outputStringStorage beginEditing];
	[outputStringStorage
     replaceCharactersInRange:NSMakeRange(0, [outputStringStorage length])
     withAttributedString:string];
	[outputStringStorage endEditing];
}

//
// applyErrorAttributesToOutputStringStorageRange:
//
// Set a range within the output string to the error attributes.
//
// Parameters:
//    aRange - the range to change
//
- (void)applyErrorAttributesToOutputStringStorageRange:(NSRange)aRange
{
	NSAssert1(currentQueue,
              @"Method %@ should only be invoked while currentQueue is set.",
              NSStringFromSelector(_cmd));
    
	[self applyOutputAttributesToRange:
     [NSDictionary dictionaryWithObjectsAndKeys:
      currentQueue.errorAttributes, @"attributes",
      [NSValue valueWithRange:aRange], @"range",
      nil]];
}

//
// appendOutputString:
//
// Appends an NSString to the outputStringStorage
//
// Parameters:
//    string - the NSString
//
- (void)appendOutputString:(NSString *)string
{
	[self appendAttributedOutputString:[self attributedStringForString:string]];
}

//
// replaceOutputString:
//
// Appends an NSString to the outputStringStorage
//
// Parameters:
//    string - the NSString
//
- (void)replaceOutputString:(NSString *)string
{
	[self replaceAttributedOutputString:[self attributedStringForString:string]];
}

//
// replaceAndApplyErrorToOutputString:
//
// Replace the outputStringStorage with an NSString and flag the whole string
// as an error
//
// Parameters:
//    string - the NSString
//
- (void)replaceAndApplyErrorToOutputString:(NSString *)string
{
	[self replaceAttributedOutputString:[self attributedStringForString:string]];
	[self applyErrorAttributesToOutputStringStorageRange:
     NSMakeRange(0, [string length])];
    NSInteger theError = self.errorCount;
	self.errorCount = theError++;
}


#pragma mark -- Methods for appending/setting the errorStringStorage

//
// applyErrorAttributesToRange:
//
// A method intended for internal use only. Used to ensure that string storage
// changes are only performed on the main thread.
//
// Takes a dictionary containing @"range" and @"attributes" keys. The attributes
// are applied to the range within the error string.
//
// Parameters:
//    attributesAndRange - a dictionary containing @"range" and @"attributes" keys
//
- (void)applyErrorAttributesToRange:(NSDictionary *)attributesAndRange
{
	if (![[NSThread currentThread] isEqual:[NSThread mainThread]])	{
		[self
         performSelectorOnMainThread:_cmd
         withObject:attributesAndRange
         waitUntilDone:NO];
		return;
	}
	
	NSRange range = [[attributesAndRange objectForKey:@"range"] rangeValue];
	NSDictionary *attributes = [attributesAndRange objectForKey:@"attributes"];
	
	[errorStringStorage beginEditing];
	[errorStringStorage setAttributes:attributes range:range];
	[errorStringStorage endEditing];
}

//
// appendAttributedErrorString:
//
// A method intended for internal use only. Used to ensure that string storage
// changes are only performed on the main thread.
//
// Appends attributed string data to the errorStringStorage
//
// Parameters:
//    string - the attributed string data
//
- (void)appendAttributedErrorString:(NSAttributedString *)string
{
	if (![[NSThread currentThread] isEqual:[NSThread mainThread]]) {
		[self
         performSelectorOnMainThread:_cmd
         withObject:string
         waitUntilDone:NO];
		return;
	}
	
	[errorStringStorage beginEditing];
	[errorStringStorage appendAttributedString:string];
	[errorStringStorage endEditing];
}

//
// replaceAttributedErrorString:
//
// A method intended for internal use only. Used to ensure that string storage
// changes are only performed on the main thread.
//
// Replaces the errorStringStorage
//
// Parameters:
//    string - the attributed string data
//
- (void)replaceAttributedErrorString:(NSAttributedString *)string
{
	if (![[NSThread currentThread] isEqual:[NSThread mainThread]]){
		[self
         performSelectorOnMainThread:_cmd
         withObject:string
         waitUntilDone:NO];
		return;
	}
	
	[errorStringStorage beginEditing];
	[errorStringStorage
     replaceCharactersInRange:NSMakeRange(0, [errorStringStorage length])
     withAttributedString:string];
	[errorStringStorage endEditing];
}

//
// applyErrorAttributesToErrorStringStorageRange:
//
// Set a range within the error string to the error attributes.
//
// Parameters:
//    aRange - the range to change
//
- (void)applyErrorAttributesToErrorStringStorageRange:(NSRange)aRange
{
	NSAssert1(currentQueue,
              @"Method %@ should only be invoked while currentQueue is set.",
              NSStringFromSelector(_cmd));
    
	[self applyErrorAttributesToRange:
     [NSDictionary dictionaryWithObjectsAndKeys:
      currentQueue.errorAttributes, @"attributes",
      [NSValue valueWithRange:aRange], @"range",
      nil]];
}


//
// appendErrorString:
//
// Appends an NSString to the errorStringStorage
//
// Parameters:
//    string - the NSString
//
- (void)appendErrorString:(NSString *)string
{
	[self appendAttributedErrorString:[self attributedStringForString:string]];
}

//
// replaceErrorString:
//
// Appends an NSString to the errorStringStorage
//
// Parameters:
//    string - the NSString
//
- (void)replaceErrorString:(NSString *)string
{
	[self replaceAttributedErrorString:[self attributedStringForString:string]];
}


//
// replaceAndApplyErrorToErrorString:
//
// Replace the errorStringStorage with an NSString and flag the whole string
// as an error
//
// Parameters:
//    string - the NSString
//
- (void)replaceAndApplyErrorToErrorString:(NSString *)string
{
	[self replaceAttributedErrorString:[self attributedStringForString:string]];
	[self applyErrorAttributesToErrorStringStorageRange:
     NSMakeRange(0, [string length])];
    NSInteger theError = self.errorCount;
	self.errorCount = theError++;
}

#pragma mark -- Resolving ScriptValues
//
// resolvedScriptValueForValue:
//
// Converts a ScriptValue to its runtime value, or if the value is not a
// ScriptValue, simply passes it through.
//
// Parameters:
//    value - the ScriptValue or otherwise
//
// returns the resolved value
//
- (NSString *)resolvedScriptValueForValue:(id)value
{
	if ([value isKindOfClass:[ScriptValue class]]) {
		if (currentQueue) {
			value = [currentQueue stateValueForKey:((ScriptValue *)value).stateKey];
			if (!value) value = @"";
		}
		else {
			value = [value description];
		}
	}
	return value;
}

//
// resolvedScriptArrayForArray:
//
// Converts an array of ScriptValues to their runtime values, or if the values
// are not ScriptValues, simply passes each through.
//
// Parameters:
//    value - the array of ScriptValue or otherwise
//
// returns the resolved values
//
- (NSArray *)resolvedScriptArrayForArray:(NSArray *)argumentsArray
{
	NSMutableArray *resolvedArray = [NSMutableArray arrayWithCapacity:[argumentsArray count]];
	for (id value in argumentsArray) {
		if ([value isKindOfClass:[ScriptValue class]]) {
			if (currentQueue) {
				value = [currentQueue stateValueForKey:((ScriptValue *)value).stateKey];
				[resolvedArray addObject:value ? value : @""];
			}
			else {
				[resolvedArray addObject:[value description]];
			}
		}
		else {
			[resolvedArray addObject:value];
		}
	}
	
	return resolvedArray;
}

//
// resolvedScriptDictionaryForDictionary:
//
// Converts a dictionary of ScriptValues to their runtime values, or if the values
// are not ScriptValues, simply passes each through.
//
// Parameters:
//    value - the dictionary of ScriptValue or otherwise
//
// returns the resolved values
//
- (NSDictionary *)resolvedScriptDictionaryForDictionary:(NSDictionary *)argumentsDictionary
{
	NSMutableDictionary *resolvedDictionary =
    [NSMutableDictionary dictionaryWithCapacity:[argumentsDictionary count]];
	for (NSString *key in argumentsDictionary) {
		id value = [argumentsDictionary objectForKey:key];
		if ([value isKindOfClass:[ScriptValue class]]) {
			if (currentQueue) {
				value = [currentQueue stateValueForKey:((ScriptValue *)value).stateKey];
				[resolvedDictionary setObject:value ? value : @"" forKey:key];
			}
			else {
				[resolvedDictionary
                 setObject:[value description]
                 forKey:key];
			}
		}
		else {
			[resolvedDictionary setObject:value forKey:key];
		}
	}
	
	return resolvedDictionary;
}

#pragma mark -- Accessors for the outputString/errorString

//
// outputStringIntoArray:
//
// Used to fetch the outputString from the ScriptQueue thread. Since
// performSelectorOnMainThread:withObject:waitUntilDone: does not have a
// return value, the return value is placed into the provided array.
//
// Parameters:
//    container - the container for the return value
//
- (void)outputStringIntoArray:(NSMutableArray *)container
{
	[container addObject:[outputStringStorage string]];
}

//
// outputString
//
// Accessor that gets the NSString value of the outputStringStorage
//
// returns the the NSString
//
- (NSString *)outputString
{
	if (![[NSThread currentThread] isEqual:[NSThread mainThread]]) {
		NSMutableArray *container = [NSMutableArray arrayWithCapacity:0];
		[self performSelectorOnMainThread:@selector(outputStringIntoArray:)
                               withObject:container
                            waitUntilDone:YES];
		return [container lastObject];
	}
	
	return [outputStringStorage string];
}

//
// errorStringIntoArray:
//
// Used to fetch the errorString from the ScriptQueue thread. Since
// performSelectorOnMainThread:withObject:waitUntilDone: does not have a
// return value, the return value is placed into the provided array.
//
// Parameters:
//    container - the container for the return value
//
- (void)errorStringIntoArray:(NSMutableArray *)container
{
	[container addObject:[errorStringStorage string]];
}

//
// errorString
//
// Accessor that gets the NSString value of the errorStringStorage
//
// returns the the NSString
//
- (NSString *)errorString
{
	if (![[NSThread currentThread] isEqual:[NSThread mainThread]]) {
		NSMutableArray *container = [NSMutableArray arrayWithCapacity:0];
		[self performSelectorOnMainThread:@selector(errorStringIntoArray:)
                               withObject:container
                            waitUntilDone:YES];
		return [container lastObject];
	}
	
	return [errorStringStorage string];
}

@end

@implementation ScriptValue

@synthesize stateKey;
- (void)dealloc
{
	[stateKey release];
	[super dealloc];
}

// ScriptValues can be passed to steps.
+ (ScriptValue*) scriptValueWithKey:(NSString *)aStateKey
{
	ScriptValue *scriptArgument = [[[ScriptValue alloc] init] autorelease];
	scriptArgument.stateKey     = aStateKey;
	return scriptArgument;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<ScriptValue: %@>", stateKey];
}

@end
