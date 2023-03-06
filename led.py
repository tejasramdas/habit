import pyboard
import datetime

class LED:
    def __init__(self, gpio='Y4', flash=False):
        self.pyb=pyboard.Pyboard('/dev/ttyACM0')
        self.pyb.enter_raw_repl()
        for i in range(16):
            self.exec(f"pyb.LED({i%4+1}).toggle()")
            self.exec("pyb.delay(10)")
        self.exec(f"led=pyb.Pin('{gpio}',pyb.Pin.OUT_PP);")
        if flash:
            self.exec("led.high(); pyb.delay(100);led.low();")
    def exec(self,cmd):
        return self.pyb.exec(cmd)
    def high(self):
        self.exec("led.high()")
    def low(self):
        self.exec("led.low()")
    def flash(self, t=0, period=0, offset=0, p_w=0):
        beg=datetime.datetime.now()
        curr_t=0
        while curr_t<(t-0.001):
            curr_t=(datetime.datetime.now()-beg).total_seconds()
            if curr_t>offset:
                if (curr_t-offset)%period<p_w:
                    self.high()
                else:
                    self.low()
            curr_t=(datetime.datetime.now()-beg).total_seconds()
        self.low()
