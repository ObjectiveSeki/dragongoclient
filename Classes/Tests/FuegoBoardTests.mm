//
//  FuegoBoardTests.m
//  DGSPhone
//
//  Created by Justin Weiss on 10/4/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import "FuegoBoardTests.h"
#import "FuegoBoard.h"

@implementation FuegoBoardTests

- (void)setUp {
	
	// Set up fuego. There doesn't seem to be any place to globally initialize SenTest,
	// so we have to setup fuego here, and assume that it'll automatically get
	// cleaned up when the tests are finished.
	[FuegoBoard initFuego];
	
}

- (NSString *)stringForSgfFile:(NSString *)sgfFilename {
	NSString * sgfFile = [NSString stringWithContentsOfFile:[[NSBundle bundleForClass:[self class] ] pathForResource:sgfFilename ofType:@"sgf"] encoding:NSUTF8StringEncoding error:NULL];
	return sgfFile;
}

- (void)testGameStateAfterPasses {
	NSString *sgfString = [self stringForSgfFile:@"Pass Should Be Move 200"];
	FuegoBoard *board = [[FuegoBoard alloc] initWithSGFString:sgfString];

	STAssertFalse([board canUndo], nil);
	STAssertFalse([board canSubmit], nil);
	
	[board pass];
	
	STAssertTrue([board canSubmit], nil);
	STAssertEquals([board moveNumber], 201, nil);
	STAssertFalse([board gameEnded], nil);
	
	[board release];
}

- (void)testMoveNumberFixForScores {
	NSString *sgfString = [self stringForSgfFile:@"Scoring Should Be Move 202"];
	FuegoBoard *board = [[FuegoBoard alloc] initWithSGFString:sgfString];
	
	STAssertEquals([board moveNumber], 202, nil);
	STAssertTrue([board gameEnded], nil);
	
	[board release];
	
	NSString *otherSgfString = [self stringForSgfFile:@"Multiple Scoring Passes"];
	FuegoBoard *otherBoard = [[FuegoBoard alloc] initWithSGFString:otherSgfString];
	
	STAssertEquals([otherBoard moveNumber], 15, nil);
	
	[otherBoard release];
}

- (void)testPlayMoveAfterScoring {
	NSString *sgfString = [self stringForSgfFile:@"Scoring Should Be Move 202"];
	FuegoBoard *board = [[FuegoBoard alloc] initWithSGFString:sgfString];
	
	STAssertTrue([board gameEnded], nil);
	
	[board playStoneAtRow:1 column:1];
	
	STAssertFalse([board gameEnded], nil);
	STAssertEquals([board moveNumber], 203, nil);
	
	[board undoLastMove];
	STAssertTrue([board gameEnded], nil);
	
	[board release];
}

@end
