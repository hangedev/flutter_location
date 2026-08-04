<p align="center">
  <h1 align="center"> <code>location</code> </h1>
</p>


本项目为 [location@5.0.3](https://pub.dev/packages/location/versions/5.0.3) 和 [location@7.0.1](https://pub.dev/packages/location/versions/7.0.1) 提供 OpenHarmony/ohos支持。

## 1. 安装与使用

### 1.1 安装方式

进入到工程目录并在 pubspec.yaml 中添加以下依赖：

<!-- tabs:start -->

#### pubspec.yaml

```yaml
dependencies:
  location:
    git:
      url: https://gitcode.com/CPF-Flutter/flutter_location.git
      # ref: 根据下方表格选择不同框架适配的TAG版本
      ref: TAG  # Select a TAG from the TAG version mapping table below
      path: "./packages/location"
```

执行命令

```bash
flutter pub get
```

> TAG 命名规则：原库版本-ohos-版本号-betax，不同 TAG 之间的变更详见 CHANGELOG.OpenHarmony.md。实际使用时请将依赖示例中的 TAG 替换为下表选择的 TAG。

| Flutter 框架版本 | TAG | 分支 |
|---|---|---|
| 3.7 | 5.0.3-ohos-1.0.0-beta.1 | master |
| 3.22 | 7.0.1-ohos.1.0.1 | br_location-v7.0.1_ohos |
| 3.27 | 7.0.1-ohos.1.0.1 | br_location-v7.0.1_ohos |
| 3.35 | 7.0.1-ohos.1.0.1 | br_location-v7.0.1_ohos |

> **迁移说明**：从 location@5.0.3 升级到 location@7.0.1 时，请注意新增了 `LocationScenario` 枚举和 `distanceInterval` 参数。不使用这些参数的已有代码将以默认值继续正常工作。

<!-- tabs:end -->

### 1.2 使用案例

使用案例详见 [example](./packages/location/example)

#### 快速开始示例

```dart
import 'package:location/location.dart';

// 获取单例实例
final location = Location();

// 检查并请求权限
bool serviceEnabled = await location.serviceEnabled();
if (!serviceEnabled) {
  serviceEnabled = await location.requestService();
  if (!serviceEnabled) {
    return;
  }
}

PermissionStatus permissionGranted = await location.hasPermission();
if (permissionGranted == PermissionStatus.denied) {
  permissionGranted = await location.requestPermission();
  if (permissionGranted != PermissionStatus.granted) {
    return;
  }
}

// 获取当前位置
LocationData locationData = await location.getLocation();

// 监听位置变化流
location.onLocationChanged.listen((LocationData currentLocation) {
  print('纬度: ${currentLocation.latitude}');
  print('经度: ${currentLocation.longitude}');
  print('精度: ${currentLocation.accuracy}');
  print('海拔: ${currentLocation.altitude}');
  print('速度: ${currentLocation.speed}');
  print('方向: ${currentLocation.heading}');
});
```

#### OHOS 专属功能示例

```dart
import 'package:location/location.dart';

final location = Location();

// 使用 OHOS 专属的 LocationScenario 进行自动策略优化
await location.changeSettings(
  accuracy: LocationAccuracy.high,
  scenario: LocationScenario.navigation,  // OHOS 专属：导航场景
  interval: 1000,
  distanceInterval: 10.0,  // OHOS 专属：距离间隔（米）
);

// 使用 OHOS 专属精度值
await location.changeSettings(
  accuracy: LocationAccuracy.balanced,  // 在 OHOS 上映射为 LOW_POWER
  scenario: LocationScenario.trajectoryTracking,  // 轨迹追踪模式
);

// 检查并启用后台模式
bool isBackgroundEnabled = await location.isBackgroundModeEnabled();
if (!isBackgroundEnabled) {
  await location.enableBackgroundMode(enable: true);
}
```

### 1.3 OHOS 环境配置

在 OpenHarmony/ohos上构建和运行：

1. **安装 DevEco Studio**：下载安装 [DevEco Studio]5.0.13.200 或更高版本
2. **配置 SDK**：在 DevEco Studio 中配置 OpenHarmony SDK（API 版本 12 或更高）
3. **构建项目**：
   ```bash
   cd packages/location/example
   flutter pub get
   flutter build hap
   ```
4. **部署运行**：使用 DevEco Studio 或 hdc 命令将 HAP 部署到设备

## 2. 约束与限制

### 2.1 兼容性

在以下版本中已测试通过：

| 三方库版本 | Flutter (OHOS) | SDK | DevEco Studio | ROM |
|---|---|---|---|---|
| location@7.0.1 | 3.27.5-ohos-1.0.1 | 5.0.0(12) | 6.0.1.260 | 6.0.0.120 SP6 |
| location@7.0.1 | 3.35.7-ohos-0.0.1 | 6.0.1(21) | 6.0.1.260 | 6.0.0.120 SP6 |

## 3. API

> [!TIP] "OHOS 支持"列为 yes 表示 OHOS 平台支持该属性；no 则表示不支持；partially 表示部分支持。使用方法跨平台一致，效果对标 iOS 或 Android 的效果。

### 方法

| 名称                | 返回值          | 描述                                                                                                             | 类型     | OHOS 支持 |
|---------------------|-------------------------------------------------------------------------------------------------------------------------|----------|-------------------|-------------------|
| changeSettings({[LocationAccuracy](#LocationAccuracy)? accuracy = [LocationAccuracy](#LocationAccuracy).high,[LocationScenario](#LocationScenario)? scenario = [LocationScenario](#LocationScenario).unset,int? interval = 1000,double? distanceFilter = 0,double? distanceInterval = 0,})                                 | Future<bool> | 修改位置请求的设置。 | function | yes          |
| isBackgroundModeEnabled() | Future<bool>                                                  | 检查服务是否在后台模式中启用。 | function | yes          |
| enableBackgroundMode({bool? enable = true})                                 | Future<bool> | 启用或禁用后台模式中的服务。 | function | yes          |
| getLocation()                                 | Future<[LocationData](#LocationData)> | 获取用户的当前位置。 | function | yes          |
| hasPermission()                                 | Future<[PermissionStatus](#PermissionStatus)> | 检查应用是否拥有访问位置的权限。 | function | yes          |
| requestPermission()                                 | Future<[PermissionStatus](#PermissionStatus)> | 请求访问位置的权限。 | function | yes          |
| serviceEnabled()                                 | Future<bool> | 检查位置服务是否已启用。 | function | yes          |
| requestService()                                 | Future<bool> | 请求激活位置服务。 | function | partially          |
| onLocationChanged                                 | Stream<[LocationData](#LocationData)> | 位置变更事件流。订阅以接收持续的位置更新。 | property | yes          |
| changeNotificationOptions({...})                                 | Future<[AndroidNotificationData](#AndroidNotificationData)?> | 修改后台模式的 Android 通知选项。 | function | no          |

> **注意**：`requestService()` 在 OHOS 上标记为 `partially`，因为 OpenHarmony 不提供弹出启用定位对话框的系统 API。该方法将返回 `PlatformException`，错误码为 `SERVICE_NOT_SUPPORTED`。用户需手动前往系统设置启用定位。

### 参数

| 名称                              | 返回值       | 描述                                                  | 类型     | OHOS 支持 |
| --------------------------------- | ------------ | ------------------------------------------------------------ | -------- | ------------ |
| interval |  | 控制位置更新的时间间隔。 | int | yes          |
| distanceFilter |  | 控制位置更新的距离阈值。在 OHOS 上映射为 `distanceInterval`。 | double | yes          |
| distanceInterval |  | 控制位置更新的距离间隔（OHOS 专属参数）。 | double | yes          |
| enable |  | 控制是否启用后台模式服务。 | bool | yes          |
| [LocationAccuracy](#LocationAccuracy) |  | 定位的精度。较低的精度会提供更长的电池续航时间。 | enum | yes          |
| [LocationScenario](#LocationScenario) |  | 用于在ohos操作系统中定义定位场景模式，允许系统根据不同场景自动优化定位策略。 | enum | yes          |
| [LocationData](#LocationData) |  | 表示现实世界中的一个地理位置。 | class | yes          |
| [PermissionStatus](#PermissionStatus) |  | 使用定位服务的权限请求的状态。 | enum | yes          |

### LocationAccuracy

| 名称                              | 返回值       | 描述                                                  | 类型     | OHOS 支持 |
| --------------------------------- | ------------ | ------------------------------------------------------------ | -------- | ------------ |
| powerSave |  | 请求尽可能高的精度，且不增加额外的功耗。在 OHOS 上等同于 FIRST_FIX 模式。 | enum | yes          |
| low |  | 请求"城市"级别的精度。在 OHOS 上等同于 LOW_POWER 模式。 | enum | yes          |
| balanced |  | 请求"街区"级别的精度。在 OHOS 上等同于 LOW_POWER 模式。 | enum | yes          |
| high |  | 请求最精确的定位信息。在 OHOS 上等同于 ACCURACY 模式。 | enum | yes          |
| navigation |  | 请求用于导航的定位信息（仅影响 iOS）。 | enum | yes          |
| reduced |  | 在 iOS 14.0 及以上版本中，对应 kCLLocationAccuracyReduced。在 OHOS 上等同于 LOW_POWER 模式。 | enum | yes          |
| unset |  | 在 OHOS 上等同于 UNSET（仅影响 OHOS）。 | enum | yes          |

### LocationScenario

| 名称                              | 返回值       | 描述                                                  | 类型     | OHOS 支持 |
| --------------------------------- | ------------ | ------------------------------------------------------------ | -------- | ------------ |
| unset |  | 请求用于默认场景的定位信息（仅影响 OHOS）。 | enum | yes          |
| navigation |  | 请求用于导航场景的定位信息（仅影响 OHOS）。 | enum | yes          |
| trajectoryTracking |  | 请求用于轨迹追踪场景的定位信息（仅影响 OHOS）。 | enum | yes          |
| carHailing |  | 请求用于网约车场景的定位信息（仅影响 OHOS）。 | enum | yes          |
| dailyLifeService |  | 请求用于日常生活服务场景的定位信息（仅影响 OHOS）。 | enum | yes          |
| noPower |  | 请求用于无功耗场景的定位信息（仅影响 OHOS）。 | enum | yes          |

### LocationData

| 名称                              | 返回值       | 描述                                                  | 类型     | OHOS 支持 |
| --------------------------------- | ------------ | ------------------------------------------------------------ | -------- | ------------ |
| latitude |  | 纬度，以度为单位。 | double | yes          |
| longitude |  | 经度，以度为单位。 | double | yes          |
| accuracy |  | 此位置的估算水平精度，以米为单位的半径值。 | double | yes          |
| altitude |  | 以米为单位，高于WGS 84参考椭球面的高度。 | double | yes          |
| speed |  | 以米/秒为单位。 | double | yes          |
| heading |  | 航向是此设备的水平行进方向，以度为单位。 | double | yes          |
| time |  | 定位数据的时间戳（epoch 毫秒）。 | double | yes          |
| verticalAccuracy |  | 海拔的估算垂直精度，以米为单位。 | double | no           |
| speedAccuracy |  | 速度精度，以米/秒为单位。 | double | no           |
| isMock |  | 该位置是否是模拟的。 | bool | no           |
| headingAccuracy |  | 获取此位置的估算方位精度，以度为单位。 | double | no           |
| elapsedRealtimeNanos |  | 返回此定位的时间，以系统启动后的流逝实时为准。 | double | no           |
| elapsedRealtimeUncertaintyNanos |  | 获取对 ElapsedRealtimeNanos 时间戳对齐精度的相对估算值。 | double | no           |
| satelliteNumber |  | 用于确定定位的卫星数量。 | int | no           |
| provider |  | 生成此定位信息的提供者名称。 | String | no           |

> **注意**：标注为 `no` 的字段在 OHOS `geoLocationManager.Location` API 中不可直接获取，在 OHOS 平台上将返回 `null`。可以使用 `LocationData.fromMap(Map<String, dynamic>)` 构造方法从 Map 创建 LocationData，不可用字段默认为 `null`。

### PermissionStatus

| 名称                              | 返回值       | 描述                                                  | 类型     | OHOS 支持 |
| --------------------------------- | ------------ | ------------------------------------------------------------ | -------- | ------------ |
| granted |  | 已授予使用定位服务的高精度权限。 | enum | yes          |
| grantedLimited |  | 权限已被授予，但仅限于低精度（仅粗略定位）。在 OHOS 上表示 APPROXIMATELY_LOCATION 已授予但 LOCATION 未授予。 | enum | yes          |
| denied |  | 用户拒绝了使用定位服务的权限。 | enum | yes          |
| deniedForever |  | 用户永久拒绝了使用定位服务的权限。请求权限时不会显示任何对话框。在 OHOS 上，此状态不会返回 — 见遗留问题。 | enum | partially    |

### 单例模式

`Location` 类通过工厂构造函数实现单例模式：

```dart
// 获取单例实例
final location = Location();

// 或直接访问实例
Location.instance;
```

可以为测试设置自定义实例：

```dart
Location.instance = MockLocation();
```

### 流式 API

`onLocationChanged` 属性提供位置更新的流：

```dart
// 订阅位置变化
location.onLocationChanged.listen((LocationData currentLocation) {
  print('位置更新: ${currentLocation.latitude}, ${currentLocation.longitude}');
});

// 取消订阅
StreamSubscription<LocationData> subscription = location.onLocationChanged.listen((_) {});
subscription.cancel();
```

## 4. 属性

> [!TIP] "OHOS 支持"列为 yes 表示 OHOS 平台支持该属性；no 则表示不支持；partially 表示部分支持。

| 名称                              | 返回值       | 描述                                                  | 类型     | OHOS 支持 |
| --------------------------------- | ------------ | ------------------------------------------------------------ | -------- | ------------ |
| onLocationChanged | Stream<[LocationData](#LocationData)> | 位置变更事件流。订阅以接收持续的位置更新。 | property | yes          |
| instance | Location | 静态单例实例。可设置为自定义实例用于测试。 | property | yes          |

## 5. 遗留问题

- **requestService()**：在 OHOS 平台上，该方法返回 `PlatformException`（错误码 `SERVICE_STATUS_DISABLED`），因为 OpenHarmony 不提供弹出启用定位对话框的系统 API。用户需手动前往系统设置启用定位。
- **LocationData 字段**：部分字段（`verticalAccuracy`、`speedAccuracy`、`isMock`、`headingAccuracy`、`elapsedRealtimeNanos`、`elapsedRealtimeUncertaintyNanos`、`satelliteNumber`、`provider`）在 OHOS `geoLocationManager.Location` API 中不可用，将返回 `null`。
- **PermissionStatus.deniedForever**：OHOS 平台无法区分"denied"（用户仍可再次请求）和"deniedForever"（用户勾选了"不再询问"）。在 OHOS 上，`requestPermission()` 始终返回 `denied`(0) 而非 `deniedForever`(2)，因为系统缺少 `shouldShowRequestPermissionRationale` 等效 API。

## 6. 其余

- **上游仓库**：[location on pub.dev](https://pub.dev/packages/location)
- **问题追踪**：[GitHub Issues](https://github.com/Lyokone/flutterlocation/issues)
- **OpenHarmony/ohos**：[ohos服务开发指导]

## 7. 开源协议

本项目基于 [MIT开源协议](https://gitcode.com/CPF-Flutter/flutter_location/blob/master/LICENSE) ，请自由地享受和参与开源。

> 模板版本: v0.0.1
