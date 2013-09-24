//
//  SpinnerView.m
//  DGSPhone
//
//  Created by Justin Weiss on 7/23/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import "SpinnerView.h"
#import <QuartzCore/QuartzCore.h>

@implementation SpinnerView

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
		[self setBackgroundColor:[UIColor clearColor]];
		[self setOpaque:NO];
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectZero];
		self.spinner = activityIndicator;
		self.spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
		[self.spinner startAnimating];
		
		UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.label = textLabel;
        
		self.label.text = @"Loading...";
		self.label.textAlignment = NSTextAlignmentCenter;
		self.label.textColor = [UIColor lightTextColor];
		self.label.font = [UIFont boldSystemFontOfSize:14.0];
		self.label.backgroundColor = [UIColor clearColor];
		self.label.opaque = NO;
        self.alpha = 0.0;

		[self addSubview:self.spinner];
		[self addSubview:self.label];
	}
    return self;
}

- (id)initInView:(UIView *)view {
    SpinnerView *spinnerView = [self initWithFrame:CGRectZero];
    [view addSubview:spinnerView];
    return spinnerView;
}

+ (SpinnerView *)showInView:(UIView *)view {
    SpinnerView *spinnerView = [[self alloc] initInView:view];
    [spinnerView show];
    return spinnerView;
}

- (void)show {
	self.transform = CGAffineTransformMakeScale(2,2);
	[self setNeedsLayout];
    self.superview.userInteractionEnabled = NO;
	[UIView animateWithDuration:0.3 delay:0.3 options:0 animations:^(void) {
		self.transform = CGAffineTransformMakeScale(1, 1);
		self.alpha = 1.0;
	} completion:^(BOOL completion) {
    }];
}

- (void)dismiss:(BOOL)animate {
	if (animate) {
		[UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionLayoutSubviews | UIViewAnimationOptionBeginFromCurrentState animations:^(void) {
			self.transform = CGAffineTransformMakeScale(2, 2);
			self.alpha = 0.0;
		} completion:^(BOOL completion) {
            if (completion) {
                self.superview.userInteractionEnabled = YES;
            }
		}];
	} else {
		self.alpha = 0.0;
	}
}

- (void)layoutSubviews {
    UIView *view = self.superview;
    
    self.frame = [view convertRect:CGRectMake(view.window.center.x - 60, view.window.center.y - 60, 120, 120) fromView:nil];
    
	int spinnerSize = 37;
	self.spinner.frame = CGRectMake((self.frame.size.width - spinnerSize) / 2, self.frame.size.height / 3.0, spinnerSize, spinnerSize);
	
	self.label.frame = CGRectMake(8, self.frame.size.height - 8 - 16, self.frame.size.width - 16, 16);
    self.layer.cornerRadius = 10;
    self.layer.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8].CGColor;
}

@end

