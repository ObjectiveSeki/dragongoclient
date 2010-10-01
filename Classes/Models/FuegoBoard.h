//
//  FuegoBoard.h
// 
//  An Objective-C wrapper around the logic in libfuego.
//
//  Created by Justin Weiss on 6/4/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SgSystem.h"
#import "SgNode.h"
#import "GoGame.h"
#import "Move.h"

@interface FuegoBoard : NSObject {
	GoGameRecord *goGame;
	GoBoard *goBoard;
	SgNode *startNode;
	Move *resignMove;
	NSArray *markedGroups;
	NSArray *changedGroups;
	bool _gameEnded;
	int scoringMoves;
}

@property(nonatomic, retain) Move *resignMove;
@property(nonatomic, retain) NSArray *markedGroups;
@property(nonatomic, retain) NSArray *changedGroups;

// Must be called after loading but before using this class
+ (void)initFuego;

// Must be called when you're done using this class
+ (void)finishFuego;

- initWithSGFString:(NSString *)sgfString;

// Properties
- (NSString *)comment;
- (bool)gameEnded;
- (int)size;
- (NSArray *)moves;
- (int)moveNumber;

// The most recently played move
- (Move *)currentMove;

// The second-to-most recently played move
- (Move *)lastMove;

// Stones that were marked on the last turn. We need to keep
// track of this group so that we can allow the player to
// unmark stones
- (NSArray *)markedStones;

// Stones whose status has changed (marked vs unmarked)
// since the last turn
- (NSArray *)changedStones;

// Marked stones whose status has not changed, and unmarked 
// stones whose status has changed
- (NSArray *)deadStones;
- (int)handicap;

// Commands
- (void)undoLastMove;
- (bool)playStoneAtRow:(int)row column:(int)col;
- (bool)markDeadStonesAtRow:(int)row column:(int)col;
- (void)pass;
- (void)resign;

// NO if the game has a handicap and the handicap stones have just been placed
- (bool)beginningOfHandicapGame;

// YES if the game has a hadicap and handicap stones still need to be placed
- (bool)needsHandicapStones;

// If handicap stones have just been placed, return the handicap stones. Otherwise, return nil.
- (NSArray *)handicapStones;

// Captured endgame territory, in an array of moves
- (NSArray *)territory;

- (bool)gameEnded;

- (bool)canUndo;
- (bool)canPlayMove;
- (bool)canPassOrResign;
- (bool)canSubmit;

- (NSString *)name:(MovePlayer)movePlayer;
- (int)captures:(MovePlayer)movePlayer;
- (float)score;

@end
