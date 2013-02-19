//
//  GameViewController.mm
//  DGSPhone
//
//  Created by Justin Weiss on 6/5/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import "GameViewController.h"
#import "FuegoBoard.h"
#import "Game.h"
#import "GoBoardView.h"
#import "MessageView.h"
#import "SpinnerView.h"
#import "NSTimer+Blocks.h"

@interface GameViewController ()

@property(nonatomic, strong) FuegoBoard *board;
@property(nonatomic) BoardState boardState;

// Zooming state
@property (nonatomic, assign) CGFloat currentZoomScale;
@property (nonatomic, assign) CGFloat maximumZoomScale;
@property (nonatomic, assign) CGFloat minimumZoomScale;

// SGF Sharing
@property (nonatomic, strong) UIDocumentInteractionController *shareController;
@property (nonatomic, strong) NSOperationQueue *sgfShareQueue;
@property (nonatomic, strong) NSOperation *sgfShareOperation;

@property (nonatomic, strong) SpinnerView *spinner;

@property (nonatomic, strong) UIActionSheet *passResignActionSheet;

// A timer that's triggered when the forward button is hit. It temporarily
// disables the resign button, to help avoid accidental keypresses.
@property (nonatomic, strong) NSTimer *resignInteractionTimer;

@property (nonatomic, strong) UIGestureRecognizer *goToBeginningGestureRecognizer;
@property (nonatomic, strong) UIGestureRecognizer *goToCurrentMoveGestureRecognizer;

@end

const NSTimeInterval kDefaultResignTimerLength = 1.0;

@implementation GameViewController

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"ViewDidLoad");
	UIScrollView *tempScrollView = (UIScrollView *)self.scrollView;
    tempScrollView.contentSize = CGSizeMake(self.boardView.bounds.size.height, self.boardView.bounds.size.width);
	self.currentZoomScale = 1.0;
	self.navigationItem.title = [NSString stringWithFormat:@"vs. %@", [self.game opponent]];
    self.spinner = [[SpinnerView alloc] initInView:self.view];
    self.scrollView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Game Background.png"]];
    self.goToBeginningGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(goToBeginning:)];
    self.goToCurrentMoveGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(goToCurrentMove:)];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.boardState = kBoardStateZoomedOut;
    NSLog(@"creating board...");
    NSLog(@"BoardView: %@", self.boardView);
    // Make sure the board view doesn't go away. This should never happen!
    NSAssert(self.boardView, @"The board view went away.");
    
	FuegoBoard *theBoard = [[FuegoBoard alloc] initWithSGFString:[self.game sgfString]];
	[[self boardView] setBoard:theBoard];
	[self setBoard:theBoard];
    
	self.currentZoomScale = [self zoomInScale];
	[self lockZoom];
	[self zoomToScale:0.5 center:self.boardView.center animated:NO];
    [self updateUI];
    self.sgfShareQueue = [[NSOperationQueue alloc] init];
    self.sgfShareQueue.name = @"SGF saving queue";
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[self.boardView setBoard:nil];
    [self.sgfShareQueue cancelAllOperations];
    self.sgfShareQueue = nil;
	self.board = nil;
}

#pragma mark - UI State

- (void)updateMessageState {
    BOOL hasCommentOrReply = [self.messageView hasMessageOrReply];
    BOOL canLeaveComment = !(self.readOnly || [self.board beforeCurrentMove]);
    
    [self setMessageIconState:hasCommentOrReply];
    self.messageView.showInputView = canLeaveComment;
    self.messageButton.enabled = (canLeaveComment || hasCommentOrReply);
}

- (void)replaceToolbarItemAtIndex:(int)itemIndex withItem:(UIBarButtonItem *)toolbarItem {
    int index = itemIndex * 2 + 1; // each item has something in between.
    if (toolbarItem == [self.toolbar.items objectAtIndex:index]) {
        return;
    }

    NSMutableArray *toolbarItems = [self.toolbar.items mutableCopy];
    [toolbarItems replaceObjectAtIndex:index withObject:toolbarItem];
    [self.toolbar setItems:toolbarItems animated:YES];
}

- (void)updateNavigationBar {
    if ([self.board canUndo]) {
		[self.navigationItem setRightBarButtonItem:[self undoButton] animated:YES];
	} else if (self.boardState == kBoardStateZoomedIn) {
        [self.navigationItem setRightBarButtonItem:self.zoomOutButton animated:YES];
    } else {
		[self.navigationItem setRightBarButtonItem:nil animated:YES];
	}
}

- (void)updateToolbar {
    if (self.readOnly) {
        self.passButton.enabled = NO;
        self.resignButton.enabled = NO;
    } else {
        self.confirmButton.enabled = self.board.canSubmit;
        self.passButton.enabled = self.board.canPassOrResign;
        self.resignButton.enabled = self.board.canPassOrResign;
    }
    
    self.previousMoveButton.enabled = self.board.hasPreviousMove;
    self.nextMoveButton.enabled = self.board.beforeCurrentMove;
    
    if (self.board.beforeCurrentMove || [self.resignInteractionTimer isValid]) {
        [self replaceToolbarItemAtIndex:1 withItem:self.nextMoveButton];
    } else {
        [self replaceToolbarItemAtIndex:1 withItem:self.resignButton];
    }
 
    // ugh. This hack will probably break at some point. Hopefully I remember
    // that I wrote this when it does!
    [[self.nextMoveButton valueForKey:@"view"] addGestureRecognizer:self.goToCurrentMoveGestureRecognizer];
    [[self.previousMoveButton valueForKey:@"view"] addGestureRecognizer:self.goToBeginningGestureRecognizer];
}

