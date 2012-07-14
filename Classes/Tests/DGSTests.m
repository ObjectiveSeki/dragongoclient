//
//  DGSTests.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/3/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import "DGSTests.h"

@implementation DGSTests

- (void)testParseQuickStatusGames {
	NSString *testData = [NSString stringWithContentsOfFile:@"TestData/status.csv" encoding:NSUTF8StringEncoding error:NULL];
	DGS *dgs = [[DGS alloc] init];
	NSArray *games = [dgs gamesFromCSV:testData];
	[dgs release];
	NSUInteger expectedCount = 2;
	STAssertEquals([games count], expectedCount, nil);
	STAssertEqualObjects([[games objectAtIndex:0] opponent], @"pledan", nil);
	STAssertEquals([[games objectAtIndex:0] gameId], 729940, nil);
    STAssertEqualObjects([[games objectAtIndex:0] time], @"F: 5d 13h (+ 1d)", nil);
}

- (void)testBoardCoords {
	DGS *dgs = [[[DGS alloc] init] autorelease];
	STAssertEqualObjects(@"ss", [dgs sgfCoordsWithRow:1 column:19 boardSize:19], nil, nil );
	STAssertEqualObjects(@"aa", [dgs sgfCoordsWithRow:19 column:1 boardSize:19], nil, nil );
	STAssertEqualObjects(@"ab", [dgs sgfCoordsWithRow:18 column:1 boardSize:19], nil, nil );
}

- (void)testParseWaitingRoom {
	NSData *testData = [NSData dataWithContentsOfFile:@"TestData/waiting.html" options:0 error:nil];

	DGS *dgs = [[DGS alloc] init];
	NSArray *games = [dgs gamesFromWaitingRoomTable:testData];
	[dgs release];
	NSUInteger expectedCount = 18;
	STAssertEquals([games count], expectedCount, nil);
	STAssertNotNil([[games objectAtIndex:0] detailUrl], nil);
	STAssertEqualObjects([[games objectAtIndex:0] opponent], @"gowc2011", nil);
	STAssertEquals([[games objectAtIndex:0] boardSize], 19, nil);
	STAssertEqualObjects([[games objectAtIndex:0] opponentRating], @"1 dan (0%)", nil);
	STAssertNil([[games objectAtIndex:17] opponentRating], nil);
	STAssertEquals([[games objectAtIndex:0] gameId], 124895, nil);
}


@end
