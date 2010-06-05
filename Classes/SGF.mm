//
//  SGF.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/4/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import "SGF.h"
#import "SgGameReader.h"
#import "SgNode.h"
#import "SgInit.h"
#import "GoInit.h"
#include <sstream>

@implementation SGF

- (id)initWithString:(NSString *)sgfString boardSize:(int)boardSize {
	if ([super init]) {
		std::string sgfStr([sgfString UTF8String]);
		std::istringstream input(sgfStr);
		SgInit();
		GoInit();
		SgGameReader gameReader(input, boardSize);
		SgNode *rootNode = gameReader.ReadGame();
		GoBoard goBoard;
		goGame = new GoGame(goBoard);
		goGame->Init(rootNode, true, false);
		while (goGame->CanGoInDirection(SgNode::NEXT)) {
			goGame->GoInDirection(SgNode::NEXT);
		}
		NSLog(@"%d", goGame->CurrentMoveNumber());
	}
	return self;
}

- (void)dealloc {
	delete goGame;
	[super dealloc];
}

@end
