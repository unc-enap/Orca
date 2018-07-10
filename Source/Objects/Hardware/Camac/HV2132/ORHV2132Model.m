/*
 *  ORHV2132Model.cpp
 *  Orca
 *
 *  Created by Mark Howe on Sat Nov 16 2002.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
 *
 */
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
#import "ORHV2132Model.h"
#import "ORCamacCrateModel.h"

NSString* ORHV2132ModelHvValueChanged			= @"ORHV2132ModelHvValueChanged";
NSString* ORHV2132ModelMainFrameChanged			= @"ORHV2132ModelMainFrameChanged";
NSString* ORHV2132ModelChannelChanged			= @"ORHV2132ModelChannelChanged";
NSString* ORHV2132SettingsLock					= @"ORHV2132SettingsLock";
NSString* ORHV2132StateFileDirChanged			= @"HVStateFileDirChanged";
NSString* ORHV2132VoltageChanged				= @"ORHV2132VoltageChanged";
NSString* ORHV2132OnOffChanged					= @"ORHV2132OnOffChanged";


@interface ORHV2132Model (fakeoutPrivate)
//-------------------------------------------------------------------------------
//  until we get the read back functionality to work use the following methods to
//  fake readback by storing the hw values in a dictionary
//-------------------------------------------------------------------------------
- (void) setHVRecordMainFrame:(int)aMainFrame channel:(int)aChannel voltage:(int)aValue;
- (void) setHVRecordMainFrame:(int)aMainFrame status:(BOOL)state;
- (int)  getHVRecordVoltageMainFrame:(int)aMainFrame channel:(int)aChannel;
- (int)  getHVRecordStatusMainFrame:(int)aMainFrame;
@end


@implementation ORHV2132Model

#pragma mark ¥¥¥Initialization
- (id) init
{		
    self = [super init];
	commLock = [[NSLock alloc] init];
    return self;
}

- (void) dealloc
{
	[hvRecord release];
	[commLock release];
    [connectorName release];
    [connector release];
    [dirName release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"HV2132Card"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORHV2132Controller"];
}

- (NSString*) helpURL
{
	return @"CAMAC/HV2132_4032.html";
}

- (void) makeConnectors
{
    //make and cache our connector. However this connector will be 'owned' by another object (the crate)
    //so we don't add it to our list of connectors. It will be added to the true owner later.
    [self setConnector: [[[ORConnector alloc] initAt:NSZeroPoint withGuardian:self withObjectLink:self] autorelease]];
    
    [connector setConnectorImageType:kDefaultImage];
    
	[ connector setConnectorType: '403O' ];
	[ connector addRestrictedConnectionType: '403I' ]; //can only connect to 4032 inputs
    
}

- (id) getHVController
{
	return self;
}

#pragma mark ¥¥¥Notifications
-(void)registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver: self
                     selector: @selector(runStopped:)
                         name: ORRunStoppedNotification
                       object: nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(runAboutToStart:)
                         name: ORRunAboutToStartNotification
                       object: nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(runStarted:)
                         name: ORRunAboutToStartNotification
                       object: nil];
	
    [notifyCenter addObserver: self
                     selector: @selector(setMainFrameIDs:)
                         name: ORGroupObjectsRemoved
                       object: nil];
	
    [notifyCenter addObserver: self
                     selector: @selector(setMainFrameIDs:)
                         name: ORGroupObjectsAdded
                       object: nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(setMainFrameIDs:)
                         name: ORConnectionChanged
                       object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(powerRestored:)
                         name : @"CamacPowerRestoredNotification"
                       object : nil];
	
}

- (void) awakeAfterDocumentLoaded
{
	[self setMainFrameIDs:nil];
}

- (void) setMainFrameIDs:(NSNotification*)aNote
{
	[[[connector connector] objectLink] setMainFrameID:0];
}

- (void) runAboutToStart:(NSNotification*)aNote
{
}

- (void) runStarted:(NSNotification*)aNote
{
}

- (void) runStopped:(NSNotification*)aNote
{
}

