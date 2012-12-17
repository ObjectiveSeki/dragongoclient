//
// A cell with an 'on/off' switch.

#import <Foundation/Foundation.h>

@class BooleanCell;

@interface BooleanCell : UITableViewCell

@property(nonatomic, copy) void (^onChanged)(BooleanCell *booleanCell);
@property(nonatomic, strong) UISwitch *toggleSwitch;

@end
