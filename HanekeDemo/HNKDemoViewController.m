//
//  HNKDemoViewController.m
//  Haneke
//
//  Created by Hermes on 11/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HNKDemoViewController.h"
#import "UIImageView+Haneke.h"
#import "HNKDemoCollectionViewCell.h"
#import "UIImage+HanekeDemo.h" // To create random images

#define HNK_USE_CUSTOM_FORMAT 0

@implementation HNKDemoViewController {
    NSArray *_items;
}

+ (void)initialize
{
    HNKCacheFormat *format = [[HNKCacheFormat alloc] initWithName:@"thumbnail"];
    
    format.compressionQuality = 0.5;
    // UIImageView category default: 0.75, -[HNKCacheFormat initWithName:] default: 1.
    
    format.allowUpscaling = YES;
    // UIImageView category default: YES, -[HNKCacheFormat initWithName:] default: NO.
    
    format.diskCapacity = 0.5 * 1024 * 1024;
    // UIImageView category default: 10 * 1024 * 1024 (10MB), -[HNKCacheFormat initWithName:] default: 0 (no disk cache).
    
    format.preloadPolicy = HNKPreloadPolicyLastSession;
    // Default: HNKPreloadPolicyNone.
    
    format.scaleMode = HNKScaleModeAspectFill;
    // UIImageView category default: -[UIImageView contentMode], -[HNKCacheFormat initWithName:] default: HNKScaleModeFill.
    
    format.size = CGSizeMake(100, 100);
    // // UIImageView category default: -[UIImageView bounds].size, -[HNKCacheFormat initWithName:] default: CGSizeZero.
    
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

+ (HNKDemoViewController*)viewController
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(100, 100);
    HNKDemoViewController *viewController = [[HNKDemoViewController alloc] initWithCollectionViewLayout:layout];
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
    static NSUInteger ImageCount = 100;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSMutableArray *items = [NSMutableArray array];
        for (NSUInteger i = 0; i < ImageCount; i++)
        {
            @autoreleasepool {
                NSString *fileName = [NSString stringWithFormat:@"sample%ld.jpg", (long)i];
                NSString *path = [documents stringByAppendingPathComponent:fileName];
                
                if (![[NSFileManager defaultManager] fileExistsAtPath:path])
                {
                    NSLog(@"Creating image %ld of %d", (long)i + 1, ImageCount);
                    UIImage *image = [UIImage demo_randomImageWithIndex:i];
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


@end
