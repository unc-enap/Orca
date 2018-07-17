//
//  ORAdcModel.m
//  Orca
//
//  Created by Mark Howe on 11/25/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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


#import "ORAdcModel.h"
#import "ORProcessOutConnector.h"
#import "ORProcessInConnector.h"
#import "ORProcessModel.h"
#import "ORProcessThread.h"
#import "ORAdcProcessing.h"

NSString* ORAdcModelTrackMaxMinChanged	= @"ORAdcModelTrackMaxMinChanged";
NSString* ORAdcModelHighTextChanged		= @"ORAdcModelHighTextChanged";
NSString* ORAdcModelInRangeTextChanged	= @"ORAdcModelInRangeTextChanged";
NSString* ORAdcModelLowTextChanged		= @"ORAdcModelLowTextChanged";
NSString* ORAdcModelMinChangeChanged	= @"ORAdcModelMinChangeChanged";
NSString* ORAdcModelOKConnection		= @"ORAdcModelOKConnection";
NSString* ORAdcModelLowConnection		= @"ORAdcModelLowConnection";
NSString* ORAdcModelHighConnection		= @"ORAdcModelHighConnection";
NSString* ORAdcModelOutOfRangeLow       = @"ORAdcModelOutOfRangeLow";
NSString* ORAdcModelOutOfRangeHi       = @"ORAdcModelOutOfRangeHi";
NSString* ORSimpleInConnection   = @"ORSimpleInConnection";

@interface ORAdcModel (private)
- (NSImage*) composeIcon;
- (NSImage*) composeLowLevelIcon;
- (NSImage*) composeHighLevelIcon;
- (NSImage*) composeHighLevelIconAsMeter;
- (NSImage*) composeHighLevelIconAsText;
- (NSImage*) composeHighLevelIconAsBar;
- (NSImage*) composeHighLevelIconAsWordBar;
@end

@implementation ORAdcModel

@synthesize lastValue;

- (void) dealloc
{
    [highText release];
    [inRangeText release];
    [lowText release];
	[lowLimitNub release];
	[highLimitNub release];
	[normalGradient release];
	[alarmGradient release];
	[resetDate release];
	[lowDate release];
    [lastValue release];

	[super dealloc];
}

#pragma mark ***Accessors

- (BOOL) trackMaxMin
{
    return trackMaxMin;
}

- (void) setTrackMaxMin:(BOOL)aTrackMaxMin
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTrackMaxMin:trackMaxMin];
    trackMaxMin = aTrackMaxMin;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAdcModelTrackMaxMinChanged object:self];
}

- (NSString*) highText
{
	if(!highText)return @"High";
    return highText;
}

- (void) setHighText:(NSString*)aHighText
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHighText:highText];
    
    [highText autorelease];
    highText = [aHighText copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAdcModelHighTextChanged object:self];
}

- (NSString*) inRangeText
{
	if(!inRangeText)return @"In Range";
    return inRangeText;
}

- (void) setInRangeText:(NSString*)aInRangeText
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInRangeText:inRangeText];
    
    [inRangeText autorelease];
    inRangeText = [aInRangeText copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAdcModelInRangeTextChanged object:self];
}

- (NSString*) lowText;
{
	if(!lowText)return @"Low";
    return lowText;
}

- (void) setLowText:(NSString*)aLowText;
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLowText:lowText];
    
    [lowText autorelease];
    lowText = [aLowText copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAdcModelLowTextChanged object:self];
}

- (float) minChange
{
    return minChange;
}

- (void) setMinChange:(float)aMinChange
{
	if(aMinChange<0)aMinChange=0;
    [[[self undoManager] prepareWithInvocationTarget:self] setMinChange:minChange];
    minChange = aMinChange;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAdcModelMinChangeChanged object:self];
}

