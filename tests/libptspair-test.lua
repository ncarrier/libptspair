#!/usr/bin/env luajit

local lib = arg[1]
local header_path = arg[2]

ffi = require "ffi"
local pp = ffi.load(lib)

local f = io.popen("cat " .. header_path .. " | gcc -E -P -")
local header = f:read "*a"
ffi.cdef(header)
f:close()

ffi.cdef[[
int open(const char *pathname, int flags);
int close(int fd);
int epoll_create1(int flags);
struct epoll_event {
	uint32_t events;
	union {
		void *ptr;
		int fd;
		uint32_t u32;
		uint64_t u64;
	} data;
};
enum EPOLL_EVENTS
{
	EPOLLIN = 0x001,
	EPOLLPRI = 0x002,
	EPOLLOUT = 0x004,
	EPOLLRDNORM = 0x040,
	EPOLLRDBAND = 0x080,
	EPOLLWRNORM = 0x100,
	EPOLLWRBAND = 0x200,
	EPOLLMSG = 0x400,
	EPOLLERR = 0x008,
	EPOLLHUP = 0x010,
	EPOLLRDHUP = 0x2000,
	EPOLLWAKEUP = 1u << 29,
	EPOLLONESHOT = 1u << 30,
	EPOLLET = 1u << 31
};
int epoll_ctl(int epfd, int op, int fd, struct epoll_event *event);
int epoll_wait(int epfd, struct epoll_event *events, int maxevents, int timeout);
enum
{
	EPOLL_CLOEXEC = 02000000
};
]]
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