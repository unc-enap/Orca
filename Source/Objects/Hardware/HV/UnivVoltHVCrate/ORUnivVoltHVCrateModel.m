//
//  ORUnivVoltHVCrateModel.m
//  Orca
//
//  Created by Jan Wouters.
//  Copyright © 2008 LANS, all rights reserved.
//-------------------------------------------------------------
// Command processing notes:
// 1) Communication between crate and computer is synchronous.
//    One command leads to one data return.  Sending two commands
//    without waiting for data returns leads to unpredictable
//    behavour.
// 2) Method queueCommand allows one to queue up multiple 
//    commands.
//			flags:
//			  mCmdsToProcess - total number of commands that
//					will be queued.  This flag is decremented
//					by one until all commands have been queued.
//			  mRetsToProcess - total number of data returns
//					expected.  Starts at zero and is incremented
//					by one for each command added to mCmdCmdQueue.
//			  mTotalCmds - Total cmds that will be processed
//
//			Structures:
//			  mCmdCmdQueue - Holds queued up commands and is used  
//					by sendSingleCommand to dequeue appropriate
//					command and send it.
//
//		Logic: when mRetsToProcess == mTotalCmds routine calls
//				sendSingleCommand to send out one command.

// 3) Method sendSingleCommand deques a single command from 
//		command queue and sends it to the HV crate.
//			Structures:
//			  mLastCmdIssued - Holds last command issued by this
//				routine.

// 4) method handleDataReturn is called by netsocket delegate method
//    dataAvailable.  This method processes data returned
//	  by HV crate.  (It uses the helper functions crateReturn and
//	  unitReturn to interpret the data from the crate and to place
//	  the return data for the unit onto the return queue.
//	  If command is a crate command, then only one data return
//	  is expected and data is not placed on queue.  For HV unit issue 
//	  multiple commands and thus expect multiple returns.  Commands are 
//    issued one at a time. When data returns stores it on return data
//	  queue and if any commands still need to be processed calls 
//    sendSingleCommand.
//
//	  dequeueAllReturns dequeues all returns stored on mReturnQueue.
//	  Sends out notification that new data is available which is handled
//	  by UNUnitVoltModel.m shortly after all notifications sent out.
//	
//			flags:
//			  mRetsToProcess - Number of returns that have not 
//				yet been processed.  Decremented by one each
//				time a new return is received.  (Check routine
//				setupReturnDict where decrement actually occurs.)
//
//			 Structures:
//			  mCmdRetQueue - Holds queued up commands and is used
//					by handleDataReturn to match command with return
//					data.
//			  mRetQueue - Holds dictionaries holding returned data.
//
//			Notes:
//			  Uses routine handleUnitReturn to actually queue up
//			  dictionary returns in mRetQueue.
//			  Uses routine 
//
//			LOOPING:
//			  If all expected returns not yet received, calls
//			  sendSingleCommand which dequeues next command from
//			  mCmdCmdQueue. Handles return when it comes and
//			  queues it up.  After last cmd-return data pair
//			  are issued callls routine dequeueAllReturns which
//			  sends the appropriate notifications out.
//			  
//-------------------------------------------------------------


#pragma mark •••Imported Files
#import "ORUnivVoltHVCrateModel.h"
#import "NetSocket.h"
#import "ORMacModel.h"
#import "ORQueue.h"

NSString* HVCrateIsConnectedChangedNotification			= @"HVCrateIsConnectedChangedNotification";
NSString* HVCrateIpAddressChangedNotification			= @"HVCrateIpAddressChangedNotification";
//NSString* ORUnivVoltHVCrateHVStatusChangedNotification			= @"ORUnivVoltHVCrateStatusChangedNotification";
NSString* HVCrateHVStatusAvailableNotification			= @"HVCrateHVStatusAvailableNotification";
NSString* HVCrateConfigAvailableNotification			= @"HVCrateConfigAvailableNotification";
NSString* HVCrateEnetAvailableNotification				= @"HVCrateEnetAvailableNotification";
NSString* HVUnitInfoAvailableNotification				= @"HVUnitInfoAvailableNotification";
NSString* HVSocketNotConnectedNotification				= @"HVSocketNotConnectedNotification";
NSString* HVShortErrorNotification						= @"HVShortErrorNotification";
NSString* HVLongErrorNotification						= @"HVLongErrorNotification";

NSString* HVCratePollTimeChanged						= @"HVCratePollTimeChanged";

// HV crate commands
NSString* ORHVkCrateHVStatus							= @"HVSTATUS";
NSString* ORHVkCrateConfig							    = @"CONFIG";
NSString* ORHVkCrateEnet								= @"ENET";
NSString* ORHVkCrateHVPanic								= @"IMOFF";
NSString* ORHVkCrateHVOn								= @"HVON";
NSString* ORHVkCrateHVOff								= @"HVOFF";

NSString* ORHVkNoReturn = @"No Return";

//NSString* ORHVkModuleDMP								= @"DMP";

// Entries in data return dictionary
NSString* UVkCmdId	 = @"CmdId";
NSString* UVkSlot	 = @"Slot";
NSString* UVkChnl    = @"Chnl";
NSString* UVkCommand = @"Command";
NSString* UVkReturn  = @"Return";
NSString* HVkErrorMsg = @"ErrorMsg";

@implementation ORUnivVoltHVCrateModel

#pragma mark •••initialization

- (id) init
{
	self = [super init];
	if ( self ) {
	}
	return ( self );
}

