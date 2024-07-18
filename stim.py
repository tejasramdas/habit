import pyboard
import datetime
import time

class Stim:
    def __init__(self, gpios=1,gpiol=14, port=1, flash=False):
        self.pyb=pyboard.Pyboard(f"/dev/ttyACM{port}")
        self.pyb.enter_raw_repl()
        self.exec(f"import neopixel, time;")
        self.exec(f"stim=machine.Pin({gpios},machine.Pin.OUT);")
        self.exec(f"led=neopixel.NeoPixel(machine.Pin({gpiol},machine.Pin.OUT), 24);")
        self.exec(f"stat=machine.Pin(25,machine.Pin.OUT);stat.high()")
    def exec(self,cmd):
        return self.pyb.exec(cmd)
    def high(self):
        self.exec("stim.high()")
    def low(self):
        self.exec("stim.low()")
    def set_led(self,r,g,b):
        for i in range(24):
            self.exec(f"led[{i}]=({r},{g},{b});")
        self.exec(f"led.write()")
    def flash_me(self, t=0, period=0, offset=0, p_w=0):
        print("Starting")
        beg=datetime.datetime.now()
        curr_t=0
        while curr_t<(t-0.001):
            self.high()
            time.sleep(p_w)
            self.low()
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

