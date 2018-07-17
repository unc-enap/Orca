//
//  ORIpeV4CrateModel.m
//  Orca
//
//  Created by Mark Howe on Fri Aug 5, 2005.
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

#pragma mark •••Imported Files
#import "ORIpeV4CrateModel.h"
//#import "ORIpeV4SLTModel.h"
#import "ORIpeCard.h"

NSString* ORIpeV4CrateModelUnlockedStopButtonChanged = @"ORIpeV4CrateModelUnlockedStopButtonChanged";
NSString* ORIpeV4CrateModelSnmpPowerSupplyIPChanged = @"ORIpeV4CrateModelSnmpPowerSupplyIPChanged";
NSString* ORIpeV4CrateConnectedChanged = @"ORIpeV4CrateConnectedChanged";

@implementation ORIpeV4CrateModel

#pragma mark •••initialization
- (void) dealloc
{
    [snmpPowerSupplyIP release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so that each crate can have its own version for drawing into.
    //---------------------------------------------------------------------------------------------------
    NSImage* aCachedImage = [NSImage imageNamed:@"IpeV4Crate"];
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
    if(powerOff){
        NSAttributedString* s = [[[NSAttributedString alloc] initWithString:@"No Pwr"
                                                                 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                     [NSColor redColor],NSForegroundColorAttributeName,
                                                                     [NSFont fontWithName:@"Geneva" size:10],NSFontAttributeName,
                                                                     nil]] autorelease]; 
        [s drawAtPoint:NSMakePoint(25,5)];
    }
    
    if([[self orcaObjects] count]){
        NSAffineTransform* transform = [NSAffineTransform transform];
        [transform translateXBy:5 yBy:47];
        [transform scaleXBy:.45 yBy:.45];
        [transform concat];
        NSEnumerator* e  = [[self orcaObjects] objectEnumerator];
        OrcaObject* anObject;
        while(anObject = [e nextObject]){
            BOOL oldHighlightState = [anObject highlighted];
            [anObject setHighlighted:NO];
            [anObject drawSelf:NSMakeRect(0,0,500,[[self image] size].height)];
            [anObject setHighlighted:oldHighlightState];
        }
    }
    [i unlockFocus];
    [self setImage:i];
    [i release];
    
    [[NSNotificationCenter defaultCenter]
                postNotificationName:OROrcaObjectImageChanged
                              object:self];
							  
}

- (void) makeConnectors
{
	//no connectors
}

- (void) connected
{
	[self setIsConnected:YES];
	//[[self adapter] readHwVersion];  //TODO: this produces issues together with the Edelweiss SLT -tb-
}

- (void) disconnected
{
	[self setIsConnected:NO];
}

- (void) makeMainController
{
    [self linkToController:@"ORIpeV4CrateController"];
}


#pragma mark •••Accessors

- (int) unlockedStopButton
{
    return unlockedStopButton;
}

- (void) setUnlockedStopButton:(int)aUnlockedStopButton
{
    unlockedStopButton = aUnlockedStopButton;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4CrateModelUnlockedStopButtonChanged object:self];
}

- (NSString*) snmpPowerSupplyIP
{
    if(!snmpPowerSupplyIP) return @"";
    return snmpPowerSupplyIP;
}

- (void) setSnmpPowerSupplyIP:(NSString*)aSnmpPowerSupplyIP
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSnmpPowerSupplyIP:snmpPowerSupplyIP];
    
    [snmpPowerSupplyIP autorelease];
    snmpPowerSupplyIP = [aSnmpPowerSupplyIP copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4CrateModelSnmpPowerSupplyIPChanged object:self];
}
- (void) setIsConnected:(BOOL)aState
{
	isConnected = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4CrateConnectedChanged object:self];
}

- (BOOL)isConnected
{
	return isConnected;
}

- (NSString*) adapterArchiveKey
{
	return @"Ipe Adapter";
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(viewChanged:)
                         name : ORIpeCardSlotChangedNotification
                       object : nil];
    
}

- (void) adapterChanged:(NSNotification*)aNote
{
	//DEBUG check when a notification was received ...    NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[self updateKatrinV4FLTs];
}

- (void) viewChanged:(NSNotification*)aNotification
{
	//DEBUG    NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
    [super viewChanged: aNotification];
}

- (void) checkCards
{
	NSEnumerator* e  = [[self orcaObjects] objectEnumerator];
	ORIpeCard* anObject;
	while(anObject = [e nextObject]){
		[anObject checkPresence];
	}	
}

