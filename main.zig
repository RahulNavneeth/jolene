const std = @import ("std");

const assert = std.debug.assert;
const print = std.debug.print;

const echoes = @cImport ({
    @cInclude ("IO.h");
});

const SAMPLE : u32 = 48000;
const PITCH_STANDARD : f32 = 440;
const NOTES = struct {
    pub const C = 3;
    pub const C_SHARP = 4; pub const D_FLAT = 4;
    pub const D = 5;
    pub const D_SHARP = 6; pub const E_FLAT = 6;
    pub const E = 7;
    pub const F = 8;
    pub const F_SHARP = 9; pub const G_FLAT = 9;
    pub const G = 10;
    pub const G_SHARP = 11; pub const A_FLAT = 11;
    pub const A = 0;
    pub const A_SHARP = 1; pub const B_FLAT = 1;
    pub const B = 2;
};
const AMPLITUDE: f32 = 0.1;
const PHASE: i4 = 0;
const TIME_PER_NOTE: f32 = 1;
const LOCAL_SAMPLE: u32 = @trunc (SAMPLE * TIME_PER_NOTE);

fn play (samples: [*c]f32) void {
    const sample = echoes.sample {
        .sample = samples,
        .sample_count = LOCAL_SAMPLE,
        .current_position = 0,
        .completed = false,
    };
    const feedback: c_int = echoes.write_audio (sample);
    assert (feedback == 0);
    std.Thread.sleep(TIME_PER_NOTE * 1000 * std.time.ns_per_ms);
}

fn get_frequency_from_note (note: i8, octave: i8) f32 {
    const oct = if (note>2) octave - 1 else octave;
    const local_oct = ((4 - oct) * -1);
    const nxlc: f32 = @floatFromInt ((12*local_oct) + note);
    return (PITCH_STANDARD * std.math.pow (f32,  2, (nxlc / 12.0)));
}

// TODO: Not quite there!
fn envelope (time: f32, attack: f32, release: f32, duration: f32) f32 {
    if (time <= 0.0) return 0.0;
    if (time < attack) {
        const x = time / attack;
        return AMPLITUDE * (x * x * (3.0 - 2.0 * x));
    }
    if (time < duration - release) return AMPLITUDE;
    if (time < duration) {
        const x = (duration - time) / release;
        return AMPLITUDE * (x * x * (3.0 - 2.0 * x));
    }
    return 0.0;
}
fn sin_wave (frequency: f32, time: f32) f32 {
    const ang_freq = 2 * std.math.pi * frequency;
    return envelope (time, 0.02, 0.20, TIME_PER_NOTE) * std.math.sin (ang_freq * time + PHASE);
}

fn make_notes (notes: []const i8) [*c]f32 {
    var samples: [LOCAL_SAMPLE]f32 = .{0} ** LOCAL_SAMPLE;
    for (notes) |note| {
        const lf = get_frequency_from_note (note, 4);
        for (&samples, 0..) |*sample, t| {
            sample.* += sin_wave(lf, @as(f32, @floatFromInt(t)) / SAMPLE);
        }
    }
   return &samples;
}

pub fn main () !void {
    const res: c_int = echoes.init_audio_driver ("Jolene!!!".ptr);
    defer echoes.cleanup_audio_driver ();
    assert (res == 0);

    // const impl: [*c]echoes.DriverIMPL = echoes.get_driver_impl ();
    // const sound_check = impl.*.sound_check orelse unreachable;
    // sound_check ();
                                                       
    play(make_notes(&.{ NOTES.C, NOTES.G }));
    play(make_notes(&.{ NOTES.A, NOTES.C, NOTES.E }));
    play(make_notes(&.{ NOTES.F, NOTES.A, NOTES.C, NOTES.E }));
    play(make_notes(&.{ NOTES.G, NOTES.B, NOTES.D, NOTES.F }));
    play(make_notes(&.{ NOTES.C, NOTES.E, NOTES.G, NOTES.B }));
    play(make_notes(&.{ NOTES.A, NOTES.C, NOTES.E, NOTES.G }));
    play(make_notes(&.{ NOTES.F, NOTES.A, NOTES.C, NOTES.E, NOTES.G }));
    play(make_notes(&.{ NOTES.G, NOTES.B, NOTES.D, NOTES.F, NOTES.A }));
    play(make_notes(&.{ NOTES.C, NOTES.E, NOTES.G, NOTES.B, NOTES.D }));

}
