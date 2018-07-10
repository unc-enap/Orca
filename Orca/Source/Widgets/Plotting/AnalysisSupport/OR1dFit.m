//
//  OR1dFit.m
//  Orca
//
//  Created by Mark Howe on 2/13/10.
//  Copyright 2010 University of North Carolina. All rights reserved.
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

#import "OR1dFit.h"
#import "ORCARootServiceDefs.h"
#import "ORAxis.h"
#import "ORPlotAttributeStrings.h"

NSString* OR1dFitChanged		 = @"OR1dFitChanged";
NSString* OR1dFitTypeChanged	 = @"OR1dFitTypeChanged";
NSString* OR1dFitOrderChanged	 = @"OR1dFitOrderChanged";
NSString* OR1dFitStringChanged	 = @"OR1dFitStringChanged";
NSString* OR1dFitFunctionChanged = @"OR1dFitFunctionChanged";
	
@interface OR1dFit (private) 
- (void) doFitType:(int)aFitType;
- (void) doFitType:(int)aFitType fitOrder:(int)aFitOrder fitFunction:(NSString*)aFitFunction;
@end

@implementation OR1dFit

#pragma mark ***Initialization
- (id) init
{
	self = [super init];
	fitValid = NO;
	fitLableAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Geneva" size:10],NSFontAttributeName,nil] retain];
	RemoveORCARootWarnings; //a #define from ORCARootServiceDefs.h 
	return self;
}

- (void) dealloc
{
    [fitLableAttributes release];
	[fitString release];
	[fitFunction release];
	[fit release];
	[fitParams release];
	[fitParamNames release];
	[fitParamErrors release];
	[chiSquare release];
	
	[super dealloc];
}

#pragma mark ***Accessors
- (void) setDataSource:(id)ds
{
 	if( ![ds respondsToSelector:@selector(plotter:index:x:y:)]){
		ds = nil;
	}
	dataSource = ds; // Don't retain to avoid cycle retention problems
}

- (id) dataSource					{ return dataSource; }

- (long) minChannel					{ return minChannel; }
- (long) maxChannel					{ return maxChannel; }
- (BOOL) fitValid					{ return fitValid; }
- (int) fitType						{ return fitType; }
- (int) fitOrder					{ return fitOrder; }
- (void) setFitValid:(BOOL)aState	{ fitValid = aState; }
- (int) fitParamCount				{ return [fitParamNames count]; }
- (BOOL)	  fitExists				{ return (fit!=nil) && ([fit count] > 0); }
- (NSString*) fitString				{ return fitString; }
- (NSString*) fitFunction			{ return fitFunction; }
- (NSArray*)  fitParams				{ return fitParams; }
- (NSArray*)  fitParamNames			{ return fitParamNames; }
- (NSArray*)  fitParamErrors		{ return fitParamErrors; }
- (NSNumber*) chiSquare				{ return chiSquare; }
- (BOOL) serviceAvailable			{ return serviceAvailable;}


- (void) setMinChannel:(long)aChannel 
{ 
	minChannel = aChannel; 
	[[NSNotificationCenter defaultCenter] postNotificationName:OR1dFitChanged object:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORPlotViewRedrawEvent object:self];
}

- (void) setMaxChannel:(long)aChannel 
{ 
	maxChannel = aChannel; 
	[[NSNotificationCenter defaultCenter] postNotificationName:OR1dFitChanged object:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORPlotViewRedrawEvent object:self];
}


- (void) setFitType:(int)aValue 
{ 
	fitType = aValue; 
	[[NSNotificationCenter defaultCenter] postNotificationName:OR1dFitTypeChanged object:self];
}

- (void) setFitOrder:(int)aValue 
{ 
	if(aValue==0)aValue=1;
	fitOrder = aValue; 
	[[NSNotificationCenter defaultCenter] postNotificationName:OR1dFitOrderChanged object:self];
}

- (void) setFitString:(NSString*)aString
{
	[fitString autorelease];
	fitString = [aString copy];
	[[NSNotificationCenter defaultCenter] postNotificationName:OR1dFitStringChanged object:self];
}

- (void) setFitFunction:(NSString*)aString
{
	[fitFunction autorelease];
	fitFunction = [aString copy];
	[[NSNotificationCenter defaultCenter] postNotificationName:OR1dFitFunctionChanged object:self];
}

- (void) setFitParams:(NSArray*)anArray
{
	[anArray retain];
	[fitParams release];
	fitParams = anArray;
}

