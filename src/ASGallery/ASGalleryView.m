//
//  ASGalleryView.m
//  Photos
//
//  Created by Sam Yang on 2/2/15.
//  Copyright (c) 2015 Andrey Syvrachev. All rights reserved.
//

#import "ASGalleryView.h"
#import "ASGalleryPage.h"

#define PADDING  20
#define SHOW_HIDE_ANIMATION_TIME 0.35

//NS_INLINE NSUInteger iOSVersion() {
//    NSUInteger version = 6;
//    NSArray *components = [[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."];
//    if ( [components count] ) {
//        version = [components[0] intValue];
//    }
//    return version;
//}

@interface ASGalleryView ()<UIScrollViewDelegate,UIGestureRecognizerDelegate,ASGalleryPageDelegate>{
    UIScrollView    *pagingScrollView;
    NSMutableSet    *recycledPages;
    
    NSUInteger      firstVisiblePageIndexBeforeRotation;
    CGFloat         percentScrolledIntoFirstVisiblePage;
    
    NSUInteger  indexForResetZoom;
    BOOL    processingRotationNow;
    BOOL    hideControls;
    
    UITapGestureRecognizer* gestureSingleTap;
    UITapGestureRecognizer* gestureDoubleTap;
    
    BOOL    callDidChangedFirstly;
    BOOL    viewVisibleNow;
}

@property (nonatomic, weak) ASGalleryPage *currentPlayingVideoPage;

@end

@implementation ASGalleryView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        //        [self initViews];
    }
    return self;
}

- (void)viewDidLoad
{
    // Step 1: make the outer paging scroll view
    CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    
    pagingScrollView = [[UIScrollView alloc] initWithFrame:pagingScrollViewFrame];
    pagingScrollView.pagingEnabled = YES;
    pagingScrollView.showsVerticalScrollIndicator = NO;
    pagingScrollView.showsHorizontalScrollIndicator = NO;
    pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
    pagingScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    pagingScrollView.delegate = self;
    
    self.backgroundColor = [UIColor blackColor];
    [self addSubview:pagingScrollView];
    
    // Step 2: prepare to tile content
    recycledPages = [[NSMutableSet alloc] init];
    _visiblePages  = [[NSMutableSet alloc] init];
    
    _fullScreenImagesToPreload = 1;
    _previewImagesToPreload = 0;
    
    gestureDoubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    gestureDoubleTap.delegate = self;
    gestureDoubleTap.numberOfTapsRequired = 2;
    [self addGestureRecognizer:gestureDoubleTap];
    
    gestureSingleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
    gestureSingleTap.delegate = self;
    [gestureSingleTap requireGestureRecognizerToFail:gestureDoubleTap];
    [self addGestureRecognizer:gestureSingleTap];
    
}

-(void)scrollToIndex:(NSUInteger)index animated:(BOOL)animated
{
    [self scrollToIndex:index autoPlay:NO animated:animated];
}

-(void)scrollToIndex:(NSUInteger)index autoPlay:(BOOL)autoPlay animated:(BOOL)animated
{
    pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
    
    CGFloat pageWidth = pagingScrollView.frame.size.width;
    CGFloat newOffset = index * pageWidth;
    [pagingScrollView setContentOffset:CGPointMake(newOffset, 0) animated:animated];
    
    if (autoPlay) {
        [[self visiblePageForIndex:self.selectedIndex] play];
    }
    
    [self tilePagesWithMaxImageType:ASGalleryImageFullScreen reload:YES];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        return UIInterfaceOrientationMaskAllButUpsideDown;
    
    return UIInterfaceOrientationMaskAll;
}

-(Class)galleryPageClass
{
    if (_galleryPageClass == nil)
        _galleryPageClass = [ASGalleryPage class];
    return _galleryPageClass;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:[UIControl class]] || [touch.view isKindOfClass:[UINavigationBar class]]) {
        // we touched a button, slider, or other UIControl
        return NO; // ignore the touch
    }
    return YES; // handle the touch
}

- (CGRect)frameForPagingScrollView {
    //    CGRect frame = [[UIScreen mainScreen] bounds];
    CGRect frame = [self bounds];
    
    //    if (iOSVersion() < 8 && UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
    //        frame.size = CGSizeMake(frame.size.height,frame.size.width);
    frame.origin.x -= PADDING;
    frame.size.width += (2 * PADDING);
    return frame;
}

- (CGRect)frameForPageAtIndex:(NSUInteger)index {
    // We have to use our paging scroll view's bounds, not frame, to calculate the page placement. When the device is in
    // landscape orientation, the frame will still be in portrait because the pagingScrollView is the root view controller's
    // view, so its frame is in window coordinate space, which is never rotated. Its bounds, however, will be in landscape
    // because it has a rotation transform applied.
    [self layoutSubviews];
    CGRect bounds = pagingScrollView.bounds;
    CGRect pageFrame = bounds;
    pageFrame.size.width -= (2 * PADDING);
    pageFrame.origin.x = (bounds.size.width * index) + PADDING;
    return pageFrame;
}

