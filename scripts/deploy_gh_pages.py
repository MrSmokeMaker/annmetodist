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
    temp_dir = os.path.join(tempfile.gettempdir(), 'annmetodist_web_build')
    
    if os.path.exists(temp_dir):
        shutil.rmtree(temp_dir, onerror=remove_readonly)
    shutil.copytree(os.path.join(repo_dir, 'build', 'web'), temp_dir)
    print(f"Copied build/web to {temp_dir}")

    def run(cmd):
        print(f"Running: {cmd}")
        res = subprocess.run(cmd, shell=True, check=True, text=True, capture_output=True)
        if res.stdout:
            print(res.stdout.strip())
        if res.stderr:
            print(res.stderr.strip())

    run('git checkout gh-pages')

    # Remove all tracked files in gh-pages to clear out old symlinks and non-web dirs
    subprocess.run('git rm -rf .', shell=True, check=True)

    # Overwrite / copy files from build/web into repo_dir
    for root, dirs, files in os.walk(temp_dir):
        rel_path = os.path.relpath(root, temp_dir)
        target_dir = repo_dir if rel_path == '.' else os.path.join(repo_dir, rel_path)
        os.makedirs(target_dir, exist_ok=True)
        for f in files:
            src_f = os.path.join(root, f)
            dst_f = os.path.join(target_dir, f)
            shutil.copy2(src_f, dst_f)

    # Ensure .nojekyll exists
    nojekyll_path = os.path.join(repo_dir, '.nojekyll')
    if not os.path.exists(nojekyll_path):
        with open(nojekyll_path, 'w') as f:
            pass

    print("Overwrote all web files in gh-pages cleanly!")
    
    subprocess.run('git add -A', shell=True, check=True)
    status = subprocess.run('git status --porcelain', shell=True, text=True, capture_output=True)
    if status.stdout.strip():
        subprocess.run('git commit -m "deploy: update GitHub Pages with Director tier, Lesson Summary Card & MetodistAI bot"', shell=True, check=True)
        print("Committed changes to gh-pages")
        subprocess.run('git push origin gh-pages', shell=True, check=True)
        print("Pushed gh-pages to origin")
    else:
        print("No changes on gh-pages to commit")

    shutil.rmtree(temp_dir, onerror=remove_readonly)
    
    # Return to master
    subprocess.run('git checkout master', shell=True, check=True)
    print("Returned to master successfully!")

if __name__ == '__main__':
    main()
