//
//  ORPlotLinkModel.m
//  Orca
//
//  Created by Mark Howe on Wed 23 23 2009.
//  Copyright © 2009 University of North Carolina. All rights reserved.
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


#pragma mark •••Imported Files
#import "ORPlotLinkModel.h"
#import "ORCommandCenter.h"

NSString* ORPlotLinkModelIconTypeChanged = @"ORPlotLinkModelIconTypeChanged";
NSString* ORPlotLinkModelDataCatalogNameChanged		 = @"ORPlotLinkModelDataCatalogNameChanged";
NSString* ORPlotLinkModelPlotNameChanged			= @"ORPlotLinkModelPlotNameChanged";
NSString* ORPlotLinkModelPlotLinkChangedNotification = @"ORPlotLinkModelPlotLinkChangedNotification";
NSString* ORPlotLinkLock							 = @"ORPlotLinkLock";

@implementation ORPlotLinkModel

#pragma mark •••initialization
- (id) init
{
    self = [super init];
    return self;
}

-(void) dealloc
{
    [plotName release];
	[dataCatalogName release];
	[super dealloc];
}

- (void) setUpImage
{
	if(iconType==1) [self setImage:[NSImage imageNamed:@"1DPlotLink"]];
	else			[self setImage:[NSImage imageNamed:@"2DPlotLink"]];
}

- (NSString*) helpURL
{
	return @"Subsystems/Containers_and_Dynamic_PlotLinks.html";
}
- (void) makeMainController
{
    [self linkToController:@"ORPlotLinkController"];
}

- (void) doDoubleClick:(id)sender
{
	if([plotName length]) [self openAltDialog:self];		
    else				  [self openMainDialog:self];
}

- (void) doCmdDoubleClick:(id)sender atPoint:(NSPoint)aPoint
{
	if([plotName length]) [self openMainDialog:self];		
    else				  [self openAltDialog:self];
}

- (void) openMainDialog:(id)sender
{
	[self makeMainController];
}

- (void) openAltDialog:(id)sender
{
	if([plotName length]!=0){
		id obj = [[self document] findObjectWithFullID:dataCatalogName];
		if([obj respondsToSelector:@selector(dataSetWithName:)]){
			id aPlot = [obj dataSetWithName:plotName];
			if([aPlot respondsToSelector:@selector(makeMainController)]){
				[aPlot makeMainController];
			}
		}
	}
	else [self makeMainController];
}

#pragma mark ***Accessors
- (int) iconType
{
    return iconType;
}

- (void) setIconType:(int)aIconType
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIconType:iconType];
    iconType = aIconType;
	[self setUpImage];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPlotLinkModelIconTypeChanged object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:OROrcaObjectMoved object:self];
}

- (NSString*)	dataCatalogName
{
	if(!dataCatalogName)return @"";
    else return dataCatalogName;
}

- (void) setDataCatalogName:(NSString*)aString
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDataCatalogName:dataCatalogName];
    
    [dataCatalogName autorelease];
    dataCatalogName = [aString copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPlotLinkModelDataCatalogNameChanged object:self];
}

- (NSString*) plotName
{
	if(!plotName)return @"";
    else return plotName;
}

- (void) setPlotName:(NSString*)aPlotName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPlotName:plotName];
    
    [plotName autorelease];
    plotName = [aPlotName copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORPlotLinkModelPlotNameChanged object:self];
}

- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian
{
    return  [aGuardian isMemberOfClass:NSClassFromString(@"ORGroup")]           || 
			[aGuardian isMemberOfClass:NSClassFromString(@"ORProcessModel")]	||
            [aGuardian isMemberOfClass:NSClassFromString(@"ORContainerModel")];
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setIconType:[decoder decodeIntForKey:@"ORPlotLinkModelIconType"]];
    [self setPlotName:			[decoder decodeObjectForKey:@"plotName"]];
    [self setDataCatalogName:	[decoder decodeObjectForKey:@"dataCatalogName"]];
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInteger:iconType forKey:@"ORPlotLinkModelIconType"];
    [encoder encodeObject:plotName	forKey:@"plotName"];
    [encoder encodeObject:dataCatalogName	forKey:@"dataCatalogName"];
}

- (void) doCntrlClick:(NSView*)aView
{
	NSEvent* theCurrentEvent = [NSApp currentEvent];
    NSEvent *event =  [NSEvent mouseEventWithType:NSEventTypeLeftMouseDown
                                         location:[theCurrentEvent locationInWindow]
                                    modifierFlags:NSEventModifierFlagControl // 0x100
                                        timestamp:(NSTimeInterval)0
                                     windowNumber:[theCurrentEvent windowNumber]
                                          context:nil
                                      eventNumber:0
                                       clickCount:1
                                         pressure:1];
	
    NSMenu *menu = [[NSMenu alloc] init];
	[[menu insertItemWithTitle:@"Open PlotLink Dialog"
						action:@selector(openMainDialog:)
				 keyEquivalent:@""
					   atIndex:0] setTarget:self];
	if([plotName length]){
		[[menu insertItemWithTitle:[NSString stringWithFormat:@"Open %@",plotName]
							action:@selector(openAltDialog:)
					 keyEquivalent:@""
						   atIndex:0] setTarget:self];
	}
	[[menu insertItemWithTitle:@"Help"
						action:@selector(openHelp:)
				 keyEquivalent:@""
					   atIndex:1] setTarget:self];
	[menu setDelegate:self];
    [NSMenu popUpContextMenu:menu withEvent:event forView:aView];
}

@end
