#!/usr/bin/env luajit

-- set to true to enable more traces
local debug = false

local lib = arg[1]
local header_path = arg[2]

ffi = require "ffi"
local pp = ffi.load(lib)

local headers = [[
#include <unistd.h>
#include <sys/epoll.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include "]] .. header_path .. [["
]]

local f = io.popen("echo '" .. headers .. "' | gcc -E -P - ")
local header = f:read "*a"
f:close()
ffi.cdef(header)

local O_RDWR = 2
local EPOLL_CTL_ADD = 1
local EPOLL_CTL_DEL = 2
local EPOLL_CTL_MOD = 3

local function dbg(...)
	if debug then
		print(...)
	end
end

local pair

local function ptspair_finalizer(pair)
	pp.ptspair_clean(pair)
end

pair = assert(ffi.new "struct ptspair")
ffi.gc(pair, ptspair_finalizer)

assert(pp.ptspair_init(pair) == 0)
local pair_fd = pp.ptspair_get_fd(pair)
assert(pp.ptspair_raw(pair, pp.PTSPAIR_FOO) ~= 1)
assert(pp.ptspair_raw(pair, pp.PTSPAIR_BAR) ~= 1)

local foo_path = ffi.string(pp.ptspair_get_path(pair, pp.PTSPAIR_FOO))
local bar_path = ffi.string(pp.ptspair_get_path(pair, pp.PTSPAIR_BAR))
dbg("foo pts " .. foo_path)
dbg("bar pts " .. bar_path)

local foo_fd = ffi.C.open(foo_path, O_RDWR)
assert(foo_fd ~= -1)
local bar_fd = ffi.C.open(bar_path, O_RDWR)
assert(bar_fd ~= -1)
local epoll_fd = ffi.C.epoll_create1(ffi.C.EPOLL_CLOEXEC)
assert(epoll_fd ~= -1)

local msg_index = 1
local messages = {
	"plop",
	"tata",
	"tutu",
	[[Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras a tellus
	vulputate, tempus nunc sed, ultrices augue. Vestibulum nec ultricies turpis.
	Donec dapibus sagittis commodo. Fusce non velit dolor. Phasellus molestie
	tempus dictum. Nunc laoreet nisi nec lectus congue varius nec vel nulla.
	Aenean viverra quam a risus dictum porta. Sed tempor felis eu finibus
	mattis.]]
}

local function process_events_ptspair()
	assert(pp.ptspair_process_events(pair) ~= -1)
end

local function write_message(fd)
	assert(ffi.C.write(fd, messages[msg_index],
			#(messages[msg_index])) ~= -1)
	dbg("written message '" .. messages[msg_index] .. "'")
end

local test_run = 0

local buf = assert(ffi.new "char[0x200]")
local function process_events_pts(fd)
	local fd_read, fd_written, sret

	dbg "process_events_pts"

	if fd == foo_fd then
		fd_read, fd_written = foo_fd, bar_fd
	else
		fd_read, fd_written = bar_fd, foo_fd
	end

	sret = ffi.C.read(fd_read, buf, 0x200)
	assert(sret ~= -1)
	buf[sret] = 0
	dbg("read '" .. ffi.string(buf) .. "' compared to '" ..
			messages[msg_index] .. "'")
	assert(ffi.string(buf) == messages[msg_index])
	msg_index = msg_index + 1

	if not messages[msg_index] then
		msg_index = 1
		test_run = test_run + 1
	end

	write_message(fd_written)
end

evt = assert(ffi.new "struct epoll_event")
evt.events = ffi.C.EPOLLIN
evt.data.fd = pair_fd
assert(ffi.C.epoll_ctl(epoll_fd, EPOLL_CTL_ADD, pair_fd, evt) == 0)
evt.events = ffi.C.EPOLLIN
evt.data.fd = foo_fd
assert(ffi.C.epoll_ctl(epoll_fd, EPOLL_CTL_ADD, foo_fd, evt) == 0)
evt.events = ffi.C.EPOLLIN
evt.data.fd = bar_fd
assert(ffi.C.epoll_ctl(epoll_fd, EPOLL_CTL_ADD, bar_fd, evt) == 0)

write_message(foo_fd)

local status = 0
while test_run < 10 do
	ret = ffi.C.epoll_wait(epoll_fd, evt, 1, 1000)
	assert(ret >= 0)
	if ret == 0 then
		print "ERROR: timeout"
		status = 1
		break
	end
	if evt.data.fd == pair_fd then
		process_events_ptspair()
	elseif evt.data.fd == foo_fd or evt.data.fd == bar_fd then
		process_events_pts(evt.data.fd)
	end
end

ffi.C.close(epoll_fd)
ffi.C.close(bar_fd)
ffi.C.close(foo_fd)

if status == 0 then
	print "SUCCESS !!!"
end

os.exit(status)