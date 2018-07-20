//
//  ORKatrinSLTModel.m
//  Orca
//
//  Created by A Kopmann on Wed Feb 29 2008.
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


#import "ORKatrinSLTModel.h"
#import "ORKatrinFLTModel.h"     //SLT needs to call some FLT code to init and stop histogramming -tb- 2008-04-24
#import "ORFireWireInterface.h"


@implementation ORKatrinSLTModel

- (id) init
{
    self = [super init];
    return self;
}

-(void) dealloc
{
    [super dealloc];
}



- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"KatrinSLTCard"]];
}


- (void) makeMainController
{
    [self linkToController:@"ORKatrinSLTController"];
}


- (void) initBoard
{
//TODO: called from ORIpeSLTModel ... - (void) runIsAboutToStart:(NSNotification*)aNote -tb- 2008-03-28
//TODO: maybe ORKatrinSLTModel should reimplement ... runIsAboutToStart: ... ??? -tb-
//TODO: ... and the notifications, too? -tb-
//TODO: should check if we can start the run (see comments in ORIpeSLTModel) -tb- 2008-03-28
   // Define variables that are not in the dialog
   //
   // Control register
   [self setInhibitSource: inhibitSource | 0x1]; // Enable software inhibit
   [self setInhibitSource: inhibitSource & 0x5]; // Disable internal inhibit
   // External inhibt in dialog
   [self setTriggerSource:1]; // Enable only software trigger
   // Second strobe in dialog
   // Testpulser not used
   // Sensors not used
   // Deadtime enable in dialog
   
   // Other parameter
   [self setInterruptMask:0]; // Clear interrupt mask


   [super initBoard];
}


//MAH added the initBoard call
- (void) serviceChanged:(NSNotification*)aNote
{
	if([[self fireWireInterface] serviceAlive]){
		[self initBoard];
	}
	[super serviceChanged:aNote];
}


#pragma mark •••Accessors
/** Used to open the alarm view only once if there are the same alarms from several 
  * FLTs (which is usually the case for FPGA configuration detection).
  */  //-tb-
- (ORAlarm*) fltFPGAConfigurationAlarm
{
    return fltFPGAConfigurationAlarm;
}

- (void) setFltFPGAConfigurationAlarm:(ORAlarm*) aAlarm
{
    fltFPGAConfigurationAlarm=aAlarm;
}

#pragma mark ••••hw histogram access

#ifdef __ORCA_DEVELOPMENT__CONFIGURATION__

// this is for testing and debugging the hardware histogramming (espec. timing) -tb- 2008-04-11
#define USE_TILLS_HISTO_DEBUG_MACRO //<--- to switch on/off debug output use/comment out this line -tb-
    #ifdef USE_TILLS_HISTO_DEBUG_MACRO
      #define    DebugHistoTB(x) x
    #else
      #define    DebugHistoTB(x) 
    #endif

#else
  #define    DebugHistoTB(x) 
#endif

/** Wait for the second strobe of the given FLT card. Returns current second.
  * Will wait for max. 1.1 second
  */
- (int) waitForSecondStrobeOfFLT:(ORKatrinFLTModel *)flt;
{
    if(!flt) return -1;
    uint32_t i,lastSec,sec;
    lastSec=[flt readTime];
    for(i=0;i<10000;i++){
        sec = [flt readTime];
        if(sec!=lastSec){
            DebugHistoTB(  NSLog(@"SLT:waitForSecondStrobeOfFLT until i=%i (x 100 usecs) for page toggle\n",i);  )
            return (int)sec;
        }
        usleep(100);
    }
    DebugHistoTB(  NSLog(@"SLT:waitForSecondStrobeOfFLT until i=%i (x 100 usecs) for page toggle\n",i);  )
    return -2;
}

/** Set EMin, TRun, BinWidth and start with according clear bit.
  */
