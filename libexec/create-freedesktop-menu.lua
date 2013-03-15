#!/usr/bin/env lua

freedesktop = {}
freedesktop.utils = require('freedesktop.utils')
freedesktop.menu = require('freedesktop.menu')
freedesktop.utils.icon_theme = 'gnome'

serpent = require('lib.serpent')

menu = freedesktop.menu.new()
io.stdout:write(serpent.dump(menu))
