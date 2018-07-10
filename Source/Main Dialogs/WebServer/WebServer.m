//
//  WebServer.m
//  Orca
//
//  Created by Mark Howe on Tuesday, June 23,2009.
//  Copyright (c) 2009 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics  sponsored 
//in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "WebServer.h"
#import "SimpleHTTPConnection.h"
#import "SimpleHTTPServer.h"
#import "SynthesizeSingleton.h"
#import "NSString+Extensions.h"

@implementation WebServer
SYNTHESIZE_SINGLETON_FOR_CLASS(WebServer);

- (id)init
{
    self = [super initWithWindowNibName:@"WebServer"];
	NSArray* names =  [[NSHost currentHost] addresses];
	id aName;
	int i;
	for(i=0;i<[names count];i++){
		aName = [names objectAtIndex:i];
		if([aName rangeOfString:@"::"].location == NSNotFound){
			if([aName rangeOfString:@".0.0."].location == NSNotFound){
				hostAddress = [aName copy];
				break;
			}
		}
	}
    [self setServer:[[[SimpleHTTPServer alloc] initWithTCPPort:50000 delegate:self] autorelease]];
    return self;
}

- (void)awakeFromNib
{
}

- (void)dealloc
{
	[validCommands release];
	[hostAddress release];
    [server release];
    [super dealloc];
}

- (IBAction) showWebServer:(id)sender
{
    [[self window] makeKeyAndOrderFront:nil];
}


- (void)setServer:(SimpleHTTPServer *)sv
{
    [server autorelease];
    server = [sv retain];
}

- (SimpleHTTPServer*) server { return server; }

- (void) processURL:(NSURL *)path connection:(SimpleHTTPConnection *)connection
{
	NSString* command = [[path absoluteString] lastPathComponent];
	NSMutableString* pageTemplate = nil;
	if([command isEqualToString:@"favicon.ico"]){
		[server replyWithData:nil  MIMEType:@"text/html"];	
	}
	else if([command isEqualToString:@"ORCA"]) {	
		[validCommands release];
		validCommands = nil;
		validCommands = [[NSMutableArray array] retain];
		NSArray* objects = [[[NSApp delegate] document] collectObjectsOfClass:[OrcaObject class]];
		NSString* bp = [[NSBundle mainBundle ]resourcePath];
		pageTemplate = [NSMutableString stringWithContentsOfFile:[bp stringByAppendingPathComponent:@"home.html"]];
		NSString* link = [NSString stringWithFormat:@"<a href=\"http://%@:%d/ORCA\"> Home</a><br/>\r",hostAddress ,[server port]];
		NSEnumerator* e = [objects objectEnumerator];
		id obj;
		while(obj = [e nextObject]){
			NSString* objLine = nil;
			NSString* objName = nil;
			
			if([obj respondsToSelector:@selector(fullName)])objName = [obj fullName];
			else objName= [obj fullID];
			
			if([objName length] && ![objName hasPrefix:@"ORGroup"]){
				[validCommands addObject:objName];
				objLine = [NSString stringWithFormat:@"<a href=\"http://%@:%d/%@\"> %@</a><br/>\r",hostAddress ,[server port],objName,objName];

				if(objLine)link = [link stringByAppendingString:objLine];
			}
		}
		[pageTemplate replace:@"<Content>" with:link];
	}
	else {
		NSMutableString* c = [NSMutableString stringWithString:command];
		[c replace:@"%20" with:@" "];
		if([validCommands containsObject:c]) {
			NSString* bp = [[NSBundle mainBundle ]resourcePath];
			pageTemplate = [NSMutableString stringWithContentsOfFile:[bp stringByAppendingPathComponent:@"home.html"]];
			NSString* link = [NSString stringWithFormat:@"<a href=\"http://%@:%d/ORCA\"> Home</a><br/>\r",hostAddress ,[server port]];
			NSString* s = [self process:c];
			if([s length]) link = [link stringByAppendingString:s];
			[pageTemplate replace:@"<Content>" with:link];
		}
	}

	if(pageTemplate)[server replyWithData:[pageTemplate dataUsingEncoding:NSASCIIStringEncoding]  MIMEType:@"text/html"];
}

- (NSString*) process: (NSMutableString*) objName
{
	id theObj = [[[NSApp delegate] document] findObjectWithFullID:objName];
	NSString* s = @"";
	NSString* status = @"";
	NSString* params = @"";
	if(theObj && [theObj respondsToSelector:@selector(addStatusToDictionary:)]){
		NSMutableDictionary* aDict = [NSMutableDictionary dictionary];
		status = [[theObj addStatusToDictionary:aDict] htmlFormatAppendingToString:s];
	}
	if(theObj && [theObj respondsToSelector:@selector(addParametersToDictionary:)]){
		NSMutableDictionary* aDict = [NSMutableDictionary dictionary];
		params = [[theObj addParametersToDictionary:aDict] htmlFormatAppendingToString:s];
	}

	return [s stringByAppendingFormat:@"%@<br/>%@\r",status,params];
}

@end
