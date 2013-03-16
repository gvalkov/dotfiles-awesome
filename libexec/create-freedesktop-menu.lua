#!/usr/bin/env lua

freedesktop = {}
freedesktop.utils = require('freedesktop.utils')
freedesktop.utils.icon_theme = 'Faenza'
freedesktop.menu = require('freedesktop.menu')

serpent = require('lib.serpent')

menu = freedesktop.menu.new()
io.stdout:write(serpent.dump(menu))
