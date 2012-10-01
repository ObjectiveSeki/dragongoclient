//
//  GameViewController.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/5/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Game.h"
#import "GoBoardView.h"
#import "MessageView.h"
#import "RootViewController.h"
#import "GameStatusProtocol.h"

enum BoardState {
	kBoardStateZoomedOut,
	kBoardStateZoomedIn,
};

@interface GameViewController : RootViewController <LoginProtocol> {
	Game *game;
	FuegoBoard *board;
	IBOutlet GoBoardView *boardView;
	IBOutlet UIScrollView *scrollView;
	IBOutlet UIBarButtonItem *undoButton;
	IBOutlet UIBarButtonItem *zoomOutButton;
	IBOutlet UIBarButtonItem *confirmButton;
	IBOutlet UIBarButtonItem *passButton;
	IBOutlet UIBarButtonItem *resignButton;
	IBOutlet UIBarButtonItem *messageButton;
	IBOutlet MessageView *messageView;
	BoardState boardState;
	float maximumZoomScale;
	float minimumZoomScale;
	float currentZoomScale;
}

@property(nonatomic, strong) Game *game;
@property(nonatomic, strong) FuegoBoard *board;
@property(nonatomic, strong) IBOutlet GoBoardView *boardView;
@property(nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property(nonatomic) BoardState boardState;
@property(nonatomic, strong) IBOutlet UIBarButtonItem *undoButton;
@property(nonatomic, strong) IBOutlet UIBarButtonItem *zoomOutButton;
@property(nonatomic, strong) IBOutlet UIBarButtonItem *confirmButton;
@property(nonatomic, strong) IBOutlet UIBarButtonItem *passButton;
@property(nonatomic, strong) IBOutlet UIBarButtonItem *resignButton;
@property(nonatomic, strong) IBOutlet UIBarButtonItem *messageButton;
@property(nonatomic, strong) IBOutlet MessageView *messageView;
@property(nonatomic, weak) id <GameStatusProtocol> delegate;

- (IBAction)undoMove;
- (IBAction)zoomOut;
- (IBAction)confirmMove;
- (IBAction)pass;
- (IBAction)resign;
- (IBAction)showMessageWindow;

@end

