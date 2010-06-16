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
		goBoard = new GoBoard();
		goGame = new GoGameRecord(*goBoard);
		goGame->InitFromRoot(rootNode, true);
		
		// Fast-forward to the end of the game
		while (goGame->CanGoInDirection(SgNode::NEXT)) {
			goGame->GoInDirection(SgNode::NEXT);
		}
	}
	return self;
}

- (int)size {
	return goGame->Board().Size();
}

- (void)undoLastMove {
	goGame->GoInDirection(SgNode::PREVIOUS);
	goGame->CurrentNode()->DeleteSubtree();
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
		} else if (move == SG_RESIGN) {
			currentMove.moveType = kMoveTypeResign;
		}
	} else {
		currentMove.col = SgPointUtil::Col(node->NodeMove());
		currentMove.row = SgPointUtil::Row(node->NodeMove());
		currentMove.moveType = kMoveTypeMove;
	}
	return currentMove;
}

- (Move *)lastMove {
	SgNode *currentNode = goGame->CurrentNode();
	goGame->GoInDirection(SgNode::PREVIOUS);
	Move *lastMove = [self moveFromNode:goGame->CurrentNode()];
	goGame->GoToNode(currentNode);
	return lastMove;
}

- (Move *)currentMove {
	return [self moveFromNode:goGame->CurrentNode()];
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

- (bool)playStoneAtRow:(int)row column:(int)col {
	SgPoint p = SgPointUtil::Pt(col, row);
	NSLog(@"%d %d", row, col);
	NSLog(@"%@", [DGS sgfCoordsWithRow:row column:col boardSize:[self size]]);
	if (goGame->Board().IsLegal(p)) {
		goGame->AddMove(p, goGame->Board().ToPlay());
		goGame->GoInDirection(SgNode::NEXT);
		return YES;
	} else {
		return NO;
	}
	return NO;
}

- (void)dealloc {
	delete goBoard;
	delete goGame;
	[super dealloc];
}

@end
