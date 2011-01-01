//
//  DGSTests.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/3/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import "DGSTests.h"

@implementation DGSTests

- (void)testParseGames {
	NSString *testData = [NSString stringWithContentsOfFile:@"TestData/status.html" encoding:NSUTF8StringEncoding error:NULL];
	DGS *dgs = [[DGS alloc] init];
	NSArray *games = [dgs gamesFromTable:testData];
	[dgs release];
	NSUInteger expectedCount = 3;
	STAssertEquals([games count], expectedCount, nil);
}

- (void)testBoardCoords {
	DGS *dgs = [[[DGS alloc] init] autorelease];
	STAssertEqualObjects(@"ss", [dgs sgfCoordsWithRow:1 column:19 boardSize:19], nil, nil );
	STAssertEqualObjects(@"aa", [dgs sgfCoordsWithRow:19 column:1 boardSize:19], nil, nil );
	STAssertEqualObjects(@"ab", [dgs sgfCoordsWithRow:18 column:1 boardSize:19], nil, nil );
}

//- (void)testParseWaitingRoom {
//	NSString *testData = [NSString stringWithContentsOfFile:@"TestData/waiting.html" encoding:NSUTF8StringEncoding error:NULL];
//	DGS *dgs = [[DGS alloc] init];
//	NSArray *games = [dgs gamesFromTable:testData];
//	[dgs release];
//	NSUInteger expectedCount = 3;
//	STAssertEquals([games count], expectedCount, nil);
//}

@end
