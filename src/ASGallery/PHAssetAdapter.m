//
//  PHAseetAdapter.m
//  Photos
//
//  Created by Sam Yang on 2/5/15.
//  Copyright (c) 2015 Andrey Syvrachev. All rights reserved.
//

#import "PHAssetAdapter.h"

@interface PHAssetAdapter(){
    PHAssetMediaType _type;
    CGSize _dimensions;
    NSNumber * _duration;
    NSURL *_assetURL;
    BOOL _canceled;
}

@end

@implementation PHAssetAdapter

-(void)setAsset:(PHAsset *)asset
{
    _asset = asset;
}

-(CGFloat)duration
{
    if (_duration == nil){
        _duration = @(_asset.duration);
    }
    return [_duration floatValue];
}

-(BOOL)isVideo
{
    _type = _asset.mediaType;
    return _type == PHAssetMediaTypeVideo;
}

-(NSURL*)url
{
    return _assetURL;
}

-(void)requestURL:(void(^)(NSURL *url))completion
{
    _canceled = NO;
    
    if (_assetURL) {
        if (_canceled) return;
        completion(_assetURL);
        return;
    }
    
    [[PHImageManager defaultManager] requestAVAssetForVideo:_asset options:nil resultHandler:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info) {
        NSLog(@"request FINISH, %d - %@", _canceled, _asset);
        if (_canceled) return;
        _assetURL = [(AVURLAsset *)asset URL];
        completion(_assetURL);
    }];
}

- (void)cancelRequest;
{
    _canceled = YES;
}

-(CGSize)dimensions
{
    if (CGSizeEqualToSize(_dimensions, CGSizeZero))
        _dimensions = CGSizeMake(_asset.pixelWidth, _asset.pixelHeight);
    return _dimensions;
}

-(BOOL)isImageForTypeAvailable:(ASGalleryImageType)imageType
{
    return YES;
}

- (void)imageForType:(ASGalleryImageType)imageType completion:(void(^)(UIImage*))completion
{
    PHImageManager *imageManager = [PHImageManager defaultManager];
    CGSize sourceSize = CGSizeMake(106.f, 106.f);
    switch (imageType) {
        case ASGalleryImageThumbnail:
            break;
        case ASGalleryImagePreview:
            sourceSize = CGSizeMake(160, 160);
            break;
        case ASGalleryImageFullScreen:{
            CGSize screenSize = [[UIScreen mainScreen] bounds].size;
            sourceSize = CGSizeMake(screenSize.width, screenSize.width * 4/3);
        }
            break;
        case ASGalleryImageFullResolution:
            sourceSize = CGSizeMake(_asset.pixelWidth, _asset.pixelHeight);
            break;
        default:
            completion(nil);
            return ;
    }
    
    [imageManager requestImageForAsset:_asset
                            targetSize:sourceSize
                           contentMode:PHImageContentModeAspectFill
                               options:nil
                         resultHandler:^(UIImage *result, NSDictionary *info) {
                             completion(result);
                             
                         }];
}

@end
