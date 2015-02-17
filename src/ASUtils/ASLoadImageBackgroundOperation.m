//
//  TGLoadImageOperation.m
//
//  Created by Andrey Syvrachev on 29.10.12. andreyalright@gmail.com
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

#import "ASLoadImageBackgroundOperation.h"

@implementation ASLoadImageBackgroundOperation

-(void)main
{
    if ([self isCancelled])
        return;

    if (_asset != nil) {
        __weak ASGalleryAssetBase *weakAsset = _asset;
        [_asset imageForType:_imageType completion:^(UIImage *image) {
            if (image) {
                [weakAsset setImageCache:image forType:_imageType];
            }
            __weak __typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong __typeof(self) strongSelf = weakSelf;
                if (strongSelf) {
                    if ([strongSelf isCancelled])
                        return;
                    
                    if (strongSelf.imageSetBlock)
                        strongSelf.imageSetBlock(image);
                }
            });
        }];
    }

}

@end