- (void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so that each crate can have its own version for drawing into.
    //---------------------------------------------------------------------------------------------------
    NSImage* aCachedImage = [NSImage imageNamed: @"UnivVoltHVCrateSmall"];
    NSImage* i = [[NSImage alloc] initWithSize: [aCachedImage size]];
    [i lockFocus];
    [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
    if([self powerOff]){
        NSAttributedString* s = [[[NSAttributedString alloc] initWithString: @"No Pwr"
                                                                 attributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                                     [NSColor redColor],NSForegroundColorAttributeName,
                                                                     [NSFont fontWithName: @"Geneva" size:10],NSFontAttributeName,
                                                                     nil]] autorelease]; 
        [s drawAtPoint:NSMakePoint(35,10)];
    }
    
    if([[self orcaObjects] count]){
        NSAffineTransform* transform = [NSAffineTransform transform];
		[transform translateXBy:5 yBy:15];
        [transform scaleXBy:.56 yBy:.62];
		[transform concat];
        NSEnumerator* e  = [[self orcaObjects] objectEnumerator];
        OrcaObject* anObject;
        while(anObject = [e nextObject])
		{
            BOOL oldHighlightState = [anObject highlighted];
            [anObject setHighlighted: NO];
            [anObject drawSelf: NSMakeRect(0, 0, 900, [[self image] size].height)];
            [anObject setHighlighted:oldHighlightState];
        }
    }
    [i unlockFocus];
    [self setImage: i];
    [i release];
    
    [[NSNotificationCenter defaultCenter]
                postNotificationName:OROrcaObjectImageChanged
                              object:self];
		
		

}

//---------------------------------------------------------------------------------------------------
- (void) awakeAfterDocumentLoaded
{
	@try {
		[super awakeAfterDocumentLoaded];
		if ( [ipAddress length] == 0 ) {
			NSString* tmpIPAddress = [NSString stringWithCString: kUnivVoltHVAddress encoding: NSASCIIStringEncoding ];
			[self setIpAddress: tmpIPAddress];
		}
		[self connect];
	}
	@catch (NSException *exception) {

		NSLog(@"ORUnivVoltHVCrateModel - awakeAfterDocumentLoaded: Caught %@: %@", [exception name], [exception  reason]);
	}
	@finally
	{
	}
	NSLog( @"ORUnivVoltHVCrateModel - awakeAfterDocumentLoaded\n" );
}


//---------------------------------------------------------------------------------------------------
- (void) dealloc
{
	[mCmdCmdQueue release];
	[mRetQueue release];
	
	[mSocket setDelegate:nil];
	[mSocket release];
	
    [super dealloc];
}

//---------------------------------------------------------------------------------------------------
- (void) makeMainController
{
    [self linkToController: @"ORUnivVoltHVCrateController"];
}

//---------------------------------------------------------------------------------------------------
- (void) makeConnectors
{
	//since CAMAC can have usb or pci adapters, we let the controllers make the connectors
}

//---------------------------------------------------------------------------------------------------
- (void) connectionChanged
{
}

#pragma mark •••Accessors

//---------------------------------------------------------------------------------------------------
- (NSString*) hvStatus
{ 
	if (mMostRecentHVStatus != nil )
	{
		return( mMostRecentHVStatus );
	}	
	return( ORHVkNoReturn );
}

//---------------------------------------------------------------------------------------------------
- (NSString *) ethernetConfig
{
	if (mMostRecentEnetConfig != nil )
	{
		return( mMostRecentEnetConfig );
	}	
	return( ORHVkNoReturn );
}

//---------------------------------------------------------------------------------------------------
- (NSString *) config
{
//	NSDictionary* queuedCommand = [mQueue dequeue];
//	NSString* command = [queuedCommand objectForKey: UVkCommand];
//	NSString* command = [mReturnToUnit objectForKey: UVkCommand];
	
//	if ( [command isEqualTo: ORHVkCrateConfig] )
	if (mMostRecentConfig != nil )
	{
		return( mMostRecentConfig );
	}	
	return( ORHVkNoReturn );
}

//---------------------------------------------------------------------------------------------------
- (NSString*) ipAddress
{
    return ipAddress;
}

//---------------------------------------------------------------------------------------------------
- (void) setIpAddress: (NSString *) anIpAddress
{
	if (!anIpAddress) anIpAddress = @"";
    [[[self undoManager] prepareWithInvocationTarget: self] setIpAddress: anIpAddress];
    
    [ipAddress autorelease];
    ipAddress = [anIpAddress copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName: HVCrateIpAddressChangedNotification object: self];
}

//---------------------------------------------------------------------------------------------------
- (NetSocket*) socket
{
	return mSocket;
}

/*- (NSDictionary*) returnDataToHVUnit
{
	return( mReturnToUnit );
}
*/

#pragma mark ***Crate Actions
//---------------------------------------------------------------------------------------------------
- (void) setSocket: (NetSocket*) aSocket
{
	if (aSocket != nil)
	{
		if( aSocket != mSocket && mSocket != nil ) 
		{
			[mSocket close];
			[mSocket release];
		}
					
		[aSocket retain];
		mSocket = aSocket;
	
 
	// setIsConnected sends notification message
		[mSocket setDelegate: self];
		mCmdQueueBlocked = NO;  // Now that socket is setup allow commands to be issued.
	}
	else
	{
		[self setIsConnected: NO];
	}
}
 
//---------------------------------------------------------------------------------------------------
- (void) obtainHVStatus
{
	[self sendCrateCommand: ORHVkCrateHVStatus];
}
 

- (void) hvPanic
{
	[self sendCrateCommand: ORHVkCrateHVPanic];
}

