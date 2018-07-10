//
//  ORFilterPluginBaseClass.m
//  Orca
//
//  Created by Mark Howe on 3/27/08.
//  Copyright 2008 University of North Carolina. All rights reserved.
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

#import "ORFilterPluginBaseClass.h"

@implementation ORFilterPluginBaseClass

- (id) initWithDelegate:(id)aDelegate
{
	self = [super init];
	delegate = aDelegate;	//never retain a delegate
	return self;
}

- (void) dealloc
{
	[symTable release];
	[super dealloc];
}

- (unsigned long*) ptr:(const char*)aKey
{
	filterData data;
	[symTable getData:&data forKey:aKey];
	return data.val.pValue;
}



- (unsigned long) value:(const char*)aKey
{
	filterData data;
	[symTable getData:&data forKey:aKey];
	return data.val.lValue;
}

- (void) setSymbolTable:(ORFilterSymbolTable*)aTable
{
	[aTable retain];
	[symTable release];
	symTable = aTable;
}

- (void) start
{
	//subclass will need to override
}
- (void) filter:(unsigned long*) currentRecordPtr length:(unsigned long)aLen
{
	//subclass will need to override
}

- (void) finish
{
	//subclass will need to override
}

@end