- (CGSize)contentSizeForPagingScrollView {
    // We have to use the paging scroll view's bounds to calculate the contentSize, for the same reason outlined above.
    CGRect bounds = pagingScrollView.bounds;
    return CGSizeMake(bounds.size.width * [self.dataSource numberOfAssetsInGalleryView:self],
                      bounds.size.height);
}

- (void)clear
{
    [recycledPages removeAllObjects];
    [_visiblePages removeAllObjects];
    
    _fullScreenImagesToPreload = 1;
    _previewImagesToPreload = 0;
}

- (void)dealloc
{
    [self removeGestureRecognizer:gestureDoubleTap];
    [self removeGestureRecognizer:gestureSingleTap];
    
    pagingScrollView = nil;
    recycledPages = nil;
    _visiblePages = nil;
}

-(void)viewWillAppear
{
    callDidChangedFirstly = YES;
    
    CGFloat pageWidth = pagingScrollView.frame.size.width;
    CGFloat newOffset = self.selectedIndex * pageWidth;
    pagingScrollView.contentOffset = CGPointMake(newOffset, 0);
    [self tilePagesWithMaxImageType:ASGalleryImageFullScreen reload:NO];
    
    viewVisibleNow = YES;
}

-(void)viewWillDisappear
{
    viewVisibleNow = NO;
    [self stopVideo];
}

- (ASGalleryPage *)dequeueRecycledPage
{
    ASGalleryPage *page = [recycledPages anyObject];
    if (page) {
        [recycledPages removeObject:page];
    }
    return page;
}

- (ASGalleryPage*)visiblePageForIndex:(NSUInteger)index
{
    ASGalleryPage* foundPage = nil;
    for (ASGalleryPage *page in _visiblePages) {
        if (page.tag == index) {
            foundPage = page;
            break;
        }
    }
    return foundPage;
}

-(ASGalleryPage*)createGalleryPage
{
    return [[self.galleryPageClass alloc] init];
}

-(void)preloadPageWithIndex:(NSInteger)index imageType:(ASGalleryImageType)imageType reload:(BOOL)reload
{
    assert(index >=0);
    ASGalleryPage *page = [self visiblePageForIndex:index];
    if (!page) {
        
        page = [self dequeueRecycledPage];
        if (page == nil) {
            page = [self createGalleryPage];
            page.delegate = self;
        }
        
        page.tag = index;
        page.frame = [self frameForPageAtIndex:index];
        
        [pagingScrollView addSubview:page];
        [_visiblePages addObject:page];
        
        reload = YES; // initally load page
    }
    
    if (reload) {
        [page prepareForReuse];
        page.asset = [self.dataSource galleryView:self assetAtIndex:index];
    }
    
    page.imageType = imageType;
}

-(void)stopVideo
{
    [self.currentPlayingVideoPage stop];
}

-(void)reloadData
{
    pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
    [self tilePagesWithMaxImageType:ASGalleryImageFullScreen reload:YES];
}

-(UIImage *)selectedImage
{
    return [self currentImageView].image;
}

