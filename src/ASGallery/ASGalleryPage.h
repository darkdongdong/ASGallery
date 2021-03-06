//
//  ASGalleryPage.h
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

#import "ASGalleryViewController.h"
#import "ASGalleryAssetBase.h"

@class ASGalleryPage;
@protocol ASGalleryPageDelegate <NSObject>

@optional
-(void)playButtonPressed:(ASGalleryPage *)page;
-(void)playbackFinished:(ASGalleryPage *)page;

@end


@interface ASGalleryPage : UIView

@property(nonatomic, weak) id<ASGalleryPageDelegate> delegate;
@property(nonatomic,strong) ASGalleryAssetBase *asset;
@property(nonatomic,assign) ASGalleryImageType imageType;

@property(nonatomic,weak,readonly) ASImageScrollView* imageView;

-(void)play;
-(void)pause;
-(void)stop;
-(BOOL)isPlaying;
-(void)prepareForReuse;
-(void)updateFrame:(CGRect)frame;
-(void)resetToDefaults;

-(void)doubleTap:(UITapGestureRecognizer *)gestureRecognizer;

-(void)menuBarsWillAppear;
-(void)willAnimateMenuBarsAppearWithDuration:(CGFloat)duration;
-(void)menuBarsDidAppear;

-(void)menuBarsWillDisappear;
-(void)willAnimateMenuBarsDisappearWithDuration:(CGFloat)duration;
-(void)menuBarsDidDisappear;

@end
