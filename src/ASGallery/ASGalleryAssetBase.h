//
//  ASGalleryAsset.h
//  Photos
//
//  Created by Andrey Syvrachev on 25.07.13.
//  Copyright (c) 2013 Andrey Syvrachev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASGalleryViewController.h"

@protocol ASGalleryAsyncImageProviding <NSObject>

@optional
-(void)imageForType:(ASGalleryImageType)imageType completion:(void(^)(UIImage *image))completion;

@end

@interface ASGalleryAssetBase : NSObject<ASGalleryAsset, ASGalleryAsyncImageProviding>

-(UIImage*)imageForType:(ASGalleryImageType)imageType;
-(CGFloat)duration;

@end
