//
//  NSInvocation+Extensions.m
//  Orca
//
//  Created by Mark Howe on Thu Feb 12 2004.
//  Copyright (c) 2004 CENPA, University of Washington. All rights reserved.
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

#import <objc/runtime.h>

@interface NSInvocation (OrcaExtensionsPrivate)
- (void) _privateInvokeWithNoUndoOnTarget:(id)aTarget withAssociatedKey:(void *)akey;
@end

@implementation NSInvocation (OrcaExtensionsPrivate)

- (void) _privateInvokeWithNoUndoOnTarget:(id)aTarget withAssociatedKey:(void *)akey
{
    NSUndoManager* undoer = [[(ORAppDelegate*)[NSApp delegate]document] undoManager];
    [undoer disableUndoRegistration];
    @try {
        [self invokeWithTarget:aTarget];
    }
    @catch (NSException *exception) {
        if (akey) {
            // If we have akey, it means we should save the exception
            objc_setAssociatedObject(self,
                                     akey,
                                     exception,
                                     OBJC_ASSOCIATION_COPY);
        } else {
            // Otherwise, reraise the exception (we should be on the main thread).
            [exception raise];
        }
    } @finally {
        [undoer enableUndoRegistration];
    }
}
@end

@implementation NSInvocation (OrcaExtensions)

//parse a string of the form method:var1 name:var2 ....	to selector			
+ (NSArray*) argumentsListFromSelector:(NSString*) aSelectorString
{
	NSCharacterSet* delimiterset = [NSCharacterSet characterSetWithCharactersInString:@": "];
	NSCharacterSet* inverteddelimiterset = [delimiterset invertedSet];
	NSCharacterSet* trimSet = [NSCharacterSet characterSetWithCharactersInString:@" [];\n\r\t"];
	
	aSelectorString		     = [aSelectorString stringByTrimmingCharactersInSet:trimSet]; //get rid of leading white space the user might have put in
	NSScanner* 	scanner      = [NSScanner scannerWithString:aSelectorString];
	NSMutableArray* cmdItems = [NSMutableArray array];
	
	//parse a string of the form method:var1 name:var2 ....				
	while(![scanner isAtEnd]) {
		NSString*  result = [NSString string];
		[scanner scanUpToCharactersFromSet:inverteddelimiterset intoString:nil];            //skip leading delimiters
		if([scanner scanUpToCharactersFromSet:delimiterset intoString:&result]){            //store up to next delimiter
			if([result length]){
				[cmdItems addObject:result];
			}
		}
	}
	return cmdItems;
}

+ (SEL) makeSelectorFromString:(NSString*) aSelectorString
{
	NSCharacterSet* delimiterset = [NSCharacterSet characterSetWithCharactersInString:@": "];
	NSCharacterSet* inverteddelimiterset = [delimiterset invertedSet];
	NSCharacterSet* trimSet = [NSCharacterSet characterSetWithCharactersInString:@" [];\n\r\t"];

	aSelectorString		     = [aSelectorString stringByTrimmingCharactersInSet:trimSet]; //get rid of leading white space the user might have put in
	NSScanner* 	scanner      = [NSScanner scannerWithString:aSelectorString];
	NSMutableArray* cmdItems = [NSMutableArray array];
	
	//parse a string of the form method:var1 name:var2 ....				
	while(![scanner isAtEnd]) {
		NSString*  result = [NSString string];
		[scanner scanUpToCharactersFromSet:inverteddelimiterset intoString:nil];            //skip leading delimiters
		if([scanner scanUpToCharactersFromSet:delimiterset intoString:&result]){            //store up to next delimiter
			if([result length]){
				[cmdItems addObject:result];
			}
		}
	}
	return [NSInvocation makeSelectorFromArray:cmdItems];
}

+ (SEL) makeSelectorFromArray:(NSArray*)cmdItems
{
    NSUInteger n = [cmdItems count];
    int i=0;
    NSMutableString* theSelectorString = [NSMutableString string];
    if(n>1)for(i=0;i<n;i+=2){
        [theSelectorString appendFormat:@"%@:",[cmdItems objectAtIndex:i]];
    }
	else if(i<n)[theSelectorString appendFormat:@"%@",[cmdItems objectAtIndex:i]];
	else theSelectorString = [NSMutableString stringWithString:@""];
    
    return NSSelectorFromString(theSelectorString);
}