- (void) powerRestored:(NSNotification*)aNote
{
    if([aNote object] == [guardian controllerCard]){
		[self clearBuffer];
    }
}

#pragma mark ¥¥¥Accessors
- (NSString*) shortName
{
	return @"HV2132";
}
- (NSString*) connectorName
{
    return connectorName;
}
- (void) setConnectorName:(NSString*)aName
{
    [aName retain];
    [connectorName release];
    connectorName = aName;
    
}

- (ORConnector*) connector
{
    return connector;
}

- (void) setConnector:(ORConnector*)aConnector
{
    [aConnector retain];
    [connector release];
    connector = aConnector;
}

- (void) setDirName:(NSString*)aDirName
{
	if(!aDirName)aDirName = @"~";
	
	[[[self undoManager] prepareWithInvocationTarget:self] setDirName:[self dirName]];
    
	[dirName autorelease];
    dirName = [aDirName copy];
    
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:ORHV2132StateFileDirChanged
	 object: self];
    
}

- (NSString*)dirName
{
	return dirName;
}


- (int) hvValue
{
    return hvValue;
}

- (void) setHvValue:(int)aHvValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHvValue:hvValue];
    
    hvValue = aHvValue;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORHV2132ModelHvValueChanged object:self];
}

- (int) mainFrame
{
    return mainFrame;
}

- (void) setMainFrame:(int)aMainFrame
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMainFrame:mainFrame];
    
    mainFrame = aMainFrame;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORHV2132ModelMainFrameChanged object:self];
}

- (int) channel
{
    return channel;
}

- (void) setChannel:(int)aChannel
{
    [[[self undoManager] prepareWithInvocationTarget:self] setChannel:channel];
    
    channel = aChannel;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORHV2132ModelChannelChanged object:self];
}

- (void) positionConnector:(ORConnector*)aConnector
{
	if(aConnector == connector){
		//position our managed connectors.
		NSRect aFrame = [aConnector localFrame];
		aFrame.origin = NSMakePoint(10+[self stationNumber]*16*.62, 75);
		[aConnector setLocalFrame:aFrame];
	}
}

- (void) setSlot:(int)aSlot
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSlot:[self slot]];
    [self setTag:aSlot];
	
    [guardian positionConnector:connector forCard:self];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORCamacCardSlotChangedNotification
	 object: self];
}
- (void) setGuardian:(id)aGuardian
{
    
    id oldGuardian = guardian;
    [super setGuardian:aGuardian];
    
    if(oldGuardian != aGuardian){
        [oldGuardian removeDisplayOf:connector];
    }
    
    [aGuardian assumeDisplayOf:connector];
    [aGuardian positionConnector:connector forCard:self];
}

- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian
{
    [aGuardian removeDisplayOf:connector];
}

- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian
{
    [aGuardian assumeDisplayOf:connector];
}


#pragma mark ¥¥¥Hardware functions
- (void) enableL1L2:(BOOL) state
{
	unsigned short f;
	if(state)f = 26;
	else f = 24;
	//[[self adapter] camacShortNAF:[self stationNumber] a:0 f:f];
	[[self adapter] camacShortNAF:[self stationNumber] a:1 f:f];
}

- (void) clearBuffer
{
	//generate f(2) reads until Q = 0;
	int count = 0;
	while(1){
		unsigned short value;
		unsigned short status = [[self adapter] camacShortNAF:[self stationNumber] a:0 f:2 data:&value];
		if(!isQbitSet(status))break;
		if(count++ > 100){
			[NSException raise:@"FIFO clear Error" format:@"Unable to clear FIFO on HV2132 %d",[self stationNumber]];
		}
	}
}

