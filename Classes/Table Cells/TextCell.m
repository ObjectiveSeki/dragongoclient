//
//  TextCell.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/28/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import "TextCell.h"


@implementation TextCell
@synthesize label, textField, textEditedSelector;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        // Initialization code
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
		self.textField.userInteractionEnabled = YES;
		[self.textField becomeFirstResponder];
	} else {
		self.textField.userInteractionEnabled = NO;
		[self.textField resignFirstResponder];
	}
	
    // Configure the view for the selected state
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
	}
}

- (void)dealloc {
	self.label = nil;
	self.textField = nil;
    [super dealloc];
}


@end