- (void) turnHVOn
{
	[self sendCrateCommand: ORHVkCrateHVOn];
}

- (void) turnHVOff
{
	[self sendCrateCommand: ORHVkCrateHVOff];
}

- (void) sendCrateCommand: (NSString*) aCommand
{
	[self queueCommand: 0 totalCmds: 1 slot: -1 channel: -1 command: aCommand];
}

//------------------------------------------------------------------------------------------------
// Queues commands onto mCmdCmdQueue.  If only one command is to be executed this routine calls
// sendSingleCommand to have it executed.
// For multiple commands queueCommands returns after each command is queued up until all commands
// are in queue.
// Note that commands that are sent to entire crate do not have slot and channel number set.  
// If command is only for slot then Sx is the form of the command where x is the slot number.  
// If command is directed at specific channel then command is of the form Sx.y where y is the 
// channel number. 
//
// (See top of this file for additional details.)
//------------------------------------------------------------------------------------------------
- (BOOL) queueCommand: (int) aCmdId			// 0 based.
			totalCmds: (int) aTotalCmds
				 slot: (int) aCurrentUnit 
			  channel: (int) aCurrentChnl 
			  command: (NSString*) aCommand 
{
	BOOL	queuedCmd = NO;
	
//	if ( aCmdId == 11 )
//		NSLog( @"id: %d, total: %d\n", aCmdId, aTotalCmds );
	
	@try
	{
		if ( !mCmdQueueBlocked ) {
			// see if all commands have been downloaded.
			if ( aTotalCmds > aCmdId )	{
			
				// Have first command - set up parameters
				if ( aCmdId == 0 ) {
					mCmdsToProcess = aTotalCmds;
//					mRetsToProcess = aTotalCmds;
					mTotalCmds = aTotalCmds;
				}
		
				if ( mCmdCmdQueue == nil ) {
					mCmdCmdQueue = [[ORQueue alloc] init];
					[mCmdCmdQueue retain];
				}
		
				// Create command dictionary object
				NSNumber* cmdId = [NSNumber numberWithInt: aCmdId];
				NSNumber* unitObj = [NSNumber numberWithInt: aCurrentUnit];
				NSNumber* chnlObj = [NSNumber numberWithInt: aCurrentChnl];
		
				NSMutableDictionary* commandObj = [NSMutableDictionary dictionaryWithCapacity: 4];
		
				[commandObj setObject: cmdId forKey: UVkCmdId];
				[commandObj setObject: unitObj forKey: UVkSlot];
				[commandObj setObject: chnlObj forKey: UVkChnl];
				[commandObj setObject: aCommand forKey: UVkCommand];

				mCmdsToProcess--;
				mRetsToProcess++;
				[mCmdCmdQueue enqueue: commandObj]; // Used to send out commands in order they were queued.
			
				// Debug line
				/*
			    NSLog( @"Queue cmd with id: %d - %@\n", aCmdId, aCommand );
				*/
				queuedCmd = YES;
//				NSLog( @"Queue cmd: %@ for cmd id: %d\n", aCommand, aCmdId );
		    }
		
		    // Queue has been filled so dequeue a single command.
		    if ( mCmdsToProcess == 0 && mTotalCmds == mRetsToProcess ) {
			   mCmdQueueBlocked = YES;  // Only block queue once all commands are issued.
			   [self sendSingleCommand];
		    }
		
			// return to calling routine so that it can queue up more commands.
		    else { 
				return( queuedCmd );
			}	// End of if related to whether we are sending a single command 
		}		// End of if determining whether we have processed all commands.
	}	
	
	@catch (NSException *exception) {

			NSLog(@"ORUnivVoltHVCrateModel - queueCommand: Caught %@: %@", [exception name], [exception  reason]);
	} 
	
	@finally
	{
	}
	
	return( queuedCmd );
}

/*- (void) sendCommandFromQueue
{
	NSDictionary* cmdDictObj = [mCmdCmdQueue dequeue];
	
	[self sendSingleCommand: cmdDictObj];
}
*/

//------------------------------------
//depreciated (11/29/06) remove someday
/*- (NSString*) crateAdapterConnectorKey
{
	return @"UnivVoltHV Crate Adapter Connector";
}
*/
//------------------------------------


