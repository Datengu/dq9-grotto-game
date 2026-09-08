# Exploration reference study — 8 September 2026

The user supplied one screenshot and four emulator recordings. We decoded and visually inspected eight samples from each clip, with additional attention to the short monster clip. Reference frames stay in ignored local test output, outside the game and source documentation. All game models, materials, geometry and dialogue are independently authored placeholders.

| Reference | Observations used | Interpretation limits |
|---|---|---|
| Screenshot, B4 ruins | Elevated perspective; local room/corridor framing; substantial walls; single-file party turning through occupied space | Left map screen is information reference only; right world screen guides exploration |
| `033309.mp4`, 31.1 seconds | Cave travel, stair approach, tight bends, leader and followers, camera tracking in confined space | Geometry and scale reference, not a source of assets or exact speed measurements |
| `033432.mp4`, 2.65 seconds | A visible monster occupies dungeon space and closes toward an encounter; transition begins around 1.6 seconds | Too brief to derive chase duration, detection radius or loss rules; transition swirl is not the exploration camera |
| `034253.mp4`, 50.0 seconds | Town lanes, NPC approach, dialogue, shrine interior and service interaction | FPS overlays also occur in this clip, including samples around 25 and 37 seconds |
| `034412.mp4`, 36.3 seconds | More town travel, building entry, inn/counter scale and dialogue | Ignore Target FPS overlays, accelerated travel and transition blackouts when choosing movement timing |

The screenshot and town recordings show an emulator arranging the DS screens side by side. Lantern Atlas uses a single full-width world viewport. M optionally reveals a compact discovered map. No emulator text, screen arrangement or speed adjustments were reproduced.

## Design translation

The qualitative target is a local high-angle perspective, a leader below the centre of the image, enough room to read nearby junctions, and substantial scenery outside view or naturally occluding the world. Camera numbers below are our tunable starting values, not measured DQIX constants.

| Parameter | Town/dungeon | Interior |
|---|---:|---:|
| Height | 10.8 m | 9 m |
| Distance | 12.5 m | 10.8 m |
| Pitch down | 42° | 42° |
| Vertical field of view | 43° | 44° |
| Tracking smoothing | 9/s | 9/s |
| Forward framing offset | 2 m | 1.2 m |

Settings live in `data/exploration.json`. F2 opens live sliders; overrides last through scene changes for the current session. Restore defaults selects the current scene's defaults. Commit JSON changes to make new defaults permanent. Height, distance, pitch and framing offset are independent; large changes should be checked together. Scenery directly between the camera and leader fades to preserve control, while surrounding walls stay opaque. This is an intentional usability adaptation.

Player travel is 4.4 m/s, with acceleration 20 m/s² and braking 26 m/s². Camera-relative horizontal input is normalised, including diagonals. Rotation follows motion; procedural limbs are replaceable animation hooks. Physics uses capsule collision. The internal floor cell measures 1.8 m; new passages are generally two cells wide. Walls are approximately 2.8 m tall. Two visual companions sample the leader's travelled trail at 0.12 m intervals, spaced 1.35 m apart, with bounded catch-up speed and collision.

Enemy detection initially reaches 6.2 m with grid line of sight; pursuit ends on distance, home leash, a ten-second limit or 2.5 seconds without sight. These are original tuning choices. Slow, ordinary and fast variants share idle/wander/chase/return states. Combat remains a single active hero against one opponent; companions are presentation only.

## Current limitations

This is a stylised geometric 3D blockout. Cave walls remain mostly rectilinear with rounded room corners and rock accents; final organic cave meshes, richer interiors, model animation and audio are future work. The observations above do not establish original enemy AI constants or exact original camera projection. A longer detection/chase reference and chest-opening example would help a later feel pass, but are not required to play this build.
