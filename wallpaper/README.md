# Wallpapers

**[Topographic Amoeba](https://basicappleguy.com/basicappleblog/topographic-amoeba)** by
**[BasicAppleGuy](https://basicappleguy.com)** — released free and in full resolution.
Thanks for making these. If you use them, consider
[supporting the work](https://basicappleguy.com/basicappleblog/topographic-amoeba).

| | |
|---|---|
| `mac/` | The **Dynamic** downloads: 6016×3900 HEICs holding two images each, with an XMP `apple_desktop:apr` map of `{l:0, d:1}`. macOS reads that and swaps light↔dark with the system appearance — which is why there is no separate light/dark file here. |
| `iphone/` | Plain PNGs, light and dark separately, because the collection ships no dynamic variant for iPhone. Not referenced by Nix; they're here to AirDrop across. |

Six in the set: Vannella Hills, Proteus Valley, Chaos Ridge, Arcella Alps,
Pelomyxa Pass, Difflugia Divide.

## How the Mac one gets picked

`wallpaper-shuffle` (defined in [`../home/darwin.nix`](../home/darwin.nix)) picks one
of `mac/*.heic` at random and sets it via System Events. It runs on every `make apply`,
at login, and hourly — and you can run `wallpaper-shuffle` yourself to reroll.

Shuffling only chooses *which* wallpaper is up; light/dark within it stays macOS's job,
so a reroll never fights the appearance switch.