#pragma mark •••Notifications
//------------------------------------------------------------------------------------------------
// Used to respond to data returns from HV crate.  Called by delegate method netSocket::
// dataAvailable. 
//
// This routine processes the returned data and places it on an output queue.  It calls the
// dequeAllRoutine which sends the appropriate notifications once all commands have been processed.  
// See sendCommand method for more details.  Only HVUnit
// needs to send multiple commands so only returns from the HVUnit are stored in retQueue.
//  
//------------------------------------------------------------------------------------------------
- (void) handleDataReturn: (NSData*) aSomeData
{
	NSString*	retSlotChnl;
	NSString*	returnFromSocket;
	NSString*	storedCmdStr;
	NSNumber*   retSlot;
	NSNumber*   retChnl;
	int			returnCode;
	bool		f_NotFound = YES;
	int			retSlotNum;
	int			retChnlNum;
	NSUInteger			scanLoc;
//	int			j;
	int			i;

	@try {		
	
		
		// Check Get data from Queued dictionary entry.
		NSString* queuedCommandStr = [mLastCmdIssued objectForKey: UVkCommand];
		NSArray* cmdTokens = [queuedCommandStr componentsSeparatedByString: @" "];
		if ( [cmdTokens count] > 1 ) {
			storedCmdStr = (NSString *) [cmdTokens objectAtIndex: 0];
		}
		else {
			storedCmdStr = queuedCommandStr;
		}
		
		NSNumber* cmdId = [mLastCmdIssued objectForKey: UVkCmdId];
		NSNumber* queuedSlot = [mLastCmdIssued objectForKey: UVkSlot];
		NSNumber* queuedChnl = [mLastCmdIssued objectForKey: UVkChnl];
	
		// Parse the returned data.
		returnFromSocket = [[self interpretDataFromSocket: aSomeData returnCode: &returnCode] retain];
		
//		NSLog( @"return from socket %@\n", returnFromSocket );
		NSCharacterSet* separators = [NSCharacterSet characterSetWithCharactersInString: @" \n"];
		NSArray* tokens = [returnFromSocket componentsSeparatedByCharactersInSet: separators]; 
// 		NSLog( @"return from socket '%@'  #tokens: %d\n", returnFromSocket, [tokens count] );
		
//added the following to get rid of a 10.4 compiler warning.   MAH 11/13/08 
#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4
		tokens = [returnFromSocket componentsSeparatedByString: @"\n"]; 
		NSString* temp = [tokens componentsJoinedByString:@" "];
		tokens = [temp componentsSeparatedByString: @" "]; 
#else
//		tokens = [returnFromSocket componentsSeparatedByCharactersInSet: separators]; 
		tokens = [returnFromSocket componentsSeparatedByCharactersInSet: separators]; 
#endif
// 		NSLog( @"return from socket '%@'  #tokens: %d\n", returnFromSocket, [tokens count] );

		// Process return code
		if ( returnCode != 1 )
		{
			NSString* fullErrorMsg = [tokens componentsJoinedByString: @" " ];
			NSString* shortErrorMsg = [NSString stringWithFormat: @"Hardware error %d (%@)\n", returnCode, fullErrorMsg];
			NSString* longErrorMsg = [NSString stringWithFormat: @"%@ - for cmd '%@' \n", shortErrorMsg, queuedCommandStr]; 
//			NSLog( @"handleDataReturn - longErrorMsg: '%@'\n", longErrorMsg );
			
			// Clear command and return queues.
			[mCmdCmdQueue removeAllObjects];
			[mRetQueue removeAllObjects];
			mCmdsToProcess = 0;
			mRetsToProcess = 0;
			mCmdQueueBlocked = NO;
			[mLastCmdIssued release];

			NSDictionary* shortErrorRet = [NSDictionary dictionaryWithObject:  shortErrorMsg forKey: HVkErrorMsg];
			[[NSNotificationCenter defaultCenter] postNotificationName: HVShortErrorNotification object: self userInfo: shortErrorRet];

			NSDictionary* longErrorRet = [NSDictionary dictionaryWithObject:  longErrorMsg forKey: HVkErrorMsg];
			[[NSNotificationCenter defaultCenter] postNotificationName: HVLongErrorNotification object: self userInfo: longErrorRet];
		}
		else
		{
		
			// 1) Make sure we have data returned from HV Crate.
			if ( [tokens count] > 0 )
			{
				NSString* retCommand = [tokens objectAtIndex: 0];
		
				// 2) if chnl > -1 then have a unit return rather than crate return
				i = 0;
				if ( [queuedSlot intValue] > -1 )
				{
			
					// Get slot and possibly channel of return data
					while ( f_NotFound && i < [tokens count] )
					{
						retSlotChnl = [tokens objectAtIndex: 1];
						char retChar = [retSlotChnl characterAtIndex: 0];
						if ( retChar == 'S' || retChar == 's' )
						{
					
							// Look for slot
							NSScanner* scannerForSlotAndChnl = [NSScanner scannerWithString: retSlotChnl];
							[scannerForSlotAndChnl setScanLocation: 1];
							[scannerForSlotAndChnl scanInt: &retSlotNum];
							retSlot = [NSNumber numberWithInt: retSlotNum];
							scanLoc = [scannerForSlotAndChnl scanLocation];
//						[scannerForSlotAndChnl setScanLocation: scanLoc + 1];


							BOOL hasPeriod = [scannerForSlotAndChnl scanString: @"." intoString: NULL];
						
							// Look for channel if present.
							if ( hasPeriod ) {
								[scannerForSlotAndChnl scanInt: &retChnlNum];
								retChnl = [NSNumber numberWithInt: retChnlNum];
							} else {
								retChnl = [NSNumber numberWithInt: -1];
							}
							f_NotFound = NO;
						} // End parsing address.
						i++;
					
					}	// End looking for address token
				}
		
				// 3) Verify that last command issued corresponds to data return.
				NSLog( @"ORUnivVoltHVCrateModel - Returned command '%@', recent command '%@'\n.", retCommand, queuedCommandStr );
				if ( [retCommand isEqualTo: storedCmdStr]  )
				{
					// Debug only. Print list of tokens.
/*				
						int j;
						for ( j = 0;  j < [tokens count]; j++ ) {
						NSString* object = [tokens objectAtIndex: j];
						NSLog( @"Token ( %d ) string: %@\n", j, object );
					}
*/			
					// 4) Crate only returns.
					if ( [queuedChnl intValue] == -1 )
						[self handleCrateReturn: retCommand retString: returnFromSocket retTokens: tokens];
					
					// 5) Handle return to HV unit.
					else if ( [retChnl intValue] > -1 )
					{
						[self handleUnitReturn: cmdId slot: retSlot channel: retChnl command: retCommand retTokens: tokens];
					}  // End if processing crate and Unit returns.
				
					// Decrement returns to process.
					mRetsToProcess--;

				}      // End if looking if returned command equals queued command.
			
				// 6) No more returns expected so deque all the data.
				if ( mRetsToProcess == 0 )
				{
					[self dequeueAllReturns];
				}
			
				// 7) Expect more returns so issue next command.
				else 
				{
					[self sendSingleCommand];
				}
			}		// End of encountering error.
		}		    // End if verifying that we actually have data.
	}
	
	@catch (NSException *exception) {

			NSLog(@"ORUnivVoltHVCrateModel - handleDataReturn: Caught %@: %@", [exception name], [exception  reason]);
	}
	
	@finally {	
		if ( returnFromSocket != nil )
		[returnFromSocket release];
	}
	return;
}

