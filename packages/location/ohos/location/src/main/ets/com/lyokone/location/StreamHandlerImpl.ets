import { BinaryMessenger, EventChannel, Log } from '@ohos/flutter_ohos';
import { EventSink, StreamHandler } from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';
import { FlutterLocation } from './FlutterLocation';

const TAG = "StreamHandlerImpl";
const STREAM_CHANNEL_NAME = "lyokone/locationstream";

export default class StreamHandlerImpl implements StreamHandler {
  private location: FlutterLocation | null = null;
  private channel: EventChannel | null = null;

  setLocation(location: FlutterLocation | null) {
    this.location = location;
  }

  startListening(messenger: BinaryMessenger) {
    if (this.channel != null) {
      this.stopListening();
    }
    this.channel = new EventChannel(messenger, STREAM_CHANNEL_NAME);
    this.channel.setStreamHandler(this);
  }

  stopListening() {
    if (this.channel == null) {
      return;
    }
    this.channel.setStreamHandler(null);
    this.channel = null;
  }

  onListen(args: ESObject, events: EventSink): void {
    Log.i(TAG, "onListen");
    if (this.location == null || this.location.ability == null) {
      return;
    }
    this.location.events = events;
    if (!this.location.checkPermissions()) {
      this.location.requestPermissions();
    } else if (!this.location.checkAccuracyPermissions()) {
      events.error("PERMISSION_DENIED", "Location permission denied", null);
      this.location.events = null;
    } else {
      this.location.startRequestingLocation();
    }
  }

  onCancel(args: ESObject): void {
    Log.i(TAG, "onCancel");
    if (this.location) {
      this.location.events = null;
    }
  }
}