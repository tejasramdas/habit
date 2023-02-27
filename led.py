import pyboard

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

