#!/usr/bin/env luajit

local lib = arg[1]
local header_path = arg[2]

ffi = require "ffi"
local pp = ffi.load(lib)

local f = io.popen("echo '#include <unistd.h>\n#include <sys/epoll.h>\n' | cat "
	.. header_path .. " - | gcc -E -P -")
local header = f:read "*a"
ffi.cdef(header)
f:close()

local O_RDWR = 2
local EPOLL_CTL_ADD = 1
local EPOLL_CTL_DEL = 2
local EPOLL_CTL_MOD = 3

local pair

local function ptspair_finalizer(pair)
	pp.ptspair_clean(pair)
end

pair = assert(ffi.new "struct ptspair")
ffi.gc(pair, ptspair_finalizer)

assert(pp.ptspair_init(pair) == 0)
local pair_fd = pp.ptspair_get_fd(pair)

local foo_path = ffi.string(pp.ptspair_get_path(pair, pp.PTSPAIR_FOO))
local bar_path = ffi.string(pp.ptspair_get_path(pair, pp.PTSPAIR_BAR))
print("foo pts " .. foo_path)
print("bar pts " .. bar_path)

--local foo_fd = ffi.C.open(foo_path, O_RDWR)
--assert(foo_fd ~= -1)
--local bar_fd = ffi.C.open(bar_path, O_RDWR)
--assert(bar_fd ~= -1)
local epoll_fd = ffi.C.epoll_create1(ffi.C.EPOLL_CLOEXEC)
assert(epoll_fd ~= -1)

local function process_events_ptspair()
	print "process_events_ptspair"
	ret = pp.ptspair_process_events(pair)
end

evt = assert(ffi.new "struct epoll_event")
evt.events = ffi.C.EPOLLIN
evt.data.fd = pair_fd
assert(ffi.C.epoll_ctl(epoll_fd, EPOLL_CTL_ADD, pair_fd, evt) == 0)
--evt.events = ffi.C.EPOLLIN
--assert(ffi.C.epoll_ctl(epoll_fd, EPOLL_CTL_ADD, foo_fd, evt) == 0)
--evt.events = ffi.C.EPOLLIN
--assert(ffi.C.epoll_ctl(epoll_fd, EPOLL_CTL_ADD, bar_fd, evt) == 0)

local status = 0
while true do
	ret = ffi.C.epoll_wait(epoll_fd, evt, 1, 10000)
	assert(ret >= 0)
	if ret == 0 then
		print "ERROR: timeout"
		status = 1
		break
	end
	if evt.data.fd == pair_fd then
		process_events_ptspair()
	end
end

ffi.C.close(epoll_fd)
--ffi.C.close(bar_fd)
--ffi.C.close(foo_fd)

os.exit(status)