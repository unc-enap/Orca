//
//  SNOModel.m
//  Orca
//
//  Created by H S  Wan Chan Tseung on 11/18/11.
//  Copyright (c) 2011 CENPA, University of Washington. All rights reserved.
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
#import "SNOModel.h"
#import "ORAxis.h"
#import "ORDataPacket.h"
#import "ORRunModel.h"
#import "OrcaObject.h"
#import "SNOConnection.h"
#import "YAJL/YAJL.h"
#import "ORTaskSequence.h"
#import "ORTimeRate.h"

NSString* ORSNOChartXChangedNotification            = @"ORSNOChartXChangedNotification";
NSString* ORSNOChartYChangedNotification            = @"ORSNOChartYChangedNotification";
NSString* slowControlTableChanged					= @"slowControlTableChanged";
NSString* slowControlConnectionStatusChanged		= @"slowControlConnectionStatusChanged";
NSString* totalRatePlotChanged                      = @"totalRatePlotChanged";

@interface SNOModel (private)
- (void) _setUpPolling;
@end

@implementation SNOModel

#pragma mark •••Initialization

- (id) init //designated initializer
{
    self = [super init];
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	
    [xAttributes release];
    [yAttributes release];
    [tableEntries release];
    [slowControlMap release];
    [iosCards release];
    [ioServers release];
    [super dealloc];
}

- (void) wakeUp
{
    if([self aWake])return;
    [super wakeUp];
}

- (void) sleep
{
    [super sleep];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"SNO"]];
}

- (void) makeMainController
{
    [self linkToController:@"SNOController"];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(runStatusChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(runAboutToStart:)
                         name : ORRunAboutToStartNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(runEnded:)
                         name : ORRunStoppedNotification
                       object : nil];
	
}



- (void) runStatusChanged:(NSNotification*)aNote
{
    int running = [[[aNote userInfo] objectForKey:ORRunStatusValue] intValue];
    if(running == eRunStopped){
        //[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(collectRates) object:nil];
        //[[self detector] unregisterRates];
    }
    else {
    }
}

- (void) runAboutToStart:(NSNotification*)aNote
{
}

- (void) runEnded:(NSNotification*)aNote
{		
}


#pragma mark •••Accessors
- (NSDictionary*)   xAttributes
{
    return xAttributes;
}

- (NSDictionary*)   yAttributes
{
    return yAttributes;
}

- (void) setYAttributes:(NSDictionary*)someAttributes
{
    [yAttributes release];
    yAttributes = [someAttributes copy];
}

- (void) setXAttributes:(NSDictionary*)someAttributes
{
    [xAttributes release];
    xAttributes = [someAttributes copy];
}

- (ORTimeRate *) parameterRate
{
    return parameterRate;
}

- (ORTimeRate *) totalDataRate
{
    return totalDataRate;
}

- (float) totalRate
{
    return [[SNOMonitoredHardware sharedSNOMonitoredHardware] xl3TotalRate];
}

- (void) getRunTypesFromOrcaDB:(NSMutableArray *)runTypeList
{
    [runTypeList insertObject:@"---" atIndex:0];
    
    NSHTTPURLResponse *response = nil;
	NSError *connectionError;
	
	NSString *urlName=[[NSString alloc] initWithFormat:
                       @"http://snoplus:scintillate@snotpenn01.snolab.ca:5984/orcatest/_design/run_type/_view/all?group=True&group_level=1"];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:
                                    [NSURL URLWithString:urlName] cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval:1];	
	NSData *responseData = [[NSData alloc] initWithData:
                            [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&connectionError]];
    
   // if (responseData!=nil){
        NSString *jsonStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        NSDictionary *runTypesView = [[NSDictionary alloc] initWithDictionary:[jsonStr yajl_JSON]];
        NSArray *runTypes = [[NSArray alloc] initWithArray:[runTypesView objectForKey:@"rows"]];

        int numtypes;
        for(numtypes=0;numtypes<[runTypes count];numtypes++){
            [runTypeList insertObject:[[[runTypes objectAtIndex:numtypes] objectForKey:@"key"] objectAtIndex:0] atIndex:numtypes+1];
        }
            
        [runTypes release];
        [jsonStr release];
        [runTypesView release];
  //  }
    
    [urlName release];
    [responseData release];
}

- (void) setRunTypeName:(NSString *)aType
{
    [aType retain];
    [runType release];
    runType = aType;
}

- (NSString *) getRunType
{
    return runType;
}

- (BOOL) isPlottingGraph
{
    return isPlottingGraph;
}

