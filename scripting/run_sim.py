
'''
import subprocess
import re

test_name = "test_rd"
verbosity = "UVM_MEDIUM"

result = subprocess.run(
    [
        "vsim",
        "-c",
        "-do", "run.do"
    ],
    capture_output=True,
    text=True
)

print(result.stdout)
print(result.stderr)

print("Return code:", result.returncode)

log_text = result.stdout + result.stderr

if re.search(r"TEST PASSED", log_text):
    status = "PASS"

elif re.search(r"TEST FAILED", log_text):
    status = "FAIL"

else:
    status = "UNKNOWN"

print("Simulation completed.")
print("Test:", test_name)
print("Verbosity:", verbosity)
print("Test status:", status)
'''

import subprocess
import re

test_name = "test_rd"
verbosity = "UVM_HIGH"

# Read run.do
with open("run.do", "r") as file:
    do_file = file.read()

do_file = re.sub(r"\+UVM_TESTNAME=\S+",f"+UVM_TESTNAME={test_name}",do_file)
do_file = re.sub(r"\+UVM_VERBOSITY=\S+",f"+UVM_VERBOSITY={verbosity}",do_file)

with open("python_run.do", "w") as file:
    file.write(do_file)

result = subprocess.run(["vsim", "-c", "-do", "python_run.do"],capture_output=True,text=True)

print(result.stdout)
print(result.stderr)

print("Return code:", result.returncode)

log_text = result.stdout + result.stderr

if re.search(r"TEST PASSED", log_text):
    status = "PASS"

elif re.search(r"TEST FAILED", log_text):
    status = "FAIL"

else:
    status = "UNKNOWN"

print("Simulation completed.")
print("Test:", test_name)
print("Verbosity:", verbosity)
print("Test status:", status)