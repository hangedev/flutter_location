import { BinaryMessenger, Log, MethodCall } from '@ohos/flutter_ohos'
import MethodChannel, {
  MethodCallHandler,
  MethodResult
} from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel'
import { FlutterLocation } from './FlutterLocation';

const TAG = "MethodCallHandlerImpl";
const METHOD_CHANNEL_NAME = "lyokone/location";

export default class MethodCallHandlerImpl implements MethodCallHandler {
  private location: FlutterLocation | null = null;
  private channel: MethodChannel | null = null;

  setLocation(location: FlutterLocation | null) {
    this.location = location;
  }

  startListening(messenger: BinaryMessenger) {
    if (this.channel != null) {
      this.stopListening();
    }
    this.channel = new MethodChannel(messenger, METHOD_CHANNEL_NAME);
    this.channel.setMethodCallHandler(this);
  }

  stopListening() {
    if (this.channel == null) {
      return;
    }
    this.channel.setMethodCallHandler(null);
    this.channel = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    Log.i(TAG, "onMethodCall step in");
    const method = call.method;
    Log.i(TAG, "Received" + method + "message.");
    switch (method) {
      case "changeSettings":
        this.onChangeSettings(call, result);
        break;
      case "getLocation":
        this.onGetLocation(result);
        break;
      case "hasPermission":
        this.onHasPermission(result);
        break;
      case "requestPermission":
        this.onRequestPermission(result);
        break;
      case "serviceEnabled":
        this.onServiceEnabled(result);
        break;
      case "requestService":
        this.location?.requestService(result);
        break;
      case "isBackgroundModeEnabled":
        this.isBackgroundModeEnabled(result);
        break;
      case "enableBackgroundMode":
        this.enableBackgroundMode(call, result);
        break;
      case "changeNotificationOptions":
        this.onChangeNotificationOptions(call, result);
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  private onHasPermission(result: MethodResult) {
    if (this.location?.checkPermissions()) {
      result.success(1);
    } else {
      result.success(0);
    }
  }

  private onRequestPermission(result: MethodResult) {
    if (this.location) {
      this.location.result = result;
      this.location.requestPermissions();
    }
  }

  private async onGetLocation(result: MethodResult): Promise<void> {
    if (this.location) {
      this.location.getLocationResult = result;
      if (!this.location.checkPermissions()) {
        this.location.requestPermissions();
      } else if (!this.location.checkAccuracyPermissions()) {
        result.error("PERMISSION_DENIED", "Location permission denied", null);
        this.location.getLocationResult = null;
      } else {
        this.location.startRequestingLocation();
      }
    }
  }

  onChangeSettings(call: MethodCall, result: MethodResult) {
    if (this.location) {
      try {
        this.location.changeSettings(
          call.argument('accuracy'),
          call.argument('interval'),
          call.argument('distanceFilter'),
          call.argument('distanceInterval'),
          call.argument('scenario')
        )
        result.success(1);
      } catch (err) {
        result.error("CHANGE_SETTINGS_ERROR",
          "An unexcepted error happened during location settings change:" + JSON.stringify(err), null);
      }
    }
  }

  onServiceEnabled(result: MethodResult) {
    if (this.location) {
      try {
        result.success(this.location.checkServiceEnabled() ? 1 : 0)
      } catch (err) {
        result.error("SERVICE_STATUS_ERROR", "Location service status couldn't be determined", null);
      }
    }
  }

  isBackgroundModeEnabled(result: MethodResult) {
    if (this.location) {
      result.success(this.location.isInForegroundMode() ? 1 : 0);
    } else {
      result.success(0);
    }
  }

  enableBackgroundMode(call: MethodCall, result: MethodResult) {
    let enable: boolean = call.argument("enable");
    if (this.location != null && enable != null) {
      if (this.location.checkPermissions()) {
        if (enable) {
          this.location.enableBackgroundMode();
          result.success(1);
        } else {
          this.location.disableBackgroundMode();
          result.success(0);
        }
      } else {
        result.error("PERMISSION_DENIED", "Location permission denied", null);
      }
    } else {
      result.success(0);
    }
  }

  onChangeNotificationOptions(call: MethodCall, result: MethodResult) {
    Log.i(TAG, 'Method onChangeNotificationOptions not implemented.');
  }
}