- (void) setFitParamNames:(NSArray*)anArray
{
	[anArray retain];
	[fitParamNames release];
	fitParamNames = anArray;
}

- (void) setFitParamErrors:(NSArray*)anArray
{
	[anArray retain];
	[fitParamErrors release];
	fitParamErrors = anArray;
}

- (void) setChiSquare:(NSNumber*)aValue
{
	[aValue retain];
	[chiSquare release];
	chiSquare = aValue;
}

- (void) setFit:(NSArray*)anArray
{
	
	[anArray retain];
	[fit release];
	fit = anArray;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:OR1dFitChanged object:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORPlotViewRedrawEvent object:self];
}


- (NSString*) fitParamName:(int) i
{
	if(i<[fitParamNames count]) return [fitParamNames objectAtIndex:i];
	else return @"";
}

- (float) fitParam:(int) i
{
	if(i<[fitParamNames count]) return [[fitParams objectAtIndex:i] floatValue];
	else return 0.0;
}

- (float) fitParamError:(int) i
{
	if(i<[fitParamNames count]) return [[fitParamErrors objectAtIndex:i] floatValue];
	else return 0.0;
}

- (void) drawFit:(id)aPlotView
{
	if([self fitExists]){
		ORAxis* mYScale = [aPlotView yScale];
		ORAxis* mXScale = [aPlotView xScale];
		
		NSBezierPath* theDataPath = [NSBezierPath bezierPath];
		[theDataPath setLineWidth:.5];
		int numPoints = [fit count];
		int minX		= MAX(0,MAX([self minChannel],[mXScale minValue]));
		int maxX		= MIN(numPoints,MIN(roundToLong([mXScale maxValue]),[self maxChannel]));
		float rawValue  = 0;
		if(minX<[fit count]) rawValue	= [[fit objectAtIndex:minX] floatValue];
		float y			= [mYScale getPixAbs:rawValue];
		float x			= [mXScale getPixAbs:minX];
		
		[theDataPath moveToPoint:NSMakePoint(x,y)];			
		long    ix;
		for (ix=minX; ix<maxX;++ix) {
			if(ix >= [fit count]-1)break;
			rawValue = [[fit objectAtIndex:ix] floatValue];
			y = [mYScale getPixAbs:rawValue];
			x = [mXScale getPixAbs:ix];
			[theDataPath lineToPoint:NSMakePoint(x,y)];
		}
		[[NSColor blackColor] set];
		[theDataPath setLineWidth:1];
		[theDataPath stroke];
		
		int fitLabelHeight = [fitString sizeWithAttributes:fitLableAttributes].height;
		float height = [aPlotView bounds].size.height;
		[fitString drawAtPoint:NSMakePoint(20,height-10-fitLabelHeight) withAttributes:fitLableAttributes];
	}
}


#pragma mark ***Fit Handling
- (void) doGaussianFit							{ [self doFitType:0 fitOrder:0 fitFunction:@""]; }
- (void) doExponentialFit						{ [self doFitType:1 fitOrder:0 fitFunction:@""]; }
- (void) doPolynomialFit:(int)aFitOrder			{ [self doFitType:2 fitOrder:aFitOrder fitFunction:@""]; }
- (void) doLandauFit							{ [self doFitType:3 fitOrder:0 fitFunction:@""]; }
- (void) doArbitraryFit:(NSString*)aFitFunction	{ [self doFitType:4 fitOrder:0 fitFunction:aFitFunction];}

