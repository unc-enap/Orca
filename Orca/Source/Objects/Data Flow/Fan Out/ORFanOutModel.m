//
//  ORFanOutModel.m
//  Orca
//
//  Created by Mark Howe on Wed Jan 1 2003.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORFanOutModel.h"
#import "ORDataPacket.h"
#import "ORDecoder.h"

#pragma mark ¥¥¥String Definitions
NSString* ORFanOutChangedNotification 	 = @"Fan In Number Changed";
static NSString *ORFanOutInputConnection = @"Fan In Input Connector";
static NSString *kFanOutConnectorKey[10]  = {
    @"Fan In Output Connector 1",
    @"Fan In Output Connector 2",
    @"Fan In Output Connector 3",
    @"Fan In Output Connector 4",
    @"Fan In Output Connector 5",
    @"Fan In Output Connector 6",
    @"Fan In Output Connector 7",
    @"Fan In Output Connector 8",
    @"Fan In Output Connector 9",
    @"Fan In Output Connector 10",
};

#define kFanOutWidth 40

@implementation ORFanOutModel

#pragma mark ¥¥¥Initialization

- (id) init //designated initializer
{
	self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    
    [self loadDefaults];
    [self registerNotificationObservers];
    
    [self setNumberOfOutputs:2];
    
    [[self undoManager] enableUndoRegistration];
    
    
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[lineColor release];
    [super dealloc];
}

- (void) setUpImage
{
    //[self setNumberOfOutputs:2];//this was the original version; maybe we can restore it, now when I added a empty '- (void) flagsChanged:(NSEvent *)theEvent'? -tb-
    if(numberOfOutputs==0)
        [self setNumberOfOutputs:2];
    else
        [self setNumberOfOutputs: numberOfOutputs];    
}


- (void) makeConnectors
{
    //first the input connector
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint([self x],[self y]+[self frame].size.height/2 - kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORFanOutInputConnection];
	[aConnector setIoType:kInputConnector];
    [aConnector release];
    //then the input connectors
    int i;
    short n = [self numberOfOutputs];
    if(n==0)n=2;
    short y_offset = 0;
    for(i=0;i<n;i++){
        aConnector = [[ORConnector alloc] initAt:NSMakePoint([self x]+[self frame].size.width-kConnectorSize,[self y]+y_offset) withGuardian:self withObjectLink:self];
        [[self connectors] setObject:aConnector forKey:kFanOutConnectorKey[i]];
		[aConnector setIoType:kOutputConnector];
        [aConnector release];
        y_offset += 2*kConnectorSize;
    }
}

- (void) loadDefaults
{
    NSColor* color = colorForData([[NSUserDefaults standardUserDefaults] objectForKey: ORLineColor]);
    [self setLineColor:(color!=nil?color:[NSColor blackColor])];
    [self setLineType:[[[NSUserDefaults standardUserDefaults] objectForKey: ORLineType] intValue]];
}

- (void) drawSelf:(NSRect)aRect withTransparency:(float)aTransparency{
    
	
	// Create the shadow below and to the right of the shape.
	NSShadow* theShadow = nil;
	if([self guardian]){
		[NSGraphicsContext saveGraphicsState]; 
		theShadow = [[NSShadow alloc] init]; 
		[theShadow setShadowOffset:NSMakeSize(3.0, -3.0)]; 
		[theShadow setShadowBlurRadius:3.0]; 
		
		// Use a partially transparent color for shapes that overlap.
		[theShadow setShadowColor:[[NSColor blackColor]
				 colorWithAlphaComponent:0.3]]; 
		
		[theShadow set];
	}
    short n = [self numberOfOutputs];
    if(n==0)n=2;
    NSSize theRect = NSMakeSize(kFanOutWidth,n*2*kConnectorSize - kConnectorSize);
    NSBezierPath* path = [NSBezierPath bezierPath];
	[path setLineWidth:.5];
    NSPoint inPoint = NSMakePoint( [self frame].origin.x + kConnectorSize, [self frame].origin.y + theRect.height/2);
    
    short i,x;
    short y_offset = kConnectorSize/2;
    for(i=0;i<n;i++){
        
        NSPoint outPoint = NSMakePoint( [self frame].origin.x + theRect.width - kConnectorSize, [self frame].origin.y + y_offset);
        
        [path moveToPoint:inPoint];
        NSPoint halfWayPoint1;
        NSPoint halfWayPoint2;
        switch ([self lineType]){
            case straightLines:
                [path lineToPoint:outPoint];
				break;
                
            case squareLines:
                x = inPoint.x + fabs(outPoint.x - inPoint.x)/2;
                halfWayPoint1 = NSMakePoint(x,inPoint.y);
                halfWayPoint2 = NSMakePoint(x,outPoint.y);
                [path lineToPoint:halfWayPoint1];
                [path lineToPoint:halfWayPoint2];
                [path lineToPoint:outPoint];
				break;
                
            case curvedLines:
                x = inPoint.x + fabs(outPoint.x - inPoint.x)/2;
                halfWayPoint1 = NSMakePoint(x,inPoint.y);
                halfWayPoint2 = NSMakePoint(x,outPoint.y);
                [path curveToPoint:outPoint controlPoint1:halfWayPoint1 controlPoint2:halfWayPoint2];
				break;
        }
        y_offset += 2*kConnectorSize;
    }
	[colorForData([[NSUserDefaults standardUserDefaults] objectForKey: ORLineColor]) set];
    [path stroke];
    
    [self drawConnections:aRect withTransparency:aTransparency];
	if([self guardian]){
		[NSGraphicsContext restoreGraphicsState];
	}
	[theShadow release]; 
}

