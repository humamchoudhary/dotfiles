"""
Theme-based Wallpaper Organizer
Scans a folder for images, matches them to themes, and sorts into theme directories
"""

import os
import shutil
import json
import math
from pathlib import Path
from typing import List, Tuple, Dict, Optional
from dataclasses import dataclass
from collections import defaultdict
import argparse
import sys

try:
    from PIL import Image
    import numpy as np
except ImportError:
    print("Error: Required packages not installed. Run: pip install Pillow numpy")
    sys.exit(1)

@dataclass
class Theme:
    name: str
    colors: Dict[str, Tuple[int, int, int]]

@dataclass
class ImageMatch:
    path: str
    filename: str
    best_theme: str
    match_score: float
    dominant_colors: List[Tuple[int, int, int]]

class ThemeWallpaperOrganizer:
    def __init__(self, themes_json: str, color_weight: Dict[str, float] = None):
        self.themes = self.load_themes(themes_json)
        self.color_weight = color_weight or {
            "true_black": 2.0,
            "vanta_ui": 1.5,
            "accent": 1.5,
            "surface": 1.0,
            "body_text": 1.0,
            "border": 0.8,
            "muted_text": 0.5,
            "bright_text": 0.5,
            "accent_dim": 0.5,
            "elevated": 0.3
        }

    def load_themes(self, themes_json: str) -> List[Theme]:
        with open(themes_json, 'r') as f:
            data = json.load(f)

        themes = []
        for theme_data in data:
            colors = {}
            for color_name, color_info in theme_data['colors'].items():
                hex_color = color_info['hex'].lstrip('#')
                colors[color_name] = tuple(int(hex_color[i:i+2], 16)
                                          for i in (0, 2, 4))
            themes.append(Theme(
                name=theme_data['palette'].replace(' ', '_'),
                colors=colors
            ))

        print(f"✓ Loaded {len(themes)} themes")
        return themes

    def color_distance(self, rgb1: Tuple[int, int, int],
                       rgb2: Tuple[int, int, int]) -> float:
        return math.sqrt(sum((a - b) ** 2 for a, b in zip(rgb1, rgb2)))

    def _kmeans_numpy(self, pixels: np.ndarray, k: int, max_iter: int = 20) -> Tuple[np.ndarray, np.ndarray]:
        rng = np.random.default_rng(42)
        indices = rng.choice(len(pixels), size=k, replace=False)
        centroids = pixels[indices].astype(float)

        labels = np.zeros(len(pixels), dtype=int)
        for _ in range(max_iter):
            diffs = pixels[:, None, :] - centroids[None, :, :]
            dists = np.sum(diffs ** 2, axis=2)
            new_labels = np.argmin(dists, axis=1)

            if np.array_equal(new_labels, labels):
                break
            labels = new_labels

            for i in range(k):
                mask = labels == i
                if mask.any():
                    centroids[i] = pixels[mask].mean(axis=0)

        return centroids, labels

    def extract_dominant_colors(self, image_path: str, num_colors: int = 10) -> List[Tuple[int, int, int]]:
        try:
            img = Image.open(image_path).convert('RGB')

            if max(img.size) > 300:
                ratio = 300 / max(img.size)
                new_size = (int(img.size[0] * ratio), int(img.size[1] * ratio))
                img = img.resize(new_size, Image.Resampling.LANCZOS)

            pixels = np.array(img).reshape(-1, 3)
            k = min(num_colors, len(pixels))
            centroids, labels = self._kmeans_numpy(pixels, k)

            counts = np.bincount(labels, minlength=k)
            sorted_indices = np.argsort(counts)[::-1]
            colors = [tuple(centroids[i].astype(int).tolist()) for i in sorted_indices]
            return colors[:num_colors]

        except Exception as e:
            print(f"  Error extracting colors from {image_path}: {e}")
            return []

    def calculate_theme_match_score(self, image_colors: List[Tuple[int, int, int]],
                                   theme: Theme) -> float:
        if not image_colors:
            return float('inf')

        total_score = 0
        total_weight = 0

        for color_name, theme_rgb in theme.colors.items():
            weight = self.color_weight.get(color_name, 1.0)
            closest_distance = min(self.color_distance(theme_rgb, img_color)
                                  for img_color in image_colors)
            max_distance = 441.67
            normalized_distance = closest_distance / max_distance
            total_score += normalized_distance * weight
            total_weight += weight

        return total_score / total_weight if total_weight > 0 else 1.0

    def find_matching_themes(self, image_path: str,
                             threshold: float = 0.3) -> List[Tuple[str, float]]:
        """Return ALL themes whose score is within the threshold, sorted best-first."""
        image_colors = self.extract_dominant_colors(image_path)

        if not image_colors:
            return []

        matches = []
        for theme in self.themes:
            score = self.calculate_theme_match_score(image_colors, theme)
            if score <= threshold:
                matches.append((theme.name, score))

        matches.sort(key=lambda x: x[1])
        return matches

    def scan_directory(self, input_dir: str, extensions: set = None) -> List[str]:
        if extensions is None:
            extensions = {'.jpg', '.jpeg', '.png', '.webp', '.bmp', '.gif'}

        images = []
        input_path = Path(input_dir)

        for file_path in input_path.rglob('*'):
            if file_path.suffix.lower() in extensions:
                images.append(str(file_path))

        print(f"✓ Found {len(images)} images in {input_dir}")
        return images

    def _transfer_file(self, src: Path, dst_dir: Path, move: bool, already_moved: bool) -> Path:
        """Copy src into dst_dir (or move for the first destination only)."""
        dst = dst_dir / src.name
        if dst.exists():
            counter = 1
            while dst.exists():
                dst = dst_dir / f"{src.stem}_{counter}{src.suffix}"
                counter += 1
        if move and not already_moved:
            shutil.move(str(src), str(dst))
        else:
            shutil.copy2(str(src), str(dst))
        return dst

    def _process_one(self, image_path: str, output_path: Path,
                     threshold: float, move: bool, dry_run: bool,
                     dir_lock: object, verbose: bool) -> dict:
        """Match a single image and immediately transfer it to all matching themes."""
        matches = self.find_matching_themes(image_path, threshold)
        src = Path(image_path)

        if matches:
            theme_names = [m[0] for m in matches]
            scores      = {m[0]: m[1] for m in matches}

            if not dry_run:
                already_moved = False
                for theme_name in theme_names:
                    dest_dir = output_path / theme_name
                    with dir_lock:
                        dest_dir.mkdir(exist_ok=True)
                    self._transfer_file(src, dest_dir, move, already_moved)
                    already_moved = already_moved or move

            if verbose:
                action = "Moved" if move else "Copied"
                destinations = ", ".join(
                    f"{n}({scores[n]:.3f})" for n in theme_names
                )
                print(f"  ✓ {action}: {src.name} -> {destinations}")

            return {'path': image_path, 'themes': theme_names, 'scores': scores}

        else:
            dest_dir = output_path / "_unmatched"
            if not dry_run:
                with dir_lock:
                    dest_dir.mkdir(exist_ok=True)
                self._transfer_file(src, dest_dir, move, False)

            if verbose:
                print(f"  ✗ No match: {src.name} -> _unmatched/")

            return {'path': image_path, 'themes': [], 'scores': {}}

    def organize_images(self, input_dir: str, output_base_dir: str = "wallpapers",
                       threshold: float = 0.25, dry_run: bool = False,
                       move: bool = False, verbose: bool = True,
                       workers: int = 4):
        import threading
        from concurrent.futures import ThreadPoolExecutor, as_completed

        output_path = Path(output_base_dir)
        if not dry_run:
            output_path.mkdir(exist_ok=True)

        images = self.scan_directory(input_dir)
        if not images:
            print("❌ No images found!")
            return

        print(f"\n🎨 Processing {len(images)} images in parallel "
              f"(workers={workers}, threshold={threshold})...")
        print("-" * 60)

        dir_lock = threading.Lock()
        results = []

        with ThreadPoolExecutor(max_workers=workers) as executor:
            futures = {
                executor.submit(
                    self._process_one,
                    img, output_path, threshold, move, dry_run, dir_lock, verbose
                ): img
                for img in images
            }
            for future in as_completed(futures):
                try:
                    results.append(future.result())
                except Exception as e:
                    print(f"  ❌ Error processing {Path(futures[future]).name}: {e}")

        matched   = [r for r in results if r['themes']]
        unmatched = [r for r in results if not r['themes']]

        themes_used = defaultdict(list)
        for r in matched:
            for t in r['themes']:
                themes_used[t].append(r['path'])

        print("\n" + "=" * 60)
        print("📊 ORGANIZATION SUMMARY")
        print("=" * 60)
        print(f"Total images processed: {len(results)}")
        print(f"Matched images:         {len(matched)}")
        print(f"Unmatched images:       {len(unmatched)}")
        print(f"Unique themes used:     {len(themes_used)}")

        if not dry_run:
            results_file = output_path / "sorting_results.json"
            with open(results_file, 'w') as f:
                json.dump({
                    'total_images': len(results),
                    'matched_count': len(matched),
                    'unmatched_count': len(unmatched),
                    'themes_used': list(themes_used.keys()),
                    'matches': [
                        {
                            'image': Path(r['path']).name,
                            'themes': r['themes'],
                            'scores': r['scores'],
                        }
                        for r in matched
                    ]
                }, f, indent=2)
            print(f"\n✓ Results saved to: {results_file}")

        print("\n📈 THEME STATISTICS:")
        print("-" * 40)
        for theme_name, imgs in sorted(themes_used.items(), key=lambda x: len(x[1]), reverse=True):
            print(f"  {theme_name}: {len(imgs)} images")
        if unmatched:
            print(f"  _unmatched: {len(unmatched)} images")

        print("\n" + "=" * 60)
        if dry_run:
            print("✓ Dry run completed - no files were copied/moved")
        else:
            print(f"✓ Done! Files {'moved' if move else 'copied'} to: {output_path}")
        print("=" * 60)

    def batch_process(self, input_dirs: List[str], output_base_dir: str = "wallpapers",
                     threshold: float = 0.25, recursive: bool = True,
                     move: bool = False, dry_run: bool = False, workers: int = 4):
        for input_dir in input_dirs:
            print(f"\n{'='*60}")
            print(f"Processing: {input_dir}")
            print(f"{'='*60}")
            self.organize_images(
                input_dir=input_dir,
                output_base_dir=output_base_dir,
                threshold=threshold,
                dry_run=dry_run,
                move=move,
                verbose=True,
                workers=workers,
            )

