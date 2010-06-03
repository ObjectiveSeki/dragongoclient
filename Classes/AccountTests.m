//
//  AccountTests.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/1/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import "AccountTests.h"
#import "Account.h"


@implementation AccountTests

// all code under test must be linked into the Unit Test bundle

- (void) testInit {
	Account *account = [[Account alloc] init];
	
	[account release];

}


@end
