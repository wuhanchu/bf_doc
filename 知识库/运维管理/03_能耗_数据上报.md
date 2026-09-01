# 能耗数据上报

能源平台：[https://www.fjjnzx.cn:9003](https://www.fjjnzx.cn:9003)（数据接口见 [系统地址](../README.md#系统地址)）

提供数据查看，同时提供驱动下载。

账号登录联系 潘羲

## 使用

```shell
# 关闭
Ksslclient stop
# 状态
Ksslclient status
# 开启
Ksslclient start 111111
```

配置 Ksslclient 作为服务

配置 tinyproxy 作为服务，允许 51 的请求

## 终端注册

```shell
curl -X POST "http://www.fjjnzx.cn:9005" \
     -H "Content-Type: application/json" \
     -d '{"enterpriseCode": "91350200587858320K","region": "350000"}'
```

结果：

```json
{
  "deviceId": "fb695e34160942d29ae7b668074fcb87",
  "loadConfigURL": "http://www.fjjnzx.cn:9005/downloadBaseData",
  "loadDicVersionURL": "http://www.fjjnzx.cn:9005/versionCheck",
  "centerInfoURL": "http://www.fjjnzx.cn:9005/uploadConfigData",
  "centerDataURL": "http://www.fjjnzx.cn:9005/uploadEnergyData",
  "centerInfoDownloadURL": "http://www.fjjnzx.cn:9005/downloadConfigData",
  "centerDataDownloadURL": "http://www.fjjnzx.cn:9005/downloadEnergyData",
  "centerMeteringDataURL": "http://www.fjjnzx.cn:9005/uploadMeteringData",
  "centerMeteringDownloadURL": "http://www.fjjnzx.cn:9005/downloadMeteringData",
  "responseCode": "0",
  "responseMessage": "RECEIVE SUCCESS",
  "uploadTime": "00:42:30"
}
```

## 版本校验

```shell
curl -X POST "http://www.fjjnzx.cn:9005/versionCheck" \
     -H "Content-Type: application/json" \
     -d '{"deviceId": "fb695e34160942d29ae7b668074fcb87"}'
```

结果：

```json
{"dicVersion":"274","responseMessage":"RECEIVE SUCCESS","regVersion":"100","responseCode":"0"}
```

## 基础数据下载

```shell
curl -X POST "http://www.fjjnzx.cn:9005/downloadBaseData" \
     -H "Content-Type: application/json" \
     -d '{"deviceId": "fb695e34160942d29ae7b668074fcb87"}'
```

## 用能单位基础信息下载

```shell
curl -X POST "http://www.fjjnzx.cn:9005/downloadConfigData" \
     -H "Content-Type: application/json" \
     -d '{"enterpriseCode": "91350200587858320K","deviceId": "fb695e34160942d29ae7b668074fcb87"}'
```

结果：

```json
{"responseCode":"0","responseMessage":"RECEIVE SUCCESS"}
```

## 用能单位基础信息上传

```shell
curl -X POST "http://www.fjjnzx.cn:9005/uploadConfigData" \
     -H "Content-Type: application/json" \
     -d @data/engrgy_uinit.json
```

上传数据示例：

```json
{
  "deviceId": "fb695e34160942d29ae7b668074fcb87",
  "enterpriseCode": "91350200587858320K",
  "collectItemConfig": [
    {
      "name": "全厂-二次能源-电力-购进已消费",
      "processCode": "00",
      "processUnitCode": "00",
      "equipmentCode": "00",
      "equipmentUnitCode": "00",
      "energyClassCode": "02",
      "energyTypeCode": "3300",
      "dataUsageCode": "11",
      "inputType": "1",
      "statType": "1",
      "collectSystemName": "EXCENERGY 能源采集系统",
      "remark": "",
      "scope": 1
    },
    {
      "name": "全厂-二次能源-天然气-购进已消费",
      "processCode": "00",
      "processUnitCode": "00",
      "equipmentCode": "00",
      "equipmentUnitCode": "00",
      "energyClassCode": "01",
      "energyTypeCode": "1500",
      "dataUsageCode": "11",
      "inputType": "1",
      "statType": "1",
      "collectSystemName": "EXCENERGY 能源采集系统",
      "remark": "",
      "scope": 1
    }
  ],
  "enterprise": {
    "code": "91350200587858320K",
    "name": "厦门保沣集团有限公司",
    "typeCode": "159",
    "typeName": "其他有限责任公司",
    "industryCode": "C3333",
    "regionCode": "350212",
    "regionName": "福建省厦门市同安区",
    "center": false,
    "corporationCode": "91350200587858320K",
    "jgzh": false,
    "energyConsumeLevel": 4,
    "latitude": 24.744788,
    "longitude": 118.223941,
    "phone": "0592-7116992",
    "fax": "0592-7116992",
    "email": "wuhs@xmbaofeng.com",
    "address": "福建省厦门市同安区布塘中路1668号",
    "zipCode": "350212",
    "url": "www.xmbaofeng.com",
    "fieldCode": "100",
    "fieldName": "工业",
    "corporationName": "陈延富",
    "registerDate": "2012-01-20 00:00:00",
    "registerPrincipal": 50000,
    "energyOffice": "安环部",
    "energyOfficial": "贺志宏",
    "energyOfficialPosition": "经理",
    "energyOfficialPhone": "18850031971",
    "energyPass": true,
    "energyRespName": "林城管",
    "energyRespPhone": "15160737607",
    "passDate": "",
    "passOrg": "",
    "productionLine": "易拉盖",
    "leadingProduct": "金属包装容器制造;金属表面处理及热处理加工",
    "remark": ""
  }
}
```

## 下载能源数据

```shell
curl -X POST "http://www.fjjnzx.cn:9005/downloadEnergyData" \
  -H "Content-Type: application/json" \
  -d '{  "deviceId": "fb695e34160942d29ae7b668074fcb87",  "enterpriseCode": "91350200587858320K",    "statType": 0,    "statDate": "2014-04-03" }'
```

## 参考文档

- [能耗上报相关文档（微信公众号）](https://mp.weixin.qq.com/s/7I2V1r2aKC8boHgzGxECWA)
