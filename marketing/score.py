"""Original 120 BPM electronic score; no samples or external music."""
from array import array
from math import sin, cos, pi, exp, tanh
from pathlib import Path
import random
import struct
import wave

RATE, SECONDS = 44100, 48
COUNT = RATE * SECONDS
left, right = array('d', [0]) * COUNT, array('d', [0]) * COUNT
rng = random.Random(931)
TAU = 2 * pi

def event(start, length, sound, gain=1, pan=0):
    offset = int(start * RATE)
    l, r = cos((pan+1)*pi/4), sin((pan+1)*pi/4)
    for j in range(min(int(length*RATE), COUNT-offset)):
        value = sound(j/RATE, j) * gain
        left[offset+j] += value*l
        right[offset+j] += value*r

def pluck(start, midi, gain=.065, pan=0, length=.8):
    hz = 440 * 2**((midi-69)/12)
    def tone(t, j):
        env = (1-exp(-t*240))*exp(-t*5.8)
        return (sin(TAU*hz*t) + .24*sin(TAU*hz*2*t) + .07*sin(TAU*hz*3*t))*env
    event(start, length, tone, gain, pan)

def bass(start, midi, gain=.12):
    hz = 440 * 2**((midi-69)/12)
    event(start, .46, lambda t,j: (1-exp(-t*180))*exp(-t*7)*(sin(TAU*hz*t)+.15*sin(TAU*hz*2*t)), gain)

def kick(start, gain=.45):
    event(start, .32, lambda t,j: sin(TAU*(43*t+2.8*(1-exp(-t*42))))*exp(-t*17), gain)

def hat(start, gain=.035):
    noise = [rng.uniform(-1,1) for _ in range(int(.09*RATE))]
    event(start, .09, lambda t,j: noise[j]*exp(-t*60), gain, .35)

def snare(start, gain=.09):
    noise = [rng.uniform(-1,1) for _ in range(int(.18*RATE))]
    event(start, .18, lambda t,j: (.8*noise[j]+.2*sin(TAU*178*t))*exp(-t*24), gain, -.1)

chords = [
    ([62,66,69,73],38), ([57,61,64,71],33),
    ([59,62,66,69],35), ([55,59,62,66],31)
]
for bar in range(24):
    start = bar*2
    notes, root = chords[(bar//2)%4]
    for beat in range(4):
        moment = start+beat*.5
        if moment < 45.5:
            kick(moment, .31 if moment < 6 else .42)
            bass(moment, root, .085 if moment < 6 else .12)
            if beat%2 == 1 and moment >= 6:
                snare(moment)
        if moment >= 6 and moment < 45.5:
            hat(moment+.25, .026)
            hat(moment, .019 if beat%2 else .03)
    pattern = [0,2,1,3,2,1,3,2]
    for k, step in enumerate(pattern):
        moment = start+k*.25
        if moment < 46:
            pluck(moment, notes[step]+12, .04 if moment < 6 else .058, -.35 if k%2 else .35)
    # Soft chord bloom at each two-bar harmony change.
    if bar%2 == 0:
        for i, midi in enumerate(notes):
            hz = 440*2**((midi-69)/12)
            event(start, 3.7, lambda t,j,hz=hz: sin(TAU*hz*t)*(1-exp(-t*7))*exp(-t*.9), .022, (i-1.5)*.32)

# A simple original closing motif, resolving to D.
for start, midi in [(41,74),(41.5,78),(42,81),(43,78),(44,76),(45,74),(46,74)]:
    pluck(start, midi, .07, length=1.8)
for midi in [50,62,66,69,74]:
    pluck(46, midi, .06, length=2)

peak = max(max(abs(x) for x in left), max(abs(x) for x in right))
scale = .82/peak
data = bytearray()
for index, (l,r) in enumerate(zip(left,right)):
    time = index/RATE
    fade = min(1, time/.06, max(0,(48-time)/1.5))
    data.extend(struct.pack('<hh', int(max(-1,min(1,l*scale*fade))*32767), int(max(-1,min(1,r*scale*fade))*32767)))
path = Path('build/launch-score.wav')
with wave.open(str(path),'wb') as result:
    result.setnchannels(2); result.setsampwidth(2); result.setframerate(RATE); result.writeframes(data)
print(f'Original stereo score: {SECONDS}s, 120 BPM, {path}')
