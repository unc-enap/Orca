//
//  Node.m
//  Orca
//
//  Created by Mark Howe  Dec 2006.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#import "NodeTree.h"
#import "setjmp.h"
#import "OrcaScript.h"

@implementation Node 

- (void) dealloc 
{
	[nodeData release];
	[super dealloc];
}
- (uint32_t)	line
{
	return line;
}

- (void) setLine:(uint32_t)aLine
{
	line = aLine;
}
- (int) type 
{
	return type;
}

- (void) setType:(int)aType 
{
	type = aType;
}

- (id) nodeData 
{
	return nodeData;
}

- (void) setNodeData:(id)someData
{
	[someData retain];
	[nodeData release];
	nodeData = someData;
}

- (id) description
{
	return [NSString stringWithFormat:@"line-type-data-retainCount: %d-%d-%@-%d\n",line,type,nodeData,(int)[nodeData retainCount]];
}

@end

@implementation OprNode
- (void) dealloc 
{
	[operands release];
	[super dealloc];
}
- (int32_t)	line
{
	return line;
}

- (void) setLine:(int32_t)aLine
{
	line = aLine;
}

- (int) operatorTag
{
	return operatorTag;
}

- (void) setOperatorTag:(int)anOperator
{
	operatorTag = anOperator;
}

- (NSMutableArray*) operands
{
	return operands;
}

- (NSUInteger) count
{
	return [operands count];
}

- (id) objectAtIndex:(NSUInteger)index
{
	if(index<[operands count]) return [operands objectAtIndex:index];
	else return nil;
}

- (void) setOperands:(NSMutableArray*)anArray
{
	[anArray retain];
	[operands release];
	operands = anArray;
}
- (NSString*) description
{
	return [NSString stringWithFormat:@"%@\n%@\n",[self className],operands];
}

- (void) addOperand:(id)anOperand
{
	if(!operands)[self setOperands:[NSMutableArray array]];
	[operands addObject: anOperand];
}



@end


