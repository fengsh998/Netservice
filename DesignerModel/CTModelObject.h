//
//  CTModelObject.h
//  QianbaoIM
//
//  Created by fengsh on 10/5/15.
//  Copyright (c) 2015年 qianbao.com. All rights reserved.
//
/**
 *                          MODEL 基类
 *
 *      如果model需要copy请继承此类
 *      如果model需要归档请继承此类
 *      如果想model使用NSLog直接打印出日志时，请继承此类。
 *      如果model需要实现特定的copy或归档。请复盖父类的相应方法。
 */

@interface CTModelObject : NSObject<NSCopying,NSCoding>

- (id)copyWithZone:(NSZone *)zone;

- (void)encodeWithCoder:(NSCoder *)aCoder;

- (id)initWithCoder:(NSCoder *)aDecoder;

- (NSString *)description;

@end
