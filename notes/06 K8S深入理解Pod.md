# 2.3 深入掌握Pod

## 2.3.2 Pod的基本用法

在K8S中，对长时间运行容器的要求是：其主程序一定要在前台执行。

```bash
nohup ./start.sh &
```

在kubelet创建包含合格容器的Pod之后运行完该命令，即认为Pod执行结束，将立刻销毁该Pod。如果为该Pod定义了ReplicationController，则系统将会监控到该Pod已经终止，之后根据RC定义中Pod的副本数生成一个新的Pod，然后又在启动命令结束后被销毁，陷入死循环中。

对于无法改造为前台执行的应用，可以使用supervisor辅助进行前台运行的功能。

## 2.3.3 静态Pod

静态Pod总是由kubelet进行管理的仅存在于特定Node上的Pod。静态Pod不能通过API Server进行管理。

> 所有以非API Server方式创建的Pod都叫做static Pod。

## 2.3.5 Pod的配置管理

### 1、ConfigMap概述

典型用法：

1. 生成为容器内的环境变量。
2. 设置容器启动命令的启动参数（需设置为环境变量）。
3. 以Volume的形式挂载为容器内部的文件或目录。

可以使用kubectl create configmap命令来创建ConfigMap。

### 2、创建ConfigMap资源对象

通过yaml方式创建

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
	name: cm-appvars
data:
	applogloevel: info
	appdatadir: /var/data
```

通过命令行创建

### 3、在Pod中使用ConfigMap

```yaml
apiVersion: v1
kind: Pod
metadata:
	name: cm-pod
spec:
	containers:
	- name: cm-pod
		image: busybox
		command: ["/bin/sh", "-c", "env | grep APP"]
		env:
		- name: APPLOGLEVEL			# 环境变量名
			valueFrom:
				configMapKeyRef:
					name: cm-appvars	# configmap中定义的name
					key: apploglevel
    - name: APPDATADIR			# 环境变量名称
			valueFrom:
				configMapRef:
					name: cm-appvars	# configmap中定义的name
					key: appdatadir
	restartPolicy: Never
```

而从K8S v1.6开始，引入了一个新的字段envFrom，实现在Pod环境内将ConfigMap中所有定义的key=value自动生成为环境变量。

```yaml
apiVersion: v1
kind: Pod
metadata:
	name: cm-pod
spec:
	containers:
	- name: cm-pod
		image: busybox
		command: ["/bin/sh", "-c", "env | grep APP"]
		envFrom:
		-	configMapKeyRef:
			name: cm-appvars	# 根据cm-appvars中的key=value自动生成环境变量
	restartPolicy: Never
```

通过以上定义，会在容器内部生成如下环境变量：

```
apploglevel=info
appdatadir=/var/data
```

> 环境变量名称受POSIX命名规范约束，`[a-zA-Z][a_zA_Z0-9_]*`，如果包含非法字符，则系统将跳过该条环境变量的创建，并记录到Event中，但并不阻止Pod的启动。

#### 使用ConfigMap的限制条件

* 必须在Pod之前创建。
* 受Namespace限制，只有处于相同Namespace的Pod可以引用。
* 静态Pod无法引用。
* 在Pod对ConfigMap进行挂载操作时，容器内部只能挂载为目录，无法挂载为文件。挂载之后，会覆盖已有文件。

## 2.3.9 Pod调度

### 1、Deployment/RC

全自动调度。

### 2、NodeSeletor：定向调度

给Node节点打标签，然后在Pod定义文件中，设置nodeSelector参数，调度到指定标签的Node节点上。

### 3、NodeAffinity

亲和性调度，用于替换NodeSelector的全新调度策略。注意事项如下：

* 如果同时定义了nodeSelector和nodeAffinity，那么必须两个条件都满足，Pod才能最终运行在指定的Node上。
* 如果nodeAffinity指定了多个nodeSelectorTerms，那么只需要其中一个能够匹配成功即可。
* 如果nodeSelectorTerms中有多个matchExpressions，则一个节点必须满足所有matchExpressions才能运行该Pod。

### 4、PodAffinity

如果具有某个标签的Pod已经运行在某个节点上，那么新的具有这个标签的Pod就不会被调度到该节点上。

> 因为Pod是属于某个Namespace，因此，上述情况只在同一个Namespace中生效。换句话说就是，不同Namespace中，具有相同标签的Pod的调度不会出现排斥的情况。

#### 1、参照目标Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
	name: pod-flag
	labels:
		security: "S1"
		app: "nginx"
	spec:
		containers:
		- name: nginx
			image: nginx
```

#### 2、Pod的亲和性调度

