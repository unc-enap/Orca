//
//  ORContainerModel.m
//  Orca
//
//  Created by Mark Howe on Fri Nov 22 2002.
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
#import "ORContainerModel.h"

NSString* ORContainerScaleChangedNotification = @"ORContainerScaleChangedNotification";
NSString* ORContainerBackgroundImageChangedNotification = @"ORContainerBackgroundImageChangedNotification";


@implementation ORContainerModel

#pragma mark ¥¥¥initialization

- (void) setUpImage
{
	//---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so that each container can have its own version for drawing into.
    //---------------------------------------------------------------------------------------------------
    NSImage* aCachedImage = [NSImage imageNamed:@"Container"];
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
	NSImage* anImage = [[NSImage alloc] initWithContentsOfFile:[backgroundImagePath stringByExpandingTildeInPath]];

	float xScale = .8*[aCachedImage size].width/[anImage size].width;
	float yScale = .8*[aCachedImage size].height/[anImage size].height;
	float scale = MIN(.8,MIN(xScale,yScale));
	float newWidth = [anImage size].width*scale;
	float newHeight = [anImage size].height*scale;
	[anImage setSize:NSMakeSize(newWidth,newHeight)];
	[anImage drawAtPoint:NSMakePoint([aCachedImage size].width/2. - [anImage size].width/2., [aCachedImage size].height/2. - [anImage size].height/2.) fromRect:[anImage imageRect] operation:NSCompositingOperationSourceAtop fraction:1.0];
	[anImage release];
	
    
    if(!anImage && [[self orcaObjects] count]){
		NSImage* imageOfObjects = [self imageOfObjects:[self orcaObjects] withTransparency:1.0];
		float xScale = .75*[aCachedImage size].width/[imageOfObjects size].width;
		float yScale = .75*[aCachedImage size].height/[imageOfObjects size].height;
		float scale = MIN(.3,MIN(xScale,yScale));
		float newWidth = [imageOfObjects size].width*scale;
		float newHeight = [imageOfObjects size].height*scale;
		
		[imageOfObjects setSize:NSMakeSize(newWidth,newHeight)];
		[imageOfObjects drawAtPoint:NSMakePoint([aCachedImage size].width/2-newWidth/2, [aCachedImage size].height/2-newHeight/2) fromRect:[imageOfObjects imageRect]  operation:NSCompositingOperationSourceAtop fraction:1.0];
	}
	
	if([self uniqueIdNumber]){
        NSAttributedString* n = [[NSAttributedString alloc] 
                                initWithString:[NSString stringWithFormat:@"%u",[self uniqueIdNumber]] 
                                    attributes:[NSDictionary dictionaryWithObject:[NSFont labelFontOfSize:14] forKey:NSFontAttributeName]];
        
        [n drawInRect:NSMakeRect(10,[i size].height-18,[i size].width-20,16)];
        [n release];

    }

    [i unlockFocus];
    [self setImage:i];
    [i release];
    
    [[NSNotificationCenter defaultCenter]
                postNotificationName:OROrcaObjectImageChanged
                              object:self];


}

- (NSString*) helpURL
{
	return @"Subsystems/Containers_and_Dynamic_Labels.html";
}

- (int)scaleFactor 
{
    return scaleFactor;
}

- (void)setScaleFactor:(int)aScaleFactor 
{
    
    if(aScaleFactor < 20)aScaleFactor = 20;
    else if(aScaleFactor>150)aScaleFactor=150;
    
    if(aScaleFactor != scaleFactor){
        [[[self undoManager] prepareWithInvocationTarget:self] setScaleFactor:scaleFactor];
                
        scaleFactor = aScaleFactor;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ORContainerScaleChangedNotification
                                                            object:self];
    }
}

- (NSString*)backgroundImagePath 
{
    return backgroundImagePath;
}

- (void)setBackgroundImagePath:(NSString*)aPath 
{
    
	[[[self undoManager] prepareWithInvocationTarget:self] setBackgroundImagePath:backgroundImagePath];
	[aPath retain];
	[backgroundImagePath release];
	backgroundImagePath = aPath;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORContainerBackgroundImageChangedNotification
														object:self];
	[self setUpImage];
}



//override this because we WANT to use the name of the connector that we are given
- (void) assumeDisplayOf:(ORConnector*)aConnector withKey:(NSString*)aKey
{
    NSEnumerator *e = [[connectors allKeys] objectEnumerator];
    id key;
    while ((key = [e nextObject])) {
        if([connectors objectForKey:key] == aConnector)return;
    }
    if(aConnector){
        [connectors setObject: aConnector forKey:aKey];
        [aConnector setGuardian:self];
    }
}


- (void) makeMainController
{
    [self linkToController:@"ORContainerController"];
}

- (void) positionConnector:(ORConnector*)aConnector
{
}

- (void) addObjects:(NSArray*)someObjects
{
	NSMutableArray* objectList = [NSMutableArray arrayWithArray:someObjects];
	NSMutableArray* forbiddenObjects = [NSMutableArray array];
	NSEnumerator* e = [someObjects objectEnumerator];
	id anObj;
	while(anObj = [e nextObject]){
		if(![anObj acceptsGuardian:self]){
			[forbiddenObjects addObject:anObj];
		}
	}
	[objectList removeObjectsInArray:forbiddenObjects];
	[super addObjects:objectList];
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
	
    int value = [decoder decodeIntForKey:@"scaleFactor"];
    if(value == 0)value = 100;
    [self setScaleFactor:value];
	[self setBackgroundImagePath:[decoder decodeObjectForKey:@"backgroundImagePath"]];
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInteger:scaleFactor forKey:@"scaleFactor"];						
    [encoder encodeObject:backgroundImagePath forKey:@"backgroundImagePath"];						
}

@end
