//
//  NSLogTest.m
//  Orca
//
//  Created by Eric Marzec (marzece@gmail.com) on 2/22/16.
//
//  N.B wRML means with Run Main Loop.
//  I use it in test names to indicate that the main loop
//  is allowed to run and do as it pleases at some point in
//  the execution of the test.
//  This allows for things like GUI updating to occur.
#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "ORStatusController.h"
@interface NSLogTest : XCTestCase {
    ORStatusController *statusCont; //The status controller that is being tested.
    BOOL sharedVar; //Used to represent a variable different threads share
    int TimeOut; //How long to wait for things to get printed to the screen
    uint nPrints; //For functions that print many times (e.g. printSequentially), this specifies exactly how many
    NSString* printSingleLineTestString; //Test string that is used in printSingleLine()
    NSString* printSeqTestString; //(unformatted) Test string that is used in printSequentially()
    
}
- (void)printSingleLine;
- (void)printSequentially;
- (void)printStringToStatusController:(NSString*)str;
- (void)RunMainLoop;
- (void)CheckSequentialPrints;
@end

@implementation NSLogTest

- (void)setUp {
    [super setUp];
    statusCont = [ORStatusController sharedStatusController];
    [statusCont retain];
    TimeOut = 3;
    nPrints = 100;
    printSingleLineTestString = @"Single Line Test string\n";
    printSeqTestString = @"PrintSeq%d\n";
}

- (void)tearDown {
    [statusCont release];
    [super tearDown];
}
//Simply checks to see that the status controller was retrieved
- (void)testRetrieveStatusController {
    XCTAssertNotNil(statusCont,@"Could not get status controller");
}
//Prints a string using the status controller then immediatly
//checks to see if it shows up
//The main thread stays in the function the entire time
- (void)testBasicPrinting {
    NSString *testString = @"TEST STRING\n";
    [self printStringToStatusController:testString];
    
    NSString* txt =[statusCont contents];
    NSRange range = [txt rangeOfString:testString];
    
    XCTAssert(range.length>0,@"Test string was not printed");
}
//Prints a string to the status controller then lets the main
//loop run for a while, then checks if the string is there
- (void)testBasicPrint_wRML{
    NSString *testString = @"TEST STRING with RML\n";
    [self printStringToStatusController:testString];
    
    [self RunMainLoop];
    
    NSString* txt =[statusCont contents];
    NSRange range = [txt rangeOfString:testString];
    XCTAssert(range.length>0,@"Test string was not printed");
}
//Prints to in a (non-main) thread then checks if the output
//shows up.
//A pause is taken to let the main loop run before any checking is done.
- (void)testSecondaryThreadPrint_wRML {
    if (![NSThread isMainThread]) {
        XCTFail(@"Test was not performed on main thread");
        return;
    }
    UInt StartingLength = [[statusCont contents] length];
    sharedVar = YES;
    [NSThread detachNewThreadSelector:@selector(printSingleLine) toTarget:self withObject:nil];
    [self RunMainLoop];
    NSString *txt = [statusCont contents];
    if([txt length] <= StartingLength) {
        XCTFail(@"Secondary Thread failed to print");
        return;
    }
    NSRange range = [txt rangeOfString:printSingleLineTestString];
    XCTAssert(range.length >0,@"Secondary thread failed to print correctly");
}
//This test will print many statements to the status controller and check
//to make sure they all get logged properly, in the correct order.
//All this is done within the main thread
//and the main thread never leaves this function
- (void)testLotsOfPrinting_MainThread {
    if(![NSThread isMainThread]) {
        XCTFail(@"Main thread test not launched on main thread");
    }
    UInt StartingLength = [[statusCont contents] length];
    [self printSequentially];
    NSString *txt = [statusCont contents];
    if ([txt length] <= StartingLength)
    {
        XCTFail(@"Secondary Thread failed to print");
        return;
    }
    [self CheckSequentialPrints];
}
//Same as testLotsOfPrinting_MainThread except a pause is taken to let the
//main loop run before any checking is done.
- (void)testLotsOfPrinting_MainThread_wRML {
    if(![NSThread isMainThread]) {
        XCTFail(@"Main thread test not launched on main thread");
    }
    UInt StartingLength = [[statusCont contents] length];
    [self printSequentially];
    
    [self RunMainLoop];
    
    NSString *txt = [statusCont contents];
    if ([txt length] <= StartingLength)
    {
        XCTFail(@"Secondary Thread failed to print");
        return;
    }
    [self CheckSequentialPrints];
}
//Runs a separate thread that outputs lots of times then
//checks after a reasonable time if that output is show.
//Lets the main loop do it's thing for a reasonable amount of time
//before checking the output.
- (void)testLotsOfPrinting_SecondaryThread_wRML {
    UInt StartingLength = [[statusCont contents] length];

    [NSThread detachNewThreadSelector:@selector(printSequentially) toTarget:self withObject:nil];
    
    [self RunMainLoop];    //Wait a reasonable amount of time
    
    NSString *txt = [statusCont contents];
    if([txt length] <= StartingLength) {
        XCTFail(@"Secondary thread failed to print");
        return;
    }
    [self CheckSequentialPrints];
}
//This test just detects if a deadlock can occur when launching a secondary thread.
//It doesn't not bother checking if things actually get outputted correctly.
//So the actual logging could totally fail and this test would still pass
//so long as it fails without locking up
- (void)testDeadlock {
    time_t TimeOutTimer = time(0);
    if (![NSThread isMainThread]) {
        XCTFail(@"Test was not performed on main thread");
        return;
    }
    [NSThread detachNewThreadSelector:@selector(printSingleLine) toTarget:self withObject:nil];
    sharedVar = YES;
    while(sharedVar) {
        if(time(0) - TimeOutTimer > TimeOut)
        {
            break;
        }
        else
        {
            usleep(10000); //Sleep for 0.1 seconds
        }
    }
    XCTAssert(!sharedVar,"Deadlock occurred"); //If sharedVar is not false it's b/c a timeout/deadlock occurred
}

