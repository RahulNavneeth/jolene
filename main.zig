const std = @import ("std");

const assert = std.debug.assert;
const print = std.debug.print;

const echoes = @cImport ({
    @cInclude ("IO.h");
});

const Frequency = f32;
const PitchOffset = f32;
const Partial = struct {
    frequency: Frequency,
    amplitude: f32,
    decay: f32,
};
const Note = struct {
    note: i8,
    octave: i8,
};

const SAMPLE : Frequency = 48000;
const PITCH_STANDARD : Frequency = 440;
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
const PARTIAL_COUNT: i8 = 24;
const BASE_DECAY: f32 = 1.5;

fn play (samples: [LOCAL_SAMPLE]f32) void {
    const sample = echoes.sample {
        .sample = samples[0..].ptr,
        .sample_count = LOCAL_SAMPLE,
        .current_position = 0,
        .completed = false,
    };
    const feedback: c_int = echoes.write_audio (sample);
    assert (feedback == 0);
    std.Thread.sleep(TIME_PER_NOTE * 1000 * std.time.ns_per_ms);
}

fn get_frequency_from_note (note: Note) Frequency {
    const oct = if (note.note>2) note.octave - 1 else note.octave;
    const local_oct = ((4 - oct) * -1);
    const nxlc: PitchOffset = @floatFromInt ((12*local_oct) + note.note);
    return (PITCH_STANDARD * std.math.pow (f32,  2, (nxlc / 12.0)));
}

// Note: Gotta study compression
fn envelope( time: f32, attack: f32, decay: f32, duration: f32, amplitude: f32,) f32 {
    if (time <= 0.0 or time >= duration) return 0.0;
    if (time < attack) {
        const x = time / attack;
        return amplitude * (x * x * (3.0 - 2.0 * x));
    }
    const x = (time - attack) / decay;
    return amplitude * std.math.exp(-3.0 * x);
}

fn sin_wave (frequency: Frequency, time: f32, amplitude: f32, decay: f32) f32 {
    const ang_freq = 2 * std.math.pi * frequency;
    const amp = amplitude * std.math.exp(-decay * time); // NOTE: Gotta study this formula
    return amp * std.math.sin(ang_freq * time + PHASE);
    // return envelope (time, 0.005, decay, TIME_PER_NOTE, amplitude) * std.math.sin (ang_freq * time + PHASE);
}

// Change the type from `comptime anytype -> [*c]i8` if fetching the notes at runtime
fn make_notes (comptime notes: anytype) [LOCAL_SAMPLE]f32 {
    var samples: [LOCAL_SAMPLE]f32 = .{0} ** LOCAL_SAMPLE;
    inline for (notes) |note| {
        const lf = get_frequency_from_note (note);
        for (&samples, 0..) |*sample, t| {
            sample.* += sin_wave(lf, @as(f32, @floatFromInt(t)) / SAMPLE, AMPLITUDE, BASE_DECAY);
            const piano_partials = make_piano (lf); // make interface of somekind
            for (piano_partials) |partial| {
                sample.* += sin_wave(partial.frequency, @as(f32, @floatFromInt(t)) / SAMPLE, partial.amplitude, partial.decay);
            }
        }
    }
   return samples;
}

fn make_piano (fundamental: Frequency) [PARTIAL_COUNT]Partial {
    const B: f32 = 0.0001;
    var partials: [PARTIAL_COUNT]Partial = std.mem.zeroes([PARTIAL_COUNT]Partial);

    for (&partials, 1..PARTIAL_COUNT+1) |*partial, k| {
        const k32 = @as(f32, @floatFromInt(k));
        const frequency = k32 * fundamental * std.math.sqrt(1.0 + B * k32 * k32);
        partial.* = .{
            .frequency = frequency,
            .amplitude = AMPLITUDE / (k32 * k32),
            .decay = BASE_DECAY * k32,
        };
    }

    return partials;
}

pub fn main () !void {
    const res: c_int = echoes.init_audio_driver ("Jolene!!!".ptr);
    defer echoes.cleanup_audio_driver ();
    assert (res == 0);

    // const impl: [*c]echoes.DriverIMPL = echoes.get_driver_impl ();
    // const sound_check = impl.*.sound_check orelse unreachable;
    // sound_check ();

    // TODO:
    // 1. Schedule notes efficiently
    //    - Don't group notes like I do now
    //    - Optimize sine-wave generation in the runtime
    //    - Schedule notes in parallel
    //    - Notes can overlap at different points in time
    //          - E.g. A, B play in parallel for 2 seconds, then C plays for 2 seconds,
    //          - then B, D play in parallel for 2 seconds

    play(make_notes([_]Note{
        .{ .note = NOTES.G, .octave = 3 },
        .{ .note = NOTES.B, .octave = 3 },
        .{ .note = NOTES.D, .octave = 4 },
    })); // G
    
    play(make_notes([_]Note{
        .{ .note = NOTES.D, .octave = 4 },
        .{ .note = NOTES.F_SHARP, .octave = 4 },
        .{ .note = NOTES.A, .octave = 4 },
    })); // D
    
    play(make_notes([_]Note{
        .{ .note = NOTES.E, .octave = 3 },
        .{ .note = NOTES.G, .octave = 3 },
        .{ .note = NOTES.B, .octave = 3 },
    })); // Em
    
    play(make_notes([_]Note{
        .{ .note = NOTES.C, .octave = 4 },
        .{ .note = NOTES.E, .octave = 4 },
        .{ .note = NOTES.G, .octave = 4 },
    })); // C

    // play (make_notes([_]Note{.{.note = NOTES.A, .octave = 4}}));
}
