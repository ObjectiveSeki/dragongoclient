//
//  TableCellFactory.m
//  BACEstimator
//
//  Created by Justin Weiss on 7/18/08.
//  Copyright 2008 Justin Weiss. All rights reserved.
//

#import "TableCellFactory.h"

@implementation TableCellFactory

- (TextCell *) textCell{
    [[NSBundle mainBundle] loadNibNamed:@"TableCells" owner:self options:nil];
    return textCell;
}

+ (TextCell *) textCell
{
    TableCellFactory *tcf = [[TableCellFactory alloc] init];
    TextCell *textCell = [tcf textCell];
    return textCell;
}

- (SelectCell *) selectCell{
    [[NSBundle mainBundle] loadNibNamed:@"TableCells" owner:self options:nil];
    return selectCell;
}

+ (SelectCell *) selectCell
{
    TableCellFactory *tcf = [[TableCellFactory alloc] init];
    SelectCell *selectCell = [tcf selectCell];
    return selectCell;
}




@end
