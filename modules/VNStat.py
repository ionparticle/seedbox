from __future__ import division # force floating point division for /
import subprocess
import string
import math
import datetime
import time
import calendar
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

def parseVNStat():
	process = subprocess.check_output(["vnstat","--dumpdb"])
	lines = process.split("\n")
	hourLines = lines[65:89]
	dayLines = lines[13:43]
	monthLines = lines[43:55]
	tr = int(getVal(lines[6]))
	tt = int(getVal(lines[7]))
	createDate = int(getVal(lines[4]))
	ttl = tr + tt
	total = {'tr': tr, 'tt': tt, 'trs': scaleBytes(tr, 'MB'), 'total': ttl,
			'tts': scaleBytes(tt, 'MB'), 'totals': scaleBytes(ttl, 'MB'),
			'create': time.strftime("%Y-%m-%d", time.localtime(createDate))}

	months = []
	for month in monthLines:
		if (getVal(month, 2) != '0'): # skip empty entries
			months.append(parseEntry(month, 'm', "MB"))
	days = []
	for day in dayLines:
		if (getVal(day, 2) != '0'): # skip empty entries
			days.append(parseEntry(day, 'd', "MB"))
	hours = []
	for hour in hourLines:
		if (getVal(hour, 2) != '0'): # skip empty entries
			hours.append(parseEntry(hour, 'h', "kB"))
	return {'total': total, 'months': months, 'days': days, 'hours': hours}

def parseEntry(line, expected, scale):
	if (getVal(line, 0) != expected):
		raise Exception("Unexpected entry type during vnstat parsing")
	index = getVal(line)
	ts = getVal(line, 2)
	rx = int(getVal(line, 3))
	tx = int(getVal(line, 4))
	# add the kilobytes part, if it exists
	if (getVal(line, 5)):
		rxk = int(getVal(line, 5))
		txk = int(getVal(line, 6))
		rx = rx + (rxk / 1024)
		tx = tx + (txk / 1024)
	total = rx + tx
	if (expected == 'm'):
		avg = calcMonthAvg(total, scale, float(ts))
	else:
		avg = calcDayAvg(total, scale)

	return {'index': index, 'time': ts, 'rx': rx, 'tx': tx, 'avg': avg,
			'total': total, 'totals': scaleBytes(total, scale),
			'rxs': scaleBytes(rx, scale), 'txs': scaleBytes(tx, scale),
			'avgs': scaleBytes(avg, 'kB') + '/s'}

def getVal(line, index = 1):
	elements = line.split(";")
	if (index < len(elements)):
		return elements[index]
	return False

def calcDayAvg(total, scale):
	if (scale == 'MB'):
		total = total * 1024
	avg = total / 86400
	return avg

def calcMonthAvg(total, scale, ts):
	#curMonth = time.strftime("%m")
	curMonth = time.localtime().tm_mon
	month = time.localtime(ts).tm_mon
	year = time.localtime(ts).tm_year

	if (month == curMonth):
		secondsElapsed = time.time() - ts
	else:
		day = calendar.monthrange(year, month)[1]
		lastDay = datetime.datetime(year, month, day, 23, 59, 59)
		lastDay = time.mktime(lastDay.timetuple())
		secondsElapsed = lastDay - ts

	# how many days in a month
	if (scale == 'MB'):
		total = total * 1024
	avg = total / secondsElapsed
	return avg
