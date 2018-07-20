
//
//  ORMacController.m
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
#import "ORMacController.h"
#import "ORMacModel.h"
#import "ORGroupView.h"
#import "ORPciCard.h"
#import "ORSerialPort.h"
#import "ORSerialPortList.h"
#import "ORSerialPortAdditions.h"

#import "ORUSB.h"
#import "ORUSBInterface.h"
#import "ORSerialPortList.h"

@interface ORMacController (private)
- (void) setSpeedPopup:(NSDictionary*)options port:(ORSerialPort*)thePort;
- (void) setParityPopup:(NSDictionary*)options port:(ORSerialPort*)thePort;
- (void) setStopBitsPopup:(NSDictionary*)options port:(ORSerialPort*)thePort;
- (void) setDataBitsPopup:(NSDictionary*)options port:(ORSerialPort*)thePort;
@end

@implementation ORMacController

- (id) init
{
    self = [super initWithWindowNibName:@"Mac"];
    return self;
}

- (void) dealloc
{
    [blankView release];
    [super dealloc];
}

- (void) awakeFromNib
{
	[super awakeFromNib];
    pciSize     = NSMakeSize(217,355);
    serialSize	= NSMakeSize(365,355);
    usbSize     = NSMakeSize(305,395);
    blankView   = [[NSView alloc] init];

	[groupView setGroup:model];
    [self reloadSerialPortList];

    [tabView selectTabViewItemAtIndex: 0];
}

#pragma mark ¥¥¥Accessors
- (ORGroupView *)groupView
{
    return [self groupView];
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [groupView setGroup:(ORGroup*)aModel];
}

- (NSTabView*) tabView
{
    return tabView;
}

- (void) selectPortAtIndex:(int)index
{
    [serialPortView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];

}
#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter]; 
    [super   registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(updateWindow)
                         name : ORGroupObjectsAdded
                       object : nil];
                       
    [notifyCenter addObserver : self
                     selector : @selector(updateWindow)
                         name : ORGroupObjectsRemoved
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupSelectionChanged
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(documentLockChanged:)
                         name : ORDocumentLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(documentLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(updateWindow)
                         name : OROrcaObjectMoved
                       object : nil];


    [notifyCenter addObserver : self
                     selector : @selector(updateWindow)
                         name : ORSerialPortStateChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(updateUSBView)
                         name : ORUSBRegisteredObjectChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(updateUSBView)
                         name : ORMacModelUSBChainVerified
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(updateUSBView)
                         name : ORMacModelUSBChainVerified
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(updateUSBView)
                         name : ORUSBDevicesAdded
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(updateUSBView)
                         name : ORUSBDevicesRemoved
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(eolTypeChanged:)
                         name : ORMacModelEolTypeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(tableViewSelectionDidChange:)
                         name : NSTableViewSelectionDidChangeNotification
						object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(serialPortListChanged:)
                         name : ORSerialPortListChanged
                        object: nil];
}

