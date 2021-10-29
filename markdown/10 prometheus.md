## Prometheus的特点
* 多维数据模型：由度量名称和键值对标识的时间序列数据(不再是行和列的二维表)
* 内置时间序列数据库：TSDB
* promQL：一种灵活的查询语言，可以利用多维数据完成复杂查询
* 基于HTTP的pull（拉取）方式采集时间序列数据（exporter）
* 同时支持PushGateway组件收集数据
* 通过服务发现或静态配置发现目标
* 多种徒刑模式及仪表盘支持
* 支持为数据源接入Grafana
 
### prometheus架构
![](https://borinboy.oss-cn-shanghai.aliyuncs.com/huan/20211028090654.png)

![](https://borinboy.oss-cn-shanghai.aliyuncs.com/huan/20211028091419.png)

Service discovery
* kubernetes_sd：基于元数据的自动发现
* file_sd：把自动发现规则写到文件中，基于文件的自动发现

注意：
```yaml
  annotations:
    # 这里必须传入一个字符串的1，如果不加引号会报错
    deployment.kubernetes.io/revision: '1'
```
