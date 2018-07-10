//
//  ORInvocationStep.m
//  Orca
//
//  Created by Mark Howe on Fri Nov 28, 2013.
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

#import "ORInvocationStep.h"
#import "OROpSequenceQueue.h"
#import "NSInvocation+Extensions.h"

@implementation ORInvocationStep

@synthesize invocation;
@synthesize outputStateKey;
@synthesize outputStringErrorPattern;

+ (ORInvocationStep*)invocation:(NSInvocation*)anInvocation;
{
	ORInvocationStep* step = [[[self alloc] init] autorelease];
    step.invocation = anInvocation;
	return step;
}

- (void)dealloc
{
    [invocation                 release];
	[outputStringErrorPattern   release];
	[outputStateKey             release];
    
    outputStateKey              = nil;
    invocation                  = nil;
    outputStringErrorPattern    = nil;
    
	[super dealloc];
}

- (void)runStep
{
    [super runStep];
	if (self.concurrentStep) [NSThread sleepForTimeInterval:5.0];

    [invocation invokeWithNoUndoOnTarget:[invocation target]];
    id result = [invocation returnValue];
    
    NSString* outputString = [NSString stringWithFormat:@"%@",result];
    [self parseErrors:outputString];
    if (outputStateKey && [outputString length]){
        [currentQueue setStateValue:outputString forKey:outputStateKey];
	}
}

- (void) parseErrors:(id)outputString
{
	NSInteger errors    = 0;
	
	if (outputStringErrorPattern) {
		NSPredicate *errorPredicate = [NSComparisonPredicate
                                       predicateWithLeftExpression:[NSExpression expressionForEvaluatedObject]
                                       rightExpression:[NSExpression expressionForConstantValue:outputStringErrorPattern]
                                       modifier:NSDirectPredicateModifier
                                       type:NSMatchesPredicateOperatorType
                                       options:0];
        
        
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
    if(errors==0) self.errorCount = 0;
    else {
        NSInteger theErrors = self.errorCount;
        theErrors += errors;
        self.errorCount   = theErrors;
    }
    
}




@end
