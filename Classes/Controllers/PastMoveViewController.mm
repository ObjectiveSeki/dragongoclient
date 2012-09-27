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
@synthesize previousButton;
@synthesize nextButton;
@synthesize delegate = _delegate;


- (void)viewDidLoad {
    [super viewDidLoad];
	UIScrollView *tempScrollView = (UIScrollView *)self.scrollView;
    JWLog(@"%f %f", self.boardView.bounds.size.height, self.boardView.bounds.size.width);
    tempScrollView.contentSize = CGSizeMake(self.boardView.bounds.size.height,
                                            self.boardView.bounds.size.width);
	self.navigationItem.title = [NSString stringWithFormat:@"Move %d", [self moveNumber]];
}

- (void)updateBoard {
    [self.navigationItem setRightBarButtonItem:nil animated:YES];
    [self.previousButton setEnabled:false];
    [self.nextButton setEnabled:false];
    JWLog(@"boardView:%@ setNeedsDisplay", self.boardView);
	[self.boardView setNeedsDisplay];
}

- (CGRect)zoomRectForScrollView:(UIScrollView *)theScrollView withScale:(float)scale withCenter:(CGPoint)center {
	
    CGRect zoomRect;
	
    zoomRect.size.height = 640; //theScrollView.frame.size.height / scale;
    zoomRect.size.width  = 640; //theScrollView.frame.size.width  / scale;

    zoomRect.origin.x = 210; //center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y = 210; //center.y - (zoomRect.size.height / 2.0);
	
    return zoomRect;
}

- (void)zoomToScale:(float)scale center:(CGPoint)center animated:(bool)animated {
    self.scrollView.maximumZoomScale = 1.0;
    self.scrollView.minimumZoomScale = 1.0;
	CGRect zoomRect = [self zoomRectForScrollView:[self scrollView] withScale:scale withCenter:center];
	[self.scrollView zoomToRect:zoomRect animated:animated];
    self.scrollView.maximumZoomScale = scale;
    self.scrollView.minimumZoomScale = scale;
}

- (IBAction)previousMove {}
- (IBAction)nextMove {}

- (void)handleGoBoardTouch:(UITouch *)touch inView:(GoBoardView *)view {}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	FuegoBoard *theBoard = [[FuegoBoard alloc] initWithSGFString:[game sgfString]];
    [theBoard goToMove: [self moveNumber]];
	[[self boardView] setBoard:theBoard];
	[self setBoard:theBoard];
	[theBoard release];
    
    if([self.board size] > 13) {
        [self zoomToScale:0.5 center:[[self boardView] center] animated:NO];        
    }
	
    [self updateBoard];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[self.boardView setBoard:nil];
	self.board = nil;
}

- (void)viewDidUnload {
	self.boardView = nil;
	self.previousButton = nil;
	self.nextButton = nil;
    [super viewDidUnload];
}


- (void)dealloc {
	self.game = nil;
    [super dealloc];
}


@end
