from __future__ import division # division by / yields float, // for integer div
import os
from flask import Flask
from flask import render_template

# quick way of making sure that code changes get loaded immediately
from uwsgidecorators import *
filemon('/home/john/sites/seedbox/seedbox.py')(uwsgi.reload)

app = Flask(__name__)

@app.route('/')
def index():
	stats = os.statvfs('/home') 
	free = stats.f_bavail * stats.f_frsize
	total = stats.f_blocks * stats.f_frsize
	# note that f_bfree counts root reserved blocks as free, f_bavail does not
	used = (stats.f_blocks - stats.f_bavail) * stats.f_frsize
	pctused = round(used / total * 100, 2)
	df = {'pctfree': 100 - pctused, 'pctused': pctused}
	free = scaleBytes(free)
	total = scaleBytes(total)
	used = scaleBytes(used)

	df.update({'total' : total, 'used' :  used, 'free' : free})
	return render_template('index.html', df=df)

# Convert bytes into a more human readable format with units
def scaleBytes(b):
	units = ["B", "kB","MB","GB"]
	for unit in units:
		if b / 1024 < 1:
			break
		elif unit == "GB": # fix off by one error where 1 TB = 1 GB
			break
		b = b / 1024
	return '%.2f %s' % (b, unit)
