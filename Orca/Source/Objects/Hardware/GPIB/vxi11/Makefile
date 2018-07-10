# Makefile to translate the vxi11 from Steve Sharples to Mac:
# http://optics.eee.nottingham.ac.uk/vxi11/
# Writeen by M. Marino
vxi11.h vxi11_clnt.c vxi11_xdr.c: vxi11.x
	@rpcgen vxi11.x
	@sh patch_vxi11_clnt.sh vxi11_clnt.c > /tmp/out 
	@mv /tmp/out vxi11_clnt.c 
	@sh patch_vxi11_h.sh vxi11.h > /tmp/out 
	@mv /tmp/out vxi11.h 
	@rm vxi11_svc.c

