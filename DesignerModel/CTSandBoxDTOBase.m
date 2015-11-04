//
//  CTSandBoxDTOBase.m
//  QianbaoIM
//
//  Created by fengsh on 10/5/15.
//  Copyright (c) 2015年 qianbao.com. All rights reserved.
//
/*
 NSUserDefaults支持的数据类型有：NSNumber（NSInteger、float、double），NSString，NSDate，NSArray，NSDictionary，BOOL.
 
 对相同的Key赋值约等于一次覆盖，要保证每一个Key的唯一性
 
 NSUserDefaults 存储的对象全是不可变的（这一点非常关键，弄错的话程序会出bug），例如，如果我想要存储一个 NSMutableArray 对象，我必须先创建一个不可变数组（NSArray）再将它存入NSUserDefaults中去
 */

#import "CTSandBoxDTOBase.h"

@implementation CTSandBoxDTOBase

@end

