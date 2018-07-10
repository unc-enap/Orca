//
//  NSDate_Extensions.h
//  Orca
//
//  Created by Mark Howe on 11/14/14.
//
//

#import <Cocoa/Cocoa.h>

@interface NSDate (ORCADateExtension)
- (NSString*) stdDescription;
- (NSString*) utcDescription;
- (NSString*) descriptionFromTemplate:(NSString*)aTemplate;
- (NSString*) descriptionFromTemplate:(NSString*)aTemplate timeZone:(NSString*)aTimeZone;
- (NSInteger) secondOfMinute;
- (NSInteger) minuteOfHour;
- (NSInteger) hourOfDay;
- (NSInteger) dayOfMonth;
- (NSInteger) monthOfYear;
- (NSInteger) yearOfCommonEra;
+ (NSDate*)dateUsingYear:(NSInteger)year month:(NSUInteger)month day:(NSUInteger)day hour:(NSUInteger)hour minute:(NSUInteger)minute second:(NSUInteger)second timeZone:(NSString *)aTimeZone;
+ (NSDate*) dateFromString:(NSString*)aDateStr calendarFormat:(NSString*)aFormat;

@end
