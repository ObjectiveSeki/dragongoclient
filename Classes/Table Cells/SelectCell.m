//
//  SelectCell.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/30/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import "SelectCell.h"

@interface SelectCell ()

@property (nonatomic, weak) UITableView *parentTableView;

@end

@implementation SelectCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        // Initialization code
        _picker = nil;
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.picker = nil;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    UITableView *tableView = (UITableView *)self.superview;
    
    if (tableView) {
        self.parentTableView = tableView;
    }
    
	if (selected && ![self isFirstResponder]) {
		[self becomeFirstResponder];
	} else if (selected) {
        [self resignFirstResponder];
        [self.parentTableView deselectRowAtIndexPath:[self.parentTableView indexPathForCell:self] animated:NO];
    }
}

- (void)setOptions:(NSArray *)options {
    if (_options != options) {
        _options = options;
        [self.picker reloadAllComponents];
    }
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (UIView *)inputView {
    if (!self.picker) {
        CGFloat windowHeight = self.parentTableView.window.frame.size.height;
        self.picker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, windowHeight, 0, 0)];
        self.picker.showsSelectionIndicator = YES;
        self.picker.dataSource = self;
        self.picker.delegate = self;
        
        for(int i = 0; i < [self.selectedOptions count]; i++) {
            NSUInteger row = [(self.options)[i] indexOfObject:(self.selectedOptions)[i]];
            [self.picker selectRow:row inComponent:i animated:NO];
        }
    }
    return self.picker;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (self.onChanged) {
        self.onChanged(self);
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	return (self.options)[component][row];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
	CGFloat size;
	if (self.sizes) {
		size = [(self.sizes)[component] floatValue];
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
	return [(self.options)[component] count];
}

- (NSString *)selectedValueInComponent:(NSInteger)component {
	return (self.options)[component][[self.picker selectedRowInComponent:component]];
}

- (void)dealloc {
	[self.picker removeFromSuperview];
}


@end
