//
//  CTHttpRequestFactory.h
//  QianbaoIM
//
//  Created by fengsh on 13/4/15.
//  Copyright (c) 2015年 fengsh. All rights reserved.
//
/**
 *  过渡层，使用工厂模式进行接口模块切换
 *
 *************************************************************************************************
 /                               业务
 /                                ↓                                                对外暴露
 /                           CTHttpTools
 /--------------------------------↓---------------------------------------------------------------
 /                       CTHttpRequestFactory(构造器)
 /                                ↓
 /                        CTHttpRequestAPI(可扩展基类)                               隐藏实现细节
 /                                ↓
 /   －－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－
 /   ↓                            ↓                                  ↓
 /  AFNetWorking实现           ASI库实现   ......(自定义扩展)  NSURLConnection系统库实现
 *************************************************************************************************
 *
 */


#import <Foundation/Foundation.h>
#import "CTHttpDefine.h"

@interface CTHttpRequestFactory : NSObject<ICTHttpRequestConstruction>
{
    @private
    APIType         _type;
}

- (instancetype)initWithImplType:(APIType)type;
- (void)setType:(APIType)type;

- (CTHttpRequest *)createRequest;
- (CTHttpUploadRequest *)createUploadRequest;
- (CTHttpDownloadRequest *)createDownloadRequest;

@end
