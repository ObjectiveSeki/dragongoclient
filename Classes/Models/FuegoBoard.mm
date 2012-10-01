//
//  FuegoBoard.mm
//
//  An Objective-C wrapper around libfuego.
//
//  Created by Justin Weiss on 6/4/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import "FuegoBoard.h"
#import "SgInit.h"
#import "GoInit.h"
#import "SgGameReader.h"
#import "GoModBoard.h"
#import "GoRegionBoard.h"
#import "GoBlock.h"
#import "Move.h"
#import "DGS.h"
#include <sstream>

static bool fuegoInitialized = NO;

@implementation FuegoBoard

@synthesize resignMove;
@synthesize markedGroups;
@synthesize changedGroups;

+ (void)initFuego {
	if (!fuegoInitialized) {
		SgInit();
		GoInit();
		fuegoInitialized = YES;
	}
}

+ (void)finishFuego {
	GoFini();
	SgFini();
}

- (MovePlayer)playerForSgPlayer:(SgBlackWhite)player {
	MovePlayer movePlayer;
	
	if (SG_BLACK == player) {
		movePlayer = kMovePlayerBlack;
	} else if (SG_WHITE == player) {
		movePlayer = kMovePlayerWhite;
	} else {
		movePlayer = kMovePlayerNone;
	}
	return movePlayer;
}

- (id)initWithSGFString:(NSString *)sgfString {
	if ([super init]) {
		_gameEnded = NO;
		scoringMoves = 0;
		std::string sgfStr([sgfString UTF8String]);
		std::istringstream input(sgfStr);
		SgGameReader gameReader(input, 19);
		SgNode *rootNode = gameReader.ReadGame();
        int handicap = rootNode->GetIntProp(SG_PROP_HANDICAP);
		double komi = rootNode->GetRealProp(SG_PROP_KOMI);
		int size = rootNode->GetIntProp(SG_PROP_SIZE);
        
		goGame = new GoGame(size);
        goGame->Init(size, GoRules(handicap, GoKomi(komi)));
		goGame->Init(rootNode);
		
		// Marked is an array of arrays, so we can undo marks correctly
		NSMutableArray *marked = [[NSMutableArray alloc] init];
		
		// Fast-forward to the end of the game
        const SgNode* n = goGame->CurrentNode();
        while (true) {
            SgNode* node = n->NodeInDirection(SgNode::NEXT);
            if (node) {
                n = node;
            } else {
                break;
            }
        }
        goGame->GoToNode(n);

        // We have to add extra move counts for scoring steps
        if (goGame->CurrentNode()->HasProp(SG_PROP_NAME) && !goGame->CurrentNode()->HasProp(SG_PROP_MOVE)) {
            std::string propName;
            goGame->CurrentNode()->GetStringProp(SG_PROP_NAME, &propName);
            
            if (propName == "B SCORE" || propName == "W SCORE") {
                scoringMoves++;
            }
        }
        
		// used to track changes for undo
		startNode = goGame->CurrentNode();
		
		if (goGame->CurrentNode()->HasProp(SG_PROP_MARKED)) {
			
			NSMutableArray *markedByDGS = [[NSMutableArray alloc] init];
			SgVector<SgPoint> points(((SgPropPointList *)goGame->CurrentNode()->Get(SG_PROP_MARKED))->Value());
			for(int i = 0; i < points.Length(); ++i) {
				Move *move = [[Move alloc] init];
				SgPoint point = points[i];
				
				move.row = SgPointUtil::Row(point);
				move.col = SgPointUtil::Col(point);
				move.boardSize = [self size];
				move.player = [self playerForSgPlayer:goGame->Board().GetStone(point)];
				
				[markedByDGS addObject:move];
			}
			[marked addObject:markedByDGS];
		}
		
		self.markedGroups = marked;
		
		self.changedGroups = @[];
		
		// We have to set game ended here. We have special logic
		// that goes around this state that we only want to execute
		// if the game is over at the time we download the sgf from DGS,
		// not if the player him/herself makes the 2nd pass.
		if (goGame->EndOfGame()) {
			_gameEnded = YES;
		}
		
		// If we just placed handicap stones, it should be W's turn to play
		// Not sure why Fuego doesn't handle this...
		if ([self beginningOfHandicapGame]) {
			goGame->SetToPlay(SG_WHITE);
		}
	}
	return self;
}

- (NSString *)comment {
	if (goGame->CurrentNode()->HasProp(SG_PROP_COMMENT)) {
		std::string commentString;
		goGame->CurrentNode()->GetStringProp(SG_PROP_COMMENT, &commentString);
		NSString *comment = @(commentString.c_str());
        if ([comment length] > 0) {
            return comment;            
        }
	}
	return nil;
}

- (bool)beginningOfHandicapGame {
	return [self handicap] && [self moveNumber] == [self handicap];
}

- (bool)needsHandicapStones {
	return [self moveNumber] < [self handicap];
}

