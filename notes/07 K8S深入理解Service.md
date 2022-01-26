# 2.4 深入掌握Service

## 2.4.2 Service基本用法

K8S提供了一种快速的办法，可以通过kubectl expose命令来创建Service

```bash
kubectl expose rc webapp
```

上述命令会为Service创建一个ClusterIP，而Service的端口则是从Pod中的containerPort复制而来。

或者通过定义Service yaml文件：

```yaml
apiVersion: v1
kind: Service
metadata:
	name: webapp
spec:
	ports:
		# Service暴露的端口
	- port: 8081
		# Pod暴露的端口
		targetPort: 8080
	selector:
		app: webapp
```

Service负载均衡策略

* RoundRobin（默认）：轮询。
* SessionAffinity：基于客户端IP地址进行会话保持模式，即第一次将某个客户端发起的请求转发到后端的某个Pod上，之后从相同客户端发起的请求都将被转发到后端相同的Pod上。

### 1、多端口Service

```yaml
apiVersion: v1
kind: Service
metadata:
	name: webapp
spec:
	ports:
	- port: 8081
		targetPort: 8080
		name: web
	- port: 8082
		targetPort: 8082
		name: management
	selector:
		app: webapp
```

多端口不同协议

```yaml
apiVersion: v1
kind: Service
metadata:
	name: kube-dns
	namespace: kube-system
	labels:
		k8s-app: kube-dns
		kubernetes.io/cluster-service: "true"
		kubernetes.io/name: "KubeNDS"
spec:
	selector:
		k8s-app: kube-dns
	clusterIP: 172.7.21.100
	ports:
	- port: 53
		targetPort: 53
		name: dns-tcp
	- port: 53
		targetPort: 53
		name: dns-udp
```

### 2、外部服务Service

在某些环境中，应用系统需要讲一个外部数据库作为后端服务进行连接，或将另一个进群或Namespace中的服务作为服务的后端，这时可以通过创建一个无Label Selector的Service来实现。

```yaml
kind: Service
apiVersion: v1
metadata:
	name: my-service
spec:
	ports:
	- protocol: TCP
		port: 80
		targetPort: 80
```

通过该定义创建的是一个不带标签选择器的Service，即无法选择后端的Pod，系统不会自动创建Endpoint，因此需要手动创建一个和该Service同名的Endpoint，用于指向实际的后端访问地址。

```yaml
kind: Endpoints
apiVersion: v1
metadata:
name: my-service
subsets:
	- address:
		- IP: 172.7.21.21
		port: 80
```

## 2.4.3 Headless Service

用户希望自己控制负载均衡的策略，或者应用程序希望知道属于同组服务的其他实例。K8S使用Headless Service，不会给Service设置ClusterIP，仅通过Label Selector将后端的Pod列表返回给调用的客户端。StatefulSet就是使用Headless Service为客户端返回多个服务地址。

```yaml
apiVersion: v1
kind: Service
metadata:
	name: nginx
	labels:
		app: nginx
spec:
	ports:
	- port: 80
	clusterIP: None
	selector:
		app: nginx
```

在去中心化的集群场景中，Headless Service将非常有用。

## 2.4.4 集群外部访问Pod或Service

### 1、将容器应用的端口号映射到物理机

#### 1、设置容器级别的hostPort

```yaml
apiVersion: v1
kind: Pod
metadata:
	name: webapp
	labels:
		app: webapp
	spec:
		containers:
		- name: webapp
			image: tomcat
			ports:
			- containerPort: 8080
				hostPort: 8081
```

可以设置Pod级别的hostNetwork=true，该Pod中所有容器的端口号都将被直接映射到物理机上。注意：在容器的ports定义部分，如果不指定hostPort，则默认hostPort等于containerPort，如果指定了hostPort，则hostPort必须等于containerPort的值。

### 2、将Service的端口号映射到物理机

#### 1、设置nodePort

```yaml
apiVersion: v1
kind: Service
metadata:
	name: webapp
	labels:
		app: webapp
	spec:
		type: NodePort
		ports:
		- port: 8080
			targetPort: 8080
			nodePort: 8081
		selector:
			app: webapp
```

注意：可能需要设置防火墙。

## 2.4.5 DNS服务搭建

## 2.4.6 自定义DNS和上游DNS服务器

## 2.4.7 Ingress

将不同URL的访问请求转发到后端不同的Service，以实现HTTP层的业务路由机制。K8S使用一个Ingress策略定义和一个具体的Ingress Controller，两者结合并实现了一个完整的Ingress负载均衡器。

使用Ingress进行负载分发时，Ingress Controller将基于Ingress规则将客户端请求直接转发到Service对应的后端（Pod）上，这样会跳过kube-proxy的转发功能。如果Ingress Controller提供的是对外服务，则实际上实现的是边缘路由器的功能。

> 具体可参考部署代码。