//------------------------------------------------------------------------------------------------
// Handles crate return.
//------------------------------------------------------------------------------------------------
- (void) handleCrateReturn: (NSString*) aCrateCmd retString: aRetString retTokens: aRetTokens
{
	NSNumber* slotForCrate = [NSNumber numberWithInt: -1];
	NSNumber* chnlForCrate = [NSNumber numberWithInt: -1];
	[self setupReturnDict: slotForCrate channel: chnlForCrate command: aCrateCmd  returnString: aRetTokens];

	if ( [aCrateCmd isEqualTo: ORHVkCrateHVStatus] || [aCrateCmd isEqualTo: ORHVkCrateHVOn]
			|| [aCrateCmd isEqualTo:  ORHVkCrateHVOff] || [aCrateCmd isEqualTo: ORHVkCrateHVPanic] ) {

		if ( mMostRecentHVStatus != nil ) [mMostRecentHVStatus release];
		mMostRecentHVStatus = [[NSString stringWithString: aRetString] retain];					
		NSLog( @"ORUnivVoltHVCrateModel - Send notification about HVStatus change.");
		[[NSNotificationCenter defaultCenter] postNotificationName: HVCrateHVStatusAvailableNotification object: self];
	}
				
	else if ( [aCrateCmd isEqualTo: ORHVkCrateConfig] ) {
		if ( mMostRecentConfig != nil ) [mMostRecentConfig release];
			mMostRecentConfig = [[NSString stringWithString: aRetString] retain];
			NSLog( @"ORUnivVoltHVCrateModel - Send notification about Config.");
			[[NSNotificationCenter defaultCenter] postNotificationName: HVCrateConfigAvailableNotification object: self];
	}
		
	else if ( [aCrateCmd isEqualTo: ORHVkCrateEnet] ) {
		if ( mMostRecentEnetConfig != nil ) [mMostRecentEnetConfig release];
			mMostRecentEnetConfig = [[NSString stringWithString: aRetString] retain];
			NSLog( @"ORUnivVoltHVCrateModel - Send notification about Enet Config.");
			[[NSNotificationCenter defaultCenter] postNotificationName: HVCrateEnetAvailableNotification object: self];
	} // end if statement about which command is applicable
}

//---------------------------------------------------------------------------------------------------
// Places return data onto queue for HV Unit.
//---------------------------------------------------------------------------------------------------
- (void) handleUnitReturn: (NSNumber *) aCmdId
				     slot: (NSNumber *) aRetSlot 
                  channel: (NSNumber *) aRetChnl 
				  command: (NSString *) aCommand 
				retTokens: (NSArray *) aRetTokens
{
	// Create return dictionary.
	if ( mRetQueue == nil ) {
		mRetQueue = [[ORQueue alloc] init];
		[mRetQueue retain];
	}
	
	// queue return.
	if ( mRetsToProcess > 0 ) {
		NSDictionary* retDictObj = [self setupReturnDict: aRetSlot 
		                                         channel: aRetChnl 
												 command: aCommand 
											returnString: aRetTokens];

		// Place return on return queue.		
		[mRetQueue enqueue: retDictObj];
	}		
}

- (void) obtainConfig
{	
	@try
	{
		[self sendCrateCommand: ORHVkCrateConfig];
	}
	
	@catch (NSException *exception) {

			NSLog( @"ORUnivVoltHVCrateModel - obtainConfig: Caught %@: %@", [exception name], [exception  reason] );
	} 
	
	@finally
	{
	//	[command release];
	}
}

- (void) obtainEthernetConfig
{	
	@try
	{
		NSString* command = [NSString stringWithFormat: @"%@",ORHVkCrateEnet];	
		[self sendCrateCommand: command];
			
		// Write the command.
		
		

//		mLastCommand = eUVEnet;	
	}
	@catch (NSException *exception) {

		NSLog( @"ORUnivVoltHVCrateModel - obtainEthernetConfig: Caught %@: %@", [exception name], [exception  reason] );
	} 
	
	@finally
	{
	//	[command release];
	}
}

- (void) connect
{
	@try {
	
		if (!mIsConnected) {
		
			// setSocket method will send out notification.
			[self setSocket: [NetSocket netsocketConnectedToHost: ipAddress port: kUnivVoltHVCratePort]];	
		}
	}
	@catch (NSException *exception) {

			NSLog( @"ORUnivVoltHVCrateModel - connect: Caught %@: %@", [exception name], [exception  reason] );
	}
	@finally{
	} 
}


- (void) disconnect
{
	if (mIsConnected ) 
	{	
		[mSocket close];
//		[mSocket release];
		[self setSocket: nil];
	}
}


