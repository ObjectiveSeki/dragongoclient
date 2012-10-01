//
//  SelectCell.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/30/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import "SelectCell.h"


@implementation SelectCell

@synthesize label;
@synthesize value;
@synthesize picker;
@synthesize options;
@synthesize selectedOptions;
@synthesize changedSelector;
@synthesize sizes;
@synthesize onChanged;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        // Initialization code
        pickerViewHeight = 0;
        tableViewHeight = 0;
        movementOffset = 0;
        picker = nil;
    }
    return self;
}

- (void)awakeFromNib {
    pickerViewHeight = 0;
    tableViewHeight = 0;
    movementOffset = 0;
    self.picker = nil;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    UITableView *tableView = (UITableView *)self.superview;
    
    if (tableView) {
        parentTableView = tableView;
    }
    
	if (selected && ![self isFirstResponder]) {
		[self becomeFirstResponder];
	} else if (selected) {
        [self resignFirstResponder];
        [parentTableView deselectRowAtIndexPath:[parentTableView indexPathForCell:self] animated:NO];
    }

}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (UIView *)inputView {
    if (!self.picker) {
        CGFloat windowHeight = parentTableView.window.frame.size.height;
        self.picker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, windowHeight, 0, 0)];
        self.picker.showsSelectionIndicator = YES;
        self.picker.dataSource = self;
        self.picker.delegate = self;
        
        for(int i = 0; i < [self.selectedOptions count]; i++) {
            int row = [[self.options objectAtIndex:i] indexOfObject:[self.selectedOptions objectAtIndex:i]];
            [self.picker selectRow:row inComponent:i animated:NO];
        }
    }
    return self.picker;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (self.onChanged) {
        self.onChanged(self);
    } else if (self.changedSelector) {
		[[UIApplication sharedApplication] sendAction:self.changedSelector to:nil from:self forEvent:nil];
	}
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	return [[self.options objectAtIndex:component] objectAtIndex:row];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
	CGFloat size;
	if (self.sizes) {
		size = [[self.sizes objectAtIndex:component] floatValue];
	} else {
		size = self.picker.frame.size.width / [self.options count];
	}
	return size;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
	return 40.0;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
	return [self.options count];
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
	return [[self.options objectAtIndex:component] count];
}

- (NSString *)selectedValueInComponent:(NSInteger)component {
	return [[self.options objectAtIndex:component] objectAtIndex:[self.picker selectedRowInComponent:component]];
}


- (void)dealloc {
	[self.picker removeFromSuperview];
}


@end