//monitor
- (void) getDataFromMorca
{
	[[SNOMonitoredHardware sharedSNOMonitoredHardware] readXL3StateDocumentFromMorca:@"getXL3State"];
	
	if (xl3PollingState > 0 && pollXl3) {
		[self performSelector:@selector(getDataFromMorca) withObject:nil afterDelay:xl3PollingState];
    }
}

- (void) getXl3Rates
{
    [[SNOMonitoredHardware sharedSNOMonitoredHardware] readXL3StateDocumentFromMorca:@"getXL3Rates"];
    
    if (isPollingXl3TotalRate) {
        float totalRate = [[SNOMonitoredHardware sharedSNOMonitoredHardware] xl3TotalRate];
        [totalDataRate addDataToTimeAverage:totalRate];
        [[NSNotificationCenter defaultCenter] postNotificationName:totalRatePlotChanged object:self];
        [self performSelector:@selector(getXl3Rates) withObject:nil afterDelay:2];
    }
}

- (void) setXl3Polling:(int)aState
{
	xl3PollingState = aState;
}

- (void) startXl3Polling
{   
	if (xl3PollingState == 0){
		NSLog(@"polling Morca once\n");
		pollXl3 = false;
		[self getDataFromMorca];
	} else if (xl3PollingState > 0 && !pollXl3){
		NSLog(@"Polling from Morca database...\n");
  
        if (parameterRate) [parameterRate release], parameterRate = nil;
        
        isPlottingGraph = false;
        parameterRate = [[ORTimeRate alloc] init];
        [parameterRate setSampleTime:xl3PollingState];

		pollXl3 = true;
        [self getDataFromMorca];
	}
}

- (void) stopXl3Polling
{
	pollXl3 = false;
    isPlottingGraph = false;
	NSLog(@"Stopped polling Morca database\n");
}

- (void) releaseParameterRate
{
    if (parameterRate) [parameterRate release];
}

- (void) collectSelectedVariable
{
    isPlottingGraph = true;
    
    if (pollXl3){
        float value = [[SNOMonitoredHardware sharedSNOMonitoredHardware] currentValueForSelectedHardware] ;
        [parameterRate addDataToTimeAverage:value];
        [self performSelector:@selector(collectSelectedVariable) withObject:nil afterDelay:xl3PollingState];
        //NSLog(@"value %f\n",value);
    }
}

- (void) startTotalXL3RatePoll
{
    if (!isPollingXl3TotalRate) {
        isPollingXl3TotalRate = true;
        if (totalDataRate) [totalDataRate release], totalDataRate = nil;
        totalDataRate = [[ORTimeRate alloc] init];
        [totalDataRate setSampleTime:2];
        
        [[SNOMonitoredHardware sharedSNOMonitoredHardware] collectingXL3Rates:YES];
        [self getXl3Rates];
    } 
}

- (void) stopTotalXL3RatePoll
{
    if (totalDataRate) [totalDataRate release], totalDataRate = nil;
    isPollingXl3TotalRate = false;
    [[SNOMonitoredHardware sharedSNOMonitoredHardware] collectingXL3Rates:NO];
}

//slow control
- (void) setSlowControlPolling:(int)aState
{
	slowControlPollingState = aState;
}

- (void) startSlowControlPolling
{
	if (slowControlPollingState > 0 && !pollSlowControl){
		NSLog(@"Monitoring slow control...\n");
		pollSlowControl = true;
		
		[self performSelector:@selector(readAllVoltagesFromIOServers) 
				   withObject:nil afterDelay:slowControlPollingState];
	}
}

- (void) stopSlowControlPolling
{
	pollSlowControl = false;
	NSLog(@"Stopped monitoring slow control\n");
}

- (void) setIoserverPasswd:(NSString *)aString
{
    [aString retain];
    [iosPasswd release];
    iosPasswd = aString;
}

- (void) setIoserverUsername:(NSString *)aString
{
    [aString retain];
    [iosUsername release];
    iosUsername = aString;
}