- (void) tableViewSelectionDidChange:(NSNotification*)aNote
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter]; 
	[notifyCenter removeObserver:self name:ORSerialPortDataReceived object:nil];
	if([aNote object] == serialPortView || !aNote){
		int32_t index = (int32_t)[serialPortView selectedRow];
		if(index >= 0){
            ORSerialPort* thePort = [[ORSerialPortList sharedSerialPortList] objectAtIndex: index];
			[selectedPortNameField setStringValue:[thePort name]];
			[openPortButton setEnabled:YES];
            NSDictionary* options = [thePort getOptions];
            [self setSpeedPopup:options port:thePort];
            [self setParityPopup:options port:thePort];
            [self setStopBitsPopup:options port:thePort];
            [self setDataBitsPopup:options port:thePort];

			[notifyCenter addObserver : self
							 selector : @selector(dataReceived:)
								 name : ORSerialPortDataReceived
							   object : thePort];
			
			if([thePort isOpen]){
                [sendCmdButton      setEnabled:YES];
                [sendCntrlCButton   setEnabled:YES];
				[clearDisplayButton setEnabled:YES];
				
				[openPortButton setTitle:@"Close"];
			}
			else {
				[outputView setString:@""];

				[sendCmdButton      setEnabled:NO];
                [sendCntrlCButton   setEnabled:NO];
				[clearDisplayButton setEnabled:NO];
				
				[openPortButton setTitle:@"Open"];
//                [self setSpeedPopup:nil port:thePort];
//                [self setParityPopup:nil port:thePort];
//                [self setStopBitsPopup:nil port:thePort];
//                [self setDataBitsPopup:nil port:thePort];
			}
		}
		else {
			[sendCmdButton      setEnabled:NO];
            [sendCntrlCButton   setEnabled:NO];
			[clearDisplayButton setEnabled:NO];
			[selectedPortNameField setStringValue:@"---"];
			[openPortButton setEnabled:NO];
			[openPortButton setTitle:@"---"];
//            [self setSpeedPopup:nil port:nil];
//            [self setParityPopup:nil port:nil];
//            [self setStopBitsPopup:nil port:nil];
//            [self setDataBitsPopup:nil port:nil];
		}
	}

	if([aNote object] == usbDevicesView  || !aNote){
		int32_t index = (int32_t)[usbDevicesView selectedRow];
		if(index>=0 && [model usbDeviceCount]>0)[usbDetailsView setString:[[model usbDeviceAtIndex:index] usbInterfaceDescription]];
		else [usbDetailsView setString:@"<nothing selected>"];
	}
}


- (void) documentLockChanged:(NSNotification*)aNotification
{
    if([gSecurity isLocked:ORDocumentLock]) [lockDocField setStringValue:@"Document is locked."];
    else if([gOrcaGlobals runInProgress])   [lockDocField setStringValue:@"Run In Progress"];
    else                                    [lockDocField setStringValue:@""];
}

- (void) updateWindow
{
    [self documentLockChanged:nil];
    [self tableViewSelectionDidChange:nil];
    [groupView setNeedsDisplay:YES];
    [self reloadSerialPortList];
	int32_t index = (uint32_t)[usbDevicesView selectedRow];
	if(index>=0 && [model usbDeviceCount]>0)[usbDetailsView setString:[[model usbDeviceAtIndex:index] usbInterfaceDescription]];
	else [usbDetailsView setString:@"<nothing selected>"];
	[self eolTypeChanged:nil];
}

- (void) serialPortListChanged:(NSNotification*)aNote
{
    [self reloadSerialPortList];
    [self tableViewSelectionDidChange:nil];
}

- (void) reloadSerialPortList
{
    [serialPortView reloadData];
}

- (void) eolTypeChanged:(NSNotification*)aNote
{
	[eolTypeMatrix selectCellWithTag: [model eolType]];
}

- (void) updateUSBView
{
    [usbDevicesView reloadData];
	
	int32_t index = (uint32_t)[usbDevicesView selectedRow];
	if(index>=0 && [model usbDeviceCount]>0)[usbDetailsView setString:[[model usbDeviceAtIndex:index] usbInterfaceDescription]];
	else [usbDetailsView setString:@"<nothing selected>"];
}

- (void) isNowKeyWindow:(NSNotification*)aNotification
{
	[[self window] makeFirstResponder:(NSResponder*)groupView];
}

- (void) groupChanged:(NSNotification*)note
{
	[self updateWindow];
}

