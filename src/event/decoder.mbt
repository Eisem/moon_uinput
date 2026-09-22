///|
/// Decode a raw Linux event into the typed MoonInput event model.
pub fn decode(raw : RawEvent) -> InputEvent {
  match @codes.EventType::from_linux(raw.event_type) {
    Key =>
      match KeyState::from_linux(raw.value) {
        Some(state) =>
          Key({
            timestamp: raw.timestamp,
            code: @codes.KeyCode::from_linux(raw.code),
            state,
          })
        None => Unknown(raw)
      }
    Relative =>
      Relative({
        timestamp: raw.timestamp,
        axis: @codes.RelativeAxis::from_linux(raw.code),
        value: raw.value,
      })
    Absolute =>
      Absolute({
        timestamp: raw.timestamp,
        axis: @codes.AbsoluteAxis::from_linux(raw.code),
        value: raw.value,
      })
    Sync =>
      Sync({
        timestamp: raw.timestamp,
        code: @codes.SyncCode::from_linux(raw.code),
      })
    Switch =>
      Switch({
        timestamp: raw.timestamp,
        code: @codes.SwitchCode::from_linux(raw.code),
        enabled: raw.value != 0,
      })
    Led =>
      Led({
        timestamp: raw.timestamp,
        code: @codes.LedCode::from_linux(raw.code),
        enabled: raw.value != 0,
      })
    Misc => Misc(raw)
    Repeat | Unknown(_) => Unknown(raw)
  }
}