- (void) forwardPorts
{
    //get all ios IP addresses
    NSHTTPURLResponse *response = nil;
    NSError *connectionError;
    NSString *urlName=[[NSString alloc] initWithString:@"http://snoplus:scintillate@snotpenn01.snolab.ca:5984/slow_control/_design/hwinfo/_view/ios"];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlName] cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval:1];
    NSData *responseData = [[NSData alloc] initWithData:[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&connectionError]];
	NSString *jsonStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
	NSDictionary *jsonServer = [[NSDictionary alloc] initWithDictionary:[jsonStr yajl_JSON]];
	NSArray *serverRows = [[NSArray alloc] initWithArray:[jsonServer objectForKey:@"rows"]];
    
    int i;
    for(i=0;i<[[jsonServer objectForKey:@"total_rows"] intValue];++i){
    
        //loop through all ios IPs and forward local ports 8000, 8001 and 8002 to IOS0, IOS1 and IOS2 respectively
        NSString* ipaddr=[[[serverRows objectAtIndex:i] objectForKey:@"value"] valueForKey:@"ipaddr"];
        NSString* hostname=[[[serverRows objectAtIndex:i] objectForKey:@"value"] valueForKey:@"hostname"];
        NSString* resourcePath = [[NSBundle mainBundle] resourcePath];
        int wmport = [[[[serverRows objectAtIndex:i] objectForKey:@"value"] valueForKey:@"wmport"] intValue];
        NSString* localport = [NSString stringWithFormat:@"%i",wmport+[[hostname substringWithRange:NSMakeRange(3,1)] intValue]];
        
        ORTaskSequence *aSequence = [ORTaskSequence taskSequenceWithDelegate:self];
        
        if ([ipaddr length] != 0){
            [aSequence addTask:[resourcePath stringByAppendingPathComponent:@"portForwardScript"] 
                     arguments:[NSArray arrayWithObjects:iosUsername,iosPasswd,ipaddr,localport,nil]];    
            //[aSequence setTextToDelegate:YES];
            [aSequence launch];
        }
    }
    
    [jsonStr release];
    [urlName release];
    [responseData release];
    [jsonServer release];
    [serverRows release];
}

- (void) connectToIOServer
{ 
    pollSlowControl=false;
    
    //forward local ports
    [self forwardPorts];

	NSString *aString=@"Connecting...";
	[self setSlowControlMonitorStatusString:aString];
	[self setSlowControlMonitorStatusStringColor:[NSColor blackColor]];
	[[NSNotificationCenter defaultCenter] postNotificationName:slowControlConnectionStatusChanged object:self];

	if (tableEntries) [tableEntries release];	
	tableEntries = [[NSMutableArray alloc] initWithCapacity:kNumSlowControlParameters];
    
    //get parameter name list, including units and display indices
	
    SNOConnection *connection = [[SNOConnection alloc] init];
    [connection setDelegate:self];
    [connection setDelegateAction:@"getSlowControlMap"];
    [connection get:@"http://snoplus:scintillate@snotpenn01.snolab.ca:5984/slow_control/_design/hwinfo/_list/hwmap/mapgen?include_docs=true"];
    [connection release];

    SNOConnection *connection2 = [[SNOConnection alloc] init];
    [connection2 setDelegate:self];
    [connection2 setDelegateAction:@"getIOSCards"];
    [connection2 get:@"http://snoplus:scintillate@snotpenn01.snolab.ca:5984/slow_control/_design/hwinfo/_view/card"];
    [connection2 release];
    
    SNOConnection *connection3 = [[SNOConnection alloc] init];
    [connection3 setDelegate:self];
    [connection3 setDelegateAction:@"getIOS"];
    [connection3 get:@"http://snoplus:scintillate@snotpenn01.snolab.ca:5984/slow_control/_design/hwinfo/_view/ios"];
    [connection3 release];

}

- (void) readAllVoltagesFromIOServers
{
	//read data from all IOS, cards and store in dictionary.
    //IOS servers give data card-wise, therefore have to loop through all available cards via iocardview in the slow control DB.
    //IOS server ips are stored in ioserver documents.
	
    NSString *cardLetter, *url, *keyname;
    
	int i, j;
	for(i=0;i<[iosCards count];++i){
		NSString *hostid, *hostname;
        int localport;
		cardLetter=[[[iosCards objectAtIndex:i] objectForKey:@"value"] objectForKey:@"cardname"];
		hostid=[[[iosCards objectAtIndex:i] objectForKey:@"value"] objectForKey:@"hostid"];
		for(j=0;j<[ioServers count];++j){
			if([hostid isEqualToString:[[ioServers objectAtIndex:j] valueForKey:@"id"]]){
				hostname=[[[ioServers objectAtIndex:j] objectForKey:@"value"] valueForKey:@"hostname"];

                localport = [[[[ioServers objectAtIndex:j] objectForKey:@"value"] valueForKey:@"wmport"] intValue]
                            +[[hostname substringWithRange:NSMakeRange(3,1)] intValue];
                
                keyname =[NSString stringWithFormat:@"%@%@",hostname,cardLetter];
                
                SNOConnection *connection = [[SNOConnection alloc] init];
                [connection setDelegate:self];
                [connection setKey:keyname];
                [connection setDelegateAction:@"getAllChannelValues"];
                url = [NSString stringWithFormat:@"http://localhost:%i/data/card%@/",localport,cardLetter];
                [connection get:url];
                [connection release];
                
                SNOConnection *connection2 = [[SNOConnection alloc] init];
                [connection2 setDelegate:self];
                [connection2 setKey:keyname];
                [connection2 setDelegateAction:@"getAllConfig"];
                url = [NSString stringWithFormat:@"http://localhost:%i/config/card%@/",localport,cardLetter];
                [connection2 get:url];
                [connection2 release];
                					
			}			
		}
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:slowControlTableChanged object:self];
    
	//poll according to delay specified by user
	if (slowControlPollingState !=0 && pollSlowControl) 
		[self performSelector:@selector(readAllVoltagesFromIOServers) withObject:nil afterDelay:slowControlPollingState];	
}

