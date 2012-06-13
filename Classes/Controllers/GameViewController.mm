//
//  GameViewController.mm
//  DGSPhone
//
//  Created by Justin Weiss on 6/5/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import "GameViewController.h"
#import "LoginViewController.h"
#import "FuegoBoard.h"
#import "DGSPhoneAppDelegate.h"

@implementation GameViewController

@synthesize game;
@synthesize board;
@synthesize boardView;
@synthesize scrollView;
@synthesize boardState;
@synthesize undoButton;
@synthesize zoomOutButton;
@synthesize confirmButton;
@synthesize passButton;
@synthesize resignButton;
@synthesize messageButton;
@synthesize messageView;
@synthesize delegate = _delegate;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

// Is this board too small to justify zooming?
- (BOOL)smallBoard {
	return [self.board size] < 13;
}

- (float)zoomInScale {
	return (float)[self.board size] / 19.0;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	UIScrollView *tempScrollView=(UIScrollView *)self.scrollView;
    tempScrollView.contentSize=CGSizeMake(self.boardView.bounds.size.height, self.boardView.bounds.size.width);
	currentZoomScale = 1.0;
	self.navigationItem.title = [NSString stringWithFormat:@"vs. %@", [game opponent]];
}

- (void)updateBoard {
	if ([self.board canUndo]) {
		[self.navigationItem setRightBarButtonItem:[self undoButton] animated:YES];
	} else {
		[self.navigationItem setRightBarButtonItem:nil animated:YES];
	}
	[[self confirmButton] setEnabled:[self.board canSubmit]];
	[[self passButton] setEnabled:[self.board canPassOrResign]];
	[[self resignButton] setEnabled:[self.board canPassOrResign]];
    JWLog(@"boardView:%@ setNeedsDisplay", self.boardView);
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

- (IBAction)undoMove {
	[self.board undoLastMove];
	[self updateBoard];
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
    maximumZoomScale = self.scrollView.maximumZoomScale;
    minimumZoomScale = self.scrollView.minimumZoomScale;

    self.scrollView.maximumZoomScale = currentZoomScale;
    self.scrollView.minimumZoomScale = currentZoomScale;
}

-(void)unlockZoom
{
    self.scrollView.maximumZoomScale = maximumZoomScale;
    self.scrollView.minimumZoomScale = minimumZoomScale;
}

- (void)zoomToScale:(float)scale center:(CGPoint)center animated:(bool)animated {
	[self unlockZoom];
	currentZoomScale = scale;
	CGRect zoomRect = [self zoomRectForScrollView:[self scrollView] withScale:scale withCenter:center];
	[[self scrollView] zoomToRect:zoomRect animated:animated];
	[self lockZoom];
}

- (void)zoomOut:(CGPoint)center {
	self.boardState = kBoardStateZoomedOut;
	if (currentZoomScale != 0.5) {
		[self zoomToScale:0.5 center:center animated:YES];
	}
	[self updateBoard];
}

- (IBAction)zoomOut {
	[self zoomOut:[self.boardView center]];
}

- (void)playedMove {
	[self hideSpinner:YES];
    if (self.delegate) {
        [self.delegate playedMoveInGame:self.game];
    }
	[[self navigationController] popViewControllerAnimated:YES];
}

- (IBAction)confirmMove {
	[self showSpinner:@"Submitting..."];
	self.confirmButton.enabled = NO;

	NSString *reply = self.messageView.reply;

	void (^onSuccess)() = ^() {
		[self playedMove];
	};

	if ([self.board beginningOfHandicapGame]) {
		[self.gs playHandicapStones:[self.board handicapStones] comment:reply gameId:self.game.gameId onSuccess:onSuccess];
	} else if ([self.board gameEnded]) {
		[self.gs markDeadStones:[self.board changedStones] moveNumber:[self.board moveNumber] comment:reply gameId:self.game.gameId onSuccess:onSuccess];
	} else {
		[self.gs playMove:[self.board currentMove] lastMove:[self.board lastMove] moveNumber:[self.board moveNumber] comment:reply gameId:self.game.gameId onSuccess:onSuccess];
	}
}

- (IBAction)pass {
	[self.board pass];
	[self updateBoard];
}

- (IBAction)resign {
	[self.board resign];
	[self updateBoard];
}

- (IBAction)showMessageWindow {
	[self.navigationController.view addSubview:self.messageView];
	[self.messageView show:^(BOOL hasMessage) {
		[self setMessageIconState:hasMessage];
	}];
}

- (void)requestCancelled {
	[self hideSpinner:NO];
	self.confirmButton.enabled = YES;
}

- (void)handleGoBoardTouch:(UITouch *)touch inView:(GoBoardView *)view {

	BOOL canZoomIn = [self.board canPlayMove] || [self.board gameEnded];

	if (![self smallBoard] && [self boardState] == kBoardStateZoomedOut && canZoomIn) {
		[self zoomToScale:[self zoomInScale] center:[touch locationInView:view] animated:YES];
		[self setBoardState:kBoardStateZoomedIn];
		[[self passButton] setEnabled:NO];
		[[self resignButton] setEnabled:NO];
		[self.navigationItem setRightBarButtonItem:self.zoomOutButton animated:YES];
	} else if ([self smallBoard] || [self boardState] == kBoardStateZoomedIn) {
		BOOL markedDeadStones = [self.board gameEnded] && [view markDeadStonesAtPoint:[touch locationInView:view]];

		BOOL playedStone = !markedDeadStones && [view playStoneAtPoint:[touch locationInView:view]];
		if (markedDeadStones || playedStone) {
			[self zoomOut:[touch locationInView:view]];
		}
	}
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.boardView;
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc that aren't in use.
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self setBoardState:kBoardStateZoomedOut];
    JWLog("creating board...");
	FuegoBoard *theBoard = [[FuegoBoard alloc] initWithSGFString:[game sgfString]];
	[[self boardView] setBoard:theBoard];
	[self setBoard:theBoard];

	if ([theBoard comment]) {
		[self setMessageIconState:YES];
		self.messageView.message = [theBoard comment];
	}

	[theBoard release];
	currentZoomScale = [self zoomInScale];
	[self lockZoom];
	[self zoomToScale:0.5 center:[[self boardView] center] animated:NO];
	[self updateBoard];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[self.boardView setBoard:nil];
	self.board = nil;
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	self.boardView = nil;
	self.undoButton = nil;
	self.zoomOutButton = nil;
	self.confirmButton = nil;
	self.passButton = nil;
	self.resignButton = nil;
	self.messageButton = nil;
	self.messageView = nil;
    [super viewDidUnload];
}


- (void)dealloc {
	self.game = nil;
    [super dealloc];
}


@end
