//
//  PHAseetAdapter.h
//  Photos
//
//  Created by Sam Yang on 2/5/15.
//  Copyright (c) 2015 Andrey Syvrachev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AssetsLibrary/AssetsLibrary.h"
#import "ASGalleryAssetBase.h"
#import <Photos/Photos.h>

@interface PHAssetAdapter : ASGalleryAssetBase
@property(nonatomic,strong) PHAsset *asset;
@end