- (void) startAllHistoModeFLTs
{
    //
    struct timeval t;//    struct timezone tz; is obsolete ... -tb-
    //timing
    gettimeofday(&t,NULL);
    time_t currentSec = t.tv_sec;
    time_t currentUSec = t.tv_usec;

		NSArray* cards = [[self crate] orcaObjects];
		NSEnumerator* e = [cards objectEnumerator];
		id card;
        ORKatrinFLTModel *flt;
		while (card = [e nextObject]){
			if([card isKindOfClass:NSClassFromString(@"ORKatrinFLTModel")]){
                flt=(ORKatrinFLTModel *)card;
                if([flt daqRunMode] == kKatrinFlt_DaqHistogram_Mode){
                    DebugHistoTB( NSLog(@"SLT:startAllHistoModeFLTs: init+starting FLT %i\n",[card slot]); )
                    //set timing info
                    [flt setHistoStartWaitingForPageToggle: FALSE];
                    [flt setHistoLastActivePage: [flt readCurrentHistogramPageNum]];
                    [flt setHistoLastPageToggleSec: (int)currentSec usec: (int)currentUSec];
                    // write TRun, EMin, BinWidth
                    //histogramming registers (now I use a broadcast: chan 31)
                    [flt writeEMin:[flt histoMinEnergy] forChan: 31];
                    [flt writeTRun:[flt histoRunTime] forChan: 31];
                    [flt writeHistogramSettingsForChan:31 mode: [flt histoStopIfNotCleared]  binWidth: [flt histoBinWidth] ];
                    [flt writeStartHistogramForChan:31 withClear: [flt histoClearAtStart] ];
                }
			}
		}
    //[firstHistoModeFLT writeHistogramControlRegisterForSlot: 31 chan: 31 value: 1]; //broadcast to the crate
}

- (void) stopAllHistoModeFLTs;
{
    //TODO: could loop over all FLTs and stop only the ones which are really in histogramming mode
    if(firstHistoModeFLT){
        [firstHistoModeFLT writeHistogramControlRegisterForSlot: 31 chan: 31 value: 0]; //broadcast to the crate
        [self waitForSecondStrobeOfFLT:firstHistoModeFLT];
    }
		NSArray* cards = [[self crate] orcaObjects];
		NSEnumerator* e = [cards objectEnumerator];
		id card;
        ORKatrinFLTModel *flt;
		while (card = [e nextObject]){
			if([card isKindOfClass:NSClassFromString(@"ORKatrinFLTModel")]){
                flt=(ORKatrinFLTModel *)card;
                if([flt daqRunMode] == kKatrinFlt_DaqHistogram_Mode){
                    DebugHistoTB( NSLog(@"SLT:stopAllHistoModeFLTs: stopping FLT %i\n",[card slot]); )
                    // left over for the FLT runTaskStopped -tb-
                }
			}
		}
}

- (void) clearAllHistoModeFLTBuffers
{
       DebugHistoTB( NSLog(@"SLT:calling clearAllHistoModeFLTBuffers \n"); )
            //swInhibit
	        [self setSwInhibit];

    ORKatrinFLTModel *aFLT=nil;
            
		NSArray* cards = [[self crate] orcaObjects];
		NSEnumerator* e  ;
		id card;
        ORKatrinFLTModel *flt;
        
        //set TRun to 1
        e = [cards objectEnumerator];
		while (card = [e nextObject]){
			if([card isKindOfClass:NSClassFromString(@"ORKatrinFLTModel")]){
                flt=(ORKatrinFLTModel *)card;
                if([flt daqRunMode] == kKatrinFlt_DaqHistogram_Mode){
                    if(!aFLT) aFLT = flt; //remember pointer to one of the flts
                    // write TRun, EMin, BinWidth
                    [flt writeTRun: 1 forChan: 31];
                    [flt writeHistogramSettingsForChan:31 mode: 0 /*0=continous*/ binWidth: 1 ];
                }
			}
		}
            //wait after second strobe
            [self waitForSecondStrobeOfFLT: aFLT];
            //start histogramming with clear
        e = [cards objectEnumerator];
		while (card = [e nextObject]){
			if([card isKindOfClass:NSClassFromString(@"ORKatrinFLTModel")]){
                flt=(ORKatrinFLTModel *)card;
                if([flt daqRunMode] == kKatrinFlt_DaqHistogram_Mode){
                    [flt writeStartHistogramForChan:31 withClear: 1 ];
                }
			}
		}
            //wait after second strobe
            [self waitForSecondStrobeOfFLT: aFLT];
            //clear + stop
        e = [cards objectEnumerator];
		while (card = [e nextObject]){
			if([card isKindOfClass:NSClassFromString(@"ORKatrinFLTModel")]){
                flt=(ORKatrinFLTModel *)card;
                if([flt daqRunMode] == kKatrinFlt_DaqHistogram_Mode){
                    [flt writeStartHistogramForChan:31 withClear: 1 ];
                }
			}
		}
            //reset TRun  --> will be done in startAllHistoModeFLTs -tb-
            //swRelease   --> will be done in takeData -tb-
            
}

