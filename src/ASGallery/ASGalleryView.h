//
//  ASGalleryView.h
//  Photos
//
//  Created by Sam Yang on 2/2/15.
//  Copyright (c) 2015 Andrey Syvrachev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASImageScrollView.h"
#import "ASGalleryAssetBase.h"

@class ASGalleryView;
@protocol ASGalleryViewDataSource <NSObject>

- (NSUInteger) numberOfAssetsInGalleryView:(ASGalleryView*)view;
- (ASGalleryAssetBase *) galleryView:(ASGalleryView*)view assetAtIndex:(NSUInteger)index;

@end

@protocol ASGalleryViewDelegate <NSObject>

@optional

- (void) galleryViewDidChangedPage:(ASImageScrollView*)imageView;
- (void) galleryViewDidTappedSingle:(ASImageScrollView*)imageView;
- (void) galleryViewDidTappedDouble:(ASImageScrollView*)imageView;

@end

@class ASGalleryPage;
@interface ASGalleryView : UIView

@property(nonatomic,unsafe_unretained) id<ASGalleryViewDataSource> dataSource;
@property(nonatomic,unsafe_unretained) id<ASGalleryViewDelegate> delegate;

@property (nonatomic,strong)     NSMutableSet    *visiblePages;


@property(nonatomic) NSUInteger selectedIndex;

@property(nonatomic,assign) NSUInteger fullScreenImagesToPreload;   // +- 1 by default
@property(nonatomic,assign) NSUInteger previewImagesToPreload;      // +- 5 by default

@property(nonatomic,strong) Class galleryPageClass;  // by default ASGalleryPage (you can have ASGalleryPage as parent class!)

@property(nonatomic,strong) ASImageScrollView* currentImageView;

-(void)clear;
-(void)stopVideo;
-(void)reloadData;

-(void)scrollToIndex:(NSUInteger)index autoPlay:(BOOL)autoPlay animated:(BOOL)animated;
-(void)scrollToIndex:(NSUInteger)index animated:(BOOL)animated;

- (ASGalleryPage*) visiblePageForIndex:(NSUInteger)index;

// can be ovveride, for create and preinit ASGalleryPage subclass. also you can use galleryPageClass only or together with this method
- (ASGalleryPage*) createGalleryPage;

- (void) viewDidLoad;
- (void) viewWillAppear;
- (void) viewWillDisappear;
- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;
- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;
@end
