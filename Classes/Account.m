//
//  Account.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/1/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import "Account.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"

@implementation Account

- (id)init
{
    if ([super init]) {

    }
    
    return self;
}

- (void)logout {
	NSURL *url = [NSURL URLWithString:@"http://www.dragongoserver.net/index.php?logout=t"];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request startSynchronous];
}

- (BOOL)login {
	NSURL *url = [NSURL URLWithString:@"http://www.dragongoserver.net/status.php"];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request startSynchronous];
	
	NSError *error = [request error];
	if (!error) {
		if (NSNotFound == [[request responseString] rangeOfString:@"you have to be logged in"].location) {
			NSLog(@"%@", [request responseString]);
			return YES;
		} else {
			NSLog(@"Unauthorized");
		}
	}
	return NO;
}

- (void)loginWithUsername:(NSString *)username password:(NSString *)password 
{

	NSURL *url = [NSURL URLWithString:@"http://www.dragongoserver.net/login.php"];
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setPostValue:username forKey:@"userid"];
	[request setPostValue:password forKey:@"passwd"];
	[request startSynchronous];
	NSError *error = [request error];
	if (!error) {
		NSLog(@"%@", [request responseString]);
	}
}

- (void)dealloc {
	[super dealloc];
}

@end