- (void) setVoltage:(int) aValue mainFrame:(int) aMainFrame channel:(int) aChannel
{
	@try {
		
		[commLock lock];
		unsigned short dataWord;
		
		//send C-M-0 cmd (modify one channel voltage)
		dataWord = ((aMainFrame&0x3f)<<4) | ((aChannel&0x3f)<<10);
		[self sendCmd:dataWord label:@"modify voltage"];
		
		//send V-1 cmd (set Value)
		dataWord = (aValue&0xfff)<<4 | 0x1;
		[self sendCmd:dataWord label:@"set value"];
		
		//load the hvrecord but only if mainframe is ON
		if([self getHVRecordStatusMainFrame:aMainFrame]){
			[self setHVRecordMainFrame: aMainFrame channel:aChannel voltage:aValue];
			[[NSNotificationCenter defaultCenter]
			 postNotificationName:ORHV2132VoltageChanged
			 object: self
			 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
					   [NSNumber numberWithInt:aMainFrame],@"MainFrame",
					   [NSNumber numberWithInt:aChannel],@"Channel",
					   [NSNumber numberWithInt:aValue],@"Voltage",
					   nil]];
		}
		[commLock unlock];
		
	}
	@catch(NSException* localException) {
		[commLock unlock];
		[localException raise];
	}
}

- (void) readVoltage:(int*) aValue mainFrame:(int) aMainFrame channel:(int) aChannel
{
	@try {
		[commLock lock];
		
#		ifdef HV2132ReadWorking
		unsigned short dataWord;
		
		//send C-M-3 cmd (read one channel voltage)
		dataWord = ((aMainFrame&0x3f)<<4) | ((aChannel&0x3f)<<10) | 3;
		[self sendCmd:dataWord label:@"read voltage"];
		[ORTimer delay:.8]; //temp
		//response should be T3
		[self readData:&dataWord numWords:1];
		if(((dataWord & 0xf) != 3) || (((dataWord>>4) & 0x3f) != aMainFrame)){
			[NSException raise:@"HV cmd Error" format:@"HV2132 %d bad reponse: set value",[self stationNumber]];
		}
		else *aValue = dataWord>>4;
		
#		else
		*aValue = [self getHVRecordVoltageMainFrame: aMainFrame channel:aChannel];
#		endif
		
		[commLock unlock];
	}
	@catch(NSException* localException) {
		[commLock unlock];
		[localException raise];
	}
}

- (void) readAllVoltages:(int*)aValues mainFrame:(int) aMainFrame
{
	@try {
		[commLock lock];
		//response should be 32 T3s
		unsigned short values[kHV2132NumberSupplies];
		int i;
		
#		ifdef HV2132ReadWorking
		unsigned short dataWord;
		//send C-M-4 cmd (read all channel voltages)
		dataWord = ((aMainFrame&0x3f)<<4) | 4;
		[self sendCmd:dataWord label:@"read all voltages"];
		
		[self readData:values numWords:kHV2132NumberSupplies];
		for(i=0;i<kHV2132NumberSupplies;i++){
			if(((values[i] & 0xf) == 3) && (((dataWord>>4) & 0x3f) == aMainFrame)){
				aValues[i] = values[i]>>4;
			}
			else {
				[NSException raise:@"HV cmd Error" format:@"HV2132 %d bad reponse: set value",[self stationNumber]];
			}
		}
#		else
		for(i=0;i<kHV2132NumberSupplies;i++){
			values[i] = [self getHVRecordVoltageMainFrame: aMainFrame channel:i];
		}
#		endif
		
		[commLock unlock];
	}
	@catch(NSException* localException) {
		[commLock unlock];
		[localException raise];
	}
}

- (void) readTarget:(int*) aValue mainFrame:(int) aMainFrame channel:(int) aChannel
{
	@try {
		[commLock lock];
		unsigned short dataWord;
		
		//send C-M-8 cmd (read one channel target)
		dataWord = ((aMainFrame&0x3f)<<4) | ((aChannel&0x3f)<<10) | 8;
		[self sendCmd:dataWord label:@"read target"];
		
		//response should be T8
		[self readData:&dataWord numWords:1];
		if(((dataWord & 0xf) != 8) || (((dataWord>>4) & 0x3f) != aMainFrame)){
			[NSException raise:@"HV cmd Error" format:@"HV2132 %d bad reponse: read Target",[self stationNumber]];
		}
		else *aValue = dataWord>>4;
		[commLock unlock];
		
	}
	@catch(NSException* localException) {
		[commLock unlock];
		[localException raise];
	}
}

