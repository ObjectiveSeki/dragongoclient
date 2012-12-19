//
//  GameViewController.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/5/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GoBoardView, MessageView, Game, FuegoBoard;

enum BoardState {
	kBoardStateZoomedOut,
	kBoardStateZoomedIn,
};

@interface GameViewController : UIViewController {
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

- (IBAction)undoMove;
- (IBAction)zoomOut;
- (IBAction)confirmMove;
- (IBAction)pass;
- (IBAction)resign;
- (IBAction)showMessageWindow;
- (IBAction)share:(id)sender;

@end

