//
//  TextCell.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/28/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import "TextCell.h"


@implementation TextCell
@synthesize label, textField, textEditedSelector, content, onChanged;


- (id)init {
    if ((self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass([self class])])) {
        [[NSBundle mainBundle] loadNibNamed:@"TextCell" owner:self options:nil];
		[self.textField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventEditingChanged];
		self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)awakeFromNib {
	[super awakeFromNib];
	[self.textField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventEditingChanged];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

	if (selected) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(keyboardWasShown:)
													 name:UIKeyboardWillShowNotification object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(keyboardWillBeHidden:)
													 name:UIKeyboardWillHideNotification object:nil];
		
		self.textField.userInteractionEnabled = YES;
		[self.textField becomeFirstResponder];
	} else {
		[[NSNotificationCenter defaultCenter] removeObserver:self 
														name:UIKeyboardWillShowNotification
													  object:nil];
											
		
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:UIKeyboardWillHideNotification
													  object:nil];
		self.textField.userInteractionEnabled = NO;
		[self.textField resignFirstResponder];
	}
}

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
	UITableView *tableView = (UITableView *)self.superview;
	
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    tableView.contentInset = contentInsets;
    tableView.scrollIndicatorInsets = contentInsets;
	
    // If this text field is hidden by keyboard, scroll it so it's visible
    CGRect aRect = tableView.frame;
    aRect.size.height -= kbSize.height;
	
	CGPoint offsetOrigin = self.frame.origin;
	offsetOrigin.y -= tableView.contentOffset.y;
	
    if (!CGRectContainsPoint(aRect, offsetOrigin) ) {
        CGPoint scrollPoint = CGPointMake(0.0, (self.frame.origin.y + self.frame.size.height) - aRect.size.height);
        [tableView setContentOffset:scrollPoint animated:YES];
    }
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
	[UIView animateWithDuration:0.3 animations:^(void) {
		UITableView *tableView = (UITableView *)self.superview;
		tableView.contentInset = contentInsets;
		tableView.scrollIndicatorInsets = contentInsets;
	}];

}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[[self textField] resignFirstResponder];
	return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	return YES;
}

- (IBAction)textFieldChanged:(id)sender {
	if (self.textEditedSelector) {
		[[UIApplication sharedApplication] sendAction:self.textEditedSelector to:nil from:self forEvent:nil];
	} else if (self.onChanged) {
		self.onChanged(self);
	}
}

- (void)dealloc {
	self.label = nil;
	self.textField = nil;
	self.content = nil;
	self.onChanged = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}


@end
