//
//  TaskStep.m
//  CocoaScript
//
//  ORShellStep.m
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


#import "ORShellStep.h"
#import "ORTaskHandler.h"
#import "OROpSequenceQueue.h"

@implementation ORShellStep

@synthesize outputStateKey;
@synthesize errorStateKey;
@synthesize currentDirectory;
@synthesize environment;
@synthesize launchPath;
@synthesize argumentsArray;
@synthesize outputStringErrorPattern;
@synthesize errorStringErrorPattern;
@synthesize trimNewlines;
//
// shellStepWithCommandLine:
//
// TaskStep runs a process as a task. The parameters to this method are the
// arguments.
// 
// There are a few options that are possible with TaskStep
//	- it can process the stdout or stderr strings for errors
//	- you can pipe into another TaskStep (which must be scheduled in the
//		queue ahead of this step)
//	- you can trim newlines off the stdout (useful for many command line
//		processes which output a trailing newline
//	- environement variables and current directory can also be set for the task
//
// Parameters:
//    aLaunchPath - the path to the executable
//    ... - the parameters to the executable
//
// returns the initialized TaskStep
//
+ (ORShellStep *)shellStepWithCommandLine:(NSString *)aLaunchPath, ...
{
    NSMutableArray *anArgumentsArray = [[NSMutableArray alloc] init];

    va_list args;
    va_start(args, aLaunchPath);
    NSString *arg;
    for (arg = va_arg(args, NSString*); arg != nil; arg = va_arg(args, NSString*)){
        [anArgumentsArray addObject:arg];
    }
    va_end(args);

	ORShellStep* step              = [[[self alloc] init] autorelease];
	step.launchPath             = aLaunchPath;
	step.argumentsArray         = anArgumentsArray;
	step->taskStartedCondition  = [[NSCondition alloc] init];
	
	[anArgumentsArray release];
	
	return step;
}

- (void)dealloc
{
	[taskStartedCondition     release];
	[taskHandler              release];
	[launchPath               release];
	[argumentsArray           release];
	[environment              release];
	[currentDirectory         release];
	[outputStateKey           release];
	[errorStateKey            release];
	[outputStringErrorPattern release];
	[errorStringErrorPattern  release];
	[outputPipe               release];
	[errorPipe                release];
    
	[super dealloc];
}

- (NSString *)title
{
    if(!title){
        NSMutableString *commandLine = [NSMutableString stringWithString:launchPath];
        for (NSString *argument in [self resolvedScriptArrayForArray:argumentsArray]){
            [commandLine appendString:@" "];
            [commandLine appendString:argument];
        }
        return commandLine;
    }
    else return title;
}

- (void)runStep
{
    [super runStep];
	if (self.concurrentStep) [NSThread sleepForTimeInterval:5.0];
    
    @try {
        taskHandler = [[ORTaskHandler alloc] initWithLaunchPath:launchPath
                                                    arguments:[self resolvedScriptArrayForArray:argumentsArray]
                                          terminationReceiver:self
                                                     selector:@selector(taskComplete:)];
        
        if (environment)      [[taskHandler task] setEnvironment: [self resolvedScriptDictionaryForDictionary:environment]];
        if (currentDirectory) [[taskHandler task] setCurrentDirectoryPath: [self resolvedScriptValueForValue:currentDirectory]];
        
        [taskHandler setOutputReceiver:self
                              selector:@selector(receiveOutputData:fromTaskHandler:)];
        
        [taskHandler setErrorReceiver:self
                             selector:@selector(receiveErrorData:fromTaskHandler:)];
        
        [taskHandler launch];
    
        [taskStartedCondition lock];
        [taskStartedCondition broadcast];
        [taskStartedCondition unlock];
    }
    @catch (NSException* e){
        [taskHandler release];
        taskHandler = nil;
        [self appendErrorString:@"Task=nil"];
    }
    
	while (![self isCancelled] && taskHandler){
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
        if ([self isCancelled])break;
	}
	
	if ([self isCancelled])[taskHandler terminate];

}

- (void)receiveInputData:(NSData *)data
{
	[taskStartedCondition lock];
	if ([taskHandler taskState] == TaskHandlerNotLaunched){
		while (![taskStartedCondition
			waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]]){
			if ([self isCancelled])return;
		}
	}
	[taskStartedCondition unlock];
	[taskHandler appendInputData:data];
}

- (void)receiveOutputData:(NSData *)data fromTaskHandler:(ORTaskHandler *)handler
{
	NSString *newString = [[[NSString alloc] initWithData:data
                                                 encoding:NSUTF8StringEncoding] autorelease];
	if ([newString length]>0) [self appendOutputString:newString];
	
	[outputPipe receiveInputData:data];
}

