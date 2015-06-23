//
//  ASGalleryPage.m
//
//  Created by Andrey Syvrachev on 07.11.12. andreyalright@gmail.com
//  Copyright (c) 2012 Andrey Syvrachev. All rights reserved.
//
// This code is distributed under the terms and conditions of the MIT license.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "ASGalleryPage.h"
#import "ASImageScrollView.h"
#import "ASGalleryViewController.h"
#import <AVFoundation/AVFoundation.h>

#import "ASLoadImageQueue.h"


@interface ASGalleryPage ()<ASGalleryImageView,ASImageScrollViewDelegate>{
    ASImageScrollView* imageScrollView;
    ASGalleryImageType _currentLoadingImageType;
    
    AVPlayer *avPlayer;
    AVPlayerLayer *avPlayerLayer;
}
@end

@implementation ASGalleryPage

-(ASImageScrollView*)imageView
{
    return imageScrollView;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        imageScrollView = [[ASImageScrollView alloc] initWithFrame:frame];
        imageScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        imageScrollView.zoomDelegate = self;
        [self addSubview:imageScrollView];
    }
    return self;
}

-(void)loadImageIfNeeded
{
    _currentLoadingImageType = _imageType;
    
    if (_currentLoadingImageType == ASGalleryImageNone)
    {
        imageScrollView.image = nil;
        return;
    }
    
//    __weak ASGalleryAssetBase *weakAsset = _asset;
//    __weak ASGalleryPage *SELF = self;
    [_asset imageForType:_currentLoadingImageType
              completion:^(UIImage *image) {
                  [imageScrollView setImage:image];
              }];
}

-(void)setImage:(UIImage *)image
{
    imageScrollView.image = image;
    [self loadImageIfNeeded];
}

-(void)setImageType:(ASGalleryImageType)imageType
{
    if (_imageType != imageType){
        _imageType = imageType;
        [self loadImageIfNeeded];
//        if (_asset.isVideo && ![self isPlaying]) {
//            [self play];
//        }
    }
}

-(void)imageViewDidEndZoomingAtScale:(CGFloat)scale
{
    if (_imageType != ASGalleryImageFullResolution &&  scale > imageScrollView.minimumZoomScale)
    {
        self.imageType = ASGalleryImageFullResolution;
    }
}

-(void)prepareForReuse
{
    
    _imageType = ASGalleryImageNone;
    _currentLoadingImageType = ASGalleryImageNone;
    
    if ([self isPlaying]) {
        [avPlayer pause];
        avPlayer = nil;
    }
    
    if (avPlayerLayer != nil) {
        [avPlayerLayer removeFromSuperlayer];
    }
    
    [imageScrollView prepareForReuse];
}

-(void)updateFrame:(CGRect)frame
{
    CGPoint restorePoint = [imageScrollView pointToCenterAfterRotation];
    CGFloat restoreScale = [imageScrollView scaleToRestoreAfterRotation];
    self.frame = frame;
    [imageScrollView setMaxMinZoomScalesForCurrentBounds];
    [imageScrollView restoreCenterPoint:restorePoint scale:restoreScale];
}

-(void)resetToDefaults
{
    self.imageType = ASGalleryImageFullScreen;
    [imageScrollView resetToDefaults];
}

-(UIImage*)image
{
    return imageScrollView.image;
}

-(void)doubleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    BOOL isVideo = _asset.isVideo;
    if (isVideo)
    {
        if (imageScrollView.zoomScale > imageScrollView.minimumZoomScale)
        {
            [imageScrollView setZoomScale:imageScrollView.minimumZoomScale animated:YES];
        }else
            [imageScrollView setZoomScale:imageScrollView.maximumZoomScale animated:YES];
        
        return;
    }
    
    
    CGPoint point = isVideo ? CGPointMake(self.frame.size.width/2,self.frame.size.height/2):[gestureRecognizer locationInView:imageScrollView.imageView];
    
    float newScale;
    if (imageScrollView.zoomScale > imageScrollView.minimumZoomScale)
    {
        self.imageType = ASGalleryImageFullScreen;
        newScale = imageScrollView.minimumZoomScale;
    }else
    {
        self.imageType = ASGalleryImageFullResolution;
        newScale = imageScrollView.maximumZoomScale;
    }
    
    CGRect zoomRect = [imageScrollView zoomRectForScale:newScale withCenter:point];
    [imageScrollView zoomToRect:zoomRect animated:YES];
}


/*  video support */
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    AVPlayerItem *playerItem = [notification object];
    [playerItem seekToTime:kCMTimeZero];
    if (![self isPlaying]) {
        [avPlayer play];
    }
}

-(void)pause
{
//    if (_asset.isVideo == NO) {
//        return;
//    }
//    [avPlayer pause];
}

-(void)stop
{
    if (_asset.isVideo == NO) {
        return;
    }
    if ([self isPlaying]) {
        [avPlayer pause];
    }
    [[avPlayer currentItem] seekToTime:kCMTimeZero];
}

-(void)play
{
    if (_asset.isVideo == NO) {
        return;
    }
    
    if ([self isPlaying]) {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(playButtonPressed:)]){
        [self.delegate playButtonPressed:self];
    }
    
    if (avPlayerLayer) {
        [avPlayerLayer removeFromSuperlayer];
    }
    
    [_asset requestURL:^(NSURL *url) {
        avPlayer = [AVPlayer playerWithURL:url];
        avPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:avPlayer];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:[avPlayer currentItem]];
        
        [avPlayerLayer setFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.layer addSublayer:avPlayerLayer];
            [avPlayer play];
        });
    }];
}

-(void)setAsset:(ASGalleryAssetBase *)asset
{
    _asset = asset;
    
    imageScrollView.isVideo = _asset.isVideo;
    if (_asset.isVideo) {
        assert(_asset.isVideo);
    }
}

- (BOOL)isPlaying
{
    
    if (avPlayer != nil && avPlayer.rate > 0 && !avPlayer.error) {
        return YES;
    }
    
    return NO;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

-(void)menuBarsWillAppear
{
}

-(void)willAnimateMenuBarsAppearWithDuration:(CGFloat)duration
{
}

-(void)menuBarsDidAppear
{
}

-(void)menuBarsWillDisappear
{
}

-(void)willAnimateMenuBarsDisappearWithDuration:(CGFloat)duration
{
}

-(void)menuBarsDidDisappear
{
}

@end
