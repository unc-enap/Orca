
//
//  Node.h
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

#import "setjmp.h"

@interface Node : NSObject
{
	int			type;
	id			nodeData;
	int			line;
}
- (int)	line;
- (void) setLine:(int)aLine;
- (int)		type;
- (void)	setType:(int)aType;
- (id)		nodeData;
- (void)	setNodeData:(id)someData;
@end

@interface OprNode : NSObject
{
    int				operatorTag;                   /* operator */
	NSMutableArray* operands;
	int			line;
}

- (int)	line;
- (void) setLine:(int)aLine;
- (int)				operatorTag;
- (void)			setOperatorTag:(int)anOperator;
- (NSMutableArray*) operands;
- (NSUInteger)		count;
- (id)				objectAtIndex:(NSUInteger)index;
- (void)			setOperands:(NSMutableArray*)anArray;
- (void)			addOperand:(id)anOperand;
@end