- (void) dataReceived:(NSNotification*)note
{
    int32_t index = (uint32_t)[serialPortView selectedRow];
    if(index >=0){
        ORSerialPort* thePort = [[ORSerialPortList sharedSerialPortList] objectAtIndex:index];
        if([[note userInfo] objectForKey:@"serialPort"] == thePort){
			//it's possible the data is non-ascii. We'll keep only the ascii part for display.
			NSMutableData* theData = [NSMutableData dataWithData:[[note userInfo] objectForKey:@"data"]];
			char* p = (char*)[theData bytes];
			NSString* theString = @"<non ascii>";
			if((p[0]>= 0x20) || (p[0]== 0xA) || (p[0]== 0xD)){
				int i;
				for(i=0;i<[theData length];i++){
					if((p[i]< 0x20) && (p[i]!= 0xA) && (p[i]!= 0xD)){
						[theData setLength:i];
						break;
					}
				}
				theString = [[[NSString alloc] initWithData:theData encoding:NSASCIIStringEncoding] autorelease];
			}

            theString = [theString stringByReplacingOccurrencesOfString:@"\r" withString:@"<CR>"];
            theString = [theString stringByReplacingOccurrencesOfString:@"\n" withString:@"<LF>"];
            theString = [theString stringByAppendingString:@"\n"];
			[model setLastStringReceived:theString];
            [outputView replaceCharactersInRange:NSMakeRange([[outputView textStorage] length], 0) withString:theString];
            [outputView scrollRangeToVisible: NSMakeRange([[outputView textStorage] length], 0)];
            
            if([[outputView textStorage] length] > 10*1024){
                [[outputView textStorage] deleteCharactersInRange:NSMakeRange(0,10*1024/3)];
                NSRange endOfLineRange = [[outputView string] rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\n"]];
               // int extra = 0;
                if(endOfLineRange.location != NSNotFound){
                    [[outputView textStorage] deleteCharactersInRange:NSMakeRange(0,endOfLineRange.location)];
                    //extra = endOfLineRange.location;
                }
            }
        }
    }
}


#pragma mark ¥¥¥Actions
- (IBAction) listSupportedUSBDevices:(id)sender
{
	[[model getUSBController] listSupportedDevices];
}

- (IBAction) eolTypeAction:(id)sender
{
	[model setEolType:(int)[[sender selectedCell] tag]];
}

- (IBAction) openPortAction:(id)sender
{
    int32_t index = (uint32_t)[serialPortView selectedRow];
    if(index >=0){
        ORSerialPort* thePort = [[ORSerialPortList sharedSerialPortList] objectAtIndex:index];
        if([thePort isOpen]){
            [thePort close];
        }
        else  {
            [thePort open];
        }
        [self reloadSerialPortList];
        [self tableViewSelectionDidChange:nil];
    }
}

- (IBAction) optionAction:(id)sender
{
    int32_t index = (uint32_t)[serialPortView selectedRow];
    if(index >=0){
        ORSerialPort* thePort = [[ORSerialPortList sharedSerialPortList] objectAtIndex:index];
        if([thePort isOpen]){
            //get the current options
            NSMutableDictionary* options = [[[thePort getOptions] mutableCopy] autorelease];
            //do the speed
            if([speedPopUp indexOfSelectedItem] != 0){
                [options setObject:[[speedPopUp selectedItem] title] forKey:ORSerialOptionSpeed];
            }
             //do the parity
            if([parityPopUp indexOfSelectedItem] != 0){
                if([parityPopUp indexOfSelectedItem] == 1) { //NONE
                    [options removeObjectForKey:ORSerialOptionParity];
                }
                else  [options setObject:[[parityPopUp selectedItem] title] forKey:ORSerialOptionParity];
            }
             //do the stop bits
            if([stopBitsPopUp indexOfSelectedItem] != 0){
                [options setObject:[[stopBitsPopUp selectedItem] title] forKey:ORSerialOptionStopBits];
            }
             //do the data bits
            if([dataBitsPopUp indexOfSelectedItem] != 0){
                [options setObject:[[dataBitsPopUp selectedItem] title] forKey:ORSerialOptionDataBits];
            }
            [thePort setOptions:options];
        }
    }
}

- (IBAction) clearDisplayAction:(id)sender
{
	[outputView setString:@""];
}

- (IBAction) sendAction:(id)sender
{
    [self endEditing];
    int32_t index = (uint32_t)[serialPortView selectedRow];
    if(index >= 0){
        ORSerialPort* thePort = [[ORSerialPortList sharedSerialPortList] objectAtIndex:index];
        if([thePort isOpen]){
            if([cmdField stringValue]!=nil){
				int eolType = [model eolType];
				NSString* theCmd  = [[cmdField stringValue] removeNLandCRs];
				switch(eolType){
					case 1: theCmd = [theCmd stringByAppendingString:@"\r"]; break;
					case 2: theCmd = [theCmd stringByAppendingString:@"\n"]; break;
					case 3: theCmd = [theCmd stringByAppendingString:@"\r\n"]; break;
				}
                [thePort writeString:theCmd];
            }
        }
    }
}
- (IBAction) sendCntrlCAction:(id)sender
{
    NSInteger index = [serialPortView selectedRow];
    if(index >= 0){
        ORSerialPort* thePort = [[ORSerialPortList sharedSerialPortList] objectAtIndex:index];
        if([thePort isOpen]){
            [thePort writeString:[NSString stringWithFormat:@"%c",0x03]]; //0x03 is control-C
        }
    }
}

#pragma mark ¥¥¥Delegate Methods
- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [[self window] setContentView:blankView];
    switch([tabView indexOfTabViewItem:tabViewItem]){
        case 0:  [self resizeWindowToSize:pciSize];      break;
        case 1:  [self resizeWindowToSize:serialSize];   break;
        case 2:  [self resizeWindowToSize:usbSize];   break;
        default: [self resizeWindowToSize:serialSize];   break;
    }
    [[self window] setContentView:tabView];
                
}


