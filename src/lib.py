# Import Required Modules
import subprocess


# Define Functions
def update_repo():
    try:
        # Run 'git pull' to update the local repo
        print("🔄 Pulling updates from remote repository...")
        result = subprocess.run(['git', 'pull'], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

        # Output the result of the pull
        print(f"📄 Output:\n{result.stdout}")

        if result.stderr:
            print(f"⚠️ Git pull errors:\n{result.stderr}")

    except subprocess.CalledProcessError as e:
        print(f"❌ Error during git pull: {e}")
        return False

    return True


def run_setup():
    try:
        # Run 'python setup.py'
        print("🚀 Setting Things Up...")
        result = subprocess.run(['pip', 'install', '-r', 'requirements.txt'], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                text=True)

        # Output the result of running setup.py
        print(f"📄 Output:\n{result.stdout}")

        if result.stderr:
            print(f"⚠️ setup.py errors:\n{result.stderr}")

    except subprocess.CalledProcessError as e:
        print(f"❌ Error during setup.py execution: {e}")


