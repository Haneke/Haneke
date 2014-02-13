//
//  HNKViewController.m
//  Haneke
//
//  Created by Hermes on 11/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HNKViewController.h"
#import "UIImageView+Haneke.h"

#define HNK_USE_CUSTOM_FORMAT 1

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
    if (HNK_USE_CUSTOM_FORMAT)
    {
        cell.imageView.hnk_cacheFormat = [HNKCache sharedCache].formats[@"thumbnail"];
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
    _items = [NSArray array];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSMutableArray *items = [NSMutableArray array];
        for (NSUInteger i = 0; i < 100; i++)
        {
            @autoreleasepool {
                NSLog(@"Creating image %ld of %d", (long)i + 1, 100);
                UIImage *image = [self imageWithIndex:i];
                NSData *data = UIImageJPEGRepresentation(image, 1);
                NSString *fileName = [NSString stringWithFormat:@"sample%ld.jpg", (long)i];
                NSString *path = [documents stringByAppendingPathComponent:fileName];
                [data writeToFile:path atomically:YES];
                [items addObject:path];
            }
        }
        dispatch_sync(dispatch_get_main_queue(), ^{
            _items = items;
            [self.tableView reloadData];
        });
    });
}

- (UIImage*)imageWithIndex:(NSUInteger)index
{
    // Photo by Paul Sableman, taken from http://www.flickr.com/photos/pasa/8636568094
    UIImage *sample = [UIImage imageNamed:@"sample.jpg"];
    NSString *indexString = [NSString stringWithFormat:@"%ld", (long)index];
    return [self drawText:indexString inImage:sample];
}

- (UIImage*)drawText:(NSString*)text inImage:(UIImage*)image
{
    UIFont *font = [UIFont boldSystemFontOfSize:image.size.height / 2];
    UIGraphicsBeginImageContext(image.size);
    [image drawInRect:CGRectMake(0,0,image.size.width,image.size.height)];
    NSDictionary *attributes = @{NSFontAttributeName : font, NSForegroundColorAttributeName : [UIColor whiteColor]};
    CGSize textSize = [text sizeWithAttributes:attributes];
    CGRect rect = CGRectMake((image.size.width - textSize.width) / 2, (image.size.height - textSize.height) / 2, textSize.width, textSize.height);
    [text drawInRect:rect withAttributes:attributes];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
