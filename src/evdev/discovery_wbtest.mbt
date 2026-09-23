///|
test "device discovery filters names and sorts event numbers naturally" {
  let entries = [
    "mouse0", "event10", "event2", "event1", "event", "event-1", "event3backup",
    "prefix-event4",
  ]
  debug_inspect(
    sorted_event_paths("/dev/input", entries[:]),
    content="[\"/dev/input/event1\", \"/dev/input/event2\", \"/dev/input/event10\"]",
  )
}

///|
test "device discovery joins directories with or without trailing slash" {
  let entries = ["event0"]
  debug_inspect(
    sorted_event_paths("/dev/input/", entries[:]),
    content="[\"/dev/input/event0\"]",
  )
}

///|
test "device probing retains errors and continues with later paths" {
  let paths = ["event0", "event1", "event2"]
  let results = collect_probe_results(paths, fake_probe)
  debug_inspect(results[0], content="Ok(\"ok:event0\")")
  debug_inspect(results[1], content="Err(PermissionDenied(path=\"event1\"))")
  debug_inspect(results[2], content="Ok(\"ok:event2\")")
}

///|
fn fake_probe(path : String) -> String raise @errors.InputError {
  if path == "event1" {
    raise PermissionDenied(path~)
  }
  "ok:\{path}"
}
