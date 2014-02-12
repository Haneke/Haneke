//
//  HNKViewController.m
//  Haneke
//
//  Created by Hermes on 11/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HNKViewController.h"
#import "HNKCache.h"
#import "HNKItem.h"

@interface HNKViewController ()

@end

@implementation HNKViewController {
    NSMutableArray *_items;
}

+ (void)initialize
{
    HNKCacheFormat *format = [[HNKCacheFormat alloc] initWithName:@"thumbnail"];
    format.allowUpscaling = NO;
    format.compressionQuality = 0.5;
    format.size = CGSizeMake(100, 100);
    format.diskCapacity = 1 * 1024 * 1024; // 1MB
    format.scaleMode = HNKScaleModeAspectFill;
    [[HNKCache sharedCache] registerFormat:format];
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
    HNKItem *item = _items[indexPath.row];
    cell.textLabel.text = item.cacheId;
    cell.imageView.image = [UIImage imageNamed:@"placeholder"];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
    [[HNKCache sharedCache] retrieveImageForEntity:item formatName:@"thumbnail" completionBlock:^(id<HNKCacheEntity> entity, NSString *formatName, UIImage *image) {
        NSString *currentId = cell.textLabel.text;
        if (![currentId isEqualToString:entity.cacheId]) return; // Reused
        
        [UIView transitionWithView:cell.imageView duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            cell.imageView.image = image;
        } completion:nil];
    }];
    return cell;
}

#pragma mark - Utils

- (void)initializeItems
{
    _items = [NSMutableArray array];
    for (int i = 0; i < 100; i++)
    {
        HNKItem *item = [HNKItem itemWithIndex:i];
        [_items addObject:item];
    }
}

@end
