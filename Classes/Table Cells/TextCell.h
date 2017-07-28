//
//  TextCell.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/28/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TextCell;

@interface TextCell : UITableViewCell <UITextFieldDelegate>

@property(nonatomic, strong) IBOutlet UITextField *textField;
@property(nonatomic, copy) void (^onChanged)(TextCell *textCell);

// max length of the text this cell contains. -1 means no maximum.
@property(nonatomic, assign) int maxTextLength;

@end
