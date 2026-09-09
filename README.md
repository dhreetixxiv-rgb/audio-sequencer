# audio-sequencer

### Materials Used

1. Altera DE1 SoC Development Board (with additional cables to connect to computer and power)
2. Headphones with 3mm diameter input jack
3. Ultrasonic Sensor (HC-SR04)

### **Description of Project**

This is a drum sequencer, where there are 8 steps, and a user can add or delete a beat to each step. They have an option of 4 different sounding beats. The output is audio that can be listened to via plugging headphones into the line out jack on the DE1 SoC board. 

To add a beat, select the step which you want to edit (SW[2:0]), select the sound you want to add (SW[9:8]), and press KEY[0] to add the beat. To delete the beat, select the step you want to delete the beat from (SW[2:0]), select the sound that you previously added to the beat (SW[9:8]), and press KEY[0] to delete the beat. You can then add another sound as you wish.

Additionally, LEDR[7:0] shows the step that the drum sequencer is on, so the user can see the tempo visually as well. LEDR[9] flashes when there is a beat added to a step.

#### User inputs:

- **SW[2:0]** – these three switches control which step you want to edit. 000 = step 0 to 111 = step 7
- **SW[9:8]** – these two switches control which beat type you want to add to your chosen step.
    - Types of beats available: 00 = kick drum, 01 = snare drum, 10 = high pitch, 11 = mid pitch
- **KEY[0]** – press when you want to add beat to the step you have selected
- **KEY[3]** – press this to reset the entire system (clears any patterns that have been added and resets the current step the counter is on to zero)
- **Ultrasonic sensor** (added component on breadboard): this controls the tempo of the sequencer. Moving your hand closer to it increases the tempo of the sequencer and vice versa.

### Module descriptions


| Module | Description |
| --- | --- |
| **DE1_SoC** | Top level module. Ties together the entire drum machine: reads switches/buttons/GPIO inputs, instantiates every subsystem module, and drives the LEDs and audio CODEC outputs. Owns the global `reset` signal and routes all inter-module wiring. |
| **metronome** | Generates two periodic timing pulses from the 50MHz clock: `tempo` (fires once per sequencer step, at a rate selected by `speed_level` — 4 selectable tempos) and `freq` (a faster, roughly-48kHz reference tick used by the audio synthesizer's envelope timers). Inputs: `clk`, `reset`, `speed_level[1:0]`. Outputs: `tempo`, `freq`. |
| **user_input_fsm** | A 3-state FSM (`WAIT` → `EDIT` → `HOLD` → `WAIT`) that converts a raw button-held signal into a single, clean one-cycle pulse (`Z`) per press, regardless of how long the button is physically held down. Inputs: `clk`, `reset`, `K`. Output: `Z`. |
| **step_counter** | A 3-bit counter that advances through 8 steps (0-7) each time `tempo` pulses, wrapping back to 0 after step 7. Also produces `step_valid`, a one-cycle-delayed version of `tempo` that lines up with the *updated* step value, and drives `leds` with a one-hot decode of the current step for visual feedback. Inputs: `clk`, `reset`, `tempo`. Outputs: `current_step[2:0]`, `step_valid`, `leds[7:0]`. |
| **pattern_memory** | Stores the programmed drum pattern: an 8-step × 4-instrument bit array (kick, snare, hi-hat, mid/tom). On an edit pulse (`change`), toggles the bit selected by `sw_step`/`sw_instr`. Combinationally reads out the four instrument bits for whichever step `current_step` currently points to. Inputs: `clk`, `reset`, `change`, `sw_step[2:0]`, `sw_instr[1:0]`, `current_step[2:0]`. Outputs: `kick`, `snare`, `hi`, `mid`. |
| **audio_synthesizer** | Generates the actual 24-bit signed PCM audio samples sent to the CODEC. Maintains four independent envelope timers (one per instrument), each triggered by `step_valid` + its respective instrument bit; each timer drives a square-wave tone at a distinct pitch (via a chosen bit of an internal counter) for a fixed duration, then fades/stops. A priority chain (kick > snare > mid > hi) selects which instrument's waveform drives the final output when multiple are active simultaneously. Inputs: `clk`, `reset`, `freq` (sample-rate tick), `step_valid`, `kick`, `snare`, `hi`, `mid`. Output: `pcm_out[23:0]`. |
| **audio_driver** | Wraps the low-level `audio_codec`/`audio_and_video_config` interface into a simplified handshake: accepts 24-bit `dac_left`/`dac_right` samples and pulses `advance` at ~48kHz to request new audio data, while handling the CODEC's serial protocol and I2C configuration internally. |
| **ultrasonic_sensor** | Drives an HC-SR04 ultrasonic distance sensor and measures how far away an object is. A 5-state FSM (`IDLE → TRIGGER → WAIT_RISE → COUNTING → GAP`) sends a 10μs trigger pulse, times the sensor's echo response in clock cycles, and reports the result. Inputs: `clk`, `reset`, `echo_raw` (from GPIO, via internal `button_sync` synchronization). Outputs: `trig` (to GPIO), `distance_ticks[21:0]` (raw echo pulse width), `new_sample` (one-cycle pulse marking a fresh measurement). |
| **distance_decoder** | A purely combinational lookup that buckets the raw `distance_ticks` value into one of 4 discrete tempo tiers based on distance thresholds. Input: `distance_ticks[21:0]`. Output: `speed_level[1:0]`. |
