port = port1
sp_nonblocking_write(port, "X8\r");
sleep(0.1);
nbytes_read, bytes = sp_nonblocking_read(port,  80);
c = String(bytes)
println(c)