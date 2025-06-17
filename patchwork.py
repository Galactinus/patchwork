#!/usr/bin/env python3

import os
import json
import shutil
import subprocess
import sys
import argparse
from pathlib import Path
from typing import Optional, Dict, Any

class Patchwork:
    def __init__(self, project_dir: str):
        self.project_dir = Path(project_dir)
        self.config_file = self.project_dir / "patchwork.json"
        self.config: Dict[str, Any] = {}
        self._load_config()

    def _load_config(self):
        if self.config_file.exists():
            with open(self.config_file, 'r') as f:
                self.config = json.load(f)
        else:
            self.config = {
                "target_dir": "",
                "patches": []
            }

    def _save_config(self):
        with open(self.config_file, 'w') as f:
            json.dump(self.config, f, indent=4)

    def init(self, target_dir: Optional[str] = None):
        if target_dir is None:
            # If no target dir provided, try to use existing one from config
            if not self.config["target_dir"]:
                raise ValueError("No target directory specified and no existing target directory found")
            target_path = Path(self.config["target_dir"])
            if not target_path.exists():
                raise ValueError(f"Existing target directory {target_path} does not exist")
        else:
            target_path = Path(target_dir)
            if not target_path.is_absolute():
                target_path = self.project_dir / target_path

            if not target_path.exists():
                raise ValueError(f"Target directory {target_dir} does not exist")

            if not target_path.is_dir():
                raise ValueError(f"{target_dir} is not a directory")

            self.config["target_dir"] = str(target_path)

        # Check if it's already a git repository
        is_git_repo = (target_path / ".git").exists()

        if not is_git_repo:
            # Initialize git repository if not already one
            subprocess.run(["git", "init"], cwd=target_path, check=True)
            subprocess.run(["git", "add", "."], cwd=target_path, check=True)
            subprocess.run(["git", "commit", "-m", "Initial commit"], cwd=target_path, check=True)
        else:
            # For existing git repo, make sure all changes are committed
            status = subprocess.run(
                ["git", "status", "--porcelain"],
                cwd=target_path,
                capture_output=True,
                text=True,
                check=True
            )
            if status.stdout.strip():
                print("Committing uncommitted changes...")
                subprocess.run(["git", "add", "."], cwd=target_path, check=True)
                subprocess.run(["git", "commit", "-m", "Commit before patchwork base tag"], cwd=target_path, check=True)

        # Remove existing patchwork_base tag if it exists
        try:
            subprocess.run(["git", "tag", "-d", "patchwork_base"], cwd=target_path, check=False)
        except subprocess.CalledProcessError:
            pass  # Tag might not exist, which is fine

        # Create patchwork_base tag at current HEAD
        subprocess.run(["git", "tag", "patchwork_base"], cwd=target_path, check=True)

        self._save_config()
        print(f"Initialized patchwork project in {self.project_dir}")
        print(f"Target directory set to {target_path}")
        if is_git_repo:
            print("Existing git repository detected and tagged as patchwork_base")

    def add_patch(self, patch_path: str):
        patch_path = Path(patch_path)
        if not patch_path.exists():
            raise ValueError(f"Patch file {patch_path} does not exist")

        # Only update config, do not delete the patch file
        patch_info = {
            "path": str(patch_path),
            "cached": False
        }
        self.config["patches"] = [patch_info]  # Only keep one patch
        self._save_config()
        print(f"Set patch to {patch_path}")

    def test(self):
        target_dir = Path(self.config["target_dir"])
        if not target_dir.exists():
            raise ValueError("Target directory does not exist")

        if not self.config["patches"]:
            print("No patch configured. Use 'add_patch' first.")
            return

        patch = self.config["patches"][0]  # Only one patch
        if not patch["cached"]:
            print("Patch is not cached. Use 'cache_patch' first.")
            return

        patch_path = self.project_dir / "patches" / Path(patch["path"]).name
        if not patch_path.exists():
            print(f"Warning: Cached patch {patch_path} does not exist")
            return

        print(f"Testing patch {patch_path}")
        try:
            # Ensure A and B directories exist
            a_dir = self.project_dir / "patches" / "A"
            b_dir = self.project_dir / "patches" / "B"
            if not a_dir.exists() or not b_dir.exists():
                raise ValueError("A and B directories do not exist. Run 'build_patch' first.")

            # Test the patch directly using diff -Naur in the patches directory
            result = subprocess.run(
                ["diff", "-Naur", "A", "B"],
                cwd=self.project_dir / "patches",
                capture_output=True,
                text=True
            )
            if result.returncode in [0, 1]:
                print("Patch test successful")
            else:
                print("Patch test failed:")
                print(result.stderr)

        except Exception as e:
            print(f"Error testing patch: {e}")
            raise

    def apply(self, force: bool = False):
        target_dir = Path(self.config["target_dir"])
        if not target_dir.exists():
            raise ValueError("Target directory does not exist")

        if not force:
            # Check if we're at the patchwork_base commit
            base_commit = subprocess.run(
                ["git", "rev-parse", "patchwork_base"],
                cwd=target_dir,
                capture_output=True,
                text=True,
                check=True
            ).stdout.strip()
            
            current_commit = subprocess.run(
                ["git", "rev-parse", "HEAD"],
                cwd=target_dir,
                capture_output=True,
                text=True,
                check=True
            ).stdout.strip()

            if base_commit != current_commit:
                raise ValueError("Target directory is not at patchwork_base commit. Use 'clear' first or --force to override.")

        if not self.config["patches"]:
            print("No patch configured. Use 'add_patch' first.")
            return

        patch = self.config["patches"][0]  # Only one patch
        if not patch["cached"]:
            print("Patch is not cached. Use 'cache_patch' first.")
            return

        patch_path = self.project_dir / "patches" / Path(patch["path"]).name
        if not patch_path.exists():
            print(f"Warning: Cached patch {patch_path} does not exist")
            return

        print(f"Applying patch {patch_path}")
        try:
            # Apply the patch using the patch command
            subprocess.run(
                ["patch", "-p1", "-i", str(patch_path)],
                cwd=target_dir,
                check=True
            )
            print("Patch applied successfully")

        except subprocess.CalledProcessError as e:
            print(f"Error applying patch: {e}")
            raise

    def clear(self):
        target_dir = Path(self.config["target_dir"])
        if not target_dir.exists():
            raise ValueError("Target directory does not exist")

        print("Resetting to patchwork_base tag...")
        subprocess.run(["git", "reset", "--hard", "patchwork_base"], cwd=target_dir, check=True)
        print("Reset complete")

    def cache_patch(self):
        for patch in self.config["patches"]:
            patch_path = Path(patch["path"])
            if not patch_path.is_absolute():
                patch_path = self.project_dir / patch_path

            if not patch_path.exists():
                print(f"Warning: Patch {patch_path} does not exist")
                continue

            cache_dir = self.project_dir / "patches"
            cache_dir.mkdir(exist_ok=True)
            cached_path = cache_dir / patch_path.name

            # Only copy if source and destination are different
            if patch_path.resolve() != cached_path.resolve():
                shutil.copy2(patch_path, cached_path)
                print(f"Cached patch {patch_path} to {cached_path}")
            else:
                print(f"Patch {patch_path} is already in cache location")
            patch["cached"] = True

        self._save_config()

    def deploy_patch(self):
        for patch in self.config["patches"]:
            if not patch["cached"]:
                print(f"Warning: Patch {patch['path']} is not cached")
                continue

            patch_path = Path(patch["path"])
            cache_dir = self.project_dir / "patches"
            cached_path = cache_dir / patch_path.name

            if not cached_path.exists():
                print(f"Warning: Cached patch {cached_path} does not exist")
                continue

            shutil.copy2(cached_path, patch_path)
            print(f"Deployed patch from {cached_path} to {patch_path}")

    def build_patch(self):
        target_dir = Path(self.config["target_dir"])
        if not target_dir.exists():
            raise ValueError("Target directory does not exist")

        # Get list of changed files
        result = subprocess.run(
            ["git", "diff", "--name-only", "patchwork_base"],
            cwd=target_dir,
            capture_output=True,
            text=True,
            check=True
        )
        changed_files = result.stdout.strip().split('\n')

        if not changed_files:
            print("No changes detected")
            return

        # Create patch directory structure
        patch_dir = self.project_dir / "patches"
        patch_dir.mkdir(exist_ok=True)

        # Create A and B directories for the diff
        a_dir = patch_dir / "A"
        b_dir = patch_dir / "B"
        if a_dir.exists():
            shutil.rmtree(a_dir)
        if b_dir.exists():
            shutil.rmtree(b_dir)
        a_dir.mkdir()
        b_dir.mkdir()

        print(f"Created A and B directories in {patch_dir}")

        # Copy changed files to A and B directories
        for file_path in changed_files:
            if not file_path:
                continue

            src_path = target_dir / file_path
            if src_path.exists():
                # Create parent directories in both A and B
                a_dst = a_dir / file_path
                b_dst = b_dir / file_path
                a_dst.parent.mkdir(parents=True, exist_ok=True)
                b_dst.parent.mkdir(parents=True, exist_ok=True)

                print(f"Copying {file_path} to A and B directories")

                # Copy to B directory (modified version)
                shutil.copy2(src_path, b_dst)

                # Copy base version to A directory
                subprocess.run(
                    ["git", "show", f"patchwork_base:{file_path}"],
                    cwd=target_dir,
                    stdout=open(a_dst, 'w'),
                    check=True
                )

        print("Creating patch file...")

        # Create patch file using diff -Naur
        patch_file = patch_dir / "changes.patch"
        with open(patch_file, 'w') as f:
            result = subprocess.run(
                ["diff", "-Naur", "A", "B"],
                cwd=patch_dir,
                stdout=f,
                stderr=subprocess.PIPE,
                text=True
            )
            if result.returncode not in [0, 1]:
                print(result.stderr)
                raise subprocess.CalledProcessError(result.returncode, result.args)

        # Update config
        patch_info = {
            "path": str(patch_file),
            "cached": True
        }
        self.config["patches"] = [patch_info]
        self._save_config()

        print(f"Built patch at {patch_file}")

def main():
    parser = argparse.ArgumentParser(description="Patchwork - Patch Management Tool")
    parser.add_argument("command", choices=[
        "init", "add_patch", "test", "apply", "clear",
        "cache_patch", "deploy_patch", "build_patch"
    ])
    parser.add_argument("args", nargs="*", help="Command arguments")
    parser.add_argument("--force", action="store_true", help="Force apply patch without checking base tag")

    args = parser.parse_args()

    # Get current directory as project directory
    project_dir = os.getcwd()
    patchwork = Patchwork(project_dir)

    try:
        if args.command == "init":
            patchwork.init(args.args[0] if args.args else None)
        elif args.command == "add_patch":
            if not args.args:
                raise ValueError("add_patch requires a patch file")
            patchwork.add_patch(args.args[0])
        elif args.command == "test":
            patchwork.test()
        elif args.command == "apply":
            patchwork.apply(force=args.force)
        elif args.command == "clear":
            patchwork.clear()
        elif args.command == "cache_patch":
            patchwork.cache_patch()
        elif args.command == "deploy_patch":
            patchwork.deploy_patch()
        elif args.command == "build_patch":
            patchwork.build_patch()
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main() 