- (void) readAllTargets:(int*)aValues mainFrame:(int) aMainFrame
{
	@try {
		[commLock lock];
		unsigned short dataWord;
		
		//send C-M-10 cmd (read all channel targets)
		dataWord = ((aMainFrame&0x3f)<<4) | 10;
		[self sendCmd:dataWord label:@"read all voltages"];
		
		//response should be kHV2132NumberSupplies T8s
		unsigned short values[kHV2132NumberSupplies];
		[self readData:values numWords:kHV2132NumberSupplies];
		int i;
		for(i=0;i<kHV2132NumberSupplies;i++){
			if(((values[i] & 0xf) == 8) && (((dataWord>>4) & 0x3f) == aMainFrame)){
				aValues[i] = values[i]>>4;
			}
			else {
				[NSException raise:@"HV cmd Error" format:@"HV2132 %d bad reponse: read Target",[self stationNumber]];
			}
		}
		[commLock unlock];
		
	}
	@catch(NSException* localException) {
		[commLock unlock];
		[localException raise];
	}
}

- (void) readStatus:(int*) aValue failedMask:(unsigned short*)failed mainFrame:(int) aMainFrame
{
	@try {
		[commLock lock];
#		ifdef HV2132ReadWorking
		
		unsigned short dataWord;
		
		//[self setEnableResponse:YES mainFrame:aMainFrame];
		//send C-M-9 cmd (read one channel target)
		dataWord = ((aMainFrame&0x3f)<<4) | 9;
		[self sendCmd:dataWord label:@"read status"];
		
		//response should be T9 for each failed channel, followed by a  T5
		*failed = 0x0;
		unsigned short result[kHV2132NumberSupplies];
		int i;
		for(i=0;i<kHV2132NumberSupplies;i++)result[i] = 0x0;
		[self readData:result numWords:kHV2132NumberSupplies];
		
		BOOL ok = NO;
		for(i=0;i<kHV2132NumberSupplies;i++){
			if((result[i]&0xf) == 9){
				*failed |= (0x1<<((result[i]>>10)&0x3f));
			}
			if((result[i]*0xf) == 5){
				*aValue = (result[i]>>10)&0x3f;
				ok = YES;
				break;
			}
		}
		
		if(!ok){
			[NSException raise:@"HV cmd Error" format:@"HV2132 %d bad reponse: read status",[self stationNumber]];
		}
#		else
		*aValue = [self getHVRecordStatusMainFrame:aMainFrame];
#		endif
		
		[commLock unlock];
		//[self setEnableResponse:NO mainFrame:aMainFrame];
		
	}
	@catch(NSException* localException) {
		[commLock unlock];
		[localException raise];
	}
}

- (void) readPodComplement:(unsigned short*) typeMask mainFrame:(int) aMainFrame
{
	@try {
		[commLock lock];
		unsigned short dataWord;
		
		//send C-M-15 cmd (get Pod Complement)
		dataWord = ((aMainFrame&0x3f)<<4)  | 15;
		[self sendCmd:dataWord label:@"read pod types"];
		
		//response should be P10
		[self readData:typeMask numWords:1];
		if(((*typeMask & 0xf) != 10) || (((*typeMask>>4) & 0x3f) != aMainFrame)){
			[NSException raise:@"HV cmd Error" format:@"HV2132 %d bad reponse: read Target",[self stationNumber]];
		}
		else *typeMask = *typeMask>>4;
		//1 for 7KV and 0 3.3KV Bit2^7 is pod 0 Bit0 is pod 0
		[commLock unlock];
		
	}
	@catch(NSException* localException) {
		[commLock unlock];
		[localException raise];
	}
}


- (void) setHV:(BOOL)state mainFrame:(int)aMainFrame
{
	@try {
		[commLock lock];
		//send S-M-5 cmd (HV ON/OFF switch)
		unsigned short dataWord = ((state&0x1)<<10) | ((aMainFrame&0x3f)<<4) | 5;
		[self sendCmd:dataWord label:@"Set HV State"];
		
		//load the hv record
		[self setHVRecordMainFrame:aMainFrame  status:state];
		
		[commLock unlock];
		
		[[NSNotificationCenter defaultCenter]
		 postNotificationName:ORHV2132OnOffChanged
		 object: self
		 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
				   [NSNumber numberWithInt:aMainFrame],@"MainFrame",
				   [NSNumber numberWithInt:state],@"State",
				   nil]];
		
		
	}
	@catch(NSException* localException) {
		[commLock unlock];
		[localException raise];
	}
}

