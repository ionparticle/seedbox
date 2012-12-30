# Seedbox Monitor

Quick project to get some stats from my seedbox.

## Stack
* Web app framework: [Flask](http://flask.pocoo.org/)
* Templating engine: [Jinja 2](http://jinja.pocoo.org/)
* Application server: [uWSGI](http://projects.unbit.it/uwsgi/)
* Web server: [nginx](http://nginx.org/)

Configured so that nginx serves static content, uWSGI serves up dynamic content. Stack setup is an exercise in frustration--er, I mean, left up to the user.

## Dev notes

Looks like uWSGI needs to be rebooted every time python code is changed. Template changes are picked up without reboots. Would be nice to have something that automatically refreshes uWSGI when the source files are changed.
