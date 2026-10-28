// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_honeycomb/otel_honeycomb.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_honeycomb-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('send records PRODUCER span', () async {
    await tracedHoneycombSend<String>(
      dataset: 'orders',
      eventCount: 100,
      team: 'acme',
      invoke: () async => 'ok',
    );
    final a = attrsOf(spans.findSpanByName('honeycomb send orders')!);
    expect(a['messaging.system'], 'honeycomb');
    expect(a['honeycomb.dataset'], 'orders');
    expect(a['messaging.batch.message_count'], 100);
    expect(a['honeycomb.team'], 'acme');
  });

  test('suppression skips spans', () async {
    await runWithoutHoneycombInstrumentationAsync(() async {
      await tracedHoneycombSend<String>(
        dataset: 'd',
        invoke: () async => 'ok',
      );
    });
    expect(spans.findSpansStartingWith('honeycomb '), isEmpty);
  });
}
