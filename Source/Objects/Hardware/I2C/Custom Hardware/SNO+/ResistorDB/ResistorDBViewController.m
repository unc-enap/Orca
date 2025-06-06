//
//  ResistorDBViewController.m
//  Orca
//
//  Created by Chris Jones on 28/04/2014.
//
//

#import "ResistorDBViewController.h"
#import "ResistorDBModel.h"


@interface ResistorDBViewController ()
@property (assign) IBOutlet NSProgressIndicator *loadingFromDbWheel;
@end

@implementation ResistorDBViewController
@synthesize loadingFromDbWheel,
resistorDocDic = _resistorDocDic;

-(id)init
{
    self = [super initWithWindowNibName:@"ResistorDBWindow"];
    return self;
}

- (void)dealloc
{
    [_resistorDocDic release];
    [super dealloc];
}

- (void) updateWindow
{
	[super updateWindow];
    
}

-(IBAction)queryResistorDB:(id)sender
{
    //check to see if actual values have been given
    if(([crateSelect stringValue] != nil) && ([cardSelect stringValue] != nil) && ([channelSelect stringValue] != nil)){
        
        int crateNumber = [[crateSelect stringValue] intValue];
        int cardNumber = [[cardSelect stringValue] intValue];
        int channelNumber = [[channelSelect stringValue] intValue];
        NSLog(@"value: %i %i %i",crateNumber,cardNumber,channelNumber);
        
        [loadingFromDbWheel setHidden:NO];
        [loadingFromDbWheel startAnimation:nil];
        [model queryResistorDb:crateNumber withCard:cardNumber withChannel:channelNumber];
    }
}

-(NSString*) parseStatusFromResistorDb:(NSString*)aKey withTrueStatement:(NSString*)aTrueStatement withFalseStatement:(NSString*)aFalseStatement
{
    if([[[model currentQueryResults] objectForKey:aKey] isEqualToString:@"0"]){
        return aFalseStatement;
    }
    else if([[[model currentQueryResults] objectForKey:aKey] isEqualToString:@"1"]){
        return aTrueStatement;
    }
    else{
        NSLog(@"ResistorDb:Setting to unknown state");
        return @"";
    }
}

-(NSString*) parseStatusToResistorDb:(NSString*)aControllerKey withTrueStatement:(NSString*)aTrueStatement withFalseStatement:(NSString*)aFalseStatement
{
    //return for YES/NO options in resistor GUI
    if([aControllerKey isEqualToString:@"NO"]){
        return aFalseStatement;
    }
    else if([aControllerKey isEqualToString:@"YES"]){
        return aTrueStatement;
    }
    //return for resistor pulled status in resistor GUI
    else if([aControllerKey isEqualToString:@"Not Pulled"]){
        return aFalseStatement;
    }
    else if([aControllerKey isEqualToString:@"Pulled"]){
        return aTrueStatement;
    }
    else{
        return @"Unknown State";
    }
}