- (BOOL) setArgument:(int)argIndex to:(id)aVal
{
    argIndex += 2; 
    const char *theArg = [[self methodSignature] getArgumentTypeAtIndex:argIndex];
    if(*theArg == 'c'){
        char c = [aVal charValue];
        [self setArgument:&c atIndex:argIndex];
    }
    else if(*theArg == 'i'){
        int c = [aVal intValue];
        [self setArgument:&c atIndex:argIndex];
    }
    else if(*theArg == 's'){
        short c = [aVal shortValue];
        [self setArgument:&c atIndex:argIndex];
    }
    else if(*theArg == 'l'){
        int32_t c = (int32_t)[aVal intValue];
        [self setArgument:&c atIndex:argIndex];
    }
    else if(*theArg == 'q'){
        int64_t c = [aVal longLongValue];
        [self setArgument:&c atIndex:argIndex];
    }
    else if(*theArg == 'C'){
        unsigned char c = [aVal unsignedCharValue];
        [self setArgument:&c atIndex:argIndex];
    }
    else if(*theArg == 'I'){
        unsigned int c = [aVal unsignedIntValue];
        [self setArgument:&c atIndex:argIndex];
    }
    else if(*theArg == 'S'){
        unsigned short c = [aVal unsignedShortValue];
        [self setArgument:&c atIndex:argIndex];
    }
    else if(*theArg == 'L'){
        uint32_t c = (uint32_t)[aVal unsignedLongValue];
        [self setArgument:&c atIndex:argIndex];
    }
    else if(*theArg == 'Q'){
        uint64_t c = [aVal unsignedLongLongValue];
        [self setArgument:&c atIndex:argIndex];
    }
    else if(*theArg == 'f'){
        float c = [aVal floatValue];
        [self setArgument:&c atIndex:argIndex];
    }
    else if(*theArg == 'd'){
        double c = [aVal doubleValue];
        [self setArgument:&c atIndex:argIndex];
    }
	else if(*theArg == 'B'){
		BOOL c;
		if([aVal class] == [NSString class]){
			if(!strncmp([aVal cStringUsingEncoding:NSASCIIStringEncoding],"YES",3))c = 1;
			else if(!strncmp([aVal cStringUsingEncoding:NSASCIIStringEncoding],"NO",2))c = 0;
		}
		else c = (bool)[aVal intValue];
		[self setArgument:&c atIndex:argIndex];
    }
    else if(*theArg == '@'){
        [self setArgument:&aVal atIndex:argIndex];
    }
	else if(!strncmp(theArg,"{_NSPo",6) || !strncmp(theArg,"{CGPoi",6)){
		aVal = [aVal substringFromIndex:2];
		aVal = [aVal substringToIndex:[aVal length]-1];
		NSArray* xy = [aVal componentsSeparatedByString:@","];
		NSPoint thePoint = NSMakePoint([[xy objectAtIndex:0] floatValue], [[xy objectAtIndex:1] floatValue]);
		[self setArgument:&thePoint atIndex:argIndex];
	}
	else if(!strncmp(theArg,"{_NSRa",6) | !strncmp(theArg,"{CGRan",6)){
		aVal = [aVal substringFromIndex:2];
		aVal = [aVal substringToIndex:[aVal length]-1];
		NSArray* xy = [aVal componentsSeparatedByString:@","];
		NSRange theRange = NSMakeRange([[xy objectAtIndex:0] floatValue], [[xy objectAtIndex:1] floatValue]);
		[self setArgument:&theRange atIndex:argIndex];
	}
	else if(!strncmp(theArg,"{_NSRe",6) || !strncmp(theArg,"{CGRec",6)){
		aVal = [aVal substringFromIndex:2];
		aVal = [aVal substringToIndex:[aVal length]-1];
		NSArray* xy = [aVal componentsSeparatedByString:@","];
		NSRect theRect = NSMakeRect([[xy objectAtIndex:0] floatValue], 
									[[xy objectAtIndex:1] floatValue],
									[[xy objectAtIndex:2] floatValue],
									[[xy objectAtIndex:3] floatValue]);
		[self setArgument:&theRect atIndex:argIndex];
	}
	else if(!strncmp(theArg,"{_NSSi",6) || !strncmp(theArg,"{CGSiz",6)){
		aVal = [aVal substringFromIndex:2];
		aVal = [aVal substringToIndex:[aVal length]-1];
		NSArray* xy = [aVal componentsSeparatedByString:@","];
		NSSize theSize = NSMakeSize([[xy objectAtIndex:0] floatValue], 
									[[xy objectAtIndex:1] floatValue]);
		[self setArgument:&theSize atIndex:argIndex];
	}
	
	
    else return NO;
    
    return YES;
    
}

