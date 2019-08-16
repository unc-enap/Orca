#import "OrcaObjectController.h"

@interface ORFlashCamController : OrcaObjectController
{
    IBOutlet NSTextField* ipAddressTextField;
    IBOutlet NSTextField* usernameTextField;
    IBOutlet NSTextField* ethInterfaceTextField;
    IBOutlet NSTextField* ethTypeTextField;
    IBOutlet NSTextField* boardAddressTextField;
    IBOutlet NSPopUpButton* traceTypeButton;
    IBOutlet NSTextField* signalDepthTextField;
    IBOutlet NSTextField* postTriggerTextField;
    IBOutlet NSTextField* baselineOffsetTextField;
    IBOutlet NSTextField* baselineBiasTextField;
    IBOutlet NSTextField* remoteDataPathTextField;
    IBOutlet NSTextField* remoteFilenameTextField;
    IBOutlet NSTextField* runNumberTextField;
    IBOutlet NSTextField* runCountTextField;
    IBOutlet NSTextField* runLengthTextField;
    IBOutlet NSButton* runUpdateButton;
    IBOutlet NSButton* sendPingButton;
    IBOutlet NSButton* startRunButton;
    IBOutlet NSButton* killRunButton;
    IBOutlet NSMatrix* chanEnabledMatrix;
    IBOutlet NSMatrix* thresholdMatrix;
    IBOutlet NSMatrix* poleZeroMatrix;
    IBOutlet NSMatrix* shapeTimeMatrix;
}

#pragma mark ***Initialization
- (id) init;
- (void) dealloc;
- (void) registerNotificationObservers;
- (void) awakeFromNib;
- (void) updateWindow;

#pragma mark ***Interface Management
- (void) ipAddressChanged:(NSNotification*)note;
- (void) usernameChanged:(NSNotification*)note;
- (void) ethInterfaceChanged:(NSNotification*)note;
- (void) ethTypeChanged:(NSNotification*)note;
- (void) boardAddressChanged:(NSNotification*)note;
- (void) traceTypeChanged:(NSNotification*)note;
- (void) signalDepthChanged:(NSNotification*)note;
- (void) postTriggerChanged:(NSNotification*)note;
- (void) baselineOffsetChanged:(NSNotification*)note;
- (void) baselineBiasChanged:(NSNotification*)note;
- (void) remoteDataPathChanged:(NSNotification*)note;
- (void) remoteFilenameChanged:(NSNotification*)note;
- (void) runNumberChanged:(NSNotification*)note;
- (void) runCountChanged:(NSNotification*)note;
- (void) runLengthChanged:(NSNotification*)note;
- (void) runUpdateChanged:(NSNotification*)note;
- (void) chanEnabledChanged:(NSNotification*)note;
- (void) thresholdChanged:(NSNotification*)note;
- (void) poleZeroChanged:(NSNotification*)note;
- (void) shapeTimeChanged:(NSNotification*)note;
- (void) pingStart:(NSNotification*)note;
- (void) pingEnd:(NSNotification*)note;
- (void) runInProgress:(NSNotification*)note;
- (void) runEnded:(NSNotification*)note;
- (void) settingsLock:(bool)lock;

#pragma mark ***Actions
- (IBAction) ipAddressAction:(id)sender;
- (IBAction) usernameAction:(id)sender;
- (IBAction) ethInterfaceAction:(id)sender;
- (IBAction) ethTypeAction:(id)sender;
- (IBAction) boardAddressAction:(id)sender;
- (IBAction) traceTypeAction:(id)sender;
- (IBAction) signalDepthAction:(id)sender;
- (IBAction) postTriggerAction:(id)sender;
- (IBAction) baselineOffsetAction:(id)sender;
- (IBAction) baselineBiasAction:(id)sender;
- (IBAction) remoteDataPathAction:(id)sender;
- (IBAction) remoteFilenameAction:(id)sender;
- (IBAction) runNumberAction:(id)sender;
- (IBAction) runCountAction:(id)sender;
- (IBAction) runLengthAction:(id)sender;
- (IBAction) runUpdateAction:(id)sender;
- (IBAction) sendPingAction:(id)sender;
- (IBAction) startRunAction:(id)sender;
- (IBAction) killRunAction:(id)sender;
- (IBAction) chanEnabledAction:(id)sender;
- (IBAction) thresholdAction:(id)sender;
- (IBAction) poleZeroAction:(id)sender;
- (IBAction) shapeTimeAction:(id)sender;

@end
