//
//  ORAlarm.m
//  Orca
//
//  Created by Mark Howe on Fri Jan 17 2003.
//  Copyright © 2003 CENPA, University of Washington. All rights reserved.
//
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


NSString* ORAlarmWasPostedNotification 			= @"Alarm Posted Notification";
NSString* ORAlarmWasClearedNotification 		= @"Alarm Cleared Notification";
NSString* ORAlarmWasAcknowledgedNotification 	= @"ORAlarmWasAcknowledgedNotification";
NSString* ORAlarmWasChangedNotification         = @"ORAlarmWasChangedNotification";

NSString* severityName[kNumAlarmSeverityTypes] = {
	@"Information",	
	@"Setup",
	@"Out of Range",			
	@"Hardware",			
	@"RunInhibitor",		
	@"DataFlow",		
	@"Important",	
	@"Emergency",
};


@implementation ORAlarm
+ (NSString*) alarmSeverityName:(int) i
{
	if(i<0 || i>kNumAlarmSeverityTypes)return @"";
	else return severityName[i];
}

#pragma mark •••Initialization
- (id) initWithName:(NSString*)aName severity:(AlarmSeverityTypes)aSeverity
{
    self = [super init];
    
    name = [aName copy];
    [self setSeverity:aSeverity];
    [self setSticky:NO];
    [self setMailDelay:k60SecDelay];
    return self;
}

- (void) dealloc
{
    [timePosted release];
    [name release];
	[additionalInfoString release];
    [self setSeverity:kInformationAlarm];
    [helpString release];
    [super dealloc];
}

#pragma mark •••Accessors

- (NSTimeInterval) timeSincePosted
{
	return [[NSDate date] timeIntervalSinceDate:timePosted];
}

- (NSString*) timePosted
{
   return [timePosted stdDescription];

}

- (NSString*) timePostedUTC
{
    return [timePosted descriptionFromTemplate:@"MM/dd/yy HH:mm:ss" timeZone:@"UTC"];
}

- (void) setTimePosted:(NSDate*)aDate
{
    [aDate retain];
    [timePosted release];
    timePosted = aDate;
}

- (NSString*) name
{
    return name;
}

- (void) setName:(NSString*)aName
{
    BOOL changed = ![aName isEqualToString:name];
    if(name && changed && !acknowledged) NSLogColor([NSColor redColor],@"Alarm changed from [%@] to [%@]\n",name,aName);

    [name autorelease];
    name = [aName copy];
    
    if(changed){
        [[NSNotificationCenter defaultCenter] postNotificationName:ORAlarmWasChangedNotification object:self];
    }
}

- (int) mailDelay
{
    return mailDelay;
}

- (void) setMailDelay:(int)aTime
{
    if(mailDelay == 0)         aTime = k60SecDelay;
    if(mailDelay > k60SecDelay)aTime = k60SecDelay;
    mailDelay = aTime;
}

- (int) severity
{
    return severity;
}

- (NSString*) severityName
{
	if(severity>=0 && severity<kNumAlarmSeverityTypes) return severityName[severity];
	else return @"Illegal Severity";
}


- (void) setSeverity:(int)aValue
{
    severity = aValue;
}

- (NSString*) additionalInfoString
{
	return additionalInfoString;
}

- (void) setAdditionalInfoString:(NSString*)aString
{
    [additionalInfoString autorelease];
    additionalInfoString = [aString copy];    
}

- (void) setHelpString:(NSString*)aString
{
    [helpString autorelease];
    helpString = [aString copy];    
}

- (NSString*) helpString
{
	if(helpString && [helpString length]){
		return [[self genericHelpString] stringByAppendingString:helpString];
	}
    else return [self genericHelpString];
}

- (NSString*) acknowledgedString
{
    return acknowledged?@"Yes":@"No";
}

- (BOOL) acknowledged
{
    return acknowledged;
}

- (NSString*) alarmWasAcknowledged
{
    return acknowledged?@"YES":@"NO";
}

- (void) setAcknowledged:(BOOL)aState
{
    acknowledged = aState;
}

- (void) setSticky:(BOOL)aState
{
    sticky = aState;
}

- (BOOL) sticky
{
    return sticky;
}
- (NSString*) genericHelpString
{
	return [NSString stringWithFormat:@"Name:%@  Severity:%@ Posted:%@    [%@ (UTC)]\n",[self name],[self severityName],[self timePosted],[self timePostedUTC]];
}


#pragma mark •••Alarm Management
- (void) postAlarm
{
    [self setTimePosted:[NSDate date]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAlarmWasPostedNotification object:self];
}

- (void) clearAlarm
{
//    [[NSNotificationCenter defaultCenter] postNotificationName:ORAlarmWasClearedNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORAlarmWasClearedNotification object:self];
}

- (void) setIsPosted:(BOOL)state
{
	isPosted = state;
}

- (BOOL) isPosted
{
	return isPosted;
}

- (void) acknowledge
{
    [self setAcknowledged:YES];
    if(!sticky){
        [self clearAlarm];
    }
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORAlarmWasAcknowledgedNotification object:self];
    NSLog(@" Alarm: [%@] Acknowledged\n",[self name]);
}

- (void) setHelpStringFromFile:(NSString*)fileName
{
	
    NSBundle* mainBundle = [NSBundle mainBundle];
	NSString*   path = [mainBundle pathForResource: fileName ofType: @"plist"];
    if([[NSFileManager defaultManager] fileExistsAtPath:path]){
        NSArray* tempArray = [NSArray arrayWithContentsOfFile:path];
        if([tempArray count]){
            [self setHelpString:[tempArray objectAtIndex:0]];
        }
    }
    else {    
        NSString* resourcePath = [[mainBundle resourcePath] stringByAppendingString:@"/Alarm Help Files/"];
        NSString* fullPath = [resourcePath stringByAppendingString:fileName];
        if([[NSFileManager defaultManager] fileExistsAtPath:fullPath]){
            [self setHelpString:[NSString stringWithContentsOfFile:fullPath encoding:NSASCIIStringEncoding error:nil]];
        }
    }
}
- (NSDictionary*) alarmInfo
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy/MM/dd HH:mm:ss";
    
    NSTimeZone* gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    [dateFormatter setTimeZone:gmt];
    NSString*   lastTimeStamp       = [dateFormatter stringFromDate:timePosted];
    NSDate*     gmtTime             = [dateFormatter dateFromString:lastTimeStamp];
    uint32_t secondsSince1970  = [gmtTime timeIntervalSince1970];
    [dateFormatter release];

    
    
	return [NSDictionary dictionaryWithObjectsAndKeys:
            [timePosted description],                           @"timePosted",
            [NSNumber numberWithUnsignedLong:[self severity]],  @"severity",
            [self name],                                        @"name",
            [self helpString],                                  @"help",
            lastTimeStamp,                                      @"timestamp",
            [NSNumber numberWithUnsignedLong: secondsSince1970],@"time",
            [NSNumber numberWithInt:[self acknowledged]],       @"acknowledged",
            nil];
}


@end
