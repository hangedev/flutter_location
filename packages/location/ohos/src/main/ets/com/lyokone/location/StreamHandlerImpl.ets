/*
 * Copyright (C) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { BinaryMessenger, EventChannel, Log } from '@ohos/flutter_ohos';
import { EventSink, StreamHandler } from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';
import { FlutterLocation } from './FlutterLocation';

const TAG = 'StreamHandlerImpl';
const STREAM_CHANNEL_NAME = 'lyokone/locationstream';

/**
 * EventChannel stream handler for location updates.
 * Manages the onLocationChanged event stream.
 */
export default class StreamHandlerImpl implements StreamHandler {
  private location: FlutterLocation | null = null;
  private channel: EventChannel | null = null;

  /**
   * Set the FlutterLocation instance.
   * @param location - FlutterLocation instance or null to clear
   */
  setLocation(location: FlutterLocation | null): void {
    this.location = location;
  }

  /**
   * Start listening for EventChannel stream events.
   * @param messenger - BinaryMessenger for channel communication
   */
  startListening(messenger: BinaryMessenger): void {
    if (this.channel != null) {
      this.stopListening();
    }
    this.channel = new EventChannel(messenger, STREAM_CHANNEL_NAME);
    this.channel.setStreamHandler(this);
  }

  /**
   * Stop listening for EventChannel stream events.
   */
  stopListening(): void {
    if (this.channel == null) {
      return;
    }
    this.channel.setStreamHandler(null);
    this.channel = null;
  }

  /**
   * Handle stream listen event from Flutter.
   * @param args - Arguments from Flutter
   * @param events - EventSink for sending location data to Flutter
   */
  onListen(args: ESObject, events: EventSink): void {
    Log.i(TAG, 'onListen');
    try {
      if (this.location == null || this.location.ability == null) {
        events.error('NOACTIVITY',
          'Location plugin not initialized or ability context is not available', null);
        return;
      }
      this.location.events = events;
      if (!this.location.checkPermissions()) {
        this.location.requestPermissions();
      } else {
        this.location.startRequestingLocation();
      }
    } catch (err) {
      Log.e(TAG, 'onListen error: ' + JSON.stringify(err));
      events.error('STREAM_LISTEN_ERROR',
        'Failed to start location stream: ' + JSON.stringify(err), null);
    }
  }

  /**
   * Handle stream cancel event from Flutter.
   * Actively stops the location subscription.
   * @param args - Arguments from Flutter
   */
  onCancel(args: ESObject): void {
    Log.i(TAG, 'onCancel');
    try {
      if (this.location) {
        // Actively stop the location subscription
        this.location.stopLocationSubscription();
        this.location.events = null;
      }
    } catch (err) {
      Log.e(TAG, 'onCancel error: ' + JSON.stringify(err));
    }
  }
}
