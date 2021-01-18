//
//  SDScanMaskView.h
//  SDScanDemo
//
//  Created by 王巍栋 on 2020/6/29.
//  Copyright © 2020 骚栋. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SDScanConfig.h"

typedef void(^UserClickExitBlock)(void);
typedef void(^UserClickAlbumBlock)(void);

@interface SDScanMaskView : UIView

// SDScanMaskView 是扫描遮罩层的视图

- (instancetype)initWithFrame:(CGRect)frame config:(SDScanConfig *)config;

/// 用户点击返回按钮的Block
@property(nonatomic,copy)UserClickExitBlock exitBlock;
@property(nonatomic,copy)UserClickAlbumBlock albumBlock;

@end