- (void) doFit
{
	if(![dataSource respondsToSelector:@selector(plotView)])return;
	id aPlotView = [dataSource plotView];
	if(![aPlotView respondsToSelector:@selector(topPlot)])return;
	id aPlot = [aPlotView topPlot];
	id roi = [aPlot roi];
	
	[self setMinChannel:[roi minChannel]];
	[self setMaxChannel:[roi maxChannel]];
	
	BOOL roiVisible = [dataSource plotterShouldShowRoi:aPlot];
	if(roiVisible){
		//get the data for the fit
		NSMutableArray* dataArray = [NSMutableArray array];
		int numPoints = [dataSource numberPointsInPlot:aPlot];
		long maxChan = MIN([self maxChannel],numPoints-1);
		long minChan = MAX([self minChannel],0);
		if((maxChan - minChan) > 1024){
			maxChan = minChan + 1024;
		}
		int ix;
		for (ix=minChan; ix<maxChan;++ix) {		
			double xValue,yValue;
			[dataSource plotter:aPlot index:ix x:&xValue y:&yValue];
			[dataArray addObject:[NSNumber numberWithDouble:yValue]];
		}
		
		[fitParams release];	
		[fitParamNames release];
		[fitParamErrors release];
		[chiSquare release];
		
		fitParams		= nil;	
		fitParamNames	= nil;
		fitParamErrors	= nil;
		chiSquare		= nil;
		fitValid		= NO;
			
		if([dataArray count]){
			NSMutableDictionary* serviceRequest = [NSMutableDictionary dictionary];
			[serviceRequest setObject:@"OROrcaRequestFitProcessor" forKey:@"Request Type"];
			[serviceRequest setObject:@"Normal"					 forKey:@"Request Option"];
			
			NSMutableDictionary* requestInputs = [NSMutableDictionary dictionary];

			[requestInputs setObject:[NSNumber numberWithInt:minChannel] forKey:@"FitLowerBound"];
			[requestInputs setObject:[NSNumber numberWithInt:maxChannel] forKey:@"FitUpperBound"];	
			
			NSString* 	theFitFunction = [[kORCARootFitShortNames[fitType] copy] autorelease];
			NSMutableArray* fitParameters = [NSMutableArray array];
			if([theFitFunction hasPrefix:@"arb"]){
				NSArray* arbInput = [fitFunction componentsSeparatedByString:@";"];
				theFitFunction = [arbInput objectAtIndex:0];
				NSLog(@"Sending fit function: %@\n", theFitFunction);
				if([arbInput count] > 1) {
					fitParameters = [[[[[arbInput objectAtIndex:1] trimSpacesFromEnds] componentsSeparatedByString:@","] mutableCopy] autorelease];
					NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
					[formatter setNumberStyle:NSNumberFormatterDecimalStyle];
					int i;
					for(i=0; i<[fitParameters count]; i++) {
						[fitParameters replaceObjectAtIndex:i withObject:[formatter numberFromString:[[fitParameters objectAtIndex:i] trimSpacesFromEnds]]];
					}
					[formatter release];
					NSLog(@"Initial fit parameters:\n");
					i = 0;
					for(id aParam in fitParameters)NSLog(@"[%d] : %@\n", i++,aParam);					
				}
			}
			else if([theFitFunction hasPrefix:@"pol"]){
				theFitFunction = [theFitFunction stringByAppendingFormat:@"%d",fitOrder];
			}

			[requestInputs setObject:theFitFunction		forKey:@"FitFunction"];
			[requestInputs setObject:fitParameters		forKey:@"FitParameters"];
			[requestInputs setObject:@""				forKey:@"FitOptions"];
			[requestInputs setObject:dataArray			forKey:@"FitYValues"];
			
			[serviceRequest setObject:requestInputs	forKey:@"Request Inputs"];
			
			//we do this via a notification so that this object (which is a widget) is decoupled from the ORCARootService object.
			NSDictionary* userInfo = [NSDictionary dictionaryWithObject:serviceRequest forKey:ServiceRequestKey];
			[[NSNotificationCenter defaultCenter] postNotificationName:ORCARootServiceRequestNotification object:self userInfo:userInfo];
		}
	}
}


