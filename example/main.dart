// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_honeycomb/otel_honeycomb.dart';

/// Traces Honeycomb Events calls with OpenTelemetry.
///
/// `otel_honeycomb` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Honeycomb Events call in
/// [tracedHoneycombSend]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'honeycomb-example');

  // Wraps a Honeycomb Events API batch send in a PRODUCER span.
  final honeycombSendId = await tracedHoneycombSend<String>(
    dataset: 'example',
    eventCount: 3,
    payloadSize: 512,
    team: 'example',
    invoke: () async {
      // Make the Honeycomb Events call here, then report what it returned.
      return 'honeycomb_8f3a2c';
    },
  );
  OTelLog.info('tracedHoneycombSend returned $honeycombSendId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutHoneycombInstrumentationAsync.
  await runWithoutHoneycombInstrumentationAsync(
    () => tracedHoneycombSend<String>(
      dataset: 'example',
      eventCount: 3,
      payloadSize: 512,
      team: 'example',
      invoke: () async {
        return 'honeycomb_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
