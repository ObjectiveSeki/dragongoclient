//
//  PastMoveViewController.m
//  DGSPhone
//
//  Created by Frank Prößdorf on 9/4/12.
//  Copyright (c) 2012 Justin Weiss. All rights reserved.
//

#import "PastMoveViewController.h"

@implementation PastMoveViewController

@synthesize game;
@synthesize moveNumber;
@synthesize board;
@synthesize boardView;
@synthesize scrollView;
@synthesize undoButton;
@synthesize zoomOutButton;
@synthesize historyButton;
@synthesize confirmButton;
@synthesize passButton;
@synthesize resignButton;
@synthesize messageButton;
@synthesize messageView;
@synthesize delegate = _delegate;


- (float)zoomInScale {
	return (float)[self.board size] / 19.0;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	UIScrollView *tempScrollView=(UIScrollView *)self.scrollView;
    tempScrollView.contentSize=CGSizeMake(self.boardView.bounds.size.height, self.boardView.bounds.size.width);
	currentZoomScale = 1.0;
	self.navigationItem.title = [NSString stringWithFormat:@"Move %d", [self moveNumber]];
}

- (void)updateBoard {
    [self.navigationItem setRightBarButtonItem:nil animated:YES];
	[[self confirmButton] setEnabled:false];
	[[self passButton] setEnabled:false];
	[[self resignButton] setEnabled:false];
    [[self messageButton] setEnabled:false];
	[self.boardView setNeedsDisplay];
}

- (void)setMessageIconState:(BOOL)hasMessage {
	if (hasMessage) {
		self.messageButton.image = [UIImage imageNamed:@"Message on.png"];
	} else {
		self.messageButton.image = [UIImage imageNamed:@"Message off.png"];
	}
}

- (IBAction)undoMove {}

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
	if (currentZoomScale != 0.5) {
		[self zoomToScale:0.5 center:center animated:YES];
	}
	[self updateBoard];
}

- (IBAction)zoomOut {
	[self zoomOut:[self.boardView center]];
}

- (IBAction)showHistory {}
- (void)playedMove {}
- (IBAction)confirmMove {}
- (IBAction)pass {}
- (IBAction)resign {}

- (IBAction)showMessageWindow {
	[self.navigationController.view addSubview:self.messageView];
	[self.messageView show:^(BOOL hasMessage) {
		[self setMessageIconState:hasMessage];
	}];
}

- (void)requestCancelled {}
- (void)handleGoBoardTouch:(UITouch *)touch inView:(GoBoardView *)view {}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.boardView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	FuegoBoard *theBoard = [[FuegoBoard alloc] initWithSGFString:[game sgfString]];
    [theBoard goToMove: [self moveNumber]];
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
