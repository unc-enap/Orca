//  ORCalibrationPane.m
//  Orca
//
//  Created by Mark Howe on 3/21/08.
//  Copyright 2008 CENPA, University of Washington. All rights reserved.
//
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

#import "ORCalibration.h"
#import "ORDataSetModel.h"

@implementation ORCalibrationPane

@synthesize calibration;

+ (id) calibrateForWindow:(NSWindow *)aWindow modalDelegate:(id)aDelegate didEndSelector:(SEL)aDidEndSelector contextInfo:(id)aContextInfo
{
    ORCalibrationPane* calibrationPane = [[ORCalibrationPane alloc] initWithModel:[aDelegate model]];
    [calibrationPane beginSheetFor:aWindow delegate:aDelegate didEndSelector:aDidEndSelector contextInfo:aContextInfo];
    return [calibrationPane autorelease];
}

- (id) initWithModel:(id)aModel
{
    self = [super initWithWindowNibName:@"Calibration"];
    model = aModel;
	return self;
}

- (void) dealloc
{
    self.calibration = nil;
	[super dealloc];
}

- (void) awakeFromNib
{
	[self populateSelectionPU];
    [self loadUI];
}

- (void) loadUI
{
	if(self.calibration == nil){
        if([model calibration]) self.calibration = [model calibration];
        else                    self.calibration = [[[ORCalibration alloc]init] autorelease];
    }

    [calibrationTableView reloadData];

    [unitsField setStringValue:[calibration units]];
    [labelField setStringValue:[calibration label]];
    [nameField setStringValue:[calibration calibrationName]];
    [ignoreButton setIntValue:[calibration ignoreCalibration]];
    [catalogButton setIntValue:[calibration type]];
    [customButton setIntValue:![calibration type]];
    if([[calibration calibrationName] length]){
        if([selectionPU indexOfItemWithTitle:[calibration calibrationName]] >=0){
            [selectionPU selectItemWithTitle:[calibration calibrationName]];
        }
        else [selectionPU selectItemWithTitle:@"---"];;
    }
    else [selectionPU selectItemWithTitle:@"---"];
	
    [customButton setIntValue:![calibration type]];

	[self enableControls];
}


- (void) beginSheetFor:(NSWindow *)aWindow delegate:(id)aDelegate didEndSelector:(SEL)aDidEndSelector contextInfo:(id)aContextInfo
{
 //   [NSApp beginSheet:[self window] modalForWindow:aWindow modalDelegate:aDelegate didEndSelector:aDidEndSelector contextInfo:aContextInfo];
    
    [aWindow beginSheet:[self window] completionHandler:^(NSModalResponse returnCode){
        NSInvocation* callBack = [NSInvocation invocationWithMethodSignature:[aDelegate methodSignatureForSelector:aDidEndSelector]];
        [callBack setSelector:aDidEndSelector];
        NSWindow* aPanel = [self window];
        [callBack setArgument:&aPanel atIndex:2];
        [callBack setArgument:&returnCode atIndex:3];
        [callBack setArgument:aContextInfo atIndex:4];
        [callBack performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:YES];
    }];
    
//    - (void) _calibrationDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo

}

- (void) calibrate
{
	if(![[self window] makeFirstResponder:[self window]]){
		[[self window] endEditingFor:nil];		
	}

	[calibration setUnits:[unitsField stringValue]];
	[calibration setLabel:[labelField stringValue]];
	[calibration setCalibrationName:[nameField stringValue]];
	[calibration setType:![customButton intValue]];
	[calibration setIgnoreCalibration:[ignoreButton intValue]];
	
	if([storeButton intValue]== 1 && [[nameField stringValue] length]){
	
		NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
		NSMutableDictionary* calDic = [NSMutableDictionary dictionaryWithDictionary:[defaults dictionaryForKey:@"ORCACalibrations"]];
		if(!calDic) calDic = [NSMutableDictionary dictionaryWithCapacity:10];
			
		NSMutableData*   calAsData     = [NSMutableData data];
		NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:calAsData];
		[archiver encodeObject:calibration forKey:@"aCalibration"];
		[archiver finishEncoding];		
		[archiver release];
		
		[calDic setObject:calAsData forKey:[nameField stringValue]];
		[defaults setObject:calDic forKey:@"ORCACalibrations"];
		
		[defaults synchronize];
		
		[self populateSelectionPU];
		[selectionPU selectItemWithTitle:[nameField stringValue]];
	}
    [calibration calibrate];
}

- (void) populateSelectionPU
{
	[selectionPU removeAllItems];
	[selectionPU addItemWithTitle:@"---"];
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary* calDictionary = [defaults objectForKey:@"ORCACalibrations"];
	NSArray* keys = [calDictionary allKeys];
	if([keys count]){
		NSArray* sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
		[selectionPU addItemsWithTitles:sortedKeys];
	}
}

