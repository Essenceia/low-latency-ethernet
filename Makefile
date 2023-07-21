ifndef debug
#debug :=
endif

TB_DIR=tb
BUILD=build
CONF=conf
FLAGS=-Wall -g2012 -gassertions -gstrict-expr-width
WAVE_FILE=wave.vcd
VIEW=gtkwave
WAVE_CONF=wave.conf
PHY_DIR=phy

all: top run


64b66b_tx : ${PHY_DIR}/64b66b.v
	iverilog ${FLAGS} -s scrambler_64b66b_tx -o ${BUILD}/64b66b_tx ${PHY_DIR}/64b66b.v

64b66b_tb: 64b66b_tx ${TB_DIR}/64b66b_tb.v
	iverilog ${FLAGS} -s lite_64b66b_tb -o ${BUILD}/lite_64b66b_tb ${PHY_DIR}/64b66b.v ${TB_DIR}/64b66b_tb.v

run: 64b66b_tb
	vvp ${BUILD}/lite_64b66b_tb

wave: run
	${VIEW} ${BUILD}/${WAVE_FILE} ${CONF}/${WAVE_CONF}

clean:
	rm -fr ${BUILD}/*
	
