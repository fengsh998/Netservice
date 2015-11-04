//
//  CTDataBaseDTOBase.m
//  QianbaoIM
//
//  Created by fengsh on 10/5/15.
//  Copyright (c) 2015年 qianbao.com. All rights reserved.
//

#import "CTDataBaseDTOBase.h"

@implementation CTDataBaseDTOBase

/**
 *  将子类的DTO属性转为符合coredata使用的Entity
 *
 *
 */
- (instancetype)converTOCoreDataEntity
{
    NSAssert(0, @"This method to do implementation in subclass .");
    return nil;
}
/**
 *  将子类的DTO属性转为SQL语句
 *
 */
- (NSString *)converToSQL
{
    NSAssert(0, @"This method to do implementation in subclass .");
    return nil;
}

/**
 *  从数据库读取出来的字段来生成对象
 *
 *  @param tableModel 数据库表结构的字段
 *
 *  @return 对象
 */
- (instancetype)initWithDatabaseDictionary:(NSDictionary *)tableModel
{
    NSAssert(0, @"This method to do implementation in subclass .");
    return nil;
}

/**
 *  通过从网上获取到的数据生成数据库结构的模型，以便更易对数据库进行操作
 *
 *
 */
- (instancetype)initWithNetServerDataDictionary:(NSDictionary *)data
{
    NSAssert(0, @"This method to do implementation in subclass .");
    return nil;
}

/**
 *  将数据对象转为可上传到服务器的参数
 *
 */
- (NSDictionary *)convertDatabaseToNetServerParams
{
    NSAssert(0, @"This method to do implementation in subclass .");
    return nil;
}


@end