#pragma mark •••Utilities
//------------------------------------------------------------------------------------------
// Dequeues all data returns sending notifications out.  These returns are queued up in
// handleDataReturn as data comes in from HV crate. 
//------------------------------------------------------------------------------------------
- (void) dequeueAllReturns
{	
	if ( mRetQueue != nil )
	{
		while ( ![mRetQueue isEmpty] )
		{
			NSDictionary* retDictObj = [mRetQueue dequeue];
			// For debugging
	/*
			NSNumber* slotObj = [retDictObj objectForKey: UVkSlot];
			NSNumber* chnlObj = [retDictObj objectForKey: UVkChnl];
			NSString* command = [retDictObj objectForKey: UVkCommand];
			NSLog( @"Send return data notification about slot: %d, chnl: %d, command '%@'\n", 
		       [slotObj intValue], [chnlObj intValue], command );
*/
			[[NSNotificationCenter defaultCenter] postNotificationName: HVUnitInfoAvailableNotification object: self userInfo: retDictObj];
		}
	}
	
	// unblock cmd queue since all cmds processed.
	mTotalCmds = 0;
	mCmdQueueBlocked = NO;
}

//------------------------------------------------------------------------------------------
// \note:	Data is returned as follows:
//			012345678901234567890123456789012345678901234567890
//			     1 HVSTATUS
//          C    1 DMP S0.10
//
//			Where column 0 is either blank or has the letter C.  C means that more data follows
//			this line.  The next 4 columns form the return code: 
//			1 - last command succesful.
//			2 - Not used.
//			3 - Crate is in local command.  Need to turn key.
//			4 - Last command a PANIC.
//			
//------------------------------------------------------------------------------------------
- (NSString*) interpretDataFromSocket: (NSData*) aDataObject returnCode: (int*) aReturnCode
{
	const int	NUMcCODENUM = 5;
	NSString*	returnStringFromSocket;
	NSString*	returnCodeAsString;
	char		returnBufferArray[ 257 ];	// 0 Byte is continuation character C is continuation.
	char		returnBufferString[ 257 ];
	char		returnCodeArray[ NUMcCODENUM + 1  ];
//	char		displayArray[ 2 ];
	uint32_t			lengthOfReturn = 0;
	int			i;
	int			responseIndex;
	int			j;
	int			nChar;
	BOOL		newLine;
	BOOL		haveCode;
	
	
	@try
	{
		// Get amount of data and data itself.
		lengthOfReturn = (uint32_t)[aDataObject length];
		[aDataObject getBytes: returnBufferArray length: lengthOfReturn];
		NSLog( @"ORUnivVoltHVCrateModel - Return string '%s'  length: %d\n", returnBufferArray, lengthOfReturn );
		
		returnCodeArray[ NUMcCODENUM ] = '\0';
		
		// Zero return array
		for ( i = 0; i < lengthOfReturn; i++ ) {
			returnBufferString[ i ] = '\0';
		}
		
/*
		displayArray[ 1 ] = '\0';
		for ( i = 0; i < lengthOfReturn; i++ ) {
			displayArray[ 0 ] = returnBufferArray[ i ];
			if ( returnBufferArray[ i ] == '\0' ) 
				displayArray[ 0 ] = '-';
			else if ( returnBufferArray[ i ] == '\n' )
				displayArray[ 0 ] = '/';

			NSLog( @"Interpreted.  Char( %d ): %s\n", i, displayArray );
		}
*/		
		nChar = 0;
				
		// Find the C and \0 in the character array.  Replace them with \n except for the last
		//\0 which stays.
		// Also find return code which is number consisting of 4 bits at front of return string.
		responseIndex = 0;
		j = -1;
		newLine = YES;
		haveCode = NO;
		
		for ( i = 0; i < lengthOfReturn; i++ )
		{
			if ( !haveCode && !newLine ) {
				if ( returnBufferArray[ i ] == '\0' ) {
					if ( i == lengthOfReturn - 1 ) {
						returnBufferString[ responseIndex++ ] = '\0';
					} 
					else {
						returnBufferString[ responseIndex++ ] = '\n';
					}
					newLine = true;						
				} 
				else {
					returnBufferString[ responseIndex++ ] = returnBufferArray[ i ];
				nChar++;
				}
			}

			if ( haveCode ) {
				j++;
				if ( j < NUMcCODENUM ) {
					returnCodeArray[ j ] = returnBufferArray[ i ];
				} else
				{
					haveCode = NO;
					j = -1;
				}
			}
			
			if ( newLine ) {
				if ( returnBufferArray[ i ] == 'C' || returnBufferArray[ i ] == ' ' ) {
					newLine = NO;
					haveCode = YES;
				}
			}						
		}
		
		// Debugging display each character in returnBufferString.		
/*
		displayArray[ 1 ] = '\0';
		for ( i = 0; i < nChar; i++ ) {
			displayArray[ 0 ] = returnBufferString[ i ];
			NSLog( @"Char( %d ): %s\n", i, displayArray );
		}
*/			

		// Get the return code as both number and string.
		returnCodeAsString = [[NSString alloc] initWithBytes: returnCodeArray length: 5 encoding: NSASCIIStringEncoding];
		*aReturnCode = [returnCodeAsString intValue];
		
//		NSLog( @"Return Code: %@, number: %d\n", returnCodeAsString, *aReturnCode);
		
		// Convert modified char array to string.
		returnStringFromSocket = [[[NSString alloc] initWithFormat: @"%s\n", returnBufferString] autorelease];
//		NSLog( @"Full return string:\n %@\n", returnStringFromSocket );
   }
	
	@catch (NSException *exception) {

		NSLog( @"ORUnivVoltHVCrateModel - interpretDataFromSocket: Caught %@: %@\n", [exception name], [exception  reason] );
	} 
	
	@finally{
//		[returnCodeAsString release];
	}
	
	return ( returnStringFromSocket );
}

