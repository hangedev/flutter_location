<p align="center">
  <h1 align="center"> <code>location</code> </h1>
</p>


本项目基于 [location@5.0.3](https://pub.dev/packages/location/versions/5.0.3) 开发。

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
      path: "./packages/location"
```

执行命令

```bash
flutter pub get
```

<!-- tabs:end -->

### 1.2 使用案例

使用案例详见 [example](./packages/location/example)

## 2. 约束与限制

### 2.1 兼容性

在以下版本中已测试通过

1. Flutter: 3.7.12-ohos-1.0.6; SDK: 5.0.0(12); IDE: DevEco Studio: 5.0.13.200; ROM: 5.1.0.120 SP3;

## 3. API

> [!TIP] "ohos Support"列为 yes 表示 ohos 平台支持该属性；no 则表示不支持；partially 表示部分支持。使用方法跨平台一致，效果对标 iOS 或 Android 的效果。

| Name                | return          | Description                                                                                                             | Type     | ohos Support |
|---------------------|-------------------------------------------------------------------------------------------------------------------------|----------|-------------------|-------------------|
| changeSettings({[LocationAccuracy](#LocationAccuracy)? accuracy = [LocationAccuracy](#LocationAccuracy).high,[LocationScenario](#LocationScenario)? scenario = [LocationScenario](#LocationScenario).unset,int? interval = 1000,double? distanceFilter = 0,double? distanceInterval = 0,})                                 | Future<bool> | 修改位置请求的设置。 | function | yes          |
| isBackgroundModeEnabled() | Future<bool>                                                  | 检查服务是否在后台模式中启用。 | function | yes          |
| enableBackgroundMode({bool? enable = true})                                 | Future<bool> | 启用或禁用后台模式中的服务。 | function | yes          |
| getLocation()                                 | Future<[LocationData](#LocationData)> | 获取用户的当前位置。 | function | yes          |
| hasPermission()                                 | Future<[PermissionStatus](#PermissionStatus)> | 检查应用是否拥有访问位置的权限。 | function | yes          |
| requestPermission()                                 | Future<[PermissionStatus](#PermissionStatus)> | 请求访问位置的权限。 | function | yes          |
| serviceEnabled()                                 | Future<bool> | 检查位置服务是否已启用。 | function | yes          |
| requestService()                                 | Future<bool> | 请求激活位置服务。 | function | yes          |

### 参数
| Name                              | return       | Description                                                  | Type     | ohos Support |
| --------------------------------- | ------------ | ------------------------------------------------------------ | -------- | ------------ |
| interval |  | 控制位置更新的时间间隔。 | int | yes          |
| distanceFilter |  | 控制位置更新的距离阈值。 | double | yes          |
| distanceInterval |  | 控制位置更新的距离间隔。 | double | yes          |
| enable |  | 控制是否启用后台模式服务。 | bool | yes          |
| [LocationAccuracy](#LocationAccuracy) |  | 定位的精度。较低的精度会提供更长的电池续航时间。 | enum | yes          |
| [LocationScenario](#LocationScenario) |  | 它用于在鸿蒙操作系统（HarmonyOS）中定义定位场景模式，允许系统根据不同的场景（例如高精度、低功耗等）自动优化定位策略，以平衡精度和功耗。 | enum | yes          |
| [LocationData](#LocationData) |  | 表示现实世界中的一个地理位置。 | class | yes          |
| [PermissionStatus](#PermissionStatus) |  | 使用定位服务的权限请求的状态。 | enum | yes          |

### LocationAccuracy
| Name                              | return       | Description                                                  | Type     | ohos Support |
| --------------------------------- | ------------ | ------------------------------------------------------------ | -------- | ------------ |
| powerSave |  | 请求尽可能高的精度，且不增加额外的功耗。在OpenHarmony系统中，这等同于FIRST_FIX模式。 | enum | yes          |
| low |  | 请求“城市”级别的精度。在 OpenHarmony 中，这等同于 LOW_POWER 模式。 | enum | yes          |
| balanced |  | 请求“街区”级别的精度。 | enum | yes          |
| high |  | 请求最精确的定位信息。在 OpenHarmony 中，这等同于 ACCURACY 模式。 | enum | yes          |
| navigation |  | 请求用于导航的定位信息（仅影响iOS）。 | enum | yes          |
| reduced |  | 在 iOS 14.0 及以上版本中，这对应于 kCLLocationAccuracyReduced。 | enum | yes          |
| unset |  | 在 OpenHarmony 中，这等同于 UNSET（仅影响 OpenHarmony）。 | enum | yes          |

### LocationScenario
| Name                              | return       | Description                                                  | Type     | ohos Support |
| --------------------------------- | ------------ | ------------------------------------------------------------ | -------- | ------------ |
| unset |  | 请求用于默认场景的定位信息（仅影响 OpenHarmony）。 | enum | yes          |
| navigation |  | 请求用于导航场景的定位信息（仅影响OpenHarmony）。 | enum | yes          |
| trajectoryTracking |  | 请求用于默认场景的定位信息（仅适用于OpenHarmony）。 | enum | yes          |
| carHailing |  | 请求用于网约车场景的定位信息（仅适用于 OpenHarmony）。 | enum | yes          |
| dailyLifeService |  | 请求用于日常生活服务场景的定位信息（仅适用于 OpenHarmony）。 | enum | yes          |
| noPower |  |  请求用于无功耗场景的定位信息（仅适用于OpenHarmony）。 | enum | yes          |

### LocationData
| Name                              | return       | Description                                                  | Type     | ohos Support |
| --------------------------------- | ------------ | ------------------------------------------------------------ | -------- | ------------ |
| latitude |  | 纬度，以度为单位。 | double | yes          |
| longitude |  | 经度，以度为单位。 | double | yes          |
| accuracy |  | 此位置的估算水平精度，以米为单位的半径值。 | double | yes          |
| verticalAccuracy |  | 海拔的估算垂直精度，以米为单位。 | double | yes          |
| altitude |  | 以米为单位，高于WGS 84参考椭球面的高度。该数据来源于GPS信息。 | double | yes          |
| speed |  | 以米/秒为单位。 | double | yes          |
| speedAccuracy |  | 以米/秒为单位。 | double | yes          |
| heading |  | 航向是此设备的水平行进方向，以度为单位。 | double | yes          |
| time |  | 定位数据的时间戳。 | double | yes          |
| isMock |  | 该位置是否是模拟的。 | bool | yes          |
| headingAccuracy |  | 获取此位置的估算方位精度，以度为单位。 | double | yes          |
| elapsedRealtimeNanos |  | 返回此定位的时间，以系统启动后的流逝实时为准。 | double | yes          |
| elapsedRealtimeUncertaintyNanos |  | 获取对 ElapsedRealtimeNanos 时间戳对齐精度 的相对估算值。 | double | yes          |
| satelliteNumber |  | 用于确定定位的卫星数量。 | int | yes          |
| provider |  | 生成此定位信息的提供者名称。 | String | yes          |

### PermissionStatus
| Name                              | return       | Description                                                  | Type     | ohos Support |
| --------------------------------- | ------------ | ------------------------------------------------------------ | -------- | ------------ |
| granted |  | 已授予使用定位服务的高精度权限。 | enum | yes          |
| grantedLimited |  | 权限已被授予，但仅限于低精度。仅在 iOS 14 及以上版本有效。 | enum | yes          |
| denied |  | 用户拒绝了使用定位服务的权限。在iOS上可能被永久拒绝。 | enum | yes          |
| deniedForever |  | 用户永久拒绝了使用定位服务的权限。在请求权限时不会显示任何对话框。 | enum | yes          |

## 4. 属性

> [!TIP] "ohos Support"列为 yes 表示 ohos 平台支持该属性；no 则表示不支持；partially 表示部分支持。使用方法跨平台一致，效果对标 iOS 或 Android 的效果。

## 5. 遗留问题

无

## 6. 其他

## 7. 开源协议

本项目基于 [MIT开源协议](https://gitcode.com/CPF-Flutter/flutter_location/blob/master/LICENSE) ，请自由地享受和参与开源。



> 模板版本: v0.0.1