# NoisyKeys Roadmap

## Vision

Turn typing into music instead of simple key click noise.

The product should feel playful, musical, and reactive without becoming chaotic or annoying.

## V1.0: Musical Keyboard Foundation

### Goal

Ship the first version as a polished musical typing experience built around a piano or lo-fi keys sound.

### Core ideas

- Every key press should trigger a musical event, not just a raw sound effect.
- Key mapping should feel intentional and harmonious.
- The system should stay musically constrained so random typing still sounds good.

### Scope

- Add a piano / lo-fi instrument mode for typing.
- Map keys into musical roles instead of random one-off sounds.
- Keep notes inside a selected key, scale, or chord shape.
- Support different behavior for letters, space, return, backspace, and modifier keys.
- Use typing speed as light performance input for rhythm and note density.
- Keep the existing global on/off controls and menu bar controls working.

### Suggested V1 key behavior

- Letter keys: melodic notes
- Space: pulse, pedal, or low accent
- Return: strong accent / phrase ending
- Backspace: tension or reverse-style accent
- Modifier keys: light percussion or texture hits

### V1 non-goals

- No cadence engine yet
- No emotional analysis yet
- No genre packs like techno or dubstep yet
- No deep text interpretation beyond simple typing-speed response

## V1.1: Musical Polish

- Improve note mapping so common typing patterns feel more musical
- Add better dynamics and velocity shaping
- Add instrument selection between piano and lo-fi
- Add light rhythm variation based on bursts of typing

## V2.0: Cadence And Emotion

### Goal

Make the music respond to how the user is typing and what the writing feels like.

### Planned features

- Detect typing cadence over time
- Speed up or slow down musical phrasing based on typing pace
- Shift note choices and harmonic color based on mood signals
- Use punctuation, capitalization, delete frequency, and burstiness as expressive inputs
- Optionally analyze typed text locally to influence tone

### Guardrails

- Keep text analysis local-only
- Do not store typed content
- Ignore or avoid sensitive fields when possible

## Future Versions

- Techno mode
- Dubstep mode
- Additional genre packs
- Smarter phrase generation
- Theme-based sound packs
- More expressive mood transitions between calm, tense, playful, and aggressive writing

## Product Principle

The app should always sound like music first and a keyboard gimmick second.