- (void) setSlowControlParameterThresholds
{	
	NSLog(@"setting thresholds\n");
	
 	int i;
	for(i=0;i<[tableEntries count];++i){
		BOOL isSelected=[[[tableEntries objectAtIndex:i] valueForKey:@"parameterSelected"] boolValue];
		if (isSelected){
            NSString *url = [NSString stringWithFormat:@"http://snoplus:scintillate@snotpenn01.snolab.ca:5984/slow_control/%@",
                             [[tableEntries objectAtIndex:i] parameterIoChannelDocId]];
            NSString *key = [NSString stringWithFormat:@"%i",i];
            SNOConnection *connection = [[SNOConnection alloc] init];
            [connection setDelegateAction:@"updateIOSChannelThresholds"];
            [connection setKey:key];
            [connection setDelegate:self];
            [connection get:url];
            [connection release];
		}
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:slowControlTableChanged object:self];
}

- (void) setSlowControlChannelGain
{/*
	NSHTTPURLResponse *response;
	NSError *connectionError;
	
	NSLog(@"setting gain\n");
	
 	int i;
	for(i=0;i<[tableEntries count];++i){
		BOOL isSelected=[[[tableEntries objectAtIndex:i] valueForKey:@"parameterSelected"] boolValue];
		if (isSelected){
			NSString* channelName = [NSString stringWithFormat:@"channel%i",[[tableEntries objectAtIndex:i] parameterChannel]];
			NSString* cardName = [NSString stringWithFormat:@"card%@",[[tableEntries objectAtIndex:i] parameterCard]];
			
			urlName=[NSString stringWithFormat:@"http://localhost:%i/config/card%@/",
					 //[[tableEntries objectAtIndex:i] IPAddress],
					 [[tableEntries objectAtIndex:i] Port],
					 [[tableEntries objectAtIndex:i] parameterCard]];
			NSMutableURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlName]];
			NSData* responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&connectionError];
			NSString* jsonStr = [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease];
			NSMutableDictionary* copiedFile = [[(NSDictionary *)[jsonStr yajl_JSON] mutableCopy] autorelease];			
			
			NSNumber* gainValue = [[[NSNumber alloc] initWithFloat:[[tableEntries objectAtIndex:i] parameterGain]]autorelease];
			[[[copiedFile objectForKey:cardName] objectForKey:channelName] setObject:gainValue forKey:@"gain"];
			
			jsonStr=[copiedFile yajl_JSONString];
			NSData* postBody=[jsonStr dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
			
			NSMutableURLRequest* sendrequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlName]];
			[sendrequest setValue:@"application/json" forHTTPHeaderField: @"Content-Type"];
			[sendrequest setValue:[NSString stringWithFormat:@"%d", [postBody length]] forHTTPHeaderField:@"Content-Length"];
			[sendrequest setHTTPMethod:@"POST"];
			[sendrequest setHTTPBody:postBody];
			responseData=[NSURLConnection sendSynchronousRequest:sendrequest returningResponse:&response error:&connectionError];		
			
			//NSString *path = @"/Users/wan/Orca/dev/Orca/Source/Experiments/SNO/testchannelgainwrite.json";
			//[jsonStr writeToFile:path atomically:YES];
		}
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:slowControlTableChanged object:self];
*/
}


- (void) enableSlowControlParameter
{
	int i;
	for(i=0;i<kNumSlowControlParameters;++i){
		BOOL isSelected=[[[tableEntries objectAtIndex:i] valueForKey:@"parameterSelected"] boolValue];
		if (isSelected && ![[tableEntries objectAtIndex:i] parameterEnabled] ){
			[[tableEntries objectAtIndex:i] setParameterEnabled:YES];
		}else if (isSelected && [[tableEntries objectAtIndex:i] parameterEnabled] ) {
			[[tableEntries objectAtIndex:i] setParameterEnabled:NO];
		}
	}
}


