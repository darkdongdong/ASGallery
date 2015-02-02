//
//  GalleryViewController.m
//  Photos
//
//  Created by Andrey Syvrachev on 21.05.13.
//  Copyright (c) 2013 Andrey Syvrachev. All rights reserved.
//

#import "GalleryViewController.h"
#import "ASGalleryView.h"

@interface GalleryViewController ()<ASGalleryViewDelegate, ASGalleryViewDataSource>
@property ASGalleryView *galleryView;
@end

@implementation GalleryViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    _galleryView = [[ASGalleryView alloc] initWithFrame:self.view.frame];
    [_galleryView setDataSource:self];
    [_galleryView setDelegate:self];
    _galleryView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.view addSubview:_galleryView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    if ([self respondsToSelector:@selector(setAutomaticallyAdjustsScrollViewInsets:)])
    {
        [self setAutomaticallyAdjustsScrollViewInsets:NO];
        [self setExtendedLayoutIncludesOpaqueBars:YES];
    }
    [self setWantsFullScreenLayout:YES];
    [_galleryView viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_galleryView viewWillAppear];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_galleryView viewWillDisappear];
}

-(NSUInteger)numberOfAssetsInGalleryView:(ASGalleryView *)view
{
    return [self.assets count];
}

-(id<ASGalleryAsset>)galleryView:(ASGalleryView *)view assetAtIndex:(NSUInteger)index
{
    return self.assets[index];
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [_galleryView willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [_galleryView willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)galleryViewDidChangedPage:(ASImageScrollView *)imageView
{
    NSLog(@"galleryViewDidChangedPage");
}

- (void)galleryViewDidTappedSingle:(ASImageScrollView *)imageView
{
    NSLog(@"galleryViewDidTappedSingle");
}

- (void)galleryViewDidTappedDouble:(ASImageScrollView *)imageView
{
    NSLog(@"galleryViewDidTappedDouble");
}

@end
