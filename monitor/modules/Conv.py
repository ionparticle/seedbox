from __future__ import division # force floating point division for /

# Convert bytes into a more human readable format with units
def scaleBytes(b, start = "B"):
	b = float(b)
	units = ["B", "kB","MB","GB","TB"]
	i = units.index(start)
	units = units[i:]
	for unit in units:
		if b / 1024 < 1:
			break
		elif unit == "GB": # fix off by one error where 1 TB = 1 GB
			break
		b = b / 1024
	return '%.2f %s' % (b, unit)