//obsolete - has to be updated.
- (void) setSlowControlMapping
{/*
	NSString *jsonStr = [NSString stringWithContentsOfFile:@"/Users/Wan/Orca/Source/Experiments/SNO/testCard.json" 
												  encoding:NSUTF8StringEncoding error:nil];
	NSMutableDictionary *copiedFile = [[(NSDictionary *)[jsonStr yajl_JSON] mutableCopy] autorelease];	
	
	NSString *cardLetter;
	NSMutableString *cardName, *channelName;
	NSDictionary *card, *channel;
	NSNumber *Value;
	
	int i, j, ichan, channelNumber;
	for(i=0;i<kNumSlowControlParameters;++i){
		BOOL isSelected=[[[tableEntries objectAtIndex:i] valueForKey:@"parameterSelected"] boolValue];
		if (isSelected){
			//get card and channel displayed in table
			cardLetter=[[tableEntries objectAtIndex:i] parameterCard];
			channelNumber=[[tableEntries objectAtIndex:i] parameterChannel];
			cardName=[NSMutableString stringWithString:@"card"];
			channelName=[NSMutableString stringWithString:@"channel"];		
			[cardName appendString:[NSString stringWithFormat:@"%@",cardLetter]];
			[channelName appendString:[NSString stringWithFormat:@"%i",channelNumber]];
			
			//set parameter connected bit to yes
			[[tableEntries objectAtIndex:i] setParameterConnected:YES];
			
			//new channel's deprecated parameter in latest db has to be disconnected
			//get channel's previous parameter index
			int oldparameterindex=[[[[copiedFile objectForKey:cardName] objectForKey:channelName] objectForKey:@"index"] intValue];
			//if the channel was previously associated to a parameter, dissociate the latter from it
			if (oldparameterindex > 0 && [[tableEntries objectAtIndex:oldparameterindex-1] parameterConnected]
				&& ![[tableEntries objectAtIndex:oldparameterindex-1] parameterSelected]){
				[[tableEntries objectAtIndex:oldparameterindex-1] setParameterConnected:NO];
				[[tableEntries objectAtIndex:oldparameterindex-1] setCardName:@"N/A"];
				[[tableEntries objectAtIndex:oldparameterindex-1] setChannelNumber:0];
				//[[tableEntries objectAtIndex:oldparameterindex-1] setChannelGain:0.0];
			}
			
			//selected variable's deprecated channel in latest db has to be emptied.
			//loop through to find card and channel that was previously associated to parameter.
			for(j=65;j<65+kMaxNumCards;++j){
				NSString *cardLetter2=[NSString stringWithFormat:@"%c", j];
				NSMutableString *cardName2=[NSMutableString stringWithString:@"card"];
				[cardName2 appendString:[NSString stringWithFormat:@"%@",cardLetter2]];
				for(ichan=0;ichan<kMaxNumChannels;++ichan){
					NSMutableString *channelName2=[NSMutableString stringWithString:@"channel"];			
					[channelName2 appendString:[NSString stringWithFormat:@"%i",ichan+1]];
					
					card = [copiedFile objectForKey:cardName2];
					channel = [copiedFile objectForKey:channelName2];
					
					if([[[[copiedFile objectForKey:cardName2] objectForKey:channelName2] objectForKey:@"index"] intValue] == i+1){
						//if found, reset the channel and don't associate it to any slow control parameter
						[[[copiedFile objectForKey:cardName2] objectForKey:channelName2] setObject:@"" forKey:@"name"];
						[[[copiedFile objectForKey:cardName2] objectForKey:channelName2] setObject:@"" forKey:@"units"];
						Value=[[NSNumber alloc] initWithFloat:0.0];
						[[[copiedFile objectForKey:cardName2] objectForKey:channelName2] setObject:Value forKey:@"conversion factor"];
						[[[copiedFile objectForKey:cardName2] objectForKey:channelName2] setObject:Value forKey:@"lo threshold"];
						[[[copiedFile objectForKey:cardName2] objectForKey:channelName2] setObject:Value forKey:@"hi threshold"];
						[[[copiedFile objectForKey:cardName2] objectForKey:channelName2] setObject:Value forKey:@"lolo threshold"];
						[[[copiedFile objectForKey:cardName2] objectForKey:channelName2] setObject:Value forKey:@"hihi threshold"];
						[[[copiedFile objectForKey:cardName2] objectForKey:channelName2] setObject:@"" forKey:@"status"];
						Value=[[NSNumber alloc] initWithInt:-1];
						[[[copiedFile objectForKey:cardName2] objectForKey:channelName2] setObject:Value forKey:@"index"];
					}
				}
				
			}
			
			//set parameter's properties to selected channel
			[[[copiedFile objectForKey:cardName] objectForKey:channelName] 
			 setObject:[[tableEntries objectAtIndex:i] parameterName] forKey:@"name"];
			[[[copiedFile objectForKey:cardName] objectForKey:channelName] 
			 setObject:[[tableEntries objectAtIndex:i] parameterUnits] forKey:@"units"];		
			Value = [[NSNumber alloc] initWithFloat:[[tableEntries objectAtIndex:i] parameterLoThreshold]];
			[[[copiedFile objectForKey:cardName] objectForKey:channelName] setObject:Value forKey:@"lo threshold"];
			Value = [[NSNumber alloc] initWithFloat:[[tableEntries objectAtIndex:i] parameterHiThreshold]];
			[[[copiedFile objectForKey:cardName] objectForKey:channelName] setObject:Value forKey:@"hi threshold"];
			Value = [[NSNumber alloc] initWithFloat:[[tableEntries objectAtIndex:i] parameterLoLoThreshold]];
			[[[copiedFile objectForKey:cardName] objectForKey:channelName] setObject:Value forKey:@"lolo threshold"];
			Value = [[NSNumber alloc] initWithFloat:[[tableEntries objectAtIndex:i] parameterHiHiThreshold]];
			[[[copiedFile objectForKey:cardName] objectForKey:channelName] setObject:Value forKey:@"hihi threshold"];
			Value = [[NSNumber alloc] initWithFloat:[[tableEntries objectAtIndex:i] parameterGain]];
			[[[copiedFile objectForKey:cardName] objectForKey:channelName] setObject:Value forKey:@"gain"];
			Value = [[NSNumber alloc] initWithInt:i+1]; //[NSNumber numberWithInteger:i+1];
			[[[copiedFile objectForKey:cardName] objectForKey:channelName] setObject:Value forKey:@"index"];
			//NSLog(@"test %i %@ %@ %@ %i %i\n",i,[[tableEntries objectAtIndex:i] parameterName],
			//	  cardName,channelName,
			//	  [[[[copiedFile objectForKey:cardName] objectForKey:channelName] objectForKey:@"index"] intValue],
			//	  oldparameterindex);
		}
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:slowControlTableChanged object:self];
	
	//NSString *path = @"/Users/wan/Orca/Source/Experiments/SNO/testCard.json";
	//[[copiedFile yajl_JSONString] writeToFile:path atomically:YES];	
*/
}


