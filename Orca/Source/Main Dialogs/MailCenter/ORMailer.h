//----------------------------------------------------------
//  ORMailer.h
//
//  Created by Mark Howe on Wed Apr 9, 2008.
//  ReWorked to use the Scripting Bridge and a NSOperation Queue Wed Aug 15, 2012
//  Copyright  © 2012 CENPA. All rights reserved.
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

@interface ORMailer : NSOperation {
	id delegate;
	NSString* to;
	NSString* cc;
	NSString *subject;
	NSAttributedString* body;
	NSString* from;
}
+ (ORMailer *)mailer;
- (void) send:(id)aDelegate;
- (void) main;

@property (nonatomic,assign)	id	delegate;
@property (nonatomic,copy)		NSString*	to;
@property (nonatomic,copy)		NSString*	cc;
@property (nonatomic,copy)		NSString*	from;
@property (nonatomic,copy)		NSString*	subject;
@property (nonatomic,copy)		NSAttributedString*	body;

@end

@interface NSObject (ORMailer)
- (void) mailSent:(NSString*)to;
@end

//a thin wrapper around NSOperationQueue to make a shared queue for mail
@interface ORMailQueue : NSObject {
    NSOperationQueue* queue;
}
+ (ORMailQueue*) sharedMailQueue;
+ (void) addOperation:(NSOperation*)anOp;
+ (NSOperationQueue*) queue;
+ (NSUInteger) operationCount;
- (void) addOperation:(NSOperation*)anOp;
- (NSOperationQueue*) queue;
- (NSInteger) operationCount;
@end

@interface ORMailerDelay : NSOperation {
}
@end
