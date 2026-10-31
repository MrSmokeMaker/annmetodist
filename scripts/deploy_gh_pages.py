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
    
    if not os.path.exists(temp_dir):
        print(f"Error: {temp_dir} does not exist.")
        return

    print(f"Using build files in {temp_dir}")

    # Overwrite / copy files into repo_dir
    for root, dirs, files in os.walk(temp_dir):
        rel_path = os.path.relpath(root, temp_dir)
        target_dir = repo_dir if rel_path == '.' else os.path.join(repo_dir, rel_path)
        os.makedirs(target_dir, exist_ok=True)
        for f in files:
            src_f = os.path.join(root, f)
            dst_f = os.path.join(target_dir, f)
            if os.path.exists(dst_f):
                try:
                    os.chmod(dst_f, stat.S_IWRITE)
                except Exception:
                    pass
            shutil.copy2(src_f, dst_f)

    print("Overwrote all web files in gh-pages!")
    
    subprocess.run('git add -A', shell=True, check=True)
    status = subprocess.run('git status --porcelain', shell=True, text=True, capture_output=True)
    if status.stdout.strip():
        subprocess.run('git commit -m "deploy: update Telegram Web App hybrid build with Director tariff and Telegram SDK"', shell=True, check=True)
        print("Committed changes to gh-pages")
        subprocess.run('git push origin gh-pages', shell=True, check=True)
        print("Pushed gh-pages to origin")
    else:
        print("No changes on gh-pages to commit")

    # Clean up temp
    shutil.rmtree(temp_dir, onerror=remove_readonly)
    
    # Return to master
    subprocess.run('git checkout master', shell=True, check=True)
    subprocess.run('git push origin master', shell=True, check=True)
    print("Master pushed successfully!")

if __name__ == '__main__':
    main()