- (void) processResponse:(NSDictionary*)aResponse
{
	if(![dataSource respondsToSelector:@selector(plotView)])return;
	id aPlotView = [dataSource plotView];
	BOOL responseOK = ([aResponse objectForKey:@"Request Error"] == nil);
	if(responseOK){
		if([[aResponse objectForKey:@"Request Type"] isEqualToString: @"OROrcaRequestFitProcessor"]){
			fitParams		= [[aResponse nestedObjectForKey:@"Request Outputs",@"FitOutputParameters",nil] retain];
			fitParamNames	= [[aResponse nestedObjectForKey:@"Request Outputs",@"FitOutputParametersNames",nil] retain];
			fitParamErrors  = [[aResponse nestedObjectForKey:@"Request Outputs",@"FitOutputErrorParameters",nil] retain];
			chiSquare		= [[aResponse nestedObjectForKey:@"Request Outputs",@"FitChiSquare",nil] retain];
			
			int  theMinChannel = [[aResponse nestedObjectForKey:@"Request Outputs",@"FitLowerBound",nil] intValue];
			int  theMaxChannel = [[aResponse nestedObjectForKey:@"Request Outputs",@"FitUpperBound",nil] intValue];
			fitValid = YES;
			
			NSLog(@"----------------------------------------\n");
			NSLog(@"Fit done on %@\n",[[aPlotView window] title]);
			NSLog(@"Channels %d to %d\n",theMinChannel,theMaxChannel);
			NSLog(@"Fit Equation: %@\n",[aResponse nestedObjectForKey:@"Request Outputs",@"FitEquation",nil]);
			int n = [fitParams count];
			int i;
			NSString* s = @""; 
			s = [s stringByAppendingFormat:@"Fit Equation: %@\n",[aResponse nestedObjectForKey:@"Request Outputs",@"FitEquation",nil]];
			for(i=0;i<n;i++){
				NSLog(@"%@ = %.5G +/- %.5G\n",[fitParamNames objectAtIndex:i], [[fitParams objectAtIndex:i] floatValue],[[fitParamErrors objectAtIndex:i] floatValue]);
				s = [s stringByAppendingFormat:@"%@ = %.5G +/- %.5G\n",[fitParamNames objectAtIndex:i], [[fitParams objectAtIndex:i] floatValue],[[fitParamErrors objectAtIndex:i] floatValue]];
			}
			NSLog(@"Chi Square = %@\n",chiSquare);
			s = [s stringByAppendingFormat:@"Chi Square = %.5G\n",[chiSquare floatValue]];
			[self setFitString:s];
			
			
			NSArray* theFit			    = [aResponse nestedObjectForKey:@"Request Outputs",@"FitOutputYValues",nil];
			NSMutableArray* theFinalFit = [NSMutableArray array];
			for( i=0;i<theMinChannel;i++){
				[theFinalFit addObject:[NSNumber numberWithInt:0]];
			}
			for(id aValue in theFit){
				[theFinalFit addObject:aValue];
			}
			
			[self setFit:theFinalFit];
			NSLog(@"----------------------------------------\n");

		}
	}
	else {
		[self setFit: nil];
		NSLog(@"----------------------------------------\n");
		NSLog(@"Error returned for Fit on %@\n",[[aPlotView window] title]);
		NSLog(@"Error message: %@\n",[aResponse objectForKey:@"Request Error"]);
		NSLog(@"----------------------------------------\n");
	}
}

- (void) removeFit
{
	[self setFitString:@""];
	[self setFit:nil];
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    
	[self setFitValid:[decoder decodeBoolForKey:@"fitValid"]];
		
    [self setMinChannel:	[decoder decodeInt32ForKey:@"minChannel"]];
    [self setMaxChannel:	[decoder decodeInt32ForKey:@"maxChannel"]];
	[self setFitParams:		[decoder decodeObjectForKey:@"fitParams"]];
	[self setFitParamNames:	[decoder decodeObjectForKey:@"fitParamNames"]];
	[self setFitParamErrors:[decoder decodeObjectForKey:@"fitParamErrors"]];
	[self setChiSquare:		[decoder decodeObjectForKey:@"chiSquare"]];
	[self setFit:			[decoder decodeObjectForKey:@"fit"]];
	
	[self setFitString:		[decoder decodeObjectForKey:@"fitString"]];
	[self setFitFunction:	[decoder decodeObjectForKey:@"fitFuction"]];
	[self setFitOrder:		[decoder decodeIntForKey:@"fitOrder"]];
	
	fitLableAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Geneva" size:10],NSFontAttributeName,nil] retain];

    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeInt32:minChannel forKey:@"minChannel"];
    [encoder encodeInt32:maxChannel forKey:@"maxChannel"];
	
	[encoder encodeBool:fitValid forKey:@"fitValid"];
	
	[encoder encodeObject:fitParams forKey:@"fitParams"];
	[encoder encodeObject:fitParamNames forKey:@"fitParamNames"];
	[encoder encodeObject:fitParamErrors forKey:@"fitParamErrors"];
	[encoder encodeObject:chiSquare forKey:@"chiSquare"];
	
    [encoder encodeObject:fit forKey:@"fit"];
    [encoder encodeInt:fitOrder forKey:@"fitOrder"];
	[encoder encodeObject:fitString forKey:@"fitString"];
	[encoder encodeObject:fitFunction forKey:@"fitFuncton"];
}

@end

@implementation OR1dFit (private)

- (void) doFitType:(int)aFitType
{	
	int aFitOrder;
	if(aFitType == 2) aFitOrder = 1;
	else			  aFitOrder = 0;
	
	[self doFitType:aFitType fitOrder:aFitOrder fitFunction:@""];
}

- (void) doFitType:(int)aFitType fitOrder:(int)aFitOrder fitFunction:(NSString*)aFitFunction
{	
	[self setFitType:aFitType];
	[self setFitOrder:aFitOrder];
	[self setFitFunction:aFitFunction];	
	[self doFit];
}

@end
