//
//  GoTo.h
//  ORCA
//
//  Created by Mark Howe on 1/3/07.
//  Copyright 2007 CENPA, University of Washington. All rights reserved.
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

#import "ORTemplates.h"
#import "ObjectFactory.h"
#import "ORFanOutModel.h"
#import "ORCrate.h"

@interface ORTemplates (private)
- (void) makeDataChain1;
- (void) makeDataChain2;
- (void) makeVmeBit3;
- (void) makeVmeSBC;
- (void) makeCAMAC;
- (void) makecPCI;
- (void) makeIPE;
- (void) makeIPEV4;
- (void) makeMCA;
- (void) makeObjects:(templateObjs*)objsToMake withConnections:(templateConnections*)connectionsToMake;
@end

@implementation ORTemplates
- (void) showPanel
{
	[dataChainMatrix selectCellWithTag:1];
	[noHWOption setState:NSOnState];
	[vmeOption setState:NSOffState];
	[camacOption setState:NSOffState];
	[cPCIOption setState:NSOffState];
	[ipeOption setState:NSOffState];
	[mcaOption setState:NSOffState];
	[ipeV4Option setState:NSOffState];
	[vme64Matrix setEnabled:NO];
	[vmeAdapterMatrix setEnabled:NO];
    [mainWindow beginSheet:templateSheet completionHandler:nil];
}


- (IBAction)done:(id)sender
{	
	int dataChainOption = (int)[[dataChainMatrix selectedCell] tag];
	
	if(dataChainOption==1)		[self makeDataChain1];
	else if(dataChainOption==2)	[self makeDataChain2];
	
	if([vmeOption state]){
		int vmeAdapterOption = (int)[[vmeAdapterMatrix selectedCell] tag];
		if(vmeAdapterOption == 0)   [self makeVmeBit3];
		else						[self makeVmeSBC];
	}
	
	else if([camacOption state]) [self makeCAMAC];
	else if([cPCIOption state])  [self makecPCI];
	else if([ipeOption state])   [self makeIPE];
	else if([mcaOption state])   [self makeMCA];
	else if([ipeV4Option state]) [self makeIPEV4];
	
	
    [templateSheet orderOut:nil];
    [NSApp endSheet:templateSheet];
	if(![mainWindow isZoomed])[mainWindow zoom:self];
}

- (IBAction)cancel:(id)sender
{
    [templateSheet orderOut:nil];
    [NSApp endSheet:templateSheet];
}

- (IBAction)hwSelectOption:(id)sender
{
	[noHWOption	 setState:NSOffState];
	[vmeOption	 setState:NSOffState];
	[camacOption setState:NSOffState];
	[cPCIOption	 setState:NSOffState];
	[ipeOption	 setState:NSOffState];
	[mcaOption	 setState:NSOffState];
	[ipeV4Option setState:NSOffState];

	if(sender == cPCIPic)		[cPCIOption setState:NSOnState];
	else if(sender == camacPic)	[camacOption setState:NSOnState];
	else if(sender == vmePic)	[vmeOption setState:NSOnState];
	else if(sender == ipePic)	[ipeOption setState:NSOnState];
	else if(sender == ipeV4Pic)	[ipeV4Option setState:NSOnState];
	else if(sender == mcaPic)	[mcaOption setState:NSOnState];
	else						[sender setState:NSOnState];

	[vme64Matrix      setEnabled:[vmeOption state]];
	[vmeAdapterMatrix setEnabled:[vmeOption state]];
	
}
@end

@implementation ORTemplates (private)

- (void) makeDataChain1
{
	static templateObjs objs[] = {
		{@"ORRunModel",		  50, 520, 0,-1},
		{@"ORDataTaskModel", 130, 500, 0,-1},
		{@"ORFanOutModel",	 270, 525, 0,-1},
		{@"ORDataFileModel", 350, 580, 0,-1},
		{@"ORHistoModel",	 350, 480, 0,-1},
		{nil,0,0,0,0} //must be last
	};
	static templateConnections connectInfo[] = {
		{0, @"Run Control Connector",	      1, @"Data Task In Connector"},
		{1, @"Data Task Data Out Connector",  2, @"Fan In Input Connector"},
		{2, @"Fan In Output Connector 2",     3, @"Data File Input Connector"},
		{2, @"Fan In Output Connector 1",     4, @"Histogrammer Data Connector"},
		{0,nil,0,nil} //must be last
	};
	[self makeObjects:objs withConnections:connectInfo];

}

- (void) makeDataChain2
{
	static templateObjs objs[] = {
		{@"ORRunModel",		   60, 520, 0,-1},
		{@"ORDataTaskModel",  130, 500, 0,-1},
		{@"ORFanOutModel",	  260, 512, 3,-1}, //used to denote the number of outputs
		{@"ORDataFileModel",  330, 580, 0,-1},
		{@"ORHistoModel",	  330, 430, 0,-1},
		{@"ORDispatcherModel",330, 509, 0,-1},		
		{nil,0,0,0,0} //must be last

	};
	static templateConnections connectInfo[] = {
		{0, @"Run Control Connector",	      1, @"Data Task In Connector"},
		{1, @"Data Task Data Out Connector",  2, @"Fan In Input Connector"},
		{2, @"Fan In Output Connector 3",     3, @"Data File Input Connector"},
		{2, @"Fan In Output Connector 1",     4, @"Histogrammer Data Connector"},
		{2, @"Fan In Output Connector 2",     5, @"Dispatcher Connector"},
		{0,nil,0,nil} //must be last

	};
	[self makeObjects:objs withConnections:connectInfo];

}

