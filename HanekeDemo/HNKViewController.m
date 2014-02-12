//
//  HNKViewController.m
//  Haneke
//
//  Created by Hermes on 11/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HNKViewController.h"
#import "HNKCache.h"
#import "UIImageView+Haneke.h"

@interface HNKViewController ()

@end

@implementation HNKViewController {
    NSMutableArray *_items;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    [self initializeItems];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    NSString *path = _items[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%ld", (long)indexPath.row];
    cell.imageView.image = [UIImage imageNamed:@"placeholder"];
    [cell.imageView sizeToFit];
    cell.imageView.contentMode = UIViewContentModeScaleToFill;
    [cell.imageView hnk_setImageFromFile:path];
    return cell;
}

#pragma mark - Utils

- (void)initializeItems
{
    _items = [NSMutableArray array];
    NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    for (int i = 0; i < 100; i++)
    {
        NSString *fileName = [NSString stringWithFormat:@"sample%ld.jpg", (long)i];
        NSString *path = [documents stringByAppendingPathComponent:fileName];
        [_items addObject:path];
    }
}

@end
