///|
fn key_packet(entries : Array[(Int, Int)]) -> @event.SyncedPacket {
  let events : Array[@event.InputEvent] = []
  for (code, value) in entries {
    events.push(
      @event.decode({
        timestamp: { sec: 0L, usec: 0L, },
        event_type: 1,
        code,
        value,
      }),
    )
  }
  Events({ timestamp: { sec: 0L, usec: 0L, }, events, })
}

///|
test "unmodified keys pass through in complete frames" {
  let mapper = LayerRemapper::new()
  let down = mapper.process(key_packet([(35, 1)]))
  assert_eq(down.length(), 2)
  assert_eq(down[0].code, 35)
  assert_eq(down[0].value, 1)
  assert_eq(down[1].event_type, 0)
  let up = mapper.process(key_packet([(35, 0)]))
  assert_eq(up.length(), 2)
  assert_eq(up[0].code, 35)
  assert_eq(up[0].value, 0)
}

///|
test "CapsLock H becomes Left and holds its mapping until release" {
  let mapper = LayerRemapper::new()
  assert_eq(mapper.process(key_packet([(58, 1)])).length(), 0)
  let left = mapper.process(key_packet([(35, 1)]))
  assert_eq(left.length(), 2)
  assert_eq(left[0].code, 105)
  assert_eq(left[0].value, 1)
  assert_eq(mapper.process(key_packet([(58, 0)])).length(), 0)
  let released = mapper.process(key_packet([(35, 0)]))
  assert_eq(released[0].code, 105)
  assert_eq(released[0].value, 0)
  assert_eq(released[1].event_type, 0)
}

///|
test "layer maps all H J K L directions and repeats" {
  let mapper = LayerRemapper::new()
  ignore(mapper.process(key_packet([(58, 1)])))
  let arrows = mapper.process(key_packet([(35, 1), (36, 1), (37, 1), (38, 1)]))
  assert_eq(arrows.length(), 5)
  assert_eq(arrows[0].code, 105)
  assert_eq(arrows[1].code, 108)
  assert_eq(arrows[2].code, 103)
  assert_eq(arrows[3].code, 106)
  assert_eq(arrows[4].event_type, 0)
  let repeated = mapper.process(key_packet([(35, 2)]))
  assert_eq(repeated[0].code, 105)
  assert_eq(repeated[0].value, 2)
}

///|
test "overlapping physical and mapped keys preserve one output hold" {
  let mapper = LayerRemapper::new()
  ignore(mapper.process(key_packet([(105, 1), (58, 1)])))
  assert_eq(mapper.process(key_packet([(35, 1)])).length(), 0)
  assert_eq(mapper.process(key_packet([(105, 0)])).length(), 0)
  let release = mapper.process(key_packet([(35, 0)]))
  assert_eq(release.length(), 2)
  assert_eq(release[0].code, 105)
  assert_eq(release[0].value, 0)
}

///|
test "recovery releases lost keys and maps newly found keys" {
  let mapper = LayerRemapper::new()
  ignore(mapper.process(key_packet([(35, 1)])))
  let recovered = mapper.process(
    Recovered({ pressed_keys: [H, CapsLock, J], absolute_axes: [], }),
  )
  assert_eq(recovered.length(), 2)
  assert_eq(recovered[0].code, 108)
  assert_eq(recovered[0].value, 1)
  assert_eq(recovered[1].event_type, 0)
  let cleared = mapper.process(
    Recovered({ pressed_keys: [CapsLock], absolute_axes: [], }),
  )
  assert_eq(cleared.length(), 3)
  assert_eq(cleared[0].code, 35)
  assert_eq(cleared[0].value, 0)
  assert_eq(cleared[1].code, 108)
  assert_eq(cleared[1].value, 0)
  assert_eq(cleared[2].event_type, 0)
}

