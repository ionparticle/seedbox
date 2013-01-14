# Seedbox Monitor

Quick project to get some stats from my seedbox. Also more of a technology testing platform for me to play with unfamiliar stuff. Linux only, tested on Ubuntu 12.04, meant for dedicated seedboxes that can be used as servers too.

## Screenshot
![Screenshot](https://raw.github.com/ionparticle/seedbox/master/screenshot.png "Screenshot")

## Dependencies

* [vnstat/vnstati](http://humdi.net/vnstat/): Logs network bandwidth usage, persistant across reboots.

## Stack

* Web app framework: [Flask](http://flask.pocoo.org/)
* Templating engine: [Jinja 2](http://jinja.pocoo.org/)
* Application server: [uWSGI](http://projects.unbit.it/uwsgi/)
* Web server: [nginx](http://nginx.org/)

Configured so that nginx serves static content, uWSGI serves up dynamic content. Stack setup is an exercise in frustration--er, I mean, left up to the user.

## Dev notes

Disk space usage is assumed to be however much space is left on /home

## Other Credits

* [AwesomeChartJS](http://cyberpython.github.com/AwesomeChartJS/): Nice and simple chart library
* Favicon from [WooFunction iconset](http://www.woothemes.com/2009/09/woofunction-178-amazing-web-design-icons/)