-(void)makeConnectors
{  
    ORProcessOutConnector* aConnector;      
    aConnector = [[ORProcessOutConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,[self frame].size.height-kConnectorSize) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORAdcModelHighConnection];
    [ aConnector setConnectorType: 'LP2 ' ];
    [ aConnector addRestrictedConnectionType: 'LP1 ' ]; //can only connect to processor inputs
    [aConnector release];

    aConnector = [[ORProcessOutConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,[self frame].size.height/2 - kConnectorSize/2+5) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORAdcModelOKConnection];
    [ aConnector setConnectorType: 'LP2 ' ];
    [ aConnector addRestrictedConnectionType: 'LP1 ' ]; //can only connect to processor inputs
    [aConnector release];

    aConnector = [[ORProcessOutConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,10) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORAdcModelLowConnection];
    [ aConnector setConnectorType: 'LP2 ' ];
    [ aConnector addRestrictedConnectionType: 'LP1 ' ]; //can only connect to processor inputs
    [aConnector release];
    
    ORProcessInConnector* inConnector = [[ORProcessInConnector alloc] initAt:NSMakePoint(0,kConnectorSize/2+8) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:inConnector forKey:ORSimpleInConnection];
    [ inConnector setConnectorType: 'LP1 ' ];
    [ inConnector addRestrictedConnectionType: 'LP2 ' ]; //can only connect to processor outputs
    [[self connectors] setObject:inConnector forKey:@"Multiplier"];
    [inConnector release];

}

- (void) setUpNubs
{
	ORConnector* aConnector;
    if(!lowLimitNub)lowLimitNub = [[ORAdcLowLimitNub alloc] init];
    [lowLimitNub setGuardian:self];
    aConnector = [[self connectors] objectForKey: ORAdcModelLowConnection];
    [aConnector setObjectLink:lowLimitNub];


    if(!highLimitNub)highLimitNub = [[ORAdcHighLimitNub alloc] init];
    [highLimitNub setGuardian:self];
    aConnector = [[self connectors] objectForKey: ORAdcModelHighConnection];
    [aConnector setObjectLink:highLimitNub];
}

- (NSString*) elementName
{
	return @"ADC";
}

- (NSArray*) validObjects
{
    return [[self document] collectObjectsConformingTo:@protocol(ORAdcProcessing)];
}

- (void) makeMainController
{
    [self linkToController:@"ORAdcController"];
}

- (BOOL) canBeInAltView
{
	return YES;
}

- (void) setUpImage
{
	[self setImage:[self composeIcon]];
}

- (BOOL) valueTooLow
{
	return valueTooLow;
}

- (BOOL) valueTooHigh
{
	return valueTooHigh;
}

- (double) lowLimit
{
	return lowLimit;
}

- (double) highLimit
{
	return highLimit;
}

- (double) hwValue
{
	return hwValue;
}

- (double) maxValue
{
	return maxValue;
}
- (double) minValue
{
	return minValue;
}

- (void) processIsStarting
{
	[self resetReportValues];
    [super processIsStarting];
    [ORProcessThread registerInputObject:self];
    id obj = [self objectConnectedTo:@"Multiplier"];
    [obj processIsStarting];

}
- (void) processIsStopping
{
    [super processIsStopping];
    id obj = [self objectConnectedTo:@"Multiplier"];
    [obj processIsStopping];
}
- (void) viewSource
{
	[[self hwObject] showMainInterface];
}

- (BOOL) isTrueEndNode
{
    return  [self objectConnectedTo:ORAdcModelHighConnection]==nil &&
            [self objectConnectedTo:ORAdcModelLowConnection]==nil &&
            [self objectConnectedTo:ORAdcModelOKConnection]==nil;
}

//--------------------------------
//runs in the process logic thread
- (id) eval
{
	if(!alreadyEvaluated){
		alreadyEvaluated = YES;
		BOOL updateNeeded = NO;
		if(![guardian inTestMode] && hwObject!=nil){
			double theConvertedValue  = [hwObject convertedValue:[self bit]]; //reads the hw
			double theMaxValue		  = [hwObject maxValueForChan:[self bit]];
			double theMinValue		  = [hwObject minValueForChan:[self bit]];
		
			if(fabs(theConvertedValue-hwValue) > minChange || theMaxValue!=maxValue || theMinValue!=minValue)updateNeeded = YES;
            
            float multiplier = 1;
            id obj = [self objectConnectedTo:@"Multiplier"];
            if(obj){
                ORProcessResult* theResult = [obj eval];
                multiplier = [theResult analogValue];
            }
            
			hwValue = theConvertedValue * multiplier;
			maxValue = theMaxValue;
			minValue = theMinValue;
			
			double theLowLimit,theHighLimit;
			[hwObject getAlarmRangeLow:&theLowLimit high:&theHighLimit channel:[self bit]];
			if(theLowLimit!=lowLimit || theHighLimit!=highLimit)updateNeeded = YES;

			lowLimit = theLowLimit;
			highLimit = theHighLimit;

			valueTooLow  = hwValue<lowLimit;
			valueTooHigh = hwValue>highLimit;
			
			if(trackMaxMin)[self checkMaxMinValues];
		}
		BOOL newState = !(valueTooLow || valueTooHigh);
		if(valueTooLow){
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORAdcModelOutOfRangeLow object:self userInfo:nil waitUntilDone:YES];
        }
		if(valueTooHigh){
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORAdcModelOutOfRangeHi object:self userInfo:nil waitUntilDone:YES];
        }
        
		if((newState == [self state]) && updateNeeded){
			//if the state will not post an update, then do it here.
			[self postStateChange];
		}
		[self setState: newState];
		[self setEvaluatedState: newState];
	}
	return [ORProcessResult processState:evaluatedState value:hwValue];
}

