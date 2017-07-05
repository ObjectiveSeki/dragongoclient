//
//  GameViewController.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/5/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GoBoardViewDelegate.h"

@class GoBoardView, MessageView, Game, FuegoBoard;

typedef NS_ENUM(NSInteger, BoardState) {
	kBoardStateZoomedOut,
	kBoardStateZoomedIn,
};

@interface GameViewController : UIViewController <GoBoardViewDelegate>

@property(nonatomic, strong) Game *game;
@property(nonatomic) BOOL readOnly;

@property(nonatomic, strong) IBOutlet GoBoardView *boardView;
@property(nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property(nonatomic, strong) IBOutlet UIBarButtonItem *undoButton;
@property(nonatomic, strong) IBOutlet UIBarButtonItem *zoomOutButton;
@property(nonatomic, strong) IBOutlet UIBarButtonItem *confirmButton;
@property(nonatomic, strong) IBOutlet UIBarButtonItem *resignButton;
@property(nonatomic, strong) IBOutlet UIBarButtonItem *messageButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *nextMoveButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *previousMoveButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *shareButton;
@property(nonatomic, strong) IBOutlet MessageView *messageView;
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;

@property (weak, nonatomic) IBOutlet UIView *statusBar;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *statusPositionConstraint;
@property (weak, nonatomic) IBOutlet UIView *bottomBar;


- (IBAction)undoMove;
- (IBAction)zoomOut;
- (IBAction)confirmMove;
- (IBAction)pass;
- (IBAction)resign;
- (IBAction)showPassResignPanel:(id)sender;
- (IBAction)showMessageWindow;
- (IBAction)share:(id)sender;
- (IBAction)goToPreviousMove:(id)sender;
- (IBAction)goToNextMove:(id)sender;

@end