- (void) enableControls
{
	[calibrationTableView   setEnabled: [customButton intValue]  == 1];
	[addPtButton            setEnabled: [customButton intValue]  == 1];
	[removePtButton         setEnabled: [customButton intValue]  == 1];
	[unitsField             setEnabled: [customButton intValue]  == 1];
	[labelField             setEnabled: [customButton intValue]  == 1];
	[nameField              setEnabled: [customButton intValue]  == 1 &&
                                        [storeButton intValue] == 1];
	[storeButton            setEnabled: [customButton intValue]  == 1];
	
	[selectionPU            setEnabled: [catalogButton intValue] == 1];
	[deleteButton           setEnabled: [catalogButton intValue] == 1 &&
                                        [selectionPU indexOfSelectedItem] != 0];
	
	[cancelButton           setEnabled:[customButton intValue]  == 1];
	[applyButton            setEnabled:[customButton intValue]  == 1];
}

- (IBAction) storeAction:(id)sender
{
	[self enableControls];
}

- (IBAction) typeAction:(id)sender
{
	if(sender == customButton){
		[catalogButton setIntValue:0];
		[customButton setIntValue:1];
	}
	else {
		[catalogButton setIntValue:1];
		[customButton setIntValue:0];
        if([selectionPU indexOfSelectedItem]){
            [self selectionAction:nil];
        }
	}
	[self enableControls];
}

- (IBAction) selectionAction:(id)sender
{
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary* calDic = [defaults objectForKey:@"ORCACalibrations"];
	NSData*   calAsData     = [calDic objectForKey:[selectionPU titleOfSelectedItem]];
	if(calAsData){
		NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:calAsData];
		self.calibration = [unarchiver decodeObjectForKey:@"aCalibration"];
		[calibration setType:1];
		[calibration setCalibrationName:[selectionPU titleOfSelectedItem]];
		[unarchiver finishDecoding];
		[unarchiver release];
		[self loadUI];
	}
	else [self loadUI];

	[self calibrate];
    [model setCalibration:calibration];
}

- (IBAction) deleteAction:(id)sender
{	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary* calDic = [NSMutableDictionary dictionaryWithDictionary:[defaults dictionaryForKey:@"ORCACalibrations"]];
	[calDic removeObjectForKey:[selectionPU titleOfSelectedItem]];
	[defaults setObject:calDic forKey:@"ORCACalibrations"];
	[self populateSelectionPU];
	[selectionPU selectItemAtIndex:0];
	[self loadUI];
	if([selectionPU numberOfItems] > 1){
		[catalogButton setIntValue:1]; 
		[customButton setIntValue:0]; 
	}
	else {
		[catalogButton setIntValue:0]; 
		[customButton setIntValue:1]; 
	}
	[self enableControls];
}

- (IBAction) apply:(id)sender
{	
	[self calibrate];
    [model setCalibration:calibration];
}

- (IBAction) ignore:(id)sender
{
    [calibration setIgnoreCalibration:[sender intValue]];
    [self apply:sender];
}

- (IBAction) addPtAction:(id)sender
{
    [[calibration calibrationArray] addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:0],@"Channel",[NSNumber numberWithFloat:0],@"Energy",nil]];
	[calibrationTableView reloadData];
}

- (IBAction) removePtAction:(id)sender
{
	NSInteger selectedRow = [calibrationTableView selectedRow];
	if(selectedRow == -1){
		[[calibration calibrationArray] removeLastObject];
		[calibrationTableView reloadData];
	}
	else if(selectedRow<[[calibration calibrationArray] count]){
		[[calibration calibrationArray] removeObjectAtIndex:selectedRow];
		[calibrationTableView reloadData];
	}
}

- (IBAction) done:(id)sender
{	
	[self calibrate];
    [model setCalibration:calibration];

	[[self window] orderOut:self];
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    [NSApp endSheet:[self window] returnCode:NSModalResponseOK];
#else
    [NSApp endSheet:[self window] returnCode:NSOKButton];
#endif
}

- (IBAction) cancel:(id)sender
{
    [[self window] orderOut:self];
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    [NSApp endSheet:[self window] returnCode:NSModalResponseCancel];
#else 
    [NSApp endSheet:[self window] returnCode:NSCancelButton];
#endif
}

- (IBAction) remove:(id)sender
{
    [model setCalibration:nil];
    [[self window] orderOut:self];
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    [NSApp endSheet:[self window] returnCode:NSModalResponseOK];
#else
    [NSApp endSheet:[self window] returnCode:NSOKButton];
#endif
}