#pragma mark •••Data Taker
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    
    //TEST: accessing the FLTs -tb-
    NSLog(@"==== ORKatrinSLTModel::runTaskStarted ====\n");
    #if 0
    NSLog(@"Loop 1:  loop over FLTs ---------\n");  //NO! -tb-
    //lets cycle through the FLTs
    int i;
    for(i=0; i<kNumFLTChannels; i++){
        ORKatrinFLTModel * flt=[dataTakers objectAtIndex:i];
        if(flt) NSLog(@"Loop 1: found a object in for loop at i= %i\n",i);
    }
    #endif
    #if 0
    NSLog(@"Loop 2:  loop over FLTs --------- dataTakers %p\n",dataTakers);  //NO! -tb-
    NSEnumerator* e = [dataTakers objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        //[obj runTaskStarted:aDataPacket userInfo:userInfo];
        if(obj) NSLog(@"Loop 2: found a object in NSEnumerator ptr= %p\n",obj);
    }
    #endif
    #if 0
    //readOutGroup ->children
    NSLog(@"Loop 4:  loop over FLTs -----readOutGroup ->children----\n");  //NO! -tb-
    //lets cycle through the FLTs
    int i;
    for(i=0; i<[[self children] count]; i++){
        ORKatrinFLTModel * flt=[[self children] objectAtIndex:i];
        if(flt) NSLog(@"Loop 4: found a object in for loop at i= %i\n",i);
    }
    #endif
    #if 0
    {
        NSLog(@"Loop 3:  loop over FLTs ---------\n");  //YES!!!!! -tb-
		NSArray* cards = [[self crate] orcaObjects];
		NSEnumerator* e = [cards objectEnumerator];
		id card;
		while (card = [e nextObject]){
			if([card isKindOfClass:NSClassFromString(@"ORIpeFLTModel")]){
                // if we have ORKatrinFLTModel cards, this search does not match
                NSLog(@"  Loop 3: found a ORIpeFLTModel in slot %i\n",[card slot]);
			}
			if([card isKindOfClass:NSClassFromString(@"ORIpeCard")]){
                // if we have ORKatrinFLTModel cards, this search does not match
                NSLog(@"  Loop 3: found a ORIpeCard in slot %i\n",[card slot]);
			}
			if([card isKindOfClass:NSClassFromString(@"ORKatrinFLTModel")]){
				//try to access a card. if it throws then we have to load the FPGAs
				//[card readControlStatus];
				//break;	//only need to try one
                NSLog(@"  Loop 3: found a ORKatrinFLTModel in slot %i\n",[card slot]);
			}
		}
    }
    #endif
    [self clearExceptionCount];
	
	
    //----------------------------------------------------------------------------------------
    // Add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORIpeSLTModel"];    
    //----------------------------------------------------------------------------------------	


	[self setSwInhibit];
	
	
    if([[userInfo objectForKey:@"doinit"]intValue]){
		[self initBoard];					
	}	

	

/*	NSArray* allFLTs = [[self crate] orcaObjects];
	NSEnumerator* e = [allFLTs objectEnumerator];
	id aCard;
	while(aCard = [e nextObject]){
		if([aCard isKindOfClass:NSClassFromString(@"ORIpeFireWireCard")])continue;
		if([dataTakers containsObject:aCard])continue;
		[aCard disableAllTriggers];
	}
*/ 
/*   
    NSEnumerator* e = [dataTakers objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        [obj runTaskStarted:aDataPacket userInfo:userInfo];
    }
*/

