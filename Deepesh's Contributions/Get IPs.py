import subprocess
import platform
import threading

# Define the base IP of the Class C network
base_ip = "192.168.182"

# List to store reachable IPs
reachable_ips = []

# Define the ping function to check each IP
def ping_ip(ip):
    # Determine the correct ping parameter based on the operating system
    param = "-n" if platform.system().lower() == "windows" else "-c"
    
    # Run the ping command and capture the output
    try:
        result = subprocess.run(
            ["ping", param, "1", ip],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            timeout=1  # Set a timeout of 1 second
        )
        
        # Check for "unreachable" in the output (common indication on many systems)
        output = result.stdout.decode('utf-8').lower()
        if "unreachable" not in output and result.returncode == 0:
            reachable_ips.append(ip)
            # print(f"{ip} is reachable")
    
    except subprocess.TimeoutExpired:
        # If the ping command times out, we consider it unreachable
        pass

# Launch threads to ping IPs in parallel
threads = []
for i in range(1, 255):
    ip = f"{base_ip}.{i}"
    thread = threading.Thread(target=ping_ip, args=(ip,))
    threads.append(thread)
    thread.start()

# Wait for all threads to complete
for thread in threads:
    thread.join()

# Print all reachable IPs
print("\nAll reachable IPs:")
for ip in reachable_ips:
    print(ip)