#pragma mark ¥¥¥Data Source Methods
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) rowIndex
{
	if(aTableView == serialPortView){
        ORSerialPort* aPort = [[ORSerialPortList sharedSerialPortList] objectAtIndex:rowIndex];
        if([[aTableColumn identifier] isEqualToString:@"name"])return [aPort name];
        else if([[aTableColumn identifier] isEqualToString:@"bsdPath"])return [aPort bsdPath];
        else
            if([[aTableColumn identifier] isEqualToString:@"state"])return [aPort isOpen]?@"open":@"closed";
        else return @"";
	}
	else {
		if(rowIndex >= 0 && rowIndex < [model usbDeviceCount]){
			return [[model usbDeviceAtIndex:rowIndex] valueForKey:[aTableColumn identifier]];
		}
		else return nil;
	}
}

// just returns the number of items we have.
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if(aTableView == serialPortView){
		return [[ORSerialPortList sharedSerialPortList] count];
	}
	else if(aTableView == usbDevicesView){
		NSInteger n =  [model usbDeviceCount];
		if(n==0)[usbDetailsView setString:@""];
		return n;
	}
	else return 0;
}

@end

@implementation ORMacController (private)
- (void) setSpeedPopup:(NSDictionary*)options port:(ORSerialPort*)thePort
{
    if(options && [thePort isOpen]){
       [speedPopUp setEnabled:YES];
        NSString* speedString = [options objectForKey:ORSerialOptionSpeed];
        [speedPopUp selectItemWithTitle:speedString];
    }
    else {
        [speedPopUp setEnabled:NO];
        [speedPopUp selectItemAtIndex:0];
    }
}

- (void) setParityPopup:(NSDictionary*)options port:(ORSerialPort*)thePort
{
    if(options && [thePort isOpen]){
        [parityPopUp setEnabled:YES];
        NSString* parityString = [options objectForKey:ORSerialOptionParity];
        if(parityString)[parityPopUp selectItemWithTitle:parityString];
        else [parityPopUp selectItemAtIndex:1]; //NONE
    }
    else {
        [parityPopUp setEnabled:NO];
        [parityPopUp selectItemAtIndex:0];
    }
}

- (void) setStopBitsPopup:(NSDictionary*)options port:(ORSerialPort*)thePort
{
    if(options && [thePort isOpen]){
        [stopBitsPopUp setEnabled:YES];
        NSString* stopBitsString = [options objectForKey:ORSerialOptionStopBits];
        [stopBitsPopUp selectItemWithTitle:stopBitsString];
    }
    else {
        [stopBitsPopUp setEnabled:NO];
        [stopBitsPopUp selectItemAtIndex:0];
    }
}

- (void) setDataBitsPopup:(NSDictionary*)options port:(ORSerialPort*)thePort
{
    if(options && [thePort isOpen]){
        [dataBitsPopUp setEnabled:YES];
        NSString* dataBitsString = [options objectForKey:ORSerialOptionDataBits];
        [dataBitsPopUp selectItemWithTitle:dataBitsString];
    }
    else {
        [dataBitsPopUp setEnabled:NO];
        [dataBitsPopUp selectItemAtIndex:0];
    }
}

@end
