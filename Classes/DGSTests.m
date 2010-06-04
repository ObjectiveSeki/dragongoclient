//
//  DGSTests.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/3/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import "DGSTests.h"

@implementation DGSTests

- (void)testParseGames {
	NSString *testData = [NSString stringWithContentsOfFile:@"TestData/status.html"];
	NSArray *games = [DGS gamesFromTable:testData];
	NSUInteger expectedCount = 3;
	STAssertEquals([games count], expectedCount, nil);
}

@end
