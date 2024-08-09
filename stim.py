import pyboard
import datetime
import time

class Stim:
    def __init__(self, gpio1=1,gpio2=2,gpio3=3,gpiol=14, port=1, flash=False):
        self.pyb=pyboard.Pyboard(f"/dev/ttyACM{port}")
        self.pyb.enter_raw_repl()
        self.exec(f"import neopixel, time;")
        self.exec(f"stim1=machine.Pin({gpio1},machine.Pin.OUT);")
        self.exec(f"stim2=machine.Pin({gpio2},machine.Pin.OUT);")
        self.exec(f"stim3=machine.Pin({gpio3},machine.Pin.OUT);")
        self.exec(f"led=neopixel.NeoPixel(machine.Pin({gpiol},machine.Pin.OUT), 24);")
        self.exec(f"stat=machine.Pin(25,machine.Pin.OUT);stat.high()")
    def exec(self,cmd):
        return self.pyb.exec(cmd)
    def high(self,n):
        self.exec(f"stim{n}.high()")
    def low(self,n):
        self.exec(f"stim{n}.low()")
    def set_led(self,r,g,b):
        for i in range(24):
            self.exec(f"led[{i}]=({r},{g},{b});")
        self.exec(f"led.write()")
    def flash_me(self, n, t=0, period=0, offset=0, p_w=0):
        print("Starting")
        beg=datetime.datetime.now()
        curr_t=0
        while curr_t<(t-0.001):
            self.high(n)
            time.sleep(p_w)
            self.low(n)
            time.sleep(period-p_w)
            curr_t=(datetime.datetime.now()-beg).total_seconds()
        self.low()
    def flash_local(self, t=0, period=0, offset=0, p_w=0):
        print("Starting")
        ex=f'''for i in range(t//period):
            stim.high()
            time.sleep({p_w})
            stim.low()
            time.sleep({period}-{p_w})
        stim.low()'''
        self.pyb.exec(ex)