- (void)receiveErrorData:(NSData *)data fromTaskHandler:(ORTaskHandler *)handler
{
	NSString *newString = [[[NSString alloc] initWithData:data
                                                 encoding:NSUTF8StringEncoding] autorelease];
	
	if (newString) [self appendErrorString:newString];
	
	[errorPipe receiveInputData:data];
}

- (void)pipeErrorInto:(ORShellStep *)destination
{
	[errorPipe autorelease];
	errorPipe = [destination retain];
	errorPipe.concurrentStep = self;
}

- (void)pipeOutputInto:(ORShellStep *)destination
{
	[outputPipe autorelease];
	outputPipe = [destination retain];
	outputPipe.concurrentStep = self;
}


// Perform line-by-line parsing of the stderr and stdout. Each line is
// compared to the error  patterns to see if there are any errors for this task.
//
- (void)parseErrors
{
	NSInteger errors    = 0;
	
	if (outputStringErrorPattern) {
		NSPredicate *errorPredicate = [NSComparisonPredicate
			predicateWithLeftExpression:[NSExpression expressionForEvaluatedObject]
			rightExpression:[NSExpression expressionForConstantValue:outputStringErrorPattern]
			modifier:NSDirectPredicateModifier
			type:NSMatchesPredicateOperatorType
			options:0];
        
	
		NSString *outputString  = [self outputString];
		NSUInteger length       = [outputString length];
		NSUInteger paraStart    = 0;
		NSUInteger paraEnd      = 0;
		NSUInteger contentsEnd  = 0;
        
		NSRange currentRange;
		while (paraEnd < length){
			[outputString getParagraphStart:&paraStart
                                        end:&paraEnd
                                contentsEnd:&contentsEnd
                                   forRange:NSMakeRange(paraEnd, 0)];
			currentRange = NSMakeRange(paraStart, contentsEnd - paraStart);
			NSString *paragraph = [outputString substringWithRange:currentRange];

			if ([errorPredicate evaluateWithObject:paragraph])          errors++;
		}
	}

	if (errorStringErrorPattern){
		NSPredicate *errorPredicate = [NSComparisonPredicate
			predicateWithLeftExpression:[NSExpression expressionForEvaluatedObject]
			rightExpression:[NSExpression expressionForConstantValue:errorStringErrorPattern]
			modifier:NSDirectPredicateModifier
			type:NSMatchesPredicateOperatorType
			options:0];

		
		NSString *errorString = [self errorString];

		NSUInteger length = [errorString length];
		NSUInteger paraStart = 0;
		NSUInteger paraEnd = 0;
		NSUInteger contentsEnd = 0;
		NSRange currentRange;
		while (paraEnd < length){
			[errorString getParagraphStart:&paraStart
                                       end:&paraEnd
                               contentsEnd:&contentsEnd
                                  forRange:NSMakeRange(paraEnd, 0)];
			currentRange = NSMakeRange(paraStart, contentsEnd - paraStart);
			NSString *paragraph = [errorString substringWithRange:currentRange];

			if ([errorPredicate evaluateWithObject:paragraph]){
				errors++;
			}

		}
	}
    if(errors==0) self.errorCount = 0;
    else {
        NSInteger theErrors = self.errorCount;
        theErrors += errors;
        self.errorCount   = theErrors;
    }
}

- (void)taskComplete:(ORTaskHandler*)aTaskHandler
{
	[outputPipe receiveInputData:nil];
	[errorPipe  receiveInputData:nil];
	
	if (errorStateKey)[currentQueue setStateValue:[self errorString] forKey:errorStateKey];
	
	if (aTaskHandler.taskState == TaskHandlerCouldNotBeLaunched){
		NSString* message = [NSString stringWithFormat: NSLocalizedString(@"Could not launch task %@", ""), [self title]];
		[self replaceAndApplyErrorToErrorString:message];
	}
	else [self parseErrors];

    if(outputStateKey){
        if(self.errorCount!=0){
            if(self.numAllowedErrors==0){
                [currentQueue setStateValue:@"0" forKey:outputStateKey];
            }
            else {
                [currentQueue setStateValue:self.errorCount<self.numAllowedErrors ? @"-1" : @"0" forKey:outputStateKey];
            }
        }
        else {
            [currentQueue setStateValue:@"1" forKey:outputStateKey];
        }
    }
    
	[taskHandler release];
	taskHandler = nil;
}

@end