#pragma mark •••Table Data Source
- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
	if( aTableView == calibrationTableView)return [[calibration calibrationArray] count];
	else return 0;
}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) rowIndex
{
	if(aTableView == calibrationTableView ){
		return [[[calibration calibrationArray] objectAtIndex:rowIndex] objectForKey:[aTableColumn identifier]];
	}
	else return nil;
}

- (void) tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if(aTableView == calibrationTableView){
		[[[calibration calibrationArray] objectAtIndex:rowIndex] setObject: anObject forKey:[aTableColumn identifier]];
	}
}

@end

@implementation ORCalibration

- (void)dealloc
{
	[calibrationArray release];
	[calibrationName release];
	[units release];
	[label release];
	[super dealloc];
}

- (NSMutableArray*)calibrationArray
{
    if(!calibrationArray) calibrationArray = [[NSMutableArray array]retain];
	return calibrationArray;
}

- (BOOL) isValidCalibration
{
    return [[NSMutableArray arrayWithArray:calibrationArray] count]>0;
}

- (void) calibrate
{
	double SUMx = 0;
	double SUMy = 0;
	double SUMxy= 0;
	double SUMxx= 0;
	calibrationValid = NO;
    
    NSMutableArray* dataArray = [NSMutableArray arrayWithArray:calibrationArray];

	int n = (int)[dataArray count];
    
	if(n!=0){
        if(n==1){
            [dataArray insertObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:0],@"Channel",[NSNumber numberWithDouble:0],@"Energy", nil] atIndex:0];
            n = (int)[dataArray count];
        }
		for(id pt in dataArray){
			double x = [[pt objectForKey:@"Channel"] doubleValue];
			double y = [[pt objectForKey:@"Energy"] doubleValue];
			SUMx = SUMx + x;
			SUMy = SUMy + y;
			SUMxy = SUMxy + x*y;
			SUMxx = SUMxx + x*x;
		}
		if((SUMx*SUMx - n*SUMxx) != 0){
			slope = ( SUMx*SUMy - n*SUMxy ) / (SUMx*SUMx - n*SUMxx);
			intercept = ( SUMy - slope*SUMx ) / n;
			calibrationValid = YES;
		}
        else {
            NSLog(@"Invalid Calibration: sum of the x values is zero\n");   
        }
	}
    else {
        NSLog(@"Invalid Calibration: you must enter at least one set of values\n");
    }
}

- (double) slope
{
	return slope;
}

- (double) intercept
{
	return intercept;
}

- (BOOL) ignoreCalibration
{
	return ignoreCalibration;
}

- (void) setIgnoreCalibration:(BOOL)aState
{
	ignoreCalibration = aState;
}

- (void) setType:(int)aType
{
	type = aType;
}

- (int) type
{
	return type;
}

- (NSString*) units
{
	if(!units)return @"keV";
	else return units;
}

- (void) setUnits:(NSString*)unitString
{
	if([unitString length]==0) unitString = @"keV";
	[units autorelease];
	units = [unitString copy];
}


- (NSString*) label
{
	if([label length]==0)return @"Energy";
	else return label;
}

- (void) setLabel:(NSString*)aString
{
	if([aString length]==0) label = @"Energy";
	[label autorelease];
	label = [aString copy];
}

- (void) setCalibrationName:(NSString*)nameString
{
    if([nameString length]==0) nameString = @"";
	[calibrationName autorelease];
	calibrationName = [nameString copy];
}

- (NSString*) calibrationName
{
    if([calibrationName length]==0) return @"";
	else return calibrationName;
}

- (BOOL) useCalibration
{
	return !ignoreCalibration && calibrationValid;
}

- (double) convertedValueForChannel:(int)aChannel
{
	return (double)aChannel*slope + intercept;
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self		= [super init];
    calibrationArray =			[[decoder decodeObjectForKey: @"calibrationArray"] retain];
	[self setUnits:				[decoder  decodeObjectForKey: @"units"]];
	[self setLabel:				[decoder  decodeObjectForKey: @"label"]];
	[self setIgnoreCalibration:	[decoder  decodeBoolForKey:   @"ignoreCalibration"]];
	[self setCalibrationName:	[decoder  decodeObjectForKey: @"calibrationName"]];
	[self setType:				[decoder  decodeIntForKey:    @"type"]];
	[self calibrate];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:calibrationArray	forKey: @"calibrationArray"];
	[encoder encodeObject:units				forKey: @"units"];
	[encoder encodeObject:label				forKey: @"label"];
	[encoder encodeBool:ignoreCalibration	forKey: @"ignoreCalibration"];
	[encoder encodeObject:calibrationName	forKey: @"calibrationName"];
	[encoder encodeInteger:type					forKey: @"type"];
}


@end