//--------------------------------
- (NSString*) iconValue 
{ 
    if(hwName)	{
		NSString* theFormat = @"%.1f";
		if([displayFormat length] != 0)									theFormat = displayFormat;
		if([theFormat rangeOfString:@"%@"].location !=NSNotFound)		theFormat = @"%.1f";
		else if([theFormat rangeOfString:@"%d"].location !=NSNotFound)	theFormat = @"%.0f";
		return [NSString stringWithFormat:theFormat,[self hwValue]];
	}
	else return @"";
}

- (NSString*) report
{	
	NSString* s = @"";
	@synchronized(self){
        BOOL isValid = YES;
        if([hwObject respondsToSelector:@selector(dataForChannelValid:)]){
            isValid = [hwObject dataForChannelValid:[self bit]];
        }
        if(isValid){
            NSString* currentValue = [self iconValue];
            s =  [NSString stringWithFormat:@"%@: %@ ", [self iconLabel],currentValue];
            if([lastValue length]){
                if([lastValue isEqualToString:currentValue]){
                    s = [s stringByAppendingString:@"(Unchanged!) "];
                }
            }
            self.lastValue = currentValue;
            
            NSString* theFormat = @"%.1f";
            if([displayFormat length] != 0)									theFormat = displayFormat;
            if([theFormat rangeOfString:@"%@"].location !=NSNotFound)		theFormat = @"%.1f";
            else if([theFormat rangeOfString:@"%d"].location !=NSNotFound)	theFormat = @"%.0f";
            
            if(valueTooLow)	{
                s =  [s stringByAppendingFormat:@" [BELOW USER SPECIFIED LIMIT (%@)] ",[NSString stringWithFormat:theFormat,lowLimit]];
            }
            else if(valueTooHigh){
               s =  [s stringByAppendingFormat:@" [ABOVE USER SPECIFIED LIMIT (%@)] ",[NSString stringWithFormat:theFormat,highLimit]];
            }
            
            if(trackMaxMin){
                NSString* highestValueString =  [NSString stringWithFormat:theFormat,highestValue];
                NSString* lowestValueString  =  [NSString stringWithFormat:theFormat,lowestValue];
                
                s =  [s stringByAppendingFormat:@" [Lowest %@ at %@]  [Highest %@ at %@] ",
                      lowestValueString, [lowDate stdDescription], highestValueString, [highDate stdDescription]];
            }
        }
        else s =  [NSString stringWithFormat:@"%@: Data Unavailable ", [self iconLabel]];
	}
	return s;
	
}

- (void) checkMaxMinValues
{
	@synchronized(self){
		double theHWValue = [self hwValue];
		if(theHWValue>highestValue){
			highestValue = theHWValue;
			[highDate release];
			highDate = [[NSDate date] retain];		
		}
		if(theHWValue<lowestValue){
			lowestValue = theHWValue;
			[lowDate release];
			lowDate = [[NSDate date] retain];		
		}
	}
}

- (void) resetReportValues
{
	@synchronized(self){
		[resetDate release];
		resetDate = [[NSDate date] retain];
		
		[highDate release];
		highDate = [[NSDate date] retain];
		highestValue = -1E99;
		
		[lowDate release];
		lowDate = [[NSDate date] retain];
		lowestValue = 1E99;
	}
}