- (id) returnValue
{

    NSString* returnValueAsString = @"0";

    const char *theArg = [[self methodSignature] methodReturnType];

    if(*theArg == 'c'){
		char buffer;
        [self getReturnValue:&buffer]; 
		returnValueAsString = [[NSNumber numberWithChar:buffer] stringValue];
    }
    else if(*theArg == 'i'){
	int buffer;
        [self getReturnValue:&buffer]; 
		returnValueAsString = [[NSNumber numberWithInt:buffer] stringValue];
    }
    else if(*theArg == 's'){
	short buffer;
        [self getReturnValue:&buffer]; 
		returnValueAsString = [[NSNumber numberWithShort:buffer] stringValue];
    }
    else if(*theArg == 'l'){
		int32_t buffer;
        [self getReturnValue:&buffer]; 
		returnValueAsString = [[NSNumber numberWithLong:buffer] stringValue];
    }
    else if(*theArg == 'C'){
		unsigned char buffer;
        [self getReturnValue:&buffer]; 
		returnValueAsString = [[NSNumber numberWithUnsignedChar:buffer] stringValue];
    }
    else if(*theArg == 'I'){
		unsigned int buffer;
        [self getReturnValue:&buffer]; 
		returnValueAsString = [[NSNumber numberWithUnsignedInt:buffer] stringValue];
    }
    else if(*theArg == 'S'){
		unsigned short buffer;
        [self getReturnValue:&buffer]; 
		returnValueAsString = [[NSNumber numberWithUnsignedShort:buffer] stringValue];
    }
    else if(*theArg == 'L'){
		uint32_t buffer;
        [self getReturnValue:&buffer]; 
		returnValueAsString = [[NSNumber numberWithUnsignedLong:buffer] stringValue];
    }
    else if(*theArg == 'q'){
        int64_t buffer;
        [self getReturnValue:&buffer];
        returnValueAsString = [[NSNumber numberWithLongLong:buffer] stringValue];
    }
    else if(*theArg == 'Q'){
        uint64_t buffer;
        [self getReturnValue:&buffer];
        returnValueAsString = [[NSNumber numberWithUnsignedLongLong:buffer] stringValue];
    }
    else if(*theArg == 'f'){
		float buffer;
        [self getReturnValue:&buffer]; 
		returnValueAsString = [[NSNumber numberWithFloat:buffer] stringValue];
    }
    else if(*theArg == 'd'){
		double buffer;
        [self getReturnValue:&buffer]; 
		returnValueAsString = [[NSNumber numberWithDouble:buffer] stringValue];
    }
    else if(*theArg == 'B'){
		BOOL buffer;
        [self getReturnValue:&buffer]; 
		returnValueAsString = [[NSNumber numberWithBool:buffer] stringValue];
    }
    else if(*theArg == '@'){
		id obj;
        [self getReturnValue:&obj]; 
		return obj;
    }
	else if(!strncmp(theArg,"{_NSPo",6) || !strncmp(theArg,"{CGPoi",6)){
		NSPoint thePoint;
        [self getReturnValue:&thePoint]; 
		return [NSString stringWithFormat:@"@(%f,%f)",thePoint.x,thePoint.y];
	}
	else if(!strncmp(theArg,"{_NSRa",6) || !strncmp(theArg,"{CGRan",6)){
		NSRange theRange;
        [self getReturnValue:&theRange]; 
		return [NSString stringWithFormat:@"@(%f,%f)",(float)theRange.location,(float)theRange.length];
	}
	else if(!strncmp(theArg,"{_NSRe",6) || !strncmp(theArg,"{CGRec",6)){
		NSRect theRect;
        [self getReturnValue:&theRect]; 
		return [NSString stringWithFormat:@"@(%f,%f,%f,%f)",theRect.origin.x,theRect.origin.y,theRect.size.width,theRect.size.height];
	}
	else if(!strncmp(theArg,"{_NSSi",6) || !strncmp(theArg,"{CGSiz",6)){
		NSSize theSize;
        [self getReturnValue:&theSize]; 
		return [NSString stringWithFormat:@"@(%f,%f)",theSize.width,theSize.height];
	}
	

    if(returnValueAsString)return [NSDecimalNumber decimalNumberWithString:returnValueAsString];
    else return [NSDecimalNumber decimalNumberWithString:@"0"];
}