//Helper Functions

//This function is meant to be run on a secondary (non-main) thread.
//It is supposed to print a test string to the status controller, and then it should return.
//If printing to the status controller blocks this function will not return until that block is resolved.
- (void)printSingleLine {
    [self printStringToStatusController:printSingleLineTestString];
    sharedVar = NO; //Change this so other threads know this function is done
}
//Prints many line of text which can be checked to make sure they show up in the correct order.
- (void)printSequentially {
    for (uint i=0; i < nPrints; i++) {
        NSString* testString = [NSString stringWithFormat:printSeqTestString,i];
        [self printStringToStatusController:testString];
        usleep(10000);
        sharedVar = NO; //Change this so other threads know this function is done
    }
}

- (void)printStringToStatusController:(NSString*)str {
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:str];
    [statusCont printAttributedString:attrString];
    [attrString release];
}
//This function just lets the main loop run for a few seconds (or whatever TimeOut is set to)
- (void)RunMainLoop {
    NSDate *date = [[NSDate alloc]initWithTimeIntervalSinceNow:TimeOut];
    [[NSRunLoop mainRunLoop] runUntilDate:date];
    [date release];
}
//This function is used to check that the output for printSequentially actually showed up.
- (void) CheckSequentialPrints {
    NSString* txt = [statusCont contents];
    for(uint i=0;i< nPrints-1;i++)
    {
        NSRange range1 = [txt rangeOfString:[NSString stringWithFormat:printSeqTestString,i]];
        NSRange range2 = [txt rangeOfString:[NSString stringWithFormat:printSeqTestString,i+1]];
        XCTAssert(range1.location < range2.location,@"%d showed up before %d\n",i+1,i);
        XCTAssertNotEqual(range1.length,(UInt)0,@"%d not found\n",i);
        XCTAssertNotEqual(range2.length,(UInt)0,@"%d not found\n",i+1);
    }
}

@end
