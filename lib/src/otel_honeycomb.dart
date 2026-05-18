// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_honeycomb_suppression.dart';

const _tracerName = 'dartastic_otel_libs_honeycomb';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Wraps a Honeycomb Events API batch send in a PRODUCER span.
Future<T> tracedHoneycombSend<T>({
  required String dataset,
  required Future<T> Function() invoke,
  int? eventCount,
  int? payloadSize,
  String? team,
}) async {
  if (honeycombInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'messaging.system': 'honeycomb',
    'messaging.operation': 'publish',
    'messaging.destination.name': dataset,
    'honeycomb.dataset': dataset,
  };
  if (eventCount != null) m['messaging.batch.message_count'] = eventCount;
  if (payloadSize != null) m['messaging.message.body.size'] = payloadSize;
  if (team != null) m['honeycomb.team'] = team;

  final span = _tracer().startSpan(
    'honeycomb send $dataset',
    kind: SpanKind.producer,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
