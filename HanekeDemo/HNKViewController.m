//
//  HNKViewController.m
//  Haneke
//
//  Created by Hermes on 11/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HNKViewController.h"
#import "UIImageView+Haneke.h"
#import "HNKDemoCollectionViewCell.h"
#import "UIImage+HanekeDemo.h" // To create random images

#define HNK_USE_CUSTOM_FORMAT 0

@implementation HNKViewController {
    NSArray *_items;
}

+ (void)initialize
{
    HNKCacheFormat *format = [[HNKCacheFormat alloc] initWithName:@"thumbnail"];
    format.diskCapacity = 0.1 * 1024 * 1024;
    format.compressionQuality = 0.5;
    format.size = CGSizeMake(100, 100);
    format.scaleMode = HNKScaleModeAspectFill;
    format.preloadPolicy = HNKPreloadPolicyLastSession;
    [[HNKCache sharedCache] registerFormat:format];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    [self.collectionView registerClass:[HNKDemoCollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
    [self initializeItems];
}

#pragma mark - Public

+ (HNKViewController*)viewController
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(100, 100);
    HNKViewController *viewController = [[HNKViewController alloc] initWithCollectionViewLayout:layout];
    return viewController;
}

#pragma mark - UICollectionViewDatasource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    return _items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    HNKDemoCollectionViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    NSString *path = _items[indexPath.row];
    if (HNK_USE_CUSTOM_FORMAT)
    {
        cell.imageView.hnk_cacheFormat = [HNKCache sharedCache].formats[@"thumbnail"];
    }
    [cell.imageView hnk_setImageFromFile:path];
    return cell;
}

#pragma mark - Utils

- (void)initializeItems
{
    _items = [NSArray array];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSMutableArray *items = [NSMutableArray array];
        for (NSUInteger i = 0; i < 100; i++)
        {
            @autoreleasepool {
                NSString *fileName = [NSString stringWithFormat:@"sample%ld.jpg", (long)i];
                NSString *path = [documents stringByAppendingPathComponent:fileName];
                
                if (![[NSFileManager defaultManager] fileExistsAtPath:path])
                {
                    NSLog(@"Creating image %ld of %d", (long)i + 1, 100);
                    UIImage *image = [self imageWithIndex:i];
                    NSData *data = UIImageJPEGRepresentation(image, 1);
                    [data writeToFile:path atomically:YES];
                }
                [items addObject:path];
            }
        }
        dispatch_sync(dispatch_get_main_queue(), ^{
            _items = items;
            [self.collectionView reloadData];
        });
    });
}

- (UIImage*)imageWithIndex:(NSUInteger)index
{
    // Photo by Paul Sableman, taken from http://www.flickr.com/photos/pasa/8636568094
    UIImage *sample = [UIImage imageNamed:@"sample.jpg"];
    NSString *indexString = [NSString stringWithFormat:@"%ld", (long)index + 1];

    CGFloat width = arc4random_uniform(sample.size.width - 100) + 1 + 100;
    CGFloat height = arc4random_uniform(sample.size.height - 100) + 1 + 100;
    CGFloat x = arc4random_uniform(sample.size.width - width + 1);
    CGFloat y = arc4random_uniform(sample.size.height - height + 1);
    CGRect cropRect = CGRectMake(x, y, width, height);
    UIImage *cropped = [sample imageByCroppingRect:cropRect];
    return [cropped imageByDrawingText:indexString];
}


@end