- (void) makeMainController
{
    [self linkToController:@"ORFanOutController"];
}

- (NSString*) helpURL
{
	return @"Data_Chain/Fan_In_Out.html";
}


- (void) flagsChanged:(NSEvent *)theEvent
{
    //overriden to prevent a side effect of drawing the image when we don't have to.
}



#pragma mark ¥¥¥Accessors
- (short) numberOfOutputs
{
    return numberOfOutputs;
}

- (void) setNumberOfOutputs:(short)newValue
{
    
    numberOfOutputs = newValue;
    
    NSSize theNewSize = NSMakeSize(kFanOutWidth,numberOfOutputs*2*kConnectorSize - kConnectorSize);
    [self setFrame:NSMakeRect([self frame].origin.x,[self frame].origin.y,theNewSize.width,theNewSize.height)];
    
    
    
    [[NSNotificationCenter defaultCenter]
            postNotificationName:ORFanOutChangedNotification
                          object:self];
    
    //force an update
    [[NSNotificationCenter defaultCenter]
            postNotificationName:ORLineColorChangedNotification
                          object:self];
    
}

- (void) adjustNumberOfOutputs:(short)newValue
{
    if([self okToAdjustNumberOfOutputs:newValue]){
		
		[[[self undoManager] prepareWithInvocationTarget:self] adjustNumberOfOutputs:[self numberOfOutputs]];
        
        NSSize theNewSize = NSMakeSize(kFanOutWidth,newValue*2*kConnectorSize - kConnectorSize);
        [self setFrame:NSMakeRect([self frame].origin.x,[self frame].origin.y,theNewSize.width,theNewSize.height)];
        
        //first move the Input
        ORConnector* aConnector = [[self connectors] objectForKey:ORFanOutInputConnection];
        [aConnector setLocalFrame:NSMakeRect(0,[self frame].size.height/2 - kConnectorSize/2,kConnectorSize,kConnectorSize)];
        
        if(newValue>[self numberOfOutputs]){
            
			//easy, just add new connector
            short i;
            short y_offset = 2 * [self numberOfOutputs] * kConnectorSize;
            for(i=[self numberOfOutputs];i<newValue;i++){
                aConnector = [[ORConnector alloc] initAt:NSMakePoint(0,0) withGuardian:self withObjectLink:self];
                [aConnector setLocalFrame:NSMakeRect([self frame].size.width-kConnectorSize,y_offset,kConnectorSize,kConnectorSize) ];
                [[self connectors] setObject:aConnector forKey:kFanOutConnectorKey[i]];
				[self setNumberOfOutputs:[[self connectors] count]];
                [aConnector release];
                y_offset += 2*kConnectorSize;
            }
            
        }
        else if(newValue < [self numberOfOutputs]){
			short i,j;
			BOOL movedOne;
			do {
				movedOne = NO;
				for(i=0;i<[[self connectors] count];i++){
					ORConnector* aConnector1 = [[self connectors] objectForKey:kFanOutConnectorKey[i]];
					if(![aConnector1 connector]){
						short emptyIndex = i;
						for(j=emptyIndex+1;j<[[self connectors] count];j++){
							ORConnector* aConnector2 = [[self connectors] objectForKey:kFanOutConnectorKey[j]];
							ORConnector* connection = [aConnector2 connector];
							if( connection){
								[aConnector2 disconnect];
								[aConnector1 connectTo:connection];
								movedOne = YES;
								break;
							}
						}
						if(movedOne == YES)break;
					}
				}
                
			}while(movedOne == YES);
            
			short n = [self numberOfOutputs]-1;
			for(i=n;i>=newValue;i--){
				ORConnector* aConnectorToRemove = [[self connectors] objectForKey:kFanOutConnectorKey[i]];
				if(![aConnectorToRemove connector]){
					[[self connectors] removeObjectForKey:kFanOutConnectorKey[i]];
				}
			}
			
		}
		
        
        [self setNumberOfOutputs:newValue];
        
    }
}

