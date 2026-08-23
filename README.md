# av2play

Players for **AVF / AVF2** video on the Atari 8-bit, with first-class
**GTIA2RGB true-colour** support.

Companion to the [avi2atari AVF Suite](https://github.com/HanJammer/avi2atari)
- converter, web UI, PC player, validator and metadata editor.

> **Experimental release.** This drop ships the **`bin/AVFPLAY` binary only**
> (v1.12). The full source will be published once the menu player
> (`AV2PLAY.XEX`) also works on hardware.

## AVFPLAY - the card-native player

`AVFPLAY` is a headless drop-in for the stock player in the **AVG CART /
SUB CART** root (native mode): copy it to the card, pick an `.avf`, it plays.
Same proven beam-raced movplay core (Avery Lee / tmp / Jakub Husak
smooth-sound), plus:

- **AVF-C80 true-colour playback** (GTIA2RGB COL80 Mode 4, 80x48 RGB444) -
  real RGB video on a stock A8 with a GTIA2RGB. *(new, working)*
- **APAC playback** - the classic profile, plays on every Atari.
- **AVF2 info screen** (`I`, while paused or playing): title, author, length,
  system, profile - 80-column COL80 when a GTIA2RGB is present, 40-column
  text otherwise.
- **Help screen** (`H`): full key reference.
- **Runtime sound device**: POKEY or one of six Covox addresses, selectable
  in ONE binary via `av2play-config` (no more per-device builds).

Keys: `START` pause, `SELECT` / `OPTION` volume (POKEY), `I` / `H` screens
(any key returns to the frozen frame, `START` resumes), `ESC` exit to the
cart menu.

> AVF-C80 files also play in the legacy players, but the colours will be
> wrong - they need a GTIA2RGB and this player for true colour.

## Screenshots
![FujiATC in 40-col GTIA2RGB mode](https://github.com/HanJammer/FujiATC/blob/main/images/fujiatc_v0.8_40col.jpg)
| | |
|---|---|
| ![AVF-C80 true-colour video playback](https://github.com/HanJammer/av2play/blob/main/images/av2play-apac-video.jpg) | ![AVF2 info screen](https://github.com/HanJammer/av2play/blob/main/images/av2play-info-screen.jpg) |
| ![APAC video playback](https://github.com/HanJammer/av2play/blob/main/images/0av2play-apac-video.jpg) | ![Help screen](https://github.com/HanJammer/av2play/blob/main/images/av2play-help-screen.jpg) |

## Install

Copy `bin/AVFPLAY` to the **root of your AVG / SUB CART SD card**. Selecting
an `.avf` launches it automatically. Write the `.avf` to the card the usual
raw way (the player skips the 8 KB header and streams the frames).

## av2play-config - set the boot defaults

`bin/av2play-config` patches the `A2CF` settings block inside the binary, so
you can bake in defaults without rebuilding - one binary covers every sound
device. Three equivalent front-ends: **`.bat`** (Windows, PowerShell inside,
no Python), **`.ps1`** (PowerShell) and **`.sh`** (POSIX).

Run with **no arguments** for an interactive menu (shows the current values),
or pass them positionally:

```
av2play-config.sh bin/AVFPLAY <UI> <SOUND> <PLAYBACK> <STORAGE>
```

| Slot | Values | Meaning |
|------|--------|---------|
| UI | `auto` `ui40` `ui80m3` `ui80m4` | info/help screen mode (`auto` = COL80 when a GTIA2RGB is present) |
| SOUND | `pokey` `d280` `d300` `d500` `d580` `d600` `d700` | PWM output: POKEY, or a Covox address |
| PLAYBACK | `playapac` `play80m3` `play80m4` | video profile the player expects |
| STORAGE | `auto` `off` | IDE storage probe |

`.` (or `-`) leaves a slot unchanged. Example - default to the $D500 Covox,
leave everything else as-is:

```
av2play-config.sh bin/AVFPLAY . d500 . .
```

## AV2PLAY.XEX - the menu player (in development - not available yet)

`AV2PLAY.XEX` targets **SIDE2-class** devices (and AVG / SUB in SIDE
emulation): a file browser with metadata and poster preview, then playback.
It boots, browses FAT16 / FAT32 and reads real AVF2 metadata - but
**playback is not working on hardware yet**.

Progress here is **hardware-blocked**: it needs a real SIDE2-class cart to
test the streaming path. I'm trying to get one; until then development
stays at its current point. The full `av2play` source ships once this build
plays.

## Credits and thanks

- **Rusty Bits** - this player, the **AVF2** metadata format and the **AVF-C80** true-colour profile.
- **Jakub Husak** - the smooth-sound AVFPLAY rework this build vendors (every PWM sample played cycle-exact, so no hiss or hum). Source and details: [github.com/jhusak/avgcart_avfplay](https://github.com/jhusak/avgcart_avfplay).
- **Avery Lee (phaeron)** - the original AVF concept and the original MOVPLAY streaming player.
- **tmp** - the AVG / SUB CART implementation.
- **AcidMaker** - the GTIA2RGB and the explanations that made AVF-C80 work.

[![GTIA2RGB by AcidMaker](images/gtia2rgb_logo.png)](https://lotharek.pl/productdetail.php?id=435)

*Not affiliated with lotharek.pl in any way. The image and link are shared purely as a courtesy and a thank-you for help preparing this program; no benefit of any kind is derived from them.*
