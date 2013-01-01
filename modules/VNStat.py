import subprocess
import string
import math
from modules.Conv import scaleBytes

def genVNStat():
	process = subprocess.check_call(["vnstati", 
		"-ne", "-nh", "-ru", "-m", "--output", "static/img/vnstat/monthly.png"])
	process = subprocess.check_call(["vnstati", 
		"-ne", "-nh", "-ru", "-d", "--output", "static/img/vnstat/daily.png"])
	process = subprocess.check_call(["vnstati", 
		"-ne", "-nh", "-ru", "-s", "--output", "static/img/vnstat/summary.png"])
	process = subprocess.check_call(["vnstati", 
		"-ne", "-nh", "-ru", "-h", "--output", "static/img/vnstat/hourly.png"])
