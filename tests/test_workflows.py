"""Workflow regressions: disposable homes/repos, no network or real activation.

Run with Python 3, Git, Bash and Zsh on PATH. The flake's `workflows` check also
supplies native builds of both Home Manager apps to test first-run CLI wiring.
"""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class Workflows(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dotfiles-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.home = self.root / "home"
        self.home.mkdir()
        self.repo = self.root / "checkout with spaces"
        self.upstream = self.root / "upstream"
        self.log = self.root / "commands.jsonl"

        # Allowlist tools instead of inheriting the developer's PATH. In
        # particular, no real nix, sudo, Home Manager, or installer is reachable.
        for tool in ("bash", "sh", "git", "sed", "grep", "tr", "head", "id", "zsh", "cat"):
            executable = shutil.which(tool)
            if not executable:
                self.fail("Required test tool is missing: " + tool)
            (self.bin / tool).symlink_to(executable)
        self.env = {
            "HOME": str(self.home),
            "USER": "root",
            "PATH": str(self.bin),
            "TMPDIR": str(self.root),
            "LC_ALL": "C",
            "NO_COLOR": "1",
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_CONFIG_GLOBAL": os.devnull,
            "GIT_ALLOW_PROTOCOL": "file",
            "GIT_TERMINAL_PROMPT": "0",
            "GIT_EDITOR": "true",
            "DOTFILES_USER": "root",
            "DOTFILES_DIR": str(self.repo),
            "DOTFILES_REPO_URL": str(self.upstream),
            "DOTFILES_TEST_LOG": str(self.log),
            # Do not let an installed Lix profile script reintroduce the host PATH.
            "__ETC_PROFILE_NIX_SOURCED": "1",
        }
        self.script("uname", 'case "$1" in -s) echo Linux;; -m) echo "${TEST_ARCH:-x86_64}";; *) exit 99;; esac\n')
        for tool in ("sudo", "curl", "systemctl"):
            self.script(tool, 'echo "Unexpected system command: $0" >&2; exit 99\n')
        for tool in ("nix-build", "nix-env"):
            self.script(tool, "exit 0\n")
        self.script(
            "nix",
            "import json, os, sys\n"
            "with open(os.environ['DOTFILES_TEST_LOG'], 'a') as log:\n"
            "    log.write(json.dumps({'args': sys.argv[1:], 'backup': os.environ.get('HOME_MANAGER_BACKUP_EXT')}) + '\\n')\n"
            "if sys.argv[1] == 'build':\n"
            "    sys.exit(77)  # Stop at the build boundary; never activate.\n"
            "if sys.argv[1] not in ('run', 'eval'):\n"
            "    sys.exit(99)\n",
            interpreter=sys.executable,
        )
        self.git(self.root, "init", "-q", "-b", "main", str(self.upstream))
        self.write(self.upstream, "flake.nix", '{\n  serverUser = "admin";\n}\n')
        self.write(self.upstream, "username.nix", '"root"\n')
        self.write(self.upstream, "config.nix", "{}\n")
        self.commit(self.upstream)
        self.git(self.root, "clone", "-q", str(self.upstream), str(self.repo))

    def script(self, name, text, interpreter=None):
        path = self.bin / name
        path.write_text("#!" + (interpreter or str(self.bin / "bash")) + "\n" + text)
        path.chmod(0o755)

    def write(self, repo, name, text):
        path = repo / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        return path

    def run_command(self, args, cwd=None, env=None, expected=0):
        result = subprocess.run(
            [str(arg) for arg in args],
            cwd=cwd or self.repo,
            env={**self.env, **(env or {})},
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=20,
        )
        if expected is not None:
            self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        return result

    def git(self, cwd, *args):
        return self.run_command([self.bin / "git", *args], cwd=cwd).stdout.strip()

    def commit(self, repo):
        self.git(repo, "add", "-A")
        self.git(repo, "-c", "user.name=Test", "-c", "user.email=test@example.invalid",
                 "commit", "-qm", "fixture", "--no-gpg-sign")

    def bootstrap(self, **kwargs):
        return self.run_command([self.bin / "bash", ROOT / "bootstrap.sh"], **kwargs)

    def linked_worktree(self):
        linked = self.root / "linked worktree"
        self.git(self.repo, "worktree", "add", "-q", "--detach", str(linked))
        self.assertTrue((linked / ".git").is_file())
        return linked

    def test_bootstrap_preserves_untracked_collision(self):
        local = self.write(self.repo, "new-config.nix", "local work\n")
        self.write(self.upstream, "new-config.nix", "upstream\n")
        self.commit(self.upstream)
        before = self.git(self.repo, "rev-parse", "HEAD")
        self.bootstrap(expected=1)
        self.assertEqual(local.read_text(), "local work\n")
        self.assertEqual(self.git(self.repo, "rev-parse", "HEAD"), before)
        self.assertFalse(self.log.exists(), "A refused refresh must not activate")

    def test_bootstrap_only_exempts_exact_root_username(self):
        for name in ("notes.txt", "username.nix.bak", "home/username.nix", "my username.nix notes"):
            with self.subTest(name=name):
                local = self.write(self.repo, name, "local work\n")
                self.bootstrap(expected=1)
                self.assertEqual(local.read_text(), "local work\n")
                local.unlink()

    def test_bootstrap_preserves_tracked_edits(self):
        self.write(self.repo, "config.nix", "local edit\n")
        self.bootstrap(expected=1)
        self.assertEqual((self.repo / "config.nix").read_text(), "local edit\n")

    def test_bootstrap_preserves_local_commits(self):
        self.write(self.repo, "config.nix", "local commit\n")
        self.commit(self.repo)
        before = self.git(self.repo, "rev-parse", "HEAD")
        self.bootstrap(expected=1)
        self.assertEqual(self.git(self.repo, "rev-parse", "HEAD"), before)

    def test_bootstrap_allows_username_stamp_and_clean_rerun(self):
        self.write(self.repo, "username.nix", '"another-user"\n')
        self.bootstrap()
        self.assertIn('"root"', (self.repo / "username.nix").read_text())
        self.bootstrap()

    def test_bootstrap_force_requires_explicit_one(self):
        local = self.write(self.repo, "new-config.nix", "local work\n")
        self.write(self.upstream, "new-config.nix", "upstream\n")
        self.commit(self.upstream)
        self.bootstrap(env={"DOTFILES_FORCE_RESET": "0"}, expected=1)
        self.assertEqual(local.read_text(), "local work\n")
        self.bootstrap(env={"DOTFILES_FORCE_RESET": "1"})
        self.assertEqual(local.read_text(), "upstream\n")

    def test_bootstrap_refreshes_linked_worktree(self):
        linked = self.linked_worktree()
        self.bootstrap(cwd=linked, env={"DOTFILES_DIR": str(linked)})
        self.assertIn('"root"', (linked / "username.nix").read_text())

    def test_apply_stages_new_files_in_clone_and_linked_worktree(self):
        self.script("home-manager", "git ls-files --error-unmatch new-module.nix\n")
        linked = self.linked_worktree()
        for repo in (self.repo, linked):
            with self.subTest(repo=repo.name):
                self.write(repo, "new-module.nix", "{}\n")
                self.run_command([self.bin / "bash", ROOT / "apply.sh", "linux"], cwd=repo)
                self.assertIn("new-module.nix", self.git(repo, "diff", "--cached", "--name-only"))

    def test_apply_staging_failure_stops_before_rebuild(self):
        self.script("home-manager", 'echo invoked > "$DOTFILES_TEST_LOG"\n')
        self.write(self.repo, ".git/index.lock", "")
        result = self.run_command([self.bin / "bash", ROOT / "apply.sh", "linux"], expected=128)
        self.assertIn("could not stage changes", result.stderr)
        self.assertFalse(self.log.exists())

    def test_apply_preserves_rebuild_failure_with_and_without_nom(self):
        self.script("home-manager", "exit 42\n")
        self.run_command([self.bin / "bash", ROOT / "apply.sh", "server"], expected=42)
        self.script("nom", "cat\n")
        self.run_command([self.bin / "bash", ROOT / "apply.sh", "server"], expected=42)

    def zsh(self, code, *args, **kwargs):
        return self.run_command(
            [self.bin / "zsh", "-f", "-c", 'source "$1"\n' + code,
             "test", ROOT / "home/config/shell/aliases.zsh", *args], **kwargs
        )

    def test_cd_failure_prevents_guarded_command(self):
        result = self.zsh('z() { return 17; }\neval \'cd missing && print BAD\'', expected=1)
        self.assertEqual(result.stdout, "")
        self.assertIn("Directory not found", result.stderr)

    def test_cd_success_for_directory_zoxide_and_home(self):
        target = self.root / "target with spaces"
        target.mkdir()
        self.zsh('eval \'cd "$2"\' && [[ "$PWD" == "$2" ]]', target)
        self.zsh('z() { builtin cd "$2"; }\neval \'cd query "$2"\' && [[ "$PWD" == "$2" ]]', target)
        self.zsh('eval cd && [[ "$PWD" == "$HOME" ]]')

    def test_home_apps_supply_pinned_cli_without_preinstalled_home_manager(self):
        apps = {name: os.environ.get("DOTFILES_TEST_" + name.upper() + "_APP")
                for name in ("linux", "server")}
        if not all(apps.values()):
            self.skipTest("Run the flake's workflows check to test the packaged apps")
        self.assertIsNone(shutil.which("home-manager", path=self.env["PATH"]))
        (self.home / ".local/state/nix/profiles").mkdir(parents=True)
        for platform, app in apps.items():
            for arch in ("x86_64", "aarch64"):
                with self.subTest(platform=platform, arch=arch):
                    self.run_command([app], env={"TEST_ARCH": arch}, expected=77)
                    calls = [json.loads(line) for line in self.log.read_text().splitlines()]
                    build = [call for call in calls if call["args"][0] == "build"][-1]
                    target = "admin-server" if platform == "server" else "root"
                    if arch == "aarch64":
                        target += "-aarch64"
                    self.assertIn('.#homeConfigurations."' + target + '".activationPackage', build["args"])
                    self.assertIn("--log-format", build["args"])
                    self.assertEqual(build["backup"], "backup")


if __name__ == "__main__":
    unittest.main(verbosity=2)
