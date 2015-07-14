#import "substrate.h"
#include "stdio.h"
#define size_t unsigned int


size_t (* original_ssl_read)(void *,void *,size_t,size_t *);
size_t (* original_ssl_write)(void *,void *,size_t,size_t *);

size_t hook_ssl_read(void *s,void *buf,size_t buf_size,size_t *err)
{
	int ret=0;
	ret=original_ssl_read(s,buf,buf_size,err);
	NSLog(@"ssl receive message len=%d\n%s",buf_size,buf);
	return ret;
}

size_t hook_ssl_write(void *s,void *buf,size_t buf_size,size_t *err)
{
	NSLog(@"ssl send message len=%d\n%s",buf_size,buf);
	return original_ssl_write(s,buf,buf_size,err);
}

%ctor
{
	void *lockdown_ssl_read=NULL;
	void *lockdown_ssl_write=NULL;
	//redirect stderr
	if(0==freopen("/var/log/lockdownd_message","a+",stderr))
	{
		NSLog(@"redirect stderr fail %d",errno);		
	}	
	lockdown_ssl_read=MSFindSymbol(NULL,"_SSLRead");
	lockdown_ssl_write=MSFindSymbol(NULL,"_SSLWrite");
	MSHookFunction(lockdown_ssl_read,(void *)hook_ssl_read,(void **)&original_ssl_read);
	MSHookFunction(lockdown_ssl_write,(void *)hook_ssl_write,(void **)&original_ssl_write);
}