```yaml
apiVersion: v1
kind: Pod
metadata:
	name: pod-affinity
spec:
	affinity:
		requireDuringSchedulingIgonreDuringExecution:
		- labelSelector:
			matchExpressions:
			- key: security
				oprator: In
				values:
				- S1
			topologKey: kubernetes.io/hostname
	containers:
	- name: with-pod-affinity
		image: gcr.io/google_containers/pause:2.0
```

#### 3、Pod的互斥性调度

```yaml
apiVersion: v1
kind: Pod
metadata:
	name: pod-affinity
spec:
	affinity:
		requireDuringSchedulingIgonreDuringExecution:
		- labelSelector:
			matchExpressions:
			- key: security
				oprator: In
				values:
				- S1
			topologKey: failure-domain.beta.kubernetes.io/zone
	podAntiAffinity:
		requireDuringSchedulingIgnoredDuringExecution:
		- labelSelector:
			matchExpressions:
			- key: app
				oprator: In
				values:
				- nginx
			topologKey: kubernetes.io/hostname
	containers:
	- name: anti-affinity
		image: gcr.io/google_containers/pause:2.0
```

与节点亲和性类似，Pod亲和性的操作符也包括：In、NotIn、Exists、DoesNotExist、Gt、Lt。

原则上，topologyKey可以使用任何合法的标签Key赋值，但是出于性能和安全方面的考虑，对topologyKey有如下限制：

* 在Pod亲和性和RequiredDuringScheduling的Pod互斥性的定义中，不允许使用空的topologyKey。
* 如果Admission controller包含了LimitPodHardAntiAffinityTopology，那么针对requireDuringScheduling的Pod互斥性定义就被限制为kubernetes.io/hostname，要使用自定义的topologyKey，就要改写或禁用该控制器。
* 在PreferredDuringScheduling类型的Pod互斥性定义中，空的topologyKey会被解释为kubernetes.io/hostname、failure-domain.beta.kubernetes.io/zone及failure-domain.beta.kubernetes.io/region的组合。
* 如果不是上述情况，就可以采用任意合法的topologyKey了。

PodAffinity规则设置注意事项：

* 除了设置Label Selector和topologyKey，用户还可i指定namespace列表来进行限制或选择。namespace的定义和Label Selecotr及topology同级。
* 省略namespace的设置，表示使用定义了affinity/anti-affinity的Pod所在的namespace。如果namespace设置为空值（""），则表示所有的namespace。
* 在所有关联requireDuringSchedulingIgnoredDuringExecution的matchExpressions全都满足之后，系统才能将Pod调度到某个Node上。

### 5、Taints和Tolerations

污点和容忍。Taint与亲和性相反，Node会拒绝Pod的运行。

在Node上设置一个或多个Taint之后，除非Pod明确声明能够容忍这些“污点”，否则无法在这些Node上运行。

```bash
kubectl taint nodes <node name> <key>=<value>:NoSchedule
```

如果在Pod中声明了Toleration，那么Pod就可以被调度到具有Taint的Node节点上。

```yaml
tolerations:
- key: "key"
	operator: "Equal"
  value: "value"
	effect: "NoSchedule"
```

或

```yaml
tolerations:
- key: "key"
	operator: "Exists"
	effect: "NoSchedule"
```

effect取值除了NoSchedule，还可以取值为PreferNoschedule，意思是优先，意思是：一个Pod如果没有声明容忍这个Taint，则系统会尽量避免把这个Pod调度到这一节点上去，但不是强制的。

Pod的Toleration声明中的key和effect需要与taint的设置保持一致，并满足以下条件：

* operator的值是Exists（无需指定value）
* operator的值是Equal并且value相等

如果不指定operator，则默认值是Equal。

另外还有特例：

* 空的key配合Exists操作符能够匹配所有的键和值。
* 空的effect匹配所有的effect。

系统允许在同一个Node上设置多个Taint，也可以在Pod上设置多个Toleration。K8S调度器处理多个Taint和Toleration的逻辑顺序为：

1. 首先列出集群中所有的Taint
2. 然后忽略Pod的Toleration能够匹配的部分
3. 剩下的没有忽略掉的Taint就是对Pod的效果了

几种特殊情况：

* 如果剩余的Taint中存在effect=NoSchedule，则调度器不会把该Pod调度到这一节点上。
* 如果剩余的Taint中没有NoSchedule但是有PreferNoSchedule
* 如果剩余Taint的效果有NoExecute，并且这个Pod已经在该节点上运行，则会被驱逐。如果没有在该节点上运行，也不会再被调度到该节点上。

> tolerationSeconds，这个设置表明Pod可以在Taint添加到Node之后还能在这个Node上运行时间（单位：s）。

