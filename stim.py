import pyboard
import datetime
import time

class Stim:
    def __init__(self, gpio='Y1', flash=False):
        self.pyb=pyboard.Pyboard('/dev/ttyACM0')
        self.pyb.enter_raw_repl()
        for i in range(16):
            self.exec(f"pyb.LED({i%4+1}).toggle()")
            self.exec("pyb.delay(10)")
        self.exec(f"stim=pyb.Pin('{gpio}',pyb.Pin.OUT_PP);")
        if flash:
            self.exec("stim.high(); pyb.delay(100);stim.low();")
    def exec(self,cmd):
        return self.pyb.exec(cmd)
    def high(self):
        self.exec("stim.high()")
    def low(self):
        self.exec("stim.low()")
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

