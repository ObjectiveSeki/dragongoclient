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
	STAssertEqualObjects([[games objectAtIndex:0] opponent], @"Tryphon Tournesol", nil);
	STAssertEquals([[games objectAtIndex:0] gameId], 571269, nil);
}

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
	NSString *testData = [NSString stringWithContentsOfFile:@"TestData/waiting.html" encoding:NSISOLatin1StringEncoding error:nil];

	DGS *dgs = [[DGS alloc] init];
	NSArray *games = [dgs gamesFromWaitingRoomTable:testData];
	[dgs release];
	NSUInteger expectedCount = 18;
	STAssertEquals([games count], expectedCount, nil);
	STAssertNotNil([[games objectAtIndex:0] detailUrl], nil);
	STAssertEqualObjects([[games objectAtIndex:0] opponent], @"gowc2011", nil);
	STAssertEquals([[games objectAtIndex:0] boardSize], 19, nil);
	STAssertEqualObjects([[games objectAtIndex:0] opponentRating], @"1 dan (0%)", nil);
	STAssertNil([[games objectAtIndex:17] opponentRating], nil);
	STAssertEquals([[games objectAtIndex:0] gameId], 124895, nil);
}

- (void)testParseWaitingRoomDetail {
	NSString *testData = [NSString stringWithContentsOfFile:@"TestData/waiting-detail.html" encoding:NSISOLatin1StringEncoding error:nil];
	
	DGS *dgs = [[DGS alloc] init];
	NewGame *game = [dgs gameFromWaitingRoomDetailTable:testData game:[[[NewGame alloc] init] autorelease]];
	[dgs release];
	STAssertEqualObjects(game.opponent, @"lesenv (lesenv)", nil);
	STAssertEquals(game.boardSize, 13, nil);
	STAssertEqualObjects(game.opponentRating, @"17 kyu (-22%)", nil);
	STAssertEqualObjects(game.comment, @"At least one diagonal fuseki please!", nil);
	STAssertEqualObjects(game.ratedString, @"Yes", nil);
	STAssertEqualObjects(game.weekendClockString, @"Yes", nil);
	STAssertEqualObjects(game.komiTypeName, @"Proper handicap", nil);
	STAssertEqualsWithAccuracy(game.komi, (CGFloat)6.0, (CGFloat)0.25, nil);
	STAssertFalse(game.myGame, nil);
	
	testData = [NSString stringWithContentsOfFile:@"TestData/waiting-detail-cn.html" encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingEUC_CN) error:nil];
	
	dgs = [[DGS alloc] init];
	game = [dgs gameFromWaitingRoomDetailTable:testData game:[[[NewGame alloc] init] autorelease]];
	[dgs release];
	STAssertEqualObjects(game.opponent, @"Loaden (Loaden)", nil);
	STAssertEquals(game.boardSize, 19, nil);
	STAssertEqualObjects(game.opponentRating, @"16 级 (-49%)", nil);
	STAssertEqualObjects(game.comment, @"Let's happy go!", nil);
	STAssertEqualObjects(game.ratedString, @"是", nil);
	STAssertEqualObjects(game.weekendClockString, @"是", nil);
	STAssertEqualObjects(game.komiTypeName, @"猜子分先", nil);
	STAssertEqualsWithAccuracy(game.komi, (CGFloat)6.5, (CGFloat)0.25, nil);
	STAssertFalse(game.myGame, nil);
	
	testData = [NSString stringWithContentsOfFile:@"TestData/owned_game.html" encoding:NSUTF8StringEncoding error:nil];
	
	dgs = [[DGS alloc] init];
	game = [dgs gameFromWaitingRoomDetailTable:testData game:[[[NewGame alloc] init] autorelease]];
	[dgs release];
	STAssertEqualObjects(game.opponent, @"test (test1)", nil);
	STAssertEquals(game.boardSize, 19, nil);
	STAssertEqualObjects(game.opponentRating, @"18 kyu (0%)", nil);
	STAssertEqualObjects(game.comment, @"This is my comment", nil);
	STAssertEqualObjects(game.ratedString, @"No", nil);
	STAssertEqualObjects(game.weekendClockString, @"Yes", nil);
	STAssertEqualObjects(game.komiTypeName, @"Even game with nigiri (Manual setting)", nil);
	STAssertEqualsWithAccuracy(game.komi, (CGFloat)6.5, (CGFloat)0.25, nil);
	STAssertTrue(game.myGame, nil);
}

@end