// maxImageType - needed to prevent loading FullScreen images while scrolling, because this is cause jittering
- (void)tilePagesWithMaxImageType:(ASGalleryImageType)maxImageType reload:(BOOL)reload
{
    // Calculate which pages are visible
    if (processingRotationNow)
        return;
    
    
    NSUInteger numberOfAssets = [self.dataSource numberOfAssetsInGalleryView:self];
    
    CGRect visibleBounds = pagingScrollView.bounds;
    
    int firstVisiblePageIndex = floorf(CGRectGetMinX(visibleBounds) / CGRectGetWidth(visibleBounds));
    if (firstVisiblePageIndex < 0)
        firstVisiblePageIndex = 0;
    int lastVisiblePageIndex  = floorf((CGRectGetMaxX(visibleBounds)-1) / CGRectGetWidth(visibleBounds));
    if (lastVisiblePageIndex >= numberOfAssets)
        lastVisiblePageIndex = (int)numberOfAssets - 1;
    
    if (firstVisiblePageIndex == lastVisiblePageIndex)
    {
        if (self.selectedIndex != firstVisiblePageIndex || callDidChangedFirstly){
            self.selectedIndex = firstVisiblePageIndex;
            callDidChangedFirstly = NO;
            
            [[self visiblePageForIndex:self.selectedIndex] play];
            
            if ([self.delegate respondsToSelector:@selector(galleryViewDidChangedPage:)])
                [self.delegate galleryViewDidChangedPage:[self currentImageView]];
        }
    }
    
    int firstNeededPageIndex = firstVisiblePageIndex - (int)(self.previewImagesToPreload+2); //  with +2 gisteresis to prevent REMOVE/ADD on tilePages noice!
    if (firstNeededPageIndex < 0)
        firstNeededPageIndex = 0;
    
    int lastNeededPageIndex  = lastVisiblePageIndex + (int)(self.previewImagesToPreload+2); // with +2 gisteresis to prevent REMOVE/ADD on tilePages noice!
    if (lastNeededPageIndex >= numberOfAssets)
        lastNeededPageIndex = (int)numberOfAssets - 1;
    
    // Recycle no-longer-visible pages
    for (ASGalleryPage *page in _visiblePages) {
        if (page.tag < firstNeededPageIndex || page.tag > lastNeededPageIndex) {
            [recycledPages addObject:page];
            [page removeFromSuperview];
        }
    }
    [_visiblePages minusSet:recycledPages];
    
    for (int index = firstVisiblePageIndex; index <= lastVisiblePageIndex; index++)
        [self preloadPageWithIndex:index imageType:maxImageType reload:reload];
    
    for (int step = 1; step <= self.previewImagesToPreload; step++) {
        
        ASGalleryImageType imageType = step > self.fullScreenImagesToPreload ? ASGalleryImagePreview: maxImageType;
        int loIndex = firstVisiblePageIndex - step;
        if (loIndex >= 0)
            [self preloadPageWithIndex:loIndex imageType:imageType reload:reload];
        
        int hiIndex = lastVisiblePageIndex + step;
        if (hiIndex < numberOfAssets)
            [self preloadPageWithIndex:hiIndex imageType:imageType reload:reload];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self tilePagesWithMaxImageType:ASGalleryImageFullScreen reload:NO];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(galleryViewWillBeginDragging:)]) {
        [self.delegate galleryViewWillBeginDragging:scrollView];
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    processingRotationNow = YES; // oto prevent incorrect scrolling in tilePages!
    
    // here, our pagingScrollView bounds have not yet been updated for the new interface orientation. So this is a good
    // place to calculate the content offset that we will need in the new orientation
    CGFloat offset = pagingScrollView.contentOffset.x;
    CGFloat pageWidth = pagingScrollView.bounds.size.width;
    
    if (offset >= 0) {
        firstVisiblePageIndexBeforeRotation = floorf(offset / pageWidth);
        percentScrolledIntoFirstVisiblePage = (offset - (firstVisiblePageIndexBeforeRotation * pageWidth)) / pageWidth;
    } else {
        firstVisiblePageIndexBeforeRotation = 0;
        percentScrolledIntoFirstVisiblePage = offset / pageWidth;
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // recalculate contentSize based on current orientation
    pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
    
    // adjust frames and configuration of each visible page
    // adjust contentOffset to preserve page location based on values collected prior to location
    CGFloat pageWidth = pagingScrollView.bounds.size.width;
    CGFloat newOffset = (firstVisiblePageIndexBeforeRotation * pageWidth) + (percentScrolledIntoFirstVisiblePage * pageWidth);
    
    pagingScrollView.contentOffset = CGPointMake(newOffset, 0);
    
    for (ASGalleryPage *page in _visiblePages) {
        //        ILog(@"page = %@",page);
        [page updateFrame:[self frameForPageAtIndex:page.tag]];
    }
    
    processingRotationNow = NO;
    
    [self tilePagesWithMaxImageType:ASGalleryImageFullScreen reload:NO];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    indexForResetZoom = self.selectedIndex;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;      // called when scroll view grinds to a halt
{
    if (indexForResetZoom != self.selectedIndex)
    {
        ASGalleryPage* page = [self visiblePageForIndex:indexForResetZoom];
        [page resetToDefaults];
    }
    [self tilePagesWithMaxImageType:ASGalleryImageFullScreen reload:NO];
}

-(void)doubleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    ASGalleryPage* isv = [self visiblePageForIndex:self.selectedIndex];
    [isv doubleTap:gestureRecognizer];
    
    if ([self.delegate respondsToSelector:@selector(galleryViewDidTappedDouble:)])
        [self.delegate galleryViewDidTappedDouble:[self currentImageView]];
}

-(ASImageScrollView*)currentImageView
{
    return [self visiblePageForIndex:self.selectedIndex].imageView;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    ASGalleryPage* isv = [self visiblePageForIndex:self.selectedIndex];
    [isv pause];
}

-(void)singleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    if ([self.delegate respondsToSelector:@selector(galleryViewDidTappedSingle:)])
        [self.delegate galleryViewDidTappedSingle:[self currentImageView]];
}

@end