- (NSArray *)handicapStones {
	if ([self beginningOfHandicapGame]) {
		return [self moves];
	} else {
		return nil;
	}
}

- (bool)gameEnded {
	return _gameEnded && goGame->EndOfGame();
}

- (NSArray *)flatten:(NSArray *)arrayOfArrays {
	NSMutableArray *flatArray = [NSMutableArray array];
	for(NSArray *group in arrayOfArrays) {
		for (id item in group) {
			[flatArray addObject:item];
		}
	}
	return flatArray;
}


- (NSArray *)markedStones {
	return [self flatten:self.markedGroups];
}

- (NSArray *)deadStones {
	NSMutableArray *deadStones = [[self changedStones] mutableCopy];
	NSArray *markedStones = [self markedStones];
	
	// if a move appears in both markedStones and changedStones, 
	// it should not be in deadStones
	for (Move *move in markedStones) {
		if (NSNotFound == [deadStones indexOfObject:move]) {
			[deadStones addObject:move];
		} else {
			[deadStones removeObject:move];
		}
	}

	return deadStones;
}

- (NSArray *)changedStones {
	return [self flatten:self.changedGroups];
}

- (int)size {
	return goGame->Board().Size();
}

- (int)handicap {
	return goGame->Board().Rules().Handicap();
}

- (void)undoLastMove {
	if (self.resignMove) {
		self.resignMove = nil;
	} else if ([self gameEnded] && [self.changedGroups count] > 0) {
		self.changedGroups = [self.changedGroups subarrayWithRange:NSMakeRange(0, [self.changedGroups count] - 1)];
	} else {
		goGame->GoInDirection(SgNode::PREVIOUS);
	}
}

- (Move *)moveFromNode:(const SgNode *)node {
	
	if (!node->HasNodeMove()) {
		return nil;
	}
	
	Move *currentMove = [[Move alloc] init];
	
	SgPoint move = node->NodeMove();

	if (SgIsSpecialMove(move)) {
		if (move == SG_PASS) {
			currentMove.moveType = kMoveTypePass;
		}
	} else {
		currentMove.col = SgPointUtil::Col(node->NodeMove());
		currentMove.row = SgPointUtil::Row(node->NodeMove());
		currentMove.moveType = kMoveTypeMove;
	}
	
	currentMove.player = [self playerForSgPlayer:node->NodePlayer()];
	currentMove.boardSize = [self size];
	
	return currentMove;
}

- (Move *)lastMove {
	
	if (self.moveNumber <= [self handicap] + 1) {
		return nil;
	}
	
	const SgNode *currentNode = goGame->CurrentNode();
	
	// If we have a resign move, pretend that the last move is actually the 'current move', from the perspective of the sgf file
	if (!self.resignMove) {
		goGame->GoInDirection(SgNode::PREVIOUS);
	}
	Move *lastMove = [self moveFromNode:goGame->CurrentNode()];
	if (!self.resignMove) {
		goGame->GoToNode(currentNode);
	}
	return lastMove;
}

- (Move *)currentMove {
	if (self.resignMove) {
		return self.resignMove;
	} else {
		return [self moveFromNode:goGame->CurrentNode()];
	}
}

- (NSArray *)moves {
	NSMutableArray *moves = [NSMutableArray array];
	
	for (GoBoard::Iterator it(goGame->Board()); it; ++it) {
		Move *move = [[Move alloc] init];
		move.col = SgPointUtil::Col(*it);
		move.row = SgPointUtil::Row(*it);
		move.boardSize = [self size];
		if (goGame->Board().Occupied(*it)) {
			move.player = [self playerForSgPlayer:goGame->Board().GetStone(*it)];
			[moves addObject:move];
		}
	}
	
	return moves;
}

- (int)moveNumber {
	int moveNumber = goGame->Board().MoveNumber();
	moveNumber += goGame->Board().Setup().m_stones.Both().Size();
	if (self.resignMove) {
		++moveNumber;
	}
	moveNumber += scoringMoves;
	return moveNumber;
}

- (bool)playStoneAtRow:(int)row column:(int)col {
	
	if (row <= 0 || row > [self size] || col <= 0 || col > [self size]) {
		return NO;
	}
	
	if (![self canPlayMove]) {
		return NO;
	}
	SgPoint p = SgPointUtil::Pt(col, row);
	if (goGame->Board().IsLegal(p)) {
		goGame->AddMove(p, goGame->Board().ToPlay());
		return YES;
	} else {
		return NO;
	}
	return NO;
}

- (bool)alreadyMarkedPointAtRow:(int)row column:(int)col {
	if (row <= 0 || row > [self size] || col <= 0 || col > [self size]) {
		return NO;
	}
	for (Move *move in [self changedStones]) {
		if ([move row] == row && [move col] == col) {
			return YES;
		}
	}
	return NO;
}