- (void) makeVmeBit3
{
	static templateObjs objs[] = {
		{@"ORMacModel",			60, 300,  0,-1},
		{@"ORVmeCrateModel",  170, 300, 0,-1},
		{@"ORPciBit3Model",		0, 0, 0,0},  //used for slot,obj
		{@"ORBit3Model",		0, 0, 0,1},  //used for slot,obj
		{nil,0,0,0,0} //must be last

	};
	static templateConnections connectInfo[] = {
		{0, @"OwnedConnection_0",			  1, @"Vme Crate Adapter Connector"},
		{0,nil,0,nil} //must be last

	};
	[self makeObjects:objs withConnections:connectInfo];

}

- (void) makeVmeSBC
{
	static templateObjs objs[] = {
		{@"ORVmeCrateModel",  170, 300, 0,-1},
		{@"ORVmecpuModel",	  0,     0, 0, 0},  //used for slot,obj
		{nil,0,0,0,0} //must be last

	};
	[self makeObjects:objs withConnections:nil];

}

- (void) makeCAMAC
{
	static templateObjs objs[] = {
		{@"ORMacModel",			60, 300,  0,-1},
		{@"ORCamacCrateModel",  170, 300, 0,-1},
		{@"ORPCICamacModel",	0, 0, 0,0},  //used for slot,obj
		{@"ORCC32Model",		0, 0, 23,1},  //used for slot,obj
		{nil,0,0,0,0} //must be last

	};
	static templateConnections connectInfo[] = {
		{0, @"OwnedConnection_0",			  1, @"OwnedConnection_0"},
		{0,nil,0,nil} //must be last

	};
	[self makeObjects:objs withConnections:connectInfo];

}

- (void) makecPCI
{
	static templateObjs objs[] = {
		{@"ORcPCICrateModel",	60, 300,  0,-1},
		{@"ORcPCIcpuModel"  ,    0, 0,    0,0},
		{nil,0,0,0,0} //must be last
	};
	[self makeObjects:objs withConnections:nil];

}

- (void) makeIPE
{
	static templateObjs objs[] = {
		{@"ORMacModel",			60, 300,  0,-1},
		{@"ORIpeCrateModel",   170, 300, 0,-1},
		{@"ORIpeSLTModel",		 0, 0, 0,1},  //used for slot,obj
		{nil,0,0,0,0} //must be last

	};
	static templateConnections connectInfo[] = {
		{0, @"ORMacFireWireConnection",			  1, @"ORIpeCrateFireWireIn"},
		{0,nil,0,nil} //must be last

	};
	[self makeObjects:objs withConnections:connectInfo];

}

- (void) makeIPEV4
{
	static templateObjs objs[] = {
		{@"ORIpeV4CrateModel",170, 300, 0, -1},
		{@"ORIpeV4SLTModel",	0,   0, 10, 0},  //used for slot,obj
		{nil,0,0,0,0} //must be last

	};
	[self makeObjects:objs withConnections:nil];

}

- (void) makeMCA
{
	static templateObjs objs[] = {
		{@"ORMacModel",		60, 350,  0,-1},
		{@"ORMCA927Model",  170, 350, 0,-1},
		{nil,0,0,0,0} //must be last

	};
	static templateConnections connectInfo[] = {
		{0, @"ORMacUSBConnection",	 1, @"ORMCA927USBInConnection"},
		{0,nil,0,nil} //must be last

	};
	[self makeObjects:objs withConnections:connectInfo];

}

- (void) makeObjects:(templateObjs*)objsToMake withConnections:(templateConnections*)connectionsToMake
{
	NSMutableArray* theObjects = [NSMutableArray array];
	ORGroup* theGroup = [[(ORAppDelegate*)[NSApp delegate] document]group];
	int i=0;
	while(objsToMake[i].name != nil){
		OrcaObject* obj;
		NSString* objClassName = objsToMake[i].name;
		
		if([objClassName isEqualTo:@"ORVmeCrateModel"]){
			int vme64Option = (int)[[vme64Matrix selectedCell] tag];
			if(vme64Option)objClassName = @"ORVme64CrateModel";
		}
		   
		@try{
			obj = [ObjectFactory makeObject:objClassName];
		}
		@catch(NSException* LocalException){
		}

		int containerIndex = objsToMake[i].special2;
		if(containerIndex >= 0){
			if(containerIndex<[theObjects count]){
				int slot = objsToMake[i].special1;
				id guardian = [theObjects objectAtIndex:containerIndex];
				[guardian addObject:obj];
				[guardian place:obj intoSlot:slot];
				[guardian setUpImage]; //force a redraw
			}
			else {
				NSLogColor([NSColor redColor], @"Programmer error in Template: container index too big\n");
			}
		}
		else {
			[obj moveTo:NSMakePoint(objsToMake[i].x, objsToMake[i].y)];
			[theGroup addObject:obj];
		}
		[obj setHighlighted:NO];
		[theObjects addObject:obj]; //just temp holding for connection step
		if([[obj className] isEqualToString:@"ORFanOutModel"]){
			int numOutputs = objsToMake[i].special1;
			if(numOutputs>2){
				[(ORFanOutModel*)obj adjustNumberOfOutputs:objsToMake[i].special1];
			}
		}
		i++;
	}
	if(connectionsToMake){
		i=0;
		while(connectionsToMake[i].startConnectorName != nil){			
			OrcaObject* obj1 =  [theObjects objectAtIndex:connectionsToMake[i].startObjIndex];
			OrcaObject* obj2 =  [theObjects objectAtIndex:connectionsToMake[i].endingObjIndex];
			ORConnector* c1 = [[obj1 connectors] objectForKey:connectionsToMake[i].startConnectorName];
			ORConnector* c2 = [[obj2 connectors] objectForKey:connectionsToMake[i].endConnectorName];
			[c1 connectTo:c2];
			i++;
		}
	}

}
@end

