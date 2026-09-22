///|
test "common key codes match the Linux ABI" {
  let codes = [
    1, 2, 11, 14, 15, 16, 25, 28, 29, 30, 38, 42, 44, 50, 54, 56, 57, 58, 59, 68,
    87, 88, 97, 100, 103, 105, 106, 108, 0x110, 0x111, 0x112,
  ]
  for code in codes {
    assert_eq(@codes.KeyCode::from_linux(code).to_linux(), code)
  }
  assert_eq(@codes.KeyCode::Unknown(777).to_linux(), 777)
}

///|
test "event families and axes preserve unknown Linux values" {
  for value in [0, 1, 2, 3, 4, 5, 17, 20, 99] {
    assert_eq(@codes.EventType::from_linux(value).to_linux(), value)
  }
  for value in [0, 1, 6, 8, 99] {
    assert_eq(@codes.RelativeAxis::from_linux(value).to_linux(), value)
  }
  for value in [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 16, 17, 99] {
    assert_eq(@codes.AbsoluteAxis::from_linux(value).to_linux(), value)
  }
  for value in [0, 1, 2, 3, 99] {
    assert_eq(@codes.SyncCode::from_linux(value).to_linux(), value)
  }
}
