
//  ORCommandClient.m
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

#import "ORCommandClient.h"
#import "NetSocket.h"

#import "ORCommandCenter.h"


@implementation ORCommandClient

- (void)netsocket:(NetSocket*)insocket dataAvailable:(NSUInteger)inAmount
{
    if(insocket == socket){
        [delegate handleCommand:[socket readString:NSASCIIStringEncoding amount:inAmount] fromClient:self];
    }
}

- (void) sendCmd:(NSString*)aCmd withString:(NSString*)aString
{
    if([self amountInBuffer]<10*1024){
        NSString* theCmd;
        if(aString)theCmd = [NSString stringWithFormat:@"%@:%@\n",aCmd,aString]; 
        else       theCmd = [NSString stringWithFormat:@"%@\n",aCmd]; 

        [socket writeString:theCmd encoding:NSASCIIStringEncoding];
    }
}

@end