- (void)updateUI {
    NSLog(@"BoardView: %@", self.boardView);
    // Make sure the board view doesn't go away. This should never happen!
    NSAssert(self.boardView, @"The board view went away.");
    self.messageView.message = self.board.comment;
    [self updateMessageState];
    [self updateNavigationBar];
    [self updateToolbar];
    [self.boardView setNeedsDisplay]; // show just placed move
}

// Sets the 'message waiting' toolbar indicator based on the value of hasMessage.
- (void)setMessageIconState:(BOOL)hasMessage {
	if (hasMessage) {
		self.messageButton.image = [UIImage imageNamed:@"Message on.png"];
	} else {
		self.messageButton.image = [UIImage imageNamed:@"Message off.png"];
	}
}

#pragma mark - Zooming and scrolling

// Is this board too small to justify zooming?
- (BOOL)isSmallBoard {
	return [self.board size] < 13;
}

- (float)zoomInScale {
	return (float)[self.board size] / 19.0;
}

- (CGRect)zoomRectForScrollView:(UIScrollView *)theScrollView withScale:(float)scale withCenter:(CGPoint)center {

    CGRect zoomRect;

    // The zoom rect is in the content view's coordinates.
    // At a zoom scale of 1.0, it would be the size of the
    // imageScrollView's bounds.
    // As the zoom scale decreases, so more content is visible,
    // the size of the rect grows.
    zoomRect.size.height = theScrollView.frame.size.height / scale;
    zoomRect.size.width  = theScrollView.frame.size.width  / scale;

    // choose an origin so as to get the right center.
    zoomRect.origin.x = center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0);

    return zoomRect;
}

-(void)lockZoom
{
    self.maximumZoomScale = self.scrollView.maximumZoomScale;
    self.minimumZoomScale = self.scrollView.minimumZoomScale;

    self.scrollView.maximumZoomScale = self.currentZoomScale;
    self.scrollView.minimumZoomScale = self.currentZoomScale;
}

-(void)unlockZoom
{
    self.scrollView.maximumZoomScale = self.maximumZoomScale;
    self.scrollView.minimumZoomScale = self.minimumZoomScale;
}

- (void)zoomToScale:(float)scale center:(CGPoint)center animated:(bool)animated {
	[self unlockZoom];
	self.currentZoomScale = scale;
	CGRect zoomRect = [self zoomRectForScrollView:self.scrollView withScale:scale withCenter:center];
	[self.scrollView zoomToRect:zoomRect animated:animated];
    
    // Center the board view in the scroll view if it's smaller than the scroll view
    CGPoint contentOffset = self.scrollView.contentOffset;
    if (self.scrollView.contentSize.width < self.scrollView.bounds.size.width) {
        contentOffset.x = -(self.scrollView.bounds.size.width - self.scrollView.contentSize.width) / 2;
    }
    if (self.scrollView.contentSize.height < self.scrollView.bounds.size.height) {
        contentOffset.y = -(self.scrollView.bounds.size.height - self.scrollView.contentSize.height) / 2;
    }
    [self.scrollView setContentOffset:contentOffset animated:YES];
    
	[self lockZoom];
}

- (void)zoomOut:(CGPoint)center {
	self.boardState = kBoardStateZoomedOut;
	if (self.currentZoomScale != 0.5) {
		[self zoomToScale:0.5 center:center animated:YES];
	}
	[self updateUI];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.boardView;
}

#pragma mark - UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (actionSheet == self.passResignActionSheet) {
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            [self resign];
        } else if (buttonIndex != actionSheet.cancelButtonIndex) {
            [self pass];
        }
        self.passResignActionSheet = nil;
    }
}

#pragma mark - Toolbar actions

- (IBAction)zoomOut {
	[self zoomOut:self.boardView.center];
}

- (IBAction)undoMove {
	[self.board undoLastMove];
	[self updateUI];
}

- (IBAction)confirmMove {
    self.spinner.label.text = @"Submitting…";
    [self.spinner show];
	self.confirmButton.enabled = NO;
    
	NSString *reply = self.messageView.reply;
    
	void (^onSuccess)() = ^() {
		[self playedMove];
	};
    
	if ([self.board beginningOfHandicapGame]) {
        [[GenericGameServer sharedGameServer] playHandicapStones:[self.board handicapStones] comment:reply game:self.game onSuccess:onSuccess onError:^(NSError *error) {
            [self.spinner dismiss:YES];
        }];
	} else if ([self.board gameEnded]) {
		[[GenericGameServer sharedGameServer] markDeadStones:[self.board changedStones] moveNumber:[self.board moveNumber] comment:reply game:self.game onSuccess:onSuccess onError:^(NSError *error) {
            [self.spinner dismiss:YES];
        }];
	} else {
		[[GenericGameServer sharedGameServer] playMove:[self.board currentMove] lastMove:[self.board lastMove] moveNumber:[self.board moveNumber] comment:reply game:self.game onSuccess:onSuccess onError:^(NSError *error) {
            [self.spinner dismiss:YES];
        }];
	}
}

