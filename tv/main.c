#include <inttypes.h>
#include <stdio.h>
#include <byteswap.h>

int main(){
	uint64_t reg  = UINT64_MAX;
	uint64_t test = 0x1e;
	uint64_t res  = 0;
	uint64_t i57, i38, ti0;
	printf("64b66b scramble\ninitial values:\n"
	"reg %+"PRIx64"\ninput %+"PRIx64"\n", reg, test);	
	for( int i=0; i<64; i++){
		i57 = ( reg >> 57 ) & 0x01;
		i38 = ( reg >> 38 ) & 0x01;
		ti0 = test & 0x01;
		test >>= 1;
		res <<= 1;
		res |= ( 0x01 & ( i57 ^ i38 ^ ti0 ));
		reg = (reg << 1)| ( res & 0x01 );
	}
	printf("output:\nres %+"PRIx64"\nres(le) %+"PRIx64"\nreg %+"PRIx64"\n", res, bswap_64(res), reg);	
}