+ (id) invoke:(NSString*)args withTarget:(id)aTarget
{
	//this is a special method that is used by the ORCA scripting language to decode an arglist
	//the argList (args) is string of "name:<objPtr> name:<objPtr> etc..."
	//the <objPtr>'s are object pointers as integer strings. Here they are converted from strings back to integers and 
	//recast back to id pointers.
	id result = nil;
	NSArray* pairList = [args componentsSeparatedByString:@"#"];
	NSMutableArray* orderedList = [NSMutableArray array];
	NSString* pairString;
	NSUInteger n = [pairList count];
	int i;
	for(i=0;i<n;i++){
		pairString = [pairList objectAtIndex:i];
		NSRange rangeOfFirstColon = [pairString rangeOfString:@":"];
		NSString* part1 = nil;
		NSString* part2 = nil;
		if(rangeOfFirstColon.location!=NSNotFound){
			part1 = [pairString substringToIndex:rangeOfFirstColon.location];
			part2 = [pairString substringFromIndex:rangeOfFirstColon.location+1];
		}
		else part1 = pairString;
		if(part1)[orderedList addObject:part1];
		if(part2)[orderedList addObject:part2];
	}

	SEL theSelector = [NSInvocation makeSelectorFromArray:orderedList];
	int returnLength = 0;
	if([aTarget respondsToSelector:theSelector]){
		NSMethodSignature* theSignature = [aTarget methodSignatureForSelector:theSelector];
		returnLength = (int)[theSignature methodReturnLength];
		NSInvocation* theInvocation = [NSInvocation invocationWithMethodSignature:theSignature];
		[theInvocation setSelector:theSelector];
		NSUInteger n = [theSignature numberOfArguments]-2; //first two are hidden
		int i;
		int argI;
		BOOL ok = YES;
		for(i=1,argI=0 ; i<=n*2 ; i+=2,argI++){
			id str = [orderedList objectAtIndex:i];
			NSDecimalNumber* ptrNum = [NSDecimalNumber decimalNumberWithString:str];
			uint64_t ptr = [ptrNum unsignedLongLongValue];
			id theVar = (id)(ptr);
			if(![theInvocation setArgument:argI to:theVar]){
				ok = NO;
				break;
				
			}
		}
		if(ok){
			[theInvocation retainArguments];
            [theInvocation invokeWithNoUndoOnTarget:aTarget];
			if(returnLength!=0){
				result =  [theInvocation returnValue];
			}
		}
	}
	else {
		NSLog(@"Command not recognized: <%@>.\n",NSStringFromSelector(theSelector));
		result = [NSDecimalNumber zero];
	}
	return result;
}

- (void) invokeWithNoUndoOnTarget:(id)aTarget
{
    static char kExceptionKey;
    if (![[NSThread currentThread] isEqual:[NSThread mainThread]]) {
        // Call the function on the main thread.
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self _privateInvokeWithNoUndoOnTarget:aTarget
                                 withAssociatedKey:&kExceptionKey];
        });
        // The following is a no-op if no exception was seen in main thread
        [objc_getAssociatedObject(self, &kExceptionKey) raise];
    } else {
        [self _privateInvokeWithNoUndoOnTarget:aTarget withAssociatedKey:nil];
    }
}

+(NSInvocation*)invocationWithTarget:(id)target
                            selector:(SEL)aSelector
                     retainArguments:(BOOL)retainArguments
                     args:(id)firstArg,  ...;
{
    va_list ap;
    va_start(ap, firstArg);
    char* args = (char*)ap;
    NSMethodSignature* signature = [target methodSignatureForSelector:aSelector];
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
    if (retainArguments) {
        [invocation retainArguments];
    }
    [invocation setTarget:target];
    [invocation setSelector:aSelector];
    int index;
    for (index = 3; index < [signature numberOfArguments]; index++) {
        const char *type = [signature getArgumentTypeAtIndex:index];
        NSUInteger size, align;
        NSGetSizeAndAlignment(type, &size, &align);
        NSUInteger mod = (NSUInteger)args % align;
        if (mod != 0) {
            args += (align - mod);
        }
        [invocation setArgument:args atIndex:index];
        args += size;
    }
    va_end(ap);
    return invocation;
}
@end
