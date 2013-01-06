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
    NSString *testData = [NSString stringWithContentsOfFile:TestFile(@"status", @"csv") encoding:NSUTF8StringEncoding error:NULL];
	DGS *dgs = [[DGS alloc] init];
	NSArray *games = [dgs gamesFromCSV:testData];
	NSUInteger expectedCount = 2;
	STAssertEquals([games count], expectedCount, nil);
	STAssertEqualObjects([games[0] opponent], @"pledan", nil);
	STAssertEquals([games[0] gameId], 729940, nil);
    STAssertEqualObjects([games[0] time], @"F: 5d 13h (+ 1d)", nil);
}

- (void)testBoardCoords {
	DGS *dgs = [[DGS alloc] init];
	STAssertEqualObjects(@"ss", [dgs sgfCoordsWithRow:1 column:19 boardSize:19], nil, nil );
	STAssertEqualObjects(@"aa", [dgs sgfCoordsWithRow:19 column:1 boardSize:19], nil, nil );
	STAssertEqualObjects(@"ab", [dgs sgfCoordsWithRow:18 column:1 boardSize:19], nil, nil );
}

- (void)testParseWaitingRoom {
	NSData *testData = [NSData dataWithContentsOfFile:TestFile(@"waiting", @"html") options:0 error:nil];

	DGS *dgs = [[DGS alloc] init];
	NSArray *games = [dgs gamesFromWaitingRoomTable:testData];
	NSUInteger expectedCount = 18;
	STAssertEquals([games count], expectedCount, nil);
	STAssertNotNil([games[0] detailUrl], nil);
	STAssertEqualObjects([games[0] opponent], @"gowc2011", nil);
	STAssertEquals([games[0] boardSize], 19, nil);
	STAssertEqualObjects([games[0] opponentRating], @"1 dan (0%)", nil);
	STAssertNil([games[17] opponentRating], nil);
	STAssertEquals([games[0] gameId], 124895, nil);
}


@end
