local Path = require("Path")
local ffi = require("ffi")
local bit = require("bit")

ffi.cdef [[
    typedef int pid_t;
    typedef long ssize_t;
    int pipe(int fds[2]);
    pid_t fork(void);
    int dup2(int oldfd, int newfd);
    int close(int fd);
    int execvp(const char *file, char *const argv[]);
    void _exit(int status);
    ssize_t write(int fd, const void *buf, size_t count);
    ssize_t read(int fd, void *buf, size_t count);
    pid_t waitpid(pid_t pid, int *status, int options);
]]


ffi.cdef [[
    typedef struct FILE FILE;
    FILE *fdopen(int fd, const char *mode);
    size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream);
    size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream);
    int fflush(FILE *stream);
    int fclose(FILE *stream);
    int fseek(FILE *stream, long offset, int whence);
    long ftell(FILE *stream);
    char *fgets(char *s, int n, FILE *stream);
]]

local record utilities

    record graph end
end

function utilities.popen2(cmd: {string}): integer | nil, FILE | nil, FILE | nil, string | nil
    local inp, outp = ffi.new("int[2]"), ffi.new("int[2]")

    if ffi.C.pipe(inp) ~= 0 then return nil, nil, nil, "Could not create input pipe" end
    if ffi.C.pipe(outp) ~= 0 then
        ffi.C.close(inp[0])
        ffi.C.close(inp[1])
        return nil, nil, nil, "Could not create output pipe"
    end

    local pid: integer = ffi.C.fork()
    if pid < 0 then
        ffi.C.close(inp[0])
        ffi.C.close(inp[1])
        ffi.C.close(outp[0])
        ffi.C.close(outp[1])
        return nil, nil, nil, "Could not fork process"
    end

    if pid == 0 then
        ffi.C.dup2(inp[0], 0)
        ffi.C.dup2(outp[1], 1)
        
        ffi.C.close(inp[0])
        ffi.C.close(inp[1])
        ffi.C.close(outp[0])
        ffi.C.close(outp[1])

        local argv = ffi.new("char *[?]", #cmd + 1) as {ffi.CData}
        for i = 1, #cmd do
            argv[i - 1] = ffi.cast("char *", cmd[i])
        end
        argv[#cmd] = nil

        ffi.C.execvp(argv[0], argv)
        ffi.C._exit(127)
    end

    ffi.C.close(inp[0])
    ffi.C.close(outp[1])

    
end

function utilities.graph.dot(inp: string, out: Path): boolean, string, integer --: string | nil, (string | nil)
    local cmd = string.format("dot -o%s -T%s", tostring(out), out:extension())
    local f = io.popen(cmd, "w") |> assert
    f:write(inp)
    return f:close()
end

local e = math.exp(1)
function utilities.tanh(x: number): number
    return (e^(2*x)-1)/(e^(2*x)+1)
end

function utilities.sigmoid(x: number): number
    return 1/(e+e^-x)
end

return utilities