- (void) sendCmd:(unsigned short)aCmd label:(NSString*)aLabel
{
#	ifndef HV2132NoHardware
	
	unsigned short statusWord = [[self adapter] camacShortNAF:[self stationNumber] a:0 f:16 data:&aCmd];
	if(!isQbitSet(statusWord)){
		[NSException raise:@"HV cmd Error" format:@"HV2132 %d refused cmd: %@",[self stationNumber],aLabel];
	}
	else [ORTimer delay:.8];
#	endif
}

- (void) setEnableResponse:(BOOL)state mainFrame:(int)aMainFrame
{
	//send S-M-11 cmd (enable/disable response)
	unsigned short dataWord = ((state&0x1)<<10) | ((aMainFrame&0x3f)<<4) | 11;
	[self sendCmd:dataWord label:@"enable/disable response"];
	//no response to this command
}

- (void) readData:(unsigned short*)data numWords:(int)num
{
	
#	ifdef HV2132NoHardware
	return;
#	endif
	
	
	if(num<=0)return;
	
    unsigned short statusWord;
    unsigned short dataWord;
	int wordCount = 0;
	BOOL timeOut = NO;
	NSTimeInterval t0 = [NSDate timeIntervalSinceReferenceDate];
	while(1){
		if([NSDate timeIntervalSinceReferenceDate]-t0 >= 7){
			timeOut = YES;
			break;
		}
		//check LAM2
		[[self adapter] camacShortNAF:[self stationNumber] a:0 f:0 data:&dataWord];
		if(dataWord & 0x2) {
			while(1){
				statusWord = [[self adapter] camacShortNAF:[self stationNumber] a:1 f:2 data:&data[wordCount]];
				if(isQbitSet(statusWord)){
					//check for errors
					if(data[wordCount] & 15){
						[NSException raise:@"HV reponse Error" format:@"HV2132 %d Transmission error in response",[self stationNumber]];
					}
					else if(data[wordCount] & 12){
						[NSException raise:@"HV reponse Error" format:@"HV2132 %d Parity error in response",[self stationNumber]];
					}
					else if(data[wordCount] & 13){
						[NSException raise:@"HV reponse Error" format:@"HV2132 %d Overwrite error in response",[self stationNumber]];
					}
					wordCount++;
				}
				else break;
			}
			//clear LAM2
			[[self adapter] camacShortNAF:[self stationNumber] a:0 f:10];
			if(wordCount > num){
				[NSException raise:@"HV reponse Error" format:@"HV2132 %d Incorrect word count in response",[self stationNumber]];
			}
			break;
		}
	}
	if(timeOut){
		NSLog(@"HV2132 %d TimeOut\n",[self stationNumber]);
		[NSException raise:@"HV cmd TimeOut" format:@"HV2132 %d Cmd TimeOut",[self stationNumber]];
	}
	else if(wordCount != num){
		[NSException raise:@"HV reponse Error" format:@"HV2132 %d Incorrect word count in response",[self stationNumber]];
	}
	
}

#pragma mark ¥¥¥Archival

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
    [self setHvValue:		[decoder decodeIntForKey:@"hvValue"]];
    [self setMainFrame:		[decoder decodeIntForKey:@"mainFrame"]];
    [self setChannel:		[decoder decodeIntForKey:@"channel"]];
	
    [self setConnectorName:	[decoder decodeObjectForKey:@"connectorName"]];
    [self setConnector:		[decoder decodeObjectForKey:@"connector"]];
    [self setDirName:		[decoder decodeObjectForKey:@"HVDirName"]];
	
    [[self undoManager] enableUndoRegistration];
    [self registerNotificationObservers];
	commLock = [[NSLock alloc] init];
	
	[self loadHVParams];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:hvValue			forKey:@"hvValue"];
    [encoder encodeInt:mainFrame		forKey:@"mainFrame"];
    [encoder encodeInt:channel			forKey:@"channel"];
    [encoder encodeObject:connectorName	forKey:@"connectorName"];
    [encoder encodeObject:connector		forKey:@"connector"];
    [encoder encodeObject:[self dirName] forKey:@"HVDirName"];
}