/*	
	[self readStatusReg];
	actualPageIndex = 0;
	eventCounter    = 0;
	lastDisplaySec = 0;
	lastDisplayCounter = 0;
	lastDisplayRate = 0;
*/
	
  	usingPBusSimulation		  = [self pBusSim];
	lastSimSec = 0;

	first = YES;
	
    //place here the startup for the histogram mode: stop (if running), clear, start (in takeData?) -tb-
    #if 1
    {
        //debug output -tb- NSLog(@"Loop over FLTs ---------\n");  //YES!!!!! -tb-
		NSArray* cards = [[self crate] orcaObjects];
		NSEnumerator* e = [cards objectEnumerator];
		id card;
        ORKatrinFLTModel *flt;
        firstHistoModeFLT=0;//remember first FLT in list -tb-
        fltsInHistoDaqMode=FALSE; //make this global
        BOOL histoIsRunning=FALSE;
		while (card = [e nextObject]){
			if([card isKindOfClass:NSClassFromString(@"ORKatrinFLTModel")]){
                flt=(ORKatrinFLTModel *)card;
				//try to access a card. if it throws then we have to load the FPGAs
				//[card readControlStatus];
				//break;	//only need to try one
                //debug output -tb- NSLog(@"  Loop 3: found a ORKatrinFLTModel in slot %i\n",[card slot]);
                if([flt daqRunMode] == kKatrinFlt_DaqHistogram_Mode){
                    fltsInHistoDaqMode=TRUE;
                    if(!firstHistoModeFLT) firstHistoModeFLT=flt;
                    if([flt histogrammingIsActiveForChan:0]) histoIsRunning=TRUE;//testing chan 0 is enough -tb-
                }
			}
		}
        if(fltsInHistoDaqMode) NSLog(@"SLT::runTaskStarted: At least one FLT is in histogram DAQ mode. Handle histogramming!\n");
        if(histoIsRunning) NSLog(@"SLT::runTaskStarted: At least one FLT is still running in histogram mode; STOP all.\n");
        //stop histogramming
        if(histoIsRunning){
            //wait after second strobe (use firstFLT for timing) TODO: ask Denis: is SLT and FLT timer syncronous? NO for v3! -tb-
            [self waitForSecondStrobeOfFLT:firstHistoModeFLT];
            //broadcast to all cards a "stop histogramming"
            [firstHistoModeFLT writeHistogramControlRegisterForSlot: 31 chan: 31 value: 0]; //broadcast to the crate
            //wait after second strobe (use firstFLT for timing)
            //[self waitForSecondStrobeOfFLT:firstHistoModeFLT];
        }
        //clear run
        if(fltsInHistoDaqMode){ //TODO: under construction -tb- (up to now: throw away first data record)
            //swInhibit
            //set TRun to 1
            //wait after second strobe
            //start histogramming with clear
            //wait after second strobe
            //clear + stop
            //reset TRun
            //swRelease
            // all moved to: clearAllHistoModeFLTBuffers
            [self clearAllHistoModeFLTBuffers];
        }
        //start histogramming modes
        if(fltsInHistoDaqMode){ //TODO: under construction -tb- (up to now: throw away first data record)
            //I do it in takeData ... if(first) ... to be sure that this is called AFTER runTaskStarted of the FLTs
            //  to avoid that they overwrite some settings -tb-
        }
    }
    #endif
}


