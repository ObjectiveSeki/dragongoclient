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

- (void)testBoardCoords {
	STAssertEqualObjects(@"ss", [DGS sgfCoordsWithRow:1 column:19 boardSize:19], nil, nil );
	STAssertEqualObjects(@"aa", [DGS sgfCoordsWithRow:19 column:1 boardSize:19], nil, nil );
	STAssertEqualObjects(@"ab", [DGS sgfCoordsWithRow:18 column:1 boardSize:19], nil, nil );
}

@end
