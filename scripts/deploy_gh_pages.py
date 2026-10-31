import shutil
import os
import stat
import subprocess
import tempfile

def remove_readonly(func, path, excinfo):
    try:
        os.chmod(path, stat.S_IWRITE)
        func(path)
    except Exception as e:
        print(f"Warning: could not remove {path}: {e}")

def main():
    repo_dir = os.path.abspath('.')
    build_web_dir = os.path.join(repo_dir, 'build', 'web')
    
    if not os.path.isdir(build_web_dir):
        print(f"Error: {build_web_dir} does not exist. Run flutter build web first.")
        return 1

    temp_worktree = os.path.join(tempfile.gettempdir(), 'annmetodist_gh_pages_worktree')
    if os.path.exists(temp_worktree):
        subprocess.run(['git', 'worktree', 'remove', '--force', temp_worktree], cwd=repo_dir)
        if os.path.exists(temp_worktree):
            shutil.rmtree(temp_worktree, onerror=remove_readonly)

    print(f"Creating git worktree at {temp_worktree} for branch gh-pages...")
    subprocess.run(['git', 'worktree', 'add', temp_worktree, 'gh-pages'], cwd=repo_dir, check=True)

    try:
        # Clear out all tracked files in worktree
        print("Cleaning worktree tracked files...")
        subprocess.run(['git', 'rm', '-rf', '.'], cwd=temp_worktree, check=True)

        # Also remove any leftover untracked files in worktree
        for item in os.listdir(temp_worktree):
            if item == '.git':
                continue
            p = os.path.join(temp_worktree, item)
            if os.path.isdir(p):
                shutil.rmtree(p, onerror=remove_readonly)
            else:
                try:
                    os.chmod(p, stat.S_IWRITE)
                    os.remove(p)
                except Exception:
                    pass

        # Copy all files from build/web into worktree
        print("Copying build/web files into worktree...")
        for root, dirs, files in os.walk(build_web_dir):
            rel_path = os.path.relpath(root, build_web_dir)
            target_dir = temp_worktree if rel_path == '.' else os.path.join(temp_worktree, rel_path)
            os.makedirs(target_dir, exist_ok=True)
            for f in files:
                src_f = os.path.join(root, f)
                dst_f = os.path.join(target_dir, f)
                shutil.copy2(src_f, dst_f)

        # Ensure .nojekyll
        nojekyll_path = os.path.join(temp_worktree, '.nojekyll')
        with open(nojekyll_path, 'w', encoding='utf-8') as f:
            pass

        print("Staging and committing files in gh-pages worktree...")
        subprocess.run(['git', 'add', '-A'], cwd=temp_worktree, check=True)

        status = subprocess.run(['git', 'status', '--porcelain'], cwd=temp_worktree, text=True, capture_output=True, check=True)
        if status.stdout.strip():
            subprocess.run([
                'git', 'commit', '-m', 
                'deploy: release v0.5.6 with dedicated mobile NewsScreen, bots menu button, and responsive layout'
            ], cwd=temp_worktree, check=True)
            print("Pushing gh-pages to origin...")
            subprocess.run(['git', 'push', 'origin', 'gh-pages'], cwd=temp_worktree, check=True)
            print("Successfully deployed clean release to GitHub Pages!")
        else:
            print("No changes to commit in gh-pages.")

    finally:
        print("Cleaning up worktree...")
        subprocess.run(['git', 'worktree', 'remove', '--force', temp_worktree], cwd=repo_dir)
        if os.path.exists(temp_worktree):
            shutil.rmtree(temp_worktree, onerror=remove_readonly)
        print("Worktree cleanup complete.")

    return 0

if __name__ == '__main__':
    exit(main())
