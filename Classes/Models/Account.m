//
//  Account.m
//  DGSPhone
//
//  Created by Justin Weiss on 7/22/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import "Account.h"


@implementation Account

@synthesize username;
@synthesize password;
@synthesize passwordConfirm;
@synthesize name;
@synthesize acceptTerms;

- (void)dealloc {
	self.username = nil;
	self.password = nil;
	self.passwordConfirm = nil;
	self.name = nil;
	[super dealloc];
}

@end
