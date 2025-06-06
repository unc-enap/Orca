//
//  ResistorDBViewController.h
//  Orca
//
//  Created by Chris Jones on 28/04/2014.
//
//

#import <Cocoa/Cocoa.h>

@interface ResistorDBViewController : OrcaObjectController {
    
    IBOutlet NSButton *queryDBButton;
    IBOutlet NSComboBox *crateSelect;
    IBOutlet NSComboBox *cardSelect;
    IBOutlet NSComboBox *channelSelect;
    IBOutlet NSTextField *currentResistorStatus;
    IBOutlet NSTextField *currentSNOLowOcc;
    IBOutlet NSTextField *currentPMTRemoved;
    IBOutlet NSTextField *currentPMTReinstallled;
    IBOutlet NSTextField *currentPulledCable;
    IBOutlet NSTextField *currentBadCable;
    IBOutlet NSTextField *currentReason;
    IBOutlet NSTextField *currentInfo;
    
    
    IBOutlet NSComboBox *updateResistorStatus;
    IBOutlet NSComboBox *updateSnoLowOcc;
    IBOutlet NSComboBox *updatePmtRemoved;
    IBOutlet NSComboBox *updatePmtReinstalled;
    IBOutlet NSComboBox *updateBadCable;
    IBOutlet NSComboBox *updatePulledCable;
    
    IBOutlet NSComboBox *updateReasonBox;
    IBOutlet NSTextField *updateReasonOther;
    IBOutlet NSTextField *updateInfoForPull;
    IBOutlet NSButton *updateDbButton;
    NSProgressIndicator *loadingFromDbWheel;
    NSMutableDictionary *_resistorDocDic;
}

@property (nonatomic,copy) NSMutableDictionary* resistorDocDic;

-(id)init;
-(void)dealloc;
-(void) updateWindow;
-(void) registerNotificationObservers;
-(void) resistorDbQueryLoaded;
-(NSString*) parseStatusFromResistorDb:(NSString*)aKey withTrueStatement:(NSString*)aTrueStatement withFalseStatement:(NSString*)aFalseStatement;

@end
