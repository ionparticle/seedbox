from __future__ import division # division by / yields float, // for integer div
import os
import subprocess
from flask import Flask
from flask import render_template
from modules import VNStat
from modules.Conv import scaleBytes
import json

# quick way of making sure that code changes get loaded immediately
from uwsgidecorators import *
filemon('/home/john/sites/seedbox/seedbox.py')(uwsgi.reload)
filemon('/home/john/sites/seedbox/modules/VNStat.py')(uwsgi.reload)

app = Flask(__name__)
app.debug = True

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
	vnstat = VNStat.genVNStat()
	stats = VNStat.parseVNStat()
	jsonStats = statToJson(stats)
	return render_template('index.html', df=df, stats=stats, 
			jsonStats = jsonStats)

def statToJson(stats):
	ret = {}
	rx = int(stats['days'][0]['rx'])
	tx = int(stats['days'][0]['tx'])
	ret['today'] = json.dumps([rx, tx])

	rx = int(stats['days'][1]['rx'])
	tx = int(stats['days'][1]['tx'])
	ret['yesterday'] = json.dumps([rx, tx])

	rx = int(stats['months'][0]['rx'])
	tx = int(stats['months'][0]['tx'])
	ret['thisMonth'] = json.dumps([rx, tx])

	rx = int(stats['months'][1]['rx'])
	tx = int(stats['months'][1]['tx'])
	ret['lastMonth'] = json.dumps([rx, tx])
	return ret