def main():
    parser = argparse.ArgumentParser(
        description='Organize wallpapers into theme-based directories'
    )
    parser.add_argument('input_dir', nargs='+',
                       help='Input directory(s) to scan for images')
    parser.add_argument('-j', '--json', default='colors.json',
                       help='Path to colors.json file (default: colors.json)')
    parser.add_argument('-o', '--output', default='wallpapers',
                       help='Output directory for sorted wallpapers (default: wallpapers)')
    parser.add_argument('-t', '--threshold', type=float, default=0.25,
                       help='Match threshold (0-1, lower = stricter, default: 0.25)')
    parser.add_argument('--move', action='store_true',
                       help='Move files instead of copying (default: copy)')
    parser.add_argument('--dry-run', action='store_true', default=False,
                       help='Show what would be done without actually doing it')
    parser.add_argument('-w', '--workers', type=int, default=4,
                       help='Number of parallel workers (default: 4)')
    parser.add_argument('--no-recursive', action='store_true',
                       help='Do not scan subdirectories recursively')

    args = parser.parse_args()

    if not os.path.exists(args.json):
        print(f"❌ Error: {args.json} not found!")
        sys.exit(1)

    organizer = ThemeWallpaperOrganizer(args.json)
    organizer.batch_process(
        input_dirs=args.input_dir,
        output_base_dir=args.output,
        threshold=args.threshold,
        recursive=not args.no_recursive,
        move=args.move,
        dry_run=args.dry_run,
        workers=args.workers
    )

if __name__ == "__main__":
    main()