-(void)resistorDbQueryLoaded
{
    //NSLog(@"in here");
    [loadingFromDbWheel setHidden:YES];
    [loadingFromDbWheel stopAnimation:nil];
    //NSLog(@"model value pulled Cable %@",[[model currentQueryResults] objectForKey:@"pulledCable"]);
    //NSLog(@"model results %@",[model currentQueryResults]);
    
    //Values to load
    NSString *resistorStatus;
    NSString *SNOLowOccString;
    NSString *pmtRemovedString;
    NSString *pmtReinstalledString;
    NSString *badCableString;
    NSString *pulledCableString;
    NSString *reason;
    NSString *info;
    
    @try{
        resistorStatus = [self parseStatusFromResistorDb:@"rPulled" withTrueStatement:@"Pulled" withFalseStatement:@"Not Pulled"];
        SNOLowOccString = [self parseStatusFromResistorDb:@"SnoLowOcc" withTrueStatement:@"YES" withFalseStatement:@"NO"];
        pmtRemovedString = [self parseStatusFromResistorDb:@"PmtRemoved" withTrueStatement:@"YES" withFalseStatement:@"NO"];
        pmtReinstalledString = [self parseStatusFromResistorDb:@"PmtReInstalled" withTrueStatement:@"YES" withFalseStatement:@"NO"];
        badCableString = [self parseStatusFromResistorDb:@"BadCable" withTrueStatement:@"YES" withFalseStatement:@"NO"];
        
        reason = [[model currentQueryResults] objectForKey:@"reason"];
        info = [[model currentQueryResults] objectForKey:@"info"];
        
        //download the start and end numbers
        [model setStartRunNumber:[NSNumber numberWithInt:[[[[model currentQueryResults] objectForKey:@"run_range"] objectAtIndex:0] intValue]]];
        [model setEndRunNumber:[NSNumber numberWithInt:[[[[model currentQueryResults] objectForKey:@"run_range"] objectAtIndex:1] intValue]]];
        
        //pulledCable isn't a string but an integer!!!
        if([[[[model currentQueryResults] objectForKey:@"pulledCable"] stringValue] isEqualToString:@"0"]){
            pulledCableString = @"NO";
        }
        else if([[[[model currentQueryResults] objectForKey:@"pulledCable"] stringValue] isEqualToString:@"1"]){
            pulledCableString = @"YES";
        }
        else{
            pulledCableString = @"Unknown Cable State";
        }
        
        
        //load the values to the screen
        [currentResistorStatus setStringValue:resistorStatus];
        [currentSNOLowOcc setStringValue:SNOLowOccString];
        [currentPulledCable setStringValue:pulledCableString];
        [currentPMTReinstallled setStringValue:pmtReinstalledString];
        [currentPMTRemoved setStringValue:pmtRemovedString];
        [currentBadCable setStringValue:badCableString];
        [currentReason setStringValue:reason];
        [currentInfo setStringValue:info];
        
        
        [updateResistorStatus setStringValue:resistorStatus];
        [updateSnoLowOcc setStringValue:SNOLowOccString];
        [updatePulledCable setStringValue:pulledCableString];
        [updatePmtReinstalled setStringValue:pmtReinstalledString];
        [updatePmtRemoved setStringValue:pmtRemovedString];
        [updateBadCable setStringValue:badCableString];
        
        
    
        //reasonbox
        NSString *reasonString = [[model currentQueryResults] objectForKey:@"reason"];
        if(!reasonString){
            reasonString = @"";
        }
        [updateReasonBox setStringValue:reasonString];
        
        //infoBox
        NSString *infoString = [[model currentQueryResults] objectForKey:@"info"];
        if(!infoString){
            infoString = @"";
        }
        [updateInfoForPull setStringValue:infoString];
        [self updateWindow];
        
        
    }
    
    @catch(NSException *e){
        NSLog(@"CouchDb Parse Error %@",e);
    }
    
}