-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{

	if(first){
		[self releaseAllPages];
        if(fltsInHistoDaqMode){
            // wait for second strobe
            [self waitForSecondStrobeOfFLT:firstHistoModeFLT];
            // start histogramming
            [self startAllHistoModeFLTs];
            // wait for second strobe - THEN histogramming will start -tb-
            [self waitForSecondStrobeOfFLT:firstHistoModeFLT];
            //need to set the FLT timers
            
        }
		[self releaseSwInhibit];
		//[self writeReg:kSLTResetDeadTime value:0];
        //start histogramming
		first = NO;
	} else {	
	
	    // TODO: Clear pages if a software trigger was generated, otherwise
		//       the stack can be completely filled !?
		//       Run a simplifed readout loop ...
				
/*
		struct timeval t0, t1;
		struct timezone tz;	
			
			
		uint64_t lPageStatus;
		lPageStatus = ((uint64_t)[self readReg:kPageStatusHigh]<<32) | [self readReg:kPageStatusLow];

		// Siumartion events everey second?!
		if (usingPBusSimulation){
		  gettimeofday(&t0, &tz);
		  if (t0.tv_sec > lastSimSec) {
		    lPageStatus = 1;
			lastSimSec = t0.tv_sec;
		  }	
		}
		
		
		if(lPageStatus != 0x0){
			while((lPageStatus & (0x1LL<<actualPageIndex)) == 0){
				if(actualPageIndex>=63)actualPageIndex=0;
				else actualPageIndex++;
			}
			
			// Set start of readout 
			gettimeofday(&t0, &tz);
			
			eventCounter++;
			
			//read page start address
			uint32_t lTimeL     = [self read: SLT_REG_ADDRESS(kSLTLastTriggerTimeStamp) + actualPageIndex];
			int iPageStart = (((lTimeL >> 10) & 0x7fe)  + 20) %2000;
			
			uint32_t timeStampH = [self read: SLT_REG_ADDRESS(kSLTPageTimeStamp) + 2*actualPageIndex];
			uint32_t timeStampL = [self read: SLT_REG_ADDRESS(kSLTPageTimeStamp) + 2*actualPageIndex+1];
			//
			//			NSLog(@"Reading event from page %d, start=%d:  %ds %dx100us\n", 
			//			         actualPageIndex+1, iPageStart, timeStampH, (timeStampL >> 11) & 0x3fff);
			
			//readout the SLT pixel trigger data
			int i;
			uint32_t buffer[2000];
			uint32_t sltMemoryAddress = (SLTID << 24) | actualPageIndex<<11;
			// Split the reading of the memory in blocks according to the maximal block size
			// supported by the firewire driver	
			// TODO: Read only the relevant trigger data for smaller page sizes!
			//       Reading needs to start in this case at start address...		
			int blockSize = 500;
			int sltSize = 2000; // Allways read the full trigger memory
			int nBlocks = sltSize / blockSize;
			for (i=0;i<nBlocks;i++)
			  [self read:sltMemoryAddress+i*blockSize data:buffer+i*blockSize size:blockSize*sizeof(uint32_t)];
			
			//for(i=0;i<2000;i++) buffer[i]=0; // only Test

            // Check result from block readout - Testing only
			//uint32_t buffer2[2000];
            //[self readBlock:sltMemoryAddress dataBuffer:(uint32_t*)buffer2 length:2000 increment:1];
			//for(i=0;i<2000;i++) if (buffer[i]!=buffer2[i]) {
			//  NSLog(@"Error reading Slt Memory\n"); 
			//  break;
			//}  
			
		    // Re-organize trigger data to get it in a continous data stream
			// There is no automatic address wrapping like in the Flts available...
			uint32_t reorderBuffer[2000];
			uint32_t *pMult = reorderBuffer;
			memcpy( pMult, buffer + iPageStart, (2000 - iPageStart)*sizeof(uint32_t));  
			memcpy( pMult + 2000 - iPageStart, buffer, iPageStart*sizeof(uint32_t));  
			
			int nTriggered = 0;
		    uint32_t xyProj[20];
			uint32_t tyProj[100];
			nTriggered = [self calcProjection:pMult xyProj:xyProj tyProj:tyProj];

			//ship the start of event record
			uint32_t eventData[5];
			eventData[0] = eventDataId | 5;	
			eventData[1] = (([self crateNumber]&0x0f)<<21) | ([self stationNumber]& 0x0000001f)<<16;
			eventData[2] = eventCounter;
			eventData[3] = timeStampH; 
			eventData[4] = timeStampL;
			[aDataPacket addLongsToFrameBuffer:eventData length:5];	//ship the event record

			//ship the pixel multiplicity data for all 20 cards (last two of 22 not used)
			uint32_t multiplicityRecord[3 + 20];
			multiplicityRecord[0] = multiplicityId | 20 + 3;	
			multiplicityRecord[1] = (([self crateNumber]&0x0f)<<21) | ([self stationNumber]& 0x0000001f)<<16; 
			multiplicityRecord[2] = eventCounter;
			for(i=0;i<20;i++) multiplicityRecord[3+i] = xyProj[i];
			[aDataPacket addLongsToFrameBuffer:multiplicityRecord length:20 + 3];

			int lStart = (lTimeL >> 11) & 0x3ff;
			NSEnumerator* e = [dataTakers objectEnumerator];
			
			//readout the flt waveforms
			// Added pixelList as parameter to the Flt readout in order
			// to enable selective readout
			// ak 5.10.2007
			NSMutableDictionary* userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithInt:actualPageIndex], @"page",
				[NSNumber numberWithInt:lStart],		  @"lStart",
				[NSNumber numberWithInt:eventCounter],	  @"eventCounter",
				[NSNumber numberWithInt:pageSize],		  @"pageSize",
				nil];
			id obj;
			while(obj = [e nextObject]){			    
				uint32_t pixelList;
				if(readAll)	pixelList = 0x3fffff;
				else		pixelList = xyProj[[obj slot] - 1];
				//NSLog(@"Datataker in slot %d, pixelList %06x\n", [obj slot], pixelList);
				[userInfo setObject:[NSNumber numberWithLong:pixelList] forKey: @"pixelList"];
				
				[obj takeData:aDataPacket userInfo:userInfo];
			}

			//free the page
			[self writeReg:kSLTSetPageFree value:actualPageIndex];
			
			// Set end of readout
			gettimeofday(&t1, &tz);

			// Display event header
			if (displayEventLoop) {
				// TODO: Display number of stored pages
				// TODO: Add control to GUI that controls the update rate
				// 7.12.07 ak
				if (t0.tv_sec > lastDisplaySec){
					NSFont* aFont = [NSFont userFixedPitchFontOfSize:9];
					int nEv = eventCounter - lastDisplayCounter;
					double rate = 0.1 * nEv / (t0.tv_sec-lastDisplaySec) + 0.9 * lastDisplayRate;
					
					uint32_t tRead = (t1.tv_sec - t0.tv_sec) * 1000000 + (t1.tv_usec - t0.tv_usec);
					if (t0.tv_sec%20 == 0) {
					    NSLogFont(aFont, @"%64s  | %16s\n", "Last event", "Interval summary"); 
						NSLogFont(aFont, @"%4s %14s %4s %14s %4s %4s %14s  |  %4s %10s\n", 
								  "No", "Actual time/s", "Page", "Time stamp/s", "Trig", 
								  "nCh", "tRead/us", "nEv", "Rate");
					}			  
					NSLogFont(aFont,   @"%4d %14d %4d %14d %4d %4d %14d  |  %4d %10.2f\n", 
							  eventCounter, t0.tv_sec, actualPageIndex, timeStampH, 0, 
							  nTriggered, tRead, nEv, rate);
					
					// Keep the last display second		  
					lastDisplaySec = t0.tv_sec;	
					lastDisplayCounter = eventCounter;
					lastDisplayRate = rate;	  
				}
			}
			
		}
		
*/		
	}
	
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{

	[self setSwInhibit];
    
    //place here the stopping for the histogram mode: stop+wait 1 sec -tb-
    #if 1
    [self stopAllHistoModeFLTs];
    #endif

/*	
	dataTakers = [[readOutGroup allObjects] retain];	//cache of data takers.
    
    NSEnumerator* e = [dataTakers objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        [obj runTaskStopped:aDataPacket userInfo:userInfo];
    }
	[dataTakers release];
	dataTakers = nil;
	if(pollingWasRunning) {
		[poller runWithTarget:self selector:@selector(readAllStatus)];
	}
*/	
}



@end
