//
//  AcknowledgementsViewController.h
//  DGSPhone
//
//  Created by Justin Weiss on 7/18/13.
//  Copyright (c) 2013 Justin Weiss. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AcknowledgementsViewController : UIViewController <UIWebViewDelegate>

@property (strong, nonatomic) IBOutlet UIWebView *webView;

- (IBAction)dismiss:(id)sender;

@end
