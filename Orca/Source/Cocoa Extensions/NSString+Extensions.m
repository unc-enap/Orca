//
//  NSString+Extensions.m
//  Orca
//
//  Created by Mark Howe on Wed Dec 04 2002.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark ¥¥¥Imported Files

@implementation NSString (OR_NSStringWithExtensions)

- (NSString*) rightJustified:(NSUInteger)aWidth
{
    return [NSString stringWithFormat:@"%*s", aWidth,[self UTF8String]];
}

- (NSString*) leftJustified:(NSUInteger)aWidth
{
    return [NSString stringWithFormat:@"%-*s", aWidth,[self UTF8String]];
}
- (NSString*) centered:(NSUInteger)aWidth
{
    int len = [self length];
    if(len >= aWidth)return self;
    else {
        int w = (aWidth - len)/2;
        return [[self leftJustified:len+w] rightJustified:aWidth];
    }
}
- (NSString*) trimSpacesFromEnds
{
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

-(NSString*) removeExtraSpaces
{
    NSArray* parts = [self tokensSeparatedByCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString* result = [parts componentsJoinedByString:@" "];
    return [[result copy] autorelease];
}

-(NSString*) removeSpaces
{
    NSArray* parts = [self tokensSeparatedByCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString* result = [parts componentsJoinedByString:@""];
    return [[result copy] autorelease];
}

- (NSString*) removeNLandCRs
{
    NSString* result = [[self componentsSeparatedByString:@"\r"]componentsJoinedByString:@" "];
    result = [[result componentsSeparatedByString:@"\n"]componentsJoinedByString:@" "];
    return result;
}


- (NSArray *)tokensSeparatedByCharactersFromSet:(NSCharacterSet *)set 
{
    //NSScanner rocks! ^_^
    NSString* aString = [[self componentsSeparatedByString:@","]componentsJoinedByString:@" "];
	
    NSScanner*      scanner     = [NSScanner scannerWithString:aString];
    NSString*       destination = [NSString string];
    NSMutableArray* tokens      = [NSMutableArray array];
	
    //throw away any leading whitespace
    [scanner scanUpToCharactersFromSet:[set invertedSet] intoString:nil];
	
    while(![scanner isAtEnd]) {
        [scanner scanUpToCharactersFromSet:set intoString:&destination];
        [scanner scanUpToCharactersFromSet:[set invertedSet] intoString:nil];
        if((destination != nil) && (![destination isEqualToString:@""])){
			[tokens addObject:[NSString stringWithString:destination]];
        }
        destination = [NSString string];
    }
    return [NSArray arrayWithArray:tokens];
}

- (NSArray*)  getValuesSeparatedByString:(NSString*)aDelimiter
{
    NSString* string = [self removeExtraSpaces];
    return [string componentsSeparatedByString:aDelimiter];
}

- (BOOL) decode:(NSString*)aString doubleValue:(double*)aValue
{
    NSRange theRange = [self rangeOfString:aString options:NSAnchoredSearch];
    if(theRange.location != NSNotFound){
        *aValue = [[self substringFromIndex:theRange.location + theRange.length] doubleValue];
        return YES;
    }
    else return NO;
}

- (BOOL) decode:(NSString*)aString intValue:(int*)aValue
{
    NSRange theRange = [self rangeOfString:aString options:NSAnchoredSearch];
    if(theRange.location != NSNotFound){
        *aValue = [[self substringFromIndex:theRange.location + theRange.length] intValue];
        return YES;
    }
    else return NO;
}

- (NSString*) decodeString:(NSString*)aString
{
    NSRange theRange = [self rangeOfString:aString options:NSAnchoredSearch];
    if(theRange.location != NSNotFound){
        return [self substringFromIndex:theRange.location + theRange.length];
    }
    else return nil;
}

- (LineEndingType)lineEndingType
{
	NSRange lineEndRange;
	
	// Is this an odd (i.e. CURL output) format?
	lineEndRange = [self rangeOfString:@"\n\r"];
	if (lineEndRange.location != NSNotFound) return LineEndingTypeOdd;
	
	
	// Is this alineEndRangeDOS format?
	lineEndRange = [self rangeOfString:@"\r\n"];
	if (lineEndRange.location != NSNotFound) return LineEndingTypeDOS;
	
	// Not DOS; is this the Mac format?
	lineEndRange = [self rangeOfString:@"\r"];
	if (lineEndRange.location != NSNotFound) return LineEndingTypeMac;
	
	// Not DOS or Mac, is this Unix format?
	lineEndRange = [self rangeOfString:@"\n"];
	if (lineEndRange.location != NSNotFound) return LineEndingTypeUnix;
	
	// This string has a single line
	return LineEndingTypeNone;
}

- (NSArray *)lines
{
	LineEndingType lineEndingType;
	
	lineEndingType = [self lineEndingType];
	
	switch (lineEndingType)
	{
		case LineEndingTypeOdd :  return [self componentsSeparatedByString: @"\n\r"];
		case LineEndingTypeDOS :  return [self componentsSeparatedByString: @"\r\n"];
		case LineEndingTypeMac :  return [self componentsSeparatedByString: @"\r"];
		case LineEndingTypeUnix : return [self componentsSeparatedByString: @"\n"];
		default : return [NSArray arrayWithObject: self];
	}
}

- (NSArray *)tabSeparatedComponents
{
	return [self componentsSeparatedByString: @"\t"];
}

- (NSArray *)rowsAndColumns
{
	return [[self lines] valueForKey: @"tabSeparatedComponents"];
}

+ (NSString*) stringWithUSBDesc:(char*)desc
{
    unsigned long   stringLength = desc[0] - 2;  // makes it neater
    char* p = (&desc[2]);	// Just the Unicode words (i.e., no size byte or descriptor type byte)
	char* p1 = p;
	char* p2 = p;
	int i;
	for(i=0;i<stringLength;i++){
		if(*p2 != '\0')*p1++ = *p2;
		p2++;
    }
	p[stringLength/2] = '\0';
	return [NSString stringWithUTF8String:p];
}

- (char) charValue
{
    return [[NSDecimalNumber decimalNumberWithString:self] charValue];
}

- (unsigned char) unsignedCharValue
{
    return [[NSDecimalNumber decimalNumberWithString:self] unsignedCharValue];
}

- (short) shortValue
{
    return [[NSDecimalNumber decimalNumberWithString:self] shortValue];
}

- (unsigned short) unsignedShortValue
{
    return [[NSDecimalNumber decimalNumberWithString:self] unsignedShortValue];
}

- (unsigned int) unsignedIntValue
{
    return [[NSDecimalNumber decimalNumberWithString:self] unsignedIntValue];
}

- (unsigned long long) unsignedLongLongValue
{
    return [[NSDecimalNumber decimalNumberWithString:self] unsignedLongLongValue];
}

- (unsigned long) unsignedLongValue
{
    return [[NSDecimalNumber decimalNumberWithString:self] unsignedLongValue];
}

+ (NSString*) stringWithFormat:(NSString*)a parameters:(va_list)valist;
{
    return [[[NSString alloc] initWithFormat:a arguments:valist] autorelease];
}

@end

@implementation NSMutableString (NSStringWithExtensions)
- (unsigned int)replace:(NSString *)target with:(NSString *)replacement
{
	if(!replacement)replacement = @"";
    return [self replaceOccurrencesOfString:target withString:replacement options:NSLiteralSearch range:NSMakeRange(0,[self length])];
}
@end

@implementation NSString (HTML_Extensions)

+ (NSMutableArray *) extractArrayFromString:(NSString *)string
                                   startTag:(NSString *)startTag
                                     endTag:(NSString *)endTag
{
    NSMutableArray* allStrings = [NSMutableArray array];
    NSScanner* scanner = [[NSScanner alloc] initWithString:string];
    if (string.length >0){
        while(1){
            @try {
                NSString* scanString = nil;
                
                [scanner scanUpToString:startTag intoString:nil];
                scanner.scanLocation += [startTag length];
                [scanner scanUpToString:endTag intoString:&scanString];
                if([scanString length]){
                    //remove the end of the start tag
                    NSRange r = [scanString rangeOfString:@">"];
                    NSString* s;
                    if(r.location != NSNotFound)s = [scanString substringFromIndex:r.location+1];
                    else s = scanString;
                    if(s)[allStrings addObject:s];
                }
                else break;
            }
            @catch(NSException* e){
                break;
            }
        }
    }
    return allStrings;
}

+ (NSString*)scanString:(NSString *)string
               startTag:(NSString *)startTag
                 endTag:(NSString *)endTag;
{
    NSScanner* scanner = [[NSScanner alloc] initWithString:string];
    NSString* scanString = @"";
    if (string.length >0){
        @try {
            [scanner scanUpToString:startTag intoString:nil];
            scanner.scanLocation += [startTag length];
            [scanner scanUpToString:endTag intoString:&scanString];
            //remove the end of the start tag
            NSRange r = [scanString rangeOfString:@">"];
            if(r.location != NSNotFound)scanString = [scanString substringFromIndex:r.location+1];
            
        }
        @catch(NSException* e){
        }
    }
    return scanString;
}
@end
