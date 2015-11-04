//
//  CTDataBaseDTOBase.h
//  QianbaoIM
//
//  Created by fengsh on 10/5/15.
//  Copyright (c) 2015年 qianbao.com. All rights reserved.
//
/**
 *  数据库模型通常一个对象对应一个表结构
 *  子类根据需要来实现某些方法，不是所有方法都必须实现的
 */

#import "CTModelObject.h"

@protocol CTDataBaseDTOIntf <NSObject>

/**
 *  将子类的DTO属性转为符合coredata使用的Entity
 *
 *
 */
- (instancetype)converTOCoreDataEntity;

/**
 *  从数据库读取出来的字段来生成对象
 *
 *  @param tableModel 数据库表结构的字段
 *
 *  @return 对象
 */
- (instancetype)initWithDatabaseDictionary:(NSDictionary *)tableModel;

/**
 *  通过从网上获取到的数据生成数据库结构的模型，以便更易对数据库进行操作
 *
 *
 */
- (instancetype)initWithNetServerDataDictionary:(NSDictionary *)data;

/**
 *  将数据对象转为可上传到服务器的参数
 *
 */
- (NSDictionary *)convertDatabaseToNetServerParams;

@end

/**
 *  数据库模型,在各自的模型中来构建必要(增删改模)的sql语句
 */
@interface CTDataBaseDTOBase : CTModelObject<CTDataBaseDTOIntf>


@end