- (void) updateKatrinV4FLTs
{
	//change/update dialog for all FLTs
    int i;
    int n = (int)[self count];
	for(i=0;i<n;i++){
	    id obj = [self objectAtIndex: i];
		//ORKatrinV4FLTModel *flt;
		    if([obj isKindOfClass:NSClassFromString(@"ORKatrinV4FLTModel")] ){
	            //NSLog(@" %@::%@ count objects: %i out of %i is FLTv4\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),i,n);//DEBUG -tb-
				if([obj respondsToSelector: @selector(updateUseSLTtime)]) 
				    [obj updateUseSLTtime];//I don't know how to get rid of this compiler warning -tb-
			}
	}
}
 
#pragma mark •••Hardware Access
//snmp access: see ORMPodCModel.m/.h - (void) writeValue:(NSString*)aCmd target:(id)aTarget selector:(SEL)aSelector;
-(void) snmpWriteStartCrateCommand
{
    //DEBUG OUTPUT:
                 NSLog(@"%@::%@: UNDER CONSTRUCTION! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO : DEBUG testing ...-tb-

    //TODO: under development - this is a first test - use snmp objects -tb- 2013-04
    //system("snmpset -v2c -m +WIENER-CRATE-MIB -c admin 192.168.2.3 sysMainSwitch.0 i 1");
    if(snmpPowerSupplyIP!=nil){
        NSString *cmd = [NSString stringWithFormat:@"snmpset -v2c -m +WIENER-CRATE-MIB -c admin %@ sysMainSwitch.0 i 1", snmpPowerSupplyIP];
        printf("calling: %s\n",[cmd cStringUsingEncoding: NSASCIIStringEncoding]);
        system([cmd cStringUsingEncoding: NSASCIIStringEncoding]);
    }
    else
    {
        printf("snmp command not called: no IP defined\n");
    }
}

-(void) snmpWriteStopCrateCommand
{
    //DEBUG OUTPUT:
                 NSLog(@"%@::%@: UNDER CONSTRUCTION! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO : DEBUG testing ...-tb-

    //TODO: under development - this is a first test - use snmp objects -tb- 2013-04
    //system("snmpset -v2c -m +WIENER-CRATE-MIB -c admin 192.168.2.3 sysMainSwitch.0 i 0");
    if(snmpPowerSupplyIP!=nil){
        NSString *cmd = [NSString stringWithFormat:@"snmpset -v2c -m +WIENER-CRATE-MIB -c admin %@ sysMainSwitch.0 i 0", snmpPowerSupplyIP];
        printf("calling: %s\n",[cmd cStringUsingEncoding: NSASCIIStringEncoding]);
        system([cmd cStringUsingEncoding: NSASCIIStringEncoding]);
    }
    else
    {
        printf("snmp command not called: no IP defined\n");
    }
}



#pragma mark *** Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    //TODO: FIXED this resets the adapter to 0x0 after setting it in [super super  initWithCoder ...], see ORCrate.m!!! -tb-

    
	[[self undoManager] disableUndoRegistration];
    
	[self setSnmpPowerSupplyIP:[decoder decodeObjectForKey:@"snmpPowerSupplyIP"]];
    //TODO:   for code wizard: 'decoder' (CW is searching this string ... , if not found maybe produce out-of-bounds exception at objectAtIndex: in CWImplementationFile.m, line ...) -tb-
        
	[[self undoManager] enableUndoRegistration];
	
	[self registerNotificationObservers];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];

    [encoder encodeObject:snmpPowerSupplyIP forKey:@"snmpPowerSupplyIP"];
    //TODO:   for code wizard: 'forKey' (CW is searching this string ... , if not found will produce out-of-bounds exception at objectAtIndex: in CWImplementationFile.m, line 242) -tb-
}

#pragma mark •••OROrderedObjHolding
- (int) maxNumberOfObjects {return 21;}
- (int) objWidth		 {return 12;}
- (NSString*) nameForSlot:(int)aSlot	{ return [NSString stringWithFormat:@"Station %d",aSlot+1]; }
- (NSRange) legalSlotsForObj:(id)anObj
{
	if(    [anObj isKindOfClass:NSClassFromString(@"ORIpeV4SLTModel")]
       || [anObj isKindOfClass:NSClassFromString(@"OREdelweissSLTModel")]
       || [anObj isKindOfClass:NSClassFromString(@"ORKatrinV4SLTModel")] ){
		return NSMakeRange(10,1);
	}
	else {
		return  NSMakeRange(0,[self maxNumberOfObjects]);
	}
}

- (BOOL) slot:(int)aSlot excludedFor:(id)anObj 
{ 
	if( !(   [anObj isKindOfClass:NSClassFromString(@"ORIpeV4SLTModel")]
          || [anObj isKindOfClass:NSClassFromString(@"OREdelweissSLTModel")]
          || [anObj isKindOfClass:NSClassFromString(@"ORKatrinV4SLTModel")]
          )
           && (aSlot==10)
       ){
		return YES;
	}
	else return NO;
}

@end