- (bool)markDeadStonesAtRow:(int)row column:(int)col {
	if (row <= 0 || row > [self size] || col <= 0 || col > [self size]) {
		return NO;
	}
	SgPoint point = SgPointUtil::Pt(col, row);
	if (goGame->Board().Occupied(point)) {
		
		if ([self alreadyMarkedPointAtRow:row column:(int)col]) {
			return NO;
		}
		
		GoRegionBoard regionBoard(goGame->Board());
		NSMutableArray *mutableChangedGroups = [self.changedGroups mutableCopy];
		NSMutableArray *markedGroup = [[NSMutableArray alloc] init];
		GoBlock *block = regionBoard.BlockAt(point);
		
		for(SgSetIterator it(block->Stones()); it; ++it) {

			Move *move = [[Move alloc] init];
			
			move.row = SgPointUtil::Row(*it);
			move.col = SgPointUtil::Col(*it);
			move.boardSize = [self size];
			
			move.player = [self playerForSgPlayer:goGame->Board().GetStone(*it)];
			
			[markedGroup addObject:move];
		}
		[mutableChangedGroups addObject:markedGroup];
		self.changedGroups = mutableChangedGroups;
		return YES;
	} 
	return NO;
}

- (void)pass {
	goGame->AddMove(SG_PASS, goGame->Board().ToPlay());
}

- (void)resign {
	// resigns are special because they aren't supported by fuego
	Move *currentMove = [[Move alloc] init];
	
	currentMove.moveType = kMoveTypeResign;
	if (goGame->Board().ToPlay() == SG_WHITE) {
		currentMove.player = kMovePlayerWhite;
	} else {
		currentMove.player = kMovePlayerBlack;
	}
	currentMove.boardSize = [self size];
	
	self.resignMove = currentMove;
}

- (NSArray *)territory {
	NSMutableArray *points = [[NSMutableArray alloc] init];
	GoSetup tempSetup;
	NSArray *stones = [self deadStones];
	
	for(Move *move in [self moves]) {
		if (NSNotFound == [stones indexOfObject:move] && move.moveType == kMoveTypeMove) {
			SgPoint point = SgPointUtil::Pt(move.col, move.row);
			if (move.player == kMovePlayerBlack) {
				tempSetup.AddBlack(point);
			} else {
				tempSetup.AddWhite(point);
			}
		} 
	}
	
	GoBoard tempBoard([self size], tempSetup);
	SgPointArray<SgEmptyBlackWhite> scoreBoard;

	GoBoardUtil::TrompTaylorScore(tempBoard, 6.5, &scoreBoard);
	
	for (SgSetIterator it(tempBoard.AllPoints()); it; ++it) {			
		Move *move = [[Move alloc] init];
		move.row = SgPointUtil::Row(*it);
		move.col = SgPointUtil::Col(*it);
		
		move.player = [self playerForSgPlayer:scoreBoard[*it]];
		
		[points addObject:move];
	}
	return points;
}

- (bool)canUndo {
	if ([self gameEnded] && [[self changedGroups] count] > 0) {
		return YES;
	} else if (self.resignMove) {
		return YES;
	} else if (goGame->CurrentNode() != startNode) {
		return YES;
	}
	return NO;
}

- (bool)canPlayMove {
	if ([self gameEnded] && [[self changedGroups] count] > 0) {
		return NO;
	} else if ([self handicap] && [self needsHandicapStones]) {
		return YES;
	} else if (goGame->CurrentNode() == startNode) {
		return YES;
	}
	return NO;
}

- (bool)canPassOrResign {
	if ([self gameEnded]) {
		return NO;
	} else if ([self needsHandicapStones]) {
		return NO;
	} else if (self.resignMove) {
		return NO;
	} else if (goGame->CurrentNode() == startNode) {
		return YES;
	}
	return NO;
}

- (bool)canSubmit {
	if ([self handicap] && [self needsHandicapStones]) {
		return NO;
	} else if ([self canUndo]) {
		return YES;
	} else if ([self gameEnded]) {
		return YES;
	}
	return NO;
}

- (NSString *)name:(MovePlayer)movePlayer {
	SgBlackWhite player;
	if (movePlayer == kMovePlayerBlack) {
		player = SG_BLACK;
	} else {
		player = SG_WHITE;
	}
	return @(goGame->GetPlayerName(player).c_str());
}
- (int)captures:(MovePlayer)movePlayer {
	SgBlackWhite player;
	if (movePlayer == kMovePlayerBlack) {
		player = SG_WHITE;
	} else {
		player = SG_BLACK;
	}
	return goGame->Board().NumPrisoners(player);
}

- (float)score {
	
	SgPointSet deadPoints;
	float score = 0.0;
	for (Move *move in [self deadStones]) {
		deadPoints.Include(SgPointUtil::Pt([move col], [move row]));
	}
	
	GoBoardUtil::ScorePosition(goGame->Board(), deadPoints, score);
	return score;
	
}

- (void)dealloc {
	delete goGame;
}

@end