- (id) description
{
	NSString* s = [self iconLabel];
	
	s =  [s stringByAppendingFormat:@" Value: %@ ",[self iconValue]];
	if(valueTooLow)		  s =  [s stringByAppendingString:@"[Low] "];
	else if(valueTooHigh) s =  [s stringByAppendingString:@"[High] "];
	else				  s =  [s stringByAppendingString:@"[In Range] "];
	return s;
}


#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setTrackMaxMin:	[decoder decodeBoolForKey:@"trackMaxMin"]];
    [self setHighText:		[decoder decodeObjectForKey:@"highText"]];
    [self setInRangeText:	[decoder decodeObjectForKey:@"inRangeText"]];
    [self setLowText:		[decoder decodeObjectForKey:@"lowText;"]];
    [self setMinChange:		[decoder decodeFloatForKey:@"minChange"]];
    [[self undoManager] enableUndoRegistration];    

    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:trackMaxMin		forKey:@"trackMaxMin"];
    [encoder encodeObject:highText		forKey:@"highText"];
    [encoder encodeObject:inRangeText	forKey:@"inRangeText"];
    [encoder encodeObject:lowText		forKey:@"lowText;"];
    [encoder encodeFloat: minChange		forKey:@"minChange"];
}

- (NSString*) iconLabel
{
	if(![self useAltView]){
		if(hwName)	{
			if(labelType ==2) return [self customLabel];
			else              return [NSString stringWithFormat:@"%@,%d",hwName,bit];
		}
		else		return @""; 
	}
	else {
		if(labelType == 1)return @"";
		else if(labelType ==2)return [self customLabel];
		else {
			if(hwName)	return [NSString stringWithFormat:@"%@,%d",hwName,bit];
			else		return @""; 
		}
	}
}
- (NSDictionary*) valueDictionary
{
    BOOL isValid = YES;
    if([hwObject respondsToSelector:@selector(dataForChannelValid:)]){
        isValid = [hwObject dataForChannelValid:[self bit]];
    }
    if(isValid){
        NSString* theName = [self iconLabel];
        if([theName rangeOfString:@","].location!=NSNotFound){
            theName = [theName stringByReplacingOccurrencesOfString:@"," withString:@"_"];
        }
        return [NSDictionary dictionaryWithObject:[NSNumber numberWithDouble:[self hwValue]] forKey:theName];
    }
    else return nil;
}
@end

@implementation ORAdcModel (private)

- (NSImage*) composeIcon
{
	if(![self useAltView])	return [self composeLowLevelIcon];
	else					return [self composeHighLevelIcon];
}

