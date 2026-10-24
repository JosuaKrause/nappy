# Every sound gets a picture an agent can read

From chirp's analysis and preview (`chirp/src/core/analyze.ts`, `chirp/src/node/preview.ts`).

**Build:** beside each WAV `tools/synthesize-sfx.py` writes, a PNG of the waveform over a
log-frequency spectrogram, and its peak and RMS in dBFS, clipped-sample count, spectral centroid
(brightness) and a pitch track, so an agent sees a smeared wash against crisp ticks before the
player listens. **sound-effects**' rule that no automated check establishes how a sound reads to the
player stays as it is.
