//
//  ALAssetAdapter.m
//
//
//  Created by Andrey Syvrachev on 21.05.13. andreyalright@gmail.com
//  Copyright (c) 2013 Andrey Syvrachev. All rights reserved.
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

#import "ALAssetAdapter.h"


@interface ALAssetAdapter (){
    NSString* type;
    NSURL* _url;
    CGSize _dimensions;
    NSNumber* _duration;
}

@end


@implementation ALAssetAdapter

-(void)setAsset:(ALAsset *)asset
{
    _asset = asset;
    [self url];
}

-(CGFloat)duration
{
    if (_duration == nil){
        _duration = [self.asset valueForProperty:ALAssetPropertyDuration];
    }
    return [_duration floatValue];
}

-(BOOL)isVideo
{
    if (type == nil)
        type = [self.asset valueForProperty:ALAssetPropertyType];
    return type == ALAssetTypeVideo;
}

-(NSURL*)url
{
    if (_url == nil)
        _url = [[_asset defaultRepresentation] url];
    return _url;
}

-(CGSize)dimensions
{
    if (CGSizeEqualToSize(_dimensions, CGSizeZero))
        _dimensions = [[_asset defaultRepresentation] dimensions];
    return _dimensions;
}

-(BOOL)isImageForTypeAvailable:(ASGalleryImageType)imageType
{
    if ([self.asset respondsToSelector:@selector(aspectRatioThumbnail)])
        return YES;
    return imageType != ASGalleryImagePreview;
}

-(void)imageForType:(ASGalleryImageType)imageType completion:(void(^)(UIImage*))completion
{
    switch (imageType) {
        case ASGalleryImageThumbnail:
            completion([UIImage imageWithCGImage:[self.asset thumbnail]]);
            return;
            
        case ASGalleryImagePreview:
            completion([UIImage imageWithCGImage:[self.asset aspectRatioThumbnail]]);
            return;
            
        case ASGalleryImageFullScreen:
            completion([UIImage imageWithCGImage:[[self.asset defaultRepresentation] fullScreenImage]]);
            return;
            
        case ASGalleryImageFullResolution:
        {
            ALAssetRepresentation* defaultRepresentation = [self.asset defaultRepresentation];
            CGImageRef fullResolutionImage = [defaultRepresentation fullResolutionImage];
            NSString *adjustmentXMP = [[defaultRepresentation metadata] objectForKey:@"AdjustmentXMP"];
            if (adjustmentXMP && [CIFilter respondsToSelector:@selector(filterArrayFromSerializedXMP:inputImageExtent:error:)]) {
                CIImage *image = [CIImage imageWithCGImage:fullResolutionImage];
                NSError *error = nil;
                NSArray *filterArray = [CIFilter filterArrayFromSerializedXMP:[adjustmentXMP dataUsingEncoding:NSUTF8StringEncoding]
                                                             inputImageExtent:image.extent
                                                                        error:&error];
                if (filterArray && !error) {
                    CIContext *context = [CIContext contextWithOptions:nil];
                    for (CIFilter *filter in filterArray) {
                        [filter setValue:image forKey:kCIInputImageKey];
                        image = [filter outputImage];
                    }
                    fullResolutionImage = [context createCGImage:image fromRect:[image extent]];
                }
            }
            completion ([UIImage imageWithCGImage:fullResolutionImage
                                       scale:defaultRepresentation.scale
                                 orientation:(UIImageOrientation)defaultRepresentation.orientation]);
            return;
        }
        default:
            completion(nil);
            return;
    }
}

@end
