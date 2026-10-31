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

    # Checkout gh-pages
    subprocess.run('git checkout gh-pages', shell=True, check=True)

    # Wipe EVERYTHING in repo_dir except .git
    for item in os.listdir(repo_dir):
        if item == '.git':
            continue
        p = os.path.join(repo_dir, item)
        if os.path.isdir(p):
            shutil.rmtree(p, onerror=remove_readonly)
        else:
            try:
                os.chmod(p, stat.S_IWRITE)
                os.remove(p)
            except Exception:
                pass

    print("Cleaned working directory for gh-pages!")

    # Copy ONLY files from temp_dir into repo_dir
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
        subprocess.run('git commit -m "deploy: clean web release with WhatCanAiDoWidget and live YandexGPT Pro"', shell=True, check=True)
        print("Committed changes to gh-pages")
        subprocess.run('git push origin gh-pages', shell=True, check=True)
        print("Pushed gh-pages to origin")
    else:
        print("No changes on gh-pages to commit")

    shutil.rmtree(temp_dir, onerror=remove_readonly)
    
    # Return to master
    subprocess.run('git checkout master', shell=True, check=True)
    subprocess.run('git checkout .', shell=True, check=True)
    print("Returned to master cleanly!")

if __name__ == '__main__':
    main()