- (void) loadHVParams
{	
    [hvRecord release];
    NSString* fullFileName = [[dirName stringByExpandingTildeInPath] stringByAppendingPathComponent:@"HV2132State"];
	hvRecord = [[NSMutableDictionary dictionaryWithContentsOfFile:fullFileName] retain];
}

- (void) saveHVParams
{
    NSString* fullFileName = [[dirName stringByExpandingTildeInPath] stringByAppendingPathComponent:@"HV2132State"];
	[hvRecord writeToFile:fullFileName atomically:YES];    
}
@end

@implementation ORHV2132Model (fakeoutPrivate)
//-------------------------------------------------------------------------------
//  until we get the read back functionality to work use the following methods to
//  fake readback by storing the hw values in a dictionary
//-------------------------------------------------------------------------------
- (void) setHVRecordMainFrame:(int)aMainFrame channel:(int)aChannel voltage:(int)aValue
{
	//make the keys
	NSString* mainFrameKey	= [NSString stringWithFormat:@"HVMainFrame%d",aMainFrame];
	NSString* timeKey		= [NSString stringWithFormat:@"SetTime%d",aChannel];
	NSString* voltageKey	= [NSString stringWithFormat:@"HVVoltage%d",aChannel];
	
	if(!hvRecord)hvRecord = [[NSMutableDictionary dictionary] retain];
	
	NSMutableDictionary* mainFrameDictionary = [hvRecord objectForKey:mainFrameKey];
	if(!mainFrameDictionary){
		mainFrameDictionary = [NSMutableDictionary dictionary];
		[hvRecord setObject:mainFrameDictionary forKey:mainFrameKey];
	}
	[mainFrameDictionary setObject:[NSNumber numberWithInt:aValue] forKey:voltageKey]; 
	[mainFrameDictionary setObject:[NSDate date] forKey:timeKey]; 
	
	
}

- (void) setHVRecordMainFrame:(int)aMainFrame status:(BOOL)state
{
	//make the keys
	NSString* mainFrameKey	= [NSString stringWithFormat:@"HVMainFrame%d",aMainFrame];
	NSString* statusKey		= [NSString stringWithFormat:@"HVStatus"];
	
	if(!hvRecord)hvRecord = [[NSMutableDictionary dictionary] retain];
	
	NSMutableDictionary* mainFrameDictionary = [hvRecord objectForKey:mainFrameKey];
	if(!mainFrameDictionary){
		mainFrameDictionary = [NSMutableDictionary dictionary];
		[hvRecord setObject:mainFrameDictionary forKey:mainFrameKey];
	}
	[mainFrameDictionary setObject:[NSNumber numberWithBool:state] forKey:statusKey]; 
}

- (int)  getHVRecordVoltageMainFrame:(int)aMainFrame channel:(int)aChannel
{
	NSString* mainFrameKey	= [NSString stringWithFormat:@"HVMainFrame%d",aMainFrame];
	NSString* voltageKey	= [NSString stringWithFormat:@"HVVoltage%d",aChannel];
	NSMutableDictionary* mainFrameDictionary = [hvRecord objectForKey:mainFrameKey];
	return [[mainFrameDictionary objectForKey:voltageKey] intValue];
}

- (int)  getHVRecordStatusMainFrame:(int)aMainFrame
{
	NSString* mainFrameKey	= [NSString stringWithFormat:@"HVMainFrame%d",aMainFrame];
	NSString* statusKey		= [NSString stringWithFormat:@"HVStatus"];
	NSMutableDictionary* mainFrameDictionary = [hvRecord objectForKey:mainFrameKey];
	return [[mainFrameDictionary objectForKey:statusKey] intValue];
}




@end