- (BOOL) isConnected
{
	return mIsConnected;
}


- (void) setIsConnected: (BOOL) aFlag
{
    mIsConnected = aFlag;
//	[self setReceiveCount: 0];
    [[NSNotificationCenter defaultCenter] postNotificationName: HVCrateIsConnectedChangedNotification object: self];
}

- (NSDictionary*) setupReturnDict: (NSNumber*) aSlotNum 
                          channel: (NSNumber*) aChnlNum 
				          command: (NSString*) aCommand 
			         returnString: (NSArray*) aRetTokens
{
	NSLog( @"ORUnivVoltHVCrateModel - Send notification data return - slot: %d, chnl: %d\n", [aSlotNum intValue], [aChnlNum intValue]);
	NSArray *keys = [NSArray arrayWithObjects: UVkSlot, UVkChnl, UVkCommand, UVkReturn, nil];
	NSArray *data = [NSArray arrayWithObjects:  aSlotNum, aChnlNum, aCommand, aRetTokens, nil];
	NSDictionary* retDictObj = [[NSDictionary alloc] initWithObjects: data forKeys: keys];
	[retDictObj autorelease];
	
	// Decrement counter indicating how many commands one still has to process before dequeuing data.
//	mRetsToProcess--;
	
	return( retDictObj);
}

// Actually takes command off of queue and sends it to the HV Crate.
- (void) sendSingleCommand
{
	NSString* fullCommand = nil;
	NSDictionary* cmdDictObj = 0;
	if ( [mCmdCmdQueue isEmpty] && mCmdsToProcess > 0)
	{
		NSLog( @"ORUnivVoltHVCrateModel - Error  - sendSingleCommand has empty cmd queue even though there should still be %d cmds to process.\n",
			mCmdsToProcess );
	}
	
	// Pop command off of queue and store it in mLastCmdIssued variable.
	else
	{	
		cmdDictObj = [mCmdCmdQueue dequeue];
		if ( mLastCmdIssued != nil )
		{
			[mLastCmdIssued release];
		}
		mLastCmdIssued = cmdDictObj;
		[mLastCmdIssued retain];
	}
	
	if ( cmdDictObj != nil )
	{
		fullCommand = [cmdDictObj objectForKey: UVkCommand];
		const char* buffer = [fullCommand cStringUsingEncoding: NSASCIIStringEncoding];
		
		NSLog( @"ORUnivVoltHVCrateModel - SendCommandBasic - Command '%s',  length:%d\n", buffer, [fullCommand length] + 1 );
		if (mSocket != nil )
		{
			[mSocket write: buffer length: [fullCommand length] + 1];	
		}
		else
		{
			NSString* errorMsg = [NSString stringWithFormat: @"Socket not connected to Crate.\n"];
			NSDictionary* errorMsgDict = [NSDictionary dictionaryWithObject: errorMsg forKey: HVkErrorMsg];
			[[NSNotificationCenter defaultCenter] postNotificationName: HVSocketNotConnectedNotification object: self userInfo: errorMsgDict];
			mRetsToProcess = 0;
			mCmdsToProcess = 0;
		}
	}
}

#pragma mark •••Delegate Methods
- (void) netsocketConnected: (NetSocket*) inNetSocket
{
	@try
	{
		if(inNetSocket == mSocket){
			[self setIsConnected: [mSocket isConnected]];
		}
	}
	@catch (NSException *exception) {

		NSLog( @"ORUnivVoltHVCrateModel - netsocketConnected: Caught %@: %@", [exception name], [exception  reason] );
	}
	@finally
	{
	}

}

- (void) netsocketDisconnected: (NetSocket*) inNetSocket
{
	@try {
		if (inNetSocket == mSocket) {

			[self setIsConnected: NO];
			[mSocket autorelease];
			mSocket = nil;
		}
	}
	@catch (NSException *exception) {

		NSLog( @"ORUnivVoltHVCrateModel - netsocketConnected: Caught %@: %@", [exception name], [exception  reason] );
	}
	@finally
	{
	}

}


- (void) netsocket: (NetSocket*) anInNetSocket dataAvailable: (NSUInteger) anInAmount
{
    @try {
		if (anInNetSocket == mSocket) {
			[self handleDataReturn: [anInNetSocket readData]];
		}
	}
	@catch (NSException *exception) {

		NSLog( @"ORUnivVoltHVCrateModel - netsocketConnected: Caught %@: %@", [exception name], [exception  reason] );
	}
	@finally
	{
	}

}


#pragma mark ***Archival
// Encode decode variable names.
static NSString*	ORUnivVoltHVCrateIPAddress		= @"ORUnivVoltHVCrateIPAddress";

- (id) initWithCoder: (NSCoder*) aDecoder
{
    self = [super initWithCoder: aDecoder];
    
    [[self undoManager] disableUndoRegistration];
	[self setIpAddress: [aDecoder decodeObjectForKey: ORUnivVoltHVCrateIPAddress]];
    [[self undoManager] enableUndoRegistration];    
		
    return self;
}

- (void)encodeWithCoder: (NSCoder*) anEncoder
{
    [super encodeWithCoder: anEncoder];
    [anEncoder encodeObject: ipAddress forKey: ORUnivVoltHVCrateIPAddress];
}