- (SNOSlowControl *) getSlowControlVariable:(int)index
{
	return [tableEntries objectAtIndex:index];
}

- (void) setSlowControlMonitorStatusString:(NSString *)aString
{
	[aString retain];
	[slowControlMonitorStatusString release];
	slowControlMonitorStatusString = aString;
}

- (void) setSlowControlMonitorStatusStringColor:(NSColor *)aColor
{
	slowControlMonitorStatusStringColor = aColor;
}

- (NSString *) getSlowControlMonitorStatusString
{
	return slowControlMonitorStatusString;
}

- (NSColor *) getSlowControlMonitorStatusStringColor
{
	return slowControlMonitorStatusStringColor;
}

- (void) getSlowControlMap:(NSString *)aString
{
    NSDictionary *jsonSlowControlVariablesView = [[NSDictionary alloc] initWithDictionary:[aString yajl_JSON]];
	NSArray *slowControlVariablesView = [[NSArray alloc] initWithArray:[jsonSlowControlVariablesView objectForKey:@"rows"]];

	//slowcontrolmap stores the channel->parameter map in a dict. for quick access
    if (slowControlMap) [slowControlMap release], slowControlMap=nil;
    slowControlMap = [[NSMutableDictionary alloc] init];
    
    //tableEntries is the parameter->channel map
	int i;
	for(i=0;i<[[jsonSlowControlVariablesView objectForKey:@"total_rows"] intValue];++i){
		SNOSlowControl *slowControlEntry = [[SNOSlowControl alloc] init];
        NSArray *values = [[slowControlVariablesView objectAtIndex:i] objectForKey:@"value"];
		[slowControlEntry setParameterNumber:[[[slowControlVariablesView objectAtIndex:i] objectForKey:@"key"] intValue]];
	    [slowControlEntry setParameterName:[values objectAtIndex:0]];
		[slowControlEntry setUnits:[values objectAtIndex:5]];
		[slowControlEntry setLoThresh:[[values objectAtIndex:7] floatValue]];
		[slowControlEntry setHiThresh:[[values objectAtIndex:8] floatValue]];
		[slowControlEntry setLoLoThresh:[[values objectAtIndex:6] floatValue]];
		[slowControlEntry setHiHiThresh:[[values objectAtIndex:9] floatValue]];	
		[slowControlEntry setCardName:[values objectAtIndex:2]];
		[slowControlEntry setChannelNumber:[[values objectAtIndex:3] intValue]];
		[slowControlEntry setParameterEnabled:YES];
		[slowControlEntry setParameterConnected:YES];
		[slowControlEntry setIPAddress:[values objectAtIndex:11]];
		[slowControlEntry setPort:[[values objectAtIndex:12] intValue]];
		[slowControlEntry setIosName:[values objectAtIndex:1]];
		[slowControlEntry setIoChannelDocId:[values objectAtIndex:4]];

        [tableEntries insertObject:slowControlEntry atIndex:i];
        
        NSString *keyname = [NSString stringWithFormat:@"%@%@%i",[values objectAtIndex:1],[values objectAtIndex:2],[[values objectAtIndex:3] intValue]];
        NSString *parNumber = [NSString stringWithFormat:@"%i",i];
        [slowControlMap setObject:parNumber forKey:keyname];

		[slowControlEntry release];
	}
    
    [jsonSlowControlVariablesView release];
    [slowControlVariablesView release];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:slowControlTableChanged object:self];
    
    NSString *status=@"Connected to snotpenn server.";
    [self setSlowControlMonitorStatusString:status];	
    [self setSlowControlMonitorStatusStringColor:[NSColor blueColor]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:slowControlConnectionStatusChanged object:self];
}

