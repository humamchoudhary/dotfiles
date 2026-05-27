"""
Wallpaper Selector
Pick a theme, browse wallpapers with q/e, apply with awww as you go
"""

import sys
import subprocess
import termios
import tty
from pathlib import Path

WALLPAPERS_DIR = Path("wallpapers")
IMAGE_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.webp', '.bmp'}


def get_themes() -> list[Path]:
    if not WALLPAPERS_DIR.exists():
        print(f"❌ Wallpapers directory '{WALLPAPERS_DIR}' not found.")
        sys.exit(1)

    themes = sorted([
        d for d in WALLPAPERS_DIR.iterdir()
        if d.is_dir() and d.name != "_unmatched"
    ])

    if not themes:
        print("❌ No themes found.")
        sys.exit(1)

    return themes


def get_wallpapers(theme_dir: Path) -> list[Path]:
    return sorted([
        f for f in theme_dir.iterdir()
        if f.suffix.lower() in IMAGE_EXTENSIONS
    ])


def getch() -> str:
    """Read a single keypress without requiring Enter."""
    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        return sys.stdin.read(1)
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)


def set_wallpaper(path: Path):
    try:
        subprocess.run(
            ["awww", "img", str(path),
             "--transition-type", "fade",
             "--transition-duration", "1"],
            check=True,
            capture_output=True,
        )
    except FileNotFoundError:
        print("\n❌ awww not found. Is it installed and in PATH?")
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print(f"\n❌ awww error: {e.stderr.decode().strip()}")


def pick_theme(themes: list[Path]) -> Path:
    print("\n┌─ Available themes " + "─" * 40)
    for i, t in enumerate(themes):
        count = len(get_wallpapers(t))
        print(f"│  [{i + 1}] {t.name}  ({count} wallpapers)")
    print("└" + "─" * 59)

    while True:
        try:
            raw = input("\nEnter theme number: ").strip()
            idx = int(raw) - 1
            if 0 <= idx < len(themes):
                return themes[idx]
            print(f"  Please enter a number between 1 and {len(themes)}.")
        except (ValueError, EOFError):
            print("  Invalid input.")


def browse(wallpapers: list[Path]):
    if not wallpapers:
        print("❌ No wallpapers in this theme.")
        return

    idx = 0
    total = len(wallpapers)

    set_wallpaper(wallpapers[idx])
    print(f"\r  [{idx + 1}/{total}]  {wallpapers[idx].name}"
          f"   (e=next  q=prev  Enter=keep  Esc=quit)    ", end="", flush=True)

    while True:
        key = getch()

        if key == "e":
            idx = (idx + 1) % total
            set_wallpaper(wallpapers[idx])
        elif key == "q":
            idx = (idx - 1) % total
            set_wallpaper(wallpapers[idx])
        elif key in ("\r", "\n"):
            print(f"\n✓ Wallpaper set: {wallpapers[idx].name}")
            break
        elif key in ("\x03", "\x1b"):
            print("\nAborted.")
            break

        print(f"\r  [{idx + 1}/{total}]  {wallpapers[idx].name}"
              f"   (e=next  q=prev  Enter=keep  Esc=quit)    ", end="", flush=True)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Browse and set wallpapers by theme using awww")
    parser.add_argument("-d", "--dir", default="wallpapers",
                        help="Base wallpapers directory (default: wallpapers)")
    args = parser.parse_args()

    global WALLPAPERS_DIR
    WALLPAPERS_DIR = Path(args.dir)

    print("╔══════════════════════════════════╗")
    print("║      awww wallpaper selector     ║")
    print("╚══════════════════════════════════╝")

    themes = get_themes()
    theme = pick_theme(themes)

    wallpapers = get_wallpapers(theme)
    if not wallpapers:
        print(f"❌ No images found in theme '{theme.name}'.")
        sys.exit(1)

    print(f"\n  Theme: {theme.name}  —  {len(wallpapers)} wallpapers")
    print("  Use  e / q  to cycle,  Enter  to keep.\n")

    browse(wallpapers)


if __name__ == "__main__":
    main()