// Unused code - getting crate return data from HV unit return.  Did work - but simplified.
/*		NSArray* tokens = [mReturnToUnit objectForKey: UVkReturn];
		int i;
		NSString* result = [NSString stringWithString: [tokens objectAtIndex: 0]];
		for (i = 1; i < [tokens count]; i++ )
		{	
			result = [result stringByAppendingFormat: @" %@", [tokens objectAtIndex: i]];
		}
		
		// setup mMostRecentConfig parameter which holds last config.
		if ( mMostRecentConfig != nil )
			[mMostRecentConfig release];
		
			
		mMostRecentConfig = [NSString stringWithString: result];
		[mMostRecentConfig retain];
		return( result );
	}
	else if ( mMostRecentConfig != nil )
		return( mMostRecentConfig );
*/

/* Old version of - (void) handleDataReturn: (NSData) aSomeData
{
	int			i;
	int			returnCode;
	bool		f_NotFound;
	int			retSlot;
	int			scanLoc;
	int			retChnl;
	
	f_NotFound = YES;
	i = 0;

	// Get oldest command
	NSDictionary* recentCommand = [mQueue dequeue];
	
	// Check that it matches return.
	NSString* command = [recentCommand objectForKey: UVkCommand];
	NSNumber* chnlNum = [recentCommand objectForKey: UVkChnl];
	NSNumber* slotNum = [recentCommand objectForKey: UVkUnit];
	
	// For commands that return ascii data parse the data.
	mReturnFromSocket = [self interpretDataFromSocket: aSomeData returnCode: &returnCode];
	NSCharacterSet* separators = [NSCharacterSet characterSetWithCharactersInString: @" \n"];
	NSArray* tokens = [mReturnFromSocket componentsSeparatedByCharactersInSet: separators]; 
	
	// Get slot and channel
	while ( f_NotFound && i < [tokens count] )
	{
		NSString* slotChnl = [tokens objectAtIndex: 1];
		char retChar = [slotChnl characterAtIndex: 0];
		if ( retChar == 'S' || retChar == 's' )
		{
			NSScanner* scannerForSlotAndChnl = [NSScanner scannerWithString: slotChnl];
			[scannerForSlotAndChnl setScanLocation: 1];
			[scannerForSlotAndChnl scanInt: &retSlot];
			scanLoc = [scannerForSlotAndChnl scanLocation];
			[scannerForSlotAndChnl setScanLocation: scanLoc + 1];
			[scannerForSlotAndChnl scanInt: &retChnl];
			f_NotFound = NO;
		}
	}
	
	
	if ( [tokens count] > 0 )
	{
		NSString* retCommand = [tokens objectAtIndex: 0];
		NSLog( @"Returned command '%@', recent command '%@'.", retCommand, command );
		if ( [retCommand isEqualTo: command]  )
		{
			// Debug only.
			for ( i = 0; i < [tokens count]; i++ )
			{
				NSString* object = [tokens objectAtIndex: i];
				NSLog( @"Token ( %d ) string: %@\n", i, object );
			}
	
	
			NSString* command = [tokens objectAtIndex: 0];
			NSLog( @"Queue command %@, return command %@", recentCommand, tokens[ 0 ] );
	
			if ( [chnlNum intValue] < 0 ) { // crate command
		
				// crate only returns.
				if ( [command isEqualTo: ORHVkCrateHVStatus] )
				{
					NSLog( @"Send notification about HVStatus.");
				[[NSNotificationCenter defaultCenter] postNotificationName: HVCrateHVStatusAvailableNotification object: self];
				
				}
				else if ( [command isEqualTo: ORHVkCrateConfig] )
				{
					NSLog( @"Send notification about Config.");
					[[NSNotificationCenter defaultCenter] postNotificationName: HVCrateConfigAvailableNotification object: self];
				}
		
				else if ( [command isEqualTo: ORHVkCrateEnet] )
				{
					NSLog( @"Send notification about Enet.");
					[[NSNotificationCenter defaultCenter] postNotificationName: HVCrateConfigAvailableNotification object: self];
				}
				
				else if ( [command isEqualTo: ORHVkHVOn] )
				{
					NSLog( @"Send notification about HV being turned on.");
					[[NSNotificationCenter defaultCenter] postNotificationName: HVCrateHVStatusAvailableNotification object: self];
				}
				
				else if ( [command isEqualTo: ORHVkHVOff] )
				{
					NSLog( @"Send notification about HV being turned off.");
					[[NSNotificationCenter defaultCenter] postNotificationName: HVCrateHVStatusAvailableNotification object: self];
				}

				else if ( [command isEqualTo: ORHVkHVPanic] )
				{
					NSLog( @"Send notification about HV PANIC.");
					[[NSNotificationCenter defaultCenter] postNotificationName: HVCrateHVStatusAvailableNotification object: self];
				}
			}
		
			// notify HV unit about return from command.
			else
			{
				
				NSMutableDictionary* channelIdentification = [[NSMutableDictionary alloc] init]; 
				[channelIdentification setObject: slotNum forKey: UVkUnit];
				[channelIdentification setObject: chnlNum forKey: UVkChnl];
				[channelIdentification setObject: command forKey: UVkCommand];
				NSDictionary* channelIdObj = [NSDictionary dictionaryWithDictionary: channelIdentification];
				NSLog( @"Send notification about HV Unit - slot: %d, chnl: %d\n", slotNum, chnlNum);
				[[NSNotificationCenter defaultCenter] postNotificationName: ORUnitInfoAvailableNotification object: self userInfo: channelIdObj];
			}
		}
	}

//		if ( mLastError != Nil ) [mLastError release];
//		[mLastError stringWithSting: @"Returned data from HV unit '%s' with last command queue '%s'.", 
//		NSLog( mLastError 
	return;
	*/

- (int) maxNumberOfObjects { return 16; }
- (int) objWidth		 { return 16; }

@end