///|
test "shutdown releases every held output key once" {
  let mapper = LayerRemapper::new()
  ignore(mapper.process(key_packet([(58, 1), (35, 1), (36, 1)])))
  let release = mapper.release_all()
  assert_eq(release.length(), 3)
  assert_eq(release[0].code, 105)
  assert_eq(release[0].value, 0)
  assert_eq(release[1].code, 108)
  assert_eq(release[1].value, 0)
  assert_eq(release[2].event_type, 0)
  assert_eq(mapper.release_all().length(), 0)
}

///|
test "ordinary held key keeps its identity while CapsLock changes" {
  let mapper = LayerRemapper::new()
  let first = mapper.process(key_packet([(35, 1)]))
  assert_eq(first[0].code, 35)
  assert_eq(first[0].value, 1)
  assert_eq(mapper.process(key_packet([(58, 1)])).length(), 0)
  let repeated = mapper.process(key_packet([(35, 2)]))
  assert_eq(repeated[0].code, 35)
  assert_eq(repeated[0].value, 2)
  let released = mapper.process(key_packet([(35, 0)]))
  assert_eq(released[0].code, 35)
  assert_eq(released[0].value, 0)
  let second = mapper.process(key_packet([(35, 1)]))
  assert_eq(second[0].code, 105)
  assert_eq(second[0].value, 1)
}

///|
test "CapsLock alone never reaches output, including repeats" {
  let mapper = LayerRemapper::new()
  assert_eq(mapper.process(key_packet([(58, 1)])).length(), 0)
  assert_eq(mapper.process(key_packet([(58, 2)])).length(), 0)
  assert_eq(mapper.process(key_packet([(58, 1)])).length(), 0)
  assert_eq(mapper.process(key_packet([(58, 0)])).length(), 0)
  assert_eq(mapper.release_all().length(), 0)
}

///|
test "repeat without a prior press is ignored" {
  let mapper = LayerRemapper::new()
  assert_eq(mapper.process(key_packet([(35, 2)])).length(), 0)
  ignore(mapper.process(key_packet([(58, 1)])))
  assert_eq(mapper.process(key_packet([(35, 2)])).length(), 0)
  let press = mapper.process(key_packet([(35, 1)]))
  assert_eq(press[0].code, 105)
  let repeat = mapper.process(key_packet([(35, 2)]))
  assert_eq(repeat.length(), 2)
  assert_eq(repeat[0].code, 105)
  assert_eq(repeat[0].value, 2)
}

///|
test "duplicate presses and releases do not unbalance key holds" {
  let mapper = LayerRemapper::new()
  ignore(mapper.process(key_packet([(58, 1)])))
  let first = mapper.process(key_packet([(35, 1)]))
  assert_eq(first.length(), 2)
  assert_eq(mapper.process(key_packet([(35, 1)])).length(), 0)
  let release = mapper.process(key_packet([(35, 0)]))
  assert_eq(release.length(), 2)
  assert_eq(release[0].code, 105)
  assert_eq(release[0].value, 0)
  assert_eq(mapper.process(key_packet([(35, 0)])).length(), 0)
  assert_eq(mapper.release_all().length(), 0)
}

///|
test "press and release in one source frame retain order" {
  let mapper = LayerRemapper::new()
  let outputs = mapper.process(key_packet([(58, 1), (35, 1), (35, 0)]))
  assert_eq(outputs.length(), 3)
  assert_eq(outputs[0].event_type, 1)
  assert_eq(outputs[0].code, 105)
  assert_eq(outputs[0].value, 1)
  assert_eq(outputs[1].event_type, 1)
  assert_eq(outputs[1].code, 105)
  assert_eq(outputs[1].value, 0)
  assert_eq(outputs[2].event_type, 0)
  assert_eq(mapper.release_all().length(), 0)
}

