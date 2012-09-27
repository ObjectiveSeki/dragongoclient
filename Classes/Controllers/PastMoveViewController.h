//
//  PastMoveViewController.h
//  DGSPhone
//
//  Created by Frank Prößdorf on 9/4/12.
//  Copyright (c) 2012 Justin Weiss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Game.h"
#import "Move.h"
#import "GoBoardView.h"
#import "MessageView.h"
#import "RootViewController.h"
#import "PastMovesViewController.h"
#import "GameStatusProtocol.h"

@interface PastMoveViewController : RootViewController <LoginProtocol> {
	Game *game;
    int moveNumber;
	FuegoBoard *board;
	IBOutlet GoBoardView *boardView;
	IBOutlet UIScrollView *scrollView;
	IBOutlet UIBarButtonItem *previousButton;
	IBOutlet UIBarButtonItem *nextButton;
	float maximumZoomScale;
	float minimumZoomScale;
	float currentZoomScale;
}

@property(nonatomic, retain) Game *game;
@property(nonatomic, assign) int moveNumber;
@property(nonatomic, retain) FuegoBoard *board;
@property(nonatomic, retain) IBOutlet GoBoardView *boardView;
@property(nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property(nonatomic, retain) IBOutlet UIBarButtonItem *previousButton;
@property(nonatomic, retain) IBOutlet UIBarButtonItem *nextButton;
@property(nonatomic, assign) id <GameStatusProtocol> delegate;

- (IBAction)previousMove;
- (IBAction)nextMove;

@end