- (IBAction)pass {
	[self.board pass];
	[self updateUI];
}

- (IBAction)resign {
	[self.board resign];
	[self updateUI];
}

- (IBAction)showPassResignPanel:(id)sender {
    self.passResignActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Resign" otherButtonTitles:@"Pass", nil];
    [self.passResignActionSheet showFromBarButtonItem:sender animated:YES];
}

- (IBAction)showMessageWindow {
	[self.navigationController.view addSubview:self.messageView];
	[self.messageView show:^() {
		[self updateMessageState];
	}];
}

- (IBAction)share:(id)sender {
    if (!self.shareController && !self.sgfShareOperation) {
        self.sgfShareOperation = [NSBlockOperation blockOperationWithBlock:^{
            NSError *writeError;
            NSString *tmpFilename = [NSString stringWithFormat:@"dgs-game-%d-%d.sgf", self.game.gameId, self.board.moveNumber];
            NSString *tmpFileFullPath = [NSTemporaryDirectory() stringByAppendingPathComponent:tmpFilename];
            
            if (!self.sgfShareOperation.isCancelled) {
                if (![self.game.sgfString writeToFile:tmpFileFullPath atomically:YES encoding:NSUTF8StringEncoding error:&writeError]) {
                    NSLog(@"Error writing sgf file: %@", writeError.localizedDescription);
                }
            }
            
            if (!self.sgfShareOperation.isCancelled) {
                self.shareController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:tmpFileFullPath]];
            }
            if (!self.sgfShareOperation.isCancelled) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    self.sgfShareOperation = nil;
                    [self share:sender];
                }];
            }
            self.sgfShareOperation = nil;
        }];
        [self.sgfShareQueue addOperation:self.sgfShareOperation];
    }
    [self.shareController presentOptionsMenuFromBarButtonItem:sender animated:YES];
}

- (IBAction)goToBeginning:(id)sender {
    [self.board goToBeginning];
    [self updateUI];
}

- (IBAction)goToCurrentMove:(id)sender {
    [self.board goToCurrentMove];
    [self updateUI];
}

- (IBAction)goToPreviousMove:(id)sender {
    [self.board goToPreviousMove];
    [self updateUI];
}

- (IBAction)goToNextMove:(id)sender {
    [self.board goToNextMove];
    
    if ([self.board atCurrentMove]) {
        [self.resignInteractionTimer invalidate];
        self.resignInteractionTimer = [NSTimer scheduledTimerWithTimeInterval:kDefaultResignTimerLength block:^(NSTimer *timer) {
            self.resignInteractionTimer = nil;
            [self updateUI];
        } repeats:NO];
    }
    
    [self updateUI];
}

#pragma mark - Playing moves

- (void)handleGoBoardTouch:(UITouch *)touch inView:(GoBoardView *)view {
    
    BOOL canPlaceStones = [self.board canPlayMove] || [self.board gameEnded];
    
	BOOL canZoomIn = canPlaceStones || [self.board beforeCurrentMove] || self.readOnly;
    BOOL shouldZoomIn = ![self isSmallBoard] && self.boardState == kBoardStateZoomedOut && canZoomIn;
    
    BOOL isZoomedIn = [self isSmallBoard] || self.boardState == kBoardStateZoomedIn;
    BOOL canPlayOrMarkStones = !self.readOnly && canPlaceStones && isZoomedIn;
    
    NSLog(@"Zoom State: %d %d %d %d %d %d", [self.board canPlayMove], [self.board gameEnded], [self.board beforeCurrentMove], self.readOnly, [self isSmallBoard], self.boardState);
    
	if (shouldZoomIn) {
		[self zoomToScale:[self zoomInScale] center:[touch locationInView:view] animated:YES];
		[self setBoardState:kBoardStateZoomedIn];
		[self.passButton setEnabled:NO];
		[self.resignButton setEnabled:NO];
		[self.navigationItem setRightBarButtonItem:self.zoomOutButton animated:YES];
	} else if (canPlayOrMarkStones) {
		BOOL markedDeadStones = [self.board gameEnded] && [view markDeadStonesAtPoint:[touch locationInView:view]];
        
		BOOL playedStone = !markedDeadStones && [view playStoneAtPoint:[touch locationInView:view]];
		if (markedDeadStones || playedStone) {
			[self zoomOut:[touch locationInView:view]];
		}
	}
}

- (void)playedMove {
	[self.spinner dismiss:YES];
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    NSLog(@"viewDidUnload called");
    [self setPreviousMoveButton:nil];
    [self setNextMoveButton:nil];
    [self setPreviousMoveButton:nil];
    [self setToolbar:nil];
    [super viewDidUnload];
}
@end