//This function builds the actual resistor document that will be posted to couchDb
-(IBAction)updatePmtDatabase:(id)sender
{
    //fetch the values from the database
    
    int crateNumber = [[crateSelect stringValue] intValue];
    int cardNumber = [[cardSelect stringValue] intValue];
    int channelNumber = [[channelSelect stringValue] intValue];
    NSString *resistorStatus = [self parseStatusToResistorDb:[updateResistorStatus stringValue] withTrueStatement:@"1" withFalseStatement:@"0"];
    NSString *SNOLowOccString = [self parseStatusToResistorDb:[updateSnoLowOcc stringValue] withTrueStatement:@"1" withFalseStatement:@"0"];
    NSString *pmtRemovedString = [self parseStatusToResistorDb:[updatePmtRemoved stringValue] withTrueStatement:@"1" withFalseStatement:@"0"];
    NSString *pmtReinstalledString = [self parseStatusToResistorDb:[updatePmtReinstalled stringValue] withTrueStatement:@"1" withFalseStatement:@"0"];
    NSString *badCableString = [self parseStatusToResistorDb:[updateBadCable stringValue] withTrueStatement:@"1" withFalseStatement:@"0"];
    NSString *pulledCableString = [self parseStatusToResistorDb:[updatePulledCable stringValue] withTrueStatement:@"1" withFalseStatement:@"0"];
    
    NSString *reasonString;
    //if another reason is given then place this in the database otherwise use one of the default values
    if([[updateReasonBox stringValue] isEqualToString:@"OTHER"]){
        reasonString = [updateReasonOther stringValue]; //update from the other reason box
    }
    else{
        reasonString = [updateReasonBox stringValue];   //update from the reason string 
    }
    
    uint32_t currentRunNumber;
    currentRunNumber = [model getCurrentRunNumber];

    
    //Whenever we update the resistor document we are also going to need to change the run range
    NSMutableArray * runRange = [NSMutableArray arrayWithCapacity:20];
    [runRange setObject:[NSNumber numberWithInt:[[model startRunNumber] intValue]] atIndexedSubscript:0];
    [runRange setObject:[NSNumber numberWithInteger:currentRunNumber] atIndexedSubscript:1];
    
    //Update the old document with the new values
    NSMutableDictionary *oldResistorDocDic = [[model currentQueryResults] mutableCopy];
    [oldResistorDocDic setObject:runRange forKey:@"run_range"];
    
    /* Strictly only allow a run range were the currentRunNumber is larger than the current run number*/
    if(currentRunNumber >= [[model startRunNumber]intValue]){
        [model updateResistorDb:oldResistorDocDic];
    }
    [oldResistorDocDic release];
    
    
    NSMutableArray * newRunRange = [NSMutableArray arrayWithCapacity:20];
    [newRunRange setObject:[NSNumber numberWithInteger:(currentRunNumber + 1)] atIndexedSubscript:0];
    [newRunRange setObject:[NSNumber numberWithInt:-1] atIndexedSubscript:1];
    
    //Check the old runRange against the new runRange. If these are the same then we don't need to add a new document as it has already been updated. This will only occur if someone tries to update the resistor database on the same crate/card/channel combination within the same run.
    

    NSString *infoString = [updateInfoForPull stringValue];
    NSMutableDictionary* newResistorDoc = [NSMutableDictionary dictionaryWithCapacity:20];
    [newResistorDoc setObject:newRunRange forKey:@"run_range"];
    [newResistorDoc setObject:[NSNumber numberWithInt:cardNumber] forKey:@"slot"];
    [newResistorDoc setObject:infoString forKey:@"info"];
    [newResistorDoc setObject:pmtRemovedString forKey:@"PmtRemoved"];
    [newResistorDoc setObject:SNOLowOccString forKey:@"SnoLowOcc"];
    [newResistorDoc setObject:[[model currentQueryResults] objectForKey:@"SnoPmt"] forKey:@"SnoPmt"];
    [newResistorDoc setObject:[NSNumber numberWithInt:crateNumber] forKey:@"crate"];
    [newResistorDoc setObject:badCableString forKey:@"BadCable"];
    [newResistorDoc setObject:reasonString forKey:@"reason"];
    [newResistorDoc setObject:resistorStatus forKey:@"rPulled"];
    [newResistorDoc setObject:@"" forKey:@"NewPmt"];
    [newResistorDoc setObject:@"" forKey:@"date"];
    [newResistorDoc setObject:[NSNumber numberWithInt:[pulledCableString intValue]] forKey:@"pulledCable"];
    [newResistorDoc setObject:pmtReinstalledString forKey:@"PmtReInstalled"];
    [newResistorDoc setObject:[NSNumber numberWithInt:channelNumber] forKey:@"channel"];
    self.resistorDocDic = [[newResistorDoc mutableCopy] autorelease];
    [model checkIfDocumentExists:crateNumber withCard:cardNumber withChannel:channelNumber withRunRange:newRunRange];
    
    
}

-(void) updateCheckResistorDb
{
    [model addNeweResistorDoc:self.resistorDocDic];
    //update the current query value
    int crateNumber = [[crateSelect stringValue] intValue];
    int cardNumber = [[cardSelect stringValue] intValue];
    int channelNumber = [[channelSelect stringValue] intValue];
    //NSLog(@"value: %i %i %i\n",crateNumber,cardNumber,channelNumber);
    [loadingFromDbWheel setHidden:NO];
    [loadingFromDbWheel startAnimation:nil];
    [model queryResistorDb:crateNumber withCard:cardNumber withChannel:channelNumber];
}

-(void) noNewDocumentRequired
{
    [model updateResistorDb:self.resistorDocDic];
    //update the current query value
    int crateNumber = [[crateSelect stringValue] intValue];
    int cardNumber = [[cardSelect stringValue] intValue];
    int channelNumber = [[channelSelect stringValue] intValue];
    //NSLog(@"value: %i %i %i\n",crateNumber,cardNumber,channelNumber);
    [loadingFromDbWheel setHidden:NO];
    [loadingFromDbWheel startAnimation:nil];
    [model queryResistorDb:crateNumber withCard:cardNumber withChannel:channelNumber];
}

- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	[super registerNotificationObservers];
    
	[notifyCenter addObserver : self
                     selector : @selector(resistorDbQueryLoaded)
                         name : resistorDBQueryLoaded
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(updateCheckResistorDb)
                         name : ORResistorDocNotExists
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(noNewDocumentRequired)
                         name : ORResistorDocExists
                        object: model];
    
}

@end
