//
//  HNKViewController.m
//  Haneke
//
//  Created by Hermes on 11/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HNKViewController.h"
#import "UIImageView+Haneke.h"

#define HNK_USE_CUSTOM_FORMAT 0

@implementation HNKViewController {
    NSMutableArray *_items;
    HNKCacheFormat *_customFormat;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    [self initializeItems];
    _customFormat = [[HNKCacheFormat alloc] initWithName:@"thumbnail"];
    _customFormat.diskCapacity = 1 * 1024 * 1024;
    _customFormat.compressionQuality = 0.5;
    _customFormat.size = CGSizeMake(100, 100);
    _customFormat.scaleMode = HNKScaleModeAspectFill;
    _customFormat.preloadPolicy = HNKPreloadPolicyLastSession;
    [[HNKCache sharedCache] registerFormat:_customFormat];
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
    if (HNK_USE_CUSTOM_FORMAT)
    {
        cell.imageView.hnk_cacheFormat = _customFormat;
    }
    else
    { // Resize image based on the `bounds` and `contentMode` of the `UIImageView`, using a default configuration
        cell.imageView.contentMode = UIViewContentModeScaleToFill;
        [cell.imageView sizeToFit];
    }
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