//ORTaskSequence delegate method
- (void) tasksCompleted:(id)sender
{
    NSLog(@"portForwardScript executed.\n");
}

//SNOConnection delegate methods

- (void) getIOSCards:(NSString *) aString
{
    if (iosCards) [iosCards release];
	iosCards = [[NSArray alloc] initWithArray:[[aString yajl_JSON] objectForKey:@"rows"]];
}

- (void) getIOS:(NSString *) aString
{
    if (ioServers) [ioServers release];
    ioServers = [[NSArray alloc] initWithArray:[[aString yajl_JSON] objectForKey:@"rows"]];
}

- (void) getAllChannelValues:(NSString *) aString withKey:(NSString *)aKey
{
    NSDictionary *voltages = [aString yajl_JSON];
 
    if (voltages != NULL) {
        int i;
        for (i=0;i<kMaxNumChannels;++i) {
            NSString *channelName = [NSString stringWithFormat:@"channel%i",i+1];
            NSString *cardName = [NSString stringWithFormat:@"card%@",[aKey substringWithRange:NSMakeRange(4, 1)]];
        
            float parValue = [[[[voltages objectForKey:cardName] objectForKey:channelName] objectForKey:@"voltage"] floatValue];
            
            NSString *fullKey = [NSString stringWithFormat:@"%@%i",aKey,i];
            if ([slowControlMap objectForKey:fullKey] != NULL){
                
                int parIndex = [[slowControlMap objectForKey:fullKey] intValue];

                if ([[tableEntries objectAtIndex:parIndex] parameterEnabled]){
                    [[tableEntries objectAtIndex:parIndex] setParameterValue:parValue];
                
                    if (parValue > [[tableEntries objectAtIndex:parIndex] parameterLoThreshold] 
                        && parValue < [[tableEntries objectAtIndex:parIndex] parameterHiThreshold]) {
                        [[tableEntries objectAtIndex:parIndex] setStatus:@"OK"];
                    }else if (parValue > [[tableEntries objectAtIndex:parIndex] parameterHiThreshold] 
                          && parValue < [[tableEntries objectAtIndex:parIndex] parameterHiHiThreshold]) {
                        [[tableEntries objectAtIndex:parIndex] setStatus:@"Hi"];
                    }else if (parValue > [[tableEntries objectAtIndex:parIndex] parameterHiHiThreshold]) {
                        [[tableEntries objectAtIndex:parIndex] setStatus:@"HiHi"];
                    }else if (parValue < [[tableEntries objectAtIndex:parIndex] parameterLoThreshold] 
                          && parValue > [[tableEntries objectAtIndex:parIndex] parameterLoLoThreshold]) {
                        [[tableEntries objectAtIndex:parIndex] setStatus:@"Lo"];
                    }else if (parValue < [[tableEntries objectAtIndex:parIndex] parameterLoLoThreshold]) {
                        [[tableEntries objectAtIndex:parIndex] setStatus:@"LoLo"];
                    }
                }else{
                    [[tableEntries objectAtIndex:parIndex] setParameterValue:nan("")];
                    [[tableEntries objectAtIndex:parIndex] setStatus:@"disabled"];
                }
            }
        }
    } 
    
    //[[NSNotificationCenter defaultCenter] postNotificationName:slowControlTableChanged object:self];
}

