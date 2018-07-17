//
//  ORContainerFeedThru.m
//  Orca
//
//  Created by Mark Howe on Wed Oct 12, 2005.
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
#import "ORContainerFeedThru.h"
#import "ORDataPacket.h"
#import "ORContainerModel.h"
#import "ORMessagePipe.h"

#pragma mark ¥¥¥String Definitions
NSString* ORContainerFeedThruChangedNotification 	 = @"ORContainerFeedThruChangedNotification";
@implementation ORContainerFeedThru

#pragma mark ¥¥¥Initialization
- (void) dealloc
{
    [messagePipes release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[remoteConnectors release];
	[lineColor release];
    [super dealloc];
}

- (void) setUpImage
{
    [[self undoManager] disableUndoRegistration];
	if(numberOfFeedThrus == 0){
		[self setNumberOfFeedThrus:1];
		[self adjustFeedThruPositions];
	}
    [[self undoManager] enableUndoRegistration];
}

- (void) awakeAfterDocumentLoaded
{
	[self adjustRemoteFeedThruPositions];
	int i;
	for(i=0;i<[self numberOfFeedThrus];i++){
		NSString* aKey = [self connectorKey:i];	
		[self setUpMessagePipeLocal:[connectors objectForKey:aKey] remote:[remoteConnectors objectForKey:aKey] pipe:[messagePipes objectAtIndex:i]];
	}
}

- (NSString*) helpURL
{
	return @"Subsystems/Containers_and_Dynamic_Labels.html";
}

- (NSMutableDictionary*) remoteConnectors
{
	return remoteConnectors;
}

- (void) setRemoteConnectors:(NSMutableDictionary*)aDict
{
	[aDict retain];
	[remoteConnectors release];
	remoteConnectors = aDict;
}

- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian
{
    if( [aGuardian isKindOfClass:NSClassFromString(@"ORContainerModel")]){
		NSArray* othersLikeMe = [aGuardian collectObjectsOfClass:[self class]];
		if([othersLikeMe count]) {
			if([[othersLikeMe objectAtIndex:0] uniqueIdNumber] == [self uniqueIdNumber]) return YES;
			else return NO;
		}
		else return YES;
	}
	else return NO;
}

- (void) setGuardian:(id)aGuardian
{
    id oldGuardian = guardian;
    [super setGuardian:aGuardian];
    
    if(oldGuardian != aGuardian){
		NSEnumerator* e = [remoteConnectors objectEnumerator];
		id aConnector;
		while(aConnector = [e nextObject]){
			[oldGuardian removeDisplayOf:aConnector];
		}
    }
    
	float y_offset = 2 * [self numberOfFeedThrus] * kConnectorSize;
	NSEnumerator* e = [remoteConnectors keyEnumerator];
	NSString* aConnectorKey;
	while(aConnectorKey = [e nextObject]){
		ORConnector* aConnector = [remoteConnectors objectForKey:aConnectorKey];
		[aConnector setLocalFrame:NSMakeRect([self remoteConnectorXPlane],y_offset,kConnectorSize,kConnectorSize) ];
		[aGuardian assumeDisplayOf:aConnector withKey:aConnectorKey];
		y_offset += 2*kConnectorSize;
	}


}

- (void) loadDefaults
{
    NSColor* color = colorForData([[NSUserDefaults standardUserDefaults] objectForKey: ORLineColor]);
    [self setLineColor:(color!=nil?color:[NSColor blackColor])];
    [self setLineType:[[[NSUserDefaults standardUserDefaults] objectForKey: ORLineType] intValue]];
}

- (void) makeMainController
{
    [self linkToController:@"ORContainerInputController"];
}

#pragma mark ¥¥¥Accessors

- (NSArray*) messagePipes
{
    return messagePipes;
}

- (void) setMessagePipes:(NSArray*)aMessagePipes
{
    [aMessagePipes retain];
    [messagePipes release];
    messagePipes = aMessagePipes;
}
- (short) numberOfFeedThrus
{
    return numberOfFeedThrus;
}

- (float) connectorXPlane
{
	return 0;
}

- (float) remoteConnectorXPlane
{
	return [guardian frame].size.width - kConnectorSize;
}

- (void) setNumberOfFeedThrus:(short)newValue
{
	[[[self undoManager] prepareWithInvocationTarget:self] setNumberOfFeedThrus:numberOfFeedThrus];
    [[self undoManager] disableUndoRegistration];

	if(newValue<1)     newValue = 1;
	else if(newValue>4)newValue = 4;
	if([self okToAdjustNumberOfFeedThrus:newValue]){

		
		[self adjustNumberOfFeedThrus:newValue];
		
		numberOfFeedThrus = newValue;
		
		NSSize theNewSize = NSMakeSize(frame.size.width,MAX([[self image] size].height,newValue*2*kConnectorSize - kConnectorSize));
		[self setFrame:NSMakeRect([self frame].origin.x,[self frame].origin.y,theNewSize.width,theNewSize.height)];
		

		[self adjustFeedThruPositions];
		[self adjustRemoteFeedThruPositions];


		[[NSNotificationCenter defaultCenter]
				postNotificationName:ORContainerFeedThruChangedNotification
							  object:self];
		
		//force an update
		[[NSNotificationCenter defaultCenter]
				postNotificationName:ORLineColorChangedNotification
							  object:self];
    
	}
    [[self undoManager] enableUndoRegistration];
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

#pragma mark ¥¥¥SubClass responsibility
- (NSString*) connectorKey:(int)i
{
	//subclasses should override
	return @"";
}

- (void) setUpMessagePipeLocal:(ORConnector*)localConnector remote:(ORConnector*)remoteConnector pipe:(ORMessagePipe*)aPipe
{
	//subclasses have to  override
}

#pragma mark ¥¥¥Drawing
- (void) drawSelf:(NSRect)aRect withTransparency:(float)aTransparency
{
    if(NSIntersectsRect(aRect,[self frame])){        
		short n = [self numberOfFeedThrus];
		if(n==0)n=1;
		NSBezierPath* path = [NSBezierPath bezierPath];
		[path setLineWidth:.5];
		
		NSPoint startPoint = NSMakePoint( frame.origin.x + frame.size.width/2., frame.origin.y + frame.size.height/2. );
		
		short x;
		int i;
		for(i=0;i<n;i++){
			ORConnector* aConnector = [connectors objectForKey:[self connectorKey:i]];
			
			NSPoint endPoint = NSMakePoint( frame.origin.x + [self connectorXPlane] + kConnectorSize/2., 
											[self frame].origin.y + [aConnector localFrame].origin.y + kConnectorSize/2. );
			
			[path moveToPoint:endPoint];
			NSPoint halfWayPoint1;
			NSPoint halfWayPoint2;
			switch ([self lineType]){
				case straightLines:
					[path lineToPoint:startPoint];
					break;
					
				case squareLines:
					x = endPoint.x + (startPoint.x - endPoint.x)/2.;
					halfWayPoint1 = NSMakePoint(x,endPoint.y);
					halfWayPoint2 = NSMakePoint(x,startPoint.y);
					[path lineToPoint:halfWayPoint1];
					[path lineToPoint:halfWayPoint2];
					[path lineToPoint:startPoint];
					break;
					
				case curvedLines:
					x = endPoint.x + (startPoint.x - endPoint.x)/2.;
					halfWayPoint1 = NSMakePoint(x,endPoint.y);
					halfWayPoint2 = NSMakePoint(x,startPoint.y);
					[path curveToPoint:startPoint controlPoint1:halfWayPoint1 controlPoint2:halfWayPoint2];
					break;
			}
		}
		[colorForData([[NSUserDefaults standardUserDefaults] objectForKey: ORLineColor]) set];            
		[path stroke];

       if(!image){
            [self setUpImage];
        }
        if(image){
			NSImage* imageToDraw;
			if([self highlighted])imageToDraw = highlightedImage;
			else imageToDraw = image;

			NSRect sourceRect = NSMakeRect(0,0,[imageToDraw size].width,[imageToDraw size].height);

			//center the image vertically
			NSPoint aPoint = frame.origin;
			aPoint.y = frame.origin.y + frame.size.height/2. - [imageToDraw size].height/2.;

			[imageToDraw drawAtPoint:aPoint fromRect:sourceRect operation:NSCompositingOperationSourceOver fraction:aTransparency];
            
        }
	}
    
    [self drawConnections:aRect withTransparency:aTransparency];
}

- (void) adjustNumberOfFeedThrus:(short)newValue
{
    if([self okToAdjustNumberOfFeedThrus:newValue]){
		        
        NSSize theNewSize = NSMakeSize(frame.size.width,newValue*2*kConnectorSize - kConnectorSize);
        [self setFrame:NSMakeRect([self frame].origin.x,[self frame].origin.y,theNewSize.width,theNewSize.height)];
                
        if(newValue>[self numberOfFeedThrus]){
			//they want more....easy, just add a new connector
            short i;
            short y_offset = 2 * [self numberOfFeedThrus] * kConnectorSize;
            for(i=[self numberOfFeedThrus];i<newValue;i++){
			
				NSString* theNewConnectorKey = [self connectorKey:i];
				//make and add our local connector
                ORConnector* localConnector = [[ORConnector alloc] initAt:NSMakePoint(0,0) withGuardian:self withObjectLink:self];
                [localConnector setLocalFrame:NSMakeRect([self connectorXPlane],y_offset,kConnectorSize,kConnectorSize) ];
                [connectors setObject:localConnector forKey:theNewConnectorKey];
				
				
				//make and add to corresponding remote connector
				if(!remoteConnectors)[self setRemoteConnectors:[NSMutableDictionary dictionary]];
		
				ORConnector* remoteConnector = [[ORConnector alloc] initAt:NSMakePoint(0,0) withGuardian:self withObjectLink:self];
				[remoteConnector setIoType:[localConnector ioType]];
				[remoteConnectors setObject:remoteConnector forKey:theNewConnectorKey];
				
				if(guardian){
					[remoteConnector setLocalFrame:NSMakeRect([self remoteConnectorXPlane],y_offset,kConnectorSize,kConnectorSize) ];
					[guardian assumeDisplayOf:remoteConnector withKey:theNewConnectorKey];
				}
			
				[self setUpMessagePipeLocal:localConnector remote:remoteConnector pipe:[messagePipes objectAtIndex:i]];
				
                [localConnector release];
				[remoteConnector release];
			
				y_offset += 2*kConnectorSize;
            }
            
        }
        else if(newValue < [self numberOfFeedThrus]){
			//OK, they want fewer... harder, we can't remove a connected that is connected to anything
			//so we have to scan thru the list and remove a free one if it exists
			short i,j;
			BOOL movedOne;
			do {
				movedOne = NO;
				for(i=0;i<[connectors count];i++){
					ORConnector* aConnector1		= [connectors objectForKey:[self connectorKey:i]];
					ORConnector* aRemoteConnector1	= [remoteConnectors objectForKey:[self connectorKey:i]];
					
					if(![aConnector1 connector] && ![aRemoteConnector1 connector]){
						short emptyIndex = i;
						for(j=emptyIndex+1;j<[connectors count];j++){
							ORConnector* aConnector2		= [connectors objectForKey:[self connectorKey:j]];
							ORConnector* aRemoteConnector2	= [remoteConnectors objectForKey:[self connectorKey:j]];
							ORConnector* connection			= [aConnector2 connector];
							ORConnector* remoteConnection	= [aRemoteConnector2 connector];
							if( connection && remoteConnection){
								[aConnector2 disconnect];
								[aConnector1 connectTo:connection];
								[aRemoteConnector2 disconnect];
								[aRemoteConnector1 connectTo:remoteConnection];
								movedOne = YES;
							}
							else if( connection && !remoteConnection){
								[aConnector2 disconnect];
								[aConnector1 connectTo:connection];
								movedOne = YES;
							}
							else if( !connection && remoteConnection){
								[aRemoteConnector2 disconnect];
								[aRemoteConnector1 connectTo:remoteConnection];
								movedOne = YES;
							}
							if(movedOne)break;
						}
						if(movedOne == YES)break;
					}
				}
                
			}while(movedOne == YES);
            
			short n = [self numberOfFeedThrus]-1;
			for(i=n;i>=newValue;i--){
				NSString* aKey = [self connectorKey:i];
				ORConnector* localConnectorToRemove = [connectors objectForKey:aKey];
				ORConnector* remoteConnectorToRemove = [remoteConnectors objectForKey:aKey];
				if(![localConnectorToRemove connector] && ![remoteConnectorToRemove connector]){
					[connectors removeObjectForKey:aKey];
					[guardian removeDisplayOf:remoteConnectorToRemove];
					[remoteConnectors removeObjectForKey:aKey];
				}
			}
			
		}
		
		
    }
}

- (void) adjustFeedThruPositions
{
	short i;
	float verticalRange = numberOfFeedThrus*2*kConnectorSize - kConnectorSize;
	float iconCenter	= frame.size.height/2;
	float feedThruStart = iconCenter - verticalRange/2;
	float yoffset		= 0;
	
	for(i=0;i<numberOfFeedThrus;i++){
		ORConnector* aConnector	= [connectors objectForKey:[self connectorKey:i]];
		[aConnector setLocalFrame:NSMakeRect([self connectorXPlane],feedThruStart+yoffset,kConnectorSize,kConnectorSize) ];
		yoffset += 2 * kConnectorSize;
	}
}

- (void) adjustRemoteFeedThruPositions
{
	short i;
	float verticalRange = numberOfFeedThrus*2*kConnectorSize - kConnectorSize;
	float iconCenter	= [guardian frame].size.height/2;
	float feedThruStart = iconCenter - verticalRange/2;
	float yoffset		= 0;
	
	for(i=0;i<numberOfFeedThrus;i++){
		ORConnector* aConnector	= [remoteConnectors objectForKey:[self connectorKey:i]];
		[aConnector setLocalFrame:NSMakeRect([self remoteConnectorXPlane],feedThruStart+yoffset,kConnectorSize,kConnectorSize) ];
		yoffset += 2 * kConnectorSize;
	}
	[guardian setUpImage];
}


- (BOOL) okToAdjustNumberOfFeedThrus:(short)newValue
{
	if(newValue<[self numberOfFeedThrus]){
        NSEnumerator *enumerator = [connectors keyEnumerator];
        id key;
        int count = 0;
        while ((key = [enumerator nextObject])) {
			ORConnector* aConnector = [connectors objectForKey:key];
			ORConnector* aRemoteConnector = [remoteConnectors objectForKey:key];
			if(![aConnector connector] && ![aRemoteConnector connector])count++;
        }
        if(count==0 ){
            ORRunAlertPanel(@"Connector Conflict!",@"You must disconnect something.",nil,nil,nil);
            return NO;
        }
    }
    return YES;
}

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self loadDefaults];
	
    numberOfFeedThrus = [decoder decodeIntegerForKey:@"NumberFeedThrus"];
	[self setRemoteConnectors:[decoder decodeObjectForKey:@"RemoteConnectors"]];

	[self adjustFeedThruPositions];

	if(!messagePipes){
		[self setMessagePipes:[NSArray arrayWithObjects:
								[ORMessagePipe messagePipe],
								[ORMessagePipe messagePipe],
								[ORMessagePipe messagePipe],
								[ORMessagePipe messagePipe],
								nil
								]];
	}

    [self registerNotificationObservers];
    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInteger:numberOfFeedThrus forKey:@"NumberFeedThrus"];
    [encoder encodeObject:remoteConnectors forKey:@"RemoteConnectors"];
}

@end
