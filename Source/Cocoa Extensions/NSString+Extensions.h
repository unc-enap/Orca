//
//  NSData+Extensions.h
//  Orca
//
//  Created by Mark Howe on Wed Dec 04 2002.
//  Copyright � 2002 CENPA, University of Washington. All rights reserved.
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




typedef enum {
   LineEndingTypeNone	= 0,
   LineEndingTypeDOS	= 1,
   LineEndingTypeMac	= 2,
   LineEndingTypeUnix	= 3,
   LineEndingTypeOdd	= 4,
} LineEndingType;

@interface NSString (OR_NSStringWithExtensions)
- (NSString*) rightJustified:(NSUInteger)aWidth;
- (NSString*) leftJustified:(NSUInteger)aWidth;
- (NSString*) centered:(NSUInteger)aWidth;
- (NSString*) trimSpacesFromEnds;
- (NSString*) removeExtraSpaces;
-(NSString*) removeSpaces;
- (NSString*) removeNLandCRs;
- (NSArray*)  getValuesSeparatedByString:(NSString*)aDelimiter;
- (NSArray *) tokensSeparatedByCharactersFromSet:(NSCharacterSet *)set;
- (NSArray *)lines;
- (NSArray *)tabSeparatedComponents;

- (NSArray *)rowsAndColumns;
- (BOOL) decode:(NSString*)aString doubleValue:(double*)aValue;
- (BOOL) decode:(NSString*)aString intValue:(int*)aValue;
- (NSString*) decodeString:(NSString*)aString;

//number conversions needed by the command center
- (char) charValue;
- (unsigned char) unsignedCharValue;
- (short) shortValue;
- (unsigned short) unsignedShortValue;
- (unsigned int) unsignedIntValue;
- (unsigned long long) unsignedLongLongValue;
- (unsigned long) unsignedLongValue;
+ (NSString*) stringWithFormat:(NSString*)s parameters:(va_list)valist;

+ (NSString*) stringWithUSBDesc:(char*)aDesc;
@end

@interface NSString (HTML_Extensions)

+ (NSMutableArray *) extractArrayFromString:(NSString *)string
                                   startTag:(NSString *)startTag
                                     endTag:(NSString *)endTag;

+ (NSString*)scanString:(NSString *)string
               startTag:(NSString *)startTag
                 endTag:(NSString *)endTag;
@end

@interface NSMutableString (NSStringWithExtensions)
- (unsigned int)replace:(NSString *)target with:(NSString *)replacement;
@end

    
