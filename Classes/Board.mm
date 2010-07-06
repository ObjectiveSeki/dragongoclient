//
//  Board.mm
//  DGSPhone
//
//  Created by Justin Weiss on 6/4/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import "Board.h"
#import "SgInit.h"
#import "GoInit.h"
#import "SgGameReader.h"
#import "SgNode.h"
#import "Move.h"
#import "DGS.h"
#include <sstream>

@implementation Board

@synthesize resignMove;

+ (void)initFuego {
	SgInit();
	GoInit();
}

+ (void)finishFuego {
	GoFini();
	SgFini();
}

- (id)initWithSGFString:(NSString *)sgfString boardSize:(int)boardSize {
	if ([super init]) {
		std::string sgfStr([sgfString UTF8String]);
		std::istringstream input(sgfStr);
		SgGameReader gameReader(input, boardSize);
		SgNode *rootNode = gameReader.ReadGame();
		int handicap = rootNode->GetIntProp(SG_PROP_HANDICAP);
		int size = rootNode->GetIntProp(SG_PROP_SIZE);
		
		goBoard = new GoBoard(size, GoSetup(), GoRules(handicap));
		goGame = new GoGameRecord(*goBoard);
		goGame->InitFromRoot(rootNode, true);
		
		// Fast-forward to the end of the game
		while (goGame->CanGoInDirection(SgNode::NEXT)) {
			goGame->GoInDirection(SgNode::NEXT);
		}
		
		// If we placed handicap stones, it should be W's turn to play
		// Not sure why Fuego doesn't handle this...
		if ([self handicap] > 0 && [self handicapStonesPlaced]) {
			goGame->SetToPlay(SG_WHITE);
		}
	}
	return self;
}

- (bool)handicapStonesPlaced {
	return [self moveNumber] == [self handicap];
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
	} else {
		goGame->GoInDirection(SgNode::PREVIOUS);
		goGame->CurrentNode()->DeleteSubtree();
	}
}

- (Move *)moveFromNode:(SgNode *)node {
	Move *currentMove = [[[Move alloc] init] autorelease];
	SgPoint move = node->NodeMove();
	
	if (node->NodePlayer() == SG_BLACK) {
		currentMove.player = kMovePlayerBlack;
	} else if (node->NodePlayer() == SG_WHITE) {
		currentMove.player = kMovePlayerWhite;
	}
	
	currentMove.boardSize = [self size];
	
	if (SgIsSpecialMove(move)) {
		if (move == SG_PASS) {
			currentMove.moveType = kMoveTypePass;
		}
	} else {
		currentMove.col = SgPointUtil::Col(node->NodeMove());
		currentMove.row = SgPointUtil::Row(node->NodeMove());
		currentMove.moveType = kMoveTypeMove;
	}
	return currentMove;
}

- (Move *)lastMove {
	
	if (self.moveNumber <= [self handicap] + 1) {
		return nil;
	}
	
	SgNode *currentNode = goGame->CurrentNode();
	
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
	} else if (self.moveNumber <= [self handicap]) {
		return nil;
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
		if (goGame->Board().IsColor(*it, SG_BLACK)) {
			move.player = kMovePlayerBlack;
			[moves addObject:move];
		} else if (goGame->Board().IsColor(*it, SG_WHITE)) {
			move.player = kMovePlayerWhite;
			[moves addObject:move];
		}
		[move release];
	}
	
	return moves;
}

- (int)moveNumber {
	int moveNumber = goGame->Board().MoveNumber();
	moveNumber += goGame->Board().Setup().m_stones.Both().Size();
	if (self.resignMove) {
		++moveNumber;
	}
	return moveNumber;
}

- (bool)playStoneAtRow:(int)row column:(int)col {
	SgPoint p = SgPointUtil::Pt(col, row);
	if (goGame->Board().IsLegal(p)) {
		goGame->AddMove(p, goGame->Board().ToPlay());
		goGame->GoInDirection(SgNode::NEXT);
		return YES;
	} else {
		return NO;
	}
	return NO;
}

- (void)pass {
	goGame->AddMove(SG_PASS, goGame->Board().ToPlay());
	goGame->GoInDirection(SgNode::NEXT);
}

- (void)resign {
	// resigns are special because they aren't supported by fuego
	Move *currentMove = [[Move alloc] init];
	
	currentMove.moveType = kMoveTypeResign;
	Move *lastMove = [self currentMove];
	if ([lastMove player] == kMovePlayerBlack) {
		currentMove.player = kMovePlayerWhite;
	} else {
		currentMove.player = kMovePlayerBlack;
	}
	currentMove.boardSize = [self size];
	
	self.resignMove = currentMove;
	[currentMove release];
}

- (void)dealloc {
	delete goBoard;
	delete goGame;
	self.resignMove = nil;
	[super dealloc];
}

@end