- (BOOL) okToAdjustNumberOfOutputs:(short)newValue
{
	if(newValue<[self numberOfOutputs]){
        NSEnumerator *enumerator = [[self connectors] keyEnumerator];
        id key;
        int count = 0;
        while ((key = [enumerator nextObject])) {
            if(key != ORFanOutInputConnection){
                ORConnector* aConnector = [[self connectors] objectForKey:key];
                if([aConnector connector])count++;
            }
        }
        if(count==[self numberOfOutputs]+1 ){
            ORRunAlertPanel(@"All Connectors Connected!",@"You must disconnect something.",nil,nil,nil);
            return NO;
        }
    }
    return YES;
}

- (NSColor*) lineColor
{
    return lineColor;
}

- (void) setLineColor:(NSColor*)aColor
{
    [aColor retain];
    [lineColor release];
    lineColor = aColor;
}

- (int) lineType;
{
    return lineType;
}

- (void) setLineType:(int)aType
{
    lineType = aType;
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
	[notifyCenter removeObserver:self];
    
    [notifyCenter addObserver : self
                     selector : @selector(lineColorChanged:)
                         name : ORLineColorChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(lineTypeChanged:)
                         name : ORLineTypeChangedNotification
                       object : nil];
    
}

- (void) lineColorChanged:(NSNotification*)aNotification
{
	NSUserDefaults*  defaults 	 = [NSUserDefaults standardUserDefaults];
	NSData*			 colorAsData = [defaults objectForKey: ORLineColor];
	[self setLineColor:[NSUnarchiver unarchiveObjectWithData:colorAsData]];
}

- (void) lineTypeChanged:(NSNotification*)aNotification
{
	NSUserDefaults* defaults 	= [NSUserDefaults standardUserDefaults];
	[self setLineType:[[defaults objectForKey: ORLineType] intValue]];
    
}

#pragma mark ¥¥¥Archival
static NSString *ORFanOutNumber 		= @"Number of Fan In Outputs";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self loadDefaults];
    [self setNumberOfOutputs:[decoder decodeIntForKey:ORFanOutNumber]];
    [self registerNotificationObservers];
    
    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:[self numberOfOutputs] forKey:ORFanOutNumber];
    
}


- (NSMethodSignature*)methodSignatureForSelector:(SEL)aSelector
{
	
	if( [[self class] instancesRespondToSelector:aSelector] ) {
		//Get the instance method signature from the Context's class.
		return [[self class] instanceMethodSignatureForSelector:aSelector];
	}
	else {
		NSMethodSignature* methodSignature = nil;
		//Get the instance method signature from the Strategy.
		short i;
		int n = [self numberOfOutputs];
		for(i=0;i<n;i++){
            id obj = [self objectConnectedTo:kFanOutConnectorKey[i]];
			if(obj){
				methodSignature = [obj methodSignatureForSelector:aSelector];
				if(methodSignature)return methodSignature;
			}
		}
		if(!methodSignature){
			//there was no method found... we will dump the message. One way this happens is if there is nothing connected to the fanout.
			return [[self class] instanceMethodSignatureForSelector:@selector(messageDump)];
		}
	}
	return nil;
}

- (void) messageDump
{
}

- (void) forwardInvocation:(NSInvocation *)invocation
{
	short i;
	for(i=0;i<[self numberOfOutputs];i++){
        id obj = [self objectConnectedTo:kFanOutConnectorKey[i]];
		if(obj)[invocation invokeWithTarget:obj];
		
	}
}

//----------------------------------------------------------------------------------------------------
//methodSignatureForSelector and forwardInvocation are quite slow, so here we cach the objects that will
//be getting hit the hardest with data processing. Let the slow methods handle everything except the next 
//three messages.
//
- (void) runTaskStarted:(NSDictionary*)userInfo
{
	[cachedProcessors release];
	cachedProcessors = [[NSMutableArray array] retain];
	int i;
	for(i=0;i<[self numberOfOutputs];i++){
        id obj = [self objectConnectedTo:kFanOutConnectorKey[i]];
		if(obj && [obj respondsToSelector:@selector(processData:decoder:)]){
			[cachedProcessors addObject:obj];
		}
		[obj runTaskStarted:userInfo];
	}
	cachedProcessorsCount = [cachedProcessors count];
}


- (void) processData:(NSArray*)dataArray decoder:(ORDecoder*)aDecoder
{
    for(id obj in cachedProcessors){
        [obj processData:dataArray decoder:aDecoder];
    }
}

- (void) runTaskStopped:(NSDictionary*)userInfo
{
	for(id obj in cachedProcessors){
        [obj runTaskStopped:userInfo];
    }
}
- (void) preCloseOut:(NSDictionary*)userInfo
{
    for(id obj in cachedProcessors){
        [obj preCloseOut:userInfo];
    }
}
- (void) closeOutRun:(NSDictionary*)userInfo
{
	for(id obj in cachedProcessors){
        [obj closeOutRun:userInfo];
    }
}



@end
