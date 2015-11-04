//
//  CTNetServerDTOBase.m
//  QianbaoIM
//
//  Created by fengsh on 10/5/15.
//  Copyright (c) 2015年 qianbao.com. All rights reserved.
//

#import "CTNetServerDTOBase.h"

@implementation CTNetServerDTOBase

- (void)setCustomDTODictionary:(NSDictionary *)custom
{
    _custom = custom;
}

/**
 *  子类进行实现
 *  将子类中DTO的各属性处理成提交给服务器需要的参数格式的Dic
 *  @return NSDictionary
 */
- (NSDictionary *)convertObjctToDictionary
{
    return _custom;
}

/**
 *  通过网络返回的Dictionary来生成对象
 *
 *  @param dictionary 网络返回的Dictionary
 *
 *  @return 对象
 */
- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    NSAssert(0, @"This method to do implementation in subclass .");
    return nil;
}

@end