///|
test "recovery adds a newly held mapped key and later releases it" {
  let mapper = LayerRemapper::new()
  let recovered = mapper.process(
    Recovered({ pressed_keys: [CapsLock, H], absolute_axes: [], }),
  )
  assert_eq(recovered.length(), 2)
  assert_eq(recovered[0].code, 105)
  assert_eq(recovered[0].value, 1)
  let after_caps = mapper.process(
    Recovered({ pressed_keys: [H], absolute_axes: [], }),
  )
  assert_eq(after_caps.length(), 0)
  let release = mapper.process(key_packet([(35, 0)]))
  assert_eq(release.length(), 2)
  assert_eq(release[0].code, 105)
  assert_eq(release[0].value, 0)
}

///|
test "recovery with overlapping mapped and physical arrows emits one hold" {
  let mapper = LayerRemapper::new()
  let recovered = mapper.process(
    Recovered({ pressed_keys: [CapsLock, H, Left], absolute_axes: [], }),
  )
  assert_eq(recovered.length(), 2)
  assert_eq(recovered[0].code, 105)
  assert_eq(recovered[0].value, 1)
  assert_eq(mapper.process(key_packet([(105, 0)])).length(), 0)
  let final_release = mapper.process(key_packet([(35, 0)]))
  assert_eq(final_release.length(), 2)
  assert_eq(final_release[0].code, 105)
  assert_eq(final_release[0].value, 0)
}

///|
test "shutdown after recovery deduplicates overlapping output keys" {
  let mapper = LayerRemapper::new()
  ignore(mapper.process(key_packet([(58, 1), (35, 1), (105, 1)])))
  assert_eq(
    mapper
    .process(
      Recovered({ pressed_keys: [CapsLock, H, Left], absolute_axes: [], }),
    )
    .length(),
    0,
  )
  let release = mapper.release_all()
  assert_eq(release.length(), 2)
  assert_eq(release[0].code, 105)
  assert_eq(release[0].value, 0)
  assert_eq(release[1].event_type, 0)
  assert_eq(mapper.release_all().length(), 0)
}

///|
test "recovery releases disappeared mapped keys before pressing new ones" {
  let mapper = LayerRemapper::new()
  ignore(mapper.process(key_packet([(58, 1), (35, 1)])))
  let transition = mapper.process(
    Recovered({ pressed_keys: [CapsLock, J], absolute_axes: [], }),
  )
  assert_eq(transition.length(), 3)
  assert_eq(transition[0].code, 105)
  assert_eq(transition[0].value, 0)
  assert_eq(transition[1].code, 108)
  assert_eq(transition[1].value, 1)
  assert_eq(transition[2].event_type, 0)
  let release = mapper.release_all()
  assert_eq(release.length(), 2)
  assert_eq(release[0].code, 108)
  assert_eq(release[0].value, 0)
}

///|
test "a recovered empty state clears modifier and all output holds" {
  let mapper = LayerRemapper::new()
  ignore(mapper.process(key_packet([(58, 1), (35, 1), (36, 1)])))
  let reset = mapper.process(
    Recovered({ pressed_keys: [], absolute_axes: [], }),
  )
  assert_eq(reset.length(), 3)
  assert_eq(reset[0].code, 105)
  assert_eq(reset[0].value, 0)
  assert_eq(reset[1].code, 108)
  assert_eq(reset[1].value, 0)
  assert_eq(reset[2].event_type, 0)
  let ordinary = mapper.process(key_packet([(35, 1)]))
  assert_eq(ordinary[0].code, 35)
  assert_eq(ordinary[0].value, 1)
}

///|
test "physical arrow passthrough works without the layer" {
  let mapper = LayerRemapper::new()
  let press = mapper.process(key_packet([(105, 1)]))
  assert_eq(press.length(), 2)
  assert_eq(press[0].code, 105)
  assert_eq(press[0].value, 1)
  assert_eq(press[1].event_type, 0)
  let repeat = mapper.process(key_packet([(105, 2)]))
  assert_eq(repeat[0].code, 105)
  assert_eq(repeat[0].value, 2)
  let release = mapper.process(key_packet([(105, 0)]))
  assert_eq(release[0].code, 105)
  assert_eq(release[0].value, 0)
}