#### 1、独占节点

```bash
kubectl taint nodes nodename dedcated=groupName:NoSchedule
```

然后个这些应用的Pod加入对应的Toleration。

#### 2、具有特殊硬件设备的节点

类似于独占节点。

#### 3、定义Pod驱逐行为，以应对节点故障

从K8S v1.6版本那是引入了一个Alpha版本的功能，即把节点故障标记为Taint（目前只针对node unreachbale与node not ready，相应的NodeCondition "Ready"的值分别为Unknown和False）。

激活TaintBasedEvictions功能后，NodeController会自动为Node设置Taint，而状态为“Ready”的Node上之前设置过的普通驱逐逻辑将会被禁用。

**注意**：在节点故障情况下，为了保持现存Pod驱逐的限速设置（rate-limiting），系统将会以限速的模式逐步给Node设置Taint，这样就能防止在一些特定情况下（比如Master暂时失联）造成的大量Pod被驱逐的后果，这一功能兼容于tolerationSeconds，允许Pod定义节点故障时持续多久才被驱逐。

### 6、DaemonSet

DaemonSet是K8S v1.2版本新增的一种资源对象，用于管理在集群中每个Node上仅运行一份Pod的副本实例，这种用法的场景：

* 在每个Node上运行一个GlusterFS存储或Ceph存储的Daemon进程。
* 在每个Node上运行一个日志采集工具、监控等

可以通过指定NodeSelector或NodeAffinity来进行调度。

### 7、Job：批处理调度

### 8、Crontab

## 2.3.10 Init Container

用于在启动应用容器前启动一个或多个“初始化”容器“，完成应用容器的环境准备，且是仅运行一次就结束的任务，并且必须在成功执行完成后，系统才能继续执行下一个容器。

Init Container也可以设置RestartPolicy。

```yaml
apiVersion: v1
kind: Pod
metadata:
	name: nginx
spec:
	initContainers:
	- name: install
		image: busybox
		command:
		- wget
		- "O"
		- "/work-dir/index.html"
		- http://kubernetes.io
# .........
```

在Pod重新启动时，init container将会重新运行。

## 2.3.11 Pod升级和回滚

如果Pod是通过Deployment创建的，则用户可以在运行时修改Deployment的Pod定义（spec.template）或镜像名称，并应用到Deployment对象上，系统即可完成Deployment的自动更新操作。如果在更新过程中发生错误，则还可以通过回滚（Rollback）操作恢复Pod的版本。

### 1、Deployment升级

```yaml
apiVersion: apps/v1beta1
kind: Deployment
metadata:
	name: nginx-deployment
spec:
	replicas: 3
	template:
		metadata:
			labels:
				app: nginx
		spec:
			containers:
			- name: nginx
				image: nginx:1.7.9
				ports:
				- containerPort: 80
```

命令行更新Pod镜像：

```bash
kubectl set image deployment/nginx-deployment nginx:1.9.1
```

`kubectl edit`更新yaml文件

```bash
kubectl edit deployment/nginx-deployment
```

一旦镜像名（或Pod定义）发生了修改，则将触发系统完成Deployment所有运行Pod得滚动升级操作。实现原理就是通过ReplicaSet，新增一个新的Pod，减少一个旧的Pod。保证整个系统中有Pod可用。

Deployment更新策略：

* RollingUpdate：默认的，滚动更新。
* Recreate：杀掉正在运行的Pod，然后创建新的Pod。

需要注意：

* 同一时间执行多个更新操作的情况。
* 注意更新Deployment Label Selector的情况。通常不建议更新Deployment Label Selector，因为这样会导致DP选择的Pod列表发生变化，也可能会与其他控制器产生冲突。

### 2、DP回滚

查看版本历史

```bash
kubectl rollout history deployment/nginx-deployment
```

回滚到上一个版本

```bash
kubectl rollout undo deployment/nginx-deployment
```

回滚到指定版本

```
kubectl rollout undo deployment/nginx-deployment --to-revision=2
```

### 4、使用rolling-update

使用kubectl rolling-update命令完成RC的滚动升级，需要注意的是：

* 新的RC需要与旧的RC在相同Namespace中，新的RC与旧的RC的名字（name）不能相同。
* selector中应至少有一个Label与旧的Label不同，以标识其为新的RC。

使用指定image来升级

```
kubectl rolling-update <pod name> --image=<pod name>:version
```

### 5、其他管理对象的更新策略

#### 1、Daemon

更新策略有两种：OnDelete和RollingUpdate。

#### 2、StatefulSet

更新策略：RollingUpdate、Paritioned和Ondelete。