- (NSImage*) composeLowLevelIcon
{
	NSImage* anImage = [NSImage imageNamed:@"adc"];
	
	NSSize theIconSize = [anImage size];
    NSImage* finalImage = [[NSImage alloc] initWithSize:theIconSize];
    [finalImage lockFocus];
    [anImage drawAtPoint:NSZeroPoint fromRect:[anImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];

	NSAttributedString* idLabel   = [self idLabelWithSize:9 color:[NSColor blackColor]];
	NSAttributedString* iconValue = [self iconValueWithSize:9 color:[NSColor blackColor]];
	NSAttributedString* iconLabel = [self iconLabelWithSize:9 color:[NSColor blackColor]];
	
	if(minValue-maxValue != 0){
		NSPoint theCenter = NSMakePoint((theIconSize.width-10)/2.+1,27);
		if(lowLimit>minValue){
			NSBezierPath* path = [NSBezierPath bezierPath];
			float lowLimitAngle = 180*(lowLimit-minValue)/(maxValue-minValue);
			lowLimitAngle =  180-lowLimitAngle;
			if(lowLimitAngle>=0 && lowLimitAngle<=180){
				[path appendBezierPathWithArcWithCenter:theCenter radius:30
											 startAngle:lowLimitAngle endAngle:180];
				[path lineToPoint:theCenter];
				[path closePath];
				[[NSColor colorWithCalibratedRed:.7 green:.4 blue:.4 alpha:.2] set];
				[path fill];
			}
		}
		
		if(highLimit<maxValue){
			float highLimitAngle = 180*(highLimit-minValue)/(maxValue-minValue);
			highLimitAngle = 180-highLimitAngle;
			if(highLimitAngle>=0 && highLimitAngle<=180){
				NSBezierPath* path = [NSBezierPath bezierPath];
				[path appendBezierPathWithArcWithCenter:theCenter radius:30
											 startAngle:0 endAngle:highLimitAngle];
				[path lineToPoint:theCenter];
				[path closePath];
				[[NSColor colorWithCalibratedRed:.7 green:0.4 blue:.4 alpha:.2] set];
				[path fill];
			}
		}
		
		float slope = (180 - 0)/(minValue-maxValue);
		float intercept = 180 - slope*minValue;
		float needleAngle = slope*hwValue + intercept;
		if(needleAngle<0)needleAngle=0;
		if(needleAngle>180)needleAngle=180;
		
		float nA = .0174553*needleAngle;
		[NSBezierPath setDefaultLineWidth:0];
		[[NSColor blackColor] set];
		[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(theCenter.x-2*1,theCenter.y-2*1,4,4)];
		[[NSColor redColor] set];
		[NSBezierPath strokeLineFromPoint:theCenter toPoint:NSMakePoint(theCenter.x + 30.*cosf(nA),theCenter.y + 30.*sinf(nA))];
	}
	
	if(iconValue){
		NSSize textSize = [iconValue size];
		float x = (theIconSize.width-kConnectorSize)/2 - textSize.width/2;
		[iconValue drawInRect:NSMakeRect(x,13,textSize.width,textSize.height)];
	}
	
	if(iconLabel){
		NSSize textSize = [iconLabel size];
		float x = theIconSize.width/2 - textSize.width/2;
		[iconLabel drawInRect:NSMakeRect(x,0,textSize.width,textSize.height)];
	}
	
	if(idLabel){
		NSSize textSize = [idLabel size];
		[idLabel drawInRect:NSMakeRect(15,theIconSize.height-textSize.height-2,textSize.width,textSize.height)];
	}

	[finalImage unlockFocus];
	return [finalImage autorelease];
}

- (void) setViewIconType:(int)aViewIconType
{
	[alarmGradient release];
	alarmGradient = nil;
	[super setViewIconType:aViewIconType];
}

- (NSImage*) composeHighLevelIcon
{
	if(viewIconType == 0)		return [self composeHighLevelIconAsMeter];
	else if(viewIconType == 1)	return [self composeHighLevelIconAsText];
	else if(viewIconType == 2)	return [self composeHighLevelIconAsBar];
	else if(viewIconType == 3)	return [self composeHighLevelIconAsWordBar];
	else if(viewIconType == 4)	return nil;
	else						return nil;
}

- (NSImage*) composeHighLevelIconAsMeter
{
	NSImage* anImage = [NSImage imageNamed:@"adcMeter"];
	NSAttributedString* idLabel   = [self idLabelWithSize:9 color:[NSColor whiteColor]];
	NSAttributedString* iconValue = [self iconValueWithSize:12 color:[NSColor whiteColor]];
	NSAttributedString* iconLabel = [self iconLabelWithSize:9 color:[NSColor whiteColor]];
	
	NSAttributedString* iconValueMin =  [[[NSAttributedString alloc] 
			 initWithString:[NSString stringWithFormat:@"%.1f", minValue]
			 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
						 [NSFont messageFontOfSize:9],NSFontAttributeName,
						 [NSColor whiteColor],NSForegroundColorAttributeName,nil]]autorelease];
	
	NSAttributedString* iconValueMax =  [[[NSAttributedString alloc] 
			initWithString:[NSString stringWithFormat:@"%.1f", maxValue]
			attributes:[NSDictionary dictionaryWithObjectsAndKeys:
						 [NSFont messageFontOfSize:9],NSFontAttributeName,
						 [NSColor whiteColor],NSForegroundColorAttributeName,nil]]autorelease];
	
	NSSize theIconSize = [anImage size];
	
    NSImage* finalImage = [[NSImage alloc] initWithSize:theIconSize];
    [finalImage lockFocus];
    [anImage drawAtPoint:NSZeroPoint fromRect:[anImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
	
	float slope = (195. + 15.)/(minValue-maxValue);
	float intercept = 195. - slope*minValue;

	if(minValue-maxValue != 0){
		NSPoint theCenter = NSMakePoint((theIconSize.width)/2.,45.);
		if(lowLimit>minValue){
			NSBezierPath* path = [NSBezierPath bezierPath];
			float lowLimitAngle = slope*lowLimit + intercept;
			//float lowLimitAngle = 195.*(lowLimit-minValue)/(maxValue-minValue);
			//lowLimitAngle =  195.-lowLimitAngle;
			if(lowLimitAngle>=-15. && lowLimitAngle<=195.){
				[path appendBezierPathWithArcWithCenter:theCenter radius:60.
											 startAngle:lowLimitAngle endAngle:195.];
				[path lineToPoint:theCenter];
				[path closePath];
				[[NSColor colorWithCalibratedRed:.7 green:.4 blue:.4 alpha:.5] set];
				[path fill];
			}
		}
		
		if(highLimit<maxValue){
			//float highLimitAngle = 195.*(highLimit-minValue)/(maxValue-minValue);
			float highLimitAngle = slope*highLimit + intercept;
			//highLimitAngle = 195.-highLimitAngle;
			if(highLimitAngle>=-15. && highLimitAngle<=195.){
				NSBezierPath* path = [NSBezierPath bezierPath];
				[path appendBezierPathWithArcWithCenter:theCenter radius:60.
											 startAngle:-15. endAngle:highLimitAngle];
				[path lineToPoint:theCenter];
				[path closePath];
				[[NSColor colorWithCalibratedRed:.7 green:0.4 blue:.4 alpha:.5] set];
				[path fill];
			}
		}
		
		float slope = (195. + 15.)/(minValue-maxValue);
		float intercept = 195. - slope*minValue;
		float needleAngle = slope*hwValue + intercept;
		if(needleAngle<-15.)needleAngle=-15.;
		if(needleAngle>195.)needleAngle=195.;
		
		float nA = .0174553*needleAngle;
		[NSBezierPath setDefaultLineWidth:3];
		[[NSColor blackColor] set];
		[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(theCenter.x,theCenter.y,4,4)];
		[[NSColor redColor] set];
		[NSBezierPath strokeLineFromPoint:theCenter toPoint:NSMakePoint(theCenter.x + 60.*cosf(nA),theCenter.y + 60.*sinf(nA))];
	}
	
	if(iconValueMin){		
		NSSize textSize = [iconValueMin size];
		[iconValueMin drawInRect:NSMakeRect(16,16,textSize.width,textSize.height)];
	}
	
	if(iconValueMax){		
		NSSize textSize = [iconValueMax size];
		float x = theIconSize.width - textSize.width - 16;
		[iconValueMax drawInRect:NSMakeRect(x,16,textSize.width,textSize.height)];
	}
	
	if(iconValue){		
		NSSize textSize = [iconValue size];
		float x = theIconSize.width/2 - textSize.width/2- 4;
		[iconValue drawInRect:NSMakeRect(x,18,textSize.width,textSize.height)];
	}
	
	if(iconLabel){		
		NSSize textSize = [iconLabel size];
		float x = theIconSize.width/2 - textSize.width/2;
		[iconLabel drawInRect:NSMakeRect(x,3,textSize.width,textSize.height)];
	}
	
	if(idLabel){		
		NSSize textSize = [idLabel size];
		[idLabel drawInRect:NSMakeRect(5,theIconSize.height-textSize.height-2,textSize.width,textSize.height)];
	}
	
    [finalImage unlockFocus];
	return [finalImage autorelease];
}

- (NSImage*) composeHighLevelIconAsWordBar
{
	NSImage* anImage = [NSImage imageNamed:@"adcHorizontalBar"];
	NSAttributedString* idLabel   = [self idLabelWithSize:12 color:[NSColor blackColor]];
	NSAttributedString* iconLabel = [self iconLabelWithSize:12 color:[NSColor blackColor]];
	
	NSSize theIconSize	= [anImage size];
	float iconStart		= MAX([iconLabel size].width,[idLabel size].width) + 1;
	theIconSize.width += iconStart;
	
    NSImage* finalImage = [[NSImage alloc] initWithSize:theIconSize];
    [finalImage lockFocus];
    [anImage drawAtPoint:NSMakePoint(iconStart,0) fromRect:[anImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
	if(!normalGradient){
		CGFloat red   = 1.0;
		CGFloat green = 1.0;
		CGFloat blue  = 1.0;
		
		normalGradient = [[NSGradient alloc] 
						  initWithStartingColor:[NSColor colorWithCalibratedRed:red green:green blue:blue alpha:1]
						  endingColor:[NSColor colorWithCalibratedRed:.5*red green:.5*green blue:.5*blue alpha:1]];
	}
	
	if(!alarmGradient){
		float red   = 1.0; 
		float green = 1.0; 
		float blue  = 1.0;
		
		alarmGradient = [[NSGradient alloc]
						 initWithStartingColor:[NSColor colorWithCalibratedRed:red green:green blue:blue alpha:1]
						 endingColor:[NSColor colorWithCalibratedRed:.5*red green:.5*green blue:.5*blue alpha:1]];
	}
	
	float w = 231;
	float h = theIconSize.height;
	float startx = iconStart+6;
		
	float theValue = [self hwValue];
	float theSize = 14;
	NSColor* textColor = [NSColor blackColor];
	NSAttributedString* iconString = nil;
	if(theValue<lowLimit){
		[alarmGradient drawInRect:NSMakeRect(startx,4,w,24) angle:270];

		iconString = [[[NSAttributedString alloc] 
					   initWithString:[self lowText]
					       attributes:[NSDictionary dictionaryWithObjectsAndKeys:
									   [NSFont fontWithName:@"Geneva" size:10],NSFontAttributeName,
									   textColor,NSForegroundColorAttributeName,nil]]autorelease];	
	}
		
	else if(theValue>highLimit){
		[alarmGradient drawInRect:NSMakeRect(startx,4,w,24) angle:270];
		iconString = [[[NSAttributedString alloc] 
					   initWithString:[self highText]
					   attributes:[NSDictionary dictionaryWithObjectsAndKeys:
								   [NSFont messageFontOfSize:theSize],NSFontAttributeName,
								   textColor,NSForegroundColorAttributeName,nil]]autorelease];	
	}
	else {
		[normalGradient drawInRect:NSMakeRect(startx,4,w,24) angle:270];
		iconString = [[[NSAttributedString alloc] 
					   initWithString:[self inRangeText]
					   attributes:[NSDictionary dictionaryWithObjectsAndKeys:
								   [NSFont messageFontOfSize:theSize],NSFontAttributeName,
								   textColor,NSForegroundColorAttributeName,nil]]autorelease];	
	}
				
	if([iconLabel length]){		
		NSSize textSize = [iconLabel size];
		[iconLabel drawInRect:NSMakeRect(iconStart-textSize.width-1,3,textSize.width,textSize.height)];
	}
	
	if([idLabel length]){		
		NSSize textSize = [idLabel size];
		[idLabel drawInRect:NSMakeRect(iconStart-textSize.width-1,theIconSize.height-textSize.height,textSize.width,textSize.height)];
	}
	
	if(iconString){		
		NSSize textSize = [iconString size];
		float x = iconStart + 10 + w/2 - textSize.width/2;
		float y = h/2 - textSize.height/2;
		[iconString drawInRect:NSMakeRect(x,y,textSize.width,textSize.height)];
	}
	
    [finalImage unlockFocus];
	return [finalImage autorelease];
}

- (NSImage*) composeHighLevelIconAsText
{
	NSImage* anImage = [NSImage imageNamed:@"adcText"];
	NSAttributedString* idLabel   = [self idLabelWithSize:12 color:[NSColor blackColor]];
	NSAttributedString* iconValue = [self iconValueWithSize:22 color:[NSColor whiteColor]];
	NSAttributedString* iconLabel = [self iconLabelWithSize:12 color:[NSColor blackColor]];
	
	NSSize theIconSize	= [anImage size];
	float iconStart		= MAX([iconLabel size].width,[idLabel size].width) + 1;

	theIconSize.width += iconStart;
	
    NSImage* finalImage = [[NSImage alloc] initWithSize:theIconSize];
    [finalImage lockFocus];
    [anImage drawAtPoint:NSMakePoint(iconStart,0) fromRect:[anImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
	if(iconValue){		
		NSSize textSize = [iconValue size];
		float x = iconStart + 10;
		[iconValue drawInRect:NSMakeRect(x,3,textSize.width,textSize.height)];
	}
	
	if(iconLabel){		
		NSSize textSize = [iconLabel size];
		[iconLabel drawInRect:NSMakeRect(iconStart-textSize.width-1,3,textSize.width,textSize.height)];
	}
	
	if(idLabel){		
		NSSize textSize = [idLabel size];
		[idLabel drawInRect:NSMakeRect(iconStart-[idLabel size].width-1,theIconSize.height-textSize.height,textSize.width,textSize.height)];
	}
	
    [finalImage unlockFocus];
	return [finalImage autorelease];
}

- (NSImage*) composeHighLevelIconAsBar
{
	NSImage* anImage = [NSImage imageNamed:@"adcHorizontalBar"];
	NSAttributedString* idLabel   = [self idLabelWithSize:12 color:[NSColor blackColor]];
	NSAttributedString* iconLabel = [self iconLabelWithSize:12 color:[NSColor blackColor]];
	
	NSSize theIconSize	= [anImage size];
	float iconStart		= MAX([iconLabel size].width,[idLabel size].width) + 1;
	theIconSize.width += iconStart;
	
    NSImage* finalImage = [[NSImage alloc] initWithSize:theIconSize];
    [finalImage lockFocus];
    [anImage drawAtPoint:NSMakePoint(iconStart,0) fromRect:[anImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
	if(!normalGradient){
		CGFloat red   = 0.0;
		CGFloat green = 1.0;
		CGFloat blue  = 0.0;
		
		normalGradient = [[NSGradient alloc] 
						   initWithStartingColor:[NSColor colorWithCalibratedRed:red green:green blue:blue alpha:1]
						   endingColor:[NSColor colorWithCalibratedRed:.5*red green:.5*green blue:.5*blue alpha:1]];
	}
	
	if(!alarmGradient){
		CGFloat red   = 1.0;
		CGFloat green = 0.0;
		CGFloat blue  = 0.0;
		
		alarmGradient = [[NSGradient alloc]
						  initWithStartingColor:[NSColor colorWithCalibratedRed:red green:green blue:blue alpha:.3]
						  endingColor:[NSColor colorWithCalibratedRed:.5*red green:.5*green blue:.5*blue alpha:.3]];
	}
	
	float w = 231;
	float startx = iconStart+6;
	if(maxValue-minValue != 0){
		
		float slope = w/(maxValue-minValue);
		float intercept = w-slope*maxValue;
		float xValue = slope*hwValue + intercept;
		if(xValue<0)xValue=0;
		if(xValue>w)xValue=w;
		[normalGradient drawInRect:NSMakeRect(startx,4,xValue,24) angle:270];
		
		if(lowLimit>minValue){
			float lowAlarmx = slope*lowLimit + intercept;
			[alarmGradient drawInRect:NSMakeRect(startx,4,lowAlarmx,24) angle:270];
		}
		
		if(highLimit<maxValue){
			float hiAlarmx = slope*highLimit + intercept;
			[alarmGradient drawInRect:NSMakeRect(startx+hiAlarmx,4,w-hiAlarmx,24) angle:270];
		}
		
		[[NSColor redColor] set];
		float x1 = MIN(startx + xValue,startx+w-3);
		[NSBezierPath fillRect:NSMakeRect(x1,4,3,24)];
		
	}
	
	if([iconLabel length]){		
		NSSize textSize = [iconLabel size];
		[iconLabel drawInRect:NSMakeRect(iconStart-textSize.width-1,3,textSize.width,textSize.height)];
	}
	
	if([idLabel length]){		
		NSSize textSize = [idLabel size];
		[idLabel drawInRect:NSMakeRect(iconStart-textSize.width-1,theIconSize.height-textSize.height,textSize.width,textSize.height)];
	}
	
    [finalImage unlockFocus];
	return [finalImage autorelease];
}


@end

//the 'Low' nub
@implementation ORAdcLowLimitNub
- (id) eval
{
	[guardian eval];
	BOOL aValue = [(ORAdcModel*)guardian valueTooLow];
	return [ORProcessResult processState:aValue value:aValue];
}

- (int) evaluatedState
{
	return [(ORAdcModel*)guardian valueTooLow];
}

@end

//the 'High' nub
@implementation ORAdcHighLimitNub
- (id) eval
{
	[guardian eval];
	BOOL aValue = [(ORAdcModel*)guardian valueTooHigh];
	return [ORProcessResult processState:aValue value:aValue];

}
- (int) evaluatedState
{
	return [(ORAdcModel*)guardian valueTooHigh];
}

@end

