//
//  DGSTests.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/3/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import "DGSTests.h"

@interface DGS ()
// Re-declare some DGS private methods
- (NSOrderedSet *)gamesFromCSV:(NSString *)csvData;
- (NSString *)sgfCoordsWithRow:(int)row column:(int)col boardSize:(int)boardSize;
@end


@implementation DGSTests

- (void)testParseQuickStatusGames {
    NSString *testData = [NSString stringWithContentsOfFile:TestFile(@"status", @"csv") encoding:NSUTF8StringEncoding error:NULL];
	DGS *dgs = [[DGS alloc] init];
	NSOrderedSet *games = [dgs gamesFromCSV:testData];
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


@end