- (void) getAllConfig:(NSString *)aString withKey:(NSString *)aKey
{
    NSDictionary *config= [aString yajl_JSON];
    if (config != NULL) {
        int i;
        for (i=0;i<kMaxNumChannels;++i){
            NSString *channelName = [NSString stringWithFormat:@"channel%i",i];
            NSString *cardName = [NSString stringWithFormat:@"card%@",[aKey substringWithRange:NSMakeRange(4, 1)]];
            
            float gainValue = [[[[config objectForKey:cardName] objectForKey:channelName] objectForKey:@"gain"] floatValue];

            NSString *fullKey = [NSString stringWithFormat:@"%@%i",aKey,i];
            int parIndex = [[slowControlMap objectForKey:fullKey] intValue];
            
            if ([[tableEntries objectAtIndex:parIndex] parameterEnabled]){
                [[tableEntries objectAtIndex:parIndex] setChannelGain:gainValue];
            }else{
                [[tableEntries objectAtIndex:parIndex] setParameterValue:nan("")];
                [[tableEntries objectAtIndex:parIndex] setStatus:@"disabled"];
            }    
        }
    } 
    
    //[[NSNotificationCenter defaultCenter] postNotificationName:slowControlTableChanged object:self];
}

- (void) updateIOSChannelThresholds:(NSString *)aString ofChannel:(NSString *)aKey
{
    //get channel document
    NSMutableDictionary *channelDoc = [(NSMutableDictionary *)[[aString yajl_JSON] mutableCopy] autorelease];
    
    //mark document as unapproved since thresholds are being updated.
    //update fields: approved -> false, 
    //set timestamp, date to current
    NSNumber *state = [NSNumber numberWithInt:0];
    [channelDoc setValue:state forKey:@"approved"];
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
    NSDate *now = [NSDate date];
    NSString *dateString = [dateFormatter stringFromDate:now];	
    NSNumber *timestamp=[NSNumber numberWithInt:[now timeIntervalSince1970]];
    [channelDoc setValue:dateString forKey:@"datetime"];
    [channelDoc setValue:timestamp forKey:@"timestamp"];
    
    //save document in database with same docid but as new revision; remove _id field 
    NSString *docid = [channelDoc objectForKey:@"_id"];
    [channelDoc removeObjectForKey:@"_id"];
    NSString *jsonStr=[channelDoc yajl_JSONString];
    NSData *postBody=[NSData dataWithData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    
    NSString *url = [NSString stringWithFormat:@"http://snoplus:scintillate@snotpenn01.snolab.ca:5984/slow_control/%@",docid];
    SNOConnection *connection2 = [[SNOConnection alloc] init];
    [connection2 setDelegate:self];
    [connection2 put:postBody atURL:url];
    [connection2 release];
    
    //create new approved document with updated threshold values
    state = [NSNumber numberWithInt:1];
    [channelDoc setValue:state forKey:@"approved"];
    [channelDoc removeObjectForKey:@"_rev"];
    
    int channel = [aKey intValue];
    NSNumber *lothresholdValue = [NSNumber numberWithFloat:[[tableEntries objectAtIndex:channel] parameterLoThreshold]];
    [channelDoc setObject:lothresholdValue forKey:@"lothresh"];
    NSNumber *hithresholdValue = [NSNumber numberWithFloat:[[tableEntries objectAtIndex:channel] parameterHiThreshold]];					 
    [channelDoc setObject:hithresholdValue forKey:@"hithresh"];
    NSNumber *lolothresholdValue = [NSNumber numberWithFloat:[[tableEntries objectAtIndex:channel] parameterLoLoThreshold]];	
    [channelDoc setObject:lolothresholdValue forKey:@"lolothresh"];
    NSNumber *hihithresholdValue = [NSNumber numberWithFloat:[[tableEntries objectAtIndex:channel] parameterHiHiThreshold]];	
    [channelDoc setObject:hihithresholdValue forKey:@"hihithresh"];
    
    jsonStr=[channelDoc yajl_JSONString];

    postBody=[NSData dataWithData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    
    //post new document in database
    url = [NSString stringWithFormat:@"http://snoplus:scintillate@snotpenn01.snolab.ca:5984/slow_control/"];
    SNOConnection *connection3 = [[SNOConnection alloc] init];
    [connection3 setDelegate:self];
    [connection3 post:postBody atURL:url];
    [connection3 release];
}

@